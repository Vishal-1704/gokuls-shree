import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/features/auth/data/auth_service.dart';
import 'package:gokul_shree_app/src/features/auth/presentation/login_screen.dart';

class MockSupabaseAuthNotifier extends ChangeNotifier implements SupabaseAuthNotifier {
  @override
  SupabaseAuthState state = AuthUnauthenticated();

  @override
  String? get currentRole => null;

  @override
  bool get isAdmin => false;

  @override
  bool get hasPhoneNameConflict => false;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> sendEmailOtp({required String email}) async {}

  @override
  Future<void> verifyEmailOtp({required String email, required String token}) async {}

  @override
  Future<void> adminLogin({required String loginId, required String password}) async {}

  @override
  Future<bool> resetPassword(String email) async => true;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> refreshProfile() async {}

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? fatherName,
    String? dob,
    String? address,
    String? gender,
    int? courseId,
    int? branchId,
  }) async => true;

  @override
  Future<void> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) async {}

  @override
  Future<PhoneLookupResult> checkPhoneNumber(String phone, {int retryCount = 1}) async {
    return PhoneLookupResult(
      isDuplicate: false,
      isFound: false,
      hasAuthAccount: false,
    );
  }

  @override
  Future<LegacyVerifyResult> verifyLegacyPassword({
    required String phone,
    required String legacyPassword,
    int retryCount = 1,
  }) async {
    return LegacyVerifyResult(verified: true);
  }

  @override
  Future<void> registerWithPhone({
    required String phone,
    required String email,
    required String password,
    required String legacyPassword,
    required String name,
  }) async {}
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final mockAuth = MockSupabaseAuthNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseAuthNotifierProvider.overrideWith((ref) => mockAuth),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify Login Screen renders correctly
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
