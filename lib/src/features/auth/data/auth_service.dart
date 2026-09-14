import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gokul_shree_app/src/core/utils/registration_number_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';


class PhoneLookupResult {
  final bool isDuplicate;
  final bool isFound;
  final bool hasAuthAccount;
  final String? email;
  final String? role;

  PhoneLookupResult({
    required this.isDuplicate,
    required this.isFound,
    required this.hasAuthAccount,
    this.email,
    this.role,
  });
}

// ============================================
// AUTH STATES
// ============================================
sealed class SupabaseAuthState {}

class AuthInitial extends SupabaseAuthState {}

class AuthLoading extends SupabaseAuthState {}

class AuthAuthenticated extends SupabaseAuthState {
  final User user;
  final Map<String, dynamic>? profile;
  AuthAuthenticated(this.user, this.profile);

  // Backward compatibility alias
  Map<String, dynamic>? get studentData => profile;
}

class AuthError extends SupabaseAuthState {
  final String message;
  AuthError(this.message);
}

class AuthUnauthenticated extends SupabaseAuthState {}

// ============================================
// AUTH NOTIFIER (Real Supabase Auth)
// ============================================
class SupabaseAuthNotifier extends ChangeNotifier {
  SupabaseClient get _client => Supabase.instance.client;
  SupabaseAuthState _state = AuthInitial();

  SupabaseAuthState get state => _state;

  /// Set by registerWithPhone() — true if another unlinked students row
  /// shares the just-registered phone number under a different name. The
  /// login screen reads this once, right after a successful registration,
  /// to show a "contact your branch admin" notice.
  bool _hasPhoneNameConflict = false;
  bool get hasPhoneNameConflict => _hasPhoneNameConflict;

  SupabaseAuthNotifier() {
    _init();
  }

