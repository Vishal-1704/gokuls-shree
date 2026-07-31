// lib/src/routing/app_router.dart
// Complete role-based navigation.
// Decoupled sub-route bundles are imported from each feature module.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../core/models/user_session.dart';
import '../core/providers/session_provider.dart';

// Import modular routes
import '../features/auth/routing/auth_routes.dart';
import '../features/contact/routing/contact_routes.dart';
import '../features/documents/routing/documents_routes.dart';
import '../features/exams/routing/exams_routes.dart';
import '../features/student/routing/student_routes.dart';
import '../features/teacher/routing/teacher_routes.dart';
import '../features/admin/routing/admin_routes.dart';
import '../features/super_admin_app/routing/super_admin_routes.dart';
import '../features/courses/presentation/courses_screen.dart';
import '../features/public/presentation/public_home_screen.dart';
import '../core/widgets/role_shell.dart';

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
        '/contact', '/centre-finder', '/verify', '/courses'];
      final isPublic = publicPaths.any((p) => path == p || path.startsWith('/verify/') || path == '/courses');

      // Not logged in → redirect to login
      if (!loggedIn) {
        if (path == '/' || !isPublic) return '/login';
      }

      // Already logged in → redirect away from public pages to role home
      if (loggedIn && isPublic) return session.homeRoute;

      // Student registered but not yet approved by a branch/super admin —
      // lock them to the pending screen; the backend rejects every other
      // student data endpoint for this account anyway, so this is just an
      // honest reflection of that, not the actual security boundary.
      const pendingPath = '/student/pending-approval';
      if (loggedIn && session.role == UserRole.student && !session.isApproved) {
        if (path != pendingPath) return pendingPath;
        return null;
      }
      if (loggedIn && session.role == UserRole.student && path == pendingPath) {
        return session.homeRoute;
      }

      if (loggedIn && !_isAllowedRouteForRole(session, path)) {
        return session.homeRoute;
      }

      return null;
    },
    routes: [
      // Public / Auth
      ...AuthRoutes.routes,
      ...ContactRoutes.routes,
      ...DocumentsRoutes.routes,
      ...ExamsRoutes.routes,
      ...StudentRoutes.standaloneRoutes,
      ...AdminRoutes.standaloneRoutes,
      ...SuperAdminRoutes.standaloneRoutes,
      ...TeacherRoutes.standaloneRoutes,
      
      GoRoute(
        path: '/courses',
        builder: (context, state) => const CoursesScreen(),
      ),

      // Public Home
      GoRoute(
        path: '/', 
        builder: (context, state) => const PublicHomeScreen(),
      ),

      // ══════════════════════════════════════════════════
      // STUDENT SHELL — bottom nav: Dashboard | Exams | Docs | Profile
      // ══════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShell(
          shell: shell,
          role: UserRole.student,
          tabs: const [
            GButton(icon: Icons.dashboard_rounded,    text: 'Home'),
            GButton(icon: Icons.assignment_rounded,   text: 'Exams'),
            GButton(icon: Icons.folder_rounded,       text: 'Docs'),
            GButton(icon: Icons.person_rounded,       text: 'Profile'),
          ],
        ),
        branches: StudentRoutes.branches,
      ),

      // ══════════════════════════════════════════════════
      // TEACHER SHELL
      // ══════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShell(
          shell: shell,
          role: UserRole.teacher,
          tabs: const [
            GButton(icon: Icons.dashboard_rounded,       text: 'Home'),
            GButton(icon: Icons.how_to_reg_rounded,     text: 'Attendance'),
            GButton(icon: Icons.people_alt_rounded,     text: 'Students'),
            GButton(icon: Icons.person_rounded,         text: 'Profile'),
          ],
        ),
        branches: TeacherRoutes.branches,
      ),

      // ══════════════════════════════════════════════════
      // BRANCH ADMIN SHELL
      // ══════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShell(
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
        branches: AdminRoutes.branchAdminBranches,
      ),

      // ══════════════════════════════════════════════════
      // SUPER ADMIN SHELL
      // ══════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShell(
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
        branches: SuperAdminRoutes.branches,
      ),
    ],
  );
});

// _RoleShell extracted to core/widgets/role_shell.dart

bool _isAllowedRouteForRole(UserSession session, String path) {
  if (session.role == UserRole.superAdmin) return true;
  if (path == session.homeRoute) return true;

  switch (session.role) {
    case UserRole.student:
      if (path.startsWith('/student')) return true;
      final allowed = {'/fee-status', '/results', '/attendance', '/id-card', '/courses'};
      return allowed.contains(path);

    case UserRole.teacher:
      if (path.startsWith('/teacher')) return true;
      return false;

    case UserRole.branchAdmin:
      if (path.startsWith('/branch-admin')) return true;
      final allowed = {
        '/admin/add-student',
        '/admin/dues-report',
        '/admin/marksheet-generator',
        '/admin/results-entry',
        '/admin/exam-scheduler',
        '/admin/study-material',
        '/admin/branch-registration',
        '/admin/franchise-setup',
      };
      return allowed.contains(path);

    default:
      return false;
  }
}
