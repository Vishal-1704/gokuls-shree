import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

/// Repository for attendance and enrollment operations
class AttendanceRepository {
  // ===========================================
  // ENROLLMENTS
  // ===========================================

  /// Get courses a student is enrolled in
  Future<List<Map<String, dynamic>>> getStudentEnrollments(
    String studentId,
  ) async {
    try {
      final response = await supabase
          .from('enrollments')
          .select('''
            *,
            courses:course_id (
              id, title, category, duration, total_classes, description
            )
          ''')
          .eq('student_id', studentId)
          .eq('status', 'active')
          .order('enrolled_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      // When RLS denies enrollments (e.g. missing policy), keep UI functional.
      return [];
    }
  }

  /// Get all enrollments for a course (for admin)
  Future<List<Map<String, dynamic>>> getCourseEnrollments(
    String courseId,
  ) async {
    final response = await supabase
        .from('enrollments')
        .select('''
          *,
          students:student_id (
            id, name, email, registration_number
          )
        ''')
        .eq('course_id', courseId)
        .order('enrolled_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Enroll a student in a course
  Future<Map<String, dynamic>> enrollStudent({
    required String studentId,
    required String courseId,
  }) async {
    final response = await supabase
        .from('enrollments')
        .insert({
          'student_id': studentId,
          'course_id': courseId,
          'status': 'active',
        })
        .select()
        .single();
    return response;
  }

  /// Update enrollment status
  Future<void> updateEnrollmentStatus(
    String enrollmentId,
    String status,
  ) async {
    await supabase
        .from('enrollments')
        .update({'status': status})
        .eq('id', enrollmentId);
  }

  // ===========================================
  // ATTENDANCE
  // ===========================================

  /// Get attendance records for an enrollment
  Future<List<Map<String, dynamic>>> getAttendanceForEnrollment(
    String enrollmentId,
  ) async {
    final response = await supabase
        .from('attendance')
        .select()
        .eq('enrollment_id', enrollmentId)
        .order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get attendance count for an enrollment
  Future<Map<String, int>> getAttendanceStats(String enrollmentId) async {
    final records = await getAttendanceForEnrollment(enrollmentId);
    int present = 0;
    int absent = 0;
    int late = 0;

    for (final record in records) {
      switch (record['status']) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
      }
    }

    return {
      'present': present,
      'absent': absent,
      'late': late,
      'total': present + absent + late,
    };
  }

  /// Get overall attendance percentage for a student
  Future<double> getOverallAttendance(String studentId) async {
    final enrollments = await getStudentEnrollments(studentId);

    if (enrollments.isEmpty) return 0.0;

    int totalPresent = 0;
    int totalClasses = 0;

    for (final enrollment in enrollments) {
      final course = enrollment['courses'];
      final courseTotal = course?['total_classes'] ?? 0;

      if (courseTotal > 0) {
        final stats = await getAttendanceStats(enrollment['id']);
        totalPresent +=
            stats['present']! + stats['late']!; // Late counts as present
        totalClasses += courseTotal as int;
      }
    }

    if (totalClasses == 0) return 0.0;
    return (totalPresent / totalClasses) * 100;
  }

  /// Get per-course attendance for a student
  Future<List<Map<String, dynamic>>> getPerCourseAttendance(
    String studentId,
  ) async {
    final enrollments = await getStudentEnrollments(studentId);
    final result = <Map<String, dynamic>>[];

    for (final enrollment in enrollments) {
      final course = enrollment['courses'];
      final stats = await getAttendanceStats(enrollment['id']);
      final totalClasses = course?['total_classes'] ?? 0;

      double percentage = 0.0;
      if (totalClasses > 0) {
        final attended = stats['present']! + stats['late']!;
        percentage = (attended / totalClasses) * 100;
      }

      result.add({
        'enrollment_id': enrollment['id'],
        'course_id': course?['id'],
        'course_title': course?['title'] ?? 'Unknown Course',
        'category': course?['category'],
        'total_classes': totalClasses,
        'attended': stats['present']! + stats['late']!,
        'present': stats['present'],
        'late': stats['late'],
        'absent': stats['absent'],
        'percentage': percentage,
      });
    }

    return result;
  }

  /// Mark attendance (admin only)
  Future<Map<String, dynamic>> markAttendance({
    required String enrollmentId,
    required DateTime date,
    required String status, // 'present', 'absent', 'late'
  }) async {
    final user = supabase.auth.currentUser;
    final response = await supabase
        .from('attendance')
        .insert({
          'enrollment_id': enrollmentId,
          'date': date.toIso8601String().split('T')[0],
          'status': status,
          'marked_by': user?.id,
        })
        .select()
        .single();
    return response;
  }

  /// Update attendance record
  Future<void> updateAttendance(String attendanceId, String status) async {
    await supabase
        .from('attendance')
        .update({'status': status})
        .eq('id', attendanceId);
  }

  /// Delete attendance record
  Future<void> deleteAttendance(String attendanceId) async {
    await supabase.from('attendance').delete().eq('id', attendanceId);
  }
}

/// Provider for AttendanceRepository
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

/// Provider for student's overall attendance
final studentOverallAttendanceProvider = FutureProvider.family<double, String>((
  ref,
  studentId,
) async {
  final repo = ref.read(attendanceRepositoryProvider);
  return repo.getOverallAttendance(studentId);
});

/// Provider for student's per-course attendance
final studentCourseAttendanceProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      studentId,
    ) async {
      final repo = ref.read(attendanceRepositoryProvider);
      return repo.getPerCourseAttendance(studentId);
    });

/// Provider for student's enrollments
final studentEnrollmentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      studentId,
    ) async {
      final repo = ref.read(attendanceRepositoryProvider);
      return repo.getStudentEnrollments(studentId);
    });
