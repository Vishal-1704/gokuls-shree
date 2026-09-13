-- 20240301000009_super_admin_approval_gates.sql
--
-- Locks down three things per explicit product rule: only super_admin may
-- delete a student or approve one, and only super_admin may author/edit/
-- delete MCQ questions. branch_admin can still ADD a student (forced
-- pending) and can still SCHEDULE tests using already-published papers,
-- but cannot approve, delete, or touch question content.

-- ════════════════════════════════════════════════════════════════════════
-- 1. delete_student_full — super_admin only (closes the gap where this
-- SECURITY DEFINER function bypassed students_delete's USING (false)
-- deny-all with no replacement check at all).
-- ════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION delete_student_full(p_student_id INT)
RETURNS VOID AS $$
DECLARE
  v_profile_id UUID;
BEGIN
  IF current_user_role() != 'super_admin' THEN
    RAISE EXCEPTION 'Only super admin can delete a student';
  END IF;

  SELECT profile_id INTO v_profile_id FROM students WHERE id = p_student_id;

  DELETE FROM students WHERE id = p_student_id;

  IF v_profile_id IS NOT NULL THEN
    DELETE FROM profiles WHERE id = v_profile_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ════════════════════════════════════════════════════════════════════════
-- 2 & 3. students — branch_admin can add (forced pending) and edit, but
-- can never set their own approval. Enforced with triggers rather than
-- RLS WITH CHECK because "don't let this role change this one column,
-- but still allow editing everything else" needs to compare OLD vs NEW,
-- which a row policy alone can't express.
-- ════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.enforce_student_status_gate()
RETURNS TRIGGER AS $$
BEGIN
  IF current_user_role() = 'branch_admin' THEN
    IF TG_OP = 'INSERT' THEN
      NEW.status := 0; -- always lands pending, regardless of what was sent
    ELSIF TG_OP = 'UPDATE' THEN
      NEW.status := OLD.status; -- can edit anything else, never the approval flag
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS students_status_gate ON students;
CREATE TRIGGER students_status_gate
  BEFORE INSERT OR UPDATE ON students
  FOR EACH ROW EXECUTE FUNCTION public.enforce_student_status_gate();

-- ════════════════════════════════════════════════════════════════════════
-- 4. question_bank / paper_questions — super_admin only, branch_admin
-- loses all access (was previously grouped with super_admin in
-- 20240301000007's admin_all policies).
-- ════════════════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "question_bank_admin_all" ON public.question_bank;
CREATE POLICY "question_bank_admin_all" ON public.question_bank
  FOR ALL USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

DROP POLICY IF EXISTS "paper_questions_admin_all" ON public.paper_questions;
CREATE POLICY "paper_questions_admin_all" ON public.paper_questions
  FOR ALL USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

-- ════════════════════════════════════════════════════════════════════════
-- 5. papers — authoring (create/edit/delete/publish) is super_admin only;
-- branch_admin keeps read-only access to published papers so their
-- scheduler's paper picker still works — scheduling is still their job,
-- authoring content is not.
-- ════════════════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "papers_admin_all" ON public.papers;
CREATE POLICY "papers_super_admin_all" ON public.papers
  FOR ALL USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

DROP POLICY IF EXISTS "papers_branch_admin_read" ON public.papers;
CREATE POLICY "papers_branch_admin_read" ON public.papers
  FOR SELECT USING (
    current_user_role() = 'branch_admin' AND status = 'published'
  );
