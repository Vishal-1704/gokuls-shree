// lib/src/core/providers/session_provider.dart
// Single source of truth for logged-in user across the entire app

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_session.dart';
import '../../features/auth/data/auth_service.dart';

// ── Session state notifier (Notifier style for Riverpod 3.0 compatibility) ──────────────────
class SessionNotifier extends Notifier<UserSession?> {
  @override
  UserSession? build() {
    final authState = ref.watch(supabaseAuthProvider);
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final profile = authState.profile;
      if (profile != null) {
        return UserSession(
          profileId: profile['id']?.toString() ?? '',
          authUid: user.id,
          role: UserRoleExt.fromString(profile['role']?.toString()),
          name: profile['full_name']?.toString() ?? profile['name']?.toString() ?? '',
          email: profile['email']?.toString() ?? user.email ?? '',
          branchId: profile['branch_id'] as int?,
          permissions: List<String>.from(profile['permissions'] ?? []),
        );
      }
    }
    return null;
  }

  void setSession(UserSession session) => state = session;
  void clearSession() => state = null;

  bool get isLoggedIn => state != null;
}

final sessionProvider =
    NotifierProvider<SessionNotifier, UserSession?>(() {
  return SessionNotifier();
});

// Convenience derived providers
final currentRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(sessionProvider)?.role ?? UserRole.guest;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider) != null;
});
