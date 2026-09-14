-- ── Fix: link_auth_user_to_entity never set profiles.permissions ─────────
-- Every profile created via the phone/legacy-claim flow silently fell back
-- to the '{}'::text[] column default, leaving every claimed account with
-- zero permissions (found via branch_admin "Ajeet" seeing no permitted
-- actions after a legit login). dart_backend's own registration routes
-- (auth_routes.dart) already set these correctly per role — same arrays
-- reused here verbatim.

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

-- ── Backfill: existing profiles created before this fix ──────────────────
UPDATE public.profiles SET permissions =
  ARRAY['READ_OWN_PROFILE','READ_OWN_FEES','READ_OWN_ATTENDANCE','READ_OWN_MARKSHEET','READ_OWN_CERTIFICATE','READ_OWN_IDCARD','TAKE_EXAM']
WHERE role = 'student' AND (permissions IS NULL OR permissions = '{}');

UPDATE public.profiles SET permissions =
  ARRAY['READ_OWN_PROFILE','MARK_ATTENDANCE','READ_BRANCH_STUDENTS','UPLOAD_MARKS']
WHERE role = 'teacher' AND (permissions IS NULL OR permissions = '{}');

UPDATE public.profiles SET permissions =
  ARRAY['READ_OWN_PROFILE','MARK_ATTENDANCE','READ_BRANCH_STUDENTS','UPLOAD_MARKS','ENROLL_STUDENT','RECORD_FEE','SUBMIT_MARKSHEET','ISSUE_ADMIT_CARD','READ_BRANCH_FEES','MANAGE_NOTICES','ISSUE_CERTIFICATE','SETUP_OWN_BRANCH','REGISTER_TEACHER']
WHERE role = 'branch_admin' AND (permissions IS NULL OR permissions = '{}');
