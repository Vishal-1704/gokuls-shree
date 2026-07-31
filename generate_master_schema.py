import os

base_path = r"c:\Users\Lenovo\Music\Projects\gokuls-shree"

migrations = [
    r"old -backend\migrations\001_supabase_schema.sql",
    r"old -backend\migrations\002_security_rls.sql",
    r"old -backend\migrations\003_super_admin_permissions.sql",
    r"old -backend\migrations\009_fix_rls_and_missing_tables.sql",
    r"dart_backend\migrations\012_fix_schema_bugs.sql",
    r"dart_backend\migrations\013_employee_and_experience_cert.sql",
    r"dart_backend\migrations\014_smart_attendance.sql",
    r"old -backend\migrations\011_recreate_views_security_invoker.sql",
    r"old -backend\migrations\010_enable_rls_all_tables.sql"
]

out_file = os.path.join(base_path, "supabase/migrations/20240101000000_master_schema.sql")

with open(out_file, "w", encoding="utf-8") as f_out:
    for mig in migrations:
        path = os.path.join(base_path, mig)
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f_in:
                content = f_in.read()
                
                # BUG-1: Remove early teacher_subjects since it fails forward reference
                if '001_supabase_schema.sql' in mig:
                    content = content.replace('''CREATE TABLE IF NOT EXISTS teacher_subjects (
  id              SERIAL PRIMARY KEY,
  teacher_id      UUID REFERENCES profiles(id),
  subject_id      INT REFERENCES subjects(id),
  branch_id       INT REFERENCES branches(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);''', '/* teacher_subjects moved to 012 */')
                
                # Remove views depending on missing stage_02 tables
                if '011_recreate_views_security_invoker.sql' in mig:
                    content = content.replace('DROP VIEW IF EXISTS public.v_student_visible_exams CASCADE;', '/* removed */')
                    # Replace the CREATE VIEW statement entirely
                    import re
                    content = re.sub(r'-- 5\. Recreate v_student_visible_exams.*?;\n', '/* v_student_visible_exams removed */\n', content, flags=re.DOTALL)
                
                # Missing table RLS in 010
                if '010_enable_rls_all_tables.sql' in mig:
                    missing_tables = ['questions', 'exam_sessions', 'exam_answers', 'issued_documents', 'paper_sets', 'exam_schedules', 'exam_assignments']
                    
                    lines = content.split('\n')
                    new_lines = []
                    skip_mode = False
                    for line in lines:
                        if any(f"ON public.{t}" in line or f"TABLE public.{t}" in line for t in missing_tables):
                            if "CREATE POLICY" in line or "DROP POLICY" in line or "ALTER TABLE" in line:
                                skip_mode = True
                                continue
                        
                        if skip_mode:
                            if ";" in line:
                                skip_mode = False
                            continue
                            
                        new_lines.append(line)
                    
                    content = "\n".join(new_lines)
                
                f_out.write(content)
                f_out.write("\n\n")

print(f"Successfully created {out_file}")
