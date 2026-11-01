-- ============================================================================
-- Migration 019: Fix App Errors (Paper Sets Schema, Exam Results & Payslip FK)
-- ============================================================================

BEGIN;

-- 1. Ensure paper_sets has all required columns used by Flutter & admin portals
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS assessment_type TEXT DEFAULT 'exam';
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS total_marks INT DEFAULT 100;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS pass_marks INT DEFAULT 33;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS duration_minutes INT DEFAULT 60;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'published';
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS branch_id INT REFERENCES public.branches(id);
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS course_id INT REFERENCES public.courses(id);
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.paper_sets ADD COLUMN IF NOT EXISTS created_by UUID;

-- Backfill title from existing name where missing
UPDATE public.paper_sets 
SET title = COALESCE(name, 'Paper Set #' || id::text) 
WHERE title IS NULL;

-- 2. Ensure exam_results has all required columns for Results Entry & Marksheets
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS subject_name TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS exam_name TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS marks_obtained NUMERIC(8,2);
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS total_marks NUMERIC(8,2);
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS grade TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.exam_results ADD COLUMN IF NOT EXISTS calculated_at TIMESTAMPTZ DEFAULT NOW();

-- 3. Fix generate_payslip RPC to correctly resolve profiles.id from auth.uid()
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
  SELECT id INTO v_profile_id FROM public.profiles WHERE auth_uid = auth.uid() LIMIT 1;
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

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

COMMIT;

