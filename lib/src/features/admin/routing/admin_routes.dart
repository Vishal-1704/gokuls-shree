import 'package:go_router/go_router.dart';
import '../presentation/admin_dashboard_home.dart';
import '../presentation/admin_panel_screen.dart';
import '../presentation/admin_dues_report_screen.dart';
import '../presentation/admin_marksheet_generator_screen.dart';
import '../presentation/admin_add_student_screen.dart';
import '../presentation/admin_results_entry_screen.dart';
import '../presentation/admin_exam_scheduler_screen.dart';
import '../presentation/admin_study_material_upload_screen.dart';
import '../presentation/admin_profile_screen.dart';
import '../presentation/branch_registration_screen.dart';
import '../presentation/franchise_setup_screen.dart';
import '../presentation/admin_reports_hub_screen.dart';
import '../presentation/admin_fee_collection_screen.dart';
import 'package:gokul_shree_app/src/features/exams/presentation/admin_schedule_results_screen.dart';
import 'package:gokul_shree_app/src/features/teacher/presentation/teacher_attendance_screen.dart';
import '../presentation/admin_payslip_generator_screen.dart';
import '../presentation/admin_propose_salary_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BRANCH ADMIN ROUTES
// All routes scoped to /branch-admin prefix.
// Shell has 4 tabs: Dashboard | Institute | Reports & Fees | Profile
// Super Admin routes have been moved to: super_admin_app/routing/super_admin_routes.dart
// ─────────────────────────────────────────────────────────────────────────────
class AdminRoutes {
  /// Branches for the BranchAdmin StatefulShellRoute in app_router.dart
  static List<StatefulShellBranch> get branchAdminBranches => [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/branch-admin',
          builder: (c, s) => const AdminDashboardHome(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/branch-admin/students',
          builder: (c, s) => const AdminPanelScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/branch-admin/reports',
          builder: (c, s) => const AdminReportsHubScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/branch-admin/profile',
          builder: (c, s) => const AdminProfileScreen(),
        ),
      ],
    ),
  ];

  /// Standalone (non-shell) routes accessible to branch_admin
  static List<GoRoute> get standaloneRoutes => [
    GoRoute(
      path: '/admin/fee-collection',
      builder: (c, s) => const AdminFeeCollectionScreen(),
    ),
    GoRoute(
      path: '/admin/add-student',
      builder: (c, s) => const AdminAddStudentScreen(),
    ),
    GoRoute(
      path: '/admin/results-entry',
      builder: (c, s) => const AdminResultsEntryScreen(),
    ),
    GoRoute(
      path: '/admin/exam-scheduler',
      builder: (c, s) => const AdminExamSchedulerScreen(),
    ),
    GoRoute(
      path: '/admin/study-material',
      builder: (c, s) => const AdminStudyMaterialUploadScreen(),
    ),
    GoRoute(
      path: '/admin/branch-registration',
      builder: (c, s) => const BranchRegistrationScreen(),
    ),
    GoRoute(
      path: '/admin/franchise-setup',
      builder: (c, s) => const FranchiseSetupScreen(),
    ),
    GoRoute(
      path: '/admin/marksheet-generator',
      builder: (c, s) => const AdminMarksheetGeneratorScreen(),
    ),
    GoRoute(
      path: '/admin/dues-report',
      builder: (c, s) => const AdminDuesReportScreen(),
    ),
    GoRoute(
      path: '/admin/schedule-results',
      builder: (c, s) => const AdminScheduleResultsScreen(),
    ),
    GoRoute(
      path: '/admin/attendance',
      builder: (c, s) => const TeacherAttendanceScreen(),
    ),
    GoRoute(
      path: '/admin/payslip-generator',
      builder: (c, s) => const AdminPayslipGeneratorScreen(),
    ),
    GoRoute(
      path: '/admin/propose-salary',
      builder: (c, s) => const AdminProposeSalaryScreen(),
    ),
  ];
}
