-- 20240301000012_legacy_claim_verification.sql
--
-- Closes a real account-takeover hole in the "we found your record"
-- onboarding flow (lookup_user_by_phone / link_auth_user_to_entity,
-- from 20240301000000_auth_phone_lookup.sql).
--
-- Before this migration, link_auth_user_to_entity linked a freshly
-- created auth account to WHATEVER students/employees/branches row
-- matched a phone number, with zero proof the caller was that person.
-- Anyone who knew (or guessed) a registered phone number could self-link
-- to that student's — or teacher's, or **branch admin's** — record and
-- take it over. It also never set students.status, so a legitimately
-- reclaimed legacy account could still show "pending approval" if the
-- old system had left that row's status at 0.
--
-- Fixed by:
--   1. Requiring the caller to supply the student's own legacy password
--      (students.legacy_data->>'password', preserved verbatim by the
--      migration that brought this data in) before any link happens.
--   2. Removing branch_admin and teacher self-claim entirely — there is
--      no legacy password to verify a teacher against (employees never
--      got legacy_data), and a branch admin account must never be
--      self-claimable through a public, unauthenticated flow at all.
--   3. Explicitly setting status = 1 on both profiles and students on a
--      successful verified claim, regardless of whatever value the
--      historical migration carried over.
-- legacy_data (including the old password) is left untouched on a
-- successful claim — kept for reference rather than redacted.

-- ── Verify-only step, used to gate the UI before it even asks for a new
-- email/password (fails fast, nothing is created yet). ─────────────────────
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
    WHERE contact = p_phone
      AND profile_id IS NULL
      AND legacy_data->>'password' IS NOT NULL
      AND legacy_data->>'password' = p_legacy_password
  ) INTO v_match;

  RETURN json_build_object('verified', v_match);
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_legacy_password(TEXT, TEXT) TO anon, authenticated;

-- ── lookup_user_by_phone — narrowed. Reporting an *unclaimed* teacher or
-- branch_admin phone number to an anonymous caller is pure reconnaissance
-- value now that neither can be self-claimed here; only students (which
-- do have a real verification path) and existing profiles (any role, so
-- an existing user is correctly routed to password login) are reported.
-- ────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.lookup_user_by_phone(p_phone TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_email      TEXT;
  v_role       TEXT;
  v_auth_uid   UUID;
BEGIN
  -- Already has an account (any role) — route to password login.
  SELECT auth_uid, role, email INTO v_auth_uid, v_role, v_email
  FROM public.profiles WHERE contact = p_phone LIMIT 1;

  IF FOUND THEN
    RETURN json_build_object(
      'isFound', true,
      'isDuplicate', false,
      'hasAuthAccount', (v_auth_uid IS NOT NULL),
      'email', v_email,
      'role', v_role
    );
  END IF;

  -- Unclaimed legacy student record — the only self-service claim path.
  SELECT email INTO v_email FROM public.students
  WHERE contact = p_phone AND profile_id IS NULL LIMIT 1;
  IF FOUND THEN
    RETURN json_build_object(
      'isFound', true, 'isDuplicate', false, 'hasAuthAccount', false,
      'email', v_email, 'role', 'student'
    );
  END IF;

  RETURN json_build_object('isFound', false, 'isDuplicate', false);
END;
$$;

-- ── link_auth_user_to_entity — now requires and checks the legacy
-- password; teacher/branch_admin self-claim removed entirely.
-- ────────────────────────────────────────────────────────────────────────
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
  v_branch_id   INT;
  v_entity_id   INT;
  v_profile_id  UUID;
  v_name        TEXT;
  v_stored_pw   TEXT;
BEGIN
  SELECT id, branch_id, name, legacy_data->>'password'
    INTO v_entity_id, v_branch_id, v_name, v_stored_pw
  FROM public.students
  WHERE contact = p_phone AND profile_id IS NULL
  LIMIT 1;

  IF FOUND THEN
    IF v_stored_pw IS NULL OR p_legacy_password IS NULL OR v_stored_pw != p_legacy_password THEN
      RETURN json_build_object('success', false, 'reason', 'invalid_credentials');
    END IF;

    INSERT INTO public.profiles (auth_uid, role, branch_id, email, contact, full_name, status)
    VALUES (p_auth_uid, 'student', v_branch_id, p_email, p_phone, COALESCE(p_name, v_name), 1)
    RETURNING id INTO v_profile_id;

    -- A verified claim IS the approval — active regardless of whatever
    -- pending/inactive value the legacy migration carried over.
    -- legacy_data (including the old password) is kept as-is, not redacted.
    UPDATE public.students
    SET profile_id = v_profile_id,
        email = p_email,
        status = 1
    WHERE id = v_entity_id;

    RETURN json_build_object('success', true, 'role', 'student');
  END IF;

  -- No matching unclaimed student — do not fall back to creating a
  -- floating, unverified profile for an arbitrary phone number.
  RETURN json_build_object('success', false, 'reason', 'not_found');
END;
$$;

GRANT EXECUTE ON FUNCTION public.link_auth_user_to_entity(TEXT, UUID, TEXT, TEXT, TEXT) TO authenticated;
