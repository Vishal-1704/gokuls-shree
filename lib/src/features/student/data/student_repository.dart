import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/core/services/supabase_service.dart';

class StudentRepository {
  final SupabaseService _supabaseService;

  StudentRepository(this._supabaseService);

  Future<Map<String, dynamic>> getStudentProfile() async {
    try {
      final user = supabase.auth.currentUser;
      final profile = await _supabaseService.getStudentProfile();

      if (profile == null) {
        final authName = user?.userMetadata?['name'] ?? 'Student';
        return {
          'id': user?.id,
          'name': authName,
          'class_section': 'Pending Setup',
          'reg_no': 'Pending Approval',
          'streak': 0,
          'photo_url':
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(authName.toString())}&background=random',
          'email': user?.email,
          'phone': user?.phone,
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

      final resolvedName = profile['name'];
      final resolvedCourse = profile['courses']?['name'] ?? 'N/A';
      final resolvedProgram = profile['courses']?['category'] ?? 'N/A';

      // Map Supabase data to UI model — keys here must match the actual
      // students table columns (see master_schema.sql), not guessed names.
      return {
        'id': profile['id']?.toString(),
        'name': (resolvedName ?? 'Student').toString(),
        'class_section': resolvedCourse.toString(),
        'program': resolvedProgram.toString(),
        'reg_no': profile['reg_no'] ?? 'N/A',
        'streak': profile['streak'] ?? 0,
        'photo_url':
            profile['photo_url'] ??
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent((resolvedName ?? 'Student').toString())}&background=random',
        'email': profile['email'],
        'phone': profile['contact'],
        'father_name': profile['father_name'],
        'guardian_name': profile['mother_name'],
        'gender': profile['gender'],
        'address': profile['address'],
        'doj': profile['doj'],
        'date_of_birth': profile['dob'],
        'course_id': profile['course_id'],
        'batch_id': profile['batch_id'],
        'branch_id': profile['branch_id'],
        'fee_summary': profile['fee_summary'],
      };
    } catch (e) {
      final user = supabase.auth.currentUser;
      final authName = user?.userMetadata?['name'] ?? 'Student';
      // Fallback for development if table/columns missing or RLS error
      return {
        'id': user?.id,
        'name': authName,
        'class_section': 'Pending Setup',
        'reg_no': 'Pending Approval',
        'streak': 0,
        'photo_url':
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(authName.toString())}&background=random',
        'email': user?.email,
        'phone': user?.phone,
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
        final marksObtained = (r['marks_obtained'] as num?) ?? 0;
        final totalMarks = (r['total_marks'] as num?) ?? 100;
        final grade = r['grade'] as String?;

        return {
          'title': r['exam_name'] ?? r['subject_name'] ?? 'Exam',
          'score': marksObtained,
          'total': totalMarks,
          'date': _formatTime(r['calculated_at'] ?? r['attempted_at'] ?? r['created_at']),
          'status': grade == 'AB'
              ? 'Absent'
              : (totalMarks > 0 && marksObtained / totalMarks >= 0.33
                    ? 'Pass'
                    : 'Fail'),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingExams({int limit = 3}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      // students.profile_id references profiles(id), not the raw auth
      // uid — resolve profiles.id first, same two-hop pattern used
      // elsewhere (e.g. supabase_service.dart's student id resolution).
      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('auth_uid', user.id)
          .maybeSingle();
      final profileId = profile?['id'];
      if (profileId == null) return [];

      // A profile can have more than one students row (one per course
      // enrollment) — collect course/batch/branch across ALL of them,
      // not just whichever one a single-row query happened to pick.
      final students = await supabase
          .from('students')
          .select('id, course_id, batch_id, branch_id')
          .eq('profile_id', profileId);
      final studentRows = List<Map<String, dynamic>>.from(students);
      if (studentRows.isEmpty) return [];

      final studentIds = studentRows.map((s) => s['id'] as int).toList();
      final rosterRows = await supabase
          .from('schedule_roster')
          .select('schedules(id, title, start_at, end_at, status)')
          .inFilter('student_id', studentIds);

      final items = <Map<String, dynamic>>[];
      for (final r in (rosterRows as List)) {
        final p = r['schedules'] as Map<String, dynamic>?;
        if (p == null) continue;
        final dateRaw = p['start_at'];
        final now = DateTime.now().toUtc();
        final startAt = dateRaw != null
            ? DateTime.tryParse(dateRaw.toString())?.toUtc()
            : null;

        String status = 'Available';
        if (startAt != null && startAt.isAfter(now)) {
          status = 'Upcoming';
        }

        items.add({
          'name': (p['title'] ?? 'Exam').toString(),
          'date': _formatDate(dateRaw?.toString()),
          'short_date': _shortDate(dateRaw?.toString()),
          'status': status,
          'dateRaw': dateRaw,
          'dateTime': startAt?.toLocal(),
          'type': 'exam',
        });
      }
      return items.take(limit).toList();
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
    int limit = 50,
  }) async {
    try {
      final items = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final currentYear = now.year;

      // 1. Standard Indian Gazetted & National Holidays for the current year
      final holidays = [
        {'name': 'Republic Day', 'month': 1, 'day': 26, 'desc': 'National Holiday'},
        {'name': 'Maha Shivratri', 'month': 2, 'day': 15, 'desc': 'Gazetted Holiday'},
        {'name': 'Holi', 'month': 3, 'day': 4, 'desc': 'Festival of Colours'},
        {'name': 'Eid-ul-Fitr', 'month': 3, 'day': 21, 'desc': 'Gazetted Holiday'},
        {'name': 'Good Friday', 'month': 4, 'day': 3, 'desc': 'Gazetted Holiday'},
        {'name': 'Dr. B.R. Ambedkar Jayanti', 'month': 4, 'day': 14, 'desc': 'National Observance'},
        {'name': 'Mahavir Jayanti', 'month': 4, 'day': 20, 'desc': 'Gazetted Holiday'},
        {'name': 'Buddha Purnima', 'month': 5, 'day': 1, 'desc': 'Gazetted Holiday'},
        {'name': 'Eid-ul-Adha (Bakrid)', 'month': 5, 'day': 28, 'desc': 'Gazetted Holiday'},
        {'name': 'Muharram', 'month': 6, 'day': 26, 'desc': 'Gazetted Holiday'},
        {'name': 'Independence Day', 'month': 8, 'day': 15, 'desc': 'National Holiday'},
        {'name': 'Janmashtami', 'month': 9, 'day': 4, 'desc': 'Gazetted Holiday'},
        {'name': 'Milad-un-Nabi', 'month': 9, 'day': 16, 'desc': 'Gazetted Holiday'},
        {'name': 'Mahatma Gandhi Jayanti', 'month': 10, 'day': 2, 'desc': 'National Holiday'},
        {'name': 'Dussehra (Vijayadashami)', 'month': 10, 'day': 20, 'desc': 'Gazetted Holiday'},
        {'name': 'Diwali (Deepavali)', 'month': 11, 'day': 8, 'desc': 'Festival of Lights'},
        {'name': 'Govardhan Puja', 'month': 11, 'day': 9, 'desc': 'Public Holiday'},
        {'name': 'Guru Nanak Jayanti', 'month': 11, 'day': 24, 'desc': 'Gazetted Holiday'},
        {'name': 'Christmas Day', 'month': 12, 'day': 25, 'desc': 'National Holiday'},
      ];

      for (final h in holidays) {
        final hDate = DateTime(currentYear, h['month'] as int, h['day'] as int);
        items.add({
          'text': h['name'],
          'date': _formatDate(hDate.toIso8601String()),
          'short_date': _shortDate(hDate.toIso8601String()),
          'type': 'holiday',
          'description': h['desc'],
          'dateTime': hDate,
        });
      }

      // 2. Scheduled Upcoming Exams & Tests
      try {
        final upcomingExams = await getUpcomingExams(limit: 20);
        for (final exam in upcomingExams) {
          final rawDt = exam['dateTime'] ?? DateTime.tryParse(exam['dateRaw']?.toString() ?? '');
          items.add({
            'text': exam['name']?.toString() ?? 'Assessment',
            'date': exam['date']?.toString() ?? 'TBA',
            'short_date': exam['short_date'] ?? exam['date']?.toString() ?? 'TBA',
            'type': (exam['type'] ?? 'exam').toString().toLowerCase(),
            'description': exam['status'] ?? 'Scheduled Assessment',
            'dateTime': rawDt,
          });
        }
      } catch (_) {}

      // 3. Admin Notices / Events
      try {
        final notices = await _supabaseService.getNotices(limit: 30);
        for (final n in notices) {
          final title = (n['title'] ?? 'Notice').toString();
          final ts = (n['published_at'] ?? n['created_at'])?.toString();
          final category = (n['category'] ?? n['type'] ?? '').toString().toLowerCase();

          if (_looksLikeCalendarEvent(title, category)) {
            final nDate = DateTime.tryParse(ts ?? '');
            final eventType = category.contains('holiday')
                ? 'holiday'
                : (category.contains('exam') ? 'exam' : 'event');
            items.add({
              'text': title,
              'date': _formatDate(ts),
              'short_date': _shortDate(ts),
              'type': eventType,
              'description': (n['content'] ?? 'Announcement').toString(),
              'dateTime': nDate,
            });
          }
        }
      } catch (_) {}

      // Deduplicate by text + short_date
      final deduped = <String, Map<String, dynamic>>{};
      for (final item in items) {
        final key = '${item['text']?.toString().toLowerCase()}|${item['short_date']?.toString()}';
        deduped[key] = item;
      }

      final list = deduped.values.toList();
      // Sort chronologically by date
      list.sort((a, b) {
        final da = a['dateTime'] as DateTime?;
        final db = b['dateTime'] as DateTime?;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

      return list.take(limit).toList();
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

final studentMarksheetsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return ref.watch(supabaseServiceProvider).getMyMarksheets();
});

final studentCertificatesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return ref.watch(supabaseServiceProvider).getMyCertificates();
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

final studentAcademicCalendarProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
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

final studentAttendanceStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getAttendanceStats();
});

final studentFeeSnapshotProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(studentRepositoryProvider);
  return repository.getFeeSnapshot();
});
