import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/exam_model.dart';

final examRepositoryProvider = Provider((ref) {
  return ExamRepository(Supabase.instance.client);
});

final adminPaperSetsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async => ref.read(examRepositoryProvider).getAdminPaperSets(),
);

final adminBatchTargetsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async => ref.read(examRepositoryProvider).getBatchTargets(),
);

final upcomingExamsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async => ref.read(examRepositoryProvider).getUpcomingExams(),
);

final examResultsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async => ref.read(examRepositoryProvider).getMyResults(),
);

class ExamRepository {
  final SupabaseClient _client;

  ExamRepository(this._client);

  /// Resolves the current auth user to their `students.id` (the INT primary
  /// key everything in this feature is keyed on — schedules, rosters,
  /// attempts). Two hops: auth user -> profiles.id -> students.id.
  Future<int?> _currentStudentId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final profile = await _client
        .from('profiles')
        .select('id')
        .eq('auth_uid', user.id)
        .maybeSingle();
    if (profile == null) return null;

    final student = await _client
        .from('students')
        .select('id')
        .eq('profile_id', profile['id'])
        .maybeSingle();
    return student?['id'] as int?;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STUDENT: View Exams
  // ═══════════════════════════════════════════════════════════════════════════

  /// All schedules the logged-in student is on the roster for (test + exam),
  /// regardless of whether their window is currently open.
  Future<List<Map<String, dynamic>>> getUpcomingExams() async {
    final studentId = await _currentStudentId();
    if (studentId == null) return [];

    try {
      final response = await _client
          .from('schedule_roster')
          .select(
            'schedules(id, title, start_at, end_at, status, max_attempts, '
            'paper_sets(id, title, assessment_type, total_marks, duration_minutes, '
            'course_id, courses(name, short_name), paper_questions(count)))',
          )
          .eq('student_id', studentId);

      final rows = (response as List)
          .map((r) => r['schedules'] as Map<String, dynamic>?)
          .whereType<Map<String, dynamic>>()
          .map((s) {
            final paper = s['paper_sets'] as Map<String, dynamic>?;
            if (paper != null) {
              final countRows = paper['paper_questions'] as List?;
              paper['questions_count'] = countRows != null && countRows.isNotEmpty
                  ? countRows.first['count']
                  : 0;
            }
            return s;
          })
          .toList();
      rows.sort(
        (a, b) => (a['start_at'] ?? '').toString().compareTo((b['start_at'] ?? '').toString()),
      );
      return rows;
    } catch (_) {
      return [];
    }
  }

  /// Schedules that are currently inside their attempt window — what the
  /// "Active Exams" quick-start list shows.
  Future<List<Exam>> getExams({int? branchId}) async {
    final schedules = await getUpcomingExams();
    final now = DateTime.now().toUtc();

    final startable = schedules.where((s) {
      if (s['status'] != 'published') return false;
      final start = DateTime.tryParse((s['start_at'] ?? '').toString())?.toUtc();
      final end = DateTime.tryParse((s['end_at'] ?? '').toString())?.toUtc();
      if (start == null || now.isBefore(start)) return false;
      if (end != null && now.isAfter(end)) return false;
      return true;
    });

    return startable.map((s) {
      final paper = s['paper_sets'] as Map<String, dynamic>? ?? {};
      return Exam.fromJson({
        'id': (paper['id'] ?? '').toString(),
        'schedule_id': s['id']?.toString(),
        'title': paper['title'] ?? s['title'] ?? 'Exam',
        'duration_minutes': paper['duration_minutes'] ?? 60,
        'total_marks': paper['total_marks'] ?? 100,
        'questions_count': paper['questions_count'] ?? 0,
        'max_attempts': s['max_attempts'] ?? 1,
      });
    }).toList();
  }

