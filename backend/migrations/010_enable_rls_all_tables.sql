-- ============================================================
-- 010_enable_rls_all_tables.sql
-- Enables RLS on all 25 remaining tables in the public schema.
-- ============================================================

-- Helper function to get current user's profile ID (UUID)
CREATE OR REPLACE FUNCTION current_profile_id()
RETURNS UUID AS $$
DECLARE
  p_id UUID;
BEGIN
  SELECT id INTO p_id FROM profiles WHERE auth_uid = auth.uid() AND status = 1 LIMIT 1;
  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ==========================================
-- 1. PUBLIC REFERENCE TABLES (Public Read, Admin Write)
-- ==========================================

-- courses
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "courses_select_public" ON public.courses;
CREATE POLICY "courses_select_public" ON public.courses FOR SELECT USING (status = 1);
DROP POLICY IF EXISTS "courses_all_admin" ON public.courses;
CREATE POLICY "courses_all_admin" ON public.courses FOR ALL USING (current_user_role() = 'super_admin');

-- subjects
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "subjects_select_public" ON public.subjects;
CREATE POLICY "subjects_select_public" ON public.subjects FOR SELECT USING (status = 1);
DROP POLICY IF EXISTS "subjects_all_admin" ON public.subjects;
CREATE POLICY "subjects_all_admin" ON public.subjects FOR ALL USING (current_user_role() = 'super_admin');

-- states
ALTER TABLE public.states ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "states_select_public" ON public.states;
CREATE POLICY "states_select_public" ON public.states FOR SELECT USING (true);
DROP POLICY IF EXISTS "states_all_admin" ON public.states;
CREATE POLICY "states_all_admin" ON public.states FOR ALL USING (current_user_role() = 'super_admin');

-- districts
ALTER TABLE public.districts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "districts_select_public" ON public.districts;
CREATE POLICY "districts_select_public" ON public.districts FOR SELECT USING (true);
DROP POLICY IF EXISTS "districts_all_admin" ON public.districts;
CREATE POLICY "districts_all_admin" ON public.districts FOR ALL USING (current_user_role() = 'super_admin');

-- notices
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notices_select_public" ON public.notices;
CREATE POLICY "notices_select_public" ON public.notices FOR SELECT USING (is_public = true OR auth.role() = 'authenticated');
DROP POLICY IF EXISTS "notices_all_admin" ON public.notices;
CREATE POLICY "notices_all_admin" ON public.notices FOR ALL USING (current_user_role() IN ('super_admin', 'branch_admin'));

-- downloads
ALTER TABLE public.downloads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "downloads_select_public" ON public.downloads;
CREATE POLICY "downloads_select_public" ON public.downloads FOR SELECT USING (is_public = true OR auth.role() = 'authenticated');
DROP POLICY IF EXISTS "downloads_all_admin" ON public.downloads;
CREATE POLICY "downloads_all_admin" ON public.downloads FOR ALL USING (current_user_role() IN ('super_admin', 'branch_admin'));


-- ==========================================
-- 2. ADMIN/STAFF MANAGED TABLES (Staff Only)
-- ==========================================

-- employees
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "employees_select" ON public.employees;
CREATE POLICY "employees_select" ON public.employees FOR SELECT USING (
  profile_id = current_profile_id() 
  OR current_user_role() = 'super_admin' 
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);
DROP POLICY IF EXISTS "employees_all_admin" ON public.employees;
CREATE POLICY "employees_all_admin" ON public.employees FOR ALL USING (
  current_user_role() = 'super_admin' 
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);

-- employee_attendance
ALTER TABLE public.employee_attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "employee_attendance_select" ON public.employee_attendance;
CREATE POLICY "employee_attendance_select" ON public.employee_attendance FOR SELECT USING (
  employee_id IN (SELECT id FROM employees WHERE profile_id = current_profile_id())
  OR current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);
