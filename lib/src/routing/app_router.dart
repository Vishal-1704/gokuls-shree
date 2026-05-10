// lib/src/routing/app_router.dart
// Complete role-based navigation.
// After login → role determines which shell + bottom nav is shown.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../core/models/user_session.dart';
import '../core/providers/session_provider.dart';

// ── Public screens
import '../features/home/presentation/public_home_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/contact/presentation/contact_screen.dart';
import '../features/contact/presentation/centre_finder_screen.dart';
import '../features/documents/presentation/verification_screen.dart';

// ── Student screens
import '../features/student/presentation/student_dashboard_screen.dart';
import '../features/student/presentation/student_fee_status_screen.dart';
import '../features/student/presentation/student_result_list_screen.dart';
import '../features/student/presentation/student_attendance_screen.dart';
import '../features/student/presentation/student_id_card_screen.dart';
import '../features/documents/presentation/my_documents_screen.dart';
import '../features/exams/presentation/exam_list_screen.dart';
import '../features/exams/presentation/exam_instructions_screen.dart';
import '../features/exams/presentation/exam_quiz_screen.dart';
import '../features/exams/presentation/exam_result_screen.dart';
import '../features/exams/domain/exam_model.dart';
import '../features/auth/presentation/account_screen.dart';

// ── Teacher screens
import '../features/teacher/presentation/teacher_dashboard_screen.dart';
import '../features/teacher/presentation/teacher_attendance_screen.dart';
import '../features/teacher/presentation/teacher_students_screen.dart';

// ── Branch Admin screens
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/admin_dashboard_home.dart';
import '../features/admin/presentation/admin_panel_screen.dart';
import '../features/admin/presentation/admin_add_student_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_results_entry_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/admin_dues_report_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/branch_registration_screen.dart';
import 'package:gokul_shree_app/src/features/admin/presentation/franchise_setup_screen.dart';
import '../features/admin/presentation/admin_dues_report_screen.dart';
import '../features/admin/presentation/admin_marksheet_generator_screen.dart';
import '../features/admin/presentation/admin_study_material_upload_screen.dart';
import '../features/admin/presentation/admin_exam_scheduler_screen.dart';

