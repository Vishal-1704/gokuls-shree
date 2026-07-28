# 🏗️ Gokul Shree LMS — Full-Stack Architecture Design
### ClassPlus-Style LMS + Zoho-Style Employee Portal

---

## 1. System Overview

```mermaid
graph TB
    subgraph CLIENT["📱 Flutter Mobile App"]
        direction TB
        SA[Super Admin Shell]
        BA[Branch Admin Shell]
        TC[Teacher Shell]
        ST[Student Shell]
    end

    subgraph BACKEND["⚙️ Node.js / Express API Layer"]
        direction TB
        GW[API Gateway\nHelmet · CORS · Rate Limiter]
        AM[Auth Middleware\nJWT Validation]
        RG[Role Guard\nPermission Matrix]
        AR[Auth Routes]
        SR[Student Routes]
        TR[Teacher Routes]
        FR[Fee Routes]
        ATR[Attendance Routes]
        CR[Course Routes]
        ER[Employee Routes]
        AL[Audit Logger]
    end

    subgraph SUPABASE["🗄️ Supabase — Database + Auth + Storage"]
        direction TB
        AUTH[Supabase Auth\nJWT Issuer]
        DB[(PostgreSQL\nRLS Enforced)]
        ST2[Supabase Storage\nDocs · Photos · PDFs]
        REALTIME[Realtime\nPresence · Notifications]
    end

    CLIENT -->|HTTPS + Bearer JWT| GW
    GW --> AM
    AM --> RG
    RG --> AR & SR & TR & FR & ATR & CR & ER
    AR & SR & TR & FR & ATR & CR & ER --> AL
    AR & SR & TR & FR & ATR & CR & ER -->|Service Role| DB
    AR --> AUTH
    DB --- ST2
    REALTIME --- DB
    CLIENT -->|Direct Supabase SDK\nRLS Protected| DB
    CLIENT -->|Storage SDK| ST2
```

---

## 2. Multi-Role Access Architecture

```mermaid
graph LR
    subgraph ROLES["User Roles Hierarchy"]
        SA2[👑 Super Admin\nAll Branches]
        BA2[🏢 Branch Admin\nOwn Branch]
        TC2[👨‍🏫 Teacher\nOwn Branch]
        ST2[🎓 Student\nOwn Records]
    end

    subgraph ACCESS["What Each Role Sees"]
        SA2 -->|Full System Control| AC1["
        ✅ All Branches Dashboard
        ✅ Approve Marksheets + Certs
        ✅ Register Branch Admins
        ✅ Reset Any Password
        ✅ Franchise Analytics
        ✅ Audit Logs
        "]

        BA2 -->|Branch Scope Only| AC2["
        ✅ Enroll Students
        ✅ Record Fee Payments
        ✅ Mark/View Attendance
        ✅ Issue Admit Cards
        ✅ Upload Results / Marksheets
        ✅ Manage Notices
        ✅ Register Teachers
        ❌ Cross-branch access
        "]

        TC2 -->|Teacher + Employee| AC3["
        ✅ Mark Student Attendance
        ✅ View Branch Students
        ✅ Upload Exam Marks
        ✅ View Assigned Subjects
        ✅ My Employee Profile (Zoho)
        ✅ My Payroll Snapshot
        ✅ My Leave Tracker
        ❌ Fee records
        ❌ Approve marksheets
        "]

        ST2 -->|Own Data Only| AC4["
        ✅ My Profile + ID Card
        ✅ My Attendance History
        ✅ My Fee Status
        ✅ My Marksheet + Certificate
        ✅ My Exam Results
        ✅ Take Online Exams
        ✅ Browse Courses (Public)
        ❌ Other students' data
        "]
    end
```

---

## 3. Flutter Frontend — Module Architecture

