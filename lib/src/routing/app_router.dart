// lib/src/routing/app_router.dart
// Complete role-based navigation.
// Decoupled sub-route bundles are imported from each feature module.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../core/models/user_session.dart';
import '../core/providers/session_provider.dart';
import '../features/auth/data/auth_service.dart';

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
import '../features/splash/presentation/splash_screen.dart';
import '../core/widgets/role_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROUTER PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
final goRouterProvider = Provider<GoRouter>((ref) {
  // Built once — does NOT ref.watch(sessionProvider), which used to force a
  // brand-new GoRouter (and a full MaterialApp.router re-initialization,
  // wiping the navigation stack) on every session change, not just at boot.
  // refreshListenable below re-runs `redirect` on the *current* route
  // instead, which is what go_router is actually designed for.
  final authNotifier = ref.read(supabaseAuthNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final path = state.uri.path;

      // The splash screen decides when to navigate onward itself (its own
      // animation timing + waiting out AuthLoading) — the generic
      // logged-in/logged-out rules below would otherwise redirect away
      // from it immediately, before the bounce animation or the
      // session-restore wait ever gets a chance to run.
      if (path == '/splash') return null;

      final authState = ref.read(supabaseAuthProvider);
      final session = ref.read(sessionProvider);
      final loggedIn = session != null;

      // No public browse-without-login landing page anymore — '/' just
      // bounces to '/login' (see the GoRoute below), so it's intentionally
      // not in this list.
      final publicPaths = ['/login', '/forgot-password',
        '/contact', '/centre-finder', '/verify', '/courses'];
      final isPublic = publicPaths.any((p) => path == p || path.startsWith('/verify/') || path == '/courses');

      // Session restoration still in flight (a persisted Supabase session
      // exists but its profile hasn't loaded yet) — this is neither a
      // confirmed logged-in nor logged-out state, so don't decide yet.
      // Forcing '/login' here is exactly what caused an already-logged-in
      // user to see the login screen on cold boot; refreshListenable will
      // re-run this redirect the moment AuthLoading resolves either way.
      if (authState is AuthLoading) {
        return null;
      }

      // Not logged in → redirect to login
      if (!loggedIn && !isPublic) return '/login';

      // Already logged in → redirect away from public pages to role home
      if (loggedIn && isPublic) return session.homeRoute;

      // Allow all students (approved or unapproved) to access the normal shell.
      // Unapproved students will see a banner on the dashboard and empty states
      // on other tabs.

      if (loggedIn && !_isAllowedRouteForRole(session, path)) {
        return session.homeRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

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

      // '/' has no page of its own anymore — bounce any stray navigation
      // to '/' (e.g. a stale bookmark) straight to '/login'.
      GoRoute(
        path: '/',
        redirect: (context, state) => '/login',
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
            GButton(icon: Icons.school_rounded,       text: 'Academics'),
            GButton(icon: Icons.person_rounded,       text: 'Account'),
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
            GButton(icon: Icons.school,               text: 'Institute'),
            GButton(icon: Icons.analytics_rounded,    text: 'Reports & Fees'),
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
        '/admin/attendance',
        '/admin/add-student',
        '/admin/dues-report',
        '/admin/marksheet-generator',
        '/admin/results-entry',
        '/admin/exam-scheduler',
        '/admin/study-material',
        '/admin/branch-registration',
        '/admin/franchise-setup',
        '/admin/schedule-results',
        '/admin/fee-collection',
      };
      return allowed.contains(path);

    default:
      return false;
  }
}
