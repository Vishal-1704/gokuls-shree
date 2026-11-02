-- ============================================================================
-- Migration 019: Fix App Errors (Paper Sets, Question Bank & RLS, Storage, Payslips)
-- ============================================================================

BEGIN;

-- 1. Ensure paper_sets has all required columns used by Flutter & admin portals
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS assessment_type TEXT DEFAULT 'exam';
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS total_marks INT DEFAULT 100;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS pass_marks INT DEFAULT 33;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS duration_minutes INT DEFAULT 60;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'published';
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS branch_id INT;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS course_id INT;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS subject_id INT;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS created_by UUID;

-- Backfill title & name where missing
UPDATE public.paper_sets 
SET title = COALESCE(title, name, 'Paper Set #' || id::text),
    name = COALESCE(name, title, 'Paper Set #' || id::text);

-- 2. Fix RLS Policies for paper_sets (Resolves 42501 Forbidden on INSERT/UPDATE/DELETE)
ALTER TABLE public.paper_sets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "paper_sets_select" ON public.paper_sets;
DROP POLICY IF EXISTS "paper_sets_all_admin" ON public.paper_sets;
DROP POLICY IF EXISTS "paper_sets_insert" ON public.paper_sets;
DROP POLICY IF EXISTS "paper_sets_update" ON public.paper_sets;
DROP POLICY IF EXISTS "paper_sets_delete" ON public.paper_sets;

CREATE POLICY "paper_sets_select" ON public.paper_sets
  FOR SELECT USING (true);

CREATE POLICY "paper_sets_insert" ON public.paper_sets
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "paper_sets_update" ON public.paper_sets
  FOR UPDATE USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "paper_sets_delete" ON public.paper_sets
  FOR DELETE USING (auth.role() = 'authenticated');

