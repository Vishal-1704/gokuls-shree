-- 20240301000021_employee_erp.sql
--
-- Employee ERP: CTC changes (super-admin approved only), monthly payslips
-- (admin-generated, signed at generation), and finishing the already
-- half-built experience-certificate flow (real request insert, real
-- approve-via-trigger, signing, RLS — none of which existed before this).
--
-- Reuses the document-signing mechanism from 20240301000014 verbatim
-- (_doc_signing_secret(), HMAC-SHA256 over a canonical payload, signed by
-- a trigger the moment status becomes 1) rather than inventing a second
-- one, and the same self/branch/super_admin RLS shape used everywhere
-- else in this schema (current_profile_id() / current_user_branch() /
-- current_user_role()).

-- ══════════════════════════════════════════════════════════════════════
-- 1. employee_salary_revisions — CTC changes require super_admin approval
-- ══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.employee_salary_revisions (
  id                SERIAL PRIMARY KEY,
  employee_id       INT NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  branch_id         INT REFERENCES public.branches(id) ON DELETE SET NULL,
  basic_salary      NUMERIC(10,2) NOT NULL,
  hra               NUMERIC(10,2) DEFAULT 0,
  da                NUMERIC(10,2) DEFAULT 0,
  other_allowance   NUMERIC(10,2) DEFAULT 0,
  effective_month   INT NOT NULL CHECK (effective_month BETWEEN 1 AND 12),
  effective_year    INT NOT NULL,
  status            SMALLINT DEFAULT 0, -- 0=pending, 1=approved, 2=rejected
  proposed_by       UUID REFERENCES public.profiles(id),
  approved_by       UUID REFERENCES public.profiles(id),
  approved_at       TIMESTAMPTZ,
  remarks           TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_salary_revisions_employee ON public.employee_salary_revisions(employee_id);
CREATE INDEX IF NOT EXISTS idx_salary_revisions_status ON public.employee_salary_revisions(status);

-- Approval copies the proposed figures onto the live employees row — this
-- is the ONLY path that changes employees.basic_salary/hra/da/
-- other_allowance going forward; admin_add_staff_screen's direct-write
-- path for these four fields should stop being used once the Dart side
-- ships (existing direct-write capability is left alone here — a data
-- migration/RLS tightening on employees itself is a separate, larger
-- change and not required for this feature to work correctly).
CREATE OR REPLACE FUNCTION public._apply_salary_revision_on_approve()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.status = 1 AND OLD.status IS DISTINCT FROM 1 THEN
    UPDATE public.employees
    SET basic_salary = NEW.basic_salary,
        hra = NEW.hra,
        da = NEW.da,
        other_allowance = NEW.other_allowance
    WHERE id = NEW.employee_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_apply_salary_revision ON public.employee_salary_revisions;
CREATE TRIGGER trg_apply_salary_revision
  AFTER UPDATE ON public.employee_salary_revisions
  FOR EACH ROW
  EXECUTE FUNCTION public._apply_salary_revision_on_approve();

ALTER TABLE public.employee_salary_revisions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "salary_revisions_select" ON public.employee_salary_revisions;
CREATE POLICY "salary_revisions_select" ON public.employee_salary_revisions FOR SELECT USING (
  employee_id IN (SELECT id FROM public.employees WHERE profile_id = current_profile_id())
  OR current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);

DROP POLICY IF EXISTS "salary_revisions_insert" ON public.employee_salary_revisions;
CREATE POLICY "salary_revisions_insert" ON public.employee_salary_revisions FOR INSERT WITH CHECK (
  current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);

-- Only super_admin may move a revision to approved (1) or rejected (2);
-- branch_admin can still update their own pending rows for corrections
-- before anyone has acted on them (status must stay 0 in that case).
DROP POLICY IF EXISTS "salary_revisions_update" ON public.employee_salary_revisions;
CREATE POLICY "salary_revisions_update" ON public.employee_salary_revisions FOR UPDATE USING (
  current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
) WITH CHECK (
  current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch() AND status = 0)
);

-- ══════════════════════════════════════════════════════════════════════
-- 2. payslips — generated (not proposed), signed immediately at generation
-- ══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.payslips (
  id                SERIAL PRIMARY KEY,
  employee_id       INT NOT NULL REFERENCES public.employees(id) ON DELETE CASCADE,
  branch_id         INT REFERENCES public.branches(id) ON DELETE SET NULL,
  month             INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  year              INT NOT NULL,
  basic_salary      NUMERIC(10,2) NOT NULL,
  hra               NUMERIC(10,2) DEFAULT 0,
  da                NUMERIC(10,2) DEFAULT 0,
  other_allowance   NUMERIC(10,2) DEFAULT 0,
  gross_pay         NUMERIC(10,2) NOT NULL,
  net_pay           NUMERIC(10,2) NOT NULL,
  signature_hash    TEXT,
  generated_by      UUID REFERENCES public.profiles(id),
  generated_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (employee_id, month, year)
);

CREATE INDEX IF NOT EXISTS idx_payslips_employee ON public.payslips(employee_id);

CREATE OR REPLACE FUNCTION public._payslip_signing_payload(p_id INT)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT concat_ws('|',
    p.id, p.employee_id, p.month, p.year,
    p.basic_salary::text, p.hra::text, p.da::text, p.other_allowance::text,
    p.gross_pay::text, p.net_pay::text
  )
  FROM public.payslips p WHERE p.id = p_id;
$$;

