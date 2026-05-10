import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/exam_model.dart';

final examRepositoryProvider = Provider((ref) {
  return ExamRepository(Supabase.instance.client);
});

final adminPaperSetsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.read(examRepositoryProvider);
  return repo.getAdminPaperSets();
});

final adminBatchTargetsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.read(examRepositoryProvider);
  return repo.getBatchTargets();
});

class ExamRepository {
  final SupabaseClient _client;

  ExamRepository(this._client);

  /// Get available paper sets (exams) for a course
  Future<List<Exam>> getExams({int? courseId}) async {
    final userId = _client.auth.currentUser?.id;

    if (userId != null) {
      try {
        final student = await _client
            .from('students')
            .select('id, course_id, batch_id, branch_id')
            .eq('id', userId)
            .maybeSingle();

        final courseIdDynamic = student?['course_id'];
        final batchIdDynamic = student?['batch_id'];
        final branchIdDynamic = student?['branch_id'];

        final filters = <String>[
          'and(assignment_type.eq.student,student_id.eq.$userId)',
        ];
        if (courseIdDynamic != null) {
          filters.add(
            'and(assignment_type.eq.course,course_id.eq.$courseIdDynamic)',
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
                  'id': e['paper_set_id'].toString(),
                  'schedule_id': e['exam_schedule_id']?.toString(),
                  'title': e['title'] ?? 'Exam',
                  'duration_minutes': e['duration_minutes'] ?? 60,
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
        // Fallback to legacy paper_sets query below.
      }
    }

    var fallbackQuery = _client
        .from('paper_sets')
        .select('*, courses(title)')
        .eq('is_active', true);

    if (courseId != null) {
      fallbackQuery = fallbackQuery.eq('course_id', courseId);
    }

    final fallbackResponse = await fallbackQuery.order(
      'created_at',
      ascending: false,
    );

    return (fallbackResponse as List)
        .map(
          (e) => Exam.fromJson({
            'id': e['id'].toString(),
            'title': e['title'] ?? e['courses']?['title'] ?? 'Exam',
            'duration_minutes': e['duration_minutes'] ?? 60,
            'total_marks': e['total_marks'] ?? 100,
            'questions_count': e['total_questions'] ?? 0,
          }),
        )
        .toList();
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
          .eq('paper_set_id', int.parse(exam.id));
      if ((attempts as List).isNotEmpty) {
        return {'allowed': false, 'reason': 'Already attempted'};
      }
    }

    return {'allowed': true};
  }

  /// Get questions for a paper set
  Future<List<Question>> getQuestions(String paperSetId) async {
    final response = await _client
        .from('questions')
        .select()
        .eq('paper_set_id', int.parse(paperSetId))
        .order('question_number');

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
            'correct_option_index': _optionToIndex(e['correct_option']),
          }),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAdminPaperSets() async {
    final response = await _client
        .from('paper_sets')
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
    int? courseId;
    int? batchId;
    int? branchId;
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
          'paper_set_id': paperSetId,
          'title': title,
          'status': 'published',
          'publish_at': (publishAt ?? DateTime.now()).toUtc().toIso8601String(),
          'start_at': startAt.toUtc().toIso8601String(),
          'duration_minutes': durationMinutes,
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
      'course_id': courseId,
      'batch_id': batchId,
      'branch_id': branchId,
    });
  }

  /// Start an exam session
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
          'paper_set_id': int.parse(paperSetId),
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

  /// Submit an answer
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

  /// Finish an exam session
  Future<Map<String, dynamic>?> finishExam(String sessionId) async {
    // Update session status
    await _client
        .from('exam_sessions')
        .update({
          'finished_at': DateTime.now().toIso8601String(),
          'status': 'completed',
        })
        .eq('id', int.parse(sessionId));

    // Calculate and return results
    final result = await _client
        .from('exam_results')
        .select()
        .eq('session_id', int.parse(sessionId))
        .maybeSingle();

    return result;
  }

  /// Get student's past exam results
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

  int _optionToIndex(String? option) {
    switch (option?.toUpperCase()) {
      case 'A':
        return 0;
      case 'B':
        return 1;
      case 'C':
        return 2;
      case 'D':
        return 3;
      default:
        return 0;
    }
  }
}
