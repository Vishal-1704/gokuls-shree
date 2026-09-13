-- 20240301000015_smart_attendance.sql
--
-- Fixes the "Smart Attendance" (QR + BLE) system, which existed only as
-- an unused, broken half-built feature:
--   - Student side: the "Scan Attendance" button only ever showed a
--     placeholder dialog ("build on a physical device"). No real check-in
--     flow existed at all.
--   - Teacher side: had a REAL flutter_blue_plus BLE scan, but it could
--     never actually work — it matched scanned device MAC addresses
--     against students.ble_mac_address, a column nothing could ever
--     correctly populate (Android has blocked apps from reading their
--     own device's real Bluetooth MAC since Android 6; a student's app
--     has no legitimate way to discover and upload its own true MAC).
--   - attendance_qr_sessions / attendance_ble_events / attendance_events
--     (migration 014) were a well-designed but entirely unused hybrid
--     QR+BLE schema — QR for session/identity binding, BLE RSSI as a
--     supplementary proximity signal. Nothing ever called into it, it
--     had zero RLS (any authenticated user could have inserted fake
--     attendance for anyone), and attendance_ble_events.student_id /
--     attendance_events.student_id / attendance_qr_sessions.scope_
--     student_id were typed UUID with no FK — inconsistent with every
--     other student-scoped table in the schema (INT REFERENCES
--     students(id)), including student_attendance, the table BOTH the
--     student's own "My Attendance" screen and the teacher's manual
--     roll-call actually read/write. Writing into the UUID-keyed tables
--     as designed would have produced a successful-looking check-in that
--     never actually showed up as present anywhere a human looks.
--
-- Architecture decided on: teacher/branch_admin/super_admin are the
-- "host" — they create a short-lived QR session scoped to a course,
-- branch, a single student, or an open "classroom_ble" session. The
-- student ("agent") scans the QR and optionally reports a BLE ambient
-- reading (there is no peripheral/advertising step from the host device
-- — flutter_blue_plus is scan/central-only, and iOS restricts background
-- peripheral advertising heavily, so QR is the authoritative signal and
-- BLE only adjusts a confidence score, never gates the check-in outright).

-- ── Drop the pre-existing RLS from master_schema.sql on these 3 tables
-- first — Postgres refuses to ALTER COLUMN TYPE while any policy
-- expression still references that column, and attendance_ble_events_
-- insert / attendance_events_insert / attendance_events_select all
-- compared student_id directly. They were also independently wrong
-- (student_id = current_profile_id() — a student id compared against a
-- profile id), so dropping them in favor of this migration's own RLS
-- below is correct, not just a workaround.
DROP POLICY IF EXISTS "attendance_qr_sessions_select" ON public.attendance_qr_sessions;
DROP POLICY IF EXISTS "attendance_qr_sessions_all_admin" ON public.attendance_qr_sessions;
DROP POLICY IF EXISTS "attendance_ble_events_insert" ON public.attendance_ble_events;
DROP POLICY IF EXISTS "attendance_ble_events_select" ON public.attendance_ble_events;
DROP POLICY IF EXISTS "attendance_ble_events_all_admin" ON public.attendance_ble_events;
DROP POLICY IF EXISTS "attendance_events_insert" ON public.attendance_events;
DROP POLICY IF EXISTS "attendance_events_select" ON public.attendance_events;
DROP POLICY IF EXISTS "attendance_events_all_admin" ON public.attendance_events;

-- v_attendance_daily (an optional, never-referenced-by-the-app reporting
-- view — confirmed via grep across lib/, zero hits) also depends on
-- attendance_events.student_id and blocks the ALTER below the same way.
-- Drop and recreate it identically afterward, just with the corrected type.
DROP VIEW IF EXISTS public.v_attendance_daily CASCADE;

-- ── Fix the UUID/INT student_id mismatch (tables are empty — confirmed
-- via a live row count before writing this migration, zero rows in all
-- three — so this is a safe, lossless type correction). ────────────────
ALTER TABLE public.attendance_qr_sessions
  ALTER COLUMN scope_student_id TYPE INT USING NULL,
  ADD CONSTRAINT attendance_qr_sessions_scope_student_fk
    FOREIGN KEY (scope_student_id) REFERENCES public.students(id);

