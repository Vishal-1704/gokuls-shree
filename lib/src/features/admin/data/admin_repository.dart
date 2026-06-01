import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:gokul_shree_app/src/core/config/env_config.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/utils/registration_number_generator.dart';
import 'package:gokul_shree_app/src/core/models/user_session.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';

/// Admin repository for CRUD operations on courses, notices, and students
/// Only accessible by admin users
class AdminRepository {
  Future<Map<String, dynamic>?> _currentAdminProfile() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return null;

    return supabase
        .from('profiles')
        .select('role, branch_id')
        .eq('auth_uid', currentUser.id)
        .maybeSingle();
  }

  Future<bool> _isSuperAdmin() async {
    final profile = await _currentAdminProfile();
    return profile?['role']?.toString() == 'super_admin';
  }

  Future<int?> _resolveBranchId({int? branchId}) async {
    if (branchId != null) return branchId;
    final profile = await _currentAdminProfile();
    return profile?['branch_id'] as int?;
  }

  // ===========================================
  // COURSES CRUD
  // ===========================================

  /// Get all courses
  Future<List<Map<String, dynamic>>> getCourses() async {
    final response = await supabase
        .from('courses')
        .select()
        .order('category')
        .order('title');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add a new course
  Future<Map<String, dynamic>> addCourse({
    required String title,
    required String category,
    required String duration,
    required String eligibility,
    String? imageUrl,
    String? description,
    int totalClasses = 0,
  }) async {
    final response = await supabase
        .from('courses')
        .insert({
          'title': title,
          'category': category,
          'duration': duration,
          'eligibility': eligibility,
          'image_url': imageUrl,
          'description': description,
          'total_classes': totalClasses,
          'is_active': true,
        })
        .select()
        .single();
    return response;
  }

  /// Update a course
  Future<Map<String, dynamic>> updateCourse({
    required String id,
    String? title,
    String? category,
    String? duration,
    String? eligibility,
    String? imageUrl,
    String? description,
    int? totalClasses,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (category != null) updates['category'] = category;
    if (duration != null) updates['duration'] = duration;
    if (eligibility != null) updates['eligibility'] = eligibility;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (description != null) updates['description'] = description;
    if (totalClasses != null) updates['total_classes'] = totalClasses;

    final response = await supabase
        .from('courses')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  /// Delete a course
  Future<void> deleteCourse(String id) async {
    await supabase.from('courses').delete().eq('id', id);
  }

  // ===========================================
  // NOTICES CRUD
  // ===========================================

  /// Get all notices
  Future<List<Map<String, dynamic>>> getNotices() async {
    final response = await supabase
        .from('notices')
        .select()
        .order('published_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add a new notice
  Future<Map<String, dynamic>> addNotice({
    required String title,
    required String category,
    String? content,
    String? link,
    String status = 'published',
    bool showAuthor = false,
  }) async {
    final user = supabase.auth.currentUser;
    final authorName = user?.userMetadata?['name'] ?? user?.email ?? 'Admin';

    final response = await supabase
        .from('notices')
        .insert({
          'title': title,
          'category': category,
          'content': content,
          'link': link,
          'status': status,
          'show_author': showAuthor,
          'author_name': authorName,
          'is_active': true,
          'published_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return response;
  }

  /// Update a notice
  Future<Map<String, dynamic>> updateNotice({
    required String id,
    String? title,
    String? category,
    String? content,
    String? link,
    String? status,
    bool? showAuthor,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (category != null) updates['category'] = category;
    if (content != null) updates['content'] = content;
    if (link != null) updates['link'] = link;
    if (status != null) updates['status'] = status;
    if (showAuthor != null) updates['show_author'] = showAuthor;

    final response = await supabase
        .from('notices')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  /// Delete a notice
  Future<void> deleteNotice(String id) async {
    await supabase.from('notices').delete().eq('id', id);
  }

  // ===========================================
  // STUDENTS CRUD
  // ===========================================

  /// Get all students
  Future<List<Map<String, dynamic>>> getStudents() async {
    final profile = await _currentAdminProfile();
    var query = supabase.from('students').select().order('name');
    final role = profile?['role']?.toString();
    final branchId = profile?['branch_id'] as int?;
    if (role != 'super_admin' && branchId != null) {
      query = query.eq('branch_id', branchId);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Paginated students list with server-side search and status filter.
  Future<List<Map<String, dynamic>>> getStudentsPaged({
    int page = 1,
    int pageSize = 20,
    String? query,
    String statusFilter = 'all',
    int? branchId,
  }) async {
    final start = (page - 1) * pageSize;
    final search = (query ?? '').trim().toLowerCase();
    final resolvedBranchId = await _resolveBranchId(branchId: branchId);
    final isSuperAdmin = await _isSuperAdmin();

    // Use correct column names matching the actual DB schema:
    // reg_no (not registration_number), contact (not phone), status (not is_active)
    var queryBuilder = supabase
        .from('students')
        .select('id, name, reg_no, contact, photo_url, status, courses(name, short_name), branches(name)')
        .order('name');

    if (!isSuperAdmin && resolvedBranchId != null) {
      queryBuilder = queryBuilder.eq('branch_id', resolvedBranchId);
    }

    final response = await queryBuilder;

    var rows = List<Map<String, dynamic>>.from(response);

    if (search.isNotEmpty) {
      rows = rows.where((row) {
        final name = (row['name'] ?? '').toString().toLowerCase();
        final reg = (row['reg_no'] ?? '').toString().toLowerCase();
        final phone = (row['contact'] ?? '').toString().toLowerCase();
        return name.contains(search) ||
            reg.contains(search) ||
            phone.contains(search);
      }).toList();
    }

    // status: 0=Pending, 1=Active, 2=Inactive
    if (statusFilter == 'active') {
      rows = rows.where((row) => row['status'] == 1).toList();
    } else if (statusFilter == 'inactive') {
      rows = rows.where((row) => (row['status'] ?? 0) != 1).toList();
    } else if (statusFilter == 'pending') {
      rows = rows.where((row) => row['status'] == 0).toList();
    }

    if (start >= rows.length) return [];

    final end = (start + pageSize) > rows.length ? rows.length : (start + pageSize);
    rows = rows.sublist(start, end);

    return rows
        .map(
          (row) => <String, dynamic>{
            ...row,
            // Normalize for UI: expose friendly status label
            'status_label': row['status'] == 1 ? 'Active' : row['status'] == 0 ? 'Pending' : 'Inactive',
          },
        )
        .toList();
  }

  /// Add a new student
  Future<Map<String, dynamic>> addStudent({
    required String name,
    required String email,
    String? registrationNumber,
    String? phone,
    String? courseId,
    String? photoUrl,
    int? branchId,
  }) async {
    final resolvedRegistrationNumber =
        registrationNumber != null && registrationNumber.trim().isNotEmpty
        ? registrationNumber.trim()
        : await RegistrationNumberGenerator.generateNext(supabase);

    var status = 0;
    final profile = await _currentAdminProfile();
    final isSuperAdmin = profile?['role']?.toString() == 'super_admin';
    final resolvedBranchId = await _resolveBranchId(branchId: branchId);
    if (isSuperAdmin) {
      status = 1;
    }

    final payload = <String, dynamic>{
      'name': name,
      'email': email,
      'reg_no': resolvedRegistrationNumber,
      'contact': phone,
      'course_id': courseId,
      'photo_url': photoUrl,
      'status': status,
    };
    if (resolvedBranchId != null) {
      payload['branch_id'] = resolvedBranchId;
    }

    final response = await supabase
        .from('students')
        .insert(payload)
        .select()
        .single();
    return response;
  }

  /// Add student with optional admission metadata.
  /// Falls back to core fields if some optional columns are not present.
  Future<Map<String, dynamic>> addStudentAdmission({
    required String name,
    required String email,
    String? registrationNumber,
    String? phone,
    String? courseId,
    String? guardianName,
    String? address,
    String? dateOfBirth,
    int? branchId,
  }) async {
    final resolvedRegistrationNumber =
        registrationNumber != null && registrationNumber.trim().isNotEmpty
        ? registrationNumber.trim()
        : await RegistrationNumberGenerator.generateNext(supabase);

    var status = 0;
    final profile = await _currentAdminProfile();
    final isSuperAdmin = profile?['role']?.toString() == 'super_admin';
    final resolvedBranchId = await _resolveBranchId(branchId: branchId);
    if (isSuperAdmin) {
      status = 1;
    }

    final fullPayload = <String, dynamic>{
      'name': name,
      'email': email,
      'reg_no': resolvedRegistrationNumber,
      'contact': phone,
      'course_id': courseId,
      'guardian_name': guardianName,
      'address': address,
      'date_of_birth': dateOfBirth,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (resolvedBranchId != null) {
      fullPayload['branch_id'] = resolvedBranchId;
    }

    try {
      final response = await supabase
          .from('students')
          .insert(fullPayload)
          .select()
          .single();
      return response;
    } catch (_) {
      final fallbackPayload = <String, dynamic>{
        'name': name,
        'email': email,
        'reg_no': resolvedRegistrationNumber,
        'contact': phone,
        'course_id': courseId,
        'status': status,
      };
      if (resolvedBranchId != null) {
        fallbackPayload['branch_id'] = resolvedBranchId;
      }

      final response = await supabase
          .from('students')
          .insert(fallbackPayload)
          .select()
          .single();
      return response;
    }
  }

  /// Update a student
  Future<Map<String, dynamic>> updateStudent({
    required String id,
    String? name,
    String? email,
    String? phone,
    String? courseId,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (phone != null) updates['contact'] = phone;
    if (courseId != null) updates['course_id'] = courseId;
    if (photoUrl != null) updates['photo_url'] = photoUrl;

    final response = await supabase
        .from('students')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  /// Delete a student
  Future<void> deleteStudent(String id) async {
    final profile = await _currentAdminProfile();
    final isSuperAdmin = profile?['role']?.toString() == 'super_admin';
    final branchId = profile?['branch_id'] as int?;

    final student = await supabase
        .from('students')
        .select('id, branch_id, profile_id')
        .eq('id', id)
        .maybeSingle();

    if (student == null) {
      throw Exception('Student not found');
    }

    final studentBranchId = student['branch_id'] as int?;
    if (!isSuperAdmin && branchId != null && studentBranchId != branchId) {
      throw Exception('You do not have permission to delete this student.');
    }

    final studentId = student['id'];
    final profileId = student['profile_id']?.toString();

    await supabase.from('students').delete().eq('id', studentId);
    if (profileId != null && profileId.isNotEmpty) {
      await supabase.from('profiles').delete().eq('id', profileId);
    }
  }

  // ===========================================
  // DOWNLOADS CRUD
  // ===========================================

  /// Get all downloads
  Future<List<Map<String, dynamic>>> getDownloads() async {
    final response = await supabase.from('downloads').select().order('title');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add a new download
  Future<Map<String, dynamic>> addDownload({
    required String title,
    required String category,
    required String url,
    String? description,
  }) async {
    final response = await supabase
        .from('downloads')
        .insert({
          'title': title,
          'category': category,
          'url': url,
          'description': description,
        })
        .select()
        .single();
    return response;
  }

  /// Delete a download
  Future<void> deleteDownload(String id) async {
    await supabase.from('downloads').delete().eq('id', id);
  }
  // ===========================================
  // DASHBOARD STATS (MOCK)
  // ===========================================

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final totalStudentsList = await supabase
          .from('students')
          .select('id')
          .eq('status', 1);
      final totalStudents = totalStudentsList.length;

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final paymentsToday = await supabase
          .from('fee_payments')
          .select('amount_paid')
          .gte('created_at', '${today}T00:00:00')
          .lte('created_at', '${today}T23:59:59');
      double todaysCollection = 0;
      for (final p in paymentsToday) {
        todaysCollection += (p['amount_paid'] as num?)?.toDouble() ?? 0;
      }

      int pendingEnquiries = 0;
      try {
        final pendingEnquiriesList = await supabase
            .from('enquiries')
            .select('id')
            .eq('status', 'new');
        pendingEnquiries = pendingEnquiriesList.length;
      } catch (_) {
        try {
          final pendingList = await supabase
              .from('contacts')
              .select('id')
              .eq('status', 'new');
          pendingEnquiries = pendingList.length;
        } catch (_) {}
      }

      return {
        'todays_collection': todaysCollection > 0 ? todaysCollection : 45200,
        'collection_growth': 12,
        'present_students': (totalStudents * 0.94).round(),
        'total_students': totalStudents > 0 ? totalStudents : 900,
        'attendance_rate': 94,
        'pending_enquiries': pendingEnquiries > 0 ? pendingEnquiries : 12,
        'new_enquiries': pendingEnquiries > 0,
      };
    } catch (_) {
      return {
        'todays_collection': 45200,
        'collection_growth': 12,
        'present_students': 845,
        'total_students': 900,
        'attendance_rate': 94,
        'pending_enquiries': 12,
        'new_enquiries': true,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    return [
      {
        'name': 'Aarav Patel',
        'class': 'Class 5B',
        'type': 'Tuition Fee',
        'amount': 12000,
        'time': '10:30 AM',
        'photo_url':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCWSHhaZ8O90DgfOHsoFGzrX-t82eyc7IsSYBnqzAh4bPyFls3e-a2uTz_LDK-Wu1Quv0XONkR8mwemYReXNYLlOdi7Lak2pM-ySIxoPknF39kk-U319dmDtlZWYyyfWkSWJ_GWgsGWVebOqtbw32q2CiL056gEziBCwTUu2HVwBBxaYt2wUDcYj_gAWAyWC4Tm5B_0cgaIrvTARcgIEbDCP4Yq25YYDrQ7TFfILqiNkznnnQ0fRxycR0mxSJL6cVQvQdVibR3IGPY',
      },
      {
        'name': 'Sneha Gupta',
        'class': 'Class 10A',
        'type': 'Exam Fee',
        'amount': 8500,
        'time': '10:15 AM',
        'photo_url':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAa-_STepkMgxKOk8C1Kck9qLnvH49pk-lZL8lvTQmgLXFjQbhxs5U9jMmqxCLmzy_kT-C1TLlc66apqhCZEbn9K244cm_FuvWavydcsj1VwwPewU2-vMxHbHs9E0T5Ja2aY8VAvqdKFcZ3SnKb3UUGP6DkKSlebBCzO-D_FRFziCKtxiPk6jhdLaMC5ORkNfxs_BYC4M9-mp2GI7QAohf0GJU_541fPpaS6f9sj2MTX-P443hJ6phW02IBTCUHECHalZdhx9r6YHM',
      },
      {
        'name': 'Rohan Mehta',
        'class': 'Class 8C',
        'type': 'Transport',
        'amount': 4200,
        'time': '09:45 AM',
        'photo_url':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDc0u7vdY0MIxsFHuXCYq2-EX8vfQVLhzXEFNKMtTnhACktdNada33DXOeg5AxOkMIWHwyj-ReN9jdgowDV7fdDF3SNfyo1bP3Wns94uiEWlMb8iD5-oFg2MVK4iVLsTKtpUQetFV1i29l0Ko8stOLrtggBXg0CgMqNsAWAlY1drAV49xDZMYdUfCzisDJVMGVWHCWfDL7w4CxwnUnhoAjlKHJkJXnY_mNnVNdId0Mwk0zz-2TT3G--0iTz6g0WcB0KuJa-MFL1I-8',
      },
      {
        'name': 'Ananya Singh',
        'class': 'Class 6A',
        'type': 'Library Fine',
        'amount': 150,
        'time': '09:20 AM',
        'photo_url':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAIk1G3rT8x5eH0RtpP4SWG0qaRSOMwyiKPoafwxJVguElkFy-ucp5Yy0U_9-mTPLolGPRmKBDzwIY-6R6rBMjtHsGvOVHW0dCJh9h5CDcH6HaGvzkG65tgfi7oGPyA5TFmYKvuba4nbKkD_r5LEaVhdQR30TgD89RGz6oXxrM6_T-Jzadfo1qv-4XYmdtOL9loXI24TxL8nBhIpC9iRpDOR4Qlaia4tdyRoEjwoFPc4nf18Ax5eyF1geaJInKfNQW8Lhz7167tRPk',
      },
    ];
  }

  Future<void> collectFee({
    required String studentId,
    required double amount,
    required String date,
    required String paymentMode,
    String? remarks,
  }) async {
    final session = supabase.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final baseUrl = EnvConfig.apiBaseUrl.isNotEmpty 
        ? EnvConfig.apiBaseUrl 
        : 'http://localhost:3001/api/v1';

    final response = await Dio().post(
      '$baseUrl/fees',
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      }),
      data: {
        'student_id': int.tryParse(studentId) ?? studentId,
        'amount': amount,
        'net_pay': amount,
        'payment_date': date,
        'payment_mode': paymentMode,
        'description': remarks ?? 'Fee payment',
      },
    );

    final body = response.data as Map<String, dynamic>;
    if (response.statusCode != 201 && body['success'] != true) {
      throw Exception(body['error'] ?? 'Fee collection failed');
    }
  }

  // ===========================================
  // RESULTS ENTRY (Phase 2)
  // ===========================================

  Future<Map<String, dynamic>> addStudentResult({
    required String studentId,
    required String subjectName,
    required double marksObtained,
    required double totalMarks,
    String? examName,
    String? grade,
    String? notes,
  }) async {
    final payload = {
      'student_id': studentId,
      'subject_name': subjectName,
      'marks_obtained': marksObtained,
      'total_marks': totalMarks,
      'exam_name': examName,
      'grade': grade,
      'notes': notes,
      'calculated_at': DateTime.now().toIso8601String(),
    };

    final response = await supabase
        .from('exam_results')
        .insert(payload)
        .select()
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getStudentResults(String studentId) async {
    final response = await supabase
        .from('exam_results')
        .select()
        .eq('student_id', studentId)
        .order('calculated_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ===========================================
  // PHASE 2: DUES + MARKSHEET + STUDY MATERIAL
  // ===========================================

  Future<List<Map<String, dynamic>>> getDuesReport() async {
    final studentsResponse = await supabase
        .from('students')
        .select('id, name, reg_no');
    final paymentsResponse = await supabase
        .from('fee_payments')
        .select('student_id, amount, amount_paid, status, due_date')
        .order('due_date', ascending: true);

    final students = List<Map<String, dynamic>>.from(studentsResponse);
    final payments = List<Map<String, dynamic>>.from(paymentsResponse);
    final studentById = {for (final s in students) s['id'].toString(): s};

    final dues = <Map<String, dynamic>>[];
    for (final p in payments) {
      final total = (p['amount'] as num?)?.toDouble() ?? 0;
      final paid = (p['amount_paid'] as num?)?.toDouble() ?? 0;
      final dueAmount = total - paid;
      final status = (p['status'] ?? '').toString().toLowerCase();
      if (dueAmount <= 0 && status != 'pending' && status != 'overdue') {
        continue;
      }

      final student = studentById[p['student_id']?.toString() ?? ''];
      dues.add({
        'student_id': p['student_id'],
        'student_name': student?['name'] ?? 'Unknown',
        'registration_number': student?['reg_no'] ?? '-',
        'total_amount': total,
        'amount_paid': paid,
        'due_amount': dueAmount > 0 ? dueAmount : 0,
        'status': status.isEmpty ? 'pending' : status,
        'due_date': p['due_date'],
      });
    }

    dues.sort(
      (a, b) => ((b['due_amount'] as num?) ?? 0).compareTo(
        (a['due_amount'] as num?) ?? 0,
      ),
    );
    return dues;
  }

  Future<List<Map<String, dynamic>>> getStudentMarksheetData(
    String studentId,
  ) async {
    final response = await supabase
        .from('exam_results')
        .select('exam_name, subject_name, marks_obtained, total_marks, grade')
        .eq('student_id', studentId)
        .order('calculated_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> addStudyMaterial({
    required String title,
    required String url,
    String? description,
    String? program,
    String? subject,
  }) async {
    final fullPayload = {
      'title': title,
      'category': 'study_material',
      'url': url,
      'description': description,
      'program': program,
      'subject': subject,
      'is_active': true,
    };

    try {
      final response = await supabase
          .from('downloads')
          .insert(fullPayload)
          .select()
          .single();
      return response;
    } catch (_) {
      final fallbackPayload = {
        'title': title,
        'category': 'study_material',
        'url': url,
        'description': description,
      };
      final response = await supabase
          .from('downloads')
          .insert(fallbackPayload)
          .select()
          .single();
      return response;
    }
  }

  Future<List<Map<String, dynamic>>> getStudyMaterials() async {
    final response = await supabase
        .from('downloads')
        .select()
        .eq('category', 'study_material')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> generateAdmitCard({
    required String studentId,
    required String examId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    // Simulate generation
    return {
      'url':
          'https://www.gokulshreeschool.com/admit_cards/2025/REG$studentId.pdf',
      'generated_at': DateTime.now().toIso8601String(),
      'status': 'Generated',
    };
  }

  Future<Map<String, dynamic>> verifyAdmitCard(String qrCode) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Mock logic: Valid if starts with 'ADM'
    final isValid = qrCode.startsWith('ADM');
    return {
      'is_valid': isValid,
      'student_name': isValid ? 'Verified Student' : null,
      'exam_date': isValid ? '2025-03-15' : null,
      'message': isValid ? 'Entry Allowed' : 'Invalid Admit Card QR',
    };
  }

  // ===========================================
  // STAFF CRUD
  // ===========================================

  /// Get all staff members
  Future<List<Map<String, dynamic>>> getStaff() async {
    final response = await supabase.from('employees').select().order('name');
    return List<Map<String, dynamic>>.from(response).map((emp) => {
      ...emp,
      'phone': emp['contact'],
      'role': emp['designation'],
      'joining_date': emp['doj'],
    }).toList();
  }

  /// Add a new staff member
  Future<Map<String, dynamic>> addStaff({
    required String name,
    required String email,
    required String role,
    required String phone,
    String? photoUrl,
    String? joiningDate,
  }) async {
    final response = await supabase
        .from('employees')
        .insert({
          'name': name,
          'email': email,
          'designation': role,
          'contact': phone,
          'doj': joiningDate?.substring(0, 10) ?? DateTime.now().toIso8601String().substring(0, 10),
          'status': 1,
        })
        .select()
        .single();
    return {
      ...response,
      'phone': response['contact'],
      'role': response['designation'],
      'joining_date': response['doj'],
    };
  }

  /// Update a staff member
  Future<Map<String, dynamic>> updateStaff({
    required String id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (role != null) updates['designation'] = role;
    if (phone != null) updates['contact'] = phone;

    final response = await supabase
        .from('employees')
        .update(updates)
        .eq('id', int.tryParse(id) ?? id)
        .select()
        .single();
    return {
      ...response,
      'phone': response['contact'],
      'role': response['designation'],
      'joining_date': response['doj'],
    };
  }

  /// Delete a staff member
  Future<void> deleteStaff(String id) async {
    await supabase.from('employees').delete().eq('id', int.tryParse(id) ?? id);
  }

  // ===========================================
  // DOCUMENT APPROVALS (Super Admin Only Flow)
  // ===========================================

  /// Super Admin: Get all pending marksheets and certificates
  Future<Map<String, List<Map<String, dynamic>>>> getPendingDocuments() async {
    final results = await Future.wait([
      supabase
          .from('marksheets')
          .select('*, students(name, reg_no), courses(name)')
          .eq('status', 0)
          .order('created_at'),
      supabase
          .from('certificates')
          .select('*, students(name, reg_no), courses(name)')
          .eq('status', 0)
          .order('created_at'),
    ]);

    return {
      'marksheets': List<Map<String, dynamic>>.from(results[0]),
      'certificates': List<Map<String, dynamic>>.from(results[1]),
    };
  }

  /// Super Admin: Get pending student registrations (status=0)
  Future<List<Map<String, dynamic>>> getPendingStudents() async {
    final response = await supabase
        .from('students')
        .select('id, name, reg_no, contact, email, doj, courses(name, short_name), branches(name)')
        .eq('status', 0)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Super Admin: Approve a pending student registration
  Future<void> approveStudent(int studentId) async {
    // Super admin direct update — RLS policy allows super_admin to set status=1
    final response = await supabase
        .from('students')
        .update({'status': 1, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', studentId)
        .select();

    if (response.isEmpty) {
      throw Exception('Approval failed — student not found or permission denied.');
    }

    final student = await supabase
        .from('students')
        .select('profile_id')
        .eq('id', studentId)
        .maybeSingle();
    final profileId = student?['profile_id']?.toString();
    if (profileId != null && profileId.isNotEmpty) {
      await supabase
          .from('profiles')
          .update({'status': 1, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', profileId);
    }
  }

  /// Super Admin: Approve a marksheet or certificate via backend API.
  /// Uses direct Supabase update — protected by RLS (super_admin can update any).
  Future<void> approveDocument({
    required String type, // 'marksheet' | 'certificate'
    required int id,
  }) async {
    final table = type == 'marksheet' ? 'marksheets' : 'certificates';
    
    final response = await supabase
        .from(table)
        .update({
          'status': 1,
          'approved_at': DateTime.now().toIso8601String(),
          'approved_by': supabase.auth.currentUser?.id,
        })
        .eq('id', id)
        .select();

    if (response.isEmpty) {
      throw Exception('Approval failed. You might not have permission.');
    }
  }

  // ===========================================
  // BRANCH & FRANCHISE MANAGEMENT (New)
  // ===========================================

  /// Super Admin: Register a new Branch Admin
  Future<Map<String, dynamic>> registerBranchAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    final session = supabase.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final baseUrl = EnvConfig.apiBaseUrl.isNotEmpty 
        ? EnvConfig.apiBaseUrl 
        : 'http://localhost:3001/api/v1';
    
    final response = await Dio().post(
      '$baseUrl/auth/admin/register-branch-admin',
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      }),
      data: {'email': email, 'password': password, 'name': name},
    );

    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Registration failed');
    }
  }

  /// Register a new Teacher/Faculty
  Future<Map<String, dynamic>> registerTeacher({
    required String email,
    required String password,
    required String name,
    int? branchId,
  }) async {
    final session = supabase.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final baseUrl = EnvConfig.apiBaseUrl.isNotEmpty 
        ? EnvConfig.apiBaseUrl 
        : 'http://localhost:3001/api/v1';

    final payload = <String, dynamic>{
      'email': email,
      'password': password,
      'name': name,
    };
    if (branchId != null) {
      payload['branch_id'] = branchId;
    }

    final response = await Dio().post(
      '$baseUrl/auth/admin/register-teacher',
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      }),
      data: payload,
    );

    final body = response.data as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Teacher registration failed');
    }
  }

  /// Branch Admin: Setup or update franchise details
  Future<Map<String, dynamic>> setupFranchise({
    required String name,
    required String code,
    String? ownerName,
    String? phone,
    String? address,
  }) async {
    final response = await supabase
        .from('branches')
        .upsert({
          'admin_id': supabase.auth.currentUser?.id,
          'name': name,
          'code': code,
          'owner_name': ownerName,
          'contact_phone': phone,
          'address': address,
        }, onConflict: 'admin_id')
        .select()
        .single();
    
    // Update local profile branch_id
    await supabase
        .from('profiles')
        .update({'branch_id': response['id']})
        .eq('auth_uid', supabase.auth.currentUser!.id);

    return response;
  }

  /// Get current branch details
  Future<Map<String, dynamic>?> getMyBranch() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final response = await supabase
        .from('branches')
        .select()
        .eq('admin_id', user.id)
        .maybeSingle();
    return response;
  }
}

/// Provider for AdminRepository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final adminStudentsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(adminRepositoryProvider).getStudents(),
);

final adminCoursesProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(adminRepositoryProvider).getCourses(),
);

final adminStudentResultsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, studentId) {
      return ref.watch(adminRepositoryProvider).getStudentResults(studentId);
    });

final adminDuesReportProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(adminRepositoryProvider).getDuesReport(),
);

final studyMaterialsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(adminRepositoryProvider).getStudyMaterials(),
);

/// Check if current user is admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return false;
  return session.role == UserRole.superAdmin || session.role == UserRole.branchAdmin;
});
