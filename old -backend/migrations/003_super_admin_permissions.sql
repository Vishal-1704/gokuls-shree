-- ============================================================
-- 003_super_admin_permissions.sql
-- Run this in your Supabase SQL Editor.
-- Configures permissions array, Super Admin singleton trigger,
-- and RLS policies for Super Admin configuration.
-- ============================================================

-- ── 1. ADD PERMISSIONS COLUMN TO PROFILES ──────────────────────────
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS permissions TEXT[] DEFAULT '{}'::text[];

-- ── 2. CREATE SUPER ADMIN SINGLETON FUNCTION & TRIGGER ──────────────
CREATE OR REPLACE FUNCTION public.check_super_admin_singleton()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'super_admin' THEN
    -- Check if another active super admin exists (excluding the current user being updated)
    IF EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE role = 'super_admin' AND id <> NEW.id AND status = 1
    ) THEN
      RAISE EXCEPTION 'A Super Admin profile already exists in the system. Only one Super Admin is permitted.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Safe drop and recreate trigger
DROP TRIGGER IF EXISTS enforce_super_admin_singleton ON public.profiles;
CREATE TRIGGER enforce_super_admin_singleton
BEFORE INSERT OR UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.check_super_admin_singleton();

-- ── 3. ENABLE RLS ON PROFILES (IF NOT ENABLED) ──────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ── 4. RECREATE RLS POLICIES FOR PROFILE MANAGEMENT ─────────────────

-- Standard Read Policy: users read own, admins/teachers read within branch
DROP POLICY IF EXISTS "profiles_read" ON public.profiles;
CREATE POLICY "profiles_read" ON public.profiles
  FOR SELECT USING (
    auth_uid = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.profiles caller
      WHERE caller.auth_uid = auth.uid()
      AND caller.role IN ('super_admin', 'branch_admin', 'teacher')
      AND caller.status = 1
      AND (caller.role = 'super_admin' OR caller.branch_id = public.profiles.branch_id)
    )
  );

-- Self-update Policy: users update own basic info, but cannot change their own role/permissions
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth_uid = auth.uid())
  WITH CHECK (
    role = (SELECT role FROM public.profiles WHERE auth_uid = auth.uid())
    AND permissions = (SELECT permissions FROM public.profiles WHERE auth_uid = auth.uid())
  );

-- Super Admin Full Control Policy: Super Admin can read/insert/update/delete any profile
DROP POLICY IF EXISTS "super_admin_manage_all_profiles" ON public.profiles;
CREATE POLICY "super_admin_manage_all_profiles" ON public.profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.auth_uid = auth.uid()
      AND p.role = 'super_admin'
      AND p.status = 1
    )
  );
