-- Enforce student registration number generation and email-change window at DB level
-- Target: PostgreSQL / Supabase

BEGIN;

-- 0) Ensure unique registration numbers at DB level
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'students'
  ) THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_indexes
      WHERE schemaname = 'public'
        AND tablename = 'students'
        AND indexname = 'students_registration_number_unique_idx'
    ) THEN
      CREATE UNIQUE INDEX students_registration_number_unique_idx
        ON public.students (registration_number)
        WHERE registration_number IS NOT NULL;
    END IF;
  END IF;
END
$$;

-- 1) Ensure email lock timestamp columns exist
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'students'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'students'
        AND column_name = 'email_last_changed_at'
    ) THEN
      ALTER TABLE public.students
        ADD COLUMN email_last_changed_at timestamptz;
    END IF;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'profiles'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'email_last_changed_at'
    ) THEN
      ALTER TABLE public.profiles
        ADD COLUMN email_last_changed_at timestamptz;
    END IF;
  END IF;
END
$$;

-- 2) Registration number generator
CREATE OR REPLACE FUNCTION public.generate_student_registration_number()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  sample_reg text;
  year_text text := to_char(current_date, 'YYYY');
  prefix text;
  width int;
  max_seq int;
BEGIN
  -- Avoid duplicate reg numbers in concurrent inserts.
  PERFORM pg_advisory_xact_lock(hashtext('public.students.registration_number'));

  -- Try to infer a pattern from existing data
  SELECT s.registration_number
  INTO sample_reg
  FROM public.students s
  WHERE s.registration_number IS NOT NULL
    AND btrim(s.registration_number) <> ''
  ORDER BY s.registration_number DESC
  LIMIT 1;

  IF sample_reg IS NULL THEN
    sample_reg := 'GS-' || year_text || '-0001';
  END IF;

  -- Pattern A: PREFIX-YYYY-0001
  IF sample_reg ~ '^[A-Za-z]+[-/][0-9]{4}[-/][0-9]+$' THEN
    prefix := regexp_replace(sample_reg, '^([A-Za-z]+)[-/].*$', '\1');
    width := length(regexp_replace(sample_reg, '^.*[-/]([0-9]+)$', '\1'));

    SELECT COALESCE(MAX((regexp_match(s.registration_number,
      '^' || prefix || '[-/]' || year_text || '[-/]([0-9]+)$'))[1]::int), 0)
    INTO max_seq
    FROM public.students s
    WHERE s.registration_number ~ ('^' || prefix || '[-/]' || year_text || '[-/][0-9]+$');

    RETURN prefix || '-' || year_text || '-' || lpad((max_seq + 1)::text, width, '0');
  END IF;

  -- Pattern B: pure numeric
  IF sample_reg ~ '^[0-9]+$' THEN
    width := length(sample_reg);

    SELECT COALESCE(MAX(s.registration_number::bigint), 0)::int
    INTO max_seq
    FROM public.students s
    WHERE s.registration_number ~ '^[0-9]+$';

    RETURN lpad((max_seq + 1)::text, width, '0');
  END IF;

  -- Pattern C: fixed prefix + numeric suffix
  IF sample_reg ~ '^(.*?)[0-9]+$' THEN
    prefix := regexp_replace(sample_reg, '^(.*?)[0-9]+$', '\1');
    width := length(regexp_replace(sample_reg, '^.*?([0-9]+)$', '\1'));

    SELECT COALESCE(MAX((regexp_match(s.registration_number,
      '^' || regexp_replace(prefix, '([\\.^$|()\[\]{}*+?\\-])', '\\\1', 'g') || '([0-9]+)$'))[1]::int), 0)
    INTO max_seq
    FROM public.students s
    WHERE s.registration_number ~ ('^' || regexp_replace(prefix, '([\\.^$|()\[\]{}*+?\\-])', '\\\1', 'g') || '[0-9]+$');

    RETURN prefix || lpad((max_seq + 1)::text, width, '0');
  END IF;

  -- Default fallback
  SELECT COALESCE(MAX((regexp_match(s.registration_number,
    '^GS-' || year_text || '-([0-9]+)$'))[1]::int), 0)
  INTO max_seq
  FROM public.students s
  WHERE s.registration_number ~ ('^GS-' || year_text || '-[0-9]+$');

  RETURN 'GS-' || year_text || '-' || lpad((max_seq + 1)::text, 4, '0');
END
$$;

-- 3) Auto-fill registration number for new students
CREATE OR REPLACE FUNCTION public.trg_students_fill_registration_number()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.registration_number IS NULL OR btrim(NEW.registration_number) = '' THEN
    NEW.registration_number := public.generate_student_registration_number();
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS students_fill_registration_number ON public.students;
CREATE TRIGGER students_fill_registration_number
BEFORE INSERT ON public.students
FOR EACH ROW
EXECUTE FUNCTION public.trg_students_fill_registration_number();

-- 4) Email can change only once in 30 days
CREATE OR REPLACE FUNCTION public.trg_enforce_email_change_30_days()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  last_changed timestamptz;
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.email IS NOT NULL AND btrim(NEW.email) <> '' THEN
      NEW.email_last_changed_at := COALESCE(NEW.email_last_changed_at, now());
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.email IS DISTINCT FROM OLD.email THEN
    -- First-time set from NULL/blank is allowed immediately
    IF OLD.email IS NULL OR btrim(OLD.email) = '' THEN
      NEW.email_last_changed_at := now();
      RETURN NEW;
    END IF;

    last_changed := COALESCE(OLD.email_last_changed_at, '-infinity'::timestamptz);

    IF now() < (last_changed + interval '30 days') THEN
      RAISE EXCEPTION 'Email can be changed only once in 30 days.'
        USING ERRCODE = 'P0001';
    END IF;

    NEW.email_last_changed_at := now();
  END IF;

  RETURN NEW;
END
$$;

-- Attach to students if email column exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'students'
      AND column_name = 'email'
  ) THEN
    DROP TRIGGER IF EXISTS students_enforce_email_30_days ON public.students;
    CREATE TRIGGER students_enforce_email_30_days
    BEFORE INSERT OR UPDATE ON public.students
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_email_change_30_days();
  END IF;
END
$$;

-- Attach to profiles if email column exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'profiles'
      AND column_name = 'email'
  ) THEN
    DROP TRIGGER IF EXISTS profiles_enforce_email_30_days ON public.profiles;
    CREATE TRIGGER profiles_enforce_email_30_days
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_email_change_30_days();
  END IF;
END
$$;

COMMIT;
