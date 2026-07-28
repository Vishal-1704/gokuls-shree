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

