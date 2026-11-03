-- Migration: Fix public.papers view and grade_attempt function
-- Resolves: 'relation "public.papers" does not exist'

-- 1. Create a view so any query referencing "public.papers" resolves to "public.paper_sets"
CREATE OR REPLACE VIEW public.papers AS 
SELECT * FROM public.paper_sets;

GRANT SELECT ON public.papers TO authenticated, anon, service_role;

-- 2. Update grade_attempt to use paper_sets directly and avoid missing table errors
CREATE OR REPLACE FUNCTION public.grade_attempt(p_attempt_id INT, p_reason TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_owner_student_id  INT;
  v_paper_id          INT;
  v_marks_correct     NUMERIC(6,2);
  v_marks_wrong       NUMERIC(6,2);
  v_marks_unanswered  NUMERIC(6,2);
  v_paper_total_marks INT;
  v_paper_pass_marks  INT;
  v_total_questions   INT;
  v_answered          INT;
  v_score             NUMERIC(8,2);
BEGIN
  SELECT a.student_id, s.paper_id, s.marks_correct, s.marks_wrong, s.marks_unanswered
    INTO v_owner_student_id, v_paper_id, v_marks_correct, v_marks_wrong, v_marks_unanswered
  FROM public.attempts a
  JOIN public.schedules s ON s.id = a.schedule_id
  WHERE a.id = p_attempt_id;

  IF v_owner_student_id IS NULL THEN
    RAISE EXCEPTION 'Attempt % not found', p_attempt_id;
  END IF;

  SELECT total_marks, pass_marks INTO v_paper_total_marks, v_paper_pass_marks
  FROM public.paper_sets WHERE id = v_paper_id;

  UPDATE public.attempt_answers aa
  SET is_correct = (qb.correct_option = aa.selected_option),
      marks_awarded = qb.marks * CASE
        WHEN qb.correct_option = aa.selected_option THEN v_marks_correct
        ELSE v_marks_wrong
      END
  FROM public.question_bank qb
  WHERE aa.question_id = qb.id AND aa.attempt_id = p_attempt_id;

  SELECT COUNT(*) INTO v_total_questions FROM public.paper_questions WHERE paper_id = v_paper_id;
  SELECT COUNT(*) INTO v_answered FROM public.attempt_answers WHERE attempt_id = p_attempt_id;

  SELECT COALESCE(SUM(marks_awarded), 0) INTO v_score
  FROM public.attempt_answers WHERE attempt_id = p_attempt_id;

  v_score := v_score + GREATEST(v_total_questions - v_answered, 0)
    * (SELECT COALESCE(AVG(marks), 1) FROM public.paper_questions pq JOIN public.question_bank qb2 ON qb2.id = pq.question_id WHERE pq.paper_id = v_paper_id)
    * v_marks_unanswered;

  UPDATE public.attempts
  SET score = v_score,
      total_marks = COALESCE(v_paper_total_marks, 100),
      result = CASE WHEN v_score >= COALESCE(v_paper_pass_marks, 33) THEN 'pass' ELSE 'fail' END,
      status = 'submitted',
      submitted_at = NOW()
  WHERE id = p_attempt_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.grade_attempt(INT, TEXT) TO authenticated, anon, service_role;