  Future<Map<String, dynamic>> canStartExam(Exam exam) async {
    final studentId = await _currentStudentId();
    if (studentId == null) {
      return {'allowed': false, 'reason': 'Login required'};
    }

    final scheduleId = exam.scheduleId;
    if (scheduleId == null || scheduleId.isEmpty) {
      return {'allowed': false, 'reason': 'This paper has not been scheduled'};
    }

    final schedule = await _client
        .from('schedules')
        .select('id, start_at, end_at, status, max_attempts')
        .eq('id', int.parse(scheduleId))
        .maybeSingle();

    if (schedule == null) {
      return {'allowed': false, 'reason': 'Exam schedule not found'};
    }

    final now = DateTime.now().toUtc();
    final startAt = DateTime.tryParse((schedule['start_at'] ?? '').toString())?.toUtc();
    final endAt = DateTime.tryParse((schedule['end_at'] ?? '').toString())?.toUtc();

    if (schedule['status'] != 'published') {
      return {'allowed': false, 'reason': 'Exam not published'};
    }
    if (startAt != null && now.isBefore(startAt)) {
      return {'allowed': false, 'reason': 'Exam has not started yet'};
    }
    if (endAt != null && now.isAfter(endAt)) {
      return {'allowed': false, 'reason': 'Exam window is closed'};
    }

    final maxAttempts = int.tryParse((schedule['max_attempts'] ?? 1).toString()) ?? 1;
    final attempts = await _client
        .from('attempts')
        .select('id')
        .eq('student_id', studentId)
        .eq('schedule_id', int.parse(scheduleId));

    if ((attempts as List).length >= maxAttempts) {
      return {'allowed': false, 'reason': 'Attempt limit reached'};
    }

    return {'allowed': true};
  }

