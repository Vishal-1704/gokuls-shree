# Backend Audit Report — Gokul Shree LMS

---

## 🔴 CRITICAL BUGS (Will Cause Runtime Failures)

### 1. `course.routes.js` — Wrong Database Client (CRASH on startup)
**File:** `src/routes/course.routes.js`

```js
const db = require('../config/database');  // ← PostgreSQL pg client
// ...
let query = 'SELECT * FROM courses WHERE is_active = true';
const result = await db.query(query, params);
```

**Problem:** This file uses the legacy **raw PostgreSQL `pg` client** (`config/database.js`) instead of the Supabase client that all other routes use. The `courses` table in `001_supabase_schema.sql` has no `is_active` column — it uses `status SMALLINT`. This will throw a DB connection or query error on every call to `/api/v1/courses`.

**Fix:** Rewrite using `const { supabase } = require('../config/supabase')` and filter on `.eq('status', 1)` instead of `is_active`.

---

### 2. `001_supabase_schema.sql` — `student_attendance` column is `attendance_date`, NOT `date`
**File:** `migrations/001_supabase_schema.sql` line 233

```sql
attendance_date DATE NOT NULL,   -- ← column is attendance_date
```

But in the Flutter app (`teacher_attendance_screen.dart`, `student_repository.dart`) the queries use:
```dart
.eq('date', todayStr)   // ← WRONG — this column does not exist
```
Also in `attendance_repository.dart` (our new provider):
```dart
.eq('date', todayStr)   // ← WRONG
```

**Fix:** Change all app-side Dart queries from `.eq('date', ...)` to `.eq('attendance_date', ...)`.

---

### 3. `auth.routes.js` — `employees.profile_id` stores `profile.id` (UUID) but is linked wrong
**File:** `src/routes/auth.routes.js` line 415

```js
const { error: employeeError } = await supabase
  .from('employees')
  .insert({
    profile_id: profile.id,   // ← profile.id is the UUID from profiles table (correct)
    ...
  });
```

**BUT** — in `attendance_repository.dart` we query:
```dart
.eq('profile_id', session.profileId)  // ← works if profileId is the UUID from profiles.id
```

This is actually _correct_ — but you need to confirm `session.profileId` is `profiles.id` (UUID) not `auth_uid`. Check `session_provider.dart` to verify the field mapping. If `profileId` maps to `auth_uid` instead of `profiles.id`, the employee query will always return null.

---

### 4. `fee.routes.js` — Permission key mismatch
**File:** `src/routes/fee.routes.js` line 99

```js
requirePermission('COLLECT_FEE'),  // ← 'COLLECT_FEE' is NOT defined in PERMISSIONS matrix
```

But in `role.guard.js`, the defined key is:
```js
RECORD_FEE: [ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
```

The `requirePermission` function will respond with HTTP 500 ("Server misconfiguration") for every fee collection request because `COLLECT_FEE` is unknown. **This is a live crash bug.**

**Fix:** Change `requirePermission('COLLECT_FEE')` → `requirePermission('RECORD_FEE')`.

---

### 5. `fee.routes.js` — Same issue: `READ_OWN_FEE` vs `READ_OWN_FEES`
**File:** `src/routes/fee.routes.js` line 19

```js
requirePermission('READ_OWN_FEE'),  // ← 'READ_OWN_FEE' — note no 'S'
```

But in `role.guard.js`:
```js
READ_OWN_FEES: [ROLES.STUDENT],    // ← has 'S'
```

Every student hitting `GET /fees/me` gets HTTP 500. Fix: change to `requirePermission('READ_OWN_FEES')`.

---

### 6. `server.js` — `sync.routes.js` exists but is never mounted
**File:** `src/routes/sync.routes.js` — exists but not imported or mounted in `server.js`.

This file likely handles legacy data syncing. If this is needed, it's silently dead. Either mount it or delete it to prevent confusion.

---

## 🟠 SECURITY VULNERABILITIES

