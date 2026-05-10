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

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- ROW LEVEL SECURITY POLICIES
-- These are the LAST LINE of defense in the database.
-- Even if someone bypasses the Node.js server, Supabase
-- will still enforce these rules at the DB level.
-- ============================================================

-- ── Helper function: get caller's role ───────────────────────
CREATE OR REPLACE FUNCTION current_user_role()
RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE auth_uid = auth.uid() AND status = 1 LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ── Helper function: get caller's branch_id ──────────────────
CREATE OR REPLACE FUNCTION current_user_branch()
RETURNS INT AS $$
  SELECT branch_id FROM profiles WHERE auth_uid = auth.uid() AND status = 1 LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ── Helper function: get caller's student_id (if student) ────
CREATE OR REPLACE FUNCTION current_student_id()
RETURNS INT AS $$
  SELECT s.id FROM students s
  JOIN profiles p ON s.profile_id = p.id
  WHERE p.auth_uid = auth.uid() AND p.status = 1 LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

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
ALTER TABLE audit_logs  ENABLE ROW LEVEL SECURITY;

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
