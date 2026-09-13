-- 20240301000010_security_hardening.sql
--
-- Comprehensive security hardening migration.
-- Safe to run in any order: exam-module sections are wrapped in DO blocks
-- that check table existence first and skip gracefully if the exam
-- migrations (003-008) have not been applied yet.

-- ================================================================
-- FIX 1 + 2: delete_student_full - soft-delete + auth.users purge
-- Hard DELETE crashes with FK 23503 errors on real data.
-- Soft-delete preserves fees/attendance/exam records.
-- auth.users purge removes the zombie account.
-- ================================================================

ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

CREATE OR REPLACE FUNCTION public.delete_student_full(p_student_id INT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_profile_id UUID;
  v_auth_uid   UUID;
BEGIN
  IF current_user_role() != 'super_admin' THEN
    RAISE EXCEPTION 'Only super admin can delete a student';
  END IF;

  SELECT s.profile_id, p.auth_uid
    INTO v_profile_id, v_auth_uid
  FROM public.students s
  LEFT JOIN public.profiles p ON p.id = s.profile_id
  WHERE s.id = p_student_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Student % not found', p_student_id;
  END IF;

  -- status = -2 is the deleted sentinel (0=pending, 1=active).
  -- Preserves all FK child rows (fees/attendance/exams).
  UPDATE public.students
  SET status     = -2,
      deleted_at = now(),
      updated_at = now()
  WHERE id = p_student_id;

  IF v_profile_id IS NOT NULL THEN
    UPDATE public.profiles
    SET status     = 0,
        updated_at = now()
    WHERE id = v_profile_id;
  END IF;

  -- Purge auth.users so phone/email is free for re-registration.
  IF v_auth_uid IS NOT NULL THEN
    DELETE FROM auth.users WHERE id = v_auth_uid;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_student_full(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_student_full(INT) TO authenticated;

-- ================================================================
-- FIX 3: enforce_student_status_gate - inverted role check
-- Previous only caught branch_admin. Students/anon could self-approve.
-- ================================================================

CREATE OR REPLACE FUNCTION public.enforce_student_status_gate()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF current_user_role() IS DISTINCT FROM 'super_admin' THEN
    IF TG_OP = 'INSERT' THEN
      NEW.status := 0;
    ELSIF TG_OP = 'UPDATE' THEN
      NEW.status := OLD.status;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
-- Trigger already exists from migration 009; function replace is sufficient.

-- ================================================================
-- FIX 4 + 5 + BONUS: Exam module policies
-- Guarded: only applied when exam tables exist (migrations 003-008).
-- ================================================================

DO $$
DECLARE
  v_papers_exist BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'papers'
  ) INTO v_papers_exist;

  IF NOT v_papers_exist THEN
    RAISE NOTICE 'Exam tables not found - skipping exam policy fixes. Run migrations 003-008 first, then re-run this migration.';
    RETURN;
  END IF;

  -- ----------------------------------------------------------------
  -- FIX 4: Gate papers/questions behind schedule start_at
  -- ----------------------------------------------------------------

  DROP POLICY IF EXISTS "papers_student_read" ON public.papers;
  EXECUTE $pol$
    CREATE POLICY "papers_student_read" ON public.papers
      FOR SELECT USING (
        status = 'published'
        AND EXISTS (
          SELECT 1 FROM public.schedules s
          JOIN public.schedule_roster sr ON sr.schedule_id = s.id
          WHERE s.paper_id = papers.id
            AND sr.student_id = current_student_id()
            AND now() >= s.start_at
        )
      )
  $pol$;

  DROP POLICY IF EXISTS "paper_questions_student_read" ON public.paper_questions;
  EXECUTE $pol$
    CREATE POLICY "paper_questions_student_read" ON public.paper_questions
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM public.schedules s
          JOIN public.schedule_roster sr ON sr.schedule_id = s.id
          WHERE s.paper_id = paper_questions.paper_id
            AND sr.student_id = current_student_id()
            AND now() >= s.start_at
        )
      )
  $pol$;

  -- Rebuild question_bank_public view with start_at gate
  DROP VIEW IF EXISTS public.question_bank_public;
  EXECUTE $vw$
    CREATE VIEW public.question_bank_public AS
    SELECT
      qb.id,
      qb.question_text,
      qb.option_a,
      qb.option_b,
      qb.option_c,
      qb.option_d,
      qb.image_url,
      qb.marks
    FROM public.question_bank qb
    WHERE EXISTS (
      SELECT 1 FROM public.paper_questions pq
      JOIN public.schedules s ON s.paper_id = pq.paper_id
      JOIN public.schedule_roster sr ON sr.schedule_id = s.id
      WHERE pq.question_id = qb.id
        AND sr.student_id = current_student_id()
        AND now() >= s.start_at
    )
  $vw$;
  GRANT SELECT ON public.question_bank_public TO authenticated;

  -- ----------------------------------------------------------------
  -- FIX 5a: papers_branch_admin_read - scope to own branch
  -- ----------------------------------------------------------------

  DROP POLICY IF EXISTS "papers_branch_admin_read" ON public.papers;
  EXECUTE $pol$
    CREATE POLICY "papers_branch_admin_read" ON public.papers
      FOR SELECT USING (
        current_user_role() = 'branch_admin'
        AND status = 'published'
        AND (
          branch_id IS NULL
          OR branch_id = current_user_branch()
        )
      )
  $pol$;

  -- ----------------------------------------------------------------
  -- FIX 5b: schedules - split into super_admin + scoped branch_admin
  -- ----------------------------------------------------------------

  DROP POLICY IF EXISTS "schedules_admin_all"            ON public.schedules;
  DROP POLICY IF EXISTS "schedules_super_admin_all"      ON public.schedules;
  DROP POLICY IF EXISTS "schedules_branch_admin_scoped"  ON public.schedules;

  EXECUTE $pol$
    CREATE POLICY "schedules_super_admin_all" ON public.schedules
      FOR ALL
      USING  (current_user_role() = 'super_admin')
      WITH CHECK (current_user_role() = 'super_admin')
  $pol$;

  EXECUTE $pol$
    CREATE POLICY "schedules_branch_admin_scoped" ON public.schedules
      FOR ALL
      USING (
        current_user_role() = 'branch_admin'
        AND EXISTS (
          SELECT 1 FROM public.papers p
          WHERE p.id = schedules.paper_id
            AND (p.branch_id IS NULL OR p.branch_id = current_user_branch())
        )
      )
      WITH CHECK (
        current_user_role() = 'branch_admin'
        AND EXISTS (
          SELECT 1 FROM public.papers p
          WHERE p.id = schedules.paper_id
            AND (p.branch_id IS NULL OR p.branch_id = current_user_branch())
        )
      )
  $pol$;

  -- ----------------------------------------------------------------
  -- FIX 5c: schedule_roster - scope to own branch
  -- ----------------------------------------------------------------

  DROP POLICY IF EXISTS "schedule_roster_admin_all"             ON public.schedule_roster;
  DROP POLICY IF EXISTS "schedule_roster_super_admin_all"       ON public.schedule_roster;
  DROP POLICY IF EXISTS "schedule_roster_branch_admin_scoped"   ON public.schedule_roster;

  EXECUTE $pol$
    CREATE POLICY "schedule_roster_super_admin_all" ON public.schedule_roster
      FOR ALL
      USING  (current_user_role() = 'super_admin')
      WITH CHECK (current_user_role() = 'super_admin')
  $pol$;

  EXECUTE $pol$
    CREATE POLICY "schedule_roster_branch_admin_scoped" ON public.schedule_roster
      FOR ALL
      USING (
        current_user_role() = 'branch_admin'
        AND EXISTS (
          SELECT 1 FROM public.schedules s
          JOIN public.papers p ON p.id = s.paper_id
          WHERE s.id = schedule_roster.schedule_id
            AND (p.branch_id IS NULL OR p.branch_id = current_user_branch())
        )
      )
      WITH CHECK (
        current_user_role() = 'branch_admin'
        AND EXISTS (
          SELECT 1 FROM public.schedules s
          JOIN public.papers p ON p.id = s.paper_id
          WHERE s.id = schedule_roster.schedule_id
            AND (p.branch_id IS NULL OR p.branch_id = current_user_branch())
        )
      )
  $pol$;

  -- ----------------------------------------------------------------
  -- FIX 5d: attempts - scope to own branch
  -- ----------------------------------------------------------------

  DROP POLICY IF EXISTS "attempts_admin_all"             ON public.attempts;
  DROP POLICY IF EXISTS "attempts_super_admin_all"       ON public.attempts;
  DROP POLICY IF EXISTS "attempts_branch_admin_scoped"   ON public.attempts;

  EXECUTE $pol$
    CREATE POLICY "attempts_super_admin_all" ON public.attempts
      FOR ALL
      USING  (current_user_role() = 'super_admin')
      WITH CHECK (current_user_role() = 'super_admin')
  $pol$;

  EXECUTE $pol$
    CREATE POLICY "attempts_branch_admin_scoped" ON public.attempts
      FOR ALL
      USING (
        current_user_role() = 'branch_admin'
        AND EXISTS (
          SELECT 1 FROM public.schedules s
          JOIN public.papers p ON p.id = s.paper_id
          WHERE s.id = attempts.schedule_id
            AND (p.branch_id IS NULL OR p.branch_id = current_user_branch())
        )
      )
      WITH CHECK (
        current_user_role() = 'branch_admin'
        AND EXISTS (
          SELECT 1 FROM public.schedules s
          JOIN public.papers p ON p.id = s.paper_id
          WHERE s.id = attempts.schedule_id
            AND (p.branch_id IS NULL OR p.branch_id = current_user_branch())
        )
      )
  $pol$;

  -- ----------------------------------------------------------------
  -- FIX 5d: attempt_answers - scope to own branch
  -- ----------------------------------------------------------------

  DROP POLICY IF EXISTS "attempt_answers_admin_all"              ON public.attempt_answers;
  DROP POLICY IF EXISTS "attempt_answers_super_admin_all"        ON public.attempt_answers;
  DROP POLICY IF EXISTS "attempt_answers_branch_admin_scoped"    ON public.attempt_answers;

  EXECUTE $pol$
    CREATE POLICY "attempt_answers_super_admin_all" ON public.attempt_answers
      FOR ALL
      USING  (current_user_role() = 'super_admin')
      WITH CHECK (current_user_role() = 'super_admin')
  $pol$;

  EXECUTE $pol$
    CREATE POLICY "attempt_answers_branch_admin_scoped" ON public.attempt_answers
      FOR ALL
      USING (
        current_user_role() = 'branch_admin'
        AND EXISTS (
          SELECT 1 FROM public.attempts a
          JOIN public.schedules s ON s.id = a.schedule_id
          JOIN public.papers p ON p.id = s.paper_id
          WHERE a.id = attempt_answers.attempt_id
            AND (p.branch_id IS NULL OR p.branch_id = current_user_branch())
        )
      )
      WITH CHECK (
        current_user_role() = 'branch_admin'
        AND EXISTS (
          SELECT 1 FROM public.attempts a
          JOIN public.schedules s ON s.id = a.schedule_id
          JOIN public.papers p ON p.id = s.paper_id
          WHERE a.id = attempt_answers.attempt_id
            AND (p.branch_id IS NULL OR p.branch_id = current_user_branch())
        )
      )
  $pol$;

  -- ----------------------------------------------------------------
  -- BONUS: attempts_self_insert - gate on schedule time window
  -- ----------------------------------------------------------------

  DROP POLICY IF EXISTS "attempts_self_insert" ON public.attempts;
  EXECUTE $pol$
    CREATE POLICY "attempts_self_insert" ON public.attempts
      FOR INSERT WITH CHECK (
        student_id = current_student_id()
        AND EXISTS (
          SELECT 1 FROM public.schedule_roster sr
          WHERE sr.schedule_id = attempts.schedule_id
            AND sr.student_id  = current_student_id()
        )
        AND EXISTS (
          SELECT 1 FROM public.schedules s
          WHERE s.id     = attempts.schedule_id
            AND s.status = 'published'
            AND now()   >= s.start_at
            AND (s.end_at IS NULL OR now() <= s.end_at)
        )
      )
  $pol$;

  RAISE NOTICE 'All exam module security policies applied successfully.';