ALTER TABLE public.attendance_ble_events
  ALTER COLUMN student_id TYPE INT USING NULL,
  ADD CONSTRAINT attendance_ble_events_student_fk
    FOREIGN KEY (student_id) REFERENCES public.students(id);

ALTER TABLE public.attendance_events
  ALTER COLUMN student_id TYPE INT USING NULL,
  ADD CONSTRAINT attendance_events_student_fk
    FOREIGN KEY (student_id) REFERENCES public.students(id);

-- Recreate v_attendance_daily exactly as it was (master_schema.sql:1329),
-- just now backed by the corrected INT student_id.
CREATE VIEW public.v_attendance_daily WITH (security_invoker = on) AS
SELECT
  student_id,
  date_trunc('day', marked_at) AS attendance_day,
  COUNT(*) FILTER (WHERE status = 'present') AS present_count,
  COUNT(*) FILTER (WHERE status = 'rejected') AS rejected_count,
  MAX(confidence_score) AS max_confidence
FROM public.attendance_events
GROUP BY student_id, date_trunc('day', marked_at);

-- ── RLS ──────────────────────────────────────────────────────────────
ALTER TABLE public.attendance_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_qr_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_ble_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_events ENABLE ROW LEVEL SECURITY;

-- Settings: read-only for any authenticated user (qr_ttl_seconds /
-- min_ble_rssi are needed client-side to build a sensible host UI);
-- no client write path at all — change via the SQL editor if ever needed.
DROP POLICY IF EXISTS "attendance_settings_read" ON public.attendance_settings;
CREATE POLICY "attendance_settings_read" ON public.attendance_settings
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Sessions: any authenticated user can read one (a session's id is an
-- unguessable UUID handed out via QR — reading it back to validate
-- expiry/scope is exactly what a scanning student needs to do; the real
-- authorization check, whether THIS student is allowed to check into
-- THIS session, happens inside checkin_attendance below, not via RLS
-- alone). Only staff can create/end sessions, branch-scoped for
-- branch_admin like every other policy in this schema.
DROP POLICY IF EXISTS "attendance_qr_sessions_read" ON public.attendance_qr_sessions;
CREATE POLICY "attendance_qr_sessions_read" ON public.attendance_qr_sessions
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "attendance_qr_sessions_write" ON public.attendance_qr_sessions;
CREATE POLICY "attendance_qr_sessions_write" ON public.attendance_qr_sessions
  FOR INSERT WITH CHECK (
    current_user_role() IN ('teacher', 'branch_admin', 'super_admin')
    AND created_by = auth.uid()
    AND (
      scope_branch_id IS NULL
      OR current_user_role() = 'super_admin'
      OR scope_branch_id = current_user_branch()
    )
  );

DROP POLICY IF EXISTS "attendance_qr_sessions_end" ON public.attendance_qr_sessions;
CREATE POLICY "attendance_qr_sessions_end" ON public.attendance_qr_sessions
  FOR UPDATE USING (
    created_by = auth.uid() OR current_user_role() = 'super_admin'
  )
  WITH CHECK (
    created_by = auth.uid() OR current_user_role() = 'super_admin'
  );

-- BLE events / final attendance events: no client write policy at all —
-- both are written exclusively by checkin_attendance (SECURITY DEFINER,
-- bypasses RLS), so a client can never insert a fake reading or a fake
-- "present" row directly. Read access: staff (branch-scoped) or the
-- student's own rows.
DROP POLICY IF EXISTS "attendance_ble_events_read" ON public.attendance_ble_events;
CREATE POLICY "attendance_ble_events_read" ON public.attendance_ble_events
  FOR SELECT USING (
    student_id = current_student_id()
    OR current_user_role() = 'super_admin'
    OR (
      current_user_role() IN ('teacher', 'branch_admin')
      AND EXISTS (
        SELECT 1 FROM public.students s
        WHERE s.id = attendance_ble_events.student_id
          AND s.branch_id = current_user_branch()
      )
    )
  );

