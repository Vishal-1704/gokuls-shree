-- ============================================================
-- Departments lookup table, replacing free-text employees.department
-- with a real super-admin-managed list (legacy emp_dep: id/name/status).
-- employees.department (TEXT) is kept as a synced display cache so every
-- existing Dart read site keeps working unchanged.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.departments (
  id          INT PRIMARY KEY,   -- explicit ids preserved from legacy emp_dep, not SERIAL
  name        TEXT NOT NULL,
  status      SMALLINT DEFAULT 1,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.departments (id, name, status) VALUES
  (4, 'Computer Faculty', 1),
  (5, 'Office', 1),
  (6, 'Computer Teacher', 1),
  (7, 'Computer Operator', 1)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.employees ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);

CREATE OR REPLACE FUNCTION public._sync_employee_department_name()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.department_id IS NOT NULL THEN
    SELECT name INTO NEW.department FROM public.departments WHERE id = NEW.department_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_employee_department ON public.employees;
CREATE TRIGGER trg_sync_employee_department
  BEFORE INSERT OR UPDATE OF department_id ON public.employees
  FOR EACH ROW EXECUTE FUNCTION public._sync_employee_department_name();

ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "departments_select_public" ON public.departments;
CREATE POLICY "departments_select_public" ON public.departments FOR SELECT USING (status = 1);
DROP POLICY IF EXISTS "departments_all_admin" ON public.departments;
CREATE POLICY "departments_all_admin" ON public.departments FOR ALL USING (current_user_role() = 'super_admin');

-- Jitendra: department_id 7 (Computer Operator), matching his legacy value directly.
UPDATE public.employees SET department_id = 7 WHERE id = 2;