### 7. `auth.routes.js` — Student registration has no branch validation
**File:** `src/routes/auth.routes.js` line 41

```js
branch_id: branch_id ? parseInt(branch_id) : null,
```

A student can self-register and assign themselves to **any** branch ID they choose by sending it in the request body. Since students register with `status: 0` (pending), this might seem safe — but it means pending records populate the wrong branch's admin queue.

**Fix:** Either validate that the `branch_id` exists and is active, or drop the field and let admin assign it during approval.

---

### 8. `auth.routes.js` — `logout` doesn't invalidate the user's specific session
**File:** `src/routes/auth.routes.js` line 275

```js
await supabase.auth.signOut();  // ← Signs out the SERVICE ROLE client, not the user!
```

The backend uses the **service role** Supabase client, so `supabase.auth.signOut()` does nothing useful. The user's token stays valid until it expires. You need to use the user's access token to sign them out.

**Fix:**
```js
const token = req.headers.authorization?.split(' ')[1];
const userClient = supabaseUser(token);
await userClient.auth.signOut();
```

---

### 9. `role.guard.js` — `READ_BRANCH_ATTENDANCE` permission is missing from PERMISSIONS matrix
**File:** `src/middleware/role.guard.js`

`attendance.routes.js` line 104 requires:
```js
requirePermission('READ_BRANCH_ATTENDANCE'),
```

But `READ_BRANCH_ATTENDANCE` is **not defined** in `PERMISSIONS`. This makes `GET /api/v1/attendance` always return HTTP 500 for admins.

**Fix:** Add to PERMISSIONS in `role.guard.js`:
```js
READ_BRANCH_ATTENDANCE: [ROLES.TEACHER, ROLES.BRANCH_ADMIN, ROLES.SUPER_ADMIN],
```

---

### 10. `002_security_rls.sql` — `audit_logs` INSERT policy has no RLS enabled first
**File:** `migrations/002_security_rls.sql` line 24

```sql
CREATE POLICY "audit_insert_only" ON audit_logs FOR INSERT WITH CHECK (true);
-- ...
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;  -- ← comes 14 lines LATER
```

Policy is created before RLS is enabled on the table. While PostgreSQL tolerates this, it's confusing and should be reordered: enable RLS first, then create policies.

---

### 11. `002_security_rls.sql` — Missing DELETE policy on `students` table
There is `SELECT`, `INSERT`, `UPDATE` policies on `students` but **no explicit DELETE policy**. Without a deny-all default, this could allow unintended deletions depending on Supabase's default RLS behavior.

**Fix:** Add:
```sql
CREATE POLICY "students_no_delete" ON students FOR DELETE USING (false);
```

---

## 🟡 SCHEMA ISSUES

### 12. Schema mismatch — `profiles.id` vs `profiles.auth_uid`
The `profiles` table has two ID columns:
- `id UUID PRIMARY KEY` — internal UUID (used by relationships like `employees.profile_id`)
- `auth_uid UUID UNIQUE` — links to Supabase `auth.users.id`

The RLS helper function `current_user_role()` queries by `auth_uid = auth.uid()` (correct), but the `profiles_read` policy uses both — this is fine. However, the Flutter app's `session_provider.dart` needs to load **both** and expose `profileId` as `profiles.id`, not `auth_uid`. This is critical for `employees.profile_id` joins.

---

### 13. `001_supabase_schema.sql` — `subjects` table has no teacher assignment column
There is no `teacher_id` or `assigned_to` column in `subjects`. The teacher portal (`teacherSubjectsProvider`) fetches subjects by `branch_id` only — meaning every teacher in a branch sees all subjects, not just their own. For a proper multi-teacher setup you need a junction table.

