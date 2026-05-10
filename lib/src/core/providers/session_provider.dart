// lib/src/core/providers/session_provider.dart
// Single source of truth for logged-in user across the entire app

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_session.dart';

// ── Session state notifier ────────────────────────────────────────────────
// ── Session state notifier (Notifier style for Riverpod 3.0 compatibility) ──────────────────
class SessionNotifier extends Notifier<UserSession?> {
  @override
  UserSession? build() => null;

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
