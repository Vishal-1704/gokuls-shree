import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gokul_shree_app/src/core/utils/registration_number_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';

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

  /// Load user profile from profiles table
  Future<void> _loadProfile(User user) async {
    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('auth_uid', user.id)
          .maybeSingle();

      _state = AuthAuthenticated(user, profile);
    } catch (e) {
      debugPrint('⚠️ Failed to load profile: $e');
      _state = AuthAuthenticated(user, null);
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

  Future<String?> _resolveEmailForIdentifier(String identifier) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty) return null;
    if (cleanId.contains('@')) return cleanId;

    try {
      final profile = await _client
          .from('profiles')
          .select('email')
          .eq('contact', cleanId)
          .maybeSingle();
      final profileEmail = profile?['email']?.toString().trim();
      if (profileEmail != null && profileEmail.isNotEmpty) {
        return profileEmail;
      }
    } catch (_) {}

    try {
      final student = await _client
          .from('students')
          .select('email')
          .eq('reg_no', cleanId)
          .maybeSingle();
      final studentEmail = student?['email']?.toString().trim();
      if (studentEmail != null && studentEmail.isNotEmpty) {
        return studentEmail;
      }
    } catch (_) {}

    return '$cleanId@gokulshree.local';
  }

  /// Send OTP to Email
  Future<void> sendEmailOtp({required String email}) async {
    _state = AuthLoading();
    notifyListeners();

    if (email.endsWith('@gokulshree.local')) {
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

  /// Sign in with mobile number (maps to internal email) or direct email
  Future<void> signInWithMobile({
    required String identifier,
    required String password,
  }) async {
    _state = AuthLoading();
    notifyListeners();

    try {
      final email = await _resolveEmailForIdentifier(identifier);
      if (email == null || email.isEmpty) {
        _state = AuthError(
          'Please enter a valid mobile number, registration number, or email.',
        );
        notifyListeners();
        return;
      }

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

  /// Admin login
  Future<void> adminLogin({
    required String loginId,
    required String password,
  }) async {
    // Admin uses normal email login — role is determined by profiles table
    await signIn(email: loginId, password: password);
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
  Future<bool> resetPassword(String email) async {
    try {
      final resolvedEmail = await _resolveEmailForIdentifier(email);
      if (resolvedEmail == null || resolvedEmail.isEmpty) {
        return false;
      }

      await _client.auth.resetPasswordForEmail(resolvedEmail);
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

      final response = await Dio().post(
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
        debugPrint('Signup via backend successful. Pending approval.');
        _state = AuthUnauthenticated();
        notifyListeners();
        return true;
      } else {
        _state = AuthError(body['error'] ?? 'Signup failed');
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['error'] ?? e.message ?? 'Signup connection error';
      debugPrint('DioException during signup: $errorMsg');
      _state = AuthError(errorMsg.toString());
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('General Exception during signup: $e');
      _state = AuthError('Signup failed: ${e.toString()}');
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

    final profilePayload = <String, dynamic>{
      'id': auth.user.id,
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

    try {
      await _client
          .from('students')
          .update(studentPayload)
          .eq('profile_id', auth.user.id);
    } catch (_) {
      if (studentPayload.containsKey('email_last_changed_at')) {
        final fallback = Map<String, dynamic>.from(studentPayload)
          ..remove('email_last_changed_at');
        await _client
            .from('students')
            .update(fallback)
            .eq('profile_id', auth.user.id);
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
