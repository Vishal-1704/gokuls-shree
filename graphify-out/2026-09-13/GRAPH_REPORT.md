# Graph Report - gokuls-shree  (2026-09-12)

## Corpus Check
- 187 files · ~648,952 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2594 nodes · 3760 edges · 155 communities (143 shown, 7 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1f94fd4b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- _
- Win32Window
- admin_add_student_screen.dart
- admin_repository.dart
- server.dart
- services/supabase_service.dart
- auth_service.dart
- GeneratedPluginRegistrant.swift
- admin_course_form_screen.dart
- question_manager_screen.dart
- login_screen.dart
- webview_screen.dart
- teacher_attendance_screen.dart
- my_documents_screen.dart
- app_colors.dart
- exam_repository.dart
- exam_quiz_screen.dart
- super_admin_approvals_screen.dart
- exam_result_screen.dart
- StatelessWidget
- admin_add_staff_screen.dart
- admin_course_detail_screen.dart
- super_admin_paper_manager_screen.dart
- admin_marksheet_generator_screen.dart
- admin_exam_scheduler_screen.dart
- exam_list_screen.dart
- app_image.dart
- config/supabase_service.dart
- my_application.cc
- env_config.dart
- admin_student_directory_screen.dart
- student_repository.dart
- super_admin_branches_screen.dart
- admin_panel_screen.dart
- admin_schedule_results_screen.dart
- ConsumerState
- app_spacing.dart
- admin_profile_screen.dart
- core/models/user_session.dart
- super_admin_reset_password_screen.dart
- userRoleProvider
- Map
- attendance_repository.dart
- widget_test.dart
- employees_routes.dart
- certificate_viewer_screen.dart
- branch_dashboard_screen.dart
- custom_text_field.dart
- admin_admit_card_screen.dart
- franchise_setup_screen.dart
- admin_routes.dart
- super_admin_routes.dart
- role_shell.dart
- admin_notices_screen.dart
- admin_dashboard_home.dart
- admin_fee_collection_screen.dart
- admin_reports_hub_screen.dart
- admin_results_entry_screen.dart
- admin_staff_directory_screen.dart
- contact_screen.dart
- admin_study_material_upload_screen.dart
- centre_finder_screen.dart
- courses_screen.dart
- package:go_router/go_router.dart
- marksheet_viewer_screen.dart
- exam_instructions_screen.dart
- document_service.dart
- app_router.dart
- package:flutter/material.dart
- forgot_password_screen.dart
- app_typography.dart
- build
- ConsumerWidget
- teacher_results_upload_screen.dart
- rate_limiter.dart
- lib/models/user_session.dart
- other_routes.dart
- MaterialPageRoute
- admin_dashboard_screen.dart
- branch_registration_screen.dart
- public_home_screen.dart
- package:gokul_shree_app/src/core/theme/app_colors.dart
- teacher_dashboard_screen.dart
- sessionProvider
- admin_qr_scanner_screen.dart
- List
- ../models/user_session.dart
- back_handler.dart
- routing/student_routes.dart
- wWinMain
- supabaseAuthProvider
- supabaseServiceProvider
- package:gokul_shree_app/src/features/admin/data/admin_repository.dart
- role_guard.dart
- routes/documents_routes.dart
- routes/student_routes.dart
- 🔴 CRITICAL BUGS (Will Cause Runtime Failures)
- student_dashboard_screen.dart
- manifest.json
- teacher_routes.dart
- responsive_container.dart
- update_service.dart
- State
- adminRepositoryProvider
- examRepositoryProvider
- super_admin_dashboard_screen.dart
- student_id_card_screen.dart
- Exam & Test Module — Rebuild Documentation
- session_provider.dart
- package:flutter_riverpod/flutter_riverpod.dart
- institute_config.dart
- package:shelf/shelf.dart
- exams_routes.dart
- adminStudentsProvider
- dart:convert
- package:supabase_flutter/supabase_flutter.dart
- MainActivity.kt
- adminCoursesProvider
- super_admin_profile_screen.dart
- 🏗️ Gokul Shree LMS — Full-Stack Architecture Design
- package:gokul_shree_app/src/core/config/env_config.dart
- 📚 Gokul Shree LMS — Complete Project Master Document
- SupabaseAuthNotifier
- CustomPainter
- 10. Backend Audit Report — 19 Issues Found
- @branch
- bool?
- String?
- logger.dart
- 🚀 Getting Started
- teacher_employment_details.dart
- account_screen.dart
- student_attendance_screen.dart
- Phase 1: Flutter Compiler & Routing Fixes ✅ DONE
- What Each Role Can Do
- 🔵 DESIGN ISSUES (6)
- 12. Hosting & Cost Analysis
- 14. Feature Backlog & Roadmap
- 🔴 CRITICAL BUGS (5) — Will Cause Runtime Crashes
- package:gokul_shree_app/src/core/services/supabase_service.dart
- 1. Project Vision & Goals
- 5. Backend API Layer Architecture
- 6. Database Schema — Entity Relationships
- 8. Zoho Employee Feature Architecture
- build
- 13. Learning Roadmap
- gokul_shree_app
- CLAUDE.md
- LaunchImage.imageset/README.md
- _buildPasswordStep

## God Nodes (most connected - your core abstractions)
1. `_` - 80 edges
2. `adminRepositoryProvider` - 50 edges
3. `Win32Window` - 24 edges
4. `📚 Gokul Shree LMS — Complete Project Master Document` - 19 edges
5. `examRepositoryProvider` - 18 edges
6. `adminStudentsProvider` - 17 edges
7. `supabaseServiceProvider` - 13 edges
8. `🏗️ Gokul Shree LMS — Full-Stack Architecture Design` - 13 edges
9. `supabaseAuthProvider` - 12 edges
10. `MessageHandler` - 12 edges

## Surprising Connections (you probably didn't know these)
- `MockSessionNotifier` --inherits--> `SessionNotifier`  [EXTRACTED]
  test/widget_test.dart → lib/src/core/providers/session_provider.dart
- `_saveStaff` --references--> `adminRepositoryProvider`  [EXTRACTED]
  lib/src/features/admin/presentation/admin_add_staff_screen.dart → lib/src/features/admin/data/admin_repository.dart
- `_refreshData` --references--> `adminRepositoryProvider`  [EXTRACTED]
  lib/src/features/admin/presentation/admin_dashboard_home.dart → lib/src/features/admin/data/admin_repository.dart
- `_submitFee` --references--> `adminRepositoryProvider`  [EXTRACTED]
  lib/src/features/admin/presentation/admin_fee_collection_screen.dart → lib/src/features/admin/data/admin_repository.dart
- `_deleteNotice` --references--> `adminRepositoryProvider`  [EXTRACTED]
  lib/src/features/admin/presentation/admin_notices_screen.dart → lib/src/features/admin/data/admin_repository.dart

## Import Cycles
- None detected.

## Communities (155 total, 7 thin omitted)

### Community 0 - "_"
Cohesion: 0.03
Nodes (71): _, _AC, AdmitCardData, AdmitCardSubject, altRow, bodyBg, border, build (+63 more)

### Community 1 - "Win32Window"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 2 - "admin_add_student_screen.dart"
Cohesion: 0.03
Nodes (60): _admissionDateController, _admissionYearController, _batchController, build, _buildAddressDetailsStep, _buildDropdownField, _buildPersonalDetailsStep, _buildSectionHeader (+52 more)

### Community 3 - "admin_repository.dart"
Cohesion: 0.04
Nodes (53): addCourse, addDownload, addNotice, addStaff, addStudent, addStudentAdmission, addStudentResult, addStudyMaterial (+45 more)

### Community 4 - "server.dart"
Cohesion: 0.07
Nodes (28): allowedOrigins, anonKey, apiBase, apiVersion, corsMiddleware, env, handler, isDev (+20 more)

### Community 5 - "services/supabase_service.dart"
Cohesion: 0.04
Nodes (45): authStateChanges, _client, currentUser, findBranches, getActivePaperSets, getBranches, getCourseById, getCourseCategories (+37 more)

### Community 6 - "auth_service.dart"
Cohesion: 0.05
Nodes (45): adminLogin, AuthAuthenticated, AuthError, AuthInitial, AuthLoading, authState, AuthUnauthenticated, checkPhoneNumber (+37 more)

### Community 7 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (33): Any, app_links, Cocoa, file_selector_macos, Flutter, flutter_blue_plus_darwin, FlutterAppDelegate, FlutterMacOS (+25 more)

### Community 8 - "admin_course_form_screen.dart"
Cohesion: 0.06
Nodes (36): _addCareerRole, _addModule, AdminCourseFormScreen, _AdminCourseFormScreenState, build, _buildHeaderBanner, _buildSectionCard, _careerRoles (+28 more)

### Community 9 - "question_manager_screen.dart"
Cohesion: 0.05
Nodes (39): build, _buildImagePicker, _Chip, color, _correctOption, createState, _difficulty, dispose (+31 more)

### Community 10 - "login_screen.dart"
Cohesion: 0.06
Nodes (32): PhoneLookupResult, _buildGlassInputDecoration, _buildLogo, _buildPhoneStep, _buildRegisterStep, _callCentre, _cancelLatencyTimer, createState (+24 more)

### Community 11 - "webview_screen.dart"
Cohesion: 0.06
Nodes (33): aboutUs, admitCard, baseUrl, build, certificateVerification, contactUs, _controller, createState (+25 more)

### Community 12 - "teacher_attendance_screen.dart"
Cohesion: 0.06
Nodes (36): _attendanceMap, _AttendanceTile, build, _buildBottomAction, _buildChoice, _buildQuickActionHeader, _buildSmartRollCallUI, _buildStudentList (+28 more)

### Community 13 - "my_documents_screen.dart"
Cohesion: 0.06
Nodes (32): certificate_viewer_screen.dart, documentRepositoryProvider, build, _buildDocCard, _buildEmptyState, _buildHeaderCard, _buildSectionTitle, _certificates (+24 more)

### Community 14 - "app_colors.dart"
Cohesion: 0.06
Nodes (32): AppColors, chipOverdueBg, chipOverdueFg, chipPaidBg, chipPaidFg, chipPendingBg, chipPendingFg, danger (+24 more)

### Community 15 - "exam_repository.dart"
Cohesion: 0.06
Nodes (31): addQuestion, canStartExam, _charToInt, _client, createExamSchedule, createPaperSet, _currentStudentId, deletePaperSet (+23 more)

### Community 16 - "exam_quiz_screen.dart"
Cohesion: 0.07
Nodes (32): ../data/exam_repository.dart, _appliedResume, _applyResumedAnswers, _attemptId, build, createState, _currentQuestionIndex, didChangeAppLifecycleState (+24 more)

### Community 17 - "super_admin_approvals_screen.dart"
Cohesion: 0.07
Nodes (31): _ApprovalCard, _ApprovalCardState, _approveDocument, badgeColor, branchId, build, _buildDetailItem, _buildDocList (+23 more)

### Community 18 - "exam_result_screen.dart"
Cohesion: 0.08
Nodes (24): Animation, AnimationController, dart:math, _animController, bgColor, color, createState, dispose (+16 more)

### Community 19 - "StatelessWidget"
Cohesion: 0.09
Nodes (26): AdmitCardWidget, _QrPlaceholder, _EmptyState, _ExamCard, _InfoChip, _QuickActionCard, _ResultCard, _ActionBtn (+18 more)

### Community 20 - "admin_add_staff_screen.dart"
Cohesion: 0.07
Nodes (27): AdminAddStaffScreen, _AdminAddStaffScreenState, _basicSalaryController, build, createState, _daController, _departmentController, dispose (+19 more)

### Community 21 - "admin_course_detail_screen.dart"
Cohesion: 0.07
Nodes (27): AdminCourseDetailScreen, _AdminCourseDetailScreenState, _buildAboutCard, _buildCareerOpportunitiesCard, _buildCertificationCard, _buildExamCriteriaCard, _buildExamRow, _buildGradeBadge (+19 more)

### Community 22 - "super_admin_paper_manager_screen.dart"
Cohesion: 0.07
Nodes (31): _assessmentType, _buildEmpty, color, controller, _CreatePaperSetBottomSheet, _CreatePaperSetBottomSheetState, createState, _deletePaperSet (+23 more)

### Community 23 - "admin_marksheet_generator_screen.dart"
Cohesion: 0.17
Nodes (12): class, AdminMarksheetGeneratorScreen, _AdminMarksheetGeneratorScreenState, _branchId, _courseId, createState, _exportSummaryPdf, _isPreparing (+4 more)

### Community 24 - "admin_exam_scheduler_screen.dart"
Cohesion: 0.07
Nodes (28): _assignmentType, _assignmentValueController, build, _buildManualAssignmentValueField, _buildPickerFallback, _buildSearchableAssignmentField, createState, dispose (+20 more)

### Community 25 - "exam_list_screen.dart"
Cohesion: 0.11
Nodes (19): Gradient, _ActiveExamsSection, build, _buildSectionTitle, date, exam, examListProvider, gradient (+11 more)

### Community 26 - "app_image.dart"
Cohesion: 0.08
Nodes (24): BorderRadius?, BoxFit, double?, AppImage, borderRadius, build, _buildBase64Image, _buildCachedNetworkImage (+16 more)

### Community 27 - "config/supabase_service.dart"
Cohesion: 0.08
Nodes (24): adminCreateUser, adminDeleteUser, adminUpdateUserById, _anonKey, getUser, init, insert, query (+16 more)

### Community 28 - "my_application.cc"
Cohesion: 0.10
Nodes (20): FlPluginRegistry, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins(), main() (+12 more)

### Community 29 - "env_config.dart"
Cohesion: 0.08
Nodes (24): addressLine1, addressLine2, apiBaseUrl, apiTimeoutSeconds, appName, appVersion, authEmailDomain, debugMode (+16 more)

### Community 30 - "admin_student_directory_screen.dart"
Cohesion: 0.08
Nodes (25): AdminStudentDirectoryScreen, _AdminStudentDirectoryScreenState, branchId, build, _buildDetailRow, createState, dispose, _hasMore (+17 more)

### Community 31 - "student_repository.dart"
Cohesion: 0.08
Nodes (24): _formatDate, _formatTime, getAcademicCalendarEvents, getAttendanceStats, getFeeSnapshot, getMyExamResults, getNotices, getStudentAttendance (+16 more)

### Community 32 - "super_admin_branches_screen.dart"
Cohesion: 0.11
Nodes (18): _addOrEditBranch, _addressCtrl, _autoGenerate, branch, _BranchFormDialog, _BranchFormDialogState, _codeCtrl, createState (+10 more)

### Community 33 - "admin_panel_screen.dart"
Cohesion: 0.08
Nodes (27): isAdminProvider, AdminPanelScreen, _AdminPanelScreenState, build, _buildDetailRow, _buildDownloadsTab, _buildNoticesTab, _confirmDelete (+19 more)

### Community 34 - "admin_schedule_results_screen.dart"
Cohesion: 0.09
Nodes (22): AdminScheduleResultsScreen, _AdminScheduleResultsScreenState, color, createState, initState, _isLoading, _isPublishing, _isRefreshingRoster (+14 more)

### Community 35 - "ConsumerState"
Cohesion: 0.21
Nodes (12): ConsumerState, ConsumerStatefulWidget, AdminExamSchedulerScreen, SuperAdminBranchesScreen, _SuperAdminBranchesScreenState, _SuperAdminProfileScreenState, ForgotPasswordScreen, _ForgotPasswordScreenState (+4 more)

### Community 36 - "app_spacing.dart"
Cohesion: 0.09
Nodes (21): AppSpacing, bottomNavHeight, buttonHeight, cardPadding, huge, inputHeight, lg, md (+13 more)

### Community 37 - "admin_profile_screen.dart"
Cohesion: 0.10
Nodes (20): _AdminProfileBody, _AdminProfileBodyState, _buildCardSection, _buildCertificateCard, _buildHeroHeader, _buildInfoTile, _buildQuickStatsStrip, _buildStatItem (+12 more)

### Community 38 - "core/models/user_session.dart"
Cohesion: 0.10
Nodes (20): accessToken, authUid, branchId, email, fromJson, fromString, hasAnyPermission, hasPermission (+12 more)

### Community 39 - "super_admin_reset_password_screen.dart"
Cohesion: 0.10
Nodes (21): _apiBase, build, _confirmCtrl, createState, dispose, _formKey, initState, _isLoading (+13 more)

### Community 40 - "userRoleProvider"
Cohesion: 0.22
Nodes (11): userRoleProvider, AccountScreen, build, _QuickActionsSection, studentFeeStatusProvider, build, StudentFeeStatusScreen, teacherEmployeeProfileProvider (+3 more)

### Community 41 - "Map"
Cohesion: 0.18
Nodes (9): build, _buildIDDetail, data, DigitalIDCard, _getCurrentSession, build, emp, Map (+1 more)

### Community 42 - "attendance_repository.dart"
Cohesion: 0.11
Nodes (18): AttendanceRepository, attendanceRepositoryProvider, deleteAttendance, enrollStudent, getAttendanceForEnrollment, getAttendanceStats, getCourseEnrollments, getOverallAttendance (+10 more)

### Community 43 - "widget_test.dart"
Cohesion: 0.10
Nodes (19): package:gokul_shree_app/src/app.dart, package:gokul_shree_app/src/core/models/user_session.dart, adminLogin, build, checkPhoneNumber, currentRole, isAdmin, main (+11 more)

### Community 44 - "employees_routes.dart"
Cohesion: 0.12
Nodes (16): _body, buildAuthRouter, _json, jsonDecode, router, str, _body, buildEmployeesRouter (+8 more)

### Community 45 - "certificate_viewer_screen.dart"
Cohesion: 0.12
Nodes (17): dart:ui, GlobalKey, build, _buildFooterDetail, _capturePng, certificate, _certificateKey, CertificateViewerScreen (+9 more)

### Community 46 - "branch_dashboard_screen.dart"
Cohesion: 0.12
Nodes (18): supabaseClientProvider, branch, BranchDashboardScreen, _BranchDashboardScreenState, build, _buildOverviewTab, _buildStatRow, createState (+10 more)

### Community 47 - "custom_text_field.dart"
Cohesion: 0.12
Nodes (16): build, controller, createState, enabled, helperText, hint, icon, initState (+8 more)

### Community 48 - "admin_admit_card_screen.dart"
Cohesion: 0.12
Nodes (17): AdminAdmitCardScreen, _AdminAdmitCardScreenState, _admitCardData, build, _buildInfoRow, createState, _generateCard, initState (+9 more)

### Community 49 - "franchise_setup_screen.dart"
Cohesion: 0.12
Nodes (17): _addressController, _autoGenerateCode, build, _codeController, createState, dispose, _formKey, FranchiseSetupScreen (+9 more)

### Community 50 - "admin_routes.dart"
Cohesion: 0.11
Nodes (17): AdminRoutes, branchAdminBranches, standaloneRoutes, package:gokul_shree_app/src/features/exams/presentation/admin_schedule_results_screen.dart, ../presentation/admin_add_student_screen.dart, ../presentation/admin_dashboard_home.dart, ../presentation/admin_dues_report_screen.dart, ../presentation/admin_exam_scheduler_screen.dart (+9 more)

### Community 51 - "super_admin_routes.dart"
Cohesion: 0.11
Nodes (17): ../../admin/presentation/admin_add_student_screen.dart, ../../admin/presentation/admin_exam_scheduler_screen.dart, ../../admin/presentation/admin_results_entry_screen.dart, ../../admin/presentation/admin_study_material_upload_screen.dart, ../../admin/presentation/branch_registration_screen.dart, ../../admin/presentation/franchise_setup_screen.dart, ../../admin/presentation/super_admin_approvals_screen.dart, ../../admin/presentation/super_admin_branches_screen.dart (+9 more)

### Community 52 - "role_shell.dart"
Cohesion: 0.12
Nodes (17): Color get, _activeColor, build, createState, dispose, _go, _handleBack, initState (+9 more)

### Community 53 - "admin_notices_screen.dart"
Cohesion: 0.13
Nodes (15): AdminNoticesScreen, _AdminNoticesScreenState, build, _contentController, createState, _deleteNotice, _formKey, initState (+7 more)

### Community 54 - "admin_dashboard_home.dart"
Cohesion: 0.12
Nodes (16): Future, _activitiesFuture, AdminDashboardHome, _AdminDashboardHomeState, _buildActivityItem, _buildPrimaryCard, _buildQuickAction, _buildSecondaryCard (+8 more)

### Community 55 - "admin_fee_collection_screen.dart"
Cohesion: 0.08
Nodes (25): adminStudentsWithFeeStatusProvider, AdminFeeCollectionScreen, _AdminFeeCollectionScreenState, _amountController, build, _buildFeeMetric, _buildFilterChip, _buildPaymentForm (+17 more)

### Community 56 - "admin_reports_hub_screen.dart"
Cohesion: 0.12
Nodes (16): AdminReportsHubScreen, _AdminReportsHubScreenState, badge, _buildSection, createState, dispose, _HubItem, icon (+8 more)

### Community 57 - "admin_results_entry_screen.dart"
Cohesion: 0.12
Nodes (16): AdminResultsEntryScreen, _AdminResultsEntryScreenState, createState, dispose, _examController, _formKey, _gradeController, initialStudentId (+8 more)

### Community 58 - "admin_staff_directory_screen.dart"
Cohesion: 0.12
Nodes (16): AdminStaffDirectoryScreen, _AdminStaffDirectoryScreenState, branchId, build, createState, _deleteStaff, _filteredStaff, _filterStaff (+8 more)

### Community 59 - "contact_screen.dart"
Cohesion: 0.13
Nodes (14): build, _ContactInfoCard, content, createState, dispose, _districtController, _emailController, _formKey (+6 more)

### Community 60 - "admin_study_material_upload_screen.dart"
Cohesion: 0.15
Nodes (14): studyMaterialsProvider, AdminStudyMaterialUploadScreen, _AdminStudyMaterialUploadScreenState, build, createState, _descriptionController, dispose, _formKey (+6 more)

### Community 61 - "centre_finder_screen.dart"
Cohesion: 0.33
Nodes (5): build, createState, dispose, _districtController, _searchController

### Community 62 - "courses_screen.dart"
Cohesion: 0.08
Nodes (23): supabaseCoursesProvider, category, Course, duration, eligibility, fromJson, id, imagePath (+15 more)

### Community 63 - "package:go_router/go_router.dart"
Cohesion: 0.14
Nodes (13): AuthRoutes, routes, ContactRoutes, routes, DocumentsRoutes, routes, package:go_router/go_router.dart, ../presentation/centre_finder_screen.dart (+5 more)

### Community 64 - "marksheet_viewer_screen.dart"
Cohesion: 0.17
Nodes (11): build, _buildHeader, _buildInfoRow, _buildMarksTable, _buildStudentInfo, _buildSummary, _buildSummaryItem, _buildTableCell (+3 more)

### Community 65 - "exam_instructions_screen.dart"
Cohesion: 0.07
Nodes (29): correctOptionIndex, durationMinutes, Exam, fromJson, id, imageUrl, maxAttempts, negativeMarkingEnabled (+21 more)

### Community 66 - "document_service.dart"
Cohesion: 0.13
Nodes (14): ../config/institute_config.dart, _assetsDir, _buildSubjectsTable, _cell, _detailRow, DocumentService, _generateCertificate, _generateDocId (+6 more)

### Community 67 - "app_router.dart"
Cohesion: 0.13
Nodes (14): ../core/widgets/role_shell.dart, ../features/admin/routing/admin_routes.dart, ../features/auth/routing/auth_routes.dart, ../features/contact/routing/contact_routes.dart, ../features/courses/presentation/courses_screen.dart, ../features/documents/routing/documents_routes.dart, ../features/exams/routing/exams_routes.dart, ../features/public/presentation/public_home_screen.dart (+6 more)

### Community 68 - "package:flutter/material.dart"
Cohesion: 0.13
Nodes (16): build, MyApp, accentColor, AppTheme, appThemeProvider, backgroundColor, errorColor, lightTheme (+8 more)

### Community 69 - "forgot_password_screen.dart"
Cohesion: 0.20
Nodes (9): FormState, build, createState, dispose, _formKey, _handleReset, _isLoading, _mobileController (+1 more)

### Community 70 - "app_typography.dart"
Cohesion: 0.13
Nodes (14): AppTypography, bodyLg, bodyMd, bodySm, displayLg, displayMd, displaySm, headingLg (+6 more)

### Community 71 - "build"
Cohesion: 0.13
Nodes (16): build, build, build, Route /admin/add-student, Route /admin/branch-registration, Route /admin/dues-report, Route /admin/exam-scheduler, Route /admin/franchise-setup (+8 more)

### Community 72 - "ConsumerWidget"
Cohesion: 0.18
Nodes (13): ConsumerWidget, AdminProfileScreen, CoursesScreen, examResultsProvider, upcomingExamsProvider, ExamListBody, _RecentResultsSection, _UpcomingScheduleSection (+5 more)

### Community 73 - "teacher_results_upload_screen.dart"
Cohesion: 0.13
Nodes (15): build, createState, dispose, _examController, _formKey, _gradeController, _isSubmitting, _notesController (+7 more)

### Community 74 - "rate_limiter.dart"
Cohesion: 0.14
Nodes (13): apiLimiter, count, _Entry, _getIp, loginLimiter, max, message, RateLimiter (+5 more)

### Community 75 - "lib/models/user_session.dart"
Cohesion: 0.14
Nodes (13): branchId, fullName, profile, profileId, queryBranchId, role, studentBranchId, studentId (+5 more)

### Community 76 - "other_routes.dart"
Cohesion: 0.14
Nodes (13): _body, buildAttendanceRouter, buildBranchRouter, buildCourseRouter, buildFeeRouter, buildNoticeRouter, _json, jsonDecode (+5 more)

### Community 77 - "MaterialPageRoute"
Cohesion: 0.18
Nodes (13): currentRoleProvider, build, _buildCoursesTab, _buildStudentsTab, _showAddCourseDialog, _showAddDialog, _showEditCourseDialog, _navigateToAddEditStaff (+5 more)

### Community 78 - "admin_dashboard_screen.dart"
Cohesion: 0.15
Nodes (13): AdminDashboardScreen, _AdminDashboardScreenState, build, createState, _selectedIndex, _widgetOptions, package:gokul_shree_app/src/core/widgets/responsive_container.dart, package:gokul_shree_app/src/features/admin/presentation/admin_dashboard_home.dart (+5 more)

### Community 79 - "branch_registration_screen.dart"
Cohesion: 0.15
Nodes (13): BranchRegistrationScreen, _BranchRegistrationScreenState, build, createState, dispose, _emailController, _formKey, _isLoading (+5 more)

### Community 80 - "public_home_screen.dart"
Cohesion: 0.12
Nodes (19): supabaseNoticesProvider, build, _buildNoticesListFromSupabase, color, createState, dispose, icon, label (+11 more)

### Community 81 - "package:gokul_shree_app/src/core/theme/app_colors.dart"
Cohesion: 0.16
Nodes (12): StudentRepository, assessmentType, build, _buildEmptyNotice, _buildNoticeTile, repo, StudentNoticeBoard, package:gokul_shree_app/src/core/theme/app_colors.dart (+4 more)

### Community 82 - "teacher_dashboard_screen.dart"
Cohesion: 0.11
Nodes (18): ../../admin/data/admin_repository.dart, ../data/attendance_repository.dart, teacherStudentAttendanceStatsProvider, _ActionTile, build, _buildDetailMiniCard, _buildStudentAttendanceCard, _buildSubjectsSection (+10 more)

### Community 83 - "sessionProvider"
Cohesion: 0.20
Nodes (14): sessionProvider, backendServiceProvider, SuperAdminDashboardScreen, studentExamResultsProvider, studentProfileProvider, studentRepositoryProvider, build, StudentDashboardScreen (+6 more)

### Community 84 - "admin_qr_scanner_screen.dart"
Cohesion: 0.15
Nodes (12): build, _buildModeButton, _buildResultSheet, _controller, createState, dispose, _handleBarcode, _isScanning (+4 more)

### Community 85 - "List"
Cohesion: 0.17
Nodes (12): AdminDocumentApprovalScreen, _AdminDocumentApprovalScreenState, _approve, build, _buildList, createState, initState, _isLoading (+4 more)

### Community 86 - "../models/user_session.dart"
Cohesion: 0.18
Nodes (10): ../config/supabase_service.dart, dart:async, auditLog, _getIp, _sanitizeBody, _writeAudit, _json, requireAuth (+2 more)

### Community 87 - "back_handler.dart"
Cohesion: 0.17
Nodes (11): DateTime, BackHandler, _dedupWindow, didPopRoute, instance, _lastFallbackBack, _lastProcessed, package:flutter/widgets.dart (+3 more)

### Community 88 - "routing/student_routes.dart"
Cohesion: 0.17
Nodes (11): ../../documents/presentation/my_documents_screen.dart, ../../exams/presentation/exam_list_screen.dart, branches, standaloneRoutes, StudentRoutes, ../presentation/student_academics_screen.dart, ../presentation/student_attendance_screen.dart, ../presentation/student_dashboard_screen.dart (+3 more)

### Community 89 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 90 - "supabaseAuthProvider"
Cohesion: 0.18
Nodes (12): build, supabaseAuthNotifierProvider, supabaseAuthProvider, _buildLogoutButton, build, _handleLogin, _handleNext, _handleRegister (+4 more)

### Community 91 - "supabaseServiceProvider"
Cohesion: 0.29
Nodes (8): supabaseServiceProvider, build, _confirmLogout, _loadProfileAndBranch, _confirmLogout, _loadProfile, _submit, Route /login

### Community 92 - "package:gokul_shree_app/src/features/admin/data/admin_repository.dart"
Cohesion: 0.15
Nodes (12): _bannerStat, _buildComparisonTable, _buildQuickLinks, _buildRevenueSection, _buildSummaryBanner, _cardContainer, _comparisonMetric, _sectionHeader (+4 more)

### Community 93 - "role_guard.dart"
Cohesion: 0.18
Nodes (10): getBranchFilter, _json, permissions, requirePermission, roleBranchAdmin, roleStudent, roleSuperAdmin, roleTeacher (+2 more)

### Community 94 - "routes/documents_routes.dart"
Cohesion: 0.18
Nodes (10): _body, buildDocumentsRouter, _json, jsonDecode, _parseCount, parts, rateLimit, router (+2 more)

### Community 95 - "routes/student_routes.dart"
Cohesion: 0.18
Nodes (10): _body, buildStudentRouter, _json, jsonDecode, _parseCount, parts, rateLimit, router (+2 more)

### Community 96 - "🔴 CRITICAL BUGS (Will Cause Runtime Failures)"
Cohesion: 0.08
Nodes (25): 10. `002_security_rls.sql` — `audit_logs` INSERT policy has no RLS enabled first, 11. `002_security_rls.sql` — Missing DELETE policy on `students` table, 12. Schema mismatch — `profiles.id` vs `profiles.auth_uid`, 13. `001_supabase_schema.sql` — `subjects` table has no teacher assignment column, 14. `fee_payments` table — no unique constraint for duplicate receipts, 15. `student_attendance` — no unique constraint for upsert, 16. Mixed database clients — `pg` + `supabase-js` both in use, 17. No employee route — no REST API for employee/teacher profile (+17 more)

### Community 97 - "student_dashboard_screen.dart"
Cohesion: 0.12
Nodes (15): _buildActionCard, _buildAppBar, _buildLoading, _buildQuickActionsGrid, _buildSectionTitle, createState, initState, package:gokul_shree_app/src/core/providers/session_provider.dart (+7 more)

### Community 98 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 99 - "teacher_routes.dart"
Cohesion: 0.20
Nodes (9): ../../auth/presentation/account_screen.dart, branches, standaloneRoutes, TeacherRoutes, ../presentation/teacher_attendance_screen.dart, ../presentation/teacher_dashboard_screen.dart, ../presentation/teacher_employment_details_screen.dart, ../presentation/teacher_results_upload_screen.dart (+1 more)

### Community 100 - "responsive_container.dart"
Cohesion: 0.25
Nodes (7): EdgeInsetsGeometry, build, child, maxWidth, padding, ResponsiveContainer, Widget

### Community 101 - "update_service.dart"
Cohesion: 0.22
Nodes (8): checkForUpdate, _githubRepo, _isUpdateAvailable, _showUpdateDialog, UpdateService, package:package_info_plus/package_info_plus.dart, package:url_launcher/url_launcher.dart, static const String

### Community 102 - "State"
Cohesion: 0.32
Nodes (8): CustomTextField, _CustomTextFieldState, InAppWebViewScreen, _InAppWebViewScreenState, AdminQRScannerScreen, _AdminQRScannerScreenState, State, StatefulWidget

### Community 103 - "adminRepositoryProvider"
Cohesion: 0.20
Nodes (10): adminRepositoryProvider, _submitForm, _saveCourse, _loadData, _loadExisting, _approveExperienceCert, _approveStudent, _loadAll (+2 more)

### Community 104 - "examRepositoryProvider"
Cohesion: 0.18
Nodes (11): _save, examRepositoryProvider, _load, _refreshRoster, _startSession, _deleteQuestion, _load, QuestionManagerScreen (+3 more)

### Community 105 - "super_admin_dashboard_screen.dart"
Cohesion: 0.12
Nodes (15): Color, IconData, build, CustomButton, icon, isLoading, onPressed, text (+7 more)

### Community 106 - "student_id_card_screen.dart"
Cohesion: 0.20
Nodes (9): ../core/models/user_session.dart, ../core/providers/session_provider.dart, _downloadCard, _formatSession, _formatValidUntil, _IdRow, _monthName, value (+1 more)

### Community 107 - "Exam & Test Module — Rebuild Documentation"
Cohesion: 0.12
Nodes (16): 1. What was broken before, 2. What changed, 3. Expected results, 4. How to walk through it, 4a. Follow-up fixes: marking scheme + question images, 4b. Code-review fixes: RLS, idempotency, grading correctness, reliability, 4c. Second review pass: deadline design flaw, an unauthenticated grading hole, and a visual bug, 5. Known limitations / not done here (+8 more)

### Community 108 - "session_provider.dart"
Cohesion: 0.17
Nodes (11): bool get, ../../features/auth/data/auth_service.dart, clearSession, isLoggedIn, isLoggedInProvider, SessionNotifier, setSession, watch (+3 more)

### Community 109 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.15
Nodes (13): main, _buildEmptyState, _buildFeeCard, _buildSummaryCard, build, _buildTableRow, StudentProfileScreen, package:flutter_riverpod/flutter_riverpod.dart (+5 more)

### Community 110 - "institute_config.dart"
Cohesion: 0.29
Nodes (6): init, InstituteConfig, legalName, shortName, verifyBaseUrl, static String

### Community 111 - "package:shelf/shelf.dart"
Cohesion: 0.29
Nodes (6): buildDownloadRouter, _json, rateLimit, router, ../middleware/rate_limiter.dart, package:shelf/shelf.dart

### Community 112 - "exams_routes.dart"
Cohesion: 0.29
Nodes (6): ../domain/exam_model.dart, ExamsRoutes, routes, ../presentation/exam_instructions_screen.dart, ../presentation/exam_quiz_screen.dart, ../presentation/exam_result_screen.dart

### Community 113 - "adminStudentsProvider"
Cohesion: 0.20
Nodes (17): branchesProvider, adminDuesReportProvider, adminRevenueByBranchProvider, adminStudentsProvider, AdminDuesReportScreen, build, _AdminExamSchedulerScreenState, _buildAssignmentPicker (+9 more)

### Community 114 - "dart:convert"
Cohesion: 0.33
Nodes (5): dart:convert, null, resolveAvatarProvider, url, return

### Community 115 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.33
Nodes (5): _defaultRegistration, generateNext, _loadExistingRegistrationNumbers, RegistrationNumberGenerator, package:supabase_flutter/supabase_flutter.dart

### Community 116 - "MainActivity.kt"
Cohesion: 0.60
Nodes (3): MainActivity, FlutterActivity, FlutterEngine

### Community 117 - "adminCoursesProvider"
Cohesion: 0.40
Nodes (5): adminCoursesProvider, AdminAddStudentScreen, _AdminAddStudentScreenState, _buildCourseDetailsStep, build

### Community 118 - "super_admin_profile_screen.dart"
Cohesion: 0.13
Nodes (14): _buildCardSection, _buildHeroHeader, _buildInfoTile, _copyToClipboard, createState, _getInitials, initState, _isUploadingPhoto (+6 more)

### Community 119 - "🏗️ Gokul Shree LMS — Full-Stack Architecture Design"
Cohesion: 0.14
Nodes (13): 10. What Needs to Be Built — Priority Roadmap, 1. System Overview, 2. Multi-Role Access Architecture, 3. Flutter Frontend — Module Architecture, 4. Backend API Layer Architecture, 5. Database Schema — Entity Relationship, 6. Role-Based Data Flow, 7. Zoho Employee Feature — Data Architecture (+5 more)

### Community 120 - "package:gokul_shree_app/src/core/config/env_config.dart"
Cohesion: 0.14
Nodes (12): Dio, BackendService, _buildCandidateUrls, _dio, downloadMarksheet, fetchCertificatePdf, fetchMarksheetPdf, _generateWebsitePdf (+4 more)

### Community 121 - "📚 Gokul Shree LMS — Complete Project Master Document"
Cohesion: 0.15
Nodes (12): 2. System Architecture Overview, 4. Flutter Frontend — Module Architecture, 7. Security Architecture — 8 Defence Layers, 9. State Management — Riverpod Provider Tree, ClassPlus-Style LMS + Zoho Employee Portal, Directory Structure, 📚 Gokul Shree LMS — Complete Project Master Document, Navigation — GoRouter Role Guard Logic (+4 more)

### Community 122 - "SupabaseAuthNotifier"
Cohesion: 1.00
Nodes (3): ChangeNotifier, SupabaseAuthNotifier, MockSupabaseAuthNotifier

### Community 123 - "CustomPainter"
Cohesion: 0.67
Nodes (3): CustomPainter, _QrGridPainter, _ScoreRingPainter

### Community 124 - "10. Backend Audit Report — 19 Issues Found"
Cohesion: 0.17
Nodes (12): 10. Backend Audit Report — 19 Issues Found, Complete Issues Summary, Issue 10 — `student_attendance` Has No UNIQUE Constraint (Upsert Breaks), Issue 11 — `fee_payments.receipt_no` Has No UNIQUE Constraint, Issue 12 — No `teacher_subjects` Junction Table, Issue 13 — `profiles.id` vs `profiles.auth_uid` Confusion, Issue 6 — Logout Doesn't Invalidate Token, Issue 7 — Student Can Self-Assign to Any Branch (+4 more)

### Community 133 - "logger.dart"
Cohesion: 0.22
Nodes (8): AppLogger, error, info, init, _log, _logFile, dart:io, static final File

### Community 134 - "🚀 Getting Started"
Cohesion: 0.22
Nodes (8): 1. Install Dart SDK, 2. Install Dependencies, 3. Environment Variables, 4. Run the Server, 5. Database Migration, 🚀 Getting Started, Gokul Shree School — Dart Backend, 🛡️ Security Architecture

### Community 135 - "teacher_employment_details.dart"
Cohesion: 0.22
Nodes (8): build, _buildEmployeeDetails, _buildInfoRow, _buildLeaveCard, _buildPayRow, emp, _requestExperienceCertificate, TeacherEmploymentDetails

### Community 136 - "account_screen.dart"
Cohesion: 0.25
Nodes (7): _buildFinancialStat, _buildInfoCard, _buildMenuTile, _buildSectionHeader, _buildSliverAppBar, package:gokul_shree_app/src/features/auth/data/auth_service.dart, package:gokul_shree_app/src/features/teacher/data/attendance_repository.dart

### Community 137 - "student_attendance_screen.dart"
Cohesion: 0.29
Nodes (7): studentAttendanceProvider, _AttStat, build, label, StudentAttendanceScreen, package:flutter/foundation.dart, String value,

### Community 138 - "Phase 1: Flutter Compiler & Routing Fixes ✅ DONE"
Cohesion: 0.25
Nodes (8): 11. Implementation Plan — What Was Built, Fix 1 — `student_id_card_screen.dart`, Fix 2 — `test/widget_test.dart`, Fix 3 — `app_router.dart` Route Guard Refactor, New Riverpod Providers in `attendance_repository.dart`, Phase 1: Flutter Compiler & Routing Fixes ✅ DONE, Phase 2: Teacher Zoho Portal ✅ DONE, Rebuilt `teacher_dashboard_screen.dart`

### Community 139 - "What Each Role Can Do"
Cohesion: 0.25
Nodes (8): 3. Multi-Role Access Design, 🏢 Branch Admin, Permission Matrix (26 Granular Permissions), Role Hierarchy, 🎓 Student, 👑 Super Admin, 👨‍🏫 Teacher, What Each Role Can Do

### Community 140 - "🔵 DESIGN ISSUES (6)"
Cohesion: 0.29
Nodes (7): 🔵 DESIGN ISSUES (6), Issue 14 — `sync.routes.js` Exists but Is Never Mounted in `server.js`, Issue 15 — No Employee REST API, Issue 16 — `bcryptjs` Is Unused Dead Weight, Issue 17 — Mixed DB Clients (`pg` + `supabase-js`), Issue 18 — No Push Notifications (FCM), Issue 19 — `.env` File Missing from Flutter Project

### Community 141 - "12. Hosting & Cost Analysis"
Cohesion: 0.33
Nodes (6): 12. Hosting & Cost Analysis, Current Setup, Limitation of Free Tier, Platform Comparison, Recommended Pricing by Stage, Why NOT to Switch

### Community 142 - "14. Feature Backlog & Roadmap"
Cohesion: 0.33
Nodes (6): 14. Feature Backlog & Roadmap, ✅ Completed, 🔴 Critical Fixes (Do Immediately), 🔵 Future — LMS Phase 2 (ClassPlus Features), 🟢 Month 2, 🟡 Next Sprint

### Community 143 - "🔴 CRITICAL BUGS (5) — Will Cause Runtime Crashes"
Cohesion: 0.33
Nodes (6): 🔴 CRITICAL BUGS (5) — Will Cause Runtime Crashes, Issue 1 — `course.routes.js` — Wrong Database Client, Issue 2 — Column Name Mismatch: `date` vs `attendance_date`, Issue 3 — `fee.routes.js` — `COLLECT_FEE` Permission Doesn't Exist → HTTP 500, Issue 4 — `fee.routes.js` — `READ_OWN_FEE` vs `READ_OWN_FEES` → HTTP 500, Issue 5 — `role.guard.js` — `READ_BRANCH_ATTENDANCE` Missing → HTTP 500 for Admins

### Community 144 - "package:gokul_shree_app/src/core/services/supabase_service.dart"
Cohesion: 0.40
Nodes (4): DocumentRepository, getDocumentById, getMyDocuments, package:gokul_shree_app/src/core/services/supabase_service.dart

### Community 145 - "1. Project Vision & Goals"
Cohesion: 0.50
Nodes (4): 1. Project Vision & Goals, Core Goals, What Are We Building?, What Makes This Different from a Basic School App

### Community 146 - "5. Backend API Layer Architecture"
Cohesion: 0.50
Nodes (4): 5. Backend API Layer Architecture, Middleware Stack Per Request Flow, Route Modules, Server Entry Point — `src/server.js`

### Community 147 - "6. Database Schema — Entity Relationships"
Cohesion: 0.50
Nodes (4): 6. Database Schema — Entity Relationships, All 14 Tables, Critical Column Notes, Row Level Security (RLS) Policies Summary

### Community 148 - "8. Zoho Employee Feature Architecture"
Cohesion: 0.50
Nodes (4): 8. Zoho Employee Feature Architecture, Database Source — `employees` table, Riverpod Providers (Flutter), What the Teacher Sees

### Community 149 - "build"
Cohesion: 0.67
Nodes (3): build, Route /exams, Route /student-dashboard

### Community 150 - "13. Learning Roadmap"
Cohesion: 0.67
Nodes (3): 13. Learning Roadmap, Recommended Learning Order, Skills Required for This Project

## Knowledge Gaps
- **1666 isolated node(s):** `env`, `supabaseUrl`, `serviceKey`, `anonKey`, `allowedOrigins` (+1661 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1891 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `_` to `package:flutter/material.dart`, `app_spacing.dart`, `StatelessWidget`, `List`, `package:gokul_shree_app/src/core/config/env_config.dart`, `CustomPainter`?**
  _High betweenness centrality (0.050) - this node is a cross-community bridge._
- **Why does `_buildPasswordStep` connect `_buildPasswordStep` to `login_screen.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Why does `build` connect `build` to `userRoleProvider`, `MaterialPageRoute`, `admin_dashboard_home.dart`, `adminRepositoryProvider`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `env`, `supabaseUrl`, `serviceKey` to the rest of the system?**
  _1666 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `_` be split into smaller, more focused modules?**
  _Cohesion score 0.02857142857142857 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05311676909569798 - nodes in this community are weakly interconnected._
- **Should `admin_add_student_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03278688524590164 - nodes in this community are weakly interconnected._