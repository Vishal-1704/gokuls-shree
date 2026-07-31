-- ============================================================
-- GOKUL SHREE - MASTER SCHEMA (AUTO-GENERATED)
-- Includes all base schema, RLS policies, and bug fixes.
-- ============================================================



-- ============================================================
-- SOURCE: old -backend\migrations\001_supabase_schema.sql
-- ============================================================

-- ============================================================
-- GOKUL SHREE SCHOOL MANAGEMENT SYSTEM
-- Restructured Supabase/PostgreSQL Schema
-- Version: 1.0 | Date: 2026-05-10
-- ============================================================
-- Run this file in your Supabase SQL Editor to create all tables.
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. BRANCHES (Franchise Centers)
-- Old table: branch
-- ============================================================
CREATE TABLE IF NOT EXISTS branches (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,                        -- original branch.id
  name            TEXT NOT NULL,
  code            TEXT UNIQUE,
  owner_name      TEXT,
  contact         TEXT,
  email           TEXT,
  address         TEXT,
  city            TEXT,
  state           TEXT,
  pincode         TEXT,
  bank_name       TEXT,
  bank_acc_no     TEXT,
  bank_ifsc       TEXT,
  pan_no          TEXT,
  status          SMALLINT DEFAULT 1,         -- 1=active, 0=inactive
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. USERS / AUTH TABLE (All roles: super_admin, branch_admin, teacher, student)
-- Replaces: admin_login, emp (login), members (login)
-- Supabase Auth handles actual authentication.
-- This table stores role & profile metadata linked to Supabase auth.users
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_uid        UUID UNIQUE,                -- links to Supabase auth.users.id
  role            TEXT NOT NULL CHECK (role IN ('super_admin','branch_admin','teacher','student')),
  branch_id       INT REFERENCES branches(id),
  legacy_id       INT,                        -- original id from old table
  legacy_table    TEXT,                       -- 'admin_login' | 'emp' | 'members'
  username        TEXT UNIQUE,
  full_name       TEXT,
  email           TEXT,
  contact         TEXT,
  status          SMALLINT DEFAULT 1,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. EMPLOYEES / TEACHERS
-- Old table: emp
-- ============================================================
CREATE TABLE IF NOT EXISTS employees (
  id              SERIAL PRIMARY KEY,
  profile_id      UUID REFERENCES profiles(id),
  legacy_id       INT,
  branch_id       INT REFERENCES branches(id),
  name            TEXT NOT NULL,
  designation     TEXT,
  department      TEXT,
  gender          TEXT,
  doj             DATE,                       -- date of joining
  contact         TEXT,
  email           TEXT,
  address         TEXT,
  basic_salary    NUMERIC(10,2) DEFAULT 0,
  hra             NUMERIC(10,2) DEFAULT 0,
  da              NUMERIC(10,2) DEFAULT 0,
  other_allowance NUMERIC(10,2) DEFAULT 0,
  pf_account_no   TEXT,
  pan_no          TEXT,
  esi_no          TEXT,
  causal_leave    INT DEFAULT 0,
  status          SMALLINT DEFAULT 1,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3b. TEACHER SUBJECTS JUNCTION TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS teacher_subjects (
  id              SERIAL PRIMARY KEY,
  teacher_id      UUID REFERENCES profiles(id),
  subject_id      INT REFERENCES subjects(id),
  branch_id       INT REFERENCES branches(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. COURSES
-- Old table: courses
-- ============================================================
CREATE TABLE IF NOT EXISTS courses (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  name            TEXT NOT NULL,
  short_name      TEXT,
  duration        TEXT,
  fee             NUMERIC(10,2) DEFAULT 0,
  category        TEXT,                       -- Computer / Yoga / Fire Safety etc.
  total_marks     INT DEFAULT 0,
  pass_marks      INT DEFAULT 0,
  status          SMALLINT DEFAULT 1,
  branch_id       INT REFERENCES branches(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. SUBJECTS
-- Old table: subject
-- ============================================================
CREATE TABLE IF NOT EXISTS subjects (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  course_id       INT REFERENCES courses(id),
  name            TEXT NOT NULL,
  code            TEXT,
  total_marks     INT DEFAULT 100,
  pass_marks      INT DEFAULT 33,
  status          SMALLINT DEFAULT 1,
  branch_id       INT REFERENCES branches(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. STUDENTS
-- Old table: members
-- ============================================================
CREATE TABLE IF NOT EXISTS students (
  id              SERIAL PRIMARY KEY,
  profile_id      UUID REFERENCES profiles(id),
  legacy_id       INT,
  branch_id       INT REFERENCES branches(id),
  course_id       INT REFERENCES courses(id),

  -- Identity
  reg_no          TEXT UNIQUE,                -- regsno (e.g. GOKUL0181121)
  adm_no          TEXT,                       -- admno / serial no
  roll_no         TEXT,
  name            TEXT NOT NULL,
  father_name     TEXT,
  mother_name     TEXT,
  gender          TEXT,
  dob             DATE,
  religion        TEXT,
  category        TEXT,                       -- GEN/OBC/SC/ST
  marital_status  TEXT,
  disability      TEXT DEFAULT 'No',
  occupation      TEXT,

  -- Contact
  contact         TEXT,
  father_contact  TEXT,
  email           TEXT,
  address         TEXT,
  temp_address    TEXT,
  state_code      INT,
  district_code   INT,
  pincode         INT,

  -- Identity Proof
  identity_type   TEXT,
  id_number       TEXT,
  aadhar          TEXT,

  -- Academic
  qualification   TEXT,
  passing_year    TEXT,
  session         TEXT,                       -- asession
  medium          TEXT,
  batch_time      TEXT,

  -- Admission
  doj             DATE,                       -- date of joining
  dol             TEXT,                       -- date of leaving
  course_fee      NUMERIC(10,2) DEFAULT 0,
  reg_fee         NUMERIC(10,2) DEFAULT 0,
  admin_fee       NUMERIC(10,2) DEFAULT 0,
  discount        NUMERIC(10,2) DEFAULT 0,
  enquiry_source  TEXT,
  remarks         TEXT,

  -- Documents (file paths / URLs)
  photo_url       TEXT,
  signature_url   TEXT,
  id_proof_url    TEXT,
  qual_proof_url  TEXT,

  -- Status
  id_card_issued  BOOLEAN DEFAULT FALSE,
  status          SMALLINT DEFAULT 1,         -- 1=active, 0=inactive
  refer           TEXT,
  type            SMALLINT DEFAULT 1,         -- 1=regular, 2=self

  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7. FEES / PAYMENTS
-- Old table: fees
-- ============================================================
CREATE TABLE IF NOT EXISTS fee_payments (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  student_id      INT REFERENCES students(id),
  branch_id       INT REFERENCES branches(id),
  course_id       INT REFERENCES courses(id),

  receipt_no      TEXT UNIQUE,
  payment_date    DATE,
  next_due_date   DATE,
  amount          NUMERIC(10,2) DEFAULT 0,
  net_pay         NUMERIC(10,2) DEFAULT 0,
  discount        NUMERIC(10,2) DEFAULT 0,
  fine            NUMERIC(10,2) DEFAULT 0,
  other_charges   NUMERIC(10,2) DEFAULT 0,
  payment_mode    TEXT DEFAULT 'CASH',        -- CASH / ONLINE / CHEQUE
  cheque_no       TEXT,
  description     TEXT,
  recorded_by     UUID REFERENCES profiles(id),

  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 8. ATTENDANCE (Student)
-- Old table: sattdance
-- ============================================================
CREATE TABLE IF NOT EXISTS student_attendance (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  student_id      INT REFERENCES students(id),
  branch_id       INT REFERENCES branches(id),
  attendance_date DATE NOT NULL,
  status          TEXT CHECK (status IN ('P','A','L','H')), -- Present/Absent/Late/Holiday
  month           SMALLINT,
  year            INT,
  marked_by       UUID REFERENCES profiles(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT student_attendance_unique UNIQUE (student_id, attendance_date)
);

-- ============================================================
-- 9. EMPLOYEE ATTENDANCE
-- Old table: sattdancet
-- ============================================================
CREATE TABLE IF NOT EXISTS employee_attendance (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  employee_id     INT REFERENCES employees(id),
  branch_id       INT REFERENCES branches(id),
  attendance_date DATE NOT NULL,
  status          TEXT CHECK (status IN ('P','A','L','H')),
  month           SMALLINT,
  year            INT,
  marked_by       UUID REFERENCES profiles(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 10. ADMIT CARDS
-- Old table: admitcard
-- ============================================================
CREATE TABLE IF NOT EXISTS admit_cards (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  student_id      INT REFERENCES students(id),
  branch_id       INT REFERENCES branches(id),
  course_id       INT REFERENCES courses(id),

  roll_no         TEXT,
  exam_date       DATE,
  exam_center     TEXT,
  exam_city       TEXT,
  session         TEXT,
  issued_date     DATE DEFAULT CURRENT_DATE,
  status          SMALLINT DEFAULT 1,
  generated_by    UUID REFERENCES profiles(id),

  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 11. MARKSHEETS
-- Old table: marksheet
-- Theory marks stored as JSON array for flexibility
-- ============================================================
CREATE TABLE IF NOT EXISTS marksheets (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  student_id      INT REFERENCES students(id),
  branch_id       INT REFERENCES branches(id),
  course_id       INT REFERENCES courses(id),

  roll_no         TEXT,
  session         TEXT,
  exam_mode       SMALLINT DEFAULT 1,         -- 1=offline, 2=online
  marks           JSONB,                      -- {"subjects": [{"name":"CF","theory":98,"practical":0,"viva":0}]}
  total_marks     INT DEFAULT 0,
  obtained_marks  INT DEFAULT 0,
  percentage      NUMERIC(5,2) DEFAULT 0,
  grade           TEXT,
  result          TEXT CHECK (result IN ('PASS','FAIL','ABSENT')),

  marksheet_sl_no  TEXT,                      -- mslno
  certificate_sl_no TEXT,                     -- cslno
  exam_date       DATE,
  issue_date      DATE,
  marksheet_month TEXT,
  marksheet_year  TEXT,
  certificate_month TEXT,
  certificate_year TEXT,

  -- Approval workflow
  status          SMALLINT DEFAULT 0,         -- 0=pending, 1=approved
  approved_by     UUID REFERENCES profiles(id),
  approved_at     TIMESTAMPTZ,
  fee_paid        BOOLEAN DEFAULT FALSE,

  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 12. CERTIFICATES
-- Old table: certificate
-- ============================================================
CREATE TABLE IF NOT EXISTS certificates (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  student_id      INT REFERENCES students(id),
  branch_id       INT REFERENCES branches(id),
  course_id       INT REFERENCES courses(id),
  marksheet_id    INT REFERENCES marksheets(id),

  certificate_no  TEXT UNIQUE,
  issue_date      DATE,
  session         TEXT,
  certificate_url TEXT,

  -- Approval workflow
  status          SMALLINT DEFAULT 0,         -- 0=pending, 1=approved
  approved_by     UUID REFERENCES profiles(id),
  approved_at     TIMESTAMPTZ,

  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 13. ONLINE EXAM CATEGORIES
-- Old table: category
-- ============================================================
CREATE TABLE IF NOT EXISTS exam_categories (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  name            TEXT NOT NULL,
  total_marks     INT DEFAULT 100,
  pass_marks      INT DEFAULT 33,
  time_limit      INT DEFAULT 60,             -- minutes
  total_questions INT DEFAULT 20,
  status          SMALLINT DEFAULT 1,
  branch_id       INT REFERENCES branches(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 14. EXAM QUESTIONS
-- Old table: (questions - was empty, using new structure)
-- ============================================================
CREATE TABLE IF NOT EXISTS exam_questions (
  id              SERIAL PRIMARY KEY,
  category_id     INT REFERENCES exam_categories(id),
  question_text   TEXT NOT NULL,
  option_a        TEXT,
  option_b        TEXT,
  option_c        TEXT,
  option_d        TEXT,
  correct_option  SMALLINT,                   -- 1,2,3,4
  marks           INT DEFAULT 1,
  status          SMALLINT DEFAULT 1,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 15. ONLINE EXAM RESULTS
-- Old table: final_result
-- ============================================================
CREATE TABLE IF NOT EXISTS exam_results (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  student_id      INT REFERENCES students(id),
  branch_id       INT REFERENCES branches(id),
  category_id     INT REFERENCES exam_categories(id),

  questions_attempted JSONB,                  -- q_id as JSON array
  answers_given   JSONB,                      -- ans as JSON array
  total_questions INT DEFAULT 0,
  correct_answers INT DEFAULT 0,
  wrong_answers   INT DEFAULT 0,
  score           INT DEFAULT 0,
  time_taken      INT DEFAULT 0,              -- seconds
  result          TEXT CHECK (result IN ('PASS','FAIL')),
  attempted_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 16. ID CARDS
-- Old table: id_card
-- ============================================================
CREATE TABLE IF NOT EXISTS id_cards (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  student_id      INT REFERENCES students(id),
  branch_id       INT REFERENCES branches(id),
  issue_date      DATE DEFAULT CURRENT_DATE,
  expiry_date     DATE,
  qr_code_url     TEXT,
  card_url        TEXT,
  status          SMALLINT DEFAULT 1,
  issued_by       UUID REFERENCES profiles(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 17. NOTICES / NEWS
-- Old table: news
-- ============================================================
CREATE TABLE IF NOT EXISTS notices (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  title           TEXT NOT NULL,
  content         TEXT,
  type            TEXT DEFAULT 'general',     -- general/exam/fee/result
  branch_id       INT REFERENCES branches(id),
  is_public       BOOLEAN DEFAULT TRUE,
  published_at    TIMESTAMPTZ DEFAULT NOW(),
  created_by      UUID REFERENCES profiles(id),
  status          SMALLINT DEFAULT 1
);

-- ============================================================
-- 18. DOWNLOADS
-- Old table: download
-- ============================================================
CREATE TABLE IF NOT EXISTS downloads (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  title           TEXT NOT NULL,
  file_url        TEXT,
  category        TEXT,                       -- syllabus/form/notice
  branch_id       INT REFERENCES branches(id),
  is_public       BOOLEAN DEFAULT TRUE,
  created_by      UUID REFERENCES profiles(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  status          SMALLINT DEFAULT 1
);

-- ============================================================
-- 19. STATE & DISTRICT LOOKUP
-- Old tables: state, district
-- ============================================================
CREATE TABLE IF NOT EXISTS states (
  code            INT PRIMARY KEY,
  name            TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS districts (
  code            INT PRIMARY KEY,
  name            TEXT NOT NULL,
  state_code      INT REFERENCES states(code)
);

-- ============================================================
-- 20. SALARY / ADVANCE
-- Old tables: advance, attendance
-- ============================================================
CREATE TABLE IF NOT EXISTS salary_advances (
  id              SERIAL PRIMARY KEY,
  legacy_id       INT,
  employee_id     INT REFERENCES employees(id),
  branch_id       INT REFERENCES branches(id),
  amount          NUMERIC(10,2) DEFAULT 0,
  reason          TEXT,
  advance_date    DATE,
  repaid          BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES for performance
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_students_branch     ON students(branch_id);
CREATE INDEX IF NOT EXISTS idx_students_course     ON students(course_id);
CREATE INDEX IF NOT EXISTS idx_students_reg_no     ON students(reg_no);
CREATE INDEX IF NOT EXISTS idx_fee_student         ON fee_payments(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_student  ON student_attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_marksheets_student  ON marksheets(student_id);
CREATE INDEX IF NOT EXISTS idx_marksheets_status   ON marksheets(status);
CREATE INDEX IF NOT EXISTS idx_exam_results_student ON exam_results(student_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role       ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_branch     ON profiles(branch_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS) - Basic policies
-- Enable after configuring Supabase Auth
-- ============================================================
ALTER TABLE students          ENABLE ROW LEVEL SECURITY;
ALTER TABLE marksheets        ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates      ENABLE ROW LEVEL SECURITY;
ALTER TABLE fee_payments      ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles          ENABLE ROW LEVEL SECURITY;

-- Students can only see their own data
CREATE POLICY "students_own_data" ON students
  FOR SELECT USING (
    profile_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
      AND p.role IN ('super_admin','branch_admin','teacher')
    )
  );

-- Marksheets: students see own, admins see all
CREATE POLICY "marksheets_read" ON marksheets
  FOR SELECT USING (
    student_id IN (
      SELECT id FROM students WHERE profile_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM profiles p WHERE p.id = auth.uid()
      AND p.role IN ('super_admin','branch_admin','teacher')
    )
  );

-- Only super_admin can approve marksheets
CREATE POLICY "marksheets_approve" ON marksheets
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles p WHERE p.id = auth.uid()
      AND p.role = 'super_admin'
    )
  );

COMMENT ON TABLE students IS 'Main student registry - migrated from legacy members table';
COMMENT ON TABLE marksheets IS 'Student marksheets with JSON marks - approval by super_admin';
COMMENT ON TABLE certificates IS 'Issued certificates - approval workflow via super_admin';
COMMENT ON TABLE profiles IS 'All user roles linked to Supabase Auth';
COMMENT ON TABLE branches IS 'Franchise/branch center details';


-- ============================================================
-- SOURCE: old -backend\migrations\002_security_rls.sql
-- ============================================================

-- ============================================================
-- 002_security.sql
-- Run this in Supabase SQL Editor AFTER 001_supabase_schema.sql
-- Adds: audit_logs table + comprehensive RLS policies
-- ============================================================

-- ── Audit Logs table ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
  id               BIGSERIAL PRIMARY KEY,
  action           TEXT NOT NULL,          -- e.g. APPROVE_MARKSHEET
  profile_id       UUID,                   -- who did it
  role             TEXT,                   -- their role at time of action
  branch_id        INT,
  ip_address       TEXT,
  user_agent       TEXT,
  request_path     TEXT,
  request_method   TEXT,
  response_status  INT,
  payload_summary  TEXT,                   -- sanitized (no passwords)
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Audit logs are append-only — no updates or deletes allowed
CREATE POLICY "audit_insert_only" ON audit_logs
  FOR INSERT WITH CHECK (true);

-- Only super_admin can read audit logs
CREATE POLICY "audit_read_super_admin" ON audit_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.auth_uid = auth.uid()
      AND p.role = 'super_admin'
      AND p.status = 1
    )
  );

-- ============================================================
-- ROW LEVEL SECURITY POLICIES
-- These are the LAST LINE of defense in the database.
-- Even if someone bypasses the Node.js server, Supabase
-- will still enforce these rules at the DB level.
-- ============================================================

-- ── Helper function: get caller's role ───────────────────────
CREATE OR REPLACE FUNCTION current_user_role()
RETURNS TEXT AS $$
DECLARE
  u_role TEXT;
BEGIN
  SELECT role INTO u_role FROM profiles WHERE auth_uid = auth.uid() AND status = 1 LIMIT 1;
  RETURN u_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ── Helper function: get caller's branch_id ──────────────────
CREATE OR REPLACE FUNCTION current_user_branch()
RETURNS INT AS $$
DECLARE
  b_id INT;
BEGIN
  SELECT branch_id INTO b_id FROM profiles WHERE auth_uid = auth.uid() AND status = 1 LIMIT 1;
  RETURN b_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ── Helper function: get caller's student_id (if student) ────
CREATE OR REPLACE FUNCTION current_student_id()
RETURNS INT AS $$
DECLARE
  s_id INT;
BEGIN
  SELECT s.id INTO s_id FROM students s
  JOIN profiles p ON s.profile_id = p.id
  WHERE p.auth_uid = auth.uid() AND p.status = 1 LIMIT 1;
  RETURN s_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ════════════════════════════════════════════════════════════
-- PROFILES TABLE RLS
-- ════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "profiles_read" ON profiles;
CREATE POLICY "profiles_read" ON profiles
  FOR SELECT USING (
    -- You can read your own profile always
    auth_uid = auth.uid()
    OR
    -- Admins can read profiles in their branch
    (
      current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
      AND (
        current_user_role() = 'super_admin'
        OR branch_id = current_user_branch()
      )
    )
  );

DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (auth_uid = auth.uid())
  WITH CHECK (
    -- Cannot change your own role via self-update
    role = (SELECT role FROM profiles WHERE auth_uid = auth.uid())
  );

-- ════════════════════════════════════════════════════════════
-- STUDENTS TABLE RLS
-- ════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "students_select" ON students;
CREATE POLICY "students_select" ON students
  FOR SELECT USING (
    CASE current_user_role()
      WHEN 'super_admin'  THEN true                                -- all students
      WHEN 'branch_admin' THEN branch_id = current_user_branch()   -- own branch only
      WHEN 'teacher'      THEN branch_id = current_user_branch()   -- own branch only
      WHEN 'student'      THEN id = current_student_id()           -- own record ONLY
      ELSE false
    END
  );

DROP POLICY IF EXISTS "students_insert" ON students;
CREATE POLICY "students_insert" ON students
  FOR INSERT WITH CHECK (
    current_user_role() IN ('super_admin', 'branch_admin')
    AND (
      current_user_role() = 'super_admin'
      OR branch_id = current_user_branch()
    )
  );

DROP POLICY IF EXISTS "students_update" ON students;
CREATE POLICY "students_update" ON students
  FOR UPDATE USING (
    current_user_role() IN ('super_admin', 'branch_admin')
    AND (
      current_user_role() = 'super_admin'
      OR branch_id = current_user_branch()
    )
  );

DROP POLICY IF EXISTS "students_delete" ON students;
CREATE POLICY "students_delete" ON students FOR DELETE USING (false);

-- ════════════════════════════════════════════════════════════
-- FEE PAYMENTS TABLE RLS
-- ════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "fees_select" ON fee_payments;
CREATE POLICY "fees_select" ON fee_payments
  FOR SELECT USING (
    CASE current_user_role()
      WHEN 'super_admin'  THEN true
      WHEN 'branch_admin' THEN branch_id = current_user_branch()
      WHEN 'student'      THEN student_id = current_student_id()
      ELSE false  -- teachers cannot see fees
    END
  );

DROP POLICY IF EXISTS "fees_insert" ON fee_payments;
CREATE POLICY "fees_insert" ON fee_payments
  FOR INSERT WITH CHECK (
    current_user_role() IN ('super_admin', 'branch_admin')
    AND (
      current_user_role() = 'super_admin'
      OR branch_id = current_user_branch()
    )
  );

-- ════════════════════════════════════════════════════════════
-- MARKSHEETS TABLE RLS — most critical
-- ════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "marksheets_select" ON marksheets;
CREATE POLICY "marksheets_select" ON marksheets
  FOR SELECT USING (
    CASE current_user_role()
      WHEN 'super_admin'  THEN true                               -- all, all statuses
      WHEN 'branch_admin' THEN branch_id = current_user_branch() -- own branch, all statuses
      WHEN 'teacher'      THEN branch_id = current_user_branch() -- own branch, all statuses
      WHEN 'student'      THEN
        student_id = current_student_id()
        AND status = 1                    -- ← STUDENTS SEE ONLY APPROVED
      ELSE false
    END
  );

DROP POLICY IF EXISTS "marksheets_insert" ON marksheets;
CREATE POLICY "marksheets_insert" ON marksheets
  FOR INSERT WITH CHECK (
    -- Only branch_admin or super_admin can create
    current_user_role() IN ('super_admin', 'branch_admin')
    -- branch_admin must insert for their own branch
    AND (
      current_user_role() = 'super_admin'
      OR branch_id = current_user_branch()
    )
    -- CRITICAL: branch_admin cannot self-approve (status must be 0)
    AND (
      current_user_role() = 'super_admin'
      OR status = 0
    )
  );

DROP POLICY IF EXISTS "marksheets_update" ON marksheets;
CREATE POLICY "marksheets_update" ON marksheets
  FOR UPDATE USING (
    -- Only super_admin can update (approve/reject)
    current_user_role() = 'super_admin'
  )
  WITH CHECK (
    current_user_role() = 'super_admin'
  );

-- ════════════════════════════════════════════════════════════
-- CERTIFICATES TABLE RLS
-- ════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "certs_select" ON certificates;
CREATE POLICY "certs_select" ON certificates
  FOR SELECT USING (
    CASE current_user_role()
      WHEN 'super_admin'  THEN true
      WHEN 'branch_admin' THEN branch_id = current_user_branch()
      WHEN 'student'      THEN student_id = current_student_id() AND status = 1
      ELSE false
    END
  );

DROP POLICY IF EXISTS "certs_insert" ON certificates;
CREATE POLICY "certs_insert" ON certificates
  FOR INSERT WITH CHECK (
    current_user_role() = 'super_admin'  -- ONLY super_admin can issue certs
  );

-- ════════════════════════════════════════════════════════════
-- ATTENDANCE TABLE RLS
-- ════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "att_select" ON student_attendance;
CREATE POLICY "att_select" ON student_attendance
  FOR SELECT USING (
    CASE current_user_role()
      WHEN 'super_admin'  THEN true
      WHEN 'branch_admin' THEN branch_id = current_user_branch()
      WHEN 'teacher'      THEN branch_id = current_user_branch()
      WHEN 'student'      THEN student_id = current_student_id()
      ELSE false
    END
  );

DROP POLICY IF EXISTS "att_insert" ON student_attendance;
CREATE POLICY "att_insert" ON student_attendance
  FOR INSERT WITH CHECK (
    current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
    AND (
      current_user_role() = 'super_admin'
      OR branch_id = current_user_branch()
    )
  );

DROP POLICY IF EXISTS "att_update" ON student_attendance;
CREATE POLICY "att_update" ON student_attendance
  FOR UPDATE USING (
    current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
    AND (
      current_user_role() = 'super_admin'
      OR branch_id = current_user_branch()
    )
  );

-- ════════════════════════════════════════════════════════════
-- BRANCHES TABLE RLS
-- ════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "branches_select" ON branches;
CREATE POLICY "branches_select" ON branches
  FOR SELECT USING (
    CASE current_user_role()
      WHEN 'super_admin'  THEN true
      ELSE id = current_user_branch()   -- others see only their own branch
    END
  );

DROP POLICY IF EXISTS "branches_manage" ON branches;
CREATE POLICY "branches_manage" ON branches
  FOR ALL USING (current_user_role() = 'super_admin');

ALTER TABLE branches    ENABLE ROW LEVEL SECURITY;

-- ════════════════════════════════════════════════════════════
-- GRANT PERMISSIONS to service_role (used by Node.js backend)
-- service_role bypasses RLS — that's why we guard at route level too
-- ════════════════════════════════════════════════════════════
GRANT ALL ON ALL TABLES    IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;

COMMENT ON POLICY "marksheets_update" ON marksheets
  IS 'Only super_admin can approve or reject marksheets — enforced at DB level';

COMMENT ON POLICY "certs_insert" ON certificates
  IS 'Only super_admin can issue certificates — enforced at DB level';


-- ============================================================
-- SOURCE: old -backend\migrations\003_super_admin_permissions.sql
-- ============================================================

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


-- ============================================================
-- SOURCE: old -backend\migrations\009_fix_rls_and_missing_tables.sql
-- ============================================================

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


-- ============================================================
-- SOURCE: old -backend\migrations\010_enable_rls_all_tables.sql
-- ============================================================

-- ============================================================
-- 010_enable_rls_all_tables.sql
-- Enables RLS on all 25 remaining tables in the public schema.
-- ============================================================

-- Helper function to get current user's profile ID (UUID)
CREATE OR REPLACE FUNCTION current_profile_id()
RETURNS UUID AS $$
DECLARE
  p_id UUID;
BEGIN
  SELECT id INTO p_id FROM profiles WHERE auth_uid = auth.uid() AND status = 1 LIMIT 1;
  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ==========================================
-- 1. PUBLIC REFERENCE TABLES (Public Read, Admin Write)
-- ==========================================

-- courses
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "courses_select_public" ON public.courses;
CREATE POLICY "courses_select_public" ON public.courses FOR SELECT USING (status = 1);
DROP POLICY IF EXISTS "courses_all_admin" ON public.courses;
CREATE POLICY "courses_all_admin" ON public.courses FOR ALL USING (current_user_role() = 'super_admin');

-- subjects
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "subjects_select_public" ON public.subjects;
CREATE POLICY "subjects_select_public" ON public.subjects FOR SELECT USING (status = 1);
DROP POLICY IF EXISTS "subjects_all_admin" ON public.subjects;
CREATE POLICY "subjects_all_admin" ON public.subjects FOR ALL USING (current_user_role() = 'super_admin');

-- states
ALTER TABLE public.states ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "states_select_public" ON public.states;
CREATE POLICY "states_select_public" ON public.states FOR SELECT USING (true);
DROP POLICY IF EXISTS "states_all_admin" ON public.states;
CREATE POLICY "states_all_admin" ON public.states FOR ALL USING (current_user_role() = 'super_admin');

-- districts
ALTER TABLE public.districts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "districts_select_public" ON public.districts;
CREATE POLICY "districts_select_public" ON public.districts FOR SELECT USING (true);
DROP POLICY IF EXISTS "districts_all_admin" ON public.districts;
CREATE POLICY "districts_all_admin" ON public.districts FOR ALL USING (current_user_role() = 'super_admin');

-- notices
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notices_select_public" ON public.notices;
CREATE POLICY "notices_select_public" ON public.notices FOR SELECT USING (is_public = true OR auth.role() = 'authenticated');
DROP POLICY IF EXISTS "notices_all_admin" ON public.notices;
CREATE POLICY "notices_all_admin" ON public.notices FOR ALL USING (current_user_role() IN ('super_admin', 'branch_admin'));

-- downloads
ALTER TABLE public.downloads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "downloads_select_public" ON public.downloads;
CREATE POLICY "downloads_select_public" ON public.downloads FOR SELECT USING (is_public = true OR auth.role() = 'authenticated');
DROP POLICY IF EXISTS "downloads_all_admin" ON public.downloads;
CREATE POLICY "downloads_all_admin" ON public.downloads FOR ALL USING (current_user_role() IN ('super_admin', 'branch_admin'));


-- ==========================================
-- 2. ADMIN/STAFF MANAGED TABLES (Staff Only)
-- ==========================================

-- employees
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "employees_select" ON public.employees;
CREATE POLICY "employees_select" ON public.employees FOR SELECT USING (
  profile_id = current_profile_id() 
  OR current_user_role() = 'super_admin' 
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);
DROP POLICY IF EXISTS "employees_all_admin" ON public.employees;
CREATE POLICY "employees_all_admin" ON public.employees FOR ALL USING (
  current_user_role() = 'super_admin' 
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);

-- employee_attendance
ALTER TABLE public.employee_attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "employee_attendance_select" ON public.employee_attendance;
CREATE POLICY "employee_attendance_select" ON public.employee_attendance FOR SELECT USING (
  employee_id IN (SELECT id FROM employees WHERE profile_id = current_profile_id())
  OR current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);
DROP POLICY IF EXISTS "employee_attendance_all_admin" ON public.employee_attendance;
CREATE POLICY "employee_attendance_all_admin" ON public.employee_attendance FOR ALL USING (
  current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);

-- salary_advances
ALTER TABLE public.salary_advances ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "salary_advances_select" ON public.salary_advances;
CREATE POLICY "salary_advances_select" ON public.salary_advances FOR SELECT USING (
  employee_id IN (SELECT id FROM employees WHERE profile_id = current_profile_id())
  OR current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);
DROP POLICY IF EXISTS "salary_advances_all_admin" ON public.salary_advances;
CREATE POLICY "salary_advances_all_admin" ON public.salary_advances FOR ALL USING (
  current_user_role() = 'super_admin'
  OR (current_user_role() = 'branch_admin' AND branch_id = current_user_branch())
);


-- ==========================================
-- 3. STUDENT PERSONAL TABLES (Student/Admin/Staff Only)
-- ==========================================

-- admit_cards
ALTER TABLE public.admit_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "admit_cards_select" ON public.admit_cards;
CREATE POLICY "admit_cards_select" ON public.admit_cards FOR SELECT USING (
  student_id = current_student_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "admit_cards_all_admin" ON public.admit_cards;
CREATE POLICY "admit_cards_all_admin" ON public.admit_cards FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- id_cards
ALTER TABLE public.id_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "id_cards_select" ON public.id_cards;
CREATE POLICY "id_cards_select" ON public.id_cards FOR SELECT USING (
  student_id = current_student_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "id_cards_all_admin" ON public.id_cards;
CREATE POLICY "id_cards_all_admin" ON public.id_cards FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- issued_documents
ALTER TABLE public.issued_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "issued_documents_select" ON public.issued_documents;
CREATE POLICY "issued_documents_select" ON public.issued_documents FOR SELECT USING (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "issued_documents_all_admin" ON public.issued_documents;
CREATE POLICY "issued_documents_all_admin" ON public.issued_documents FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);


-- ==========================================
-- 4. EXAM MODULE TABLES (Controlled Access)
-- ==========================================

-- exam_categories
ALTER TABLE public.exam_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_categories_select" ON public.exam_categories;
CREATE POLICY "exam_categories_select" ON public.exam_categories FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "exam_categories_all_admin" ON public.exam_categories;
CREATE POLICY "exam_categories_all_admin" ON public.exam_categories FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_questions
ALTER TABLE public.exam_questions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_questions_select" ON public.exam_questions;
CREATE POLICY "exam_questions_select" ON public.exam_questions FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "exam_questions_all_admin" ON public.exam_questions;
CREATE POLICY "exam_questions_all_admin" ON public.exam_questions FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_results
ALTER TABLE public.exam_results ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_results_select" ON public.exam_results;
CREATE POLICY "exam_results_select" ON public.exam_results FOR SELECT USING (
  student_id = current_student_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "exam_results_all_admin" ON public.exam_results;
CREATE POLICY "exam_results_all_admin" ON public.exam_results FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- paper_sets
ALTER TABLE public.paper_sets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "paper_sets_select" ON public.paper_sets;
CREATE POLICY "paper_sets_select" ON public.paper_sets FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "paper_sets_all_admin" ON public.paper_sets;
CREATE POLICY "paper_sets_all_admin" ON public.paper_sets FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- questions
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "questions_select" ON public.questions;
CREATE POLICY "questions_select" ON public.questions FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "questions_all_admin" ON public.questions;
CREATE POLICY "questions_all_admin" ON public.questions FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_sessions
ALTER TABLE public.exam_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_sessions_select" ON public.exam_sessions;
CREATE POLICY "exam_sessions_select" ON public.exam_sessions FOR SELECT USING (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "exam_sessions_insert" ON public.exam_sessions;
CREATE POLICY "exam_sessions_insert" ON public.exam_sessions FOR INSERT WITH CHECK (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin')
);
DROP POLICY IF EXISTS "exam_sessions_update" ON public.exam_sessions;
CREATE POLICY "exam_sessions_update" ON public.exam_sessions FOR UPDATE USING (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin')
);
DROP POLICY IF EXISTS "exam_sessions_delete" ON public.exam_sessions;
CREATE POLICY "exam_sessions_delete" ON public.exam_sessions FOR DELETE USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_answers
ALTER TABLE public.exam_answers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_answers_select" ON public.exam_answers;
CREATE POLICY "exam_answers_select" ON public.exam_answers FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM exam_sessions 
    WHERE id = session_id 
      AND (student_id = current_profile_id() OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher'))
  )
);
DROP POLICY IF EXISTS "exam_answers_insert" ON public.exam_answers;
CREATE POLICY "exam_answers_insert" ON public.exam_answers FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM exam_sessions 
    WHERE id = session_id AND student_id = current_profile_id()
  ) OR current_user_role() IN ('super_admin', 'branch_admin')
);
DROP POLICY IF EXISTS "exam_answers_update" ON public.exam_answers;
CREATE POLICY "exam_answers_update" ON public.exam_answers FOR UPDATE USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);
DROP POLICY IF EXISTS "exam_answers_delete" ON public.exam_answers;
CREATE POLICY "exam_answers_delete" ON public.exam_answers FOR DELETE USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_schedules
ALTER TABLE public.exam_schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_schedules_select" ON public.exam_schedules;
CREATE POLICY "exam_schedules_select" ON public.exam_schedules FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "exam_schedules_all_admin" ON public.exam_schedules;
CREATE POLICY "exam_schedules_all_admin" ON public.exam_schedules FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- exam_assignments
ALTER TABLE public.exam_assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "exam_assignments_select" ON public.exam_assignments;
CREATE POLICY "exam_assignments_select" ON public.exam_assignments FOR SELECT USING (
  student_id = current_profile_id() OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "exam_assignments_all_admin" ON public.exam_assignments;
CREATE POLICY "exam_assignments_all_admin" ON public.exam_assignments FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);


-- ==========================================
-- 5. ATTENDANCE & PROXIMITY TABLES (Proximity Engine)
-- ==========================================

-- attendance_settings
ALTER TABLE public.attendance_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "attendance_settings_select" ON public.attendance_settings;
CREATE POLICY "attendance_settings_select" ON public.attendance_settings FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "attendance_settings_all_admin" ON public.attendance_settings;
CREATE POLICY "attendance_settings_all_admin" ON public.attendance_settings FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- attendance_qr_sessions
ALTER TABLE public.attendance_qr_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "attendance_qr_sessions_select" ON public.attendance_qr_sessions;
CREATE POLICY "attendance_qr_sessions_select" ON public.attendance_qr_sessions FOR SELECT USING (
  auth.role() = 'authenticated'
);
DROP POLICY IF EXISTS "attendance_qr_sessions_all_admin" ON public.attendance_qr_sessions;
CREATE POLICY "attendance_qr_sessions_all_admin" ON public.attendance_qr_sessions FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);

-- attendance_ble_events
ALTER TABLE public.attendance_ble_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "attendance_ble_events_insert" ON public.attendance_ble_events;
CREATE POLICY "attendance_ble_events_insert" ON public.attendance_ble_events FOR INSERT WITH CHECK (
  student_id = current_profile_id()
);
DROP POLICY IF EXISTS "attendance_ble_events_select" ON public.attendance_ble_events;
CREATE POLICY "attendance_ble_events_select" ON public.attendance_ble_events FOR SELECT USING (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "attendance_ble_events_all_admin" ON public.attendance_ble_events;
CREATE POLICY "attendance_ble_events_all_admin" ON public.attendance_ble_events FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);

-- attendance_events
ALTER TABLE public.attendance_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "attendance_events_insert" ON public.attendance_events;
CREATE POLICY "attendance_events_insert" ON public.attendance_events FOR INSERT WITH CHECK (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "attendance_events_select" ON public.attendance_events;
CREATE POLICY "attendance_events_select" ON public.attendance_events FOR SELECT USING (
  student_id = current_profile_id()
  OR current_user_role() IN ('super_admin', 'branch_admin', 'teacher')
);
DROP POLICY IF EXISTS "attendance_events_all_admin" ON public.attendance_events;
CREATE POLICY "attendance_events_all_admin" ON public.attendance_events FOR ALL USING (
  current_user_role() IN ('super_admin', 'branch_admin')
);


-- ============================================================
-- SOURCE: old -backend\migrations\011_recreate_views_security_invoker.sql
-- ============================================================

-- ============================================================
-- 011_recreate_views_security_invoker.sql
-- Drops the 4 views and recreates them as security invoker views.
-- This resolves the "Security Definer View" advisor warnings.
-- ============================================================

-- 1. Drop existing views to clear relation options
DROP VIEW IF EXISTS public.student_enrollments CASCADE;
DROP VIEW IF EXISTS public.payment_transactions CASCADE;
DROP VIEW IF EXISTS public.v_attendance_daily CASCADE;
DROP VIEW IF EXISTS public.v_student_visible_exams CASCADE;

-- 2. Recreate student_enrollments with security_invoker = on
CREATE VIEW public.student_enrollments WITH (security_invoker = on) AS
SELECT 
  id AS enrollment_id,
  profile_id AS student_id,
  course_id,
  created_at AS enrolled_at,
  status
FROM public.students;

-- 3. Recreate payment_transactions with security_invoker = on
CREATE VIEW public.payment_transactions WITH (security_invoker = on) AS
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

-- 4. Recreate v_attendance_daily with security_invoker = on
CREATE VIEW public.v_attendance_daily WITH (security_invoker = on) AS
SELECT
  student_id,
  date_trunc('day', marked_at) AS attendance_day,
  COUNT(*) FILTER (WHERE status = 'present') AS present_count,
  COUNT(*) FILTER (WHERE status = 'rejected') AS rejected_count,
  MAX(confidence_score) AS max_confidence
FROM public.attendance_events
GROUP BY student_id, date_trunc('day', marked_at);

-- 5. Recreate v_student_visible_exams with security_invoker = on
CREATE VIEW public.v_student_visible_exams WITH (security_invoker = on) AS
SELECT
  es.id AS exam_schedule_id,
  es.paper_set_id,
  es.title,
  es.publish_at,
  es.start_at,
  es.end_at,
  es.duration_minutes,
  es.max_attempts,
  es.shuffle_questions,
  es.shuffle_options,
  es.negative_marking_enabled,
  es.marks_correct,
  es.marks_wrong,
  es.marks_unanswered,
  ea.assignment_type,
  ea.student_id,
  ea.course_id,
  ea.batch_id,
  ea.branch_id
FROM public.exam_schedules es
JOIN public.exam_assignments ea ON ea.exam_schedule_id = es.id AND ea.is_active = true
WHERE es.status IN ('published', 'scheduled')
  AND now() >= es.publish_at
  AND now() >= es.start_at
  AND now() <= es.end_at;


-- ============================================================
-- SOURCE: dart_backend\migrations\012_fix_schema_bugs.sql
-- ============================================================

-- ============================================================
-- 012_fix_schema_bugs.sql
-- Fixes all P0/P1 schema bugs identified in backend_audit_v2.md
-- Run this in Supabase SQL Editor
-- ============================================================

-- ── BUG-1 FIX: Move teacher_subjects AFTER subjects ──────────
-- If teacher_subjects was created with the forward FK error, recreate it:
DROP TABLE IF EXISTS teacher_subjects;
CREATE TABLE IF NOT EXISTS teacher_subjects (
  id              SERIAL PRIMARY KEY,
  teacher_id      UUID REFERENCES profiles(id) ON DELETE CASCADE,
  subject_id      INT  REFERENCES subjects(id) ON DELETE CASCADE,  -- subjects now exists
  branch_id       INT  REFERENCES branches(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (teacher_id, subject_id, branch_id)
);

-- ── BUG-3 FIX: Add admin_id column to branches ───────────────
-- Allows branch.routes.js (and Dart equivalent) to link a branch to its admin
ALTER TABLE branches
  ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_branches_admin ON branches(admin_id);

-- ── BUG-4 FIX: Add title and description columns to courses ───
-- The API was returning undefined for title and description.
-- We add them as aliases / additional columns.
ALTER TABLE courses
  ADD COLUMN IF NOT EXISTS title       TEXT GENERATED ALWAYS AS (name) STORED,
  ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';

-- ── BUG-5 FIX: Remove dead admins table reference ─────────────
-- No need to create the table — it was used incorrectly.
-- auth.routes.js / auth_routes.dart now no longer inserts to admins.
-- The profiles table is the single source of truth for admin identity.
-- (No SQL needed — just removing the insert from application code)

-- ── DB-2 FIX: Add missing index on fee_payments.branch_id ─────
CREATE INDEX IF NOT EXISTS idx_fee_branch     ON fee_payments(branch_id);
CREATE INDEX IF NOT EXISTS idx_fee_date       ON fee_payments(payment_date);

-- ── DB-3 FIX: Add UNIQUE constraint on employee_attendance ─────
ALTER TABLE employee_attendance
  ADD CONSTRAINT employee_attendance_unique
  UNIQUE (employee_id, attendance_date)
  DEFERRABLE INITIALLY DEFERRED;  -- deferred so bulk inserts don't fail mid-batch

-- ── BUG-9 FIX: Verify contact column exists (not contact_phone) ─
-- branches table already has 'contact TEXT' from migration 001.
-- The route was using 'contact_phone' which silently failed.
-- Fixed in Dart code — no SQL change needed.

-- ── Ensure audit_logs has all needed columns ──────────────────
ALTER TABLE audit_logs
  ADD COLUMN IF NOT EXISTS submitted_by UUID REFERENCES profiles(id);

-- ── Performance: add missing indexes ─────────────────────────
CREATE INDEX IF NOT EXISTS idx_notices_branch     ON notices(branch_id);
CREATE INDEX IF NOT EXISTS idx_notices_published  ON notices(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_certificates_student ON certificates(student_id);
CREATE INDEX IF NOT EXISTS idx_marksheets_branch  ON marksheets(branch_id);

COMMENT ON COLUMN branches.admin_id IS 'Profile ID of the branch admin who owns this branch';
COMMENT ON COLUMN courses.title IS 'Alias for name — generated column for API backward compatibility';
COMMENT ON COLUMN courses.description IS 'Extended description of the course';


-- ============================================================
-- SOURCE: dart_backend\migrations\013_employee_and_experience_cert.sql
-- ============================================================

-- ============================================================
-- 013_employee_and_experience_cert.sql
-- Adds explicit schema for Zoho Employee Details and Experience Certificates
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Ensure employees table has all the Zoho HRMS fields
CREATE TABLE IF NOT EXISTS employees (
    id SERIAL PRIMARY KEY,
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    contact TEXT,
    address TEXT,
    designation TEXT,
    department TEXT,
    doj DATE,
    basic_salary NUMERIC(10, 2) DEFAULT 0,
    hra NUMERIC(10, 2) DEFAULT 0,
    da NUMERIC(10, 2) DEFAULT 0,
    other_allowance NUMERIC(10, 2) DEFAULT 0,
    pf_account_no TEXT,
    pan_no TEXT,
    esi_no TEXT,
    causal_leave INT DEFAULT 15,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    status INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (profile_id)
);

-- Note: If employees table already exists from a previous migration, 
-- we add the columns safely if they don't exist:
DO $$
BEGIN
    BEGIN
        ALTER TABLE employees ADD COLUMN designation TEXT;
    EXCEPTION WHEN duplicate_column THEN END;
    BEGIN
        ALTER TABLE employees ADD COLUMN department TEXT;
    EXCEPTION WHEN duplicate_column THEN END;
    BEGIN
        ALTER TABLE employees ADD COLUMN doj DATE;
    EXCEPTION WHEN duplicate_column THEN END;
    BEGIN
        ALTER TABLE employees ADD COLUMN basic_salary NUMERIC(10, 2) DEFAULT 0;
    EXCEPTION WHEN duplicate_column THEN END;
    BEGIN
        ALTER TABLE employees ADD COLUMN hra NUMERIC(10, 2) DEFAULT 0;
    EXCEPTION WHEN duplicate_column THEN END;
    BEGIN
        ALTER TABLE employees ADD COLUMN da NUMERIC(10, 2) DEFAULT 0;
    EXCEPTION WHEN duplicate_column THEN END;
    BEGIN
        ALTER TABLE employees ADD COLUMN other_allowance NUMERIC(10, 2) DEFAULT 0;
    EXCEPTION WHEN duplicate_column THEN END;
    BEGIN
        ALTER TABLE employees ADD COLUMN pf_account_no TEXT;
    EXCEPTION WHEN duplicate_column THEN END;
    BEGIN
        ALTER TABLE employees ADD COLUMN pan_no TEXT;
    EXCEPTION WHEN duplicate_column THEN END;
    BEGIN
        ALTER TABLE employees ADD COLUMN esi_no TEXT;
    EXCEPTION WHEN duplicate_column THEN END;
    BEGIN
        ALTER TABLE employees ADD COLUMN causal_leave INT DEFAULT 15;
    EXCEPTION WHEN duplicate_column THEN END;
END $$;


-- 2. Create Experience Certificates Table
CREATE TABLE IF NOT EXISTS experience_certificates (
    id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(id) ON DELETE CASCADE,
    branch_id INT REFERENCES branches(id) ON DELETE SET NULL,
    request_date TIMESTAMPTZ DEFAULT NOW(),
    status INT DEFAULT 0, -- 0: Pending, 1: Approved, 2: Rejected
    issue_date TIMESTAMPTZ,
    approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    certificate_url TEXT,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_experience_certs_emp ON experience_certificates(employee_id);
CREATE INDEX IF NOT EXISTS idx_experience_certs_branch ON experience_certificates(branch_id);
CREATE INDEX IF NOT EXISTS idx_experience_certs_status ON experience_certificates(status);



-- ============================================================
-- SOURCE: dart_backend\migrations\014_smart_attendance.sql
-- ============================================================

-- Stage 14: Smart Attendance (QR + BLE Hybrid)
-- Target: Supabase PostgreSQL

BEGIN;

-- Core settings for attendance engine
CREATE TABLE IF NOT EXISTS public.attendance_settings (
  id SMALLINT PRIMARY KEY DEFAULT 1,
  qr_ttl_seconds INTEGER NOT NULL DEFAULT 45,
  proximity_required BOOLEAN NOT NULL DEFAULT true,
  min_ble_rssi INTEGER NOT NULL DEFAULT -72,
  max_clock_skew_seconds INTEGER NOT NULL DEFAULT 90,
  allow_offline_buffer BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT attendance_settings_singleton CHECK (id = 1)
);

INSERT INTO public.attendance_settings (id)
VALUES (1)
ON CONFLICT (id) DO NOTHING;

-- QR broadcast sessions generated by teacher/admin device
CREATE TABLE IF NOT EXISTS public.attendance_qr_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scope_type TEXT NOT NULL CHECK (scope_type IN ('student', 'course', 'batch', 'branch', 'classroom_ble')),
  scope_student_id UUID,
  scope_course_id BIGINT,
  scope_batch_id BIGINT,
  scope_branch_id BIGINT,
  starts_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  qr_nonce TEXT NOT NULL,
  qr_payload_hash TEXT NOT NULL,
  created_by UUID,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (expires_at > starts_at)
);

CREATE INDEX IF NOT EXISTS idx_attendance_qr_sessions_active_time
  ON public.attendance_qr_sessions (is_active, starts_at, expires_at);

-- BLE proximity validations between teacher and student devices
CREATE TABLE IF NOT EXISTS public.attendance_ble_events (
  id BIGSERIAL PRIMARY KEY,
  qr_session_id UUID REFERENCES public.attendance_qr_sessions(id) ON DELETE CASCADE,
  teacher_device_id TEXT NOT NULL,
  student_device_id TEXT NOT NULL,
  student_id UUID,
  rssi INTEGER,
  estimated_distance_m NUMERIC(6,2),
  captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_valid BOOLEAN NOT NULL DEFAULT false,
  reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_attendance_ble_events_session_student
  ON public.attendance_ble_events (qr_session_id, student_id, captured_at DESC);

-- Final attendance events (accepted/rejected) with anti-fraud metadata
CREATE TABLE IF NOT EXISTS public.attendance_events (
  id BIGSERIAL PRIMARY KEY,
  qr_session_id UUID REFERENCES public.attendance_qr_sessions(id) ON DELETE SET NULL,
  student_id UUID NOT NULL,
  source TEXT NOT NULL CHECK (source IN ('qr', 'ble', 'hybrid', 'ble_proximity')),
  status TEXT NOT NULL CHECK (status IN ('present', 'rejected', 'pending_review')),
  marked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  teacher_device_id TEXT,
  student_device_id TEXT,
  ble_rssi INTEGER,
  estimated_distance_m NUMERIC(6,2),
  confidence_score NUMERIC(5,2) NOT NULL DEFAULT 0,
  rejection_reason TEXT,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_attendance_events_student_time
  ON public.attendance_events (student_id, marked_at DESC);

CREATE INDEX IF NOT EXISTS idx_attendance_events_session
  ON public.attendance_events (qr_session_id, marked_at DESC);

-- Optional daily consolidation view
CREATE OR REPLACE VIEW public.v_attendance_daily AS
SELECT
  student_id,
  date_trunc('day', marked_at) AS attendance_day,
  COUNT(*) FILTER (WHERE status = 'present') AS present_count,
  COUNT(*) FILTER (WHERE status = 'rejected') AS rejected_count,
  MAX(confidence_score) AS max_confidence
FROM public.attendance_events
GROUP BY student_id, date_trunc('day', marked_at);

COMMIT;


-- ============================================================
-- SOURCE: old -backend\migrations\stage_02_exam_scheduler_visibility.sql
-- ============================================================

-- Stage 02: Exam Scheduler, Visibility, Attempts, Shuffle, Negative Marking
-- Target: Supabase PostgreSQL

BEGIN;

-- Canonical exam schedule table
CREATE TABLE IF NOT EXISTS public.exam_schedules (
  id BIGSERIAL PRIMARY KEY,
  paper_set_id BIGINT REFERENCES public.paper_sets(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
  publish_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ,
  timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'published', 'closed', 'archived')),
  max_attempts INTEGER NOT NULL DEFAULT 1 CHECK (max_attempts >= 1),
  shuffle_questions BOOLEAN NOT NULL DEFAULT true,
  shuffle_options BOOLEAN NOT NULL DEFAULT true,
  negative_marking_enabled BOOLEAN NOT NULL DEFAULT false,
  marks_correct NUMERIC(8,3) NOT NULL DEFAULT 1,
  marks_wrong NUMERIC(8,3) NOT NULL DEFAULT 0,
  marks_unanswered NUMERIC(8,3) NOT NULL DEFAULT 0,
  negative_formula TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_exam_schedules_status_time
  ON public.exam_schedules (status, publish_at, start_at, end_at);

-- Assignment: supports per-student and by course/batch/branch
CREATE TABLE IF NOT EXISTS public.exam_assignments (
  id BIGSERIAL PRIMARY KEY,
  exam_schedule_id BIGINT NOT NULL REFERENCES public.exam_schedules(id) ON DELETE CASCADE,
  assignment_type TEXT NOT NULL CHECK (assignment_type IN ('student', 'course', 'batch', 'branch')),
  student_id UUID,
  course_id BIGINT,
  batch_id BIGINT,
  branch_id BIGINT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (
    (assignment_type = 'student' AND student_id IS NOT NULL AND course_id IS NULL AND batch_id IS NULL AND branch_id IS NULL)
    OR
    (assignment_type = 'course' AND course_id IS NOT NULL AND student_id IS NULL AND batch_id IS NULL AND branch_id IS NULL)
    OR
    (assignment_type = 'batch' AND batch_id IS NOT NULL AND student_id IS NULL AND course_id IS NULL AND branch_id IS NULL)
    OR
    (assignment_type = 'branch' AND branch_id IS NOT NULL AND student_id IS NULL AND course_id IS NULL AND batch_id IS NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_exam_assignments_lookup
  ON public.exam_assignments (assignment_type, student_id, course_id, batch_id, branch_id);

-- Enforce mandatory option shuffle for all exams per requirement
CREATE OR REPLACE FUNCTION public.trg_exam_schedule_enforce_shuffle()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.shuffle_options := true;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS exam_schedule_enforce_shuffle ON public.exam_schedules;
CREATE TRIGGER exam_schedule_enforce_shuffle
BEFORE INSERT OR UPDATE ON public.exam_schedules
FOR EACH ROW
EXECUTE FUNCTION public.trg_exam_schedule_enforce_shuffle();

-- Auto-derive end_at from start_at + duration if omitted
CREATE OR REPLACE FUNCTION public.trg_exam_schedule_derive_end_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.end_at IS NULL THEN
    NEW.end_at := NEW.start_at + (NEW.duration_minutes || ' minutes')::interval;
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS exam_schedule_derive_end_at ON public.exam_schedules;
CREATE TRIGGER exam_schedule_derive_end_at
BEFORE INSERT OR UPDATE ON public.exam_schedules
FOR EACH ROW
EXECUTE FUNCTION public.trg_exam_schedule_derive_end_at();

-- Extend session table for attempts/shuffle seeds/backward compatibility
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'exam_sessions'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'exam_sessions' AND column_name = 'exam_schedule_id'
    ) THEN
      ALTER TABLE public.exam_sessions ADD COLUMN exam_schedule_id BIGINT REFERENCES public.exam_schedules(id);
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'exam_sessions' AND column_name = 'attempt_no'
    ) THEN
      ALTER TABLE public.exam_sessions ADD COLUMN attempt_no INTEGER NOT NULL DEFAULT 1;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'exam_sessions' AND column_name = 'option_shuffle_seed'
    ) THEN
      ALTER TABLE public.exam_sessions ADD COLUMN option_shuffle_seed BIGINT;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'exam_sessions' AND column_name = 'submitted_at'
    ) THEN
      ALTER TABLE public.exam_sessions ADD COLUMN submitted_at TIMESTAMPTZ;
    END IF;
  END IF;
END
$$;

-- Visibility view: who can see exam now
CREATE OR REPLACE VIEW public.v_student_visible_exams AS
SELECT
  es.id AS exam_schedule_id,
  es.paper_set_id,
  es.title,
  es.publish_at,
  es.start_at,
  es.end_at,
  es.duration_minutes,
  es.max_attempts,
  es.shuffle_questions,
  es.shuffle_options,
  es.negative_marking_enabled,
  es.marks_correct,
  es.marks_wrong,
  es.marks_unanswered,
  ea.assignment_type,
  ea.student_id,
  ea.course_id,
  ea.batch_id,
  ea.branch_id
FROM public.exam_schedules es
JOIN public.exam_assignments ea ON ea.exam_schedule_id = es.id AND ea.is_active = true
WHERE es.status IN ('published', 'scheduled')
  AND now() >= es.publish_at
  AND now() >= es.start_at
  AND now() <= es.end_at;

COMMIT;
