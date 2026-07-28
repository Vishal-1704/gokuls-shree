import 'package:go_router/go_router.dart';
import '../presentation/admin_dashboard_home.dart';
import '../presentation/admin_panel_screen.dart';
import '../presentation/admin_dues_report_screen.dart';
import '../presentation/admin_marksheet_generator_screen.dart';
import '../../auth/presentation/account_screen.dart';
import '../presentation/admin_add_student_screen.dart';
import '../presentation/admin_results_entry_screen.dart';
import '../presentation/admin_exam_scheduler_screen.dart';
import '../presentation/admin_study_material_upload_screen.dart';
import '../presentation/branch_registration_screen.dart';
import '../presentation/franchise_setup_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BRANCH ADMIN ROUTES
// All routes scoped to /branch-admin prefix.
// Shell has 5 tabs: Dashboard | Students | Fees | Reports | Profile
// Super Admin routes have been moved to: super_admin_app/routing/super_admin_routes.dart
// ─────────────────────────────────────────────────────────────────────────────
class AdminRoutes {
  /// Branches for the BranchAdmin StatefulShellRoute in app_router.dart
  static List<StatefulShellBranch> get branchAdminBranches => [
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/branch-admin',
        builder: (c, s) => const AdminDashboardHome(),
      ),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/branch-admin/students',
        builder: (c, s) => const AdminPanelScreen(),
      ),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/branch-admin/fees',
        builder: (c, s) => const AdminDuesReportScreen(),
      ),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/branch-admin/reports',
        builder: (c, s) => const AdminMarksheetGeneratorScreen(),
      ),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/branch-admin/profile',
        builder: (c, s) => const AccountScreen(),
      ),
    ]),
  ];

  /// Standalone (non-shell) routes accessible to branch_admin
  static List<GoRoute> get standaloneRoutes => [
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
  ];
}
