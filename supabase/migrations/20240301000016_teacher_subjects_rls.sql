-- ============================================================
-- teacher_subjects has never had RLS enabled since it was created
-- (master_schema.sql:1039) — any authenticated user could read or write
-- any teacher's subject assignments via the REST API. Close that gap and
-- bring it in line with every sibling table (employees, subjects, ...).
-- ============================================================

ALTER TABLE public.teacher_subjects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "teacher_subjects_select" ON public.teacher_subjects;
CREATE POLICY "teacher_subjects_select" ON public.teacher_subjects FOR SELECT USING (
  teacher_id = current_profile_id()
  OR current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);

DROP POLICY IF EXISTS "teacher_subjects_write_admin" ON public.teacher_subjects;
CREATE POLICY "teacher_subjects_write_admin" ON public.teacher_subjects FOR ALL USING (
  current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);
