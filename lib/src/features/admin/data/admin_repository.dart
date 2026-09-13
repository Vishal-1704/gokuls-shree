import 'package:flutter/foundation.dart';
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
        .select('id, role, branch_id')
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
    final bId = profile?['branch_id'] as int?;
    if (bId != null) return bId;

    try {
      final myBranch = await getMyBranch();
      if (myBranch != null && myBranch['id'] != null) {
        return (myBranch['id'] as num).toInt();
      }
    } catch (_) {}
    return null;
  }

  // ===========================================
  // COURSES CRUD
  // ===========================================

  /// Get all courses
  Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      final response = await supabase.from('courses').select();
      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) return list;
    } catch (_) {}

    try {
      final response = await supabase.from('academics.courses').select();
      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) return list;
    } catch (_) {}

    return [
      {'id': 1, 'name': 'DCA (Diploma in Computer Applications)'},
      {'id': 2, 'name': 'ADCA (Advanced Diploma in Computer Applications)'},
      {'id': 3, 'name': 'O-Level Computer Course'},
    ];
  }

  /// Add a new course
  Future<Map<String, dynamic>> addCourse({
    required String title,
    String? shortName,
    required String category,
    required String duration,
    double? fee,
    required String eligibility,
    String? imageUrl,
    String? description,
    int totalClasses = 0,
    int totalMarks = 100,
    int passMarks = 40,
    int theoryMarks = 60,
    int practicalMarks = 30,
    int internalMarks = 10,
    List<Map<String, dynamic>>? syllabus,
    List<String>? careerOpportunities,
  }) async {
    final payload = <String, dynamic>{
      'name': title,
      'category': category,
      'duration': duration,
      'eligibility': eligibility,
      'image_url': imageUrl,
      'description': description,
      'total_classes': totalClasses,
      'total_marks': totalMarks,
      'pass_marks': passMarks,
      'theory_marks': theoryMarks,
      'practical_marks': practicalMarks,
      'internal_marks': internalMarks,
      'status': 1,
    };
    if (shortName != null && shortName.isNotEmpty) payload['short_name'] = shortName;
    if (fee != null && fee > 0) payload['fee'] = fee;
    if (syllabus != null) payload['syllabus'] = syllabus;
    if (careerOpportunities != null) payload['career_opportunities'] = careerOpportunities;

    try {
      final response = await supabase
          .from('courses')
          .insert(payload)
          .select()
          .single();
      return response;
    } catch (e) {
      // Fallback for older database schemas without newly added columns
      final basicPayload = <String, dynamic>{
        'name': title,
        if (shortName != null && shortName.isNotEmpty) 'short_name': shortName,
        'category': category,
        'duration': duration,
        if (fee != null && fee > 0) 'fee': fee,
        'total_marks': totalMarks,
        'pass_marks': passMarks,
        if (description != null) 'description': description,
        'status': 1,
      };
      final response = await supabase
          .from('courses')
          .insert(basicPayload)
          .select()
          .single();
      return response;
    }
  }

  /// Update a course
  Future<Map<String, dynamic>> updateCourse({
    required String id,
    String? title,
    String? shortName,
    String? category,
    String? duration,
    double? fee,
    String? eligibility,
    String? imageUrl,
    String? description,
    int? totalClasses,
    int? totalMarks,
    int? passMarks,
    int? theoryMarks,
    int? practicalMarks,
    int? internalMarks,
    List<Map<String, dynamic>>? syllabus,
    List<String>? careerOpportunities,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['name'] = title;
    if (shortName != null) updates['short_name'] = shortName;
    if (category != null) updates['category'] = category;
    if (duration != null) updates['duration'] = duration;
    if (fee != null) updates['fee'] = fee;
    if (eligibility != null) updates['eligibility'] = eligibility;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (description != null) updates['description'] = description;
    if (totalClasses != null) updates['total_classes'] = totalClasses;
    if (totalMarks != null) updates['total_marks'] = totalMarks;
    if (passMarks != null) updates['pass_marks'] = passMarks;
    if (theoryMarks != null) updates['theory_marks'] = theoryMarks;
    if (practicalMarks != null) updates['practical_marks'] = practicalMarks;
    if (internalMarks != null) updates['internal_marks'] = internalMarks;
    if (syllabus != null) updates['syllabus'] = syllabus;
    if (careerOpportunities != null) updates['career_opportunities'] = careerOpportunities;

    try {
      final response = await supabase
          .from('courses')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      // Fallback without new jsonb columns if schema has not yet been migrated
      final basicUpdates = Map<String, dynamic>.from(updates)
        ..remove('eligibility')
        ..remove('total_classes')
        ..remove('theory_marks')
        ..remove('practical_marks')
        ..remove('internal_marks')
        ..remove('syllabus')
        ..remove('career_opportunities');
      final response = await supabase
          .from('courses')
          .update(basicUpdates)
          .eq('id', id)
          .select()
          .single();
      return response;
    }
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
    dynamic query = supabase.from('students').select('*, courses(name, short_name)');
    final role = profile?['role']?.toString();
    final branchId = profile?['branch_id'] as int?;
    if (role != 'super_admin' && branchId != null) {
      query = query.eq('branch_id', branchId);
    }
    query = query.order('name');

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get students enrolled in courses taught by a specific teacher
  Future<List<Map<String, dynamic>>> getStudentsForTeacher(String profileId) async {
    // 1. Get subjects for this teacher
    final teacherSubjects = await supabase
        .from('teacher_subjects')
        .select('subject_id')
        .eq('teacher_id', profileId);
        
    if (teacherSubjects.isEmpty) return [];
    
    final subjectIds = teacherSubjects.map((s) => s['subject_id'] as int).toList();
    
    // 2. Get course_ids from those subjects
    final subjectsResponse = await supabase
        .from('subjects')
        .select('course_id')
        .inFilter('id', subjectIds);
        
    if (subjectsResponse.isEmpty) return [];
    
    // Get unique course IDs
    final courseIds = subjectsResponse
        .map((s) => s['course_id'] as int?)
        .where((id) => id != null)
        .toSet()
        .toList();
        
    if (courseIds.isEmpty) return [];
    
    // 3. Get students in those courses
    final studentsResponse = await supabase
        .from('students')
        .select('*, courses(name, short_name)')
        .inFilter('course_id', courseIds)
        .order('name');
        
    return List<Map<String, dynamic>>.from(studentsResponse);
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
    dynamic queryBuilder = supabase
        .from('students')
        .select('id, name, reg_no, contact, photo_url, status, courses(name, short_name), branches(name)');

    if (!isSuperAdmin && resolvedBranchId != null) {
      queryBuilder = queryBuilder.eq('branch_id', resolvedBranchId);
    }

    queryBuilder = queryBuilder.order('name');

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
      rows = rows.where((row) => row['status'] == 2).toList();
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
    String? photoUrl,
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
      'photo_url': photoUrl,
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
        'photo_url': photoUrl,
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

  /// Upload a profile photo to Supabase Storage 'avatars' bucket.
  /// Throws on failure — callers must surface this to the user rather than
  /// silently submitting the form without a photo.
  Future<String> uploadProfilePhoto(String fileName, dynamic fileBytes) async {
    final currentUser = supabase.auth.currentUser;
    final userPrefix = currentUser != null ? '${currentUser.id}/' : '';
    final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final String path = '$userPrefix${DateTime.now().millisecondsSinceEpoch}_$cleanName';
    await supabase.storage.from('avatars').uploadBinary(
      path,
      fileBytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );
    return supabase.storage.from('avatars').getPublicUrl(path);
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
  /// Only super_admin may delete a student — branch_admin cannot, even for
  /// their own branch. Enforced server-side too (delete_student_full
  /// rejects any other caller); this check just fails fast with a clear
  /// message instead of a raw RPC error.
  Future<void> deleteStudent(String id) async {
    final isSuperAdmin = await _isSuperAdmin();
    if (!isSuperAdmin) {
      throw Exception('Only a super admin can delete a student.');
    }

    // Deletes the student row and its linked profile atomically (migration
    // 018) so a mid-way failure can't orphan one without the other.
    await supabase.rpc('delete_student_full', params: {'p_student_id': int.parse(id)});
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
      final profile = await _currentAdminProfile();
      final isSuperAdmin = profile?['role']?.toString() == 'super_admin';
      final branchId = profile?['branch_id'] as int?;

      dynamic studentsQuery = supabase.from('students').select('id').eq('status', 1);
      if (!isSuperAdmin && branchId != null) {
        studentsQuery = studentsQuery.eq('branch_id', branchId);
      }
      final totalStudentsList = await studentsQuery;
      final totalStudents = totalStudentsList.length;

      final today = DateTime.now().toIso8601String().substring(0, 10);

      dynamic paymentsQuery = supabase
          .from('fee_payments')
          .select('amount')
          .gte('created_at', '${today}T00:00:00')
          .lte('created_at', '${today}T23:59:59');
      if (!isSuperAdmin && branchId != null) {
        paymentsQuery = paymentsQuery.eq('branch_id', branchId);
      }
      final paymentsToday = await paymentsQuery;
      double todaysCollection = 0;
      for (final p in paymentsToday) {
        todaysCollection += (p['amount'] as num?)?.toDouble() ?? 0;
      }

      int presentStudents = 0;
      try {
        dynamic attendanceQuery = supabase
            .from('student_attendance')
            .select('id')
            .eq('attendance_date', today)
            .eq('status', 'P');
        if (!isSuperAdmin && branchId != null) {
          attendanceQuery = attendanceQuery.eq('branch_id', branchId);
        }
        final presentList = await attendanceQuery;
        presentStudents = presentList.length;
      } catch (_) {}
      final attendanceRate = totalStudents > 0
          ? ((presentStudents / totalStudents) * 100).round()
          : 0;

      int pendingEnquiries = 0;
      try {
        dynamic enquiriesQuery = supabase
            .from('enquiries')
            .select('id')
            .eq('status', 'new');
        if (!isSuperAdmin && branchId != null) {
          enquiriesQuery = enquiriesQuery.eq('branch_id', branchId);
        }
        final pendingEnquiriesList = await enquiriesQuery;
        pendingEnquiries = pendingEnquiriesList.length;
      } catch (_) {
        try {
          dynamic contactsQuery = supabase
              .from('contacts')
              .select('id')
              .eq('status', 'new');
          if (!isSuperAdmin && branchId != null) {
            contactsQuery = contactsQuery.eq('branch_id', branchId);
          }
          final pendingList = await contactsQuery;
          pendingEnquiries = pendingList.length;
        } catch (_) {}
      }

      return {
        'todays_collection': todaysCollection,
        'collection_growth': 0,
        'present_students': presentStudents,
        'total_students': totalStudents,
        'attendance_rate': attendanceRate,
        'pending_enquiries': pendingEnquiries,
        'new_enquiries': pendingEnquiries > 0,
      };
    } catch (e) {
      print("Error fetching dashboard stats: $e");
      return {
        'todays_collection': 0,
        'collection_growth': 0,
        'present_students': 0,
        'total_students': 0,
        'attendance_rate': 0,
        'pending_enquiries': 0,
        'new_enquiries': false,
      };
    }
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

    // Strategy 1: Direct Supabase insert into fee_payments
    try {
      final parsedStudentId = int.tryParse(studentId);
      dynamic studentQuery = supabase
          .from('students')
          .select('id, branch_id, course_id');

      if (parsedStudentId != null) {
        studentQuery = studentQuery.eq('id', parsedStudentId);
      } else {
        studentQuery = studentQuery.eq('reg_no', studentId);
      }

      final student = await studentQuery.maybeSingle();
      final int sId = student != null ? (student['id'] as int) : (parsedStudentId ?? 0);
      final int? branchId = student?['branch_id'] as int?;
      final int? courseId = student?['course_id'] as int?;

      final receiptNo = 'REC${DateTime.now().millisecondsSinceEpoch % 10000000}';
      final paymentDate = date.length >= 10 ? date.substring(0, 10) : date;

      final insertData = <String, dynamic>{
        'student_id': sId,
        'amount': amount,
        'net_pay': amount,
        'payment_date': paymentDate,
        'payment_mode': paymentMode.toUpperCase(),
        'description': remarks ?? 'Fee collection',
        'receipt_no': receiptNo,
      };
      if (branchId != null) insertData['branch_id'] = branchId;
      if (courseId != null) insertData['course_id'] = courseId;

      await supabase.from('fee_payments').insert(insertData);
      return;
    } catch (dbError) {
      // Strategy 2: Fallback to HTTP API if configured
      try {
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
      } catch (_) {
        throw Exception('Failed to record fee payment: $dbError');
      }
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

  /// Fetch all students in the branch with their computed fee payment status
  Future<List<Map<String, dynamic>>> getBranchStudentsWithFeeStatus({int? branchId}) async {
    final resolvedBranchId = await _resolveBranchId(branchId: branchId);
    final isSuperAdmin = await _isSuperAdmin();

    // 1. Fetch branch students with fee fields and course details
    dynamic studentQuery = supabase.from('students').select(
      'id, name, reg_no, contact, photo_url, branch_id, course_id, course_fee, reg_fee, admin_fee, discount, courses(name, fee)',
    );

    if (!isSuperAdmin && resolvedBranchId != null) {
      studentQuery = studentQuery.eq('branch_id', resolvedBranchId);
    }

    final studentsResponse = await studentQuery.order('name');
    final students = List<Map<String, dynamic>>.from(studentsResponse);

    if (students.isEmpty) return [];

    // 2. Fetch payments for all these students
    final studentIds = students.map((s) => s['id']).whereType<int>().toList();
    final paymentsMap = <int, double>{};

    if (studentIds.isNotEmpty) {
      try {
        final paymentsResponse = await supabase
            .from('fee_payments')
            .select('student_id, net_pay, amount')
            .inFilter('student_id', studentIds);

        for (final p in (paymentsResponse as List)) {
          final sid = p['student_id'] as int?;
          if (sid != null) {
            final net = (p['net_pay'] as num?)?.toDouble() ??
                (p['amount'] as num?)?.toDouble() ??
                0.0;
            paymentsMap[sid] = (paymentsMap[sid] ?? 0.0) + net;
          }
        }
      } catch (_) {}
    }

    // 3. Compute per-student status
    final result = <Map<String, dynamic>>[];
    for (final s in students) {
      final sId = s['id'] as int;
      final courseMap = s['courses'] as Map<String, dynamic>? ?? {};
      final courseName = courseMap['name']?.toString() ?? 'General Course';
      final courseDefaultFee = (courseMap['fee'] as num?)?.toDouble() ?? 0.0;

      final courseFee = (s['course_fee'] as num?)?.toDouble() ?? 0.0;
      final regFee = (s['reg_fee'] as num?)?.toDouble() ?? 0.0;
      final adminFee = (s['admin_fee'] as num?)?.toDouble() ?? 0.0;
      final discount = (s['discount'] as num?)?.toDouble() ?? 0.0;

      var totalFee = (courseFee + regFee + adminFee) - discount;
      if (totalFee <= 0 && courseDefaultFee > 0) {
        totalFee = courseDefaultFee;
      }

      final paidAmount = paymentsMap[sId] ?? 0.0;
      final dueAmount = totalFee > paidAmount ? (totalFee - paidAmount) : 0.0;
      final isFullyPaid = (totalFee > 0 && dueAmount <= 0) || (totalFee == 0 && paidAmount > 0);

      String status = 'unpaid';
      if (isFullyPaid) {
        status = 'paid';
      } else if (paidAmount > 0) {
        status = 'partial';
      }

      result.add({
        'id': sId,
        'name': s['name'] ?? 'Unknown',
        'reg_no': s['reg_no'] ?? '-',
        'contact': s['contact'] ?? '',
        'photo_url': s['photo_url'],
        'branch_id': s['branch_id'],
        'course_id': s['course_id'],
        'course_name': courseName,
        'total_fee': totalFee,
        'paid_amount': paidAmount,
        'due_amount': dueAmount,
        'is_fully_paid': isFullyPaid,
        'status': status,
      });
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getDuesReport() async {
    final studentsWithFee = await getBranchStudentsWithFeeStatus();
    final dues = <Map<String, dynamic>>[];

    for (final item in studentsWithFee) {
      final due = (item['due_amount'] as num?)?.toDouble() ?? 0.0;
      if (due > 0) {
        dues.add({
          'student_id': item['id'],
          'student_name': item['name'],
          'registration_number': item['reg_no'],
          'branch_id': item['branch_id'],
          'course_name': item['course_name'],
          'total_amount': item['total_fee'],
          'amount_paid': item['paid_amount'],
          'due_amount': due,
          'status': (item['paid_amount'] as num? ?? 0) > 0 ? 'partial' : 'pending',
          'photo_url': item['photo_url'],
        });
      }
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
    final parsedStudentId = int.tryParse(studentId);

    // 1. Check legacy/structured marksheets table first
    if (parsedStudentId != null) {
      try {
        final responseList = await supabase
            .from('marksheets')
            .select('marks')
            .eq('student_id', parsedStudentId)
            .order('created_at', ascending: false)
            .limit(1);

        if (responseList.isNotEmpty && responseList.first['marks'] != null) {
          final response = responseList.first;
          final marksData = response['marks'] as Map<String, dynamic>;
          final subjects = marksData['subjects'] as List<dynamic>? ?? [];

          if (subjects.isNotEmpty) {
            return subjects.map((sub) {
              final s = sub as Map<String, dynamic>;
              final obtained = (s['theory'] ?? 0) + (s['practical'] ?? 0) + (s['viva'] ?? 0);
              final total = s['total_marks'] ?? 100;

              final pct = (total > 0) ? (obtained / total) * 100 : 0;
              String grade = 'F';
              if (pct >= 90) grade = 'A+';
              else if (pct >= 80) grade = 'A';
              else if (pct >= 70) grade = 'B';
              else if (pct >= 60) grade = 'C';
              else if (pct >= 50) grade = 'D';

              return {
                'subject_name': s['name'] ?? 'Unknown',
                'marks_obtained': obtained,
                'total_marks': total,
                'grade': s['grade'] ?? grade,
              };
            }).toList();
          }
        }
      } catch (_) {}
    }

    // 2. Fallback: check exam_results table where manual entries & online exam scores are stored
    try {
      dynamic query = supabase
          .from('exam_results')
          .select('subject_name, exam_name, marks_obtained, total_marks, grade, score, total_questions');

      if (parsedStudentId != null) {
        query = query.eq('student_id', parsedStudentId);
      } else {
        query = query.eq('student_id', studentId);
      }

      final List<dynamic> results = await query.order('calculated_at', ascending: false);
      if (results.isNotEmpty) {
        return results.map((r) {
          final row = r as Map<String, dynamic>;
          final obtained = (row['marks_obtained'] as num?)?.toDouble() ??
              (row['score'] as num?)?.toDouble() ??
              0.0;
          final total = (row['total_marks'] as num?)?.toDouble() ??
              (row['total_questions'] as num?)?.toDouble() ??
              100.0;

          final pct = (total > 0) ? (obtained / total) * 100 : 0;
          String grade = row['grade']?.toString() ?? 'F';
          if (row['grade'] == null || row['grade'].toString().isEmpty) {
            if (pct >= 90) {
              grade = 'A+';
            } else if (pct >= 80) {
              grade = 'A';
            } else if (pct >= 70) {
              grade = 'B';
            } else if (pct >= 60) {
              grade = 'C';
            } else if (pct >= 50) {
              grade = 'D';
            }
          }

          return {
            'subject_name': row['subject_name'] ?? row['exam_name'] ?? 'General Examination',
            'marks_obtained': obtained,
            'total_marks': total,
            'grade': grade,
          };
        }).toList();
      }
    } catch (_) {}

    return [];
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
          '${EnvConfig.websiteBaseUrl.replaceFirst('://', '://www.')}/admit_cards/2025/REG$studentId.pdf',
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
  Future<List<Map<String, dynamic>>> getStaff({int? branchId}) async {
    final profile = await _currentAdminProfile();
    final role = profile?['role']?.toString();
    final adminBranchId = profile?['branch_id'] as int?;

    dynamic query = supabase.from('employees').select();
    
    // Explicit override (e.g. from Super Admin Branch Dashboard)
    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    } 
    // Otherwise fallback to admin's restricted branch
    else if (role != 'super_admin' && adminBranchId != null) {
      query = query.eq('branch_id', adminBranchId);
    }

    final response = await query.order('name');
    
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
    Map<String, dynamic>? hrDetails,
  }) async {
    final insertData = <String, dynamic>{
      'name': name,
      'email': email,
      'designation': role,
      'contact': phone,
      'doj': joiningDate?.substring(0, 10) ?? DateTime.now().toIso8601String().substring(0, 10),
      'status': 1,
    };
    if (hrDetails != null) {
      insertData.addAll(hrDetails);
    }
    final response = await supabase
        .from('employees')
        .insert(insertData)
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
    Map<String, dynamic>? hrDetails,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (role != null) updates['designation'] = role;
    if (phone != null) updates['contact'] = phone;
    if (hrDetails != null) updates.addAll(hrDetails);

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
  Future<Map<String, List<Map<String, dynamic>>>> getPendingDocuments({int? branchId}) async {
    dynamic marksheetQuery = supabase
        .from('marksheets')
        .select('*, students!inner(name, reg_no, branch_id), courses(name)')
        .eq('status', 0);
        
    dynamic certQuery = supabase
        .from('certificates')
        .select('*, students!inner(name, reg_no, branch_id), courses(name)')
        .eq('status', 0);

    if (branchId != null) {
      marksheetQuery = marksheetQuery.eq('students.branch_id', branchId);
      certQuery = certQuery.eq('students.branch_id', branchId);
    }

    final results = await Future.wait([
      marksheetQuery.order('created_at') as Future<dynamic>,
      certQuery.order('created_at') as Future<dynamic>,
    ]);

    return {
      'marksheets': List<Map<String, dynamic>>.from(results[0]),
      'certificates': List<Map<String, dynamic>>.from(results[1]),
    };
  }

  /// Super Admin: Get pending student registrations (status=0)
  Future<List<Map<String, dynamic>>> getPendingStudents({int? branchId}) async {
    dynamic query = supabase
        .from('students')
        .select('id, name, reg_no, contact, email, doj, courses(name, short_name), branches(name)')
        .eq('status', 0);
        
    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }
    
    final response = await query.order('created_at');
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

  /// Super Admin only: Reject a pending student registration (soft-deletes student &
  /// deactivates profile via delete_student_full which is enforced server-side too).
  Future<void> rejectStudent(int studentId) async {
    final isSuperAdmin = await _isSuperAdmin();
    if (!isSuperAdmin) {
      throw Exception('Only a super admin can reject and remove a student.');
    }

    final student = await supabase
        .from('students')
        .select('id')
        .eq('id', studentId)
        .maybeSingle();

    if (student == null) {
      throw Exception('Student not found');
    }

    // Soft-deletes the student (status=-2) and deactivates linked profile
    // atomically. Auth.users is also purged server-side.
    await supabase.rpc('delete_student_full', params: {'p_student_id': studentId});
  }

  Future<List<Map<String, dynamic>>> getPendingExperienceCerts({int? branchId}) async {
    dynamic query = supabase
        .from('experience_certificates')
        .select('*, employees!inner(name, designation, department, doj, branch_id)')
        .eq('status', 0);
        
    if (branchId != null) {
      query = query.eq('employees.branch_id', branchId);
    }

    final response = await query.order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Direct Supabase update (was a separate Dart-backend REST call, which
  /// bypassed Postgres entirely and never fired the signing trigger added
  /// in 20240301000021 — matching approveDocument()'s pattern below fixes
  /// that). approved_by is profiles(id), not the raw auth uid — resolved
  /// via _currentAdminProfile() rather than supabase.auth.currentUser?.id.
  Future<void> approveExperienceCert(int certId) async {
    final profile = await _currentAdminProfile();
    final response = await supabase
        .from('experience_certificates')
        .update({
          'status': 1,
          'approved_by': profile?['id'],
        })
        .eq('id', certId)
        .select();

    if (response.isEmpty) {
      throw Exception('Approval failed. You might not have permission.');
    }
  }

  /// branch_admin/super_admin: propose a CTC change — takes effect only
  /// once a super_admin approves it (employee_salary_revisions RLS
  /// enforces that transition server-side too, this isn't just a UI rule).
  Future<void> proposeSalaryRevision({
    required int employeeId,
    required double basicSalary,
    required double hra,
    required double da,
    required double otherAllowance,
    required int effectiveMonth,
    required int effectiveYear,
  }) async {
    final profile = await _currentAdminProfile();
    await supabase.from('employee_salary_revisions').insert({
      'employee_id': employeeId,
      'branch_id': profile?['branch_id'],
      'basic_salary': basicSalary,
      'hra': hra,
      'da': da,
      'other_allowance': otherAllowance,
      'effective_month': effectiveMonth,
      'effective_year': effectiveYear,
      'proposed_by': profile?['id'],
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSalaryRevisions({int? branchId}) async {
    dynamic query = supabase
        .from('employee_salary_revisions')
        .select('*, employees!inner(name, designation, department, branch_id)')
        .eq('status', 0);

    if (branchId != null) {
      query = query.eq('employees.branch_id', branchId);
    }

    final response = await query.order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// super_admin only — RLS's WITH CHECK also restricts the approved
  /// transition to super_admin, this isn't the only enforcement.
  Future<void> approveSalaryRevision(int revisionId) async {
    final profile = await _currentAdminProfile();
    final response = await supabase
        .from('employee_salary_revisions')
        .update({
          'status': 1,
          'approved_by': profile?['id'],
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', revisionId)
        .select();

    if (response.isEmpty) {
      throw Exception('Approval failed. You might not have permission.');
    }
  }

  Future<void> rejectSalaryRevision(int revisionId) async {
    final profile = await _currentAdminProfile();
    final response = await supabase
        .from('employee_salary_revisions')
        .update({
          'status': 2,
          'approved_by': profile?['id'],
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', revisionId)
        .select();

    if (response.isEmpty) {
      throw Exception('Rejection failed. You might not have permission.');
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

  /// Auto-generate next unique branch code (e.g. GS001, GS002, ...)
  Future<String> generateNextBranchCode() async {
    // 1. Try server-side RPC if migration was applied
    try {
      final res = await supabase.rpc('get_next_branch_code');
      if (res != null && res.toString().trim().isNotEmpty) {
        return res.toString().trim();
      }
    } catch (_) {}

    // 2. Client-side database scan fallback
    try {
      final rows = await supabase
          .from('branches')
          .select('code')
          .like('code', 'GS%')
          .limit(300);

      int maxNum = 0;
      final regex = RegExp(r'^GS(\d+)$', caseSensitive: false);
      for (final row in (rows as List)) {
        final code = (row['code'] ?? '').toString().trim();
        final match = regex.firstMatch(code);
        if (match != null) {
          final n = int.tryParse(match.group(1)!) ?? 0;
          if (n > maxNum) maxNum = n;
        }
      }
      final nextNum = maxNum + 1;
      return 'GS${nextNum.toString().padLeft(3, '0')}';
    } catch (_) {
      // 3. Fallback timestamp-based sequential code
      final rand = (DateTime.now().millisecondsSinceEpoch % 900) + 100;
      return 'GS$rand';
    }
  }

  /// Branch Admin: Setup or update franchise details.
  /// Uses Supabase directly (RPC + direct fallback) to avoid reliance on
  /// external containers that may return 503 or fail health checks.
  Future<Map<String, dynamic>> setupFranchise({
    required String name,
    required String code,
    String? ownerName,
    String? phone,
    String? address,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final cleanName = name.trim();
    final cleanCode = code.trim().toUpperCase();
    final cleanOwner = ownerName?.trim();
    final cleanPhone = phone?.trim();
    final cleanAddress = address?.trim();

    // ── Strategy 1: Server-side atomic RPC (Migration 20240301000008) ────────
    try {
      final rpcResult = await supabase.rpc('setup_franchise', params: {
        'p_name': cleanName,
        'p_code': cleanCode,
        'p_owner_name': cleanOwner,
        'p_contact': cleanPhone,
        'p_address': cleanAddress,
      });

      if (rpcResult is Map) {
        return Map<String, dynamic>.from(rpcResult);
      }
    } catch (rpcError) {
      // If RPC fails (e.g. not yet applied in DB), proceed to direct Supabase fallback
    }

    // ── Strategy 2: Direct Supabase Write Fallback ──────────────────────────
    try {
      final profile = await supabase
          .from('profiles')
          .select('id, branch_id')
          .eq('auth_uid', user.id)
          .maybeSingle();

      final profileId = profile?['id'] as String?;
      int? branchId = profile?['branch_id'] as int?;

      if (branchId == null) {
        // Try looking up branch by admin_id (could be profileId or user.id)
        if (profileId != null) {
          final existingByAdmin = await supabase
              .from('branches')
              .select('id')
              .eq('admin_id', profileId)
              .maybeSingle();
          branchId = existingByAdmin?['id'] as int?;
        }
        if (branchId == null) {
          final existingByAuth = await supabase
              .from('branches')
              .select('id')
              .eq('admin_id', user.id)
              .maybeSingle();
          branchId = existingByAuth?['id'] as int?;
        }
      }

      if (branchId != null) {
        // Update existing branch
        final existingBranch = await supabase
            .from('branches')
            .select('code')
            .eq('id', branchId)
            .maybeSingle();

        // Preserve super admin assigned code if present
        final currentCode = existingBranch?['code'] as String?;
        final finalCode = (currentCode != null && currentCode.trim().isNotEmpty)
            ? currentCode.trim()
            : cleanCode;

        final updateData = <String, dynamic>{
          'name': cleanName,
          'code': finalCode,
          'owner_name': cleanOwner,
          'contact': cleanPhone,
          'address': cleanAddress,
        };
        // branches.admin_id references public.profiles(id)
        if (profileId != null) {
          updateData['admin_id'] = profileId;
        }

        await supabase.from('branches').update(updateData).eq('id', branchId);

        if (profileId != null) {
          await supabase.from('profiles').update({
            'branch_id': branchId,
          }).eq('id', profileId);
        }

        return {
          'success': true,
          'message': 'Franchise setup updated successfully',
          'branch_id': branchId,
        };
      } else {
        // Create new branch
        final insertData = <String, dynamic>{
          'name': cleanName,
          'code': cleanCode,
          'owner_name': cleanOwner,
          'contact': cleanPhone,
          'address': cleanAddress,
          'status': 1,
        };
        // branches.admin_id references public.profiles(id)
        if (profileId != null) {
          insertData['admin_id'] = profileId;
        }

        final inserted = await supabase
            .from('branches')
            .insert(insertData)
            .select('id')
            .single();

        final newBranchId = inserted['id'] as int;

        if (profileId != null) {
          await supabase.from('profiles').update({
            'branch_id': newBranchId,
          }).eq('id', profileId);
        }

        return {
          'success': true,
          'message': 'Franchise setup completed successfully',
          'branch_id': newBranchId,
        };
      }
    } catch (directError) {
      throw Exception('Failed to save franchise setup: $directError');
    }
  }

  /// Get current branch details
  Future<Map<String, dynamic>?> getMyBranch() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final profile = await supabase
          .from('profiles')
          .select('id, branch_id')
          .eq('auth_uid', user.id)
          .maybeSingle();

      final profileId = profile?['id'] as String?;
      final profileBranchId = profile?['branch_id'] as int?;

      // 1. Try by profile.branch_id (assigned by super admin or saved during setup)
      if (profileBranchId != null) {
        final response = await supabase
            .from('branches')
            .select()
            .eq('id', profileBranchId)
            .maybeSingle();

        if (response != null) {
          // If branch admin_id is null and we have a valid profileId, link it safely
          if (profileId != null && response['admin_id'] == null) {
            try {
              await supabase
                  .from('branches')
                  .update({'admin_id': profileId})
                  .eq('id', profileBranchId);
            } catch (_) {}
          }
          return response;
        }
      }

      // 2. Try by admin_id = profileId
      if (profileId != null) {
        final response = await supabase
            .from('branches')
            .select()
            .eq('admin_id', profileId)
            .maybeSingle();

        if (response != null) return response;
      }

      // 3. Fallback try by admin_id = user.id (for legacy rows)
      final legacyResponse = await supabase
          .from('branches')
          .select()
          .eq('admin_id', user.id)
          .maybeSingle();

      return legacyResponse;
    } catch (e) {
      debugPrint('Error in getMyBranch: $e');
      return null;
    }
  }

  /// All-time fee revenue totals grouped by branch. Super Admin only —
  /// unlike other admin queries this is never branch-scoped by caller role.
  Future<List<Map<String, dynamic>>> getRevenueByBranch() async {
    final payments = await supabase.from('fee_payments').select('amount, branch_id');
    final branches = await supabase.from('branches').select('id, name, code');

    final branchNames = {
      for (final b in branches) b['id']: (b['name'] ?? b['code'] ?? 'Branch ${b['id']}').toString(),
    };

    final totals = <dynamic, double>{};
    for (final p in payments) {
      final branchId = p['branch_id'];
      final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
      totals[branchId] = (totals[branchId] ?? 0.0) + amount;
    }

    final result = totals.entries
        .map((e) => {
              'branch_id': e.key,
              'branch_name': e.key == null ? 'Unassigned' : (branchNames[e.key] ?? 'Branch ${e.key}'),
              'total_revenue': e.value,
            })
        .toList();

    result.sort((a, b) => (b['total_revenue'] as double).compareTo(a['total_revenue'] as double));
    return result;
  }
}

/// Provider for AdminRepository
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final adminRevenueByBranchProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(adminRepositoryProvider).getRevenueByBranch(),
);

final adminStudentsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(adminRepositoryProvider).getStudents(),
);

final adminStudentsWithFeeStatusProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(adminRepositoryProvider).getBranchStudentsWithFeeStatus(),
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
