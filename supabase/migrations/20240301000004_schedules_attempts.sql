-- 20240301000004_schedules_attempts.sql
--
-- Scheduling + attempt tracking for the MCQ test/exam module.
-- Replaces exam_schedules/exam_assignments/exam_sessions/exam_answers,
-- which were built against a `paper_sets` table the paper-authoring flow
-- never actually wrote to (see 20240301000003's header comment). Those old
-- tables are left in place, untouched, in case any historical rows matter —
-- nothing here drops them.
--
-- Also patches `exam_results` (the manual subject-wise marksheet table used
-- by admin_repository.dart's addStudentResult/getStudentResults) with the
-- columns that code already assumes exist. It was missing them entirely,
-- so manual result entry — and now MCQ result publishing, which reuses the
-- same table — could not work.

CREATE TABLE IF NOT EXISTS public.schedules (
  id                        SERIAL PRIMARY KEY,
  paper_id                  INT NOT NULL REFERENCES public.papers(id) ON DELETE CASCADE,
  title                     TEXT NOT NULL,
  start_at                  TIMESTAMPTZ NOT NULL,
  end_at                    TIMESTAMPTZ,
  publish_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  assignment_type           TEXT NOT NULL CHECK (assignment_type IN ('student', 'course', 'batch', 'branch')),
  assignment_value          TEXT NOT NULL,
  max_attempts              INT NOT NULL DEFAULT 1,
  negative_marking_enabled  BOOLEAN NOT NULL DEFAULT false,
  marks_correct             NUMERIC(6,2) NOT NULL DEFAULT 1,
  marks_wrong               NUMERIC(6,2) NOT NULL DEFAULT 0,
  marks_unanswered          NUMERIC(6,2) NOT NULL DEFAULT 0,
  status                    TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('published', 'closed')),
  created_by                UUID REFERENCES public.profiles(id),
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.schedule_roster (
  id            SERIAL PRIMARY KEY,
  schedule_id   INT NOT NULL REFERENCES public.schedules(id) ON DELETE CASCADE,
  student_id    INT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (schedule_id, student_id)
);

CREATE TABLE IF NOT EXISTS public.attempts (
  id            SERIAL PRIMARY KEY,
  schedule_id   INT NOT NULL REFERENCES public.schedules(id) ON DELETE CASCADE,
  student_id    INT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  attempt_no    INT NOT NULL DEFAULT 1,
  started_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  submitted_at  TIMESTAMPTZ,
  status        TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'submitted')),
  score         NUMERIC(8,2),
  total_marks   NUMERIC(8,2),
  result        TEXT CHECK (result IN ('pass', 'fail')),
  UNIQUE (schedule_id, student_id, attempt_no)
);

CREATE TABLE IF NOT EXISTS public.attempt_answers (
  id                SERIAL PRIMARY KEY,
  attempt_id        INT NOT NULL REFERENCES public.attempts(id) ON DELETE CASCADE,
  question_id       INT NOT NULL REFERENCES public.question_bank(id) ON DELETE CASCADE,
  selected_option   SMALLINT CHECK (selected_option BETWEEN 1 AND 4),
  is_correct        BOOLEAN,
  marks_awarded     NUMERIC(6,2),
  answered_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (attempt_id, question_id)
);

-- ── Roster materialization ───────────────────────────────────────────────
-- Snapshots who is expected to take a schedule at the moment it's created,
-- expanding course/batch/branch into concrete students. This is what makes
-- "who was absent" answerable later — a live re-query would silently change
-- the answer if a student's batch/branch changes afterwards.
CREATE OR REPLACE FUNCTION public.materialize_schedule_roster(p_schedule_id INT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_type  TEXT;
  v_value TEXT;
BEGIN
  SELECT assignment_type, assignment_value INTO v_type, v_value
  FROM public.schedules WHERE id = p_schedule_id;

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

GRANT EXECUTE ON FUNCTION public.materialize_schedule_roster(INT) TO authenticated;

-- ── Grading ──────────────────────────────────────────────────────────────
-- Runs server-side, in one transaction, when a student submits. Replaces
-- the previous behaviour where the Flutter app computed the score itself
-- in memory (and never saved it) using the correct answers it had shipped
-- to the client in the questions payload.
CREATE OR REPLACE FUNCTION public.grade_attempt(p_attempt_id INT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_schedule_id         INT;
  v_paper_id            INT;
  v_marks_correct       NUMERIC(6,2);
  v_marks_wrong         NUMERIC(6,2);
  v_marks_unanswered    NUMERIC(6,2);
  v_paper_total_marks   INT;
  v_paper_pass_marks    INT;
  v_total_questions     INT;
  v_answered            INT;
  v_score               NUMERIC(8,2);
BEGIN
  SELECT a.schedule_id, s.paper_id, s.marks_correct, s.marks_wrong, s.marks_unanswered
    INTO v_schedule_id, v_paper_id, v_marks_correct, v_marks_wrong, v_marks_unanswered
  FROM public.attempts a
  JOIN public.schedules s ON s.id = a.schedule_id
  WHERE a.id = p_attempt_id;

  SELECT total_marks, pass_marks INTO v_paper_total_marks, v_paper_pass_marks
  FROM public.papers WHERE id = v_paper_id;

  -- Grade each submitted answer against the bank's correct option.
  -- marks_correct/marks_wrong are multipliers on that question's own `marks`
  -- weight (default 1 / 0), not flat per-question values — a 2-mark
  -- question loses twice as much on a wrong answer as a 1-mark one, and a
  -- harder question authored with a higher `marks` value counts for more
  -- when answered correctly.
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
      total_marks = COALESCE(v_paper_total_marks, 0),
      result = CASE WHEN v_score >= COALESCE(v_paper_pass_marks, 0) THEN 'pass' ELSE 'fail' END,
      status = 'submitted'
  WHERE id = p_attempt_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.grade_attempt(INT) TO authenticated;

-- ── exam_results: add the columns manual + published-MCQ results need ────
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS subject_name TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS exam_name TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS marks_obtained NUMERIC(8,2);
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS total_marks NUMERIC(8,2);
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS grade TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS calculated_at TIMESTAMPTZ DEFAULT NOW();
