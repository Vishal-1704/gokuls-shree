-- 20240301000007_rls_and_grading_fixes.sql
--
-- Fixes raised in code review of the exam/test module rebuild:
--   1. None of the new tables had RLS enabled — every row (including
--      question_bank.correct_option, the answer key) was readable and
--      writable by any authenticated user via the REST API directly,
--      regardless of what the Flutter app's queries asked for.
--   2. publishScheduleResults() had no idempotency — re-publishing (double
--      tap, or a genuine re-run after a makeup test) created duplicate
--      marksheet rows with no way to detect or prevent it.
--   3. grade_attempt() had three correctness bugs: unanswered-question
--      penalty used the paper's *average* question weight instead of the
--      actual skipped questions' weights; a NULL selected_option would be
--      graded as wrong instead of unanswered; and pass/fail was checked
--      against the paper's static total_marks/pass_marks even when they
--      didn't match the sum of the paper's actual question marks.
--   4. Nothing enforced the exam's time window server-side — a student
--      could background the app indefinitely and submit whenever they
--      liked, and the server had no way to tell.
--
-- Uses current_user_role()/current_user_branch()/current_student_id(),
-- the same helper functions master_schema.sql's own RLS policies use.

-- ════════════════════════════════════════════════════════════════════════
-- 1. question_bank — the answer key never leaves the database for students
-- ════════════════════════════════════════════════════════════════════════
ALTER TABLE public.question_bank ENABLE ROW LEVEL SECURITY;

-- Admins author/manage questions directly (this is the only path that ever
-- sees correct_option).
DROP POLICY IF EXISTS "question_bank_admin_all" ON public.question_bank;
CREATE POLICY "question_bank_admin_all" ON public.question_bank
  FOR ALL USING (current_user_role() IN ('super_admin', 'branch_admin'))
  WITH CHECK (current_user_role() IN ('super_admin', 'branch_admin'));

-- Students never query this table directly (see question_bank_public
-- below) — no student SELECT policy is added on purpose.

-- A view with no correct_option column at all — not hidden by convention,
-- structurally absent, so there's no query shape that can extract it here.
-- Runs as the view owner (not security_invoker), so it works even though
-- the base table's RLS above would otherwise block a student's direct
-- access; the roster check in the WHERE clause is what scopes visibility.
DROP VIEW IF EXISTS public.question_bank_public;
CREATE VIEW public.question_bank_public AS
SELECT qb.id, qb.question_text, qb.option_a, qb.option_b, qb.option_c, qb.option_d,
       qb.image_url, qb.marks
FROM public.question_bank qb
WHERE EXISTS (
  SELECT 1 FROM public.paper_questions pq
  JOIN public.schedules s ON s.paper_id = pq.paper_id
  JOIN public.schedule_roster sr ON sr.schedule_id = s.id
  WHERE pq.question_id = qb.id AND sr.student_id = current_student_id()
);

GRANT SELECT ON public.question_bank_public TO authenticated;

-- ════════════════════════════════════════════════════════════════════════
-- 2. papers
-- ════════════════════════════════════════════════════════════════════════
ALTER TABLE public.papers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "papers_admin_all" ON public.papers;
CREATE POLICY "papers_admin_all" ON public.papers
  FOR ALL USING (current_user_role() IN ('super_admin', 'branch_admin'))
  WITH CHECK (current_user_role() IN ('super_admin', 'branch_admin'));

DROP POLICY IF EXISTS "papers_student_read" ON public.papers;
CREATE POLICY "papers_student_read" ON public.papers
  FOR SELECT USING (
    status = 'published'
    AND EXISTS (
      SELECT 1 FROM public.schedules s
      JOIN public.schedule_roster sr ON sr.schedule_id = s.id
      WHERE s.paper_id = papers.id AND sr.student_id = current_student_id()
    )
  );

-- ════════════════════════════════════════════════════════════════════════
-- 3. paper_questions
-- ════════════════════════════════════════════════════════════════════════
ALTER TABLE public.paper_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "paper_questions_admin_all" ON public.paper_questions;
CREATE POLICY "paper_questions_admin_all" ON public.paper_questions
  FOR ALL USING (current_user_role() IN ('super_admin', 'branch_admin'))
  WITH CHECK (current_user_role() IN ('super_admin', 'branch_admin'));

