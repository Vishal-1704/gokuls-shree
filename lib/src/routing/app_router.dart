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
      // Public / Auth
      ...AuthRoutes.routes,
      ...ContactRoutes.routes,
      ...DocumentsRoutes.routes,
      ...ExamsRoutes.routes,
      ...StudentRoutes.standaloneRoutes,
      ...AdminRoutes.standaloneRoutes,
      ...TeacherRoutes.standaloneRoutes,

      // Fallback or Public Home
      GoRoute(path: '/', builder: (c, s) => const Scaffold(body: Center(child: CircularProgressIndicator()))),

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
        branches: StudentRoutes.branches,
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
        branches: TeacherRoutes.branches,
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
        branches: AdminRoutes.branchAdminBranches,
      ),

      // ══════════════════════════════════════════════════
      // SUPER ADMIN SHELL
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
        branches: AdminRoutes.superAdminBranches,
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