  /// Questions for a paper — deliberately withholds the correct answer.
  /// Grading happens server-side (grade_attempt, migration
  /// 20240301000004/7). This reads `question_bank_public` (migration
  /// 20240301000007), a view with no `correct_option` column at all —
  /// structurally absent, not just omitted from this query — so there's no
  /// way to pull the answer key out of the API regardless of what a
  /// student's client asks for. paper_questions gives the ordered id list;
  /// the base `question_bank` table itself is admin-only under RLS.
  Future<List<Question>> getQuestions(String paperSetId) async {
    final links = await _client
        .from('paper_questions')
        .select('question_id, order_index')
        .eq('paper_id', int.parse(paperSetId))
        .order('order_index');

    final orderedIds = (links as List).map((r) => r['question_id'] as int).toList();
    if (orderedIds.isEmpty) return [];

    final rows = await _client
        .from('question_bank_public')
        .select('id, question_text, option_a, option_b, option_c, option_d, image_url')
        .inFilter('id', orderedIds);

    final byId = {for (final r in (rows as List)) r['id'] as int: r as Map<String, dynamic>};

    return orderedIds
        .map((id) => byId[id])
        .whereType<Map<String, dynamic>>()
        .map((q) => Question.fromJson({
              'id': q['id'].toString(),
              'text': q['question_text'] ?? '',
              'options': [
                q['option_a'] ?? '',
                q['option_b'] ?? '',
                q['option_c'] ?? '',
                q['option_d'] ?? '',
              ],
              'correct_option_index': -1, // structurally not present in this view
              'image_url': q['image_url'],
            }))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN: Paper Management (Super Admin / Branch Admin)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all papers for admin management view
  Future<List<Map<String, dynamic>>> getAdminPaperSets() async {
    final response = await _client
        .from('paper_sets')
        .select(
          'id, title, assessment_type, total_marks, duration_minutes, status, created_at, '
          'branches(name), paper_questions(count)',
        )
        .order('created_at', ascending: false);

    return (response as List).map((p) {
      final map = Map<String, dynamic>.from(p);
      final countRows = map['paper_questions'] as List?;
      map['total_questions'] = countRows != null && countRows.isNotEmpty
          ? countRows.first['count']
          : 0;
      return map;
    }).toList();
  }

  /// Create a new paper (question paper shell — questions added afterwards)
  /// Returns the created paper's ID
  Future<int> createPaperSet({
    required String title,
    required int durationMinutes,
    required int totalMarks,
    required String assessmentType, // 'test' or 'exam'
    int? branchId,
    int? courseId,
  }) async {
    final response = await _client
        .from('paper_sets')
        .insert({
          'title': title,
          'assessment_type': assessmentType,
          'duration_minutes': durationMinutes,
          'total_marks': totalMarks,
          'branch_id': branchId,
          'course_id': courseId,
          'status': 'draft', // Draft by default until questions are added
          'created_by': _client.auth.currentUser?.id,
        })
        .select('id')
        .single();

    return response['id'] as int;
  }

  /// Update paper metadata
  Future<void> updatePaperSet({
    required int paperSetId,
    String? title,
    int? durationMinutes,
    int? totalMarks,
    int? branchId,
    int? courseId,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (durationMinutes != null) updates['duration_minutes'] = durationMinutes;
    if (totalMarks != null) updates['total_marks'] = totalMarks;
    if (branchId != null) updates['branch_id'] = branchId;
    if (courseId != null) updates['course_id'] = courseId;

    await _client.from('paper_sets').update(updates).eq('id', paperSetId);
  }

  /// Delete a paper (also deletes its question links via cascade — the
  /// underlying question_bank rows are untouched so they stay reusable)
  Future<void> deletePaperSet(int paperSetId) async {
    await _client.from('paper_sets').delete().eq('id', paperSetId);
  }

  /// Publish/unpublish a paper
  Future<void> togglePaperSetStatus(int paperSetId, bool isActive) async {
    await _client
        .from('paper_sets')
        .update({'status': isActive ? 'published' : 'draft'})
        .eq('id', paperSetId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN: Question Management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all questions for a paper (admin view — includes correct answer)
  Future<List<Map<String, dynamic>>> getAdminQuestions(int paperSetId) async {
    final response = await _client
        .from('paper_questions')
        .select(
          'order_index, question_bank(id, question_text, option_a, option_b, '
          'option_c, option_d, correct_option, marks, subject, difficulty, image_url)',
        )
        .eq('paper_id', paperSetId)
        .order('order_index');

    return (response as List).map((row) {
      final q = Map<String, dynamic>.from(row['question_bank'] as Map);
      q['correct_option'] = _intToChar(q['correct_option']);
      return q;
    }).toList();
  }

  /// Add a single MCQ question to a paper
  Future<void> addQuestion({
    required int paperSetId,
    required String questionText,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required String correctOption, // 'A', 'B', 'C', or 'D'
    double marks = 1.0,
    String? subject,
    String difficulty = 'medium',
    String? imageUrl,
  }) async {
    final paper = await _client
        .from('paper_sets')
        .select('course_id')
        .eq('id', paperSetId)
        .single();

    final question = await _client
        .from('question_bank')
        .insert({
          'course_id': paper['course_id'],
          'subject': subject,
          'difficulty': difficulty,
          'question_text': questionText,
          'option_a': optionA,
          'option_b': optionB,
          'option_c': optionC,
          'option_d': optionD,
          'correct_option': _charToInt(correctOption),
          'marks': marks,
          'image_url': imageUrl,
          'created_by': _client.auth.currentUser?.id,
        })
        .select('id')
        .single();

    final existing = await _client
        .from('paper_questions')
        .select('id')
        .eq('paper_id', paperSetId);
    final nextOrder = (existing as List).length;

    await _client.from('paper_questions').insert({
      'paper_id': paperSetId,
      'question_id': question['id'],
      'order_index': nextOrder,
    });
  }

  /// Update an existing question
  Future<void> updateQuestion({
    required int questionId,
    required String questionText,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required String correctOption,
    double marks = 1.0,
    String? subject,
    String difficulty = 'medium',
    String? imageUrl,
  }) async {
    await _client.from('question_bank').update({
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': _charToInt(correctOption),
      'marks': marks,
      'subject': subject,
      'difficulty': difficulty,
      'image_url': imageUrl,
    }).eq('id', questionId);
  }

  /// Remove a question from a paper. The question_bank row itself is left
  /// alone (it may be reused by other papers) — only the link is deleted.
  Future<void> deleteQuestion(int questionId, int paperSetId) async {
    await _client
        .from('paper_questions')
        .delete()
        .eq('paper_id', paperSetId)
        .eq('question_id', questionId);
  }

  /// Uploads a diagram/image for a question to the 'question-images' bucket
  /// (see migration 20240301000006) and returns its public URL.
  Future<String> uploadQuestionImage(String fileName, dynamic fileBytes) async {
    final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('question-images').uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
    return _client.storage.from('question-images').getPublicUrl(path);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN: Exam Scheduling
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getBatchTargets() async {
    final response = await _client
        .from('students')
        .select('batch_id')
        .not('batch_id', 'is', null)
        .order('batch_id');

    final seen = <int>{};
    final out = <Map<String, dynamic>>[];
    for (final row in response as List) {
      final batchIdRaw = row['batch_id'];
      final batchId = int.tryParse((batchIdRaw ?? '').toString());
      if (batchId == null || seen.contains(batchId)) continue;
      seen.add(batchId);
      out.add({'id': batchId, 'label': 'Batch #$batchId'});
    }
    return out;
  }

  /// Creates a schedule for a published paper and immediately materializes
  /// its roster (see migration 20240301000004) — the snapshot of who is
  /// expected to attempt it, used later to tell attempted apart from absent.
  Future<void> createExamSchedule({
    required int paperSetId,
    required String title,
    required int durationMinutes,
    required DateTime startAt,
    DateTime? publishAt,
    DateTime? endAt,
    required String assignmentType,
    required String assignmentValue,
    int maxAttempts = 1,
    bool negativeMarkingEnabled = false,
    double marksCorrect = 1.0,
    double marksWrong = 0.0,
    double marksUnanswered = 0.0,
    String? negativeFormula,
  }) async {
    final rawAssignment = assignmentValue.trim();
    if (rawAssignment.isEmpty) {
      throw Exception('An assignment target is required');
    }
    if (assignmentType != 'student' && int.tryParse(rawAssignment) == null) {
      throw Exception('Invalid id for assignment');
    }

    final schedule = await _client
        .from('schedules')
        .insert({
          'paper_id': paperSetId,
          'title': title,
          'status': 'published',
          'publish_at': (publishAt ?? DateTime.now()).toUtc().toIso8601String(),
          'start_at': startAt.toUtc().toIso8601String(),
          'end_at': endAt?.toUtc().toIso8601String(),
          'max_attempts': maxAttempts,
          'negative_marking_enabled': negativeMarkingEnabled,
          'marks_correct': marksCorrect,
          'marks_wrong': marksWrong,
          'marks_unanswered': marksUnanswered,
          'assignment_type': assignmentType,
          'assignment_value': rawAssignment,
          'created_by': _client.auth.currentUser?.id,
        })
        .select('id')
        .single();

    final scheduleId = schedule['id'] as int;
    await _client.rpc('materialize_schedule_roster', params: {'p_schedule_id': scheduleId});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STUDENT: Exam Session
  // ═══════════════════════════════════════════════════════════════════════════

  /// [paperSetId]/[studentId] are kept for call-site compatibility with the
  /// existing quiz screen but are no longer used to resolve identity — the
  /// student is always the current authenticated user, resolved server-side.
  /// Returns `{attempt_id, started_at, resumed, answers}` — `answers` maps
  /// question id -> previously selected option (1-4) or null.
  ///
  /// If an in-progress attempt already exists within its time window (the
  /// student's app crashed / battery died mid-exam), that attempt is
  /// resumed instead of creating a new one — otherwise a crash would
  /// permanently burn a single-attempt exam with no way back in.
  Future<Map<String, dynamic>?> startExamSession({
    required String paperSetId,
    required String studentId,
    String? examScheduleId,
  }) async {
    if (examScheduleId == null || examScheduleId.isEmpty) {
      throw Exception('This exam has no active schedule to attempt');
    }
    final resolvedStudentId = await _currentStudentId();
    if (resolvedStudentId == null) {
      throw Exception('Could not resolve your student record');
    }
    final scheduleId = int.parse(examScheduleId);

    final inProgress = await _client
        .from('attempts')
        .select('id, started_at')
        .eq('student_id', resolvedStudentId)
        .eq('schedule_id', scheduleId)
        .eq('status', 'in_progress')
        .order('attempt_no', ascending: false)
        .limit(1)
        .maybeSingle();

    if (inProgress != null) {
      // Remaining time is computed by the database (attempt_remaining_seconds,
      // migration 20240301000008), not from the device's own clock — a
      // skewed phone clock can no longer cause a premature client-side
      // auto-submit or an incorrect countdown display.
      final remaining = await _client.rpc('attempt_remaining_seconds', params: {'p_attempt_id': inProgress['id']});
      final remainingSeconds = (remaining as num?)?.toInt() ?? 0;
      if (remainingSeconds > 0) {
        final answers = await _client
            .from('attempt_answers')
            .select('question_id, selected_option')
            .eq('attempt_id', inProgress['id']);
        return {
          'attempt_id': inProgress['id'].toString(),
          'remaining_seconds': remainingSeconds,
          'resumed': true,
          'answers': {
            for (final a in (answers as List)) a['question_id'].toString(): a['selected_option'],
          },
        };
      }
    }

    final existing = await _client
        .from('attempts')
        .select('attempt_no')
        .eq('student_id', resolvedStudentId)
        .eq('schedule_id', scheduleId)
        .order('attempt_no', ascending: false)
        .limit(1);
    final attemptNo = (existing as List).isNotEmpty ? (existing.first['attempt_no'] as int) + 1 : 1;

    final response = await _client
        .from('attempts')
        .insert({
          'schedule_id': scheduleId,
          'student_id': resolvedStudentId,
          'attempt_no': attemptNo,
          'status': 'in_progress',
        })
        .select('id')
        .single();

    final remaining = await _client.rpc('attempt_remaining_seconds', params: {'p_attempt_id': response['id']});

    return {
      'attempt_id': response['id']?.toString(),
      'remaining_seconds': (remaining as num?)?.toInt() ?? (0),
      'resumed': false,
      'answers': <String, dynamic>{},
    };
  }

  /// Upserts the student's answer for one question. Safe to call repeatedly
  /// as the student changes their mind before submitting — updates the same
  /// row instead of accumulating duplicates.
  Future<void> submitAnswer({
    required String sessionId,
    required String questionId,
    required String selectedOption, // 'A' | 'B' | 'C' | 'D'
  }) async {
    await _client.from('attempt_answers').upsert({
      'attempt_id': int.parse(sessionId),
      'question_id': int.parse(questionId),
      'selected_option': _charToInt(selectedOption),
    }, onConflict: 'attempt_id,question_id');
  }

  /// Marks the attempt submitted and grades it server-side via
  /// grade_attempt (migration 20240301000004) — no client-side scoring.
  /// Grades the attempt. `submitted_at` is set by grade_attempt itself
  /// (server clock, not the device's). [reason], when non-null, records why
  /// this was an automatic submission (e.g. 'app_switch', 'time_expired')
  /// so an admin reviewing results can tell a flagged auto-submit apart
  /// from a normal one and decide whether it warrants a manual override.
  Future<Map<String, dynamic>?> finishExam(String sessionId, {String? reason}) async {
    final attemptId = int.parse(sessionId);

    await _client.rpc('grade_attempt', params: {'p_attempt_id': attemptId, 'p_reason': reason});

    return await _client
        .from('attempts')
        .select('score, total_marks, result')
        .eq('id', attemptId)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> getMyResults() async {
    final studentId = await _currentStudentId();
    if (studentId == null) return [];

    try {
      final response = await _client
          .from('attempts')
          .select('id, score, total_marks, result, submitted_at, schedules(title, paper_sets(title))')
          .eq('student_id', studentId)
          .eq('status', 'submitted')
          .order('submitted_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN: Schedule Results (attempted / absent / publish to marksheet)
  // ═══════════════════════════════════════════════════════════════════════════

  /// List schedules for the results screen — branch-scoped for branch
  /// admins (via their created papers/branch), unscoped for super admin.
  Future<List<Map<String, dynamic>>> getSchedulesForAdmin() async {
    try {
      final response = await _client
          .from('schedules')
          .select('id, title, start_at, end_at, status, paper_sets(title, assessment_type, total_marks)')
          .order('start_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      try {
        final fallback = await _client
            .from('exam_schedules')
            .select('id, name, start_at, end_at, status, assessment_type')
            .order('start_at', ascending: false);
        return (fallback as List).map((row) {
          final m = Map<String, dynamic>.from(row as Map);
          return {
            'id': m['id'],
            'title': m['name'] ?? 'Exam #${m['id']}',
            'start_at': m['start_at'],
            'end_at': m['end_at'],
            'status': m['status'] ?? 'published',
            'paper_sets': {
              'title': m['name'] ?? 'Exam',
              'assessment_type': m['assessment_type'] ?? 'exam',
              'total_marks': 100,
            }
          };
        }).toList();
      } catch (_) {
        return [];
      }
    }
  }

  /// Roster joined against attempts for one schedule — the raw material for
  /// the Submitted / Started-not-submitted / Absent breakdown.
  Future<List<Map<String, dynamic>>> getScheduleRoster(int scheduleId) async {
    final roster = await _client
        .from('schedule_roster')
        .select('student_id, students(id, name, reg_no)')
        .eq('schedule_id', scheduleId);

    final attempts = await _client
        .from('attempts')
        .select('student_id, score, total_marks, result, started_at, submitted_at, auto_submit_reason')
        .eq('schedule_id', scheduleId)
        .order('attempt_no', ascending: false);

    final attemptByStudent = <int, Map<String, dynamic>>{};
    for (final a in (attempts as List)) {
      final sid = a['student_id'] as int;
      attemptByStudent.putIfAbsent(sid, () => Map<String, dynamic>.from(a));
    }

    return (roster as List).map((r) {
      final student = r['students'] as Map<String, dynamic>? ?? {};
      final attempt = attemptByStudent[r['student_id']];
      String state;
      if (attempt == null) {
        state = 'absent';
      } else if (attempt['submitted_at'] != null) {
        state = 'submitted';
      } else {
        state = 'started';
      }
      return {
        'student_id': r['student_id'],
        'name': student['name'] ?? 'Unknown',
        'reg_no': student['reg_no'] ?? '-',
        'state': state,
        'score': attempt?['score'],
        'total_marks': attempt?['total_marks'],
        'result': attempt?['result'],
        'auto_submit_reason': attempt?['auto_submit_reason'],
      };
    }).toList();
  }

  /// Pushes every submitted attempt's score into the manual marksheet table
  /// (exam_results) so it shows up in the student's existing "My Results"
  /// screen alongside manually entered subject marks.
  /// [markAbsentees]: if true, absent students get an 'AB' grade row with no
  /// numeric marks instead of being skipped.
  /// Idempotent: uses `schedule_id` as the upsert conflict target (see
  /// migration 20240301000007's partial unique index), so re-publishing —
  /// a double tap, or a deliberate re-run after a makeup test — updates
  /// the existing row for each student instead of inserting a duplicate.
  /// Also a single batched upsert rather than one round-trip per student,
  /// so a dropped connection partway through can't leave some students
  /// published and others not from the same click.
  Future<int> publishScheduleResults(int scheduleId, {bool markAbsentees = false}) async {
    final schedule = await _client
        .from('schedules')
        .select('title, paper_sets(title, total_marks)')
        .eq('id', scheduleId)
        .single();
    final paper = schedule['paper_sets'] as Map<String, dynamic>? ?? {};
    final examName = schedule['title'] as String? ?? 'Test';
    final subjectName = paper['title'] as String? ?? 'Paper';
    final totalMarks = (paper['total_marks'] as num?)?.toDouble() ?? 100;

    final roster = await getScheduleRoster(scheduleId);
    final rowsToPublish = <Map<String, dynamic>>[];

    for (final row in roster) {
      if (row['state'] == 'submitted') {
        final score = (row['score'] as num?)?.toDouble() ?? 0;
        final total = (row['total_marks'] as num?)?.toDouble() ?? totalMarks;
        final pct = total > 0 ? (score / total) * 100 : 0.0;
        rowsToPublish.add({
          'student_id': row['student_id'],
          'schedule_id': scheduleId,
          'subject_name': subjectName,
          'exam_name': examName,
          'marks_obtained': score,
          'total_marks': total,
          'grade': _gradeFor(pct),
        });
      } else if (row['state'] == 'absent' && markAbsentees) {
        rowsToPublish.add({
          'student_id': row['student_id'],
          'schedule_id': scheduleId,
          'subject_name': subjectName,
          'exam_name': examName,
          'marks_obtained': 0,
          'total_marks': totalMarks,
          'grade': 'AB',
          'notes': 'Absent',
        });
      }
    }

    if (rowsToPublish.isEmpty) return 0;
    await _client.from('exam_results').upsert(rowsToPublish, onConflict: 'student_id,schedule_id');
    return rowsToPublish.length;
  }

  /// Re-runs roster materialization for a schedule — picks up students who
  /// enrolled into the assigned course/batch/branch after the schedule was
  /// first created. Safe to call repeatedly (ON CONFLICT DO NOTHING).
  Future<void> refreshScheduleRoster(int scheduleId) async {
    await _client.rpc('materialize_schedule_roster', params: {'p_schedule_id': scheduleId});
  }

  String _gradeFor(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B';
    if (pct >= 60) return 'C';
    if (pct >= 33) return 'D';
    return 'F';
  }

  int _charToInt(String char) {
    switch (char.toUpperCase()) {
      case 'A': return 1;
      case 'B': return 2;
      case 'C': return 3;
      case 'D': return 4;
      default: return 1;
    }
  }

  String _intToChar(dynamic val) {
    if (val is! int) return 'A';
    switch (val) {
      case 1: return 'A';
      case 2: return 'B';
      case 3: return 'C';
      case 4: return 'D';
      default: return 'A';
    }
  }
}