DROP POLICY IF EXISTS "paper_questions_student_read" ON public.paper_questions;
CREATE POLICY "paper_questions_student_read" ON public.paper_questions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.schedules s
      JOIN public.schedule_roster sr ON sr.schedule_id = s.id
      WHERE s.paper_id = paper_questions.paper_id AND sr.student_id = current_student_id()
    )
  );

-- ════════════════════════════════════════════════════════════════════════
-- 4. schedules
-- ════════════════════════════════════════════════════════════════════════
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "schedules_admin_all" ON public.schedules;
CREATE POLICY "schedules_admin_all" ON public.schedules
  FOR ALL USING (current_user_role() IN ('super_admin', 'branch_admin'))
  WITH CHECK (current_user_role() IN ('super_admin', 'branch_admin'));

DROP POLICY IF EXISTS "schedules_student_read" ON public.schedules;
CREATE POLICY "schedules_student_read" ON public.schedules
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.schedule_roster sr
      WHERE sr.schedule_id = schedules.id AND sr.student_id = current_student_id()
    )
  );

-- ════════════════════════════════════════════════════════════════════════
-- 5. schedule_roster
-- ════════════════════════════════════════════════════════════════════════
ALTER TABLE public.schedule_roster ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "schedule_roster_admin_all" ON public.schedule_roster;
CREATE POLICY "schedule_roster_admin_all" ON public.schedule_roster
  FOR ALL USING (current_user_role() IN ('super_admin', 'branch_admin'))
  WITH CHECK (current_user_role() IN ('super_admin', 'branch_admin'));

DROP POLICY IF EXISTS "schedule_roster_self_read" ON public.schedule_roster;
CREATE POLICY "schedule_roster_self_read" ON public.schedule_roster
  FOR SELECT USING (student_id = current_student_id());

-- ════════════════════════════════════════════════════════════════════════
-- 6. attempts — students may create and read their own attempts, but
-- CANNOT update them. Scoring only ever happens through grade_attempt(),
-- a SECURITY DEFINER function that bypasses RLS — a student PATCHing their
-- own attempts row directly (e.g. setting score=100) is now impossible,
-- since no UPDATE policy grants them that at all.
-- ════════════════════════════════════════════════════════════════════════
ALTER TABLE public.attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "attempts_admin_all" ON public.attempts;
CREATE POLICY "attempts_admin_all" ON public.attempts
  FOR ALL USING (current_user_role() IN ('super_admin', 'branch_admin'))
  WITH CHECK (current_user_role() IN ('super_admin', 'branch_admin'));

DROP POLICY IF EXISTS "attempts_self_read" ON public.attempts;
CREATE POLICY "attempts_self_read" ON public.attempts
  FOR SELECT USING (student_id = current_student_id());

DROP POLICY IF EXISTS "attempts_self_insert" ON public.attempts;
CREATE POLICY "attempts_self_insert" ON public.attempts
  FOR INSERT WITH CHECK (
    student_id = current_student_id()
    AND EXISTS (
      SELECT 1 FROM public.schedule_roster sr
      WHERE sr.schedule_id = attempts.schedule_id AND sr.student_id = current_student_id()
    )
  );

-- ════════════════════════════════════════════════════════════════════════
-- 7. attempt_answers — students can write answers only into their own
-- still-in-progress attempt; once submitted, further writes are blocked
-- (a student can't edit answers after grading has already run).
-- ════════════════════════════════════════════════════════════════════════
ALTER TABLE public.attempt_answers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "attempt_answers_admin_all" ON public.attempt_answers;
CREATE POLICY "attempt_answers_admin_all" ON public.attempt_answers
  FOR ALL USING (current_user_role() IN ('super_admin', 'branch_admin'))
  WITH CHECK (current_user_role() IN ('super_admin', 'branch_admin'));

DROP POLICY IF EXISTS "attempt_answers_self_read" ON public.attempt_answers;
CREATE POLICY "attempt_answers_self_read" ON public.attempt_answers
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.attempts a WHERE a.id = attempt_answers.attempt_id AND a.student_id = current_student_id())
  );

DROP POLICY IF EXISTS "attempt_answers_self_write" ON public.attempt_answers;
CREATE POLICY "attempt_answers_self_write" ON public.attempt_answers
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.attempts a WHERE a.id = attempt_answers.attempt_id AND a.student_id = current_student_id() AND a.status = 'in_progress')
  );

