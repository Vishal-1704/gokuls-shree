-- Migration to add phone lookup and registration functions
CREATE OR REPLACE FUNCTION lookup_user_by_phone(p_phone TEXT)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INT := 0;
  v_email TEXT;
  v_role TEXT;
  v_auth_uid UUID;
  v_profile_id UUID;
  v_record RECORD;
BEGIN
  -- Count total matches across tables
  SELECT 
    (SELECT count(*) FROM students WHERE contact = p_phone) +
    (SELECT count(*) FROM employees WHERE contact = p_phone) +
    (SELECT count(*) FROM branches WHERE contact = p_phone) +
    (SELECT count(*) FROM profiles WHERE contact = p_phone)
  INTO v_count;

  IF v_count = 0 THEN
    RETURN json_build_object('isFound', false, 'isDuplicate', false);
  END IF;

  IF v_count > 1 THEN
    -- Since a user might have a record in `students` AND `profiles`, that's count=2!
    -- Wait, we should check if they are the SAME person (e.g. students.profile_id = profiles.id)
    -- To keep it simple: Just count unique contacts across logical users.
    -- Actually, if we just find the user in profiles FIRST.
    -- Let's rewrite the lookup logic carefully.
  END IF;

  -- This logic was flawed. Let's do it properly:
  -- Find in profiles first
  SELECT id, auth_uid, role, email INTO v_profile_id, v_auth_uid, v_role, v_email 
  FROM profiles WHERE contact = p_phone LIMIT 1;

  IF FOUND THEN
    RETURN json_build_object(
      'isFound', true, 
      'isDuplicate', false, 
      'hasAuthAccount', (v_auth_uid IS NOT NULL),
      'email', v_email,
      'role', v_role
    );
  END IF;

  -- If not in profiles, check students
  SELECT email INTO v_email FROM students WHERE contact = p_phone LIMIT 1;
  IF FOUND THEN
    RETURN json_build_object(
      'isFound', true, 'isDuplicate', false, 'hasAuthAccount', false,
      'email', v_email, 'role', 'student'
    );
  END IF;

  -- Check employees
  SELECT email INTO v_email FROM employees WHERE contact = p_phone LIMIT 1;
  IF FOUND THEN
    RETURN json_build_object(
      'isFound', true, 'isDuplicate', false, 'hasAuthAccount', false,
      'email', v_email, 'role', 'teacher'
    );
  END IF;

  -- Check branches (branch admin)
  SELECT email INTO v_email FROM branches WHERE contact = p_phone LIMIT 1;
  IF FOUND THEN
    RETURN json_build_object(
      'isFound', true, 'isDuplicate', false, 'hasAuthAccount', false,
      'email', v_email, 'role', 'branch_admin'
    );
  END IF;

  RETURN json_build_object('isFound', false, 'isDuplicate', false);
END;
$$;

-- Function to link a newly created auth user to an existing entity
CREATE OR REPLACE FUNCTION link_auth_user_to_entity(
  p_phone TEXT, 
  p_auth_uid UUID, 
  p_email TEXT,
  p_name TEXT DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_role TEXT;
  v_branch_id INT;
  v_entity_id INT;
  v_profile_id UUID;
  v_name TEXT;
BEGIN
  -- 1. Check students
  SELECT id, branch_id, name INTO v_entity_id, v_branch_id, v_name FROM students WHERE contact = p_phone LIMIT 1;
  IF FOUND THEN
    v_role := 'student';
    INSERT INTO profiles (auth_uid, role, branch_id, email, contact, full_name)
    VALUES (p_auth_uid, v_role, v_branch_id, p_email, p_phone, v_name)
    RETURNING id INTO v_profile_id;
    
    UPDATE students SET profile_id = v_profile_id, email = p_email WHERE id = v_entity_id;
    RETURN json_build_object('success', true, 'role', v_role);
  END IF;

  -- 2. Check employees
  SELECT id, branch_id, name INTO v_entity_id, v_branch_id, v_name FROM employees WHERE contact = p_phone LIMIT 1;
  IF FOUND THEN
    v_role := 'teacher';
    INSERT INTO profiles (auth_uid, role, branch_id, email, contact, full_name)
    VALUES (p_auth_uid, v_role, v_branch_id, p_email, p_phone, v_name)
    RETURNING id INTO v_profile_id;
    
    UPDATE employees SET profile_id = v_profile_id, email = p_email WHERE id = v_entity_id;
    RETURN json_build_object('success', true, 'role', v_role);
  END IF;

  -- 3. Check branches
  SELECT id, owner_name INTO v_entity_id, v_name FROM branches WHERE contact = p_phone LIMIT 1;
  IF FOUND THEN
    v_role := 'branch_admin';
    INSERT INTO profiles (auth_uid, role, branch_id, email, contact, full_name)
    VALUES (p_auth_uid, v_role, v_entity_id, p_email, p_phone, v_name)
    RETURNING id INTO v_profile_id;
    
    RETURN json_build_object('success', true, 'role', v_role);
  END IF;

  -- 4. Fallback: If not found anywhere, create a new unassigned student profile
  v_role := 'student';
  INSERT INTO profiles (auth_uid, role, branch_id, email, contact, full_name)
  VALUES (p_auth_uid, v_role, NULL, p_email, p_phone, COALESCE(p_name, 'New User'))
  RETURNING id INTO v_profile_id;
  
  RETURN json_build_object('success', true, 'role', v_role, 'is_new', true);
END;
$$;