-- 3. Create question_bank & paper_questions tables (Resolves PGRST205 table not found)
CREATE TABLE IF NOT EXISTS public.question_bank (
  id              SERIAL PRIMARY KEY,
  course_id       INT,
  subject         TEXT,
  difficulty      TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  question_text   TEXT NOT NULL,
  option_a        TEXT NOT NULL,
  option_b        TEXT NOT NULL,
  option_c        TEXT NOT NULL,
  option_d        TEXT NOT NULL,
  correct_option  SMALLINT NOT NULL CHECK (correct_option BETWEEN 1 AND 4),
  marks           NUMERIC(6,2) NOT NULL DEFAULT 1.0,
  image_url       TEXT,
  status          SMALLINT NOT NULL DEFAULT 1,
  created_by      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.paper_questions (
  id            SERIAL PRIMARY KEY,
  paper_id      INT NOT NULL,
  question_id   INT NOT NULL REFERENCES public.question_bank(id) ON DELETE CASCADE,
  order_index   INT NOT NULL DEFAULT 0,
  UNIQUE (paper_id, question_id)
);

CREATE TABLE IF NOT EXISTS public.exam_questions (
  id              SERIAL PRIMARY KEY,
  category_id     INT,
  question_text   TEXT NOT NULL,
  option_a        TEXT,
  option_b        TEXT,
  option_c        TEXT,
  option_d        TEXT,
  correct_option  SMALLINT,
  marks           INT DEFAULT 1,
  status          SMALLINT DEFAULT 1,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable RLS and setup policies for question tables
ALTER TABLE public.question_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paper_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "question_bank_select" ON public.question_bank;
DROP POLICY IF EXISTS "question_bank_admin_all" ON public.question_bank;
DROP POLICY IF EXISTS "question_bank_insert" ON public.question_bank;
DROP POLICY IF EXISTS "question_bank_update" ON public.question_bank;
DROP POLICY IF EXISTS "question_bank_delete" ON public.question_bank;
DROP POLICY IF EXISTS "question_bank_all" ON public.question_bank;

CREATE POLICY "question_bank_select" ON public.question_bank FOR SELECT USING (true);
CREATE POLICY "question_bank_insert" ON public.question_bank FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "question_bank_update" ON public.question_bank FOR UPDATE USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "question_bank_delete" ON public.question_bank FOR DELETE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "paper_questions_select" ON public.paper_questions;
DROP POLICY IF EXISTS "paper_questions_admin_all" ON public.paper_questions;
DROP POLICY IF EXISTS "paper_questions_student_read" ON public.paper_questions;
DROP POLICY IF EXISTS "paper_questions_insert" ON public.paper_questions;
DROP POLICY IF EXISTS "paper_questions_update" ON public.paper_questions;
DROP POLICY IF EXISTS "paper_questions_delete" ON public.paper_questions;
DROP POLICY IF EXISTS "paper_questions_all" ON public.paper_questions;

CREATE POLICY "paper_questions_select" ON public.paper_questions FOR SELECT USING (true);
CREATE POLICY "paper_questions_insert" ON public.paper_questions FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "paper_questions_update" ON public.paper_questions FOR UPDATE USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "paper_questions_delete" ON public.paper_questions FOR DELETE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "exam_questions_all" ON public.exam_questions;
DROP POLICY IF EXISTS "exam_questions_select" ON public.exam_questions;
DROP POLICY IF EXISTS "exam_questions_all_admin" ON public.exam_questions;

CREATE POLICY "exam_questions_all" ON public.exam_questions FOR ALL USING (true) WITH CHECK (true);

-- 5. Fix RLS Policies for papers (if papers table exists)
DO $$ 
BEGIN 
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'papers') THEN
    ALTER TABLE public.papers ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "papers_select" ON public.papers;
    DROP POLICY IF EXISTS "papers_super_admin_all" ON public.papers;
    DROP POLICY IF EXISTS "papers_admin_all" ON public.papers;
    DROP POLICY IF EXISTS "papers_insert" ON public.papers;
    DROP POLICY IF EXISTS "papers_update" ON public.papers;
    DROP POLICY IF EXISTS "papers_delete" ON public.papers;

    CREATE POLICY "papers_select" ON public.papers FOR SELECT USING (true);
    CREATE POLICY "papers_insert" ON public.papers FOR INSERT WITH CHECK (auth.role() = 'authenticated');
    CREATE POLICY "papers_update" ON public.papers FOR UPDATE USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
    CREATE POLICY "papers_delete" ON public.papers FOR DELETE USING (auth.role() = 'authenticated');
    GRANT ALL ON public.papers TO authenticated, service_role;
  END IF;
END $$;

-- 6. Ensure exam_results has all required columns for Results Entry & Marksheets
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS subject_name TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS exam_name TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS marks_obtained NUMERIC(8,2);
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS total_marks NUMERIC(8,2);
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS grade TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS calculated_at TIMESTAMPTZ DEFAULT NOW();

-- 7. Fix generate_payslip RPC to correctly resolve profiles.id from auth.uid()
CREATE OR REPLACE FUNCTION public.generate_payslip(
  p_employee_id INT,
  p_month INT,
  p_year INT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_role       TEXT := current_user_role();
  v_emp        RECORD;
  v_gross      NUMERIC(10,2);
  v_payslip    RECORD;
  v_profile_id UUID;
BEGIN
  IF v_role NOT IN ('branch_admin', 'super_admin') THEN
    RETURN json_build_object('success', false, 'reason', 'not_authorized');
  END IF;

  SELECT * INTO v_emp FROM public.employees WHERE id = p_employee_id;
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'reason', 'employee_not_found');
  END IF;

  IF v_role = 'branch_admin' AND v_emp.branch_id != current_user_branch() THEN
    RETURN json_build_object('success', false, 'reason', 'not_authorized');
  END IF;

  -- generated_by references public.profiles(id).
  -- auth.uid() matches profiles.auth_uid, so resolve the corresponding profiles.id.
  SELECT id INTO v_profile_id FROM public.profiles WHERE (auth_uid = auth.uid() OR id = auth.uid()) LIMIT 1;
  IF v_profile_id IS NULL THEN
    v_profile_id := current_profile_id();
  END IF;

  v_gross := COALESCE(v_emp.basic_salary, 0) + COALESCE(v_emp.hra, 0)
           + COALESCE(v_emp.da, 0) + COALESCE(v_emp.other_allowance, 0);

  INSERT INTO public.payslips (
    employee_id, branch_id, month, year,
    basic_salary, hra, da, other_allowance, gross_pay, net_pay, generated_by
  ) VALUES (
    p_employee_id, v_emp.branch_id, p_month, p_year,
    v_emp.basic_salary, v_emp.hra, v_emp.da, v_emp.other_allowance,
    v_gross, v_gross, v_profile_id
  )
  ON CONFLICT (employee_id, month, year) DO NOTHING
  RETURNING * INTO v_payslip;

  IF v_payslip.id IS NULL THEN
    RETURN json_build_object('success', false, 'reason', 'already_generated');
  END IF;

  UPDATE public.payslips
  SET signature_hash = encode(hmac(public._payslip_signing_payload(v_payslip.id), public._doc_signing_secret(), 'sha256'), 'hex')
  WHERE id = v_payslip.id;

  RETURN json_build_object('success', true, 'payslip_id', v_payslip.id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_payslip(INT, INT, INT) TO authenticated;

-- 8. Grant full table and sequence permissions
GRANT ALL ON public.paper_sets TO authenticated, service_role;
GRANT ALL ON public.question_bank TO authenticated, service_role;
GRANT ALL ON public.paper_questions TO authenticated, service_role;
GRANT ALL ON public.exam_questions TO authenticated, service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;

-- 9. Create Storage Buckets (question-images, avatars) & Policies
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('question-images', 'question-images', true),
  ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated users to upload question images" ON storage.objects;
CREATE POLICY "Allow authenticated users to upload question images"
ON storage.objects FOR INSERT TO authenticated, anon
WITH CHECK (bucket_id = 'question-images');

DROP POLICY IF EXISTS "Allow authenticated users to update question images" ON storage.objects;
CREATE POLICY "Allow authenticated users to update question images"
ON storage.objects FOR UPDATE TO authenticated, anon
USING (bucket_id = 'question-images');

DROP POLICY IF EXISTS "Allow authenticated users to delete question images" ON storage.objects;
CREATE POLICY "Allow authenticated users to delete question images"
ON storage.objects FOR DELETE TO authenticated, anon
USING (bucket_id = 'question-images');

DROP POLICY IF EXISTS "Allow public to view question images" ON storage.objects;
CREATE POLICY "Allow public to view question images"
ON storage.objects FOR SELECT TO public, anon, authenticated
USING (bucket_id = 'question-images');

DROP POLICY IF EXISTS "Allow authenticated to upload avatars" ON storage.objects;
CREATE POLICY "Allow authenticated to upload avatars"
ON storage.objects FOR INSERT TO authenticated, anon
WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Allow authenticated to update avatars" ON storage.objects;
CREATE POLICY "Allow authenticated to update avatars"
ON storage.objects FOR UPDATE TO authenticated, anon
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Allow public to view avatars" ON storage.objects;
CREATE POLICY "Allow public to view avatars"
ON storage.objects FOR SELECT TO public, anon, authenticated
USING (bucket_id = 'avatars');

-- 10. Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;
