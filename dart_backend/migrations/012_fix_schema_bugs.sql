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