```mermaid
graph TB
    subgraph APP["lib/src/"]
        direction TB

        subgraph CORE["core/"]
            THEME[theme/\nColors · Typography · AppTheme]
            MODELS[models/\nUserSession · AppUser]
            PROVIDERS[providers/\nsessionProvider · authNotifier]
            SERVICES[services/\nsupabaseService]
            ROUTING[routing/\napp_router.dart\nGoRouter + Role Guard]
        end

        subgraph FEATURES["features/"]
            direction LR

            subgraph AUTH_F["auth/"]
                A1[LoginScreen]
                A2[AccountScreen]
                A3[ForgotPasswordScreen]
                A4[supabaseAuthNotifier]
            end

            subgraph STUDENT_F["student/"]
                S1[StudentDashboard]
                S2[StudentAttendance]
                S3[StudentFeeStatus]
                S4[StudentIdCard]
                S5[StudentExams]
                S6[StudentMarksheet]
                SD[studentRepository\nstudentProviders]
            end

            subgraph TEACHER_F["teacher/"]
                T1[TeacherDashboard\n• Attendance Stats\n• Subjects I Teach]
                T2[TeacherAttendance\n• Mark Bulk Attendance]
                T3[TeacherStudents\n• Branch Student List]
                T4[TeacherResults\n• Upload Marks]
                T5[Zoho Employee Profile\n• Payroll · Leaves · Details]
                TD[attendanceRepository\nteacherProviders]
            end

            subgraph ADMIN_F["admin/"]
                AD1[AdminDashboard]
                AD2[AddStudent]
                AD3[FeeManagement]
                AD4[MarksheetGenerator]
                AD5[ExamScheduler]
                AD6[BranchRegistration]
                ADD[adminRepository]
            end

            subgraph HOME_F["home/"]
                H1[HomeScreen\nRole-aware Landing]
                H2[MenuScreen]
                H3[ContactScreen]
            end

            subgraph COURSES_F["courses/"]
                C1[CoursesScreen\nPublic Catalog]
            end

            subgraph DOCS_F["documents/"]
                D1[DocumentsScreen]
                D2[CertificatesScreen]
            end
        end
    end

    ROUTING -->|Guards + Redirects| AUTH_F & STUDENT_F & TEACHER_F & ADMIN_F
    PROVIDERS --> AUTH_F & STUDENT_F & TEACHER_F & ADMIN_F
    SERVICES --> SD & TD & ADD
```

---

## 4. Backend API Layer Architecture

```mermaid
graph TB
    subgraph ENTRY["Entry Point — server.js"]
        MW1[Helmet\nSecurity Headers]
        MW2[Trust Proxy\nRender.com]
        MW3[CORS\nWhitelisted Origins]
        MW4[Morgan\nRequest Logging]
        MW5[Body Parser\n5MB JSON Limit]
    end

    subgraph MIDDLEWARE_STACK["Middleware Stack — Applied Per Route"]
        direction LR
        M1[1. requireAuth\nJWT → Supabase → Profile → Status]
        M2[2. requirePermission\nRole Matrix Lookup]
        M3[3. strictBranchGuard\nInjects req.queryBranchId]
        M4[4. studentSelfGuard\nFor Student-only routes]
        M5[5. sensitiveLimiter\nExtra rate limit for mutations]
        M6[6. auditLog\nEvery sensitive action recorded]
        M1 --> M2 --> M3 --> M4 --> M5 --> M6
    end

    subgraph ROUTES["Route Modules"]
        R1["/auth\n• /login\n• /register\n• /logout\n• /refresh\n• /me\n• /send-otp\n• /verify-otp\n• /admin/register-teacher\n• /admin/register-branch-admin\n• /admin/reset-password"]

        R2["/students\n• GET /  (branch list)\n• GET /me  (own record)\n• GET /:id\n• POST /  (enroll)\n• PUT /:id  (update)\n• PATCH /:id/approve"]

        R3["/attendance\n• GET /me  (student own)\n• POST /mark  (teacher bulk)\n• GET /  (admin branch view)"]

        R4["/fees\n• GET /me  (student own)\n• GET /  (admin branch list)\n• POST /  (record payment)"]

        R5["/courses\n• GET /  (public catalog)\n• GET /:id\n• GET /meta/categories"]

        R6["/employees ⭐ NEW\n• GET /me  (teacher own profile)\n• GET /  (admin list)\n• PATCH /:id  (update salary/leaves)\n• GET /:id/payslip"]

        R7["/notices\n• GET /\n• POST /\n• DELETE /:id"]

        R8["/documents\n• GET /\n• POST /upload\n• GET /:id/download"]

        R9["/branches\n• GET /\n• POST /\n• PATCH /:id"]
    end

    ENTRY --> MIDDLEWARE_STACK --> ROUTES
```