**Suggested fix (run in Supabase):**
```sql
CREATE TABLE IF NOT EXISTS teacher_subjects (
  id          SERIAL PRIMARY KEY,
  teacher_id  UUID REFERENCES profiles(id),
  subject_id  INT REFERENCES subjects(id),
  branch_id   INT REFERENCES branches(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 14. `fee_payments` table — no unique constraint for duplicate receipts
`receipt_no TEXT` has no `UNIQUE` constraint. Multiple records with the same receipt number can be inserted silently.

**Fix:**
```sql
ALTER TABLE fee_payments ADD CONSTRAINT fee_receipt_no_unique UNIQUE (receipt_no);
```

---

### 15. `student_attendance` — no unique constraint for upsert
`attendance.routes.js` does:
```js
.upsert(rows, { onConflict: 'student_id,attendance_date' })
```

But there is no `UNIQUE(student_id, attendance_date)` constraint defined in `001_supabase_schema.sql`. Supabase upserts need a real constraint or unique index to work.

**Fix:**
```sql
ALTER TABLE student_attendance ADD CONSTRAINT student_attendance_unique 
  UNIQUE (student_id, attendance_date);
```

---

## 🔵 ARCHITECTURAL / DESIGN ISSUES

### 16. Mixed database clients — `pg` + `supabase-js` both in use
`course.routes.js` uses `pg` (raw PostgreSQL), all other routes use `@supabase/supabase-js`. This is inconsistent and the legacy `pg` connection in `config/database.js` likely points to a different database or may not have valid credentials at all in the Supabase-hosted deployment.

**Fix:** Eliminate the `pg` client entirely. Rewrite `course.routes.js` with Supabase client.

---

### 17. No employee route — no REST API for employee/teacher profile
There is no `employees.routes.js`. The teacher's Zoho profile, leave balance, and salary details are fetched directly from the Flutter app via `supabase-js` client-side. This bypasses server-side validation and audit logging for sensitive payroll data.

**Recommended:** Add `src/routes/employee.routes.js` with:
- `GET /api/v1/employees/me` — teacher views own profile
- `PATCH /api/v1/employees/:id` — super_admin updates salary/leaves

---

### 18. `bcryptjs` is in `dependencies` but never used
`package.json` lists `bcryptjs` as a dependency. Since Supabase handles all password hashing, this package is dead weight. Remove it.

---

### 19. No API versioning on `course.routes.js`
All other routes mount as `/api/v1/...`. The course route is mounted at `${API}/courses` correctly in `server.js`, but the route handlers inside `course.routes.js` use raw `db.query` which is detached from the Supabase API version pattern.

---

## Summary Table

| # | Severity | File | Issue |
|---|----------|------|-------|
| 1 | 🔴 CRITICAL | `course.routes.js` | Uses legacy pg client + wrong column (`is_active`) |
| 2 | 🔴 CRITICAL | Schema + Flutter | `date` vs `attendance_date` column mismatch |
| 3 | 🔴 CRITICAL | `fee.routes.js` | `COLLECT_FEE` permission key doesn't exist → HTTP 500 |
| 4 | 🔴 CRITICAL | `fee.routes.js` | `READ_OWN_FEE` should be `READ_OWN_FEES` → HTTP 500 |
| 5 | 🔴 CRITICAL | `role.guard.js` | `READ_BRANCH_ATTENDANCE` missing → HTTP 500 for admins |
| 6 | 🟠 SECURITY | `auth.routes.js` | `signOut()` doesn't invalidate user token |
| 7 | 🟠 SECURITY | `auth.routes.js` | Student can self-assign to any branch |
| 8 | 🟡 SCHEMA | `student_attendance` | No UNIQUE constraint — upsert by conflict breaks |
| 9 | 🟡 SCHEMA | `fee_payments` | No UNIQUE on `receipt_no` |
| 10 | 🟡 SCHEMA | `subjects` | No teacher-subject assignment table |
| 11 | 🔵 DESIGN | Backend | No employee REST API — payroll data exposed client-side |
| 12 | 🔵 DESIGN | `package.json` | `bcryptjs` is dead weight |
| 13 | 🔵 DESIGN | `server.js` | `sync.routes.js` mounted nowhere |