DROP POLICY IF EXISTS "employee_attendance_all_admin" ON public.employee_attendance;
CREATE POLICY "employee_attendance_all_admin" ON public.employee_attendance FOR ALL USING (
  current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);

-- salary_advances
ALTER TABLE public.salary_advances ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "salary_advances_select" ON public.salary_advances;
CREATE POLICY "salary_advances_select" ON public.salary_advances FOR SELECT USING (
  employee_id IN (SELECT id FROM employees WHERE profile_id = current_profile_id())
  OR current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);
DROP POLICY IF EXISTS "salary_advances_all_admin" ON public.salary_advances;
CREATE POLICY "salary_advances_all_admin" ON public.salary_advances FOR ALL USING (
  current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);


-- ==========================================
-- 3. STUDENT PERSONAL TABLES (Student/Admin/Staff Only)
-- ==========================================

-- admit_cards
ALTER TABLE public.admit_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "admit_cards_select" ON public.admit_cards;
CREATE POLICY "admit_cards_select" ON public.admit_cards FOR SELECT USING (
  student_id = current_student_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "admit_cards_all_admin" ON public.admit_cards;
CREATE POLICY "admit_cards_all_admin" ON public.admit_cards FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- id_cards
ALTER TABLE public.id_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "id_cards_select" ON public.id_cards;
CREATE POLICY "id_cards_select" ON public.id_cards FOR SELECT USING (
  student_id = current_student_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "id_cards_all_admin" ON public.id_cards;
CREATE POLICY "id_cards_all_admin" ON public.id_cards FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- issued_documents
ALTER TABLE public.issued_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "issued_documents_select" ON public.issued_documents;
CREATE POLICY "issued_documents_select" ON public.issued_documents FOR SELECT USING (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "issued_documents_all_admin" ON public.issued_documents;
CREATE POLICY "issued_documents_all_admin" ON public.issued_documents FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);


-- ==========================================
-- 4. EXAM MODULE TABLES (Controlled Access)
-- ==========================================

-- exam_categories
ALTER TABLE public.exam_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_categories_select" ON public.exam_categories;
CREATE POLICY "exam_categories_select" ON public.exam_categories FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "exam_categories_all_admin" ON public.exam_categories;
CREATE POLICY "exam_categories_all_admin" ON public.exam_categories FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_questions
ALTER TABLE public.exam_questions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_questions_select" ON public.exam_questions;
CREATE POLICY "exam_questions_select" ON public.exam_questions FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "exam_questions_all_admin" ON public.exam_questions;
CREATE POLICY "exam_questions_all_admin" ON public.exam_questions FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_results
ALTER TABLE public.exam_results ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_results_select" ON public.exam_results;
CREATE POLICY "exam_results_select" ON public.exam_results FOR SELECT USING (
  student_id = current_student_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "exam_results_all_admin" ON public.exam_results;
CREATE POLICY "exam_results_all_admin" ON public.exam_results FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- paper_sets
ALTER TABLE public.paper_sets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "paper_sets_select" ON public.paper_sets;
CREATE POLICY "paper_sets_select" ON public.paper_sets FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "paper_sets_all_admin" ON public.paper_sets;
CREATE POLICY "paper_sets_all_admin" ON public.paper_sets FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- questions
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "questions_select" ON public.questions;
CREATE POLICY "questions_select" ON public.questions FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "questions_all_admin" ON public.questions;
CREATE POLICY "questions_all_admin" ON public.questions FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_sessions
ALTER TABLE public.exam_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_sessions_select" ON public.exam_sessions;
CREATE POLICY "exam_sessions_select" ON public.exam_sessions FOR SELECT USING (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "exam_sessions_insert" ON public.exam_sessions;
CREATE POLICY "exam_sessions_insert" ON public.exam_sessions FOR INSERT WITH CHECK (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin')
);
DROP POLICY IF EXISTS "exam_sessions_update" ON public.exam_sessions;
CREATE POLICY "exam_sessions_update" ON public.exam_sessions FOR UPDATE USING (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin')
);
DROP POLICY IF EXISTS "exam_sessions_delete" ON public.exam_sessions;
CREATE POLICY "exam_sessions_delete" ON public.exam_sessions FOR DELETE USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_answers
ALTER TABLE public.exam_answers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_answers_select" ON public.exam_answers;
CREATE POLICY "exam_answers_select" ON public.exam_answers FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM exam_sessions 
    WHERE id = session_id 
      AND (student_id = current_profile_id() OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher'))
  )
);
DROP POLICY IF EXISTS "exam_answers_insert" ON public.exam_answers;
CREATE POLICY "exam_answers_insert" ON public.exam_answers FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM exam_sessions 
    WHERE id = session_id AND student_id = current_profile_id()
  ) OR current_user_role() IN ('super_admin', 'branch_admin')
);
DROP POLICY IF EXISTS "exam_answers_update" ON public.exam_answers;
CREATE POLICY "exam_answers_update" ON public.exam_answers FOR UPDATE USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);
DROP POLICY IF EXISTS "exam_answers_delete" ON public.exam_answers;
CREATE POLICY "exam_answers_delete" ON public.exam_answers FOR DELETE USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_schedules
ALTER TABLE public.exam_schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_schedules_select" ON public.exam_schedules;
CREATE POLICY "exam_schedules_select" ON public.exam_schedules FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "exam_schedules_all_admin" ON public.exam_schedules;
CREATE POLICY "exam_schedules_all_admin" ON public.exam_schedules FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_assignments
ALTER TABLE public.exam_assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_assignments_select" ON public.exam_assignments;
CREATE POLICY "exam_assignments_select" ON public.exam_assignments FOR SELECT USING (
  student_id = current_profile_id() OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "exam_assignments_all_admin" ON public.exam_assignments;
CREATE POLICY "exam_assignments_all_admin" ON public.exam_assignments FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);


