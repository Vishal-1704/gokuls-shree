-- checkin_attendance wrote attendance_qr_sessions.created_by (the host's
-- raw auth.uid(), which RLS on that table correctly compares against
-- auth.uid() — don't change that) straight into
-- student_attendance.marked_by, which is REFERENCES profiles(id), not
-- auth.users(id). Same auth-uid-vs-profile-id mismatch fixed elsewhere in
-- this app; here it would surface as a foreign-key violation the first
-- time anyone actually completes a QR check-in. Fix: resolve the host's
-- profiles.id at the point of use, leave created_by's own meaning alone.

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
  v_host_profile_id UUID;
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
      NULL;
  END CASE;

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
    v_confidence := CASE WHEN p_ble_rssi >= v_min_rssi THEN 90 ELSE 60 END;
  ELSIF v_proximity_on THEN
    v_confidence := 55;
  END IF;

  -- Resolve the host's profiles.id from their auth uid — student_attendance.
  -- marked_by is a profiles(id) FK, attendance_qr_sessions.created_by is a
  -- raw auth uid; these are not the same value.
  SELECT id INTO v_host_profile_id FROM public.profiles WHERE auth_uid = v_session.created_by;

  INSERT INTO public.student_attendance (student_id, branch_id, attendance_date, status, marked_by)
  VALUES (v_student_id, v_student.branch_id, v_today, 'P', v_host_profile_id)
  ON CONFLICT (student_id, attendance_date)
  DO UPDATE SET status = 'P', marked_by = v_host_profile_id;

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