END;
$$;

-- ================================================================
-- FIX 6: grade_attempt - definitive version
-- Plpgsql function bodies are validated only at call-time, so this is
-- safe to define even when exam tables are absent.
-- auto_submit_reason added here if missing (normally from migration 008).
-- ================================================================

-- Ensure the column exists (idempotent; defined in migration 008 normally)
-- Wrapped: safe when exam tables are absent.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'attempts'
  ) THEN
    ALTER TABLE public.attempts ADD COLUMN IF NOT EXISTS auto_submit_reason TEXT;
  END IF;
END;
$$;

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
  v_dynamic_total     NUMERIC(8,2);
  v_pass_ratio        NUMERIC(6,4);
  v_effective_pass    NUMERIC(8,2);
  v_unanswered_bonus  NUMERIC(8,2);
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

  IF NOT (
    current_user_role() IN ('super_admin', 'branch_admin')
    OR v_owner_student_id = current_student_id()
  ) THEN
    RAISE EXCEPTION 'Not authorized to grade this attempt';
  END IF;

  -- No deadline check: anti-cheat is on attempt_answers INSERT/UPDATE.
  -- Blocking grading itself breaks legitimate late-network submissions.

  SELECT total_marks, pass_marks
    INTO v_paper_total_marks, v_paper_pass_marks
  FROM public.papers WHERE id = v_paper_id;

  -- marks_correct/marks_wrong/marks_unanswered are RATIOS applied to each
  -- question weight. NULL selected_option = unanswered, NOT wrong.
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

  -- Questions never opened at all (no attempt_answers row)
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