  void _init() {
    // Listen to auth changes
    _client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadProfile(session.user);
      } else if (event == AuthChangeEvent.signedOut) {
        _state = AuthUnauthenticated();
        notifyListeners();
      }
    });

    // Check if already logged in
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      _loadProfile(currentUser);
      _state = AuthLoading(); // Will be updated by _loadProfile
      notifyListeners();
    } else {
      _state = AuthInitial();
      notifyListeners();
    }
  }

  // Bumped each time _loadProfile is called; a call whose result lands after
  // a newer call has already updated _state is stale and must not overwrite
  // it — otherwise a slow, premature fetch (e.g. one fired by the
  // onAuthStateChange listener right after signUp(), before the profile row
  // is linked) can clobber the correct result from a later, authoritative
  // call with a null profile.
  int _loadProfileSeq = 0;

  /// Load user profile from profiles table
  Future<void> _loadProfile(User user) async {
    final seq = ++_loadProfileSeq;
    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('auth_uid', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (seq != _loadProfileSeq) return; // superseded by a newer call

      if (profile == null) {
        // A signed-in auth user with no matching profiles row is an
        // orphaned/incomplete account, never a legitimate "guest" — routing
        // it onward as AuthAuthenticated(user, null) sends it to a dead-end
        // public screen with no way to recover.
        _state = AuthError('Your account isn\'t fully set up. Please log in again or contact your branch admin.');
        try {
          await _client.auth.signOut();
        } catch (_) {}
      } else {
        _state = AuthAuthenticated(user, profile);
      }
    } catch (e) {
      if (seq != _loadProfileSeq) return;
      debugPrint('⚠️ Failed to load profile: $e');
      _state = AuthError('Network Error. Could not load profile. Please check your connection.');
      try {
        await _client.auth.signOut(); // Force clear bad session
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    _state = AuthLoading();
    notifyListeners();

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadProfile(response.user!);
      } else {
        _state = AuthError('Login failed. Invalid credentials.');
        notifyListeners();
      }
    } on AuthException catch (e) {
      _state = AuthError(e.message);
      notifyListeners();
    } catch (e) {
      _state = AuthError('Login failed: ${e.toString()}');
      notifyListeners();
    }
  }


  Future<PhoneLookupResult> checkPhoneNumber(String phone) async {
    try {
      final response = await _client
          .rpc('lookup_user_by_phone', params: {'p_phone': phone.trim()})
          .timeout(const Duration(seconds: 5));
      return PhoneLookupResult(
        isDuplicate: response['isDuplicate'] ?? false,
        isFound: response['isFound'] ?? false,
        hasAuthAccount: response['hasAuthAccount'] ?? false,
        email: response['email'],
        role: response['role'],
      );
    } on TimeoutException {
      debugPrint('Error: checkPhoneNumber timed out');
      throw Exception('Network timeout. Please check your internet connection.');
    } catch (e) {
      debugPrint('Error looking up phone number: $e');
      throw Exception('Failed to look up phone number. Please try again.');
    }
  }

  /// Checks the caller actually owns the legacy student record for this
  /// phone number before letting them anywhere near creating an account —
  /// previously anyone who knew a registered phone number could claim it
  /// with no proof at all. This must be verified before [registerWithPhone]
  /// is ever called.
  Future<bool> verifyLegacyPassword({
    required String phone,
    required String legacyPassword,
  }) async {
    try {
      final response = await _client
          .rpc('verify_legacy_password', params: {
            'p_phone': phone.trim(),
            'p_legacy_password': legacyPassword,
          })
          .timeout(const Duration(seconds: 5));
      return response['verified'] == true;
    } on TimeoutException {
      throw Exception('Network timeout. Please check your internet connection.');
    } catch (e) {
      debugPrint('Error verifying legacy password: $e');
      throw Exception('Could not verify your old password. Please try again.');
    }
  }

  /// Claims an existing (already legacy-password-verified) student record.
  /// [newPassword] is what the student will log in with going forward — if
  /// they chose to keep their old password instead of setting a new one,
  /// callers should pass the same value they already verified with
  /// [verifyLegacyPassword].
  Future<void> registerWithPhone({
    required String phone,
    required String email,
    required String password,
    required String name,
    required String legacyPassword,
  }) async {
    _state = AuthLoading();
    notifyListeners();

    try {
      // 1. Sign up the user (this creates auth.users)
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name.trim(),
          'display_name': name.trim(),
          'phone': phone.trim(),
        },
      );

      if (authResponse.user == null) {
        _state = AuthError('Registration failed.');
        notifyListeners();
        return;
      }

      // 2. Link auth user to entity — re-verifies the legacy password
      // server-side too, it isn't just trusting the earlier check.
      final linkResponse = await _client.rpc('link_auth_user_to_entity', params: {
        'p_phone': phone.trim(),
        'p_auth_uid': authResponse.user!.id,
        'p_email': email.trim(),
        'p_name': name.trim(),
        'p_legacy_password': legacyPassword,
      });

      if (linkResponse['success'] == true) {
        // Informational only — does not block registration. True means
        // another UNLINKED students row shares this phone number under a
        // different name (a known legacy pattern: a branch admin may have
        // entered a placeholder/their own number for a student who hadn't
        // given theirs yet). The UI surfaces this as "contact your branch
        // admin" rather than silently leaving that other row unexplained.
        try {
          _hasPhoneNameConflict = await _client.rpc('find_phone_name_conflict', params: {
            'p_phone': phone.trim(),
            'p_name': name.trim(),
          }) as bool? ?? false;
        } catch (_) {
          _hasPhoneNameConflict = false;
        }
        await _loadProfile(authResponse.user!);
      } else {
        _state = AuthError('Could not verify your record. Please contact your branch admin.');
        notifyListeners();
      }
    } on AuthException catch (e) {
      _state = AuthError(e.message);
      notifyListeners();
    } catch (e) {
      _state = AuthError('Registration error: ');
      notifyListeners();
    }
  }
  /// Send OTP to Email
  Future<void> sendEmailOtp({required String email}) async {
    _state = AuthLoading();
    notifyListeners();

    if (email.endsWith('@${EnvConfig.authEmailDomain}')) {
      _state = AuthError(
        'OTP login is not supported for mobile numbers (requires a configured SMS gateway). Please use Password login or enter a valid email address.',
      );
      notifyListeners();
      return;
    }

    try {
      await _client.auth.signInWithOtp(email: email);
      // OTP sent — state remains Unauthenticated but we signal success in UI
      _state = AuthUnauthenticated();
      notifyListeners();
    } on AuthException catch (e) {
      _state = AuthError(e.message);
      notifyListeners();
    } catch (e) {
      _state = AuthError('Failed to send OTP: ${e.toString()}');
      notifyListeners();
    }
  }

  /// Verify Email OTP
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    _state = AuthLoading();
    notifyListeners();

    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: token,
      );

      if (response.user != null) {
        await _loadProfile(response.user!);
      } else {
        _state = AuthError('OTP verification failed.');
        notifyListeners();
      }
    } on AuthException catch (e) {
      _state = AuthError(e.message);
      notifyListeners();
    } catch (e) {
      _state = AuthError('OTP verification failed: ${e.toString()}');
      notifyListeners();
    }
  }



  /// Admin login
  Future<void> adminLogin({
    required String loginId,
    required String password,
  }) async {
    // Admin uses normal email login — role is determined by profiles table
    await signIn(email: loginId, password: password);
  }

  /// Re-fetch the current user's profile row (e.g. after an admin approves
  /// a pending registration) without a full sign-out/sign-in cycle.
  Future<void> refreshProfile() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      await _loadProfile(user);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _state = AuthUnauthenticated();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Sign out error: $e');
      _state = AuthUnauthenticated();
      notifyListeners();
    }
  }

  /// Reset password
  Future<bool> resetPassword(String identifier) async {
    try {
      String? email;
      if (identifier.contains('@')) {
        email = identifier;
      } else {
        final lookup = await checkPhoneNumber(identifier);
        email = lookup.email;
      }
      
      if (email == null || email.isEmpty) {
        return false;
      }

      await _client.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sign up
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
  }) async {
    _state = AuthLoading();
    notifyListeners();

    try {
      final baseUrl = EnvConfig.apiBaseUrl.isNotEmpty
          ? EnvConfig.apiBaseUrl
          : 'http://localhost:3001/api/v1';

      debugPrint('Attempting student signup via backend for $email');

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));
      final response = await dio.post(
        '$baseUrl/auth/register',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'father_name': fatherName,
          'dob': dob,
          'address': address,
          'gender': gender,
          'course_id': courseId,
          'branch_id': branchId,
        },
      );

      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        debugPrint('Signup via backend successful.');
        _state = AuthUnauthenticated();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Backend registration unavailable ($e). Registering directly via Supabase Auth...');
    }

    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'phone': phone,
          'role': 'student',
        },
      );

      if (res.user != null) {
        _state = AuthUnauthenticated();
        notifyListeners();
        return true;
      } else {
        _state = AuthError('Failed to create account.');
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Supabase signup error: $e');
      _state = AuthError('Registration failed: ${e.toString()}');
      notifyListeners();
      return false;
    }
  }

  /// Update profile
  Future<void> updateProfile({
    required String name,
    required String phone,
    String? email,
  }) async {
    if (_state is! AuthAuthenticated) {
      throw Exception('User is not authenticated.');
    }

    final auth = _state as AuthAuthenticated;
    final now = DateTime.now();
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    final incomingEmail = email?.trim();

    final currentEmail =
        (auth.user.email ?? auth.profile?['email']?.toString() ?? '').trim();
    final targetEmail = (incomingEmail == null || incomingEmail.isEmpty)
        ? currentEmail
        : incomingEmail;

    final changedEmail =
        targetEmail.isNotEmpty &&
        targetEmail.toLowerCase() != currentEmail.toLowerCase();

    if (changedEmail) {
      if (!targetEmail.contains('@')) {
        throw Exception('Please enter a valid email address.');
      }

      final metadataTs = auth.user.userMetadata?['email_last_changed_at']
          ?.toString();
      final profileTs = auth.profile?['email_last_changed_at']?.toString();
      final parsedTs =
          DateTime.tryParse(metadataTs ?? '') ??
          DateTime.tryParse(profileTs ?? '');

      if (parsedTs != null) {
        final daysPassed = now.difference(parsedTs).inDays;
        if (daysPassed < 30) {
          final waitDays = 30 - daysPassed;
          throw Exception(
            'Email can be changed once in 30 days. Try again in $waitDays day(s).',
          );
        }
      }
    }

    final metadataUpdate = <String, dynamic>{'name': trimmedName};
    if (changedEmail) {
      metadataUpdate['email_last_changed_at'] = now.toIso8601String();
    }

    if (changedEmail) {
      await _client.auth.updateUser(
        UserAttributes(email: targetEmail, data: metadataUpdate),
      );
    } else {
      await _client.auth.updateUser(UserAttributes(data: metadataUpdate));
    }

    // profiles.id is its own generated UUID, NOT the same value as
    // auth.user.id (the Supabase auth uid) — using auth.user.id here
    // would upsert against a row whose id essentially never matches the
    // real profile, instead of updating it. auth.profile is already the
    // loaded profile row, so its own 'id' is the correct value.
    final resolvedProfileId = auth.profile?['id'];
    final profilePayload = <String, dynamic>{
      if (resolvedProfileId != null) 'id': resolvedProfileId,
      'full_name': trimmedName,
      'contact': trimmedPhone,
      'updated_at': now.toIso8601String(),
    };
    if (targetEmail.isNotEmpty) {
      profilePayload['email'] = targetEmail;
    }
    if (changedEmail) {
      profilePayload['email_last_changed_at'] = now.toIso8601String();
    }

    try {
      await _client.from('profiles').upsert(profilePayload);
    } catch (_) {
      if (profilePayload.containsKey('email_last_changed_at')) {
        final fallback = Map<String, dynamic>.from(profilePayload)
          ..remove('email_last_changed_at');
        await _client.from('profiles').upsert(fallback);
      }
    }

    final studentPayload = <String, dynamic>{
      'name': trimmedName,
      'contact': trimmedPhone,
    };
    if (targetEmail.isNotEmpty) {
      studentPayload['email'] = targetEmail;
    }
    if (changedEmail) {
      studentPayload['email_last_changed_at'] = now.toIso8601String();
    }

    // students.profile_id references profiles(id), not auth.user.id —
    // same fix as the profile upsert above. Updates every students row
    // for this profile (a profile can have more than one, one per course
    // enrollment), since name/contact are person-level fields correct to
    // update on all of them, not just whichever row a single-row query
    // used to pick.
    if (resolvedProfileId != null) {
      try {
        await _client
            .from('students')
            .update(studentPayload)
            .eq('profile_id', resolvedProfileId);
      } catch (_) {
        if (studentPayload.containsKey('email_last_changed_at')) {
          final fallback = Map<String, dynamic>.from(studentPayload)
            ..remove('email_last_changed_at');
          await _client
              .from('students')
              .update(fallback)
              .eq('profile_id', resolvedProfileId);
        }
      }
    }

    final refreshedUser = _client.auth.currentUser ?? auth.user;
    await _loadProfile(refreshedUser);
  }

  /// Get current user's role
  String? get currentRole {
    if (_state is AuthAuthenticated) {
      final auth = _state as AuthAuthenticated;
      final profileRole = auth.profile?['role']?.toString();
      final metadataRole = auth.user.userMetadata?['role']?.toString();
      final isAdminMeta = auth.user.userMetadata?['is_admin'] == true;
      final metadataIsAdminRole =
          metadataRole == 'super_admin' || metadataRole == 'branch_admin';

      if (metadataIsAdminRole) return metadataRole;
      if (isAdminMeta) return 'branch_admin';
      if (profileRole != null && profileRole.isNotEmpty) return profileRole;
      if (metadataRole != null && metadataRole.isNotEmpty) return metadataRole;
    }
    return null;
  }

  /// Check if current user is admin
  bool get isAdmin {
    final role = currentRole;
    return role == 'super_admin' || role == 'branch_admin';
  }
}