---

## 5. Database Schema — Entity Relationship

```mermaid
erDiagram
    branches {
        int id PK
        text name
        text code
        text owner_name
        text contact
        text email
        text address
        smallint status
    }

    profiles {
        uuid id PK
        uuid auth_uid UK
        text role
        int branch_id FK
        text full_name
        text email
        text contact
        text[] permissions
        smallint status
    }

    employees {
        int id PK
        uuid profile_id FK
        int branch_id FK
        text name
        text designation
        text department
        date doj
        numeric basic_salary
        numeric hra
        numeric da
        numeric other_allowance
        text pf_account_no
        text pan_no
        text esi_no
        int causal_leave
        smallint status
    }

    teacher_subjects {
        int id PK
        uuid teacher_id FK
        int subject_id FK
        int branch_id FK
    }

    students {
        int id PK
        uuid profile_id FK
        int branch_id FK
        int course_id FK
        text reg_no UK
        text name
        text father_name
        date dob
        text contact
        text email
        text photo_url
        smallint status
    }

    courses {
        int id PK
        int branch_id FK
        text name
        text short_name
        text duration
        numeric fee
        text category
        smallint status
    }

    subjects {
        int id PK
        int course_id FK
        int branch_id FK
        text name
        text code
        int total_marks
        int pass_marks
        smallint status
    }

    student_attendance {
        int id PK
        int student_id FK
        int branch_id FK
        date attendance_date
        text status
        smallint month
        int year
        uuid marked_by FK
    }

    fee_payments {
        int id PK
        int student_id FK
        int branch_id FK
        text receipt_no UK
        date payment_date
        numeric amount
        numeric net_pay
        text payment_mode
        uuid recorded_by FK
    }

    marksheets {
        int id PK
        int student_id FK
        int branch_id FK
        int course_id FK
        jsonb marks
        numeric percentage
        text grade
        text result
        smallint status
        uuid approved_by FK
    }

    certificates {
        int id PK
        int student_id FK
        int marksheet_id FK
        text certificate_no UK
        smallint status
        uuid approved_by FK
    }

    audit_logs {
        bigint id PK
        text action
        uuid profile_id
        text role
        int branch_id
        text ip_address
        text request_path
        int response_status
        timestamptz created_at
    }

    branches ||--o{ profiles : "has"
    branches ||--o{ employees : "employs"
    branches ||--o{ students : "hosts"
    branches ||--o{ courses : "offers"
    profiles ||--o{ employees : "linked_to"
    profiles ||--o{ teacher_subjects : "teaches"
    courses ||--o{ subjects : "contains"
    subjects ||--o{ teacher_subjects : "assigned_to"
    students ||--o{ student_attendance : "has"
    students ||--o{ fee_payments : "pays"
    students ||--o{ marksheets : "receives"
    marksheets ||--o| certificates : "generates"
```

---

## 6. Role-Based Data Flow

```mermaid
sequenceDiagram
    participant APP as Flutter App
    participant GW as API Gateway
    participant AUTH as Auth Middleware
    participant GUARD as Role Guard
    participant DB as Supabase DB (RLS)

    APP->>GW: POST /api/v1/attendance/mark\nAuthorization: Bearer <JWT>

    GW->>AUTH: Validate JWT
    AUTH->>DB: SELECT role, status FROM profiles\nWHERE auth_uid = jwt.sub
    DB-->>AUTH: { role: 'teacher', branch_id: 3, status: 1 }
    AUTH-->>GW: ✅ req.role='teacher', req.branchId=3

    GW->>GUARD: requirePermission('MARK_ATTENDANCE')
    GUARD-->>GW: ✅ teacher is allowed

    GW->>GUARD: strictBranchGuard
    GUARD-->>GW: ✅ req.queryBranchId = 3\n(overrides any client-sent branch_id)

    GW->>DB: INSERT INTO student_attendance\nWHERE branch_id = 3 (server-enforced)
    DB-->>GW: RLS CHECK: current_user_branch() = 3 ✅
    DB-->>GW: { success: true, marked: 32 }
    GW-->>APP: 200 OK { marked: 32 }
```

