-- 018_delete_student_full_rpc.sql
-- Run in Supabase SQL editor.
--
-- Deleting a student is currently two separate client calls (delete students
-- row, then delete profiles row). If the second call fails, the student row
-- is already gone but the linked profile is left behind — an orphaned login
-- with no student record. Wrapping both deletes in one plpgsql function
-- makes them atomic: either both rows go, or neither does.

CREATE OR REPLACE FUNCTION delete_student_full(p_student_id INT)
RETURNS VOID AS $$
DECLARE
  v_profile_id UUID;
BEGIN
  SELECT profile_id INTO v_profile_id FROM students WHERE id = p_student_id;

  DELETE FROM students WHERE id = p_student_id;

  IF v_profile_id IS NOT NULL THEN
    DELETE FROM profiles WHERE id = v_profile_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION delete_student_full(INT) TO authenticated;