-- ==========================================
-- 5. ATTENDANCE & PROXIMITY TABLES (Proximity Engine)
-- ==========================================

-- attendance_settings
ALTER TABLE public.attendance_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "attendance_settings_select" ON public.attendance_settings;
CREATE POLICY "attendance_settings_select" ON public.attendance_settings FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "attendance_settings_all_admin" ON public.attendance_settings;
CREATE POLICY "attendance_settings_all_admin" ON public.attendance_settings FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- attendance_qr_sessions
ALTER TABLE public.attendance_qr_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "attendance_qr_sessions_select" ON public.attendance_qr_sessions;
CREATE POLICY "attendance_qr_sessions_select" ON public.attendance_qr_sessions FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "attendance_qr_sessions_all_admin" ON public.attendance_qr_sessions;
CREATE POLICY "attendance_qr_sessions_all_admin" ON public.attendance_qr_sessions FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);

-- attendance_ble_events
ALTER TABLE public.attendance_ble_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "attendance_ble_events_insert" ON public.attendance_ble_events;
CREATE POLICY "attendance_ble_events_insert" ON public.attendance_ble_events FOR INSERT WITH CHECK (
  student_id = current_profile_id()
);
DROP POLICY IF EXISTS "attendance_ble_events_select" ON public.attendance_ble_events;
CREATE POLICY "attendance_ble_events_select" ON public.attendance_ble_events FOR SELECT USING (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "attendance_ble_events_all_admin" ON public.attendance_ble_events;
CREATE POLICY "attendance_ble_events_all_admin" ON public.attendance_ble_events FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- attendance_events
ALTER TABLE public.attendance_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "attendance_events_insert" ON public.attendance_events;
CREATE POLICY "attendance_events_insert" ON public.attendance_events FOR INSERT WITH CHECK (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "attendance_events_select" ON public.attendance_events;
CREATE POLICY "attendance_events_select" ON public.attendance_events FOR SELECT USING (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "attendance_events_all_admin" ON public.attendance_events;
CREATE POLICY "attendance_events_all_admin" ON public.attendance_events FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);
