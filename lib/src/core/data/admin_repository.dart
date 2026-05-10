import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';
import 'package:gokul_shree_app/src/core/utils/registration_number_generator.dart';

/// Admin repository for CRUD operations on courses, notices, and students
/// Only accessible by admin users
class AdminRepository {
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
    final response = await supabase.from('students').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Paginated students list with server-side search and status filter.
  Future<List<Map<String, dynamic>>> getStudentsPaged({
    int page = 1,
    int pageSize = 20,
    String? query,
    String statusFilter = 'all',
  }) async {
    final start = (page - 1) * pageSize;
    final search = (query ?? '').trim().toLowerCase();

    final response = await supabase
        .from('students')
        .select('id, name, registration_number, phone, photo_url, is_active')
        .order('name');

    var rows = List<Map<String, dynamic>>.from(response);

    if (search.isNotEmpty) {
      rows = rows.where((row) {
        final name = (row['name'] ?? '').toString().toLowerCase();
        final reg = (row['registration_number'] ?? '').toString().toLowerCase();
        final phone = (row['phone'] ?? '').toString().toLowerCase();
        return name.contains(search) ||
            reg.contains(search) ||
            phone.contains(search);
      }).toList();
    }

    if (statusFilter == 'active') {
      rows = rows.where((row) => row['is_active'] == true).toList();
    } else if (statusFilter == 'inactive') {
      rows = rows.where((row) => row['is_active'] == false).toList();
    }

    if (start >= rows.length) {
      return [];
    }

    final end = (start + pageSize) > rows.length
        ? rows.length
        : (start + pageSize);
    rows = rows.sublist(start, end);

    return rows
        .map(
          (row) => <String, dynamic>{
            ...row,
            'reg_no': row['registration_number'] ?? '-',
            'class': row['class_section'] ?? 'N/A',
            'status': (row['is_active'] == false) ? 'Inactive' : 'Active',
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
  }) async {
    final resolvedRegistrationNumber =
        registrationNumber != null && registrationNumber.trim().isNotEmpty
        ? registrationNumber.trim()
        : await RegistrationNumberGenerator.generateNext(supabase);

    final response = await supabase
        .from('students')
        .insert({
          'name': name,
          'email': email,
          'registration_number': resolvedRegistrationNumber,
          'phone': phone,
          'course_id': courseId,
          'photo_url': photoUrl,
          'is_active': true,
        })
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
  }) async {
    final resolvedRegistrationNumber =
        registrationNumber != null && registrationNumber.trim().isNotEmpty
        ? registrationNumber.trim()
        : await RegistrationNumberGenerator.generateNext(supabase);

    final fullPayload = {
      'name': name,
      'email': email,
      'registration_number': resolvedRegistrationNumber,
      'phone': phone,
      'course_id': courseId,
      'guardian_name': guardianName,
      'address': address,
      'date_of_birth': dateOfBirth,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final response = await supabase
          .from('students')
          .insert(fullPayload)
          .select()
          .single();
      return response;
    } catch (_) {
      final fallbackPayload = {
        'name': name,
        'email': email,
        'registration_number': resolvedRegistrationNumber,
        'phone': phone,
        'course_id': courseId,
        'is_active': true,
      };

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
    if (phone != null) updates['phone'] = phone;
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
    await supabase.from('students').delete().eq('id', id);
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
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    return {
      'todays_collection': 45200,
      'collection_growth': 12, // percentage
      'present_students': 845,
      'total_students': 900,
      'attendance_rate': 94,
      'pending_enquiries': 12,
      'new_enquiries': true,
    };
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
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // In a real app, this would POST to /new/fee_submit.php
    // with data: {'id': studentId, 'newamt': amount, 'doj': date, 'cheque': paymentMode, 'remarks': remarks}

    // Success implied if no error thrown
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
        .select('id, name, registration_number');
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
        'registration_number': student?['registration_number'] ?? '-',
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
    final response = await supabase.from('staff').select().order('name');
    return List<Map<String, dynamic>>.from(response);
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
        .from('staff')
        .insert({
          'name': name,
          'email': email,
          'role': role,
          'phone': phone,
          'photo_url': photoUrl,
          'joining_date': joiningDate ?? DateTime.now().toIso8601String(),
          'is_active': true,
        })
        .select()
        .single();
    return response;
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
    if (role != null) updates['role'] = role;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photo_url'] = photoUrl;

    final response = await supabase
        .from('staff')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  /// Delete a staff member
  Future<void> deleteStaff(String id) async {
    await supabase.from('staff').delete().eq('id', id);
  }

  // ===========================================
  // DOCUMENT APPROVALS (New Secure Flow)
  // ===========================================

  /// Get pending marksheets and certificates
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

  /// Approve a marksheet or certificate
  Future<void> approveDocument({
    required String type, // 'marksheet' | 'certificate'
    required int id,
  }) async {
    final table = type == 'marksheet' ? 'marksheets' : 'certificates';
    
    // We update via Supabase directly if RLS allows, 
    // or we could call our hardened API endpoint.
    // For now, let's use the direct update as it's cleaner in the repo.
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

    // Use the backend API
    final baseUrl = 'https://www.gokulshreeschool.com/api/v1'; // Standardized production URL
    
    final response = await supabase.functions.invoke(
      'admin/register-branch-admin', 
      body: {'email': email, 'password': password, 'name': name},
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );

    // If the above invoke fails or if we want to use direct HTTP (preferred for custom backend)
    // We would use http.post, but for consistency with existing code, 
    // let's assume we've set up a Supabase Edge Function proxy or use a custom client.
    
    // For now, I'll provide the HTTP implementation as a fallback/comment
    /*
    final httpResponse = await http.post(
      Uri.parse('$baseUrl/auth/admin/register-branch-admin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );
    return jsonDecode(httpResponse.body);
    */

    return response.data;
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
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  // Check if user has admin role in metadata or in a separate admins table
  final isAdminMeta = user.userMetadata?['is_admin'] == true;
  if (isAdminMeta) return true;

  // Check hardcoded admin email first (for testing/bootstrap)
  if (user.email == 'admin@gokulshreeschool.com') return true;

  // Check admins table
  try {
    final response = await supabase
        .from('admins')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
    return response != null;
  } catch (e) {
    return false;
  }
});
