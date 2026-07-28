# 📚 Gokul Shree LMS — Complete Project Master Document
### Version 1.0 | Generated: July 2026
### ClassPlus-Style LMS + Zoho Employee Portal

---

> **Project:** Gokul Shree School Management & LMS Mobile App
> **Tech Stack:** Flutter (Mobile) · Node.js/Express (API) · Supabase (DB + Auth + Storage) · Render.com (Hosting)
> **Codebase:** `c:/Users/Lenovo/Music/Projects/gokuls-shree`
> **Backend:** `c:/Users/Lenovo/Music/Projects/gokuls-shree/backend`

---

## 📋 TABLE OF CONTENTS

1. [Project Vision & Goals](#1-project-vision--goals)
2. [System Architecture Overview](#2-system-architecture-overview)
3. [Multi-Role Access Design](#3-multi-role-access-design)
4. [Flutter Frontend — Module Architecture](#4-flutter-frontend--module-architecture)
5. [Backend API Layer Architecture](#5-backend-api-layer-architecture)
6. [Database Schema — Entity Relationships](#6-database-schema--entity-relationships)
7. [Security Architecture — 8 Defence Layers](#7-security-architecture--8-defence-layers)
8. [Zoho Employee Feature Architecture](#8-zoho-employee-feature-architecture)
9. [State Management — Riverpod Provider Tree](#9-state-management--riverpod-provider-tree)
10. [Backend Audit Report — 19 Issues Found](#10-backend-audit-report--19-issues-found)
11. [Implementation Plan — What Was Built](#11-implementation-plan--what-was-built)
12. [Hosting & Cost Analysis](#12-hosting--cost-analysis)
13. [Learning Roadmap](#13-learning-roadmap)
14. [Feature Backlog & Roadmap](#14-feature-backlog--roadmap)

---

## 1. Project Vision & Goals

### What Are We Building?
A **full-featured LMS (Learning Management System)** mobile application for Gokul Shree School — modelled on **ClassPlus** with additional **Zoho HR** features for employee/teacher management.

### Core Goals
| Goal | Description |
|------|-------------|
| **Multi-branch LMS** | One platform for all franchise branches under Gokul Shree |
| **4 User Roles** | Super Admin, Branch Admin, Teacher, Student — each with isolated data |
| **ClassPlus Features** | Course catalog, attendance, marksheets, certificates, online exams, ID cards |
| **Zoho Features** | Teacher payroll snapshot, leave tracker, employee profile, PF/ESI details |
| **Security First** | 8-layer security model — JWT + RLS + branch isolation + audit logging |
| **Mobile First** | Flutter app for Android/iOS, Supabase backend, Node.js for complex logic |

### What Makes This Different from a Basic School App
- **Branch isolation** — a teacher in Branch A can never see Branch B's students, even if they try
- **Granular permissions** — 26 named permissions per user (not just role-based), stored in DB
- **Zoho-style HR** — teachers get a full employee card: basic salary, HRA, DA, PF number, ESI number, causal leave balance, joining date
- **Audit trail** — every sensitive action (approve marksheet, collect fee, mark attendance) is logged with IP, timestamp, and actor

---

## 2. System Architecture Overview

```
┌────────────────────────────────────────────────────────────────┐
│                    📱 Flutter Mobile App                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ Super    │ │ Branch   │ │ Teacher  │ │ Student          │  │
│  │ Admin    │ │ Admin    │ │ Shell    │ │ Shell            │  │
│  │ Shell    │ │ Shell    │ │          │ │                  │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘  │
└────────────────────┬───────────────────────────────────────────┘
                     │ HTTPS + Bearer JWT
                     ▼
┌────────────────────────────────────────────────────────────────┐
│              ⚙️ Node.js / Express API (Render.com)             │
│                                                                │
│  Helmet → CORS → Rate Limiter → requireAuth → requirePermission│
│  → strictBranchGuard → studentSelfGuard → auditLog             │
│                                                                │
│  /auth  /students  /attendance  /fees  /courses                │
│  /employees  /notices  /documents  /branches                   │
└────────────┬──────────────────────────────┬───────────────────┘
             │ Service Role (bypasses RLS)  │
             ▼                              ▼
┌─────────────────────────┐   ┌────────────────────────────────┐
│  🗄️ Supabase PostgreSQL │   │   📦 Supabase Storage          │
│  14 tables + RLS        │   │   Photos · PDFs · Certificates │
│  Row Level Security     │   │   ID Cards · Marksheets        │
│  Real-time subscriptions│   └────────────────────────────────┘
└─────────────────────────┘
             ▲
             │ Direct SDK (RLS enforced)
             │
        Flutter App (for read-only, non-sensitive queries)
```

### Why Two Paths to Supabase?
- **Via Node.js** → For all **writes**, **sensitive reads**, and anything needing audit logs + permission checks
- **Direct Supabase SDK from Flutter** → For safe **read-only** queries (e.g. listing courses, reading own profile) where Supabase RLS is sufficient
- The **SERVICE ROLE key** (master key that bypasses RLS) lives ONLY on the Node.js server — never in the Flutter app

---

## 3. Multi-Role Access Design

### Role Hierarchy
```
👑 Super Admin (God Mode — all branches)
    │
    ├── 🏢 Branch Admin (own branch only)
    │       │
    │       └── 👨‍🏫 Teacher (own branch, own students)
    │
    └── 🎓 Student (own records only)
```

### What Each Role Can Do

#### 👑 Super Admin
- Full system control — all branches, all data
- Approve marksheets and certificates
- Register Branch Admins
- Reset any user's password
- View audit logs
- Franchise analytics across all branches
- Manage all courses, branches, subjects

#### 🏢 Branch Admin
- Enroll students (pending → admin approves)
- Record fee payments
- Mark and view attendance
- Issue admit cards
- Upload results and submit marksheets for approval
- Manage branch notices
- Register teachers for own branch
- ❌ Cannot see other branches' data
- ❌ Cannot approve own marksheets (requires Super Admin)

#### 👨‍🏫 Teacher
- Mark bulk student attendance for branch
- View all students in branch
- Upload exam marks
- View subjects assigned to them
- **Zoho Employee Profile Tab:**
  - View own designation, department, joining date
  - View payroll snapshot (Basic + HRA + DA + Gross Salary)
  - View PF account number, PAN, ESI number
  - View causal leave balance
- ❌ Cannot see fee records
- ❌ Cannot approve marksheets

#### 🎓 Student
- View own profile + ID card (works offline)
- View own attendance history with percentage
- View own fee payment history and balance due
- View own marksheet (only after super_admin approves)
- View own certificate (only after approved)
- Take online exams
- Browse course catalog (public)
- ❌ Cannot see any other student's data

### Permission Matrix (26 Granular Permissions)
```
READ_OWN_PROFILE       → Student, Teacher, Branch Admin, Super Admin
READ_OWN_FEES          → Student only
READ_OWN_ATTENDANCE    → Student only
READ_OWN_MARKSHEET     → Student only
READ_OWN_CERTIFICATE   → Student only
READ_OWN_IDCARD        → Student only
TAKE_EXAM              → Student only

MARK_ATTENDANCE        → Teacher, Branch Admin, Super Admin
READ_BRANCH_STUDENTS   → Teacher, Branch Admin, Super Admin
UPLOAD_MARKS           → Teacher, Branch Admin, Super Admin
READ_BRANCH_ATTENDANCE → Teacher, Branch Admin, Super Admin

ENROLL_STUDENT         → Branch Admin, Super Admin
RECORD_FEE             → Branch Admin, Super Admin
SUBMIT_MARKSHEET       → Branch Admin, Super Admin
ISSUE_ADMIT_CARD       → Branch Admin, Super Admin
READ_BRANCH_FEES       → Branch Admin, Super Admin
MANAGE_NOTICES         → Branch Admin, Super Admin
REGISTER_TEACHER       → Branch Admin, Super Admin
SETUP_OWN_BRANCH       → Branch Admin, Super Admin
ISSUE_CERTIFICATE      → Branch Admin, Super Admin

APPROVE_MARKSHEET      → Super Admin only
APPROVE_STUDENT        → Super Admin only
APPROVE_CERTIFICATE    → Super Admin only
READ_ALL_BRANCHES      → Super Admin only
MANAGE_BRANCHES        → Super Admin only
REGISTER_BRANCH_ADMIN  → Super Admin only
RESET_USER_PASSWORD    → Super Admin only
ACCESS_ALL_DATA        → Super Admin only
```

---

## 4. Flutter Frontend — Module Architecture

### Directory Structure
```
lib/src/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart          # Color tokens (Ink Navy, Gold CTA, etc.)
│   │   ├── app_typography.dart      # Font styles (Inter, Outfit)
│   │   └── app_theme.dart           # ThemeData (dark theme only)
│   ├── models/
│   │   └── user_session.dart        # UserSession model (role, branchId, permissions)
│   ├── providers/
│   │   └── session_provider.dart    # Riverpod: current user session
│   ├── services/
│   │   └── supabase_service.dart    # Supabase direct SDK calls
│   └── routing/
│       └── app_router.dart          # GoRouter + role-based redirect guards
│
└── features/
    ├── auth/
    │   ├── presentation/
    │   │   ├── login_screen.dart
    │   │   ├── account_screen.dart      # Shared profile page
    │   │   └── forgot_password_screen.dart
    │   └── data/
    │       └── supabase_auth_notifier.dart
    │
    ├── student/
    │   ├── presentation/
    │   │   ├── student_dashboard_screen.dart
    │   │   ├── student_attendance_screen.dart
    │   │   ├── student_fee_status_screen.dart
    │   │   ├── student_id_card_screen.dart
    │   │   ├── student_exams_screen.dart
    │   │   └── student_marksheet_screen.dart
    │   ├── data/
    │   │   └── student_repository.dart  # All student data providers
    │   └── routing/
    │       └── student_routes.dart
    │
    ├── teacher/
    │   ├── presentation/
    │   │   ├── teacher_dashboard_screen.dart  # ← UPGRADED: 2 tabs
    │   │   │                                  #   Tab 1: Attendance stats + Subjects
    │   │   │                                  #   Tab 2: Zoho Employee Profile
    │   │   ├── teacher_attendance_screen.dart  # Bulk mark attendance
    │   │   ├── teacher_students_screen.dart    # Branch student list
    │   │   └── teacher_results_upload_screen.dart
    │   ├── data/
    │   │   └── attendance_repository.dart  # ← UPGRADED: + 3 new providers
    │   └── routing/
    │       └── teacher_routes.dart
    │
    ├── admin/
    │   ├── presentation/
    │   │   ├── admin_dashboard_screen.dart
    │   │   ├── add_student_screen.dart
    │   │   ├── fee_management_screen.dart
    │   │   ├── marksheet_generator_screen.dart
    │   │   ├── exam_scheduler_screen.dart
    │   │   └── branch_registration_screen.dart
    │   └── data/
    │       └── admin_repository.dart
    │
    ├── home/
    │   ├── presentation/
    │   │   ├── home_screen.dart     # Role-aware landing (routes by role)
    │   │   └── menu_screen.dart
    │   └── routing/
    │
    ├── courses/
    │   └── presentation/
    │       └── courses_screen.dart  # Public course catalog (no auth required)
    │
    └── documents/
        └── presentation/
            ├── documents_screen.dart
            └── certificates_screen.dart
```

### Navigation — GoRouter Role Guard Logic
```
User opens app
    │
    ▼
sessionProvider checks auth state
    │
    ├── Not logged in → redirect to /login
    │
    └── Logged in → check path vs role
            │
            ├── Student → /student/home (and /student/* paths)
            ├── Teacher → /teacher/home (and /teacher/* paths)
            ├── Branch Admin → /branch-admin/home (and /branch-admin/* paths)
            └── Super Admin → any path allowed
```

**Key fix made:** Route guard now uses `path.startsWith('/role-prefix')` instead of exact matching — so tab sub-routes (`/teacher/attendance`, `/student/fees`) no longer get redirected back to home.

---

## 5. Backend API Layer Architecture

### Server Entry Point — `src/server.js`
```
Security Middleware Stack (applied to every request):
  1. Helmet          → X-Frame-DENY, X-Content-Type-Options, Referrer-Policy
  2. Trust Proxy     → Correct IP detection on Render.com
  3. CORS            → Whitelist from ALLOWED_ORIGINS env var
  4. Morgan          → Request logging (combined in prod, dev in dev)
  5. Body Parser     → JSON + urlencoded, 5MB max
  6. Extra Headers   → nosniff, DENY frame, no-referrer
```

### Route Modules

| Route | File | Key Endpoints |
|-------|------|--------------|
| `/api/v1/auth` | `auth.routes.js` | POST /login, /register, /logout, /refresh, /send-otp, /verify-otp, GET /me |
| `/api/v1/students` | `student.routes.js` | GET / (branch list), GET /me, GET /:id, POST / (enroll), PUT /:id, PATCH /:id/approve |
| `/api/v1/attendance` | `attendance.routes.js` | GET /me, POST /mark, GET / (admin view) |
| `/api/v1/fees` | `fee.routes.js` | GET /me, GET /, POST / |
| `/api/v1/courses` | `course.routes.js` | GET /, GET /:id, GET /meta/categories |
| `/api/v1/notices` | `notice.routes.js` | GET /, POST /, DELETE /:id |
| `/api/v1/documents` | `documents.routes.js` | GET /, POST /upload, GET /:id/download |
| `/api/v1/branches` | `branch.routes.js` | GET /, POST /, PATCH /:id |
| `/api/v1/employees` | ⚠️ MISSING — needs to be built | GET /me, PATCH /:id, GET /:id/payslip |
| `/api/v1/downloads` | `download.routes.js` | GET / |

### Middleware Stack Per Request Flow
```
Incoming Request
      │
      ▼
  requireAuth
  ├── Check Authorization header (Bearer token)
  ├── Validate JWT via supabase.auth.getUser(token)
  ├── Fetch profile from profiles table (auth_uid = jwt.sub)
  ├── Check profile.status === 1 (active)
  ├── Check role is valid (super_admin|branch_admin|teacher|student)
  └── Check branch_id assigned (for non-super-admin)
      │
      ▼
  requirePermission('PERMISSION_KEY')
  └── Look up PERMISSIONS matrix → check req.role is in allowed list
      │
      ▼
  strictBranchGuard
  ├── super_admin: req.queryBranchId = null (see all)
  └── others: req.queryBranchId = profile.branch_id (LOCKED)
      │
      ▼
  studentSelfGuard (student-only routes)
  └── Fetch student record by profile_id → attach req.studentId
      │
      ▼
  sensitiveLimiter (write operations)
  └── Extra rate limit for mutations (prevent abuse)
      │
      ▼
  auditLog('ACTION_NAME')
  └── INSERT into audit_logs (action, profile_id, role, ip, path, status)
      │
      ▼
  Route Handler → Supabase DB Query (always uses req.queryBranchId)
```

---

## 6. Database Schema — Entity Relationships

### All 14 Tables

```
branches              ← Root table. Every branch is a franchise centre.
    │
    ├── profiles      ← All users (auth linked). role + permissions stored here.
    │       │
    │       └── employees ← Teacher/staff HR record. Salary, PF, ESI, leaves.
    │               │
    │               └── teacher_subjects ← [NEEDS TO BE CREATED]
    │                                       Maps teacher → subjects they teach
    │
    ├── students      ← Student registry. Full admission data.
    │       │
    │       ├── student_attendance ← Daily P/A/L/H per student
    │       ├── fee_payments       ← Payment receipts per student
    │       ├── marksheets         ← Results (JSON marks). Approval workflow.
    │       ├── certificates       ← Issued after marksheet approved.
    │       ├── admit_cards        ← Exam admit cards
    │       ├── id_cards           ← Physical ID card records
    │       └── exam_results       ← Online exam scores
    │
    ├── courses       ← Course catalog (DCA, DIT, Yoga, etc.)
    │       └── subjects ← Subjects per course (CF, C Programming, etc.)
    │
    ├── exam_categories ← Online exam types
    │       └── exam_questions ← MCQ bank
    │
    ├── notices       ← Branch announcements
    ├── downloads     ← Syllabus, forms, study material
    ├── states        ← Location lookup
    ├── districts     ← Location lookup
    ├── salary_advances ← Employee advance tracking
    └── audit_logs    ← Append-only action log (super_admin read only)
```

### Critical Column Notes
| Table | Column | Note |
|-------|--------|------|
| `profiles` | `id` (UUID) | Internal ID — used by `employees.profile_id` |
| `profiles` | `auth_uid` (UUID) | Links to Supabase `auth.users.id` |
| `student_attendance` | `attendance_date` | ⚠️ NOT `date` — many queries use wrong column name |
| `courses` | `status` (SMALLINT) | ⚠️ NOT `is_active` — course.routes.js uses wrong column |
| `students` | `status` 0=pending, 1=active | New registrations start at 0 |
| `marksheets` | `status` 0=pending, 1=approved | Students only see status=1 |

### Row Level Security (RLS) Policies Summary
```
students:          student sees own, teacher/admin sees branch, super_admin sees all
marksheets:        student sees own APPROVED only, admin sees branch, super_admin all
fee_payments:      student sees own, branch_admin sees branch, teacher BLOCKED
certificates:      student sees own APPROVED only, super_admin all
student_attendance: student sees own, teacher/admin sees branch, super_admin all
profiles:          own profile always + branch admin sees branch profiles
audit_logs:        super_admin read only, INSERT allowed (append-only)
```

---

## 7. Security Architecture — 8 Defence Layers

```
Layer 1: 🛡️ Helmet
  └── Sets HTTP security headers on every response
      X-Frame-Options: DENY
      X-Content-Type-Options: nosniff
      Strict-Transport-Security (HTTPS only)
      Referrer-Policy: no-referrer

Layer 2: 🌐 CORS
  └── Only whitelisted origins in ALLOWED_ORIGINS env var
      No wildcards in production

Layer 3: ⏱️ Rate Limiter
  ├── Login endpoint: 5 requests per 15 minutes per IP
  └── API endpoints: 120 requests per minute per IP

Layer 4: 🔑 requireAuth Middleware
  ├── Authorization header must be present + Bearer format
  ├── JWT validated via Supabase Auth (checks expiry + signature)
  ├── profiles row must exist for this auth user
  ├── profile.status must be 1 (not suspended)
  └── branch_id must be set (for non-super-admin)

Layer 5: 👮 requirePermission Middleware
  └── Role-permission matrix check (26 named permissions)
      Unknown permission key → HTTP 500 (coding bug alert)
      Role not in allowed list → HTTP 403

Layer 6: 🏢 strictBranchGuard Middleware
  ├── super_admin: req.queryBranchId = null (can see all)
  └── everyone else: req.queryBranchId = profile.branch_id
      Client-sent branch_id is DELETED and replaced server-side
      This prevents privilege escalation via forged body params

Layer 7: 🎓 studentSelfGuard Middleware
  ├── Only for student-only routes (/me endpoints)
  ├── Fetches student record by profile_id
  └── Attaches req.studentId — routes use this ONLY, never query params

Layer 8: 🗄️ Supabase Row Level Security
  └── Database-level enforcement (bypasses all above layers if someone
      connects directly to DB — this is the final defence)
      Even if Node.js server is compromised, RLS still protects data
```

---

## 8. Zoho Employee Feature Architecture

### What the Teacher Sees

**Tab 2 of Teacher Dashboard — "Zoho Employee Profile":**

```
┌──────────────────────────────────────────────┐
│  👤 RAMESH KUMAR                             │
│  Senior Faculty · Dept: Computer Science     │
└──────────────────────────────────────────────┘

Leave Entitlements:
┌──────────┬──────────┬──────────────────────┐
│  Total   │  Taken   │  Balance Available   │
│  15 days │  3 days  │  12 days             │
└──────────┴──────────┴──────────────────────┘

Payroll Snapshot (Monthly):
  Basic Salary           ₹45,000.00
  House Rent Allowance   ₹8,000.00
  Dearness Allowance     ₹5,000.00
  Special Allowances     ₹2,000.00
  ──────────────────────────────
  Gross Salary           ₹60,000.00

  PF Account No   PF-982341-GS
  ESI No          ESI-9812-76
  PAN Card        ABCDE1234F

Registry Details:
  📧 ramesh@gokulshree.in
  📞 9876543210
  📅 Joined: 2023-08-15
  📍 Gokul Shree Campus, Uttar Pradesh
```

### Database Source — `employees` table
```sql
employees (
  id, profile_id (UUID → profiles.id),
  branch_id, name, designation, department,
  gender, doj (date of joining), contact, email, address,
  basic_salary, hra, da, other_allowance,
  pf_account_no, pan_no, esi_no,
  causal_leave (total leave days), status
)
```

### Riverpod Providers (Flutter)
```dart
teacherEmployeeProfileProvider  // FutureProvider<Map<String,dynamic>?>
  → supabase.from('employees')
    .select('*, branches(name)')
    .eq('profile_id', session.profileId)
    .maybeSingle()
  → Returns mock data if null (for dev/no DB seed)

teacherSubjectsProvider  // FutureProvider<List<Map<String,dynamic>>>
  → supabase.from('subjects')
    .select('*, courses(title)')
    .eq('branch_id', session.branchId)
    .eq('status', 1)
  → Returns mock subjects if empty

teacherStudentAttendanceStatsProvider  // FutureProvider<Map<String,dynamic>>
  → Fetches all student IDs in branch
  → Fetches today's attendance records
  → Computes: total, present, absent, pending, rate%
  → Returns mock stats on error (90.6% rate, 35 students)
```

---

## 9. State Management — Riverpod Provider Tree

```
sessionProvider (StateProvider<UserSession?>)
    │
    │── Watched by all feature providers
    │── Provides: role, branchId, profileId, name, email, permissions
    │
    ├── supabaseAuthNotifierProvider (StateNotifier)
    │     Methods: signIn, signOut, signUp, resetPassword, updateProfile, adminLogin
    │
    ├── STUDENT PROVIDERS (when role == student)
    │     ├── studentRepositoryProvider
    │     ├── studentProfileProvider         → FutureProvider
    │     ├── studentAttendanceProvider      → FutureProvider
    │     ├── studentFeeStatusProvider       → FutureProvider
    │     ├── studentExamResultsProvider     → FutureProvider
    │     ├── studentAcademicCalendarProvider → FutureProvider
    │     └── studentAcademicCalendarProvider → FutureProvider
    │
    ├── TEACHER PROVIDERS (when role == teacher) ⭐ NEW
    │     ├── attendanceRepositoryProvider
    │     ├── teacherEmployeeProfileProvider    → FutureProvider (Zoho data)
    │     ├── teacherSubjectsProvider           → FutureProvider (subjects taught)
    │     └── teacherStudentAttendanceStatsProvider → FutureProvider (branch stats)
    │
    └── ADMIN PROVIDERS (when role == branch_admin | super_admin)
          ├── adminRepositoryProvider
          ├── adminStudentsProvider     → FutureProvider
          ├── adminFeesProvider         → FutureProvider
          └── adminNoticesProvider      → FutureProvider
```

---

## 10. Backend Audit Report — 19 Issues Found

### 🔴 CRITICAL BUGS (5) — Will Cause Runtime Crashes

#### Issue 1 — `course.routes.js` — Wrong Database Client
```js
// WRONG — uses legacy pg client + non-existent column
const db = require('../config/database');
let query = 'SELECT * FROM courses WHERE is_active = true';

// FIX — use Supabase client + correct column
const { supabase } = require('../config/supabase');
const { data } = await supabase.from('courses').select('*').eq('status', 1);
```

#### Issue 2 — Column Name Mismatch: `date` vs `attendance_date`
```dart
// WRONG — column doesn't exist
.eq('date', todayStr)

// FIX — correct column name from schema
.eq('attendance_date', todayStr)
```
Affected files: `teacher_attendance_screen.dart`, `student_repository.dart`, `attendance_repository.dart`

#### Issue 3 — `fee.routes.js` — `COLLECT_FEE` Permission Doesn't Exist → HTTP 500
```js
// WRONG — COLLECT_FEE not in PERMISSIONS matrix
requirePermission('COLLECT_FEE')

// FIX
requirePermission('RECORD_FEE')
```

#### Issue 4 — `fee.routes.js` — `READ_OWN_FEE` vs `READ_OWN_FEES` → HTTP 500
```js
// WRONG — missing 'S'
requirePermission('READ_OWN_FEE')

// FIX
requirePermission('READ_OWN_FEES')
```

#### Issue 5 — `role.guard.js` — `READ_BRANCH_ATTENDANCE` Missing → HTTP 500 for Admins
```js
// MISSING from PERMISSIONS — attendance admin list always fails
// FIX: Add to PERMISSIONS object in role.guard.js
READ_BRANCH_ATTENDANCE: [ROLES.TEACHER, ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
```

---

### 🟠 SECURITY VULNERABILITIES (4)

#### Issue 6 — Logout Doesn't Invalidate Token
```js
// WRONG — signs out service role client, not the user
await supabase.auth.signOut();

// FIX — use user's own token
const token = req.headers.authorization?.split(' ')[1];
const userClient = supabaseUser(token);
await userClient.auth.signOut();
```

#### Issue 7 — Student Can Self-Assign to Any Branch
Student sends `branch_id: 999` in registration body — it gets accepted without validation. Fix: validate branch exists and is active before assigning.

#### Issue 8 — `audit_logs` Policy Created Before RLS Enabled
```sql
-- WRONG ORDER
CREATE POLICY "audit_insert_only" ON audit_logs FOR INSERT WITH CHECK (true);
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;  -- comes AFTER policy

-- CORRECT ORDER
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_insert_only" ON audit_logs FOR INSERT WITH CHECK (true);
```

#### Issue 9 — Missing DELETE Deny Policy on `students` Table
```sql
-- ADD THIS to prevent unintended student record deletion
CREATE POLICY "students_no_delete" ON students FOR DELETE USING (false);
```

---

### 🟡 SCHEMA ISSUES (4)

#### Issue 10 — `student_attendance` Has No UNIQUE Constraint (Upsert Breaks)
```sql
-- The backend does: .upsert(rows, { onConflict: 'student_id,attendance_date' })
-- But there's no constraint! FIX:
ALTER TABLE student_attendance
  ADD CONSTRAINT student_attendance_unique UNIQUE (student_id, attendance_date);
```

#### Issue 11 — `fee_payments.receipt_no` Has No UNIQUE Constraint
```sql
ALTER TABLE fee_payments
  ADD CONSTRAINT fee_receipt_no_unique UNIQUE (receipt_no);
```

#### Issue 12 — No `teacher_subjects` Junction Table
Every teacher sees ALL subjects in branch. Fix: create proper many-to-many mapping.
```sql
CREATE TABLE IF NOT EXISTS teacher_subjects (
  id          SERIAL PRIMARY KEY,
  teacher_id  UUID REFERENCES profiles(id),
  subject_id  INT REFERENCES subjects(id),
  branch_id   INT REFERENCES branches(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

#### Issue 13 — `profiles.id` vs `profiles.auth_uid` Confusion
- `profiles.id` = internal UUID (used by `employees.profile_id`) ✅
- `profiles.auth_uid` = Supabase auth UID
- `session.profileId` in Flutter MUST map to `profiles.id`, NOT `auth_uid`
- Check `session_provider.dart` carefully — wrong mapping → employee queries always return null

---

### 🔵 DESIGN ISSUES (6)

#### Issue 14 — `sync.routes.js` Exists but Is Never Mounted in `server.js`
Either import and mount it, or delete it to reduce confusion.

#### Issue 15 — No Employee REST API
Payroll data is fetched client-side (Flutter → Supabase direct). Sensitive salary/PF data should go through server with audit logging.
```
Needed: src/routes/employee.routes.js
  GET  /api/v1/employees/me        → teacher views own record
  PATCH /api/v1/employees/:id      → super_admin updates salary/leaves
  GET  /api/v1/employees/:id/payslip → generate PDF payslip
```

#### Issue 16 — `bcryptjs` Is Unused Dead Weight
```json
// Remove from package.json — Supabase handles all password hashing
"bcryptjs": "^2.4.3"  // DELETE
```

#### Issue 17 — Mixed DB Clients (`pg` + `supabase-js`)
Only `course.routes.js` uses `pg`. All others use Supabase. Eliminate `pg` dependency entirely.

#### Issue 18 — No Push Notifications (FCM)
No Firebase Cloud Messaging integration yet. Teachers can't notify students of new results/notices.

#### Issue 19 — `.env` File Missing from Flutter Project
`pubspec.yaml` assets section references `.env` but the file doesn't exist → build warning on every `flutter analyze`.

### Complete Issues Summary

| # | Severity | File | Issue |
|---|----------|------|-------|
| 1 | 🔴 CRITICAL | `course.routes.js` | Legacy pg client + `is_active` column doesn't exist |
| 2 | 🔴 CRITICAL | Schema + Flutter | `date` vs `attendance_date` column mismatch everywhere |
| 3 | 🔴 CRITICAL | `fee.routes.js` | `COLLECT_FEE` permission undefined → HTTP 500 |
| 4 | 🔴 CRITICAL | `fee.routes.js` | `READ_OWN_FEE` should be `READ_OWN_FEES` → HTTP 500 |
| 5 | 🔴 CRITICAL | `role.guard.js` | `READ_BRANCH_ATTENDANCE` missing → HTTP 500 |
| 6 | 🟠 SECURITY | `auth.routes.js` | `signOut()` doesn't invalidate user's JWT token |
| 7 | 🟠 SECURITY | `auth.routes.js` | Student can self-assign to any branch_id |
| 8 | 🟠 SECURITY | `002_security_rls.sql` | Policy created before RLS enabled |
| 9 | 🟠 SECURITY | `002_security_rls.sql` | No DELETE deny policy on students table |
| 10 | 🟡 SCHEMA | `student_attendance` | No UNIQUE constraint — upsert on conflict fails |
| 11 | 🟡 SCHEMA | `fee_payments` | No UNIQUE on receipt_no — duplicates possible |
| 12 | 🟡 SCHEMA | `subjects` | No teacher-subject junction table |
| 13 | 🟡 SCHEMA | `session_provider.dart` | profileId may map to wrong UUID column |
| 14 | 🔵 DESIGN | `server.js` | `sync.routes.js` exists but never mounted |
| 15 | 🔵 DESIGN | Backend | No employee REST API — payroll exposed client-side |
| 16 | 🔵 DESIGN | `package.json` | `bcryptjs` unused dead weight |
| 17 | 🔵 DESIGN | `course.routes.js` | Mixed pg + supabase-js clients |
| 18 | 🔵 DESIGN | Flutter | No FCM push notifications |
| 19 | 🔵 DESIGN | Flutter | `.env` asset referenced in pubspec but missing |

---

## 11. Implementation Plan — What Was Built

### Phase 1: Flutter Compiler & Routing Fixes ✅ DONE

#### Fix 1 — `student_id_card_screen.dart`
```dart
// ADDED — resolves "Undefined class 'UserSession'" error
import '../../../core/models/user_session.dart';
```

#### Fix 2 — `test/widget_test.dart`
Added concrete implementations for all missing mock overrides:
- `resetPassword(String email)`
- `signOut()`
- `signUp({...all params...})`
- `updateProfile({...params...})`
Fixed dangling `}) async {}` syntax error on line 41.

#### Fix 3 — `app_router.dart` Route Guard Refactor
```dart
// BEFORE — exact path matching (blocks all sub-routes)
final allowedPaths = <String>{ session.homeRoute, '/teacher/attendance', ... };
return allowedPaths.contains(path);

// AFTER — prefix matching (allows all role sub-routes)
switch (session.role) {
  case UserRole.teacher:
    if (path.startsWith('/teacher')) return true;  // ← All teacher/* routes pass
    return false;
  case UserRole.student:
    if (path.startsWith('/student')) return true;
    // ...
}
```

Also registered the missing `/courses` route:
```dart
GoRoute(
  path: '/courses',
  builder: (context, state) => const CoursesScreen(),
),
```

### Phase 2: Teacher Zoho Portal ✅ DONE

#### New Riverpod Providers in `attendance_repository.dart`
Three new providers added:
1. **`teacherEmployeeProfileProvider`** — fetches `employees` table by `profile_id`, returns mock Zoho data if not seeded
2. **`teacherSubjectsProvider`** — fetches `subjects` for branch, returns 3 mock subjects if empty
3. **`teacherStudentAttendanceStatsProvider`** — computes today's attendance stats (total, present, absent, pending, rate%)

#### Rebuilt `teacher_dashboard_screen.dart`
Converted to 2-tab layout using `DefaultTabController`:

**Tab 1 — Dashboard:**
- Circular progress attendance card (branch stats)
- Horizontal scrolling "Subjects I Teach" catalog
- Quick action tiles (Mark Attendance, View Students, Upload Results)
- Permission-aware — locked tiles shown if no permission

**Tab 2 — Zoho Employee Profile:**
- Employee identity card (name, designation, department)
- Leave tracker (Total · Taken · Balance) — 3-column grid
- Payroll snapshot (Basic, HRA, DA, Allowances, Gross)
- Statutory section (PF number, ESI, PAN)
- Registry details (email, phone, joining date, address)
- Pull-to-refresh support on both tabs

---

## 12. Hosting & Cost Analysis

### Current Setup
```
Flutter App (Android/iOS — free to build)
    ↓
Render.com (Node.js server — FREE tier)
    ↓
Supabase (PostgreSQL DB + Auth + Storage — FREE tier)
```
**Current monthly cost: ₹0**

### Limitation of Free Tier
- Render free: **sleeps after 15 minutes** → 30-60 second cold start for first request
- Supabase free: **DB pauses after 7 days inactivity** → wake it up in dashboard
- Both: **Not for production with real users** who will notice delays

### Platform Comparison

| Platform | Type | Free? | Monthly Cost | Puppeteer/PDF | Cold Start | Best For |
|----------|------|--------|-------------|---------------|-----------|----------|
| **Render.com** | PaaS | ✅ Yes | $0 (free) / $7 (paid) | ✅ Yes | ⚠️ 30-60s free | Current setup — easiest |
| **Hostinger VPS** | VPS | ❌ No | ₹149/month | ✅ Yes | ✅ None | Cheapest production option |
| **AIC Cloud** | VPS | ❌ No | ₹99/month | ✅ Yes | ✅ None | Absolute cheapest, India server |
| **Railway.app** | PaaS | ❌ No | $5/month | ✅ Yes | ✅ None | Better DX than Render |
| **Fly.io** | PaaS | ❌ No | $2-3/month | ✅ Yes | ⚠️ Configurable | Pay-as-you-go |
| **Vercel** | Serverless | ✅ Yes | Free / $20 | ❌ 50MB limit | ⚡ Fast | ❌ NOT suitable (no Puppeteer) |
| **Firebase** | BaaS | ✅ Limited | $0 / Pay-per-use | ✅ Cloud Functions | ⚡ Fast | ❌ NOT suitable (NoSQL, not SQL) |
| **Supabase Edge** | Serverless | ✅ 500K calls | Free / $25 Pro | ❌ No Puppeteer | ⚡ Fast | Future option (rewrite backend) |

### Recommended Pricing by Stage

```
📌 RIGHT NOW (Building & Testing):
   Render FREE + Supabase FREE = ₹0/month
   Perfect. Don't spend anything yet.

📌 WHEN YOU GET REAL USERS (Production):
   Option A (Cheapest): Hostinger VPS ₹149/mo + Supabase Free = ₹149/month
   Option B (Easiest):  Render Paid $7/mo (~₹630) + Supabase Free = ₹630/month

📌 WHEN YOU SCALE (100+ branches):
   Hostinger VPS 2GB ₹299/mo + Supabase Pro $25/mo (~₹2,250) = ~₹2,550/month
```

### Why NOT to Switch
- ❌ **Firebase** — Your schema is relational SQL with 14 tables and JOINs. Firebase is NoSQL. Migration = months of wasted work.
- ❌ **Vercel** — 50MB function limit kills Puppeteer (200MB). Your PDF generation breaks entirely.
- ✅ **Stay on Render + Supabase** — exact right choice for this project's requirements.

---

## 13. Learning Roadmap

### Skills Required for This Project

| Skill | Why You Need It | Where to Learn |
|-------|----------------|----------------|
| **Flutter & Dart** | Entire mobile app | flutter.dev/learn |
| **Riverpod** | State management | riverpod.dev |
| **GoRouter** | Navigation & role guards | pub.dev/go_router |
| **Supabase** | DB + Auth + Storage | supabase.com/docs |
| **PostgreSQL / SQL** | Understanding schema, writing queries | postgresqltutorial.com |
| **RLS (Row Level Security)** | Data protection at DB level | Supabase docs → Auth → RLS |
| **Node.js + Express** | Backend API server | expressjs.com |
| **REST APIs** | Flutter ↔ Backend communication | Any API fundamentals course |
| **JWT Authentication** | How login tokens work | jwt.io |

### Recommended Learning Order

```
Week 1:  Flutter basics + Dart + Riverpod state management
Week 2:  Supabase dashboard — run SQL migrations, test RLS policies
Week 3:  GoRouter navigation — understand shell routes + guards
Week 4:  Node.js + Express — understand middleware chain
Month 2: Fix all 19 audit issues → Deploy → Test on device
Month 3: Add missing features (employee API, PDF payslip, notifications)
Month 4: LMS course content layer (ClassPlus phase)
```

---

## 14. Feature Backlog & Roadmap

### ✅ Completed
- [x] Flutter routing guard refactor (prefix-based path matching)
- [x] `/courses` route registered in GoRouter
- [x] `UserSession` import fix in student_id_card_screen.dart
- [x] Widget test compilation fixes (mock overrides)
- [x] `teacherEmployeeProfileProvider` — Zoho payroll data
- [x] `teacherSubjectsProvider` — subjects taught
- [x] `teacherStudentAttendanceStatsProvider` — branch attendance stats
- [x] Teacher dashboard rebuilt (2-tab: Dashboard + Zoho Employee Profile)
- [x] Backend audit — 19 issues documented

### 🔴 Critical Fixes (Do Immediately)
- [ ] Fix `course.routes.js` — rewrite with Supabase client, fix `is_active` → `status`
- [ ] Fix `fee.routes.js` — `COLLECT_FEE` → `RECORD_FEE`, `READ_OWN_FEE` → `READ_OWN_FEES`
- [ ] Fix `role.guard.js` — add `READ_BRANCH_ATTENDANCE` to PERMISSIONS
- [ ] Fix `auth.routes.js` — fix logout to invalidate user token
- [ ] Fix all Dart queries — `'date'` → `'attendance_date'`
- [ ] Add `UNIQUE(student_id, attendance_date)` constraint to DB
- [ ] Add `UNIQUE(receipt_no)` to fee_payments
- [ ] Create `.env` file in Flutter project root

### 🟡 Next Sprint
- [ ] Build `src/routes/employee.routes.js` (GET /me, PATCH /:id)
- [ ] Create `teacher_subjects` junction table in DB
- [ ] Fix student branch_id validation on registration
- [ ] Run all migration SQL files in Supabase dashboard (001 → 011)
- [ ] Deploy backend to Render.com
- [ ] Test all 4 role flows end-to-end on device

### 🟢 Month 2
- [ ] PDF Payslip Generator (server-side using pdf-lib)
- [ ] Leave application workflow for teachers
- [ ] Push Notifications (FCM — Firebase Cloud Messaging for notifications only)
- [ ] Student ID card offline caching (Hive)
- [ ] Marksheet approval UI for Super Admin
- [ ] Certificate PDF generation + download

### 🔵 Future — LMS Phase 2 (ClassPlus Features)
- [ ] Course detail screens
- [ ] Video/content player integration
- [ ] Study material upload for teachers
- [ ] Student progress tracking per course/subject
- [ ] Parent portal (4th role expansion)
- [ ] Exam scheduling with notifications
- [ ] Result SMS/Email notification system

---

## Quick Reference — Key Files

| Purpose | File Path |
|---------|-----------|
| Router + Role Guard | [app_router.dart](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/lib/src/routing/app_router.dart) |
| Teacher Dashboard (Zoho) | [teacher_dashboard_screen.dart](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/lib/src/features/teacher/presentation/teacher_dashboard_screen.dart) |
| Teacher Providers | [attendance_repository.dart](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/lib/src/features/teacher/data/attendance_repository.dart) |
| Student Data | [student_repository.dart](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/lib/src/features/student/data/student_repository.dart) |
| Auth Middleware | [auth.middleware.js](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/backend/src/middleware/auth.middleware.js) |
| Permission Matrix | [role.guard.js](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/backend/src/middleware/role.guard.js) |
| Fee Routes (broken) | [fee.routes.js](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/backend/src/routes/fee.routes.js) |
| Course Routes (broken) | [course.routes.js](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/backend/src/routes/course.routes.js) |
| Main DB Schema | [001_supabase_schema.sql](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/backend/migrations/001_supabase_schema.sql) |
| RLS Policies | [002_security_rls.sql](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/backend/migrations/002_security_rls.sql) |
| Supabase Config | [supabase.js](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/backend/src/config/supabase.js) |
| Server Entry | [server.js](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/backend/src/server.js) |

---

*Document generated from full conversation analysis — July 2026*
*Project: Gokul Shree LMS | Stack: Flutter + Node.js + Supabase + Render.com*
