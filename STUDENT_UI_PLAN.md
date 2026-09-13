# Student Role — UI Plan

## Data contract (fix this before touching layout)
`getStudentProfile()` → `students` row (+ `courses(name, category)` join). Only these keys exist:

```
id, name, father_name, mother_name, gender, dob, religion, category,
contact, email, address, reg_no, adm_no, course_id, batch_time,
doj, photo_url, status, branch_id, courses: { name, category }
```

No `registration_number`, `phone`, `guardian_name`, `date_of_birth`, `streak` columns exist on `students` — any screen must read the real names (`reg_no`, `contact`, `mother_name`, `dob`) or a fallback default, never a guessed key.

## Screens

### 1. Dashboard (`student_dashboard_screen.dart`) — exists, just fixed
- Digital ID card: name, course, reg no, session — now reading correct keys.
- Pending-approval banner: only when `status != 1`.
- Quick actions grid: Attendance, Fee Status, Calendar, Notice Board.
- **Gap:** no real data density — attendance streak, next class, fee due amount are all static/zero. Low priority unless requested.

### 2. Profile (`student_profile_screen.dart`) — exists
- Should surface: name, father/mother name, dob, gender, address, contact, email, reg_no, course, branch.
- Edit flow already exists via `updateProfile()` in `auth_service.dart` (name/phone/email only — matches the 30-day email-change lock).

### 3. Attendance (`teacher_attendance_screen.dart` marks it, student side reads it)
- Student view should be read-only: date, status (present/absent), maybe a monthly % — check `student_attendance` table columns before building, don't assume.

### 4. Fees (`getMyFeePayments` / `getPendingFees`, now fixed)
- List of `fee_payments` rows + a pending-amount summary card.
- These queries are now correctly scoped by resolved `students.id`, so this screen should start returning real rows once wired to `studentFeeSnapshotProvider` (verify it calls the fixed methods).

### 5. Exams / Results (`exam_repository.dart`, already built in the MCQ module)
- Test list → attempt → result screens already exist from the earlier exam-module work; nothing new needed here, just confirm student nav links to them.

### 6. Documents (`my_documents_screen.dart`, `certificate_viewer_screen.dart`)
- Backed by `getMyCertificates()` / `getMyMarksheets()`, both now fixed to use `students.id`.

## What NOT to build
- No new tables — `student_enrollments` and `payment_transactions` don't exist in the schema; either the tables need creating (separate decision) or those two repository methods should be removed rather than "fixed" further.
- No speculative gamification (streaks, badges) until a real `students` column backs it.

## Immediate next step
Confirm on-device that dashboard/profile/fees/documents now render real data for Sakshi's account after the key-mapping fix, before planning any new screens.
