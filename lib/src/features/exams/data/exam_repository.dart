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
  (ref) async => ref.read(examRepositoryProvider).getExamResults(),
);

class ExamRepository {
  final SupabaseClient _client;

  ExamRepository(this._client);

  // ═══════════════════════════════════════════════════════════════════════════
  // STUDENT: View Exams
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get available paper sets (exams) for the logged-in student.
  Future<List<Exam>> getExams({int? branchId}) async {
    final userId = _client.auth.currentUser?.id;

    if (userId != null) {
      try {
        final student = await _client
            .from('students')
            .select('id, branch_id, batch_id, branch_id')
            .eq('profile_id', userId)
            .maybeSingle();

        final branchIdDynamic = student?['branch_id'];
        final batchIdDynamic = student?['batch_id'];

        final filters = <String>[
          'and(assignment_type.eq.student,student_id.eq.$userId)',
        ];
        if (branchIdDynamic != null) {
          filters.add(
            'and(assignment_type.eq.course,branch_id.eq.$branchIdDynamic)',
          );
        }
        if (batchIdDynamic != null) {
          filters.add(
            'and(assignment_type.eq.batch,batch_id.eq.$batchIdDynamic)',
          );
        }
        if (branchIdDynamic != null) {
          filters.add(
            'and(assignment_type.eq.branch,branch_id.eq.$branchIdDynamic)',
          );
        }

        final visibleResponse = await _client
            .from('v_student_visible_exams')
            .select()
            .or(filters.join(','))
            .order('start_at', ascending: true);

        if (visibleResponse.isNotEmpty) {
          return (visibleResponse as List)
              .map(
                (e) => Exam.fromJson({
                  'id': e['category_id'].toString(),
                  'schedule_id': e['exam_schedule_id']?.toString(),
                  'name': e['name'] ?? 'Exam',
                  'time_limit': e['time_limit'] ?? 60,
                  'total_marks': e['total_marks'] ?? 100,
                  'questions_count': e['total_questions'] ?? 0,
                  'max_attempts': e['max_attempts'] ?? 1,
                  'shuffle_options': e['shuffle_options'] == true,
                  'negative_marking_enabled':
                      e['negative_marking_enabled'] == true,
                }),
              )
              .toList();
        }
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> canStartExam(Exam exam) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return {'allowed': false, 'reason': 'Login required'};
    }

    final scheduleId = exam.scheduleId;
    if (scheduleId != null && scheduleId.isNotEmpty) {
      final schedule = await _client
          .from('exam_schedules')
          .select('id, start_at, end_at, status, max_attempts')
          .eq('id', int.parse(scheduleId))
          .maybeSingle();

      if (schedule == null) {
        return {'allowed': false, 'reason': 'Exam schedule not found'};
      }

      final now = DateTime.now().toUtc();
      final startAt = DateTime.tryParse(
        (schedule['start_at'] ?? '').toString(),
      )?.toUtc();
      final endAt = DateTime.tryParse(
        (schedule['end_at'] ?? '').toString(),
      )?.toUtc();
      final status = (schedule['status'] ?? '').toString().toLowerCase();

      if (!(status == 'published' || status == 'scheduled')) {
        return {'allowed': false, 'reason': 'Exam not published'};
      }
      if (startAt != null && now.isBefore(startAt)) {
        return {'allowed': false, 'reason': 'Exam has not started yet'};
      }
      if (endAt != null && now.isAfter(endAt)) {
        return {'allowed': false, 'reason': 'Exam window is closed'};
      }

      final maxAttempts =
          int.tryParse((schedule['max_attempts'] ?? 1).toString()) ?? 1;
      final attempts = await _client
          .from('exam_sessions')
          .select('id')
          .eq('student_id', userId)
          .eq('exam_schedule_id', int.parse(scheduleId));

      if ((attempts as List).length >= maxAttempts) {
        return {'allowed': false, 'reason': 'Attempt limit reached'};
      }
    } else {
      final attempts = await _client
          .from('exam_sessions')
          .select('id')
          .eq('student_id', userId)
          .eq('category_id', int.parse(exam.id));
      if ((attempts as List).isNotEmpty) {
        return {'allowed': false, 'reason': 'Already attempted'};
      }
    }

    return {'allowed': true};
  }

  /// Get questions for a paper set
  Future<List<Question>> getQuestions(String paperSetId) async {
    final response = await _client
        .from('exam_questions')
        .select()
        .eq('category_id', int.parse(paperSetId))
        .order('id');

    return (response as List)
        .map(
          (e) => Question.fromJson({
            'id': e['id'].toString(),
            'text': e['question_text'] ?? '',
            'options': [
              e['option_a'] ?? '',
              e['option_b'] ?? '',
              e['option_c'] ?? '',
              e['option_d'] ?? '',
            ],
            'correct_option_index': (e['correct_option'] as int? ?? 1) - 1,
          }),
        )
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN: Paper Set Management (Super Admin / Branch Admin)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all paper sets for admin management view
  Future<List<Map<String, dynamic>>> getAdminPaperSets() async {
    final response = await _client
        .from('exam_categories')
        .select('id, name, total_marks, time_limit, total_questions, status, created_at, branches(name)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new paper set (exam paper)
  /// Returns the created paper_set ID
  Future<int> createPaperSet({
    required String title,
    required int durationMinutes,
    required int totalMarks,
    int? branchId,
    int? courseId,
    bool isActive = false, // Draft by default until questions are added
  }) async {
    final response = await _client
        .from('exam_categories')
        .insert({
          'name': title,
          'time_limit': durationMinutes,
          'total_marks': totalMarks,
          'total_questions': 0,
          'branch_id': branchId,
          'course_id': courseId,
          'status': isActive ? 1 : 0,
          'created_by': _client.auth.currentUser?.id,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return response['id'] as int;
  }

  /// Update paper set metadata
  Future<void> updatePaperSet({
    required int paperSetId,
    String? title,
    int? durationMinutes,
    int? totalMarks,
    int? branchId,
    int? courseId,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['name'] = title;
    if (durationMinutes != null) updates['time_limit'] = durationMinutes;
    if (totalMarks != null) updates['total_marks'] = totalMarks;
    if (branchId != null) updates['branch_id'] = branchId;
    if (courseId != null) updates['course_id'] = courseId;
    if (isActive != null) updates['status'] = isActive ? 1 : 0;

    await _client.from('exam_categories').update(updates).eq('id', paperSetId);
  }

  /// Delete a paper set (also deletes all questions via cascade)
  Future<void> deletePaperSet(int paperSetId) async {
    await _client.from('exam_categories').delete().eq('id', paperSetId);
  }

  /// Publish/unpublish a paper set
  Future<void> togglePaperSetStatus(int paperSetId, bool isActive) async {
    await _client
        .from('exam_categories')
        .update({'status': isActive ? 1 : 0})
        .eq('id', paperSetId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN: Question Management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all questions for a paper set (admin view — includes correct answer)
  Future<List<Map<String, dynamic>>> getAdminQuestions(int paperSetId) async {
    final response = await _client
        .from('exam_questions')
        .select('id, question_text, option_a, option_b, option_c, option_d, correct_option, marks')
        .eq('category_id', paperSetId)
        .order('id');

    return (response as List).map((q) {
      final map = Map<String, dynamic>.from(q);
      map['correct_option'] = _intToChar(map['correct_option']);
      return map;
    }).toList();
  }

  /// Add a single MCQ question to a paper set
  Future<void> addQuestion({
    required int paperSetId,
    required String questionText,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required String correctOption, // 'A', 'B', 'C', or 'D'
    double marks = 1.0,
  }) async {
    // Get current question count to set question_number
    final existing = await _client
        .from('exam_questions')
        .select('id')
        .eq('category_id', paperSetId);
    final nextNum = (existing as List).length + 1;

    await _client.from('exam_questions').insert({
      'category_id': paperSetId,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': _charToInt(correctOption),
      'marks': marks,
    });

    // Update total_questions count on paper_set
    await _client
        .from('exam_categories')
        .update({'total_questions': nextNum})
        .eq('id', paperSetId);
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
  }) async {
    await _client.from('exam_questions').update({
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': _charToInt(correctOption),
      'marks': marks,
    }).eq('id', questionId);
  }

  /// Delete a question and renumber remaining
  Future<void> deleteQuestion(int questionId, int paperSetId) async {
    await _client.from('exam_questions').delete().eq('id', questionId);

    // Recount and update total_questions
    final remaining = await _client
        .from('exam_questions')
        .select('id')
        .eq('category_id', paperSetId);
    await _client
        .from('exam_categories')
        .update({'total_questions': (remaining as List).length})
        .eq('id', paperSetId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN: Exam Scheduling
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAdminPaperSetsSimple() async {
    final response = await _client
        .from('exam_categories')
        .select('id, title')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

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

  Future<void> createExamSchedule({
    required int paperSetId,
    required String title,
    required int durationMinutes,
    required DateTime startAt,
    DateTime? publishAt,
    required String assignmentType,
    required String assignmentValue,
    int maxAttempts = 1,
    bool negativeMarkingEnabled = false,
    double marksCorrect = 1.0,
    double marksWrong = 0.0,
    double marksUnanswered = 0.0,
    String? negativeFormula,
  }) async {
    int? branchId;
    int? batchId;
    int? courseId;
    String? studentId;
    final rawAssignment = assignmentValue.trim();

    switch (assignmentType) {
      case 'course':
        courseId = int.tryParse(rawAssignment);
        if (courseId == null || courseId <= 0) {
          throw Exception('Invalid course id for assignment');
        }
        break;
      case 'batch':
        batchId = int.tryParse(rawAssignment);
        if (batchId == null || batchId <= 0) {
          throw Exception('Invalid batch id for assignment');
        }
        break;
      case 'branch':
        branchId = int.tryParse(rawAssignment);
        if (branchId == null || branchId <= 0) {
          throw Exception('Invalid branch id for assignment');
        }
        break;
      default:
        if (rawAssignment.isEmpty) {
          throw Exception('Student id is required for student assignment');
        }
        studentId = rawAssignment;
    }

    final schedule = await _client
        .from('exam_schedules')
        .insert({
          'category_id': paperSetId,
          'name': title,
          'status': 'published',
          'publish_at': (publishAt ?? DateTime.now()).toUtc().toIso8601String(),
          'start_at': startAt.toUtc().toIso8601String(),
          'time_limit': durationMinutes,
          'max_attempts': maxAttempts,
          'shuffle_questions': true,
          'shuffle_options': true,
          'negative_marking_enabled': negativeMarkingEnabled,
          'marks_correct': marksCorrect,
          'marks_wrong': marksWrong,
          'marks_unanswered': marksUnanswered,
          'negative_formula': negativeFormula,
          'created_by': _client.auth.currentUser?.id,
        })
        .select('id')
        .single();

    final scheduleId = schedule['id'] as int;

    await _client.from('exam_assignments').insert({
      'exam_schedule_id': scheduleId,
      'assignment_type': assignmentType,
      'student_id': studentId,
      'branch_id': branchId,
      'batch_id': batchId,
      'course_id': courseId,
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STUDENT: Exam Session
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> startExamSession({
    required String paperSetId,
    required String studentId,
    String? examScheduleId,
  }) async {
    int attemptNo = 1;
    if (examScheduleId != null && examScheduleId.isNotEmpty) {
      final existing = await _client
          .from('exam_sessions')
          .select('id')
          .eq('student_id', studentId)
          .eq('exam_schedule_id', int.parse(examScheduleId));
      attemptNo = (existing as List).length + 1;
    }

    final response = await _client
        .from('exam_sessions')
        .insert({
          'category_id': int.parse(paperSetId),
          'student_id': studentId,
          'exam_schedule_id': examScheduleId == null || examScheduleId.isEmpty
              ? null
              : int.parse(examScheduleId),
          'attempt_no': attemptNo,
          'started_at': DateTime.now().toIso8601String(),
          'status': 'in_progress',
        })
        .select('id')
        .single();

    return response['id']?.toString();
  }

  Future<void> submitAnswer({
    required String sessionId,
    required String questionId,
    required String selectedOption,
  }) async {
    await _client.from('exam_answers').upsert({
      'session_id': int.parse(sessionId),
      'question_id': int.parse(questionId),
      'selected_option': selectedOption,
      'answered_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> finishExam(String sessionId) async {
    await _client
        .from('exam_sessions')
        .update({
          'finished_at': DateTime.now().toIso8601String(),
          'status': 'completed',
        })
        .eq('id', int.parse(sessionId));

    final result = await _client
        .from('exam_results')
        .select()
        .eq('session_id', int.parse(sessionId))
        .maybeSingle();

    return result;
  }

  Future<List<Map<String, dynamic>>> getMyResults() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('exam_sessions')
        .select('*, paper_sets(title, total_marks), exam_results(*)')
        .eq('student_id', userId)
        .eq('status', 'completed')
        .order('finished_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUpcomingExams() async {
    try {
      final response = await _client
          .from('exam_schedules')
          .select('*, paper_sets(*), courses(*)')
          .order('start_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getExamResults() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await _client
          .from('exam_results')
          .select('*, exam_sessions!inner(*, paper_sets(*))')
          .order('calculated_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
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