---

## 7. Zoho Employee Feature — Data Architecture

```mermaid
graph TB
    subgraph ZOHO["🧑‍💼 Zoho Employee Portal (Teacher View)"]
        direction TB

        subgraph IDENTITY["Employee Identity Card"]
            EI1[Name · Designation · Department]
            EI2[Date of Joining · Branch]
            EI3[Contact · Email]
        end

        subgraph PAYROLL["💰 Payroll Snapshot"]
            PR1[Basic Salary]
            PR2[HRA · DA · Special Allowance]
            PR3[Gross Salary = Sum of above]
            PR4[PF Account No]
            PR5[PAN Card · ESI No]
        end

        subgraph LEAVES["🏖️ Leave Tracker"]
            LV1[Total Causal Leaves = 15/yr]
            LV2[Leaves Taken = employees.causal_leave_taken]
            LV3[Balance = Total − Taken]
            LV4[Apply Leave → future feature]
        end

        subgraph ATTENDANCE_ZOHO["📅 Employee Attendance"]
            EA1[Monthly Attendance View]
            EA2[employee_attendance table]
            EA3[P · A · L · H status]
        end
    end

    subgraph BACKEND_ZOHO["Backend — Employee API"]
        EB1["GET /api/v1/employees/me\nFetch own employee record"]
        EB2["PATCH /api/v1/employees/:id\nAdmin: update salary/leaves"]
        EB3["GET /api/v1/employees/:id/payslip\nGenerate PDF payslip"]
    end

    subgraph DB_ZOHO["Database Tables"]
        DB1[(employees\nSalary · Allowances\nPF · PAN · ESI · Leaves)]
        DB2[(employee_attendance\nDaily P/A/L/H record)]
        DB3[(salary_advances\nAdvance tracking)]
    end

    IDENTITY & PAYROLL & LEAVES & ATTENDANCE_ZOHO --> EB1
    EB1 --> DB1 & DB2
    EB2 --> DB1
    EB3 --> DB1
```

---

## 8. Security Architecture — Defence Layers

```mermaid
graph TB
    subgraph LAYERS["Security Onion — 8 Layers"]
        L1["🛡️ Layer 1: Helmet\nHTTP Security Headers\nCSP · HSTS · X-Frame-DENY"]
        L2["🌐 Layer 2: CORS\nWhitelisted origins only\nNo wildcards in prod"]
        L3["⏱️ Layer 3: Rate Limiter\nLogin: 5 req/15min per IP\nAPI: 120 req/min"]
        L4["🔑 Layer 4: requireAuth\nSupabase JWT validation\nProfile existence + status=1 check"]
        L5["👮 Layer 5: requirePermission\nRole-permission matrix\n26 granular permissions"]
        L6["🏢 Layer 6: strictBranchGuard\nBranch ID injected server-side\nClient branch_id always overridden"]
        L7["🎓 Layer 7: studentSelfGuard\nStudents read ONLY their own records\nNever by query param"]
        L8["🗄️ Layer 8: Supabase RLS\nDatabase-level row policies\nBypasses Node.js if attacked directly"]

        L1 --> L2 --> L3 --> L4 --> L5 --> L6 --> L7 --> L8
    end
```

---

## 9. Flutter State Management Architecture (Riverpod)

