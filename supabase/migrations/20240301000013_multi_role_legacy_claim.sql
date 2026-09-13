-- 20240301000013_multi_role_legacy_claim.sql
--
-- Extends the legacy-password-verified claim flow (20240301000012) to
-- employees (teachers) and branches (branch_admin) — there are only a
-- handful of each, so pre-seeding their real legacy passwords is
-- practical, unlike trying to build a whole separate onboarding path.
--
-- IMPORTANT: super_admin is intentionally never part of this. There is
-- no "unclaimed super_admin" table to match against — that role only
-- ever exists as profiles.role = 'super_admin', created directly by an
-- existing super_admin. It cannot be reached through this flow no matter
-- what phone number or password is supplied, by construction.

-- ── legacy_data columns, mirroring students' ────────────────────────────
ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS legacy_data JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.branches  ADD COLUMN IF NOT EXISTS legacy_data JSONB DEFAULT '{}'::jsonb;

-- ── Seed real legacy passwords for the 3 branch_admin rows that already
-- exist and map cleanly to the old admin_login table (decoded from its
-- double-base64 encoding — see conversation for how these were derived).
-- admin_login id=88 (branch 144) and id=1 (gokuladmin, super_admin) are
-- deliberately excluded — 144 doesn't correspond to any current branch
-- row, and the super_admin row must never be seeded here at all.
UPDATE public.branches SET contact = '9628281020', legacy_data = '{"password": "Aj@945439"}'::jsonb WHERE id = 146;
UPDATE public.branches SET contact = '9335848463', legacy_data = '{"password": "Sa@123"}'::jsonb    WHERE id = 147;
UPDATE public.branches SET contact = '9140574021', legacy_data = '{"password": "Am@914057"}'::jsonb WHERE id = 148;

-- Seed the one teacher whose old branch (1, "GOKUL") maps cleanly to a
-- current branch (branches.id = 1). Mohit (old branch 98) and Navnit (old
-- branch 120) are left out — those old branch ids have no corresponding
-- current branches row, so mapping them needs a human decision, not a
-- guess.
-- employees has no unique constraint to key an ON CONFLICT off of, so
-- guard re-runs with a plain existence check instead.
INSERT INTO public.employees (name, contact, email, branch_id, legacy_data, status)
SELECT 'JITENDRA KUMAR AMBEDKAR', '9721464285', 'jitendraambedkar3@gmail.com', 1,
       '{"password": "Jk@271801"}'::jsonb, 1
WHERE NOT EXISTS (
  SELECT 1 FROM public.employees WHERE contact = '9721464285'
);

-- ── verify_legacy_password — now checks students, employees, branches ───
CREATE OR REPLACE FUNCTION public.verify_legacy_password(p_phone TEXT, p_legacy_password TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_match BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.students
    WHERE contact = p_phone AND profile_id IS NULL
      AND legacy_data->>'password' = p_legacy_password
  ) INTO v_match;
  IF v_match THEN RETURN json_build_object('verified', true, 'role', 'student'); END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.employees
    WHERE contact = p_phone AND profile_id IS NULL
      AND legacy_data->>'password' = p_legacy_password
  ) INTO v_match;
  IF v_match THEN RETURN json_build_object('verified', true, 'role', 'teacher'); END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.branches
    WHERE contact = p_phone AND admin_id IS NULL
      AND legacy_data->>'password' = p_legacy_password
  ) INTO v_match;
  IF v_match THEN RETURN json_build_object('verified', true, 'role', 'branch_admin'); END IF;

  RETURN json_build_object('verified', false);
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_legacy_password(TEXT, TEXT) TO anon, authenticated;

