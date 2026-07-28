-- ============================================================
-- 011_recreate_views_security_invoker.sql
-- Drops the 4 views and recreates them as security invoker views.
-- This resolves the "Security Definer View" advisor warnings.
-- ============================================================

-- 1. Drop existing views to clear relation options
DROP VIEW IF EXISTS public.student_enrollments CASCADE;
DROP VIEW IF EXISTS public.payment_transactions CASCADE;
DROP VIEW IF EXISTS public.v_attendance_daily CASCADE;
DROP VIEW IF EXISTS public.v_student_visible_exams CASCADE;

-- 2. Recreate student_enrollments with security_invoker = on
CREATE VIEW public.student_enrollments WITH (security_invoker = on) AS
SELECT 
  id AS enrollment_id,
  profile_id AS student_id,
  course_id,
  created_at AS enrolled_at,
  status
FROM public.students;

-- 3. Recreate payment_transactions with security_invoker = on
CREATE VIEW public.payment_transactions WITH (security_invoker = on) AS
SELECT 
  fp.id,
  fp.legacy_id,
  s.profile_id AS student_id,
  fp.branch_id,
  fp.course_id,
  fp.receipt_no,
  fp.payment_date,
  fp.amount,
  fp.payment_mode,
  fp.description,
  fp.created_at
FROM public.fee_payments fp
JOIN public.students s ON fp.student_id = s.id;

-- 4. Recreate v_attendance_daily with security_invoker = on
CREATE VIEW public.v_attendance_daily WITH (security_invoker = on) AS
SELECT
  student_id,
  date_trunc('day', marked_at) AS attendance_day,
  COUNT(*) FILTER (WHERE status = 'present') AS present_count,
  COUNT(*) FILTER (WHERE status = 'rejected') AS rejected_count,
  MAX(confidence_score) AS max_confidence
FROM public.attendance_events
GROUP BY student_id, date_trunc('day', marked_at);

-- 5. Recreate v_student_visible_exams with security_invoker = on
CREATE VIEW public.v_student_visible_exams WITH (security_invoker = on) AS
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
