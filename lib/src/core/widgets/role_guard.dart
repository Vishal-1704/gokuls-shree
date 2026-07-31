import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
// lib/src/core/widgets/role_guard.dart
//
// Flutter-side security guard.
// Wraps any screen that should only be accessible by specific roles.
// If the current user's role doesn't match → shows AccessDeniedScreen.
//
// Usage:
//   RoleGuard(
//     allowedRoles: [UserRole.superAdmin],
//     child: SuperAdminApprovalsScreen(),
//   )
//
// Also used automatically by the router's StatefulShellRoute builders.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_session.dart';
import '../providers/session_provider.dart';
import '../../features/auth/data/auth_service.dart';

class RoleGuard extends ConsumerWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  final List<UserRole> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    // Not logged in at all
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const _LoadingScreen();
    }

    // Role not in allowed list
    if (!allowedRoles.contains(session.role)) {
      return _AccessDeniedScreen(
        currentRole: session.role,
        allowedRoles: allowedRoles,
      );
    }

    return child;
  }
}

// ── Loading placeholder while redirecting ────────────────────────────────
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.inkNavy800,
    body: Center(child: CircularProgressIndicator(color: AppColors.goldCta)),
  );
}

// ── Access Denied screen ─────────────────────────────────────────────────
class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen({
    required this.currentRole,
    required this.allowedRoles,
  });
  final UserRole currentRole;
  final List<UserRole> allowedRoles;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.inkNavy800,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Access Denied',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This section is not available for your account type.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldCta,
                foregroundColor: AppColors.inkNavy800,
              ),
              onPressed: () => context.go('/'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// SESSION WATCHDOG
// Monitors session validity. If token is revoked server-side
// (e.g., account suspended), logs user out automatically.
// Wrap this around MaterialApp in main.dart.
// ════════════════════════════════════════════════════════════════
class SessionWatchdog extends ConsumerStatefulWidget {
  const SessionWatchdog({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SessionWatchdog> createState() => _SessionWatchdogState();
}

class _SessionWatchdogState extends ConsumerState<SessionWatchdog>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-validate session when app comes back from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateSession();
    }
  }

  Future<void> _validateSession() async {
    final session = ref.read(sessionProvider);
    if (session == null) return;

    try {
      // TODO: call GET /auth/me on the Dart backend to verify the token is
      // still valid server-side (401/403 → sign out), so a suspended
      // account doesn't stay logged in until its local token expires.
    } catch (_) {
      ref.read(supabaseAuthNotifierProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