-- ── lookup_user_by_phone — reports unclaimed teacher/branch_admin records
-- again, now that there's a real verification path behind them. ─────────
CREATE OR REPLACE FUNCTION public.lookup_user_by_phone(p_phone TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_email    TEXT;
  v_role     TEXT;
  v_auth_uid UUID;
BEGIN
  SELECT auth_uid, role, email INTO v_auth_uid, v_role, v_email
  FROM public.profiles WHERE contact = p_phone LIMIT 1;
  IF FOUND THEN
    RETURN json_build_object(
      'isFound', true, 'isDuplicate', false,
      'hasAuthAccount', (v_auth_uid IS NOT NULL),
      'email', v_email, 'role', v_role
    );
  END IF;

  SELECT email INTO v_email FROM public.students
  WHERE contact = p_phone AND profile_id IS NULL LIMIT 1;
  IF FOUND THEN
    RETURN json_build_object('isFound', true, 'isDuplicate', false, 'hasAuthAccount', false, 'email', v_email, 'role', 'student');
  END IF;

  SELECT email INTO v_email FROM public.employees
  WHERE contact = p_phone AND profile_id IS NULL LIMIT 1;
  IF FOUND THEN
    RETURN json_build_object('isFound', true, 'isDuplicate', false, 'hasAuthAccount', false, 'email', v_email, 'role', 'teacher');
  END IF;

  SELECT email INTO v_email FROM public.branches
  WHERE contact = p_phone AND admin_id IS NULL LIMIT 1;
  IF FOUND THEN
    RETURN json_build_object('isFound', true, 'isDuplicate', false, 'hasAuthAccount', false, 'email', v_email, 'role', 'branch_admin');
  END IF;

  RETURN json_build_object('isFound', false, 'isDuplicate', false);
END;
$$;

-- ── link_auth_user_to_entity — role-aware across all three tables, each
-- gated on its own legacy_data->>'password' match. ──────────────────────
CREATE OR REPLACE FUNCTION public.link_auth_user_to_entity(
  p_phone TEXT,
  p_auth_uid UUID,
  p_email TEXT,
  p_name TEXT DEFAULT NULL,
  p_legacy_password TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_branch_id  INT;
  v_entity_id  INT;
  v_profile_id UUID;
  v_name       TEXT;
  v_stored_pw  TEXT;
BEGIN
  -- 1. Students
  SELECT id, branch_id, name, legacy_data->>'password'
    INTO v_entity_id, v_branch_id, v_name, v_stored_pw
  FROM public.students WHERE contact = p_phone AND profile_id IS NULL LIMIT 1;

  IF FOUND THEN
    IF v_stored_pw IS NULL OR p_legacy_password IS NULL OR v_stored_pw != p_legacy_password THEN
      RETURN json_build_object('success', false, 'reason', 'invalid_credentials');
    END IF;

    INSERT INTO public.profiles (auth_uid, role, branch_id, email, contact, full_name, status)
    VALUES (p_auth_uid, 'student', v_branch_id, p_email, p_phone, COALESCE(p_name, v_name), 1)
    RETURNING id INTO v_profile_id;

    UPDATE public.students
    SET profile_id = v_profile_id, email = p_email, status = 1
    WHERE id = v_entity_id;

    RETURN json_build_object('success', true, 'role', 'student');
  END IF;

  -- 2. Employees (teachers)
  SELECT id, branch_id, name, legacy_data->>'password'
    INTO v_entity_id, v_branch_id, v_name, v_stored_pw
  FROM public.employees WHERE contact = p_phone AND profile_id IS NULL LIMIT 1;

  IF FOUND THEN
    IF v_stored_pw IS NULL OR p_legacy_password IS NULL OR v_stored_pw != p_legacy_password THEN
      RETURN json_build_object('success', false, 'reason', 'invalid_credentials');
    END IF;

    INSERT INTO public.profiles (auth_uid, role, branch_id, email, contact, full_name, status)
    VALUES (p_auth_uid, 'teacher', v_branch_id, p_email, p_phone, COALESCE(p_name, v_name), 1)
    RETURNING id INTO v_profile_id;

    UPDATE public.employees
    SET profile_id = v_profile_id, email = p_email, status = 1
    WHERE id = v_entity_id;

    RETURN json_build_object('success', true, 'role', 'teacher');
  END IF;

  -- 3. Branches (branch_admin)
  SELECT id, name, legacy_data->>'password'
    INTO v_entity_id, v_name, v_stored_pw
  FROM public.branches WHERE contact = p_phone AND admin_id IS NULL LIMIT 1;

  IF FOUND THEN
    IF v_stored_pw IS NULL OR p_legacy_password IS NULL OR v_stored_pw != p_legacy_password THEN
      RETURN json_build_object('success', false, 'reason', 'invalid_credentials');
    END IF;

    INSERT INTO public.profiles (auth_uid, role, branch_id, email, contact, full_name, status)
    VALUES (p_auth_uid, 'branch_admin', v_entity_id, p_email, p_phone, COALESCE(p_name, v_name), 1)
    RETURNING id INTO v_profile_id;

    -- admin_id references profiles(id), not the raw auth uid — use the
    -- profile row just inserted above, matching migration 012's FK.
    UPDATE public.branches
    SET admin_id = v_profile_id, email = p_email, status = 1
    WHERE id = v_entity_id;

    RETURN json_build_object('success', true, 'role', 'branch_admin');
  END IF;

  RETURN json_build_object('success', false, 'reason', 'not_found');
END;
$$;

GRANT EXECUTE ON FUNCTION public.link_auth_user_to_entity(TEXT, UUID, TEXT, TEXT, TEXT) TO authenticated;