DROP POLICY IF EXISTS "attempt_answers_self_update" ON public.attempt_answers;
CREATE POLICY "attempt_answers_self_update" ON public.attempt_answers
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.attempts a WHERE a.id = attempt_answers.attempt_id AND a.student_id = current_student_id() AND a.status = 'in_progress')
  );

-- ════════════════════════════════════════════════════════════════════════
-- 8. exam_results — idempotent publishing
-- ════════════════════════════════════════════════════════════════════════
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS schedule_id INT REFERENCES public.schedules(id);

-- Partial unique index: only constrains rows that came from the MCQ
-- publish flow (schedule_id set). Manually entered marksheet rows (no
-- schedule) are unaffected and can still have duplicates if an admin
-- genuinely enters the same subject twice — that's their call, not this
-- module's.
CREATE UNIQUE INDEX IF NOT EXISTS exam_results_student_schedule_unique
  ON public.exam_results (student_id, schedule_id)
  WHERE schedule_id IS NOT NULL;

-- ════════════════════════════════════════════════════════════════════════
-- 9. grade_attempt — corrected
-- ════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.grade_attempt(p_attempt_id INT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_started_at          TIMESTAMPTZ;
  v_paper_id            INT;
  v_marks_correct       NUMERIC(6,2);
  v_marks_wrong         NUMERIC(6,2);
  v_marks_unanswered    NUMERIC(6,2);
  v_duration_minutes    INT;
  v_end_at              TIMESTAMPTZ;
  v_paper_total_marks   INT;
  v_paper_pass_marks    INT;
  v_dynamic_total       NUMERIC(8,2);
  v_pass_ratio          NUMERIC(6,4);
  v_effective_pass      NUMERIC(8,2);
  v_unanswered_marks    NUMERIC(8,2);
  v_score               NUMERIC(8,2);
BEGIN
  SELECT a.started_at, s.paper_id, s.marks_correct, s.marks_wrong,
         s.marks_unanswered, p.duration_minutes, s.end_at
    INTO v_started_at, v_paper_id, v_marks_correct, v_marks_wrong,
         v_marks_unanswered, v_duration_minutes, v_end_at
  FROM public.attempts a
  JOIN public.schedules s ON s.id = a.schedule_id
  JOIN public.papers p ON p.id = s.paper_id
  WHERE a.id = p_attempt_id;

  -- Server-side deadline check — the client's countdown timer is only a
  -- UI convenience; this is what actually prevents an indefinitely
  -- backgrounded app from submitting hours later. A small grace window
  -- absorbs genuine network/processing lag.
  IF v_started_at IS NOT NULL
     AND now() > v_started_at + make_interval(mins => v_duration_minutes) + INTERVAL '3 minutes' THEN
    RAISE EXCEPTION 'Submission window has expired for this attempt';
  END IF;
  IF v_end_at IS NOT NULL AND now() > v_end_at + INTERVAL '3 minutes' THEN
    RAISE EXCEPTION 'This schedule''s submission window has closed';
  END IF;

  SELECT total_marks, pass_marks INTO v_paper_total_marks, v_paper_pass_marks
  FROM public.papers WHERE id = v_paper_id;

  -- Grade each submitted answer. A NULL selected_option (cleared/never
  -- chosen) is left ungraded here and folded into the unanswered bucket
  -- below instead of being scored as wrong.
  UPDATE public.attempt_answers aa
  SET is_correct = (qb.correct_option = aa.selected_option),
      marks_awarded = qb.marks * CASE
        WHEN aa.selected_option IS NULL THEN v_marks_unanswered
        WHEN qb.correct_option = aa.selected_option THEN v_marks_correct
        ELSE v_marks_wrong
      END
  FROM public.question_bank qb
  WHERE aa.question_id = qb.id AND aa.attempt_id = p_attempt_id;

  -- Marks for questions with no attempt_answers row at all (never opened) —
  -- summed from those specific questions' own weights, not the paper's
  -- average, so a skipped high-value question is penalized correctly.
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

  -- The paper's total_marks/pass_marks are set when the paper is created,
  -- often before any questions exist, so they can drift from what the
  -- questions actually sum to. Treat them as expressing a *ratio*
  -- (e.g. pass_marks=33/total_marks=100 = pass at 33%) and apply that
  -- ratio to the paper's real, current total — so a 10-question, 10-mark
  -- paper still passes at 33%, not at a literal "33 marks" that's
  -- impossible to reach.
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
      submitted_at = now()
  WHERE id = p_attempt_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.grade_attempt(INT) TO authenticated;