```mermaid
graph TB
    subgraph RIVERPOD["Riverpod Provider Tree"]
        direction TB

        SP[sessionProvider\nUserSession?]

        subgraph AUTH_P["Auth Providers"]
            AN[supabaseAuthNotifierProvider\nStateNotifier]
        end

        subgraph STUDENT_P["Student Providers"]
            SRP[studentRepositoryProvider]
            SPR[studentProfileProvider]
            SAP[studentAttendanceProvider]
            SFP[studentFeeStatusProvider]
            SER[studentExamResultsProvider]
        end

        subgraph TEACHER_P["Teacher Providers"]
            ARP[attendanceRepositoryProvider]
            TEP[teacherEmployeeProfileProvider\n⭐ NEW — Zoho data]
            TSP[teacherSubjectsProvider\n⭐ NEW — Subjects taught]
            TAS[teacherStudentAttendanceStatsProvider\n⭐ NEW — Branch stats]
        end

        subgraph ADMIN_P["Admin Providers"]
            ADMP[adminRepositoryProvider]
            ADS[adminStudentsProvider]
            ADF[adminFeesProvider]
            ADN[adminNoticesProvider]
        end

        SP --> AUTH_P & STUDENT_P & TEACHER_P & ADMIN_P
    end

    subgraph UI["UI Layer"]
        TSC[TeacherDashboardScreen\nWatches: TEP + TSP + TAS]
        SSC[StudentDashboardScreen\nWatches: SPR + SAP + SFP]
        ASC[AdminDashboardScreen\nWatches: ADS + ADF]
    end

    TEACHER_P --> TSC
    STUDENT_P --> SSC
    ADMIN_P --> ASC
```

---

## 10. What Needs to Be Built — Priority Roadmap

```mermaid
gantt
    title Feature Roadmap — LMS + Zoho
    dateFormat YYYY-MM-DD
    section 🔴 Critical Fixes (Now)
        Fix fee permission keys         :done, f1, 2026-07-14, 1d
        Fix attendance_date column      :done, f2, 2026-07-14, 1d
        Rewrite course.routes.js        :active, f3, 2026-07-14, 1d
        Add missing UNIQUE constraints  :f4, 2026-07-15, 1d
        Fix logout token invalidation   :f5, 2026-07-15, 1d
    section 🟡 Current Sprint
        Teacher Dashboard (Zoho UI)     :done, s1, 2026-07-13, 2d
        Teacher Employee Providers      :done, s2, 2026-07-13, 1d
        Route guard prefix fix          :done, s3, 2026-07-13, 1d
    section 🟢 Next Sprint
        Employee REST API endpoint      :n1, 2026-07-16, 2d
        teacher_subjects junction table :n2, 2026-07-16, 1d
        PDF Payslip Generator           :n3, 2026-07-18, 2d
        Leave application workflow      :n4, 2026-07-20, 3d
    section 🔵 Future (LMS Phase 2)
        Course Detail screens           :p1, 2026-07-25, 5d
        Video/Content Player            :p2, 2026-08-01, 7d
        Push Notifications (FCM)        :p3, 2026-08-10, 3d
        Parent Portal role              :p4, 2026-08-15, 5d
```

---

## Key Architecture Decisions

| Decision | Chosen | Reason |
|----------|--------|--------|
| Auth Provider | Supabase Auth | Built-in JWT, OTP, OAuth, admin APIs |
| Database | PostgreSQL via Supabase | RLS + real-time + REST auto-generation |
| API Layer | Node.js + Express | Fine-grained middleware control for audit logging |
| State Management | Riverpod (Flutter) | Compile-safe, testable, no BuildContext dependency |
| Navigation | GoRouter | Deep linking, shell routes, role-based redirect |
| Employee Data | `employees` table | Mirrors Zoho HR structure (salary, PF, ESI, leaves) |
| Branch Isolation | `strictBranchGuard` middleware | Server enforces branch_id — client cannot forge it |
| Permission Model | Flat permission strings in DB array | Per-user granular permissions, not just role-based |
| Storage | Supabase Storage | Photos, PDFs, marksheets, certificates all in one |
| Offline Support | Hive local cache (future) | Student ID card must work offline |
