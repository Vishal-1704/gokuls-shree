# Implementation Plan: Teacher Employee Data (Zoho-Style) & Bug Fixes

Based on your feedback, we have postponed the new course learning player/details screen features for a future milestone. This plan now focuses on:
1. Fixing the critical compiler and routing errors immediately.
2. Expanding the Teacher Portal with Zoho-like employee profile stats (payslip, leaves, joined date), subjects taught, and student attendance tracking.

---

## User Review Required

> [!IMPORTANT]
> **1. Teacher Employee Profile (Mini-Zoho)**
> We will add an employee profile tab or section on the teacher's dashboard showing basic salary, allowances (HRA, DA, PF/ESI numbers), leave balances, joined date, designation, and department, fetched from the `employees` table.
>
> **2. Subjects Taught**
> Display a list of subjects assigned to/taught by the teacher, dynamically fetched from the database branch/subjects catalog.
>
> **3. Student Attendance Statistics**
> Display branch student attendance summaries (Today's rate, present vs absent counts) on the teacher's dashboard to give them an overview of their branch student attendance data.

---

## Proposed Changes

### 1. Codebase Compile & Routing Fixes

#### [MODIFY] [app_router.dart](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/lib/src/routing/app_router.dart)
- Re-architect `_isAllowedRouteForRole` to handle role sub-paths dynamically using path prefix checks instead of exact path matching, which solves the bottom nav tab redirection bug.
- Register `/courses` route for public courses.

#### [MODIFY] [student_id_card_screen.dart](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/lib/src/features/student/presentation/student_id_card_screen.dart)
- Import `import '../../../core/models/user_session.dart';` to fix the `Undefined class 'UserSession'` compilation error.

#### [MODIFY] [widget_test.dart](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/test/widget_test.dart)
- Fix the dangling syntax error on line 41 (`}) async {}`).
- Add missing concrete mock implementations of `resetPassword`, `signOut`, `signUp`, and `updateProfile` to the `MockSupabaseAuthNotifier` class.

---

### 2. Teacher Portal Zoho & Attendance Features

#### [MODIFY] [attendance_repository.dart](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/lib/src/features/teacher/data/attendance_repository.dart)
- Add `teacherEmployeeProfileProvider` to fetch the logged-in teacher's record from the `employees` table, including designation, salary, HRA, DA, PF, and leaves, with a robust fallback to mock profile details.
- Add `teacherSubjectsProvider` to query subjects within the teacher's branch/assigned courses.
- Add `teacherStudentAttendanceStatsProvider` to compute today's student attendance rate and present/absent stats in the branch.

#### [MODIFY] [teacher_dashboard_screen.dart](file:///c:/Users/Lenovo/Music/Projects/gokuls-shree/lib/src/features/teacher/presentation/teacher_dashboard_screen.dart)
- Convert dashboard to a double-tabbed layout (using a `DefaultTabController` and a custom slider tab bar):
  - **Tab 1: Dashboard & Attendance**:
    - "Today's Student Attendance Rate" card with a circular percent indicator and counts (Present, Absent, Pending).
    - "Subjects I Teach" horizontal catalog (list of subjects with code and course category).
    - Quick action buttons (Mark Attendance, View Students, Upload Results).
  - **Tab 2: My Employee Profile (Mini Zoho)**:
    - Zoho-style card detailing basic designation, department, and DOJ.
    - Leaves snapshot (Causal leaves taken, total, and balance).
    - Payroll Payslip Card detailing basic salary, HRA, DA, PF/ESI numbers, and net salary.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to verify that there are zero compilation or static analysis errors.
- Run `flutter test` to ensure mock smoke test passes.

### Manual Verification
- We will verify that the teacher dashboard builds successfully and displays the correct employee, subject, and student attendance statistics.
