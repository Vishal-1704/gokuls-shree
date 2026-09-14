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
        .eq('reg_no', regNo)
        .maybeSingle();
    return response;
  }

  /// students.profile_id references profiles(id), not the Supabase auth
  /// uid — auth.currentUser.id has to be resolved to the profiles row
  /// first. Querying students.profile_id directly against the auth uid
  /// never matches, so every student saw the "pending approval" fallback
  /// regardless of actual approval status.
  ///
  /// A profile can have MORE than one students row (one per course
  /// enrollment) — see link_sibling_student_enrollments() in migration
  /// 20240301000024. Returns every enrollment id, not just one.
  Future<List<int>> _currentStudentIds() async {
    final authUid = _client.auth.currentUser?.id;
    if (authUid == null) return [];

    final profile = await _client
        .from('profiles')
        .select('id')
        .eq('auth_uid', authUid)
        .maybeSingle();
    final profileId = profile?['id'];
    if (profileId == null) return [];

    final students = await _client
        .from('students')
        .select('id')
        .eq('profile_id', profileId);
    return List<Map<String, dynamic>>.from(students)
        .map((s) => s['id'] as int)
        .toList();
  }

  /// Returns the student's identity (most recent enrollment's personal
  /// fields — name/DOB/photo/etc., same as before) plus an `enrollments`
  /// list covering every linked students row, and a combined `fee_summary`
  /// across all of them. A profile can have more than one enrollment (see
  /// link_sibling_student_enrollments, migration 20240301000024) — the
  /// identity card still shows one person, but enrollments/fees are now a
  /// combined list rather than assuming exactly one row.
  Future<Map<String, dynamic>?> getStudentProfile() async {
    final authUid = _client.auth.currentUser?.id;
    if (authUid == null) return null;

    final profile = await _client
        .from('profiles')
        .select('id')
        .eq('auth_uid', authUid)
        .maybeSingle();
    final profileId = profile?['id'];
    if (profileId == null) return null;

    final rows = await _client
        .from('students')
        .select('*, courses(name, category)')
        .eq('profile_id', profileId)
        .order('doj', ascending: false);
    final enrollments = List<Map<String, dynamic>>.from(rows);
    if (enrollments.isEmpty) return null;

    final response = Map<String, dynamic>.from(enrollments.first);
    response['enrollments'] = enrollments;

    // get_student_fee_summary returns {course_fee, paid_total, discount,
    // due_amount} for ONE enrollment (see 20240301000001_assessment_type_
    // and_fees.sql) — sum each field across every linked enrollment for
    // the combined total, and keep the per-enrollment summary too in case
    // a caller wants a single course's figures.
    double courseFee = 0, paidTotal = 0, discount = 0, dueAmount = 0;
    for (final e in enrollments) {
      try {
        final summary = await _client.rpc(
          'get_student_fee_summary',
          params: {'p_student_id': e['id']},
        );
        final map = summary is Map ? summary : <String, dynamic>{};
        e['fee_summary'] = map;
        courseFee += (map['course_fee'] as num?)?.toDouble() ?? 0;
        paidTotal += (map['paid_total'] as num?)?.toDouble() ?? 0;
        discount += (map['discount'] as num?)?.toDouble() ?? 0;
        dueAmount += (map['due_amount'] as num?)?.toDouble() ?? 0;
      } catch (_) {
        e['fee_summary'] = null;
      }
    }
    response['fee_summary'] = {
      'course_fee': courseFee,
      'paid_total': paidTotal,
      'discount': discount,
      'due_amount': dueAmount,
    };

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
  // Host: teacher/branch_admin/super_admin creates a short-lived session
  // scoped to a course, a branch, a single student, or an open
  // "classroom_ble" session with no restriction. Server-side (migration
  // 20240301000015) enforces role + branch scoping — this is a thin RPC
  // wrapper, not a raw table insert, since attendance_qr_sessions'
  // INSERT policy requires created_by = auth.uid() plus role checks that
  // are simplest to enforce inside the function itself.
  Future<Map<String, dynamic>> createAttendanceSession({
    required String scopeType,
    int? courseId,
    int? branchId,
    int? studentId,
    int? durationSeconds,
  }) async {
    final response = await _client.rpc(
      'create_attendance_session',
      params: {
        'p_scope_type': scopeType,
        'p_course_id': courseId,
        'p_branch_id': branchId,
        'p_student_id': studentId,
        'p_duration_seconds': durationSeconds,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> generatePayslip({
    required int employeeId,
    required int month,
    required int year,
  }) async {
    final response = await _client.rpc(
      'generate_payslip',
      params: {
        'p_employee_id': employeeId,
        'p_month': month,
        'p_year': year,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> endAttendanceSession(String sessionId) async {
    final response = await _client.rpc(
      'end_attendance_session',
      params: {'p_session_id': sessionId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  /// Agent: student scans the host's QR and (optionally) reports a BLE
  /// ambient reading. BLE is supplementary — a missing/weak reading never
  /// blocks the check-in server-side, it only affects confidence_score.
  Future<Map<String, dynamic>> checkinAttendance({
    required String sessionId,
    required String qrNonce,
    int? bleRssi,
    String? teacherDeviceId,
    String? studentDeviceId,
  }) async {
    final response = await _client.rpc(
      'checkin_attendance',
      params: {
        'p_session_id': sessionId,
        'p_qr_nonce': qrNonce,
        'p_ble_rssi': bleRssi,
        'p_teacher_device_id': teacherDeviceId,
        'p_student_device_id': studentDeviceId,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  // ============================================
  // ENROLLMENTS
  // ============================================
  /// student_enrollments.student_id is aliased FROM profile_id (one row
  /// per enrollment, all sharing the same profile_id) — filter by the
  /// resolved profile_id directly, not a students.id. No id-list helper
  /// needed here, unlike the methods below.
  Future<List<Map<String, dynamic>>> getMyEnrollments() async {
    final authUid = _client.auth.currentUser?.id;
    if (authUid == null) return [];

    final profile = await _client
        .from('profiles')
        .select('id')
        .eq('auth_uid', authUid)
        .maybeSingle();
    final profileId = profile?['id'];
    if (profileId == null) return [];

    final response = await _client
        .from('student_enrollments')
        .select('*, courses(title, code)')
        .eq('student_id', profileId)
        .order('enrolled_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // MARKSHEETS & CERTIFICATES
  // ============================================
  Future<List<Map<String, dynamic>>> getMyMarksheets() async {
    final studentIds = await _currentStudentIds();
    if (studentIds.isEmpty) return [];

    // marksheet_details doesn't exist anywhere in the schema — that join
    // threw a PostgREST error on every call, silently swallowed by the
    // Academics Hub's `orElse: () => 0`, so this always showed "0" there
    // even when the Documents screen (a different query, no bad join)
    // correctly showed real marksheets. Also filtering to status=1 here
    // to match the Documents screen's "only approved" behavior — without
    // it this count could include pending/unapproved marksheets the
    // Documents screen deliberately hides.
    final response = await _client
        .from('marksheets')
        .select()
        .inFilter('student_id', studentIds)
        .eq('status', 1)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMyCertificates() async {
    final studentIds = await _currentStudentIds();
    if (studentIds.isEmpty) return [];

    final response = await _client
        .from('certificates')
        .select()
        .inFilter('student_id', studentIds)
        .order('issue_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // FEE PAYMENTS
  // ============================================
  Future<List<Map<String, dynamic>>> getMyFeePayments() async {
    final studentIds = await _currentStudentIds();
    if (studentIds.isEmpty) return [];

    final response = await _client
        .from('fee_payments')
        .select()
        .inFilter('student_id', studentIds)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getMyPaymentTransactions() async {
    final studentIds = await _currentStudentIds();
    if (studentIds.isEmpty) return [];

    final response = await _client
        .from('payment_transactions')
        .select()
        .inFilter('student_id', studentIds)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get pending fee amount for current student, summed across every
  /// linked enrollment.
  Future<double> getPendingFees() async {
    final studentIds = await _currentStudentIds();
    if (studentIds.isEmpty) return 0;

    final response = await _client
        .from('fee_payments')
        .select('amount, amount_paid')
        .inFilter('student_id', studentIds)
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
  // ============================================
  // BRANCHES (Admin)
  // ============================================

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
    final studentIds = await _currentStudentIds();
    if (studentIds.isEmpty) return [];

    // exam_results.student_id is a plain column — no join needed. The old
    // query required an inner join through exam_sessions, which nothing
    // (manual entry or the MCQ module) ever populated, so it always
    // returned zero rows regardless of how many results actually existed.
    final response = await _client
        .from('exam_results')
        .select()
        .inFilter('student_id', studentIds)
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

  Future<List<Map<String, dynamic>>> getBranches() async {
    try {
      final response = await _client.from('branches').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      try {
        final response = await _client.from('iam.tenants').select();
        return List<Map<String, dynamic>>.from(response);
      } catch (_) {
        return [
          {'id': 1, 'name': 'Main Branch Campus'},
        ];
      }
    }
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

final departmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('departments')
      .select()
      .order('name');
  return List<Map<String, dynamic>>.from(response);
});