-- Grant the (INT, TEXT) overload we just created.
-- Also try to grant the old (INT) overload from migration 007/008 if it
-- exists on this database; swallow the error if it does not.
DO $$
BEGIN
  GRANT EXECUTE ON FUNCTION public.grade_attempt(INT, TEXT) TO authenticated;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'grade_attempt(INT, TEXT) not found - skipping grant';
END;
$$;
DO $$
BEGIN
  GRANT EXECUTE ON FUNCTION public.grade_attempt(INT) TO authenticated;
EXCEPTION WHEN undefined_function THEN
  NULL; -- Old (INT) overload not present; that is fine
END;
$$;

-- ================================================================
-- BONUS: materialize_schedule_roster - require admin role
-- ================================================================

CREATE OR REPLACE FUNCTION public.materialize_schedule_roster(p_schedule_id INT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_type  TEXT;
  v_value TEXT;
BEGIN
  IF current_user_role() NOT IN ('super_admin', 'branch_admin') THEN
    RAISE EXCEPTION 'Only admins can materialize schedule rosters';
  END IF;

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

DO $$
BEGIN
  GRANT EXECUTE ON FUNCTION public.materialize_schedule_roster(INT) TO authenticated;
EXCEPTION WHEN undefined_function THEN
  RAISE NOTICE 'materialize_schedule_roster(INT) not found - skipping grant';
END;
$$;
