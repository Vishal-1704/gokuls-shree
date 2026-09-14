-- ── Multi-enrollment support ──────────────────────────────────────────────
-- A real person (`profiles` row) can legitimately have more than one
-- `students` row (one per course enrollment). Today only ONE ever gets
-- linked (`profile_id` set) — via `link_auth_user_to_entity`'s
-- `... LIMIT 1` match — leaving sibling enrollments permanently invisible
-- to the student's own login, and RLS itself only ever authorizes that
-- one row via `current_student_id()`'s own `LIMIT 1`.
--
-- Matching rule (explicit user requirement): same phone number AND
-- same name (lowercased + trimmed) = same person, auto-link. Same phone,
-- DIFFERENT name = a different person who happens to share a number
-- (a known legacy pattern — branch admins sometimes entered their own/a
-- placeholder number before a student gave theirs) — never auto-merge;
-- surface it to the client instead via find_phone_name_conflict().
--
-- current_student_id() (single-row) is left completely untouched — it's
-- referenced ~17 more places beyond the 8 read policies below (exam
-- attempts, grading, attendance check-in) where "exactly one enrollment"
-- is the CORRECT behavior (attributing one write to one enrollment).
-- Only a new current_student_ids() is added, and only the 8 *read*
-- policies are pointed at it.

-- ── 1. Linking: find + link sibling enrollments by phone+name ────────────
CREATE OR REPLACE FUNCTION public.link_sibling_student_enrollments(p_profile_id UUID)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_phone TEXT;
  v_name  TEXT;
  v_count INT;
BEGIN
  SELECT contact, name INTO v_phone, v_name
  FROM public.students
  WHERE profile_id = p_profile_id
  ORDER BY doj DESC NULLS LAST
  LIMIT 1;

  IF v_phone IS NULL OR v_name IS NULL THEN
    RETURN 0;
  END IF;

  UPDATE public.students
  SET profile_id = p_profile_id, status = 1
  WHERE profile_id IS NULL
    AND contact = v_phone
    AND lower(trim(name)) = lower(trim(v_name));

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.link_sibling_student_enrollments(UUID) TO authenticated;

