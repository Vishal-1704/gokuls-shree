import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';

/// Initialize Supabase - call this in main() before runApp()
Future<void> initializeSupabase() async {
  if (!EnvConfig.isSupabaseConfigured) {
    throw Exception('Supabase credentials not configured in .env file');
  }

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );
}

/// Get Supabase client instance
SupabaseClient get supabase => Supabase.instance.client;

/// Supabase service for all database operations
class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  // ============================================
  // COURSES & PROGRAMS
  // ============================================
  Future<List<Map<String, dynamic>>> getPrograms() async {
    final response = await _client
        .from('programs')
        .select()
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getCourses({String? category}) async {
    var query = _client
        .from('courses')
        .select('*, programs(name)')
        .eq('is_active', true);

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final response = await query.order('title');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getCourseById(int id) async {
    final response = await _client
        .from('courses')
        .select('*, programs(name), subjects(*)')
        .eq('id', id)
        .single();
    return response;
  }

  Future<List<String>> getCourseCategories() async {
    final response = await _client
        .from('courses')
        .select('category')
        .eq('is_active', true);

    final categories = <String>{};
    for (final row in response) {
      if (row['category'] != null) {
        categories.add(row['category'] as String);
      }
    }
    return categories.toList()..sort();
  }

  Future<List<Map<String, dynamic>>> getSubjects({int? courseId}) async {
    var query = _client.from('subjects').select('*, courses(title)');
    if (courseId != null) {
      query = query.eq('course_id', courseId);
    }
    final response = await query.order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // NOTICES
  // ============================================
  Future<List<Map<String, dynamic>>> getNotices({int? limit}) async {
    var query = _client
        .from('notices')
        .select()
        .eq('is_active', true)
        .order('published_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // DOWNLOADS
  // ============================================
  Future<List<Map<String, dynamic>>> getDownloads() async {
    final response = await _client
        .from('downloads')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> incrementDownloadCount(int id) async {
    await _client.rpc('increment_download_count', params: {'row_id': id});
  }

  // ============================================
  // STUDENTS
  // ============================================
  Future<Map<String, dynamic>?> getStudentByRegNo(String regNo) async {
    final response = await _client
        .from('students')
        .select('*, courses(title)')
        .eq('registration_number', regNo)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getStudentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('students')
        .select('*, courses(title)')
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<List<Map<String, dynamic>>> getStudentAttendance(
    dynamic studentId,
  ) async {
    if (studentId == null) return [];

    try {
      final response = await _client
          .from('student_attendance')
          .select()
          .eq('student_id', studentId)
          .order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      // Backward compatibility: some schemas only have attendance(enrollment_id,...)
      // or temporary data mismatch; return empty and let UI show fallback state.
      return [];
    }
  }

  // ============================================
  // SMART ATTENDANCE (QR + BLE)
  // ============================================
  Future<Map<String, dynamic>> startQrAttendanceSession({
    required String scopeType,
    String? studentId,
    int? courseId,
    int? batchId,
    int? branchId,
    required DateTime startsAt,
    required DateTime expiresAt,
    required String qrNonce,
    required String qrPayloadHash,
  }) async {
    final payload = {
      'scope_type': scopeType,
      'scope_student_id': studentId,
      'scope_course_id': courseId,
      'scope_batch_id': batchId,
      'scope_branch_id': branchId,
      'starts_at': startsAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'qr_nonce': qrNonce,
      'qr_payload_hash': qrPayloadHash,
      'created_by': _client.auth.currentUser?.id,
      'is_active': true,
    };

    final response = await _client
        .from('attendance_qr_sessions')
        .insert(payload)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<void> submitBleProximityEvent({
    required String qrSessionId,
    required String teacherDeviceId,
    required String studentDeviceId,
    required String studentId,
    int? rssi,
    double? estimatedDistanceM,
    bool isValid = false,
    String? reason,
  }) async {
    await _client.from('attendance_ble_events').insert({
      'qr_session_id': qrSessionId,
      'teacher_device_id': teacherDeviceId,
      'student_device_id': studentDeviceId,
      'student_id': studentId,
      'rssi': rssi,
      'estimated_distance_m': estimatedDistanceM,
      'is_valid': isValid,
      'reason': reason,
    });
  }

  Future<Map<String, dynamic>> markSmartAttendance({
    required String studentId,
    required String source,
    required String status,
    String? qrSessionId,
    String? teacherDeviceId,
    String? studentDeviceId,
    int? bleRssi,
    double? estimatedDistanceM,
    double confidenceScore = 0,
    String? rejectionReason,
    Map<String, dynamic>? meta,
  }) async {
    final response = await _client
        .from('attendance_events')
        .insert({
          'qr_session_id': qrSessionId,
          'student_id': studentId,
          'source': source,
          'status': status,
          'teacher_device_id': teacherDeviceId,
          'student_device_id': studentDeviceId,
          'ble_rssi': bleRssi,
          'estimated_distance_m': estimatedDistanceM,
          'confidence_score': confidenceScore,
          'rejection_reason': rejectionReason,
          'meta': meta ?? <String, dynamic>{},
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  // ============================================
  // ENROLLMENTS
  // ============================================
  Future<List<Map<String, dynamic>>> getMyEnrollments() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('student_enrollments')
        .select('*, courses(title, code)')
        .eq('student_id', userId)
        .order('enrolled_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // MARKSHEETS & CERTIFICATES
  // ============================================
  Future<List<Map<String, dynamic>>> getMyMarksheets() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('marksheets')
        .select('*, marksheet_details(*)')
        .eq('student_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMyCertificates() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('certificates')
        .select()
        .eq('student_id', userId)
        .order('issue_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // FEE PAYMENTS
  // ============================================
  Future<List<Map<String, dynamic>>> getMyFeePayments() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('fee_payments')
        .select()
        .eq('student_id', userId)
        .order('due_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMyPaymentTransactions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('payment_transactions')
        .select()
        .eq('student_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get pending fee amount for current student
  Future<double> getPendingFees() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('fee_payments')
        .select('amount, amount_paid')
        .eq('student_id', userId)
        .eq('status', 'pending');

    double pending = 0;
    for (final row in response) {
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;
      final paid = (row['amount_paid'] as num?)?.toDouble() ?? 0;
      pending += (amount - paid);
    }
    return pending;
  }

  // ============================================
  // BRANCHES (Admin)
  // ============================================
  Future<List<Map<String, dynamic>>> getBranches() async {
    final response = await _client.from('branches').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Public centre finder query used by website/app Phase 2.
  Future<List<Map<String, dynamic>>> findBranches({
    String? search,
    String? district,
  }) async {
    var query = _client.from('branches').select().eq('status', true);

    if (district != null && district.trim().isNotEmpty) {
      query = query.ilike('district', '%${district.trim()}%');
    }

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim();
      query = query.or('name.ilike.%$q%,code.ilike.%$q%,address.ilike.%$q%');
    }

    final response = await query.order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Public enquiry submission. Supports both `enquiries` and legacy `contacts` tables.
  Future<bool> submitEnquiry({
    required String name,
    required String mobile,
    required String message,
    String? email,
    String? district,
  }) async {
    final payload = {
      'name': name.trim(),
      'mobile': mobile.trim(),
      'message': message.trim(),
      'email': email?.trim().isEmpty == true ? null : email?.trim(),
      'district': district?.trim().isEmpty == true ? null : district?.trim(),
      'source': 'mobile_app',
      'status': 'new',
    };

    try {
      await _client.from('enquiries').insert(payload);
      return true;
    } catch (_) {
      try {
        await _client.from('contacts').insert(payload);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  // ============================================
  // EMPLOYEES (Admin)
  // ============================================
  Future<List<Map<String, dynamic>>> getEmployees({int? branchId}) async {
    var query = _client
        .from('employees')
        .select('*, profiles(full_name, mobile)');
    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // AUTH (using Supabase Auth)
  // ============================================
  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  // ============================================
  // EXAM RESULTS
  // ============================================
  Future<List<Map<String, dynamic>>> getMyExamResults() async {
    final student = await getStudentProfile();
    if (student == null) return [];

    final studentId = student['id'];

    final response = await _client
        .from('exam_results')
        .select('''
          *,
          exam_sessions!inner (
            ended_at,
            paper_sets (
              name
            )
          )
        ''')
        .eq('exam_sessions.student_id', studentId)
        .order('calculated_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get active paper sets for dashboard exam schedule fallback.
  Future<List<Map<String, dynamic>>> getActivePaperSets({int limit = 5}) async {
    final response = await _client
        .from('paper_sets')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}

// ============================================
// RIVERPOD PROVIDERS
// ============================================
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return supabase;
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(ref.watch(supabaseClientProvider));
});

// Data providers
final supabaseCoursesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((
      ref,
      category,
    ) async {
      final service = ref.watch(supabaseServiceProvider);
      return service.getCourses(category: category);
    });

final supabaseNoticesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getNotices(limit: 10);
});

final supabaseDownloadsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getDownloads();
});

final supabaseProgramsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getPrograms();
});

final myEnrollmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getMyEnrollments();
});

final myMarksheetsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getMyMarksheets();
});

final myCertificatesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getMyCertificates();
});

final myFeePaymentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getMyFeePayments();
});

// ============================================
// EXAM RESULTS
// ============================================
final pendingFeesProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getPendingFees();
});

final branchesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getBranches();
});