// ============================================
// PROVIDERS
// ============================================

// Use ChangeNotifierProvider so listeners rebuild on notifyListeners()
final supabaseAuthNotifierProvider =
    ChangeNotifierProvider<SupabaseAuthNotifier>((ref) {
      return SupabaseAuthNotifier();
    });

// Backward compatibility for consumers watching the state
final supabaseAuthProvider = Provider<SupabaseAuthState>((ref) {
  return ref.watch(supabaseAuthNotifierProvider).state;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(supabaseAuthProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

final userProfileProvider = Provider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(supabaseAuthProvider);
  if (authState is AuthAuthenticated) {
    return authState.profile;
  }
  return null;
});

final userRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(supabaseAuthProvider);
  if (authState is! AuthAuthenticated) return null;

  final profileRole = authState.profile?['role']?.toString();
  final metadataRole = authState.user.userMetadata?['role']?.toString();
  final isAdminMeta = authState.user.userMetadata?['is_admin'] == true;
  final metadataIsAdminRole =
      metadataRole == 'super_admin' || metadataRole == 'branch_admin';

  if (metadataIsAdminRole) return metadataRole;
  if (isAdminMeta) return 'branch_admin';
  if (profileRole != null && profileRole.isNotEmpty) return profileRole;
  if (metadataRole != null && metadataRole.isNotEmpty) return metadataRole;
  return null;
});

// Note: isAdminProvider is defined in admin_repository.dart
// It checks both profiles.role AND the admins table for comprehensive access control.

// Backward compatibility
final studentDataProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(userProfileProvider);
});
