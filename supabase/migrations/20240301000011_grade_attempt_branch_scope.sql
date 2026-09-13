-- 20240301000011_grade_attempt_branch_scope.sql
--
-- 20240301000010 carefully branch-scoped every branch_admin RLS policy
-- (schedules, schedule_roster, attempts, attempt_answers all check
-- p.branch_id IS NULL OR p.branch_id = current_user_branch()) — but missed
-- the same check in two SECURITY DEFINER functions, which bypass RLS
-- entirely and must enforce it themselves:
--
--   - grade_attempt(): the authorization check allows ANY branch_admin
--     (current_user_role() IN ('super_admin','branch_admin')) with no
--     branch match, so a branch_admin from Branch A could grade/force-
--     close an in-progress attempt belonging to Branch B's student.
--   - materialize_schedule_roster(): same gap — any branch_admin can
--     re-run roster materialization for any other branch's schedule.
--
-- Both are patched here to match the branch-scoping pattern already
-- established everywhere else in migration 010.

-- Plpgsql function bodies are only validated at call-time (same as
-- migration 010's FIX 6 notes), so defining these is safe even on a
-- database where the exam tables (003-008) haven't been applied yet.

CREATE OR REPLACE FUNCTION public.grade_attempt(p_attempt_id INT, p_reason TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_student_id  INT;
  v_paper_id          INT;
  v_paper_branch_id   INT;
  v_marks_correct     NUMERIC(6,2);
  v_marks_wrong       NUMERIC(6,2);
  v_marks_unanswered  NUMERIC(6,2);
  v_paper_total_marks INT;
  v_paper_pass_marks  INT;
  v_dynamic_total     NUMERIC(8,2);
  v_pass_ratio        NUMERIC(6,4);
  v_effective_pass    NUMERIC(8,2);
  v_unanswered_bonus  NUMERIC(8,2);
  v_score             NUMERIC(8,2);
BEGIN
  SELECT a.student_id, s.paper_id, s.marks_correct, s.marks_wrong, s.marks_unanswered, p.branch_id
    INTO v_owner_student_id, v_paper_id, v_marks_correct, v_marks_wrong, v_marks_unanswered, v_paper_branch_id
  FROM public.attempts a
  JOIN public.schedules s ON s.id = a.schedule_id
  JOIN public.papers p ON p.id = s.paper_id
  WHERE a.id = p_attempt_id;

  IF v_owner_student_id IS NULL THEN
    RAISE EXCEPTION 'Attempt % not found', p_attempt_id;
  END IF;

  IF NOT (
    current_user_role() = 'super_admin'
    OR v_owner_student_id = current_student_id()
    OR (
      current_user_role() = 'branch_admin'
      AND (v_paper_branch_id IS NULL OR v_paper_branch_id = current_user_branch())
    )
  ) THEN
    RAISE EXCEPTION 'Not authorized to grade this attempt';
  END IF;

  -- No deadline check: anti-cheat is on attempt_answers INSERT/UPDATE.
  -- Blocking grading itself breaks legitimate late-network submissions.

  SELECT total_marks, pass_marks
    INTO v_paper_total_marks, v_paper_pass_marks
  FROM public.papers WHERE id = v_paper_id;

  UPDATE public.attempt_answers aa
  SET
    is_correct = CASE
      WHEN aa.selected_option IS NULL THEN NULL
      ELSE (qb.correct_option = aa.selected_option)
    END,
    marks_awarded = qb.marks * CASE
      WHEN aa.selected_option IS NULL              THEN v_marks_unanswered
      WHEN qb.correct_option = aa.selected_option  THEN v_marks_correct
      ELSE                                              v_marks_wrong
    END
  FROM public.question_bank qb
  WHERE aa.question_id = qb.id
    AND aa.attempt_id  = p_attempt_id;

  SELECT COALESCE(SUM(qb.marks * v_marks_unanswered), 0)
    INTO v_unanswered_bonus
  FROM public.paper_questions pq
  JOIN public.question_bank qb ON qb.id = pq.question_id
  WHERE pq.paper_id = v_paper_id
    AND pq.question_id NOT IN (
      SELECT question_id FROM public.attempt_answers WHERE attempt_id = p_attempt_id
    );

  SELECT COALESCE(SUM(marks_awarded), 0)
    INTO v_score
  FROM public.attempt_answers
  WHERE attempt_id = p_attempt_id;

  v_score := v_score + v_unanswered_bonus;

  SELECT COALESCE(SUM(qb.marks), 0)
    INTO v_dynamic_total
  FROM public.paper_questions pq
  JOIN public.question_bank qb ON qb.id = pq.question_id
  WHERE pq.paper_id = v_paper_id;

  v_pass_ratio := CASE
    WHEN COALESCE(v_paper_total_marks, 0) > 0
      THEN v_paper_pass_marks::NUMERIC / v_paper_total_marks
    ELSE 0.33
  END;
  v_effective_pass := v_dynamic_total * v_pass_ratio;

  UPDATE public.attempts
  SET
    score              = v_score,
    total_marks        = v_dynamic_total,
    result             = CASE WHEN v_score >= v_effective_pass THEN 'pass' ELSE 'fail' END,
    status             = 'submitted',
    submitted_at       = COALESCE(submitted_at, now()),
    auto_submit_reason = COALESCE(p_reason, auto_submit_reason)
  WHERE id = p_attempt_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.materialize_schedule_roster(p_schedule_id INT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_type       TEXT;
  v_value      TEXT;
  v_branch_id  INT;
BEGIN
  SELECT s.assignment_type, s.assignment_value, p.branch_id
    INTO v_type, v_value, v_branch_id
  FROM public.schedules s
  JOIN public.papers p ON p.id = s.paper_id
  WHERE s.id = p_schedule_id;

  IF NOT (
    current_user_role() = 'super_admin'
    OR (
      current_user_role() = 'branch_admin'
      AND (v_branch_id IS NULL OR v_branch_id = current_user_branch())
    )
  ) THEN
    RAISE EXCEPTION 'Not authorized to materialize this schedule''s roster';
  END IF;

  IF v_type = 'student' THEN
    INSERT INTO public.schedule_roster (schedule_id, student_id)
    VALUES (p_schedule_id, v_value::INT)
    ON CONFLICT DO NOTHING;
  ELSIF v_type = 'course' THEN
    INSERT INTO public.schedule_roster (schedule_id, student_id)
    SELECT p_schedule_id, id FROM public.students
    WHERE course_id = v_value::INT AND status = 1
    ON CONFLICT DO NOTHING;
  ELSIF v_type = 'batch' THEN
    INSERT INTO public.schedule_roster (schedule_id, student_id)
    SELECT p_schedule_id, id FROM public.students
    WHERE batch_id = v_value::INT AND status = 1
    ON CONFLICT DO NOTHING;
  ELSIF v_type = 'branch' THEN
    INSERT INTO public.schedule_roster (schedule_id, student_id)
    SELECT p_schedule_id, id FROM public.students
    WHERE branch_id = v_value::INT AND status = 1
    ON CONFLICT DO NOTHING;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.grade_attempt(INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.materialize_schedule_roster(INT) TO authenticated;
