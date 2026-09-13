-- 20240301000008_grading_reliability_and_security.sql
--
-- Fixes from a second review pass:
--   1. grade_attempt had NO caller-authorization check at all — any
--      authenticated user could grade/force-close any other student's
--      in-progress attempt by calling the RPC with their attempt id.
--   2. grade_attempt's deadline check meant a legitimate submission that
--      hit a network blip right at the cutoff could never be graded again,
--      even though every answer had been saved on time. The anti-cheat
--      boundary belongs on the WRITE path (can you still save new answers
--      after time is up?), not on grading itself (grading what was
--      already legitimately saved is always safe, whenever it happens).
--   3. Nothing ever grades an attempt nobody returns to close out — added
--      a sweep function for attempts stuck in_progress well past their
--      window (e.g. the student's app crashed and was never reopened).
--   4. The countdown shown to the student was computed from the device's
--      clock, so a skewed device clock could trigger a premature
--      client-side auto-submit. Added a server-computed alternative.

-- ── 1 & 2: grade_attempt — add authorization, drop the hard deadline block ──
CREATE OR REPLACE FUNCTION public.grade_attempt(p_attempt_id INT, p_reason TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_student_id    INT;
  v_paper_id            INT;
  v_marks_correct       NUMERIC(6,2);
  v_marks_wrong         NUMERIC(6,2);
  v_marks_unanswered    NUMERIC(6,2);
  v_paper_total_marks   INT;
  v_paper_pass_marks    INT;
  v_dynamic_total       NUMERIC(8,2);
  v_pass_ratio          NUMERIC(6,4);
  v_effective_pass      NUMERIC(8,2);
  v_unanswered_marks    NUMERIC(8,2);
  v_score               NUMERIC(8,2);
BEGIN
  SELECT a.student_id, s.paper_id, s.marks_correct, s.marks_wrong, s.marks_unanswered
    INTO v_owner_student_id, v_paper_id, v_marks_correct, v_marks_wrong, v_marks_unanswered
  FROM public.attempts a
  JOIN public.schedules s ON s.id = a.schedule_id
  WHERE a.id = p_attempt_id;

  IF v_owner_student_id IS NULL THEN
    RAISE EXCEPTION 'Attempt not found';
  END IF;

  -- Only the attempt's own student, or an admin, may trigger grading.
  -- Without this, any authenticated user could grade — and thereby
  -- force-close — any other student's still in-progress attempt.
  IF NOT (
    current_user_role() IN ('super_admin', 'branch_admin')
    OR v_owner_student_id = current_student_id()
  ) THEN
    RAISE EXCEPTION 'Not authorized to grade this attempt';
  END IF;

  -- No deadline check here on purpose. The real anti-cheat boundary is on
  -- attempt_answers writes below — a student can no longer save a *new*
  -- answer once their window has closed, so grading late (a network blip
  -- at submit time, or the sweep function below picking up an abandoned
  -- attempt) only ever grades what was legitimately saved during the
  -- actual exam window, whenever that grading call happens to run.

  SELECT total_marks, pass_marks INTO v_paper_total_marks, v_paper_pass_marks
  FROM public.papers WHERE id = v_paper_id;

  UPDATE public.attempt_answers aa
  SET is_correct = (qb.correct_option = aa.selected_option),
      marks_awarded = qb.marks * CASE
        WHEN aa.selected_option IS NULL THEN v_marks_unanswered
        WHEN qb.correct_option = aa.selected_option THEN v_marks_correct
        ELSE v_marks_wrong
      END
  FROM public.question_bank qb
  WHERE aa.question_id = qb.id AND aa.attempt_id = p_attempt_id;

  SELECT COALESCE(SUM(qb.marks), 0) INTO v_unanswered_marks
  FROM public.paper_questions pq
  JOIN public.question_bank qb ON qb.id = pq.question_id
  WHERE pq.paper_id = v_paper_id
    AND pq.question_id NOT IN (
      SELECT question_id FROM public.attempt_answers WHERE attempt_id = p_attempt_id
    );

  SELECT COALESCE(SUM(marks_awarded), 0) INTO v_score
  FROM public.attempt_answers WHERE attempt_id = p_attempt_id;
  v_score := v_score + v_unanswered_marks * v_marks_unanswered;

  SELECT COALESCE(SUM(qb.marks), 0) INTO v_dynamic_total
  FROM public.paper_questions pq JOIN public.question_bank qb ON qb.id = pq.question_id
  WHERE pq.paper_id = v_paper_id;

  v_pass_ratio := CASE WHEN COALESCE(v_paper_total_marks, 0) > 0
    THEN v_paper_pass_marks::NUMERIC / v_paper_total_marks
    ELSE 0.33
  END;
  v_effective_pass := v_dynamic_total * v_pass_ratio;

  UPDATE public.attempts
  SET score = v_score,
      total_marks = v_dynamic_total,
      result = CASE WHEN v_score >= v_effective_pass THEN 'pass' ELSE 'fail' END,
      status = 'submitted',
      submitted_at = COALESCE(submitted_at, now()),
      auto_submit_reason = COALESCE(p_reason, auto_submit_reason)
  WHERE id = p_attempt_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.grade_attempt(INT, TEXT) TO authenticated;

-- ── 3. attempts.auto_submit_reason — visible on the admin roster screen ────
ALTER TABLE public.attempts ADD COLUMN IF NOT EXISTS auto_submit_reason TEXT;

-- ── 4. The real anti-cheat boundary: can't save new answers once the
-- attempt's window has closed. This is what actually stops "background
-- the app and answer at leisure for hours" — not a check on grading.
DROP POLICY IF EXISTS "attempt_answers_self_write" ON public.attempt_answers;
CREATE POLICY "attempt_answers_self_write" ON public.attempt_answers
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.attempts a
      JOIN public.schedules s ON s.id = a.schedule_id
      JOIN public.papers p ON p.id = s.paper_id
      WHERE a.id = attempt_answers.attempt_id
        AND a.student_id = current_student_id()
        AND a.status = 'in_progress'
        AND now() <= a.started_at + make_interval(mins => p.duration_minutes) + INTERVAL '3 minutes'
    )
  );