-- ── 2. Conflict check: same phone, different (normalized) name ───────────
-- True means "don't assume these are the same person" — the client shows
-- a "profile already exists under a different name, contact your branch
-- admin" message rather than silently leaving the row unlinked with no
-- explanation.
CREATE OR REPLACE FUNCTION public.find_phone_name_conflict(p_phone TEXT, p_name TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.students
    WHERE profile_id IS NULL
      AND contact = p_phone
      AND lower(trim(name)) <> lower(trim(p_name))
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.find_phone_name_conflict(TEXT, TEXT) TO authenticated;

-- ── 3. link_auth_user_to_entity — call the linker after a student links ──
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

    INSERT INTO public.profiles (auth_uid, role, branch_id, email, contact, full_name, status, permissions)
    VALUES (p_auth_uid, 'student', v_branch_id, p_email, p_phone, COALESCE(p_name, v_name), 1,
      ARRAY['READ_OWN_PROFILE','READ_OWN_FEES','READ_OWN_ATTENDANCE','READ_OWN_MARKSHEET','READ_OWN_CERTIFICATE','READ_OWN_IDCARD','TAKE_EXAM'])
    RETURNING id INTO v_profile_id;

    UPDATE public.students
    SET profile_id = v_profile_id, email = p_email, status = 1
    WHERE id = v_entity_id;

    -- Auto-link any sibling enrollment rows sharing this phone + name.
    PERFORM public.link_sibling_student_enrollments(v_profile_id);

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

    INSERT INTO public.profiles (auth_uid, role, branch_id, email, contact, full_name, status, permissions)
    VALUES (p_auth_uid, 'teacher', v_branch_id, p_email, p_phone, COALESCE(p_name, v_name), 1,
      ARRAY['READ_OWN_PROFILE','MARK_ATTENDANCE','READ_BRANCH_STUDENTS','UPLOAD_MARKS'])
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

    INSERT INTO public.profiles (auth_uid, role, branch_id, email, contact, full_name, status, permissions)
    VALUES (p_auth_uid, 'branch_admin', v_entity_id, p_email, p_phone, COALESCE(p_name, v_name), 1,
      ARRAY['READ_OWN_PROFILE','MARK_ATTENDANCE','READ_BRANCH_STUDENTS','UPLOAD_MARKS','ENROLL_STUDENT','RECORD_FEE','SUBMIT_MARKSHEET','ISSUE_ADMIT_CARD','READ_BRANCH_FEES','MANAGE_NOTICES','ISSUE_CERTIFICATE','SETUP_OWN_BRANCH','REGISTER_TEACHER'])
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

-- ── 4. One-time backfill: link any pre-existing sibling rows now ─────────
-- For every profile that already has at least one linked students row,
-- try linking its siblings by the same phone+name rule.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT DISTINCT profile_id FROM public.students WHERE profile_id IS NOT NULL LOOP
    PERFORM public.link_sibling_student_enrollments(r.profile_id);
  END LOOP;
END $$;

-- ── 5. current_student_ids() — set-returning sibling of current_student_id() ──
CREATE OR REPLACE FUNCTION public.current_student_ids()
RETURNS INT[]
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  ids INT[];
BEGIN
  SELECT array_agg(s.id) INTO ids
  FROM public.students s
  JOIN public.profiles p ON s.profile_id = p.id
  WHERE p.auth_uid = auth.uid() AND p.status = 1;
  RETURN COALESCE(ids, ARRAY[]::INT[]);
END;
$$;

-- ── 6. Point the 8 read policies at current_student_ids() ────────────────
-- current_student_id() itself, and every other site using it, is
-- untouched — only these SELECT policies change.

DROP POLICY IF EXISTS "students_select" ON students;
CREATE POLICY "students_select" ON students
  FOR SELECT USING (
    CASE current_user_role()
      WHEN 'super_admin'  THEN true
      WHEN 'branch_admin' THEN branch_id = current_user_branch()
      WHEN 'teacher'      THEN branch_id = current_user_branch()
      WHEN 'student'      THEN id = ANY(current_student_ids())
      ELSE false
    END
  );

DROP POLICY IF EXISTS "fees_select" ON fee_payments;
CREATE POLICY "fees_select" ON fee_payments
  FOR SELECT USING (
    CASE current_user_role()
      WHEN 'super_admin'  THEN true
      WHEN 'branch_admin' THEN branch_id = current_user_branch()
      WHEN 'student'      THEN student_id = ANY(current_student_ids())
      ELSE false
    END
  );

DROP POLICY IF EXISTS "marksheets_select" ON marksheets;
CREATE POLICY "marksheets_select" ON marksheets
  FOR SELECT USING (
    CASE current_user_role()
      WHEN 'super_admin'  THEN true
      WHEN 'branch_admin' THEN branch_id = current_user_branch()
      WHEN 'teacher'      THEN branch_id = current_user_branch()
      WHEN 'student'      THEN
        student_id = ANY(current_student_ids())
        AND status = 1
      ELSE false
    END
  );

DROP POLICY IF EXISTS "certs_select" ON certificates;
CREATE POLICY "certs_select" ON certificates
  FOR SELECT USING (
    CASE current_user_role()
      WHEN 'super_admin'  THEN true
      WHEN 'branch_admin' THEN branch_id = current_user_branch()
      WHEN 'student'      THEN student_id = ANY(current_student_ids()) AND status = 1
      ELSE false
    END
  );

DROP POLICY IF EXISTS "att_select" ON student_attendance;
CREATE POLICY "att_select" ON student_attendance
  FOR SELECT USING (
    CASE current_user_role()
      WHEN 'super_admin'  THEN true
      WHEN 'branch_admin' THEN branch_id = current_user_branch()
      WHEN 'teacher'      THEN branch_id = current_user_branch()
      WHEN 'student'      THEN student_id = ANY(current_student_ids())
      ELSE false
    END
  );

DROP POLICY IF EXISTS "admit_cards_select" ON public.admit_cards;
CREATE POLICY "admit_cards_select" ON public.admit_cards FOR SELECT USING (
  student_id = ANY(current_student_ids())
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);

DROP POLICY IF EXISTS "id_cards_select" ON public.id_cards;
CREATE POLICY "id_cards_select" ON public.id_cards FOR SELECT USING (
  student_id = ANY(current_student_ids())
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);

DROP POLICY IF EXISTS "exam_results_select" ON public.exam_results;
CREATE POLICY "exam_results_select" ON public.exam_results FOR SELECT USING (
  student_id = ANY(current_student_ids())
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
