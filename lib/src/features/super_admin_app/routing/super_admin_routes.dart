import 'package:go_router/go_router.dart';
import '../../admin/presentation/super_admin_dashboard_screen.dart';
import '../../admin/presentation/super_admin_approvals_screen.dart';
import '../../admin/presentation/super_admin_branches_screen.dart';
import '../../admin/presentation/manage_departments_screen.dart';
import '../../admin/presentation/admin_payslip_generator_screen.dart';
import '../../admin/presentation/admin_propose_salary_screen.dart';
import '../../admin/presentation/super_admin_reports_screen.dart';
import '../../admin/presentation/super_admin_profile_screen.dart';
import '../../admin/presentation/super_admin_reset_password_screen.dart';
import '../../exams/presentation/super_admin_paper_manager_screen.dart';
import '../../admin/presentation/admin_add_student_screen.dart';
import '../../admin/presentation/admin_results_entry_screen.dart';
import '../../admin/presentation/admin_exam_scheduler_screen.dart';
import '../../admin/presentation/admin_study_material_upload_screen.dart';
import '../../admin/presentation/branch_registration_screen.dart';
import '../../admin/presentation/franchise_setup_screen.dart';
import '../../exams/presentation/admin_schedule_results_screen.dart';
import '../../teacher/presentation/teacher_attendance_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SUPER ADMIN ROUTES
// All routes scoped to /super-admin prefix.
// This shell has 5 tabs: Dashboard | Approvals | Branches | Reports | Profile
// ─────────────────────────────────────────────────────────────────────────────
class SuperAdminRoutes {
  /// Branches for the SuperAdmin StatefulShellRoute in app_router.dart
  static List<StatefulShellBranch> get branches => [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/super-admin',
          builder: (c, s) => const SuperAdminDashboardScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/super-admin/approvals',
          builder: (c, s) => const SuperAdminApprovalsScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/super-admin/branches',
          builder: (c, s) => const SuperAdminBranchesScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/super-admin/reports',
          builder: (c, s) => const SuperAdminReportsScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/super-admin/profile',
          builder: (c, s) => const SuperAdminProfileScreen(),
        ),
      ],
    ),
  ];

  /// Standalone (non-shell) routes accessible to super_admin
  static List<GoRoute> get standaloneRoutes => [
    GoRoute(
      path: '/super-admin/reset-password',
      builder: (c, s) => const SuperAdminResetPasswordScreen(),
    ),
    GoRoute(
      path: '/super-admin/paper-manager',
      builder: (c, s) => const SuperAdminPaperManagerScreen(),
    ),
    GoRoute(
      path: '/super-admin/add-student',
      builder: (c, s) => const AdminAddStudentScreen(),
    ),
    GoRoute(
      path: '/super-admin/results-entry',
      builder: (c, s) => const AdminResultsEntryScreen(),
    ),
    GoRoute(
      path: '/super-admin/exam-scheduler',
      builder: (c, s) => const AdminExamSchedulerScreen(),
    ),
    GoRoute(
      path: '/super-admin/study-material',
      builder: (c, s) => const AdminStudyMaterialUploadScreen(),
    ),
    GoRoute(
      path: '/super-admin/branch-registration',
      builder: (c, s) => const BranchRegistrationScreen(),
    ),
    GoRoute(
      path: '/super-admin/franchise-setup',
      builder: (c, s) => const FranchiseSetupScreen(),
    ),
    GoRoute(
      path: '/super-admin/schedule-results',
      builder: (c, s) => const AdminScheduleResultsScreen(),
    ),
    GoRoute(
      path: '/super-admin/attendance',
      builder: (c, s) => const TeacherAttendanceScreen(),
    ),
    GoRoute(
      path: '/super-admin/manage-departments',
      builder: (c, s) => const ManageDepartmentsScreen(),
    ),
    GoRoute(
      path: '/super-admin/payslip-generator',
      builder: (c, s) => const AdminPayslipGeneratorScreen(),
    ),
    GoRoute(
      path: '/super-admin/propose-salary',
      builder: (c, s) => const AdminProposeSalaryScreen(),
    ),
  ];
}