DROP POLICY IF EXISTS "attempt_answers_self_update" ON public.attempt_answers;
CREATE POLICY "attempt_answers_self_update" ON public.attempt_answers
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.attempts a
      JOIN public.schedules s ON s.id = a.schedule_id
      JOIN public.papers p ON p.id = s.paper_id
      WHERE a.id = attempt_answers.attempt_id
        AND a.student_id = current_student_id()
        AND a.status = 'in_progress'
        AND now() <= a.started_at + make_interval(mins => p.duration_minutes) + INTERVAL '3 minutes'
    )
  );

-- ── 5. Server-computed remaining time — the countdown the student sees no
-- longer depends on their device's clock being correct.
CREATE OR REPLACE FUNCTION public.attempt_remaining_seconds(p_attempt_id INT)
RETURNS INT
LANGUAGE sql
STABLE
AS $$
  SELECT GREATEST(
    0,
    (p.duration_minutes * 60) - EXTRACT(EPOCH FROM (now() - a.started_at))::INT
  )
  FROM public.attempts a
  JOIN public.schedules s ON s.id = a.schedule_id
  JOIN public.papers p ON p.id = s.paper_id
  WHERE a.id = p_attempt_id;
$$;

GRANT EXECUTE ON FUNCTION public.attempt_remaining_seconds(INT) TO authenticated;

-- ── 6. Sweep function for attempts nobody ever returns to close out (app
-- crashed, uninstalled, etc). Grades whatever was legitimately saved,
-- exactly like a normal on-time submission would. This needs a scheduler
-- to actually run periodically — Supabase doesn't wire that up for you
-- automatically. Either enable the pg_cron extension and schedule it
-- (`SELECT cron.schedule('grade-expired-attempts', '*/5 * * * *',
-- 'SELECT public.grade_expired_attempts()')`), or call it from any
-- existing periodic job (e.g. a scheduled Edge Function) you already run.
CREATE OR REPLACE FUNCTION public.grade_expired_attempts()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_attempt RECORD;
  v_count INT := 0;
BEGIN
  FOR v_attempt IN
    SELECT a.id
    FROM public.attempts a
    JOIN public.schedules s ON s.id = a.schedule_id
    JOIN public.papers p ON p.id = s.paper_id
    WHERE a.status = 'in_progress'
      AND now() > a.started_at + make_interval(mins => p.duration_minutes) + INTERVAL '10 minutes'
  LOOP
    PERFORM public.grade_attempt(v_attempt.id, 'auto_swept_expired');
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.grade_expired_attempts() TO service_role;
