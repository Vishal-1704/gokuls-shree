import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/app.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';
import 'package:gokul_shree_app/src/core/models/user_session.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';

class MockSessionNotifier extends SessionNotifier {
  @override
  UserSession? build() {
    return null; // Guest user
  }
}

class MockSupabaseAuthNotifier extends ChangeNotifier implements SupabaseAuthNotifier {
  @override
  SupabaseAuthState state = AuthUnauthenticated();

  @override
  String? get currentRole => null;

  @override
  bool get isAdmin => false;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> sendEmailOtp({required String email}) async {}

  @override
  Future<void> verifyEmailOtp({required String email, required String token}) async {}

  @override
  Future<void> signInWithMobile({required String identifier, required String password}) async {}

  @override
  Future<void> adminLogin({required String loginId, required String password}) async {}

  }) async {}
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame, overriding providers to mock authentication
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => MockSessionNotifier()),
          supabaseAuthNotifierProvider.overrideWith((ref) => MockSupabaseAuthNotifier()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app builds without crashing.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
