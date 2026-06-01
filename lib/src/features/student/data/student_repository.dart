import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

class StudentRepository {
  final SupabaseService _supabaseService;

  StudentRepository(this._supabaseService);

  Future<Map<String, dynamic>> getStudentProfile() async {
    try {
      final profile = await _supabaseService.getStudentProfile();
      if (profile == null) throw Exception('Student profile not found');

      final resolvedName =
          profile['name'] ?? profile['full_name'] ?? profile['student_name'];
      final resolvedCourse =
          profile['courses']?['title'] ?? profile['course'] ?? 'N/A';

      // Map Supabase data to UI model
      return {
        'id': profile['id']?.toString(),
        'name': (resolvedName ?? 'Student').toString(),
        'class_section': resolvedCourse.toString(),
        'reg_no': profile['registration_number'] ?? 'N/A',
        'streak':
            profile['streak'] ??
            0, // Assuming streak column exists or default 0
        'photo_url':
            profile['photo_url'] ??
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent((resolvedName ?? 'Student').toString())}&background=random',
        'email': profile['email'],
        'phone': profile['phone'],
        'father_name': profile['father_name'],
        'guardian_name': profile['guardian_name'],
        'address': profile['address'],
        'doj': profile['doj'],
        'date_of_birth': profile['date_of_birth'],
        'course_id': profile['course_id'],
        'batch_id': profile['batch_id'],
        'branch_id': profile['branch_id'],
      };
    } catch (e) {
      // Fallback for development if table/columns missing
      return {
        'id': null,
        'name': 'Gokul Student',
        'class_section': 'Loading...',
        'reg_no': 'GS-2024-XX',
        'streak': 0,
        'photo_url': 'https://ui-avatars.com/api/?name=Student',
        'email': null,
        'phone': null,
        'father_name': null,
        'guardian_name': null,
        'address': null,
        'doj': null,
        'date_of_birth': null,
        'course_id': null,
        'batch_id': null,
        'branch_id': null,
      };
    }
  }

  Future<String> markMyAttendance() async {
    try {
      final profile = await _supabaseService.getStudentProfile();
      final studentId = profile?['id']?.toString();
      if (studentId == null || studentId.isEmpty) {
        throw Exception('Student profile not found');
      }

      final today = DateTime.now();
      final dateOnly =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      try {
        await _supabaseService.markSmartAttendance(
          studentId: studentId,
          source: 'manual_tap',
          status: 'present',
          confidenceScore: 1,
          meta: {'marked_from': 'student_dashboard', 'date': dateOnly},
        );
        return 'Attendance marked successfully';
      } catch (_) {
        // Fallback for legacy schemas.
      }

      await supabase.from('student_attendance').insert({
        'student_id': studentId,
        'date': dateOnly,
        'status': 'present',
        'marked_at': DateTime.now().toIso8601String(),
      });

      return 'Attendance marked successfully';
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('duplicate') || msg.contains('unique')) {
        return 'Attendance already marked for today';
      }
      return 'Unable to mark attendance right now';
    }
  }

  Future<Map<String, dynamic>> getAttendanceStats() async {
    try {
      final profile = await _supabaseService.getStudentProfile();
      if (profile == null) return {'percentage': 0, 'status': 'No Data'};

      final studentId = profile['id'];
      final attendance = await _supabaseService.getStudentAttendance(studentId);

      if (attendance.isEmpty) {
        return {'percentage': 0, 'status': 'No Records', 'trend': 'flat'};
      }

      // Calculate percentage (assuming 'status' column is 'Present' or 'Absent')
      final total = attendance.length;
      final present = attendance.where((a) {
        final status = (a['status'] ?? '').toString().toLowerCase();
        return status == 'present' || status == 'p' || status == 'late';
      }).length;

      final percentage = (present / total * 100).round();

      String statusText = 'Needs Improvement';
      if (percentage >= 75)
        statusText = 'Great Progress!';
      else if (percentage >= 60)
        statusText = 'Average';

      return {'percentage': percentage, 'status': statusText, 'trend': 'up'};
    } catch (e) {
      return {'percentage': 0, 'status': 'Error', 'trend': 'flat'};
    }
  }

  Future<List<Map<String, dynamic>>> getNotices() async {
    try {
      final notices = await _supabaseService.getNotices(limit: 5);

      return notices.map((n) {
        // Normalize data for UI
        final type = n['type'] ?? 'event_note';
        final color = type == 'campaign' ? 'blue' : 'amber';

        return {
          'title': n['title'] ?? 'Notice',
          'content': n['content'] ?? n['description'] ?? '',
          'description': n['description'] ?? '',
          'time': _formatTime(n['created_at']), // Simple formatter
          'type': type,
          'color': color,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMyExamResults() async {
    try {
      final results = await _supabaseService.getMyExamResults();
      return results.map((r) {
        final session = r['exam_sessions'] as Map<String, dynamic>;
        final paperSet = session['paper_sets'] as Map<String, dynamic>;

        return {
          'title': paperSet['name'] ?? 'Exam',
          'score': r['marks_obtained'] ?? 0,
          'total': r['total_marks'] ?? 100,
          'date': _formatTime(session['ended_at']),
          'status': (r['passed'] ?? false) ? 'Pass' : 'Fail',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingExams({int limit = 3}) async {
    try {
      final results = await _supabaseService.getMyExamResults();
      final now = DateTime.now();

      final upcomingFromSessions = <Map<String, dynamic>>[];
      for (final r in results) {
        final session = r['exam_sessions'];
        if (session is! Map<String, dynamic>) continue;

        final endedAtRaw = session['ended_at']?.toString();
        if (endedAtRaw == null || endedAtRaw.isEmpty) continue;

        final endedAt = DateTime.tryParse(endedAtRaw);
        if (endedAt == null || !endedAt.isAfter(now)) continue;

        final paperSet = session['paper_sets'];
        upcomingFromSessions.add({
          'name': (paperSet is Map<String, dynamic>)
              ? (paperSet['name'] ?? paperSet['title'] ?? 'Exam').toString()
              : 'Exam',
          'date': _formatDate(endedAtRaw),
          'status': 'Upcoming',
        });
      }

      if (upcomingFromSessions.isNotEmpty) {
        return upcomingFromSessions.take(limit).toList();
      }

      final paperSets = await _supabaseService.getActivePaperSets(limit: limit);
      return paperSets.map((p) {
        final dateRaw =
            p['exam_date'] ??
            p['scheduled_at'] ??
            p['start_at'] ??
            p['created_at'];
        final statusRaw = (p['status'] ?? '').toString().toLowerCase();
        final status = statusRaw == 'scheduled' || statusRaw == 'upcoming'
            ? 'Upcoming'
            : 'Available';

        return {
          'name': (p['title'] ?? p['name'] ?? 'Exam').toString(),
          'date': _formatDate(dateRaw?.toString()),
          'status': status,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getFeeSnapshot() async {
    try {
      final fees = await _supabaseService.getMyFeePayments();
      if (fees.isEmpty) {
        return {
          'total_paid': 0.0,
          'total_pending': 0.0,
          'latest_paid_amount': null,
          'latest_paid_date': null,
          'all_paid': true,
        };
      }

      double totalPaid = 0;
      double totalPending = 0;
      Map<String, dynamic>? latestPaid;
      DateTime? latestPaidDate;

      for (final fee in fees) {
        final amount = (fee['amount'] as num?)?.toDouble() ?? 0;
        final status = (fee['status'] ?? '').toString().toLowerCase();
        final amountPaidRaw = (fee['amount_paid'] as num?)?.toDouble();
        final paid = amountPaidRaw ?? (status == 'paid' ? amount : 0);

        totalPaid += paid;
        totalPending += (amount - paid) > 0 ? (amount - paid) : 0;

        if (paid <= 0) continue;

        final paidDate =
            _parseDateTime(fee['paid_date']) ??
            _parseDateTime(fee['updated_at']);
        if (paidDate == null) continue;

        if (latestPaidDate == null || paidDate.isAfter(latestPaidDate)) {
          latestPaidDate = paidDate;
          latestPaid = fee;
        }
      }

      return {
        'total_paid': totalPaid,
        'total_pending': totalPending,
        'latest_paid_amount': latestPaid == null
            ? null
            : ((latestPaid['amount_paid'] as num?)?.toDouble() ??
                  (latestPaid['amount'] as num?)?.toDouble() ??
                  0),
        'latest_paid_date': latestPaidDate?.toIso8601String(),
        'all_paid': totalPending <= 0,
      };
    } catch (_) {
      return {
        'total_paid': 0.0,
        'total_pending': 0.0,
        'latest_paid_amount': null,
        'latest_paid_date': null,
        'all_paid': false,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAcademicCalendarEvents({
    int limit = 4,
  }) async {
    try {
      final upcomingExams = await getUpcomingExams(limit: limit);
      final notices = await _supabaseService.getNotices(limit: limit * 2);

      final items = <Map<String, dynamic>>[];

      for (final exam in upcomingExams) {
        items.add({
          'text': exam['name']?.toString() ?? 'Upcoming Exam',
          'date': exam['date']?.toString() ?? 'TBA',
          'type': 'exam',
        });
      }

      for (final n in notices) {
        final title = (n['title'] ?? 'Notice').toString();
        final ts = (n['published_at'] ?? n['created_at'])?.toString();
        final type = (n['type'] ?? n['category'] ?? '')
            .toString()
            .toLowerCase();

        if (_looksLikeCalendarEvent(title, type)) {
          items.add({
            'text': title,
            'date': _shortDate(ts),
            'type': type.isEmpty ? 'notice' : type,
          });
        }
      }

      final deduped = <String, Map<String, dynamic>>{};
      for (final item in items) {
        final key =
            '${item['text']?.toString().toLowerCase()}|${item['date']?.toString()}';
        deduped[key] = item;
      }

      return deduped.values.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  bool _looksLikeCalendarEvent(String title, String type) {
    final hay = '$title $type'.toLowerCase();
    return hay.contains('exam') ||
        hay.contains('result') ||
        hay.contains('holiday') ||
        hay.contains('session') ||
        hay.contains('admit') ||
        hay.contains('notice') ||
        hay.contains('event');
  }

  String _shortDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'TBA';
    final date = DateTime.tryParse(timestamp);
    if (date == null) return 'TBA';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'TBA';
    final date = DateTime.tryParse(timestamp);
    if (date == null) return 'TBA';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      final date = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays} days ago';
      if (diff.inHours > 0) return '${diff.inHours} hours ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
      return 'Just now';
    } catch (e) {
      return 'Recently';
    }
  }
}

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return StudentRepository(supabaseService);
});

final studentExamResultsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getMyExamResults();
});

final studentProfileProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getStudentProfile();
});

final studentAttendanceProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(studentRepositoryProvider);
  final profile = await repository.getStudentProfile();
  final studentId = profile['id']?.toString();
  if (studentId == null || studentId.isEmpty) {
    return [];
  }

  final supabaseService = ref.watch(supabaseServiceProvider);
  return supabaseService.getStudentAttendance(studentId);
});

final studentAcademicCalendarProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getAcademicCalendarEvents();
});

final studentFeeStatusProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final payments = await supabaseService.getMyFeePayments();

  return payments.map((p) {
    return {
      'installment': p['title'] ?? p['description'] ?? 'Fee Installment',
      'amount': (p['amount'] as num?)?.toDouble() ?? 0.0,
      'dueDate': p['due_date']?.toString().split(' ')[0] ?? 'N/A',
      'status': p['status']?.toString().toLowerCase() ?? 'pending',
      'paidDate': p['paid_date']?.toString().split(' ')[0],
      'receiptNo': p['receipt_no'],
    };
  }).toList();
});
