-- ── verify_legacy_password now also returns name + email ─────────────────
-- Previously only {verified, role} — the matched row's own name/email were
-- already being implicitly matched against but never selected. Returning
-- them lets the registration step prefill "keep or change" fields for name
-- and email, the same way the password step already lets a student keep
-- their existing password. No identity is ever returned on a failed match
-- (still just {verified: false}) — same posture as lookup_user_by_phone,
-- which deliberately never reports identity before password ownership is
-- proven.
CREATE OR REPLACE FUNCTION public.verify_legacy_password(p_phone TEXT, p_legacy_password TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_name  TEXT;
  v_email TEXT;
BEGIN
  SELECT name, email INTO v_name, v_email
  FROM public.students
  WHERE contact = p_phone AND profile_id IS NULL
    AND legacy_data->>'password' = p_legacy_password
  LIMIT 1;
  IF FOUND THEN
    RETURN json_build_object('verified', true, 'role', 'student', 'name', v_name, 'email', v_email);
  END IF;

  SELECT name, email INTO v_name, v_email
  FROM public.employees
  WHERE contact = p_phone AND profile_id IS NULL
    AND legacy_data->>'password' = p_legacy_password
  LIMIT 1;
  IF FOUND THEN
    RETURN json_build_object('verified', true, 'role', 'teacher', 'name', v_name, 'email', v_email);
  END IF;

  SELECT name, email INTO v_name, v_email
  FROM public.branches
  WHERE contact = p_phone AND admin_id IS NULL
    AND legacy_data->>'password' = p_legacy_password
  LIMIT 1;
  IF FOUND THEN
    RETURN json_build_object('verified', true, 'role', 'branch_admin', 'name', v_name, 'email', v_email);
  END IF;

  RETURN json_build_object('verified', false);
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_legacy_password(TEXT, TEXT) TO anon, authenticated;
