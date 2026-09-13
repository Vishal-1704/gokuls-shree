-- 20240301000008_franchise_setup_rpc.sql
--
-- Adds server-side franchise setup function (SECURITY DEFINER) and
-- auto-generation of unique branch codes so branch admins can complete
-- franchise setup directly without depending on external container APIs.

-- 1. Function to auto-generate the next branch code (e.g. GS001, GS002, ...)
CREATE OR REPLACE FUNCTION public.get_next_branch_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next_num INT := 1;
  v_code TEXT;
BEGIN
  SELECT COALESCE(MAX(
    CASE 
      WHEN code ~* '^GS[0-9]+$' THEN SUBSTRING(code FROM 3)::INT
      ELSE 0
    END
  ), 0) + 1 INTO v_next_num
  FROM public.branches;

  v_code := 'GS' || LPAD(v_next_num::TEXT, 3, '0');
  RETURN v_code;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_next_branch_code() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_next_branch_code() TO anon;

-- 2. Franchise Setup RPC Function (runs in one transaction with elevated privileges)
CREATE OR REPLACE FUNCTION public.setup_franchise(
  p_name TEXT,
  p_code TEXT,
  p_owner_name TEXT DEFAULT NULL,
  p_contact TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_profile_id UUID;
  v_branch_id INT;
  v_existing_code TEXT;
  v_effective_code TEXT;
  v_result JSONB;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Find profile
  SELECT id, branch_id INTO v_profile_id, v_branch_id
  FROM public.profiles
  WHERE auth_uid = v_user_id
  LIMIT 1;

  -- If branch_id is null on profile, check branches.admin_id
  IF v_branch_id IS NULL THEN
    SELECT id INTO v_branch_id
    FROM public.branches
    WHERE admin_id = v_profile_id OR admin_id = v_user_id
    LIMIT 1;
  END IF;

  IF v_branch_id IS NOT NULL THEN
    -- Branch already exists: preserve super admin assigned code if present
    SELECT code INTO v_existing_code FROM public.branches WHERE id = v_branch_id;
    v_effective_code := COALESCE(NULLIF(TRIM(v_existing_code), ''), NULLIF(TRIM(p_code), ''), public.get_next_branch_code());

    UPDATE public.branches
    SET name = COALESCE(NULLIF(TRIM(p_name), ''), name),
        code = v_effective_code,
        owner_name = COALESCE(p_owner_name, owner_name),
        contact = COALESCE(p_contact, contact),
        address = COALESCE(p_address, address),
        admin_id = COALESCE(admin_id, v_profile_id)
    WHERE id = v_branch_id;

    -- Ensure profile is linked
    IF v_profile_id IS NOT NULL THEN
      UPDATE public.profiles
      SET branch_id = v_branch_id
      WHERE id = v_profile_id;
    END IF;
  ELSE
    -- Branch does not exist: ensure branch code is unique
    v_effective_code := COALESCE(NULLIF(TRIM(p_code), ''), public.get_next_branch_code());

    -- If the requested code already belongs to another branch, generate a fresh unique code
    IF EXISTS (SELECT 1 FROM public.branches WHERE code = v_effective_code) THEN
      v_effective_code := public.get_next_branch_code();
    END IF;

    INSERT INTO public.branches (
      admin_id,
      name,
      code,
      owner_name,
      contact,
      address,
      status
    ) VALUES (
      v_profile_id,
      p_name,
      v_effective_code,
      p_owner_name,
      p_contact,
      p_address,
      1
    ) RETURNING id INTO v_branch_id;

    -- Link profile to new branch
    IF v_profile_id IS NOT NULL THEN
      UPDATE public.profiles
      SET branch_id = v_branch_id
      WHERE id = v_profile_id;
    END IF;
  END IF;

  SELECT to_jsonb(b) INTO v_result FROM public.branches b WHERE b.id = v_branch_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Franchise setup completed successfully',
    'branch_id', v_branch_id,
    'branch', v_result
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.setup_franchise(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- 3. Update RLS policy on branches so branch admins can read & update their own branch
DROP POLICY IF EXISTS "branches_branch_admin_update" ON public.branches;
CREATE POLICY "branches_branch_admin_update" ON public.branches
  FOR UPDATE
  USING (
    admin_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
    OR admin_id = auth.uid()
    OR id IN (SELECT branch_id FROM public.profiles WHERE auth_uid = auth.uid())
  )
  WITH CHECK (
    admin_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
    OR admin_id = auth.uid()
    OR id IN (SELECT branch_id FROM public.profiles WHERE auth_uid = auth.uid())
  );

DROP POLICY IF EXISTS "branches_branch_admin_insert" ON public.branches;
CREATE POLICY "branches_branch_admin_insert" ON public.branches
  FOR INSERT
  WITH CHECK (
    admin_id IN (SELECT id FROM public.profiles WHERE auth_uid = auth.uid())
    OR admin_id = auth.uid()
  );
