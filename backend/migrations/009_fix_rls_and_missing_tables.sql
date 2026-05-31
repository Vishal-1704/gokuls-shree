-- 1. Fix RLS policies on profiles to prevent infinite recursion
DROP POLICY IF EXISTS "profiles_read" ON public.profiles;
CREATE POLICY "profiles_read" ON public.profiles
  FOR SELECT USING (
    auth_uid = auth.uid()
    OR
    (
      current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
      AND (
        current_user_role() = 'super_admin'
        OR branch_id = current_user_branch()
      )
    )
  );

DROP POLICY IF EXISTS "super_admin_manage_all_profiles" ON public.profiles;
CREATE POLICY "super_admin_manage_all_profiles" ON public.profiles
  FOR ALL USING (
    current_user_role() = 'super_admin'
  );

-- Create current_user_permissions helper function
CREATE OR REPLACE FUNCTION current_user_permissions()
RETURNS TEXT[] AS $$
DECLARE
  u_perms TEXT[];
BEGIN
  SELECT permissions INTO u_perms FROM profiles WHERE auth_uid = auth.uid() AND status = 1 LIMIT 1;
  RETURN u_perms;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth_uid = auth.uid())
  WITH CHECK (
    role = current_user_role()
    AND permissions = current_user_permissions()
  );

-- 2. Add title and code generated columns to courses to support app queries
ALTER TABLE public.courses ADD COLUMN IF NOT EXISTS title TEXT GENERATED ALWAYS AS (name) STORED;
ALTER TABLE public.courses ADD COLUMN IF NOT EXISTS code TEXT GENERATED ALWAYS AS (short_name) STORED;

-- 3. Create student_enrollments view mapping student profiles to courses
CREATE OR REPLACE VIEW public.student_enrollments AS
SELECT 
  id AS enrollment_id,
  profile_id AS student_id,
  course_id,
  created_at AS enrolled_at,
  status
FROM public.students;

-- 4. Create payment_transactions view mapping fee payments to student profile UUIDs
CREATE OR REPLACE VIEW public.payment_transactions AS
SELECT 
  fp.id,
  fp.legacy_id,
  s.profile_id AS student_id,
  fp.branch_id,
  fp.course_id,
  fp.receipt_no,
  fp.payment_date,
  fp.amount,
  fp.payment_mode,
  fp.description,
  fp.created_at
FROM public.fee_payments fp
JOIN public.students s ON fp.student_id = s.id;

-- 5. Create enquiries table
CREATE TABLE IF NOT EXISTS public.enquiries (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  mobile TEXT NOT NULL,
  message TEXT,
  email TEXT,
  district TEXT,
  source TEXT DEFAULT 'mobile_app',
  status TEXT DEFAULT 'new',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.enquiries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "enquiries_insert_public" ON public.enquiries;
CREATE POLICY "enquiries_insert_public" ON public.enquiries
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "enquiries_read_admin" ON public.enquiries;
CREATE POLICY "enquiries_read_admin" ON public.enquiries
  FOR SELECT USING (
    current_user_role() IN ('super_admin', 'branch_admin')
  );