ALTER TABLE public.payslips ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "payslips_select" ON public.payslips;
CREATE POLICY "payslips_select" ON public.payslips FOR SELECT USING (
  employee_id IN (SELECT id FROM public.employees WHERE profile_id = current_profile_id())
  OR current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);
-- No client INSERT/UPDATE policy at all — generate_payslip (SECURITY
-- DEFINER) below is the only way a row can ever be written.

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
  v_role     TEXT := current_user_role();
  v_emp      RECORD;
  v_gross    NUMERIC(10,2);
  v_payslip  RECORD;
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

  v_gross := COALESCE(v_emp.basic_salary, 0) + COALESCE(v_emp.hra, 0)
           + COALESCE(v_emp.da, 0) + COALESCE(v_emp.other_allowance, 0);

  INSERT INTO public.payslips (
    employee_id, branch_id, month, year,
    basic_salary, hra, da, other_allowance, gross_pay, net_pay, generated_by
  ) VALUES (
    p_employee_id, v_emp.branch_id, p_month, p_year,
    v_emp.basic_salary, v_emp.hra, v_emp.da, v_emp.other_allowance,
    v_gross, v_gross, auth.uid()
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

-- ══════════════════════════════════════════════════════════════════════
-- 3. experience_certificates — finish the already-half-built flow:
-- signing + RLS (neither existed before this), same status convention
-- already used by the pending-list/approve code in admin_repository.dart.
-- ══════════════════════════════════════════════════════════════════════
ALTER TABLE public.experience_certificates ADD COLUMN IF NOT EXISTS signature_hash TEXT;

CREATE OR REPLACE FUNCTION public._experience_cert_signing_payload(p_id INT)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT concat_ws('|', e.id, e.employee_id, e.branch_id, e.issue_date::text)
  FROM public.experience_certificates e WHERE e.id = p_id;
$$;

CREATE OR REPLACE FUNCTION public._sign_experience_cert_on_approve()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.status = 1 AND (OLD.status IS DISTINCT FROM 1 OR NEW.signature_hash IS NULL) THEN
    IF NEW.issue_date IS NULL THEN
      NEW.issue_date := NOW();
    END IF;
    NEW.signature_hash := encode(
      hmac(public._experience_cert_signing_payload(NEW.id), public._doc_signing_secret(), 'sha256'),
      'hex'
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sign_experience_cert ON public.experience_certificates;
CREATE TRIGGER trg_sign_experience_cert
  BEFORE UPDATE ON public.experience_certificates
  FOR EACH ROW
  EXECUTE FUNCTION public._sign_experience_cert_on_approve();

ALTER TABLE public.experience_certificates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "experience_certs_select" ON public.experience_certificates;
CREATE POLICY "experience_certs_select" ON public.experience_certificates FOR SELECT USING (
  employee_id IN (SELECT id FROM public.employees WHERE profile_id = current_profile_id())
  OR current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);

-- An employee may only request their own certificate, and only as pending.
DROP POLICY IF EXISTS "experience_certs_insert_self" ON public.experience_certificates;
CREATE POLICY "experience_certs_insert_self" ON public.experience_certificates FOR INSERT WITH CHECK (
  status = 0
  AND employee_id IN (SELECT id FROM public.employees WHERE profile_id = current_profile_id())
);

DROP POLICY IF EXISTS "experience_certs_update_admin" ON public.experience_certificates;
CREATE POLICY "experience_certs_update_admin" ON public.experience_certificates FOR UPDATE USING (
  current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
) WITH CHECK (
  current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);

-- ══════════════════════════════════════════════════════════════════════
-- 4. Extend verify_document_signature with 'payslip' and
-- 'experience_certificate' branches — CREATE OR REPLACE, safe to run
-- even though 20240301000014 already created this function.
-- ══════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.verify_document_signature(p_type TEXT, p_id INT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_stored_hash TEXT;
  v_status      SMALLINT;
  v_expected    TEXT;
BEGIN
  IF p_type = 'marksheet' THEN
    SELECT signature_hash, status INTO v_stored_hash, v_status
    FROM public.marksheets WHERE id = p_id;
  ELSIF p_type = 'certificate' THEN
    SELECT signature_hash, status INTO v_stored_hash, v_status
    FROM public.certificates WHERE id = p_id;
  ELSIF p_type = 'payslip' THEN
    SELECT signature_hash, 1 INTO v_stored_hash, v_status
    FROM public.payslips WHERE id = p_id;
  ELSIF p_type = 'experience_certificate' THEN
    SELECT signature_hash, status INTO v_stored_hash, v_status
    FROM public.experience_certificates WHERE id = p_id;
  ELSE
    RETURN json_build_object('result', 'not_found');
  END IF;

  IF NOT FOUND OR v_status IS NULL THEN
    RETURN json_build_object('result', 'not_found');
  END IF;

  IF v_status != 1 OR v_stored_hash IS NULL THEN
    RETURN json_build_object('result', 'unsigned');
  END IF;

  v_expected := encode(
    hmac(
      CASE p_type
        WHEN 'marksheet' THEN public._marksheet_signing_payload(p_id)
        WHEN 'certificate' THEN public._certificate_signing_payload(p_id)
        WHEN 'payslip' THEN public._payslip_signing_payload(p_id)
        ELSE public._experience_cert_signing_payload(p_id)
      END,
      public._doc_signing_secret(),
      'sha256'
    ),
    'hex'
  );

  IF v_expected = v_stored_hash THEN
    RETURN json_build_object('result', 'valid');
  ELSE
    RETURN json_build_object('result', 'tampered');
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_document_signature(TEXT, INT) TO anon, authenticated;
