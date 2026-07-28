-- Stage 02: Exam Scheduler, Visibility, Attempts, Shuffle, Negative Marking
-- Target: Supabase PostgreSQL

BEGIN;

-- Canonical exam schedule table
CREATE TABLE IF NOT EXISTS public.exam_schedules (
  id BIGSERIAL PRIMARY KEY,
  paper_set_id BIGINT REFERENCES public.paper_sets(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
  publish_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ,
  timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'published', 'closed', 'archived')),
  max_attempts INTEGER NOT NULL DEFAULT 1 CHECK (max_attempts >= 1),
  shuffle_questions BOOLEAN NOT NULL DEFAULT true,
  shuffle_options BOOLEAN NOT NULL DEFAULT true,
  negative_marking_enabled BOOLEAN NOT NULL DEFAULT false,
  marks_correct NUMERIC(8,3) NOT NULL DEFAULT 1,
  marks_wrong NUMERIC(8,3) NOT NULL DEFAULT 0,
  marks_unanswered NUMERIC(8,3) NOT NULL DEFAULT 0,
  negative_formula TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_exam_schedules_status_time
  ON public.exam_schedules (status, publish_at, start_at, end_at);

-- Assignment: supports per-student and by course/batch/branch
CREATE TABLE IF NOT EXISTS public.exam_assignments (
  id BIGSERIAL PRIMARY KEY,
  exam_schedule_id BIGINT NOT NULL REFERENCES public.exam_schedules(id) ON DELETE CASCADE,
  assignment_type TEXT NOT NULL CHECK (assignment_type IN ('student', 'course', 'batch', 'branch')),
  student_id UUID,
  course_id BIGINT,
  batch_id BIGINT,
  branch_id BIGINT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (
    (assignment_type = 'student' AND student_id IS NOT NULL AND course_id IS NULL AND batch_id IS NULL AND branch_id IS NULL)
    OR
    (assignment_type = 'course' AND course_id IS NOT NULL AND student_id IS NULL AND batch_id IS NULL AND branch_id IS NULL)
    OR
    (assignment_type = 'batch' AND batch_id IS NOT NULL AND student_id IS NULL AND course_id IS NULL AND branch_id IS NULL)
    OR
    (assignment_type = 'branch' AND branch_id IS NOT NULL AND student_id IS NULL AND course_id IS NULL AND batch_id IS NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_exam_assignments_lookup
  ON public.exam_assignments (assignment_type, student_id, course_id, batch_id, branch_id);

-- Enforce mandatory option shuffle for all exams per requirement
CREATE OR REPLACE FUNCTION public.trg_exam_schedule_enforce_shuffle()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.shuffle_options := true;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS exam_schedule_enforce_shuffle ON public.exam_schedules;
CREATE TRIGGER exam_schedule_enforce_shuffle
BEFORE INSERT OR UPDATE ON public.exam_schedules
FOR EACH ROW
EXECUTE FUNCTION public.trg_exam_schedule_enforce_shuffle();

-- Auto-derive end_at from start_at + duration if omitted
CREATE OR REPLACE FUNCTION public.trg_exam_schedule_derive_end_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.end_at IS NULL THEN
    NEW.end_at := NEW.start_at + (NEW.duration_minutes || ' minutes')::interval;
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS exam_schedule_derive_end_at ON public.exam_schedules;
CREATE TRIGGER exam_schedule_derive_end_at
BEFORE INSERT OR UPDATE ON public.exam_schedules
FOR EACH ROW
EXECUTE FUNCTION public.trg_exam_schedule_derive_end_at();

-- Extend session table for attempts/shuffle seeds/backward compatibility
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'exam_sessions'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'exam_sessions' AND column_name = 'exam_schedule_id'
    ) THEN
      ALTER TABLE public.exam_sessions ADD COLUMN exam_schedule_id BIGINT REFERENCES public.exam_schedules(id);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'exam_sessions' AND column_name = 'attempt_no'
    ) THEN
      ALTER TABLE public.exam_sessions ADD COLUMN attempt_no INTEGER NOT NULL DEFAULT 1;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'exam_sessions' AND column_name = 'option_shuffle_seed'
    ) THEN
      ALTER TABLE public.exam_sessions ADD COLUMN option_shuffle_seed BIGINT;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'exam_sessions' AND column_name = 'submitted_at'
    ) THEN
      ALTER TABLE public.exam_sessions ADD COLUMN submitted_at TIMESTAMPTZ;
    END IF;
  END IF;
END
$$;

-- Visibility view: who can see exam now
CREATE OR REPLACE VIEW public.v_student_visible_exams AS
SELECT
  es.id AS exam_schedule_id,
  es.paper_set_id,
  es.title,
  es.publish_at,
  es.start_at,
  es.end_at,
  es.duration_minutes,
  es.max_attempts,
  es.shuffle_questions,
  es.shuffle_options,
  es.negative_marking_enabled,
  es.marks_correct,
  es.marks_wrong,
  es.marks_unanswered,
  ea.assignment_type,
  ea.student_id,
  ea.course_id,
  ea.batch_id,
  ea.branch_id
FROM public.exam_schedules es
JOIN public.exam_assignments ea ON ea.exam_schedule_id = es.id AND ea.is_active = true
WHERE es.status IN ('published', 'scheduled')
  AND now() >= es.publish_at
  AND now() >= es.start_at
  AND now() <= es.end_at;

COMMIT;