// ── Super Admin screens  (reuse admin screens + extras)
import '../features/admin/presentation/super_admin_dashboard_screen.dart';
import '../features/admin/presentation/super_admin_approvals_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROUTER PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
final goRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loggedIn = session != null;
      final path = state.uri.path;

      final publicPaths = ['/', '/login', '/forgot-password',
        '/contact', '/centre-finder', '/verify'];
      final isPublic = publicPaths.any((p) => path == p || path.startsWith('/verify/'));

      // Not logged in → force to public home
      if (!loggedIn && !isPublic) return '/';

      // Already logged in → redirect away from public pages to role home
      if (loggedIn && isPublic) return session.homeRoute;

      return null;
    },
    routes: [
      // ══════════════════════════════════════════════════
      // PUBLIC — no auth needed
      // ══════════════════════════════════════════════════
      GoRoute(path: '/',               builder: (c, s) => const PublicHomeScreen()),
      GoRoute(path: '/login',          builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/forgot-password',builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(path: '/contact',        builder: (c, s) => const ContactScreen()),
      GoRoute(path: '/centre-finder',  builder: (c, s) => const CentreFinderScreen()),
      GoRoute(
        path: '/verify',
        builder: (c, s) => const VerificationScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (c, s) => VerificationScreen(documentId: s.pathParameters['id']),
          ),
        ],
      ),

      // ══════════════════════════════════════════════════
      // STUDENT SHELL — bottom nav: Dashboard | Exams | Docs | Profile
      // ══════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _RoleShell(
          shell: shell,
          role: UserRole.student,
          tabs: const [
            GButton(icon: Icons.dashboard_rounded,    text: 'Home'),
            GButton(icon: Icons.assignment_rounded,   text: 'Exams'),
            GButton(icon: Icons.folder_rounded,       text: 'Docs'),
            GButton(icon: Icons.person_rounded,       text: 'Profile'),
          ],
        ),
      branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/student', builder: (c, s) => const StudentDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/exams', builder: (c, s) => const ExamListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/docs', builder: (c, s) => const MyDocumentsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/student/profile', builder: (c, s) => const AccountScreen()),
          ]),
        ],
      ),

      // ══════════════════════════════════════════════════
      // TEACHER SHELL
      // ══════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _RoleShell(
          shell: shell,
          role: UserRole.teacher,
          tabs: const [
            GButton(icon: Icons.dashboard_rounded,       text: 'Home'),
            GButton(icon: Icons.how_to_reg_rounded,     text: 'Attendance'),
            GButton(icon: Icons.people_alt_rounded,     text: 'Students'),
            GButton(icon: Icons.person_rounded,         text: 'Profile'),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/teacher', builder: (c, s) => const TeacherDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/teacher/attendance', builder: (c, s) => const TeacherAttendanceScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/teacher/students', builder: (c, s) => const TeacherStudentsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/teacher/profile', builder: (c, s) => const AccountScreen()),
          ]),
        ],
      ),

      // ══════════════════════════════════════════════════
      // BRANCH ADMIN SHELL
      // ══════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _RoleShell(
          shell: shell,
          role: UserRole.branchAdmin,
          tabs: const [
            GButton(icon: Icons.dashboard_rounded,    text: 'Dashboard'),
            GButton(icon: Icons.people_alt_rounded,   text: 'Students'),
            GButton(icon: Icons.payments_rounded,     text: 'Fees'),
            GButton(icon: Icons.bar_chart_rounded,    text: 'Reports'),
            GButton(icon: Icons.person_rounded,       text: 'Profile'),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            // Use AdminDashboardHome directly to avoid double nav bar from AdminDashboardScreen
            GoRoute(path: '/branch-admin', builder: (c, s) => const AdminDashboardHome()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/branch-admin/students', builder: (c, s) => const AdminPanelScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/branch-admin/fees', builder: (c, s) => const AdminDuesReportScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/branch-admin/reports', builder: (c, s) => const AdminMarksheetGeneratorScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/branch-admin/profile', builder: (c, s) => const AccountScreen()),
          ]),
        ],
      ),

      // ══════════════════════════════════════════════════
      // SUPER ADMIN SHELL — Dashboard | Approvals | Branches | Settings | Profile
      // ══════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _RoleShell(
          shell: shell,
          role: UserRole.superAdmin,
          tabs: const [
            GButton(icon: Icons.admin_panel_settings_rounded, text: 'Dashboard'),
            GButton(icon: Icons.verified_rounded,             text: 'Approvals'),
            GButton(icon: Icons.account_balance_rounded,      text: 'Branches'),
            GButton(icon: Icons.bar_chart_rounded,            text: 'Reports'),
            GButton(icon: Icons.person_rounded,               text: 'Profile'),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/super-admin', builder: (c, s) => const SuperAdminDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/super-admin/approvals', builder: (c, s) => const SuperAdminApprovalsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/super-admin/branches', builder: (c, s) => const AdminPanelScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/super-admin/reports', builder: (c, s) => const AdminMarksheetGeneratorScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/super-admin/profile', builder: (c, s) => const AccountScreen()),
          ]),
        ],
      ),

      // ══════════════════════════════════════════════════
      // STANDALONE SCREENS (push on top of any shell)
      // ══════════════════════════════════════════════════
      GoRoute(path: '/fee-status',  builder: (c, s) => const StudentFeeStatusScreen()),
      GoRoute(path: '/results',     builder: (c, s) => const StudentResultListScreen()),
      GoRoute(path: '/attendance',  builder: (c, s) => const StudentAttendanceScreen()),
      GoRoute(path: '/id-card',     builder: (c, s) => const StudentIdCardScreen()),

      GoRoute(path: '/admin/add-student',        builder: (c, s) => const AdminAddStudentScreen()),
      GoRoute(path: '/admin/results-entry',      builder: (c, s) => const AdminResultsEntryScreen()),
      GoRoute(path: '/admin/exam-scheduler',     builder: (c, s) => const AdminExamSchedulerScreen()),
      GoRoute(path: '/admin/study-material',     builder: (c, s) => const AdminStudyMaterialUploadScreen()),
      GoRoute(path: '/admin/branch-registration', builder: (c, s) => const BranchRegistrationScreen()),
      GoRoute(path: '/admin/franchise-setup',     builder: (c, s) => const FranchiseSetupScreen()),

      // Exam flow
      GoRoute(
        path: '/exam-instruction/:id',
        builder: (c, s) => ExamInstructionsScreen(exam: s.extra as Exam),
      ),
      GoRoute(
        path: '/exam-start/:id',
        builder: (c, s) => ExamQuizScreen(
          examId: s.pathParameters['id']!,
          examMetadata: s.extra as Exam?,
        ),
      ),
      GoRoute(
        path: '/exam-result',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return ExamResultScreen(
            score: e['score'], totalQuestions: e['total'], examTitle: e['title'],
          );
        },
      ),
    ],
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// ROLE SHELL WIDGET — shared bottom nav bar with role-specific tabs
// ─────────────────────────────────────────────────────────────────────────────
class _RoleShell extends ConsumerStatefulWidget {
  const _RoleShell({
    required this.shell,
    required this.role,
    required this.tabs,
  });
  final StatefulNavigationShell shell;
  final UserRole role;
  final List<GButton> tabs;

  @override
  ConsumerState<_RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends ConsumerState<_RoleShell> {
  DateTime? _lastBack;
  final List<int> _history = [0];

  void _go(int index) {
    setState(() => _history.add(index));
    widget.shell.goBranch(index,
        initialLocation: index == widget.shell.currentIndex);
  }

  void _onPop(bool didPop) {
    if (didPop) return;
    if (_history.length > 1) {
      _history.removeLast();
      setState(() {});
      widget.shell.goBranch(_history.last, initialLocation: false);
      return;
    }
    final now = DateTime.now();
    if (_lastBack == null || now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Press back again to exit'), duration: Duration(seconds: 2)),
      );
    } else {
      SystemNavigator.pop();
    }
  }

  // Nav bar color per role
  Color get _navBg {
    switch (widget.role) {
      case UserRole.superAdmin:  return const Color(0xFF1A0A2E); // deep purple
      case UserRole.branchAdmin: return const Color(0xFF0A1628); // deep blue
      case UserRole.teacher:     return const Color(0xFF0A2010); // deep green
      default:                   return const Color(0xFF0E1E33); // ink navy (student)
    }
  }

  Color get _activeColor => const Color(0xFFF5CC45); // gold CTA — same for all roles

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: _onPop,
      child: Scaffold(
        body: widget.shell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: _navBg,
            border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: GNav(
                gap: 6,
                iconSize: 22,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                duration: const Duration(milliseconds: 250),
                tabBackgroundColor: _activeColor,
                activeColor: const Color(0xFF070D18),
                color: Colors.white54,
                tabs: widget.tabs,
                selectedIndex: widget.shell.currentIndex,
                onTabChange: _go,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