DROP POLICY IF EXISTS "attendance_events_read" ON public.attendance_events;
CREATE POLICY "attendance_events_read" ON public.attendance_events
  FOR SELECT USING (
    student_id = current_student_id()
    OR current_user_role() = 'super_admin'
    OR (
      current_user_role() IN ('teacher', 'branch_admin')
      AND EXISTS (
        SELECT 1 FROM public.students s
        WHERE s.id = attendance_events.student_id
          AND s.branch_id = current_user_branch()
      )
    )
  );

-- ── Host: create a session ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_attendance_session(
  p_scope_type TEXT,
  p_course_id INT DEFAULT NULL,
  p_branch_id INT DEFAULT NULL,
  p_student_id INT DEFAULT NULL,
  p_duration_seconds INT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_role      TEXT := current_user_role();
  v_branch    INT;
  v_ttl       INT;
  v_nonce     TEXT;
  v_session   RECORD;
BEGIN
  IF v_role NOT IN ('teacher', 'branch_admin', 'super_admin') THEN
    RETURN json_build_object('success', false, 'reason', 'not_authorized');
  END IF;
  IF p_scope_type NOT IN ('student', 'course', 'branch', 'classroom_ble') THEN
    RETURN json_build_object('success', false, 'reason', 'invalid_scope');
  END IF;

  -- branch_admin / teacher may only host sessions for their own branch —
  -- same branch-scoping pattern used throughout this schema.
  v_branch := p_branch_id;
  IF v_role != 'super_admin' THEN
    v_branch := current_user_branch();
  END IF;

  SELECT qr_ttl_seconds INTO v_ttl FROM public.attendance_settings WHERE id = 1;
  v_nonce := encode(gen_random_bytes(12), 'hex');

  INSERT INTO public.attendance_qr_sessions (
    scope_type, scope_student_id, scope_course_id, scope_branch_id,
    starts_at, expires_at, qr_nonce, qr_payload_hash, created_by, is_active
  ) VALUES (
    p_scope_type, p_student_id, p_course_id, v_branch,
    now(), now() + make_interval(secs => COALESCE(p_duration_seconds, v_ttl, 45)),
    v_nonce,
    encode(digest(v_nonce || now()::text, 'sha256'), 'hex'),
    auth.uid(), true
  )
  RETURNING * INTO v_session;

  RETURN json_build_object(
    'success', true,
    'session_id', v_session.id,
    'qr_nonce', v_session.qr_nonce,
    'expires_at', v_session.expires_at
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_attendance_session(TEXT, INT, INT, INT, INT) TO authenticated;

-- Host: end a session early (e.g. class ended before the QR's natural
-- expiry) — separate from the UPDATE RLS policy so the client only ever
-- needs one clean call instead of a raw table PATCH.
CREATE OR REPLACE FUNCTION public.end_attendance_session(p_session_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.attendance_qr_sessions
  SET is_active = false
  WHERE id = p_session_id
    AND (created_by = auth.uid() OR current_user_role() = 'super_admin');

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'reason', 'not_found_or_not_authorized');
  END IF;
  RETURN json_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.end_attendance_session(UUID) TO authenticated;

-- ── Agent: check in to a session ─────────────────────────────────────
-- BLE is a supplementary signal only — a missing or weak RSSI reading
-- never blocks a legitimate scan (mobile BLE scans can genuinely take a
-- few seconds to return a first result, and treating "no reading yet" as
-- a hard failure would produce false rejections for real students). It
-- only nudges confidence_score, which is recorded for later staff review
-- rather than used to silently auto-reject anyone.
CREATE OR REPLACE FUNCTION public.checkin_attendance(
  p_session_id UUID,
  p_qr_nonce TEXT,
  p_ble_rssi INT DEFAULT NULL,
  p_teacher_device_id TEXT DEFAULT NULL,
  p_student_device_id TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_student_id   INT := current_student_id();
  v_session      RECORD;
  v_student      RECORD;
  v_min_rssi     INT;
  v_proximity_on BOOLEAN;
  v_confidence   NUMERIC := 50;
  v_source       TEXT := 'qr';
  v_today        DATE := CURRENT_DATE;
BEGIN
  IF v_student_id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'not_a_student');
  END IF;

  SELECT * INTO v_session FROM public.attendance_qr_sessions WHERE id = p_session_id;
  IF NOT FOUND OR v_session.qr_nonce != p_qr_nonce THEN
    RETURN json_build_object('success', false, 'reason', 'invalid_session');
  END IF;
  IF NOT v_session.is_active OR now() < v_session.starts_at OR now() > v_session.expires_at THEN
    RETURN json_build_object('success', false, 'reason', 'session_expired');
  END IF;

  SELECT id, course_id, branch_id INTO v_student FROM public.students WHERE id = v_student_id;

  -- Scope check: does this student actually belong to what the session
  -- was scoped to? classroom_ble sessions have no further restriction.
  CASE v_session.scope_type
    WHEN 'student' THEN
      IF v_session.scope_student_id != v_student_id THEN
        RETURN json_build_object('success', false, 'reason', 'not_in_scope');
      END IF;
    WHEN 'course' THEN
      IF v_session.scope_course_id IS DISTINCT FROM v_student.course_id THEN
        RETURN json_build_object('success', false, 'reason', 'not_in_scope');
      END IF;
    WHEN 'branch' THEN
      IF v_session.scope_branch_id IS DISTINCT FROM v_student.branch_id THEN
        RETURN json_build_object('success', false, 'reason', 'not_in_scope');
      END IF;
    ELSE
      NULL; -- classroom_ble: open to anyone who scans within the window
  END CASE;

  -- Idempotent: scanning twice in one day just confirms, doesn't double-count.
  IF EXISTS (
    SELECT 1 FROM public.attendance_events
    WHERE student_id = v_student_id
      AND qr_session_id = p_session_id
      AND status = 'present'
  ) THEN
    RETURN json_build_object('success', true, 'already_checked_in', true);
  END IF;

  SELECT min_ble_rssi, proximity_required INTO v_min_rssi, v_proximity_on
  FROM public.attendance_settings WHERE id = 1;

  IF p_ble_rssi IS NOT NULL THEN
    v_source := 'hybrid';
    -- Stronger (less negative) than the configured floor -> high
    -- confidence; weaker -> still accepted, just logged with lower
    -- confidence for staff to see, never auto-rejected.
    v_confidence := CASE WHEN p_ble_rssi >= v_min_rssi THEN 90 ELSE 60 END;
  ELSIF v_proximity_on THEN
    v_confidence := 55; -- no BLE reading available; QR alone still accepted
  END IF;

  -- student_attendance is the table BOTH the student's own "My
  -- Attendance" screen and the teacher's manual roll-call actually
  -- read/write — this upsert is what makes a QR/BLE check-in visible
  -- everywhere else in the app, not just in this feature's own tables.
  INSERT INTO public.student_attendance (student_id, branch_id, attendance_date, status, marked_by)
  VALUES (v_student_id, v_student.branch_id, v_today, 'P', v_session.created_by)
  ON CONFLICT (student_id, attendance_date)
  DO UPDATE SET status = 'P', marked_by = v_session.created_by;

  INSERT INTO public.attendance_ble_events (
    qr_session_id, teacher_device_id, student_device_id, student_id,
    rssi, is_valid, reason
  ) VALUES (
    p_session_id, COALESCE(p_teacher_device_id, 'unknown'), COALESCE(p_student_device_id, 'unknown'),
    v_student_id, p_ble_rssi, (p_ble_rssi IS NOT NULL AND p_ble_rssi >= v_min_rssi),
    CASE WHEN p_ble_rssi IS NULL THEN 'no_ble_reading' ELSE NULL END
  );

  INSERT INTO public.attendance_events (
    qr_session_id, student_id, source, status,
    teacher_device_id, student_device_id, ble_rssi, confidence_score
  ) VALUES (
    p_session_id, v_student_id, v_source, 'present',
    p_teacher_device_id, p_student_device_id, p_ble_rssi, v_confidence
  );

  RETURN json_build_object('success', true, 'confidence_score', v_confidence);
END;
$$;

GRANT EXECUTE ON FUNCTION public.checkin_attendance(UUID, TEXT, INT, TEXT, TEXT) TO authenticated;
