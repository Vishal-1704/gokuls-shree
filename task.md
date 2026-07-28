# Checklist: Teacher Employee Profile & Codebase Bug Fixes

- [ ] **1. Codebase Compile & Routing Fixes**
  - [ ] Import `user_session.dart` in `student_id_card_screen.dart`
  - [ ] Fix syntax errors and add mock overrides in `test/widget_test.dart`
  - [ ] Refactor routing guard `_isAllowedRouteForRole` and add `/courses` route in `app_router.dart`
  - [ ] Verify that `flutter analyze` runs successfully with zero errors

- [ ] **2. Teacher Repository & Providers**
  - [ ] Implement `teacherEmployeeProfileProvider` in `attendance_repository.dart`
  - [ ] Implement `teacherSubjectsProvider` in `attendance_repository.dart`
  - [ ] Implement `teacherStudentAttendanceStatsProvider` in `attendance_repository.dart`

- [ ] **3. Teacher Portal UI Upgrades**
  - [ ] Convert `teacher_dashboard_screen.dart` to a Tabbed layout (Syllabus/Attendance + Zoho Employee Profile)
  - [ ] Implement "Today's Student Attendance Rate" widget with circular progress bar
  - [ ] Implement "Subjects I Teach" horizontal scrolling component
  - [ ] Implement Zoho-style Employee details (Allowances, basic salary, joined date, causal leaves remaining)

- [ ] **4. Final Verification**
  - [ ] Run `flutter analyze` and `flutter test`
  - [ ] Document changes in `walkthrough.md`
