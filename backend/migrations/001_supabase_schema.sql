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

  receipt_no      TEXT,
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
  created_at      TIMESTAMPTZ DEFAULT NOW()
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
