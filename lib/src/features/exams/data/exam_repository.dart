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

  /// Resolves the current auth user to every `students.id` they're linked
  /// to (the INT primary key everything in this feature is keyed on —
  /// schedules, rosters, attempts). Two hops: auth user -> profiles.id ->
  /// students.id — but a profile can have more than one students row (one
  /// per course enrollment, see link_sibling_student_enrollments,
  /// migration 20240301000024), so this returns every linked id, not one.
  Future<List<int>> _currentStudentIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final profile = await _client
        .from('profiles')
        .select('id')
        .eq('auth_uid', user.id)
        .maybeSingle();
    if (profile == null) return [];

    final students = await _client
        .from('students')
        .select('id')
        .eq('profile_id', profile['id']);
    return List<Map<String, dynamic>>.from(students)
        .map((s) => s['id'] as int)
        .toList();
  }

  /// Resolves which ONE of the caller's linked enrollment ids is actually
  /// on a given schedule's roster — used wherever an action must attribute
  /// to a single correct enrollment (starting an exam, counting attempts
  /// against THAT enrollment specifically), never "any of my ids".
  Future<int?> _rosterStudentId(int scheduleId) async {
    final ids = await _currentStudentIds();
    if (ids.isEmpty) return null;

    final row = await _client
        .from('schedule_roster')
        .select('student_id')
        .eq('schedule_id', scheduleId)
        .inFilter('student_id', ids)
        .maybeSingle();
    if (row != null && row['student_id'] != null) {
      return row['student_id'] as int;
    }

    // Fallback: If not explicitly in roster yet, check if student qualifies by course/branch or student ID
    try {
      final sched = await _client.from('schedules').select('assignment_type, assignment_value').eq('id', scheduleId).maybeSingle();
      if (sched != null) {
        final type = sched['assignment_type']?.toString();
        final val = sched['assignment_value']?.toString();
        bool isTargeted = false;

        if (type == 'student' && ids.map((i) => i.toString()).contains(val)) {
          isTargeted = true;
        } else if (type == 'course' || type == 'branch' || type == 'batch') {
          final studentRows = await _client.from('students').select('id, course_id, branch_id, batch_id').inFilter('id', ids);
          for (final s in (studentRows as List)) {
            if (type == 'course' && s['course_id']?.toString() == val) isTargeted = true;
            if (type == 'branch' && s['branch_id']?.toString() == val) isTargeted = true;
            if (type == 'batch' && s['batch_id']?.toString() == val) isTargeted = true;
          }
        }

        if (isTargeted) {
          final sid = ids.first;
          await _client.from('schedule_roster').insert({'schedule_id': scheduleId, 'student_id': sid});
          return sid;
        }
      }
    } catch (_) {}

    return ids.first;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STUDENT: View Exams
  // ═══════════════════════════════════════════════════════════════════════════

  /// All schedules the logged-in student is on the roster for (test + exam),
  /// regardless of whether their window is currently open.
  Future<List<Map<String, dynamic>>> getUpcomingExams() async {
    final studentIds = await _currentStudentIds();
    if (studentIds.isEmpty) return [];

    try {
      // 1. Fetch schedules the student is rostered for, including assignment info
      final rosterRows = await _client
          .from('schedule_roster')
          .select('schedules(id, paper_id, title, start_at, end_at, status, max_attempts, assignment_type, assignment_value)')
          .inFilter('student_id', studentIds);

      final scheduleList = <Map<String, dynamic>>[];
      final paperIds = <int>{};

      for (final r in (rosterRows as List)) {
        final sched = r['schedules'] as Map<String, dynamic>?;
        if (sched != null) {
          final copy = Map<String, dynamic>.from(sched);
          scheduleList.add(copy);
          final pId = copy['paper_id'];
          if (pId is int) paperIds.add(pId);
        }
      }

      if (scheduleList.isEmpty) return [];

      // 2. Fetch student's own enrolled course IDs as reliable fallback
      final studentCourseIds = <int>{};
      try {
        final studentRows = await _client
            .from('students')
            .select('course_id')
            .inFilter('id', studentIds);
        for (final st in (studentRows as List)) {
          final cid = st['course_id'];
          if (cid is int) {
            studentCourseIds.add(cid);
          } else if (cid != null) {
            final parsed = int.tryParse(cid.toString());
            if (parsed != null) studentCourseIds.add(parsed);
          }
        }
      } catch (_) {}

      // 3. Fetch paper_sets details without embedding courses(name)
      // (avoiding PostgREST relationship errors since paper_sets has no FK to courses)
      final paperMap = <int, Map<String, dynamic>>{};
      if (paperIds.isNotEmpty) {
        try {
          final paperRows = await _client
              .from('paper_sets')
              .select('id, title, name, assessment_type, total_marks, duration_minutes, course_id')
              .inFilter('id', paperIds.toList());
          for (final p in (paperRows as List)) {
            paperMap[p['id'] as int] = Map<String, dynamic>.from(p as Map);
          }
        } catch (_) {}

        // Count questions per paper
        try {
          final pqRows = await _client
              .from('paper_questions')
              .select('paper_id, question_id')
              .inFilter('paper_id', paperIds.toList());
          final countMap = <int, int>{};
          for (final pq in (pqRows as List)) {
            final pid = pq['paper_id'] as int?;
            if (pid != null) {
              countMap[pid] = (countMap[pid] ?? 0) + 1;
            }
          }
          for (final entry in paperMap.entries) {
            entry.value['questions_count'] = countMap[entry.key] ?? 0;
          }
        } catch (_) {}
      }

      // 4. Collect all distinct course IDs and batch fetch their names
      final allCourseIds = <int>{...studentCourseIds};
      for (final p in paperMap.values) {
        final cid = p['course_id'];
        if (cid is int) {
          allCourseIds.add(cid);
        } else if (cid != null) {
          final parsed = int.tryParse(cid.toString());
          if (parsed != null) allCourseIds.add(parsed);
        }
      }
      for (final s in scheduleList) {
        if (s['assignment_type']?.toString().toLowerCase() == 'course') {
          final parsed = int.tryParse(s['assignment_value']?.toString() ?? '');
          if (parsed != null) allCourseIds.add(parsed);
        }
      }

      final courseMap = <int, String>{};
      if (allCourseIds.isNotEmpty) {
        try {
          final courseRows = await _client
              .from('courses')
              .select('id, name, short_name')
              .inFilter('id', allCourseIds.toList());
          for (final c in (courseRows as List)) {
            final cid = c['id'] as int;
            final cname = (c['name'] ?? c['short_name'] ?? '').toString().trim();
            if (cname.isNotEmpty) {
              courseMap[cid] = cname;
            }
          }
        } catch (_) {}
      }

      String? defaultCourseName;
      for (final cid in studentCourseIds) {
        if (courseMap.containsKey(cid)) {
          defaultCourseName = courseMap[cid];
          break;
        }
      }

      // 5. Merge paper sets, attach normalized course name & assessment_type
      for (final s in scheduleList) {
        final pid = s['paper_id'] as int?;
        final paper = paperMap[pid] ?? {
          'id': pid,
          'title': s['title'],
          'assessment_type': 'exam',
          'total_marks': 100,
          'duration_minutes': 60,
          'questions_count': 0,
        };

        String? resolvedCourseName;
        final paperCourseId = paper['course_id'] is int
            ? paper['course_id'] as int
            : int.tryParse(paper['course_id']?.toString() ?? '');
        if (paperCourseId != null && courseMap.containsKey(paperCourseId)) {
          resolvedCourseName = courseMap[paperCourseId];
        } else if (s['assignment_type']?.toString().toLowerCase() == 'course') {
          final schedCourseId = int.tryParse(s['assignment_value']?.toString() ?? '');
          if (schedCourseId != null && courseMap.containsKey(schedCourseId)) {
            resolvedCourseName = courseMap[schedCourseId];
          }
        }
        resolvedCourseName ??= defaultCourseName ?? 'General';

        paper['course_name'] = resolvedCourseName;
        paper['courses'] = {'name': resolvedCourseName, 'short_name': resolvedCourseName};
        s['course_name'] = resolvedCourseName;
        s['paper_sets'] = paper;
        s['assessment_type'] = paper['assessment_type'] ?? 'exam';
      }

      scheduleList.sort(
        (a, b) => (a['start_at'] ?? '').toString().compareTo((b['start_at'] ?? '').toString()),
      );
      return scheduleList;
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
    final studentIds = await _currentStudentIds();
    if (studentIds.isEmpty) {
      return {'allowed': false, 'reason': 'Login required'};
    }

    final scheduleId = exam.scheduleId;
    if (scheduleId == null || scheduleId.isEmpty) {
      return {'allowed': false, 'reason': 'This paper has not been scheduled'};
    }

    // Attempt counting must be scoped to whichever ONE of the student's
    // enrollments is actually on this schedule's roster — not any of
    // their ids — so attempts stay correctly attributed per enrollment,
    // matching startExamSession()'s own attribution.
    final rosterStudentId = await _rosterStudentId(int.parse(scheduleId));
    if (rosterStudentId == null) {
      return {'allowed': false, 'reason': 'You are not on the roster for this exam'};
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
        .eq('student_id', rosterStudentId)
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

    dynamic rows;
    try {
      rows = await _client
          .from('question_bank')
          .select('id, question_text, option_a, option_b, option_c, option_d, image_url')
          .inFilter('id', orderedIds);
    } catch (_) {
      try {
        rows = await _client
            .from('question_bank_public')
            .select('id, question_text, option_a, option_b, option_c, option_d, image_url')
            .inFilter('id', orderedIds);
      } catch (_) {
        return [];
      }
    }

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
    List<dynamic> response;
    try {
      response = await _client
          .from('paper_sets')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      try {
        response = await _client
            .from('papers')
            .select()
            .order('created_at', ascending: false)
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        return [];
      }
    }

    final paperIds = response.map((p) => p['id']).whereType<int>().toList();
    final counts = <int, int>{};

    if (paperIds.isNotEmpty) {
      try {
        final pq = await _client
            .from('paper_questions')
            .select('paper_id')
            .inFilter('paper_id', paperIds);
        for (final row in pq as List) {
          final pid = row['paper_id'] as int?;
          if (pid != null) counts[pid] = (counts[pid] ?? 0) + 1;
        }
      } catch (_) {}

      try {
        final eq = await _client
            .from('exam_questions')
            .select('category_id')
            .inFilter('category_id', paperIds);
        for (final row in eq as List) {
          final pid = row['category_id'] as int?;
          if (pid != null && !counts.containsKey(pid)) {
            counts[pid] = (counts[pid] ?? 0) + 1;
          }
        }
      } catch (_) {}
    }

    return response.map((p) {
      final map = Map<String, dynamic>.from(p as Map);
      final id = map['id'] as int?;
      map['title'] = map['title'] ?? map['name'] ?? map['description'] ?? 'Paper Set #${id ?? ''}';
      map['duration_minutes'] = map['duration_minutes'] ?? 60;
      map['total_marks'] = map['total_marks'] ?? 100;
      map['assessment_type'] = map['assessment_type'] ?? 'exam';
      map['status'] = map['status'] ?? 'published';
      map['total_questions'] = (id != null ? counts[id] : null) ?? 0;
      return map;
    }).toList();
  }

  /// Create a new paper (question paper shell — questions added afterwards)
  /// Returns the created paper's ID
  /// Subjects for one course, for the Course → Subject cascade in the
  /// create-paper dialog.
  Future<List<Map<String, dynamic>>> getSubjectsForCourse(int courseId) async {
    final response = await _client
        .from('subjects')
        .select('id, name, code')
        .eq('course_id', courseId)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> createPaperSet({
    required String title,
    required int durationMinutes,
    required int totalMarks,
    required String assessmentType, // 'test' or 'exam'
    int? branchId,
    int? courseId,
    int? subjectId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    Map<String, dynamic> response;
    try {
      response = await _client
          .from('paper_sets')
          .insert({
            'title': title,
            'name': title,
            'description': "$assessmentType - $durationMinutes mins ($totalMarks marks)",
            'assessment_type': assessmentType,
            'duration_minutes': durationMinutes,
            'total_marks': totalMarks,
            'branch_id': branchId,
            'course_id': courseId,
            'subject_id': subjectId,
            'status': 'published',
            if (userId != null) 'created_by': userId,
          })
          .select('id')
          .single();
    } catch (_) {
      try {
        response = await _client
            .from('paper_sets')
            .insert({
              'name': title,
              'description': "$assessmentType - $durationMinutes mins ($totalMarks marks)",
              'subject_id': subjectId,
              if (userId != null) 'created_by': userId,
            })
            .select('id')
            .single();
      } catch (_) {
        response = await _client
            .from('paper_sets')
            .insert({
              'title': title,
              'assessment_type': assessmentType,
              'duration_minutes': durationMinutes,
              'total_marks': totalMarks,
              'branch_id': branchId,
              'course_id': courseId,
              'subject_id': subjectId,
              'status': 'published',
              if (userId != null) 'created_by': userId,
            })
            .select('id')
            .single();
      }
    }

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
    try {
      await _client
          .from('paper_sets')
          .update({'status': isActive ? 'published' : 'draft'})
          .eq('id', paperSetId);
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN: Question Management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all questions for a paper (admin view — includes correct answer)
  Future<List<Map<String, dynamic>>> getAdminQuestions(int paperSetId) async {
    try {
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
    } catch (_) {
      try {
        final legacy = await _client
            .from('exam_questions')
            .select()
            .eq('category_id', paperSetId)
            .order('id');
        return (legacy as List).map((row) {
          final q = Map<String, dynamic>.from(row as Map);
          q['correct_option'] = _intToChar(q['correct_option']);
          q['difficulty'] = q['difficulty'] ?? 'medium';
          q['marks'] = (q['marks'] as num?)?.toDouble() ?? 1.0;
          return q;
        }).toList();
      } catch (_) {
        return [];
      }
    }
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
    try {
      int? courseId;
      try {
        final paper = await _client
            .from('paper_sets')
            .select('course_id')
            .eq('id', paperSetId)
            .maybeSingle();
        courseId = paper?['course_id'] as int?;
      } catch (_) {}

      final question = await _client
          .from('question_bank')
          .insert({
            if (courseId != null) 'course_id': courseId,
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
    } catch (e) {
      // Fallback: save to exam_questions if modern tables are missing
      await _client.from('exam_questions').insert({
        'category_id': paperSetId,
        'question_text': questionText,
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'correct_option': _charToInt(correctOption),
        'marks': marks.toInt(),
      });
    }
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
    try {
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
    } catch (_) {
      await _client.from('exam_questions').update({
        'question_text': questionText,
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'correct_option': _charToInt(correctOption),
        'marks': marks.toInt(),
      }).eq('id', questionId);
    }
  }

  /// Remove a question from a paper. The question_bank row itself is left
  /// alone (it may be reused by other papers) — only the link is deleted.
  Future<void> deleteQuestion(int questionId, int paperSetId) async {
    try {
      await _client
          .from('paper_questions')
          .delete()
          .eq('paper_id', paperSetId)
          .eq('question_id', questionId);
    } catch (_) {}
    try {
      await _client.from('exam_questions').delete().eq('id', questionId);
    } catch (_) {}
  }

  /// Uploads a diagram/image for a question to the 'question-images' bucket
  /// (see migration 20240301000006) and returns its public URL.
  Future<String> uploadQuestionImage(String fileName, dynamic fileBytes) async {
    final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    try {
      await _client.storage.from('question-images').uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _client.storage.from('question-images').getPublicUrl(path);
    } catch (_) {
      // Resilient fallback to verified existing 'avatars' bucket
      final fallbackPath = 'questions/$path';
      await _client.storage.from('avatars').uploadBinary(
            fallbackPath,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _client.storage.from('avatars').getPublicUrl(fallbackPath);
    }
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

    try {
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
      try {
        await _client.rpc('materialize_schedule_roster', params: {'p_schedule_id': scheduleId});
      } catch (_) {}
    } catch (e) {
      // Fallback: save to legacy exam_schedules
      await _client.from('exam_schedules').insert({
        'category_id': paperSetId,
        'name': title,
        'status': 'published',
        'publish_at': (publishAt ?? DateTime.now()).toUtc().toIso8601String(),
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': endAt?.toUtc().toIso8601String(),
        'time_limit': durationMinutes,
        'max_attempts': maxAttempts,
        'negative_marking_enabled': negativeMarkingEnabled,
        'marks_correct': marksCorrect,
        'marks_wrong': marksWrong,
        'marks_unanswered': marksUnanswered,
        'created_by': _client.auth.currentUser?.id,
      });
    }
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
    final scheduleId = int.parse(examScheduleId);

    // Must be the specific enrollment this schedule's roster lists — a
    // student with two enrollments could otherwise have this attempt
    // attributed to the wrong one, since _currentStudentIds() returns
    // every linked id, not just the one relevant here.
    final resolvedStudentId = await _rosterStudentId(scheduleId);
    if (resolvedStudentId == null) {
      throw Exception('Could not resolve your student record');
    }

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
      int remainingSeconds = 3600;
      try {
        final remaining = await _client.rpc('attempt_remaining_seconds', params: {'p_attempt_id': inProgress['id']});
        if (remaining is num) remainingSeconds = remaining.toInt();
      } catch (_) {
        try {
          final startedAt = DateTime.tryParse(inProgress['started_at']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc();
          final elapsed = DateTime.now().toUtc().difference(startedAt).inSeconds;
          int durationMins = 60;
          final sched = await _client.from('schedules').select('paper_id').eq('id', scheduleId).maybeSingle();
          final pid = sched?['paper_id'] as int?;
          if (pid != null) {
            final p = await _client.from('paper_sets').select('duration_minutes').eq('id', pid).maybeSingle();
            durationMins = (p?['duration_minutes'] as int?) ?? 60;
          }
          remainingSeconds = (durationMins * 60) - elapsed;
          if (remainingSeconds < 0) remainingSeconds = 0;
        } catch (_) {
          remainingSeconds = 3600;
        }
      }

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

    int remainingSeconds = 3600;
    try {
      final remaining = await _client.rpc('attempt_remaining_seconds', params: {'p_attempt_id': response['id']});
      if (remaining is num) remainingSeconds = remaining.toInt();
    } catch (_) {
      try {
        final sched = await _client.from('schedules').select('paper_id').eq('id', scheduleId).maybeSingle();
        final pid = sched?['paper_id'] as int?;
        if (pid != null) {
          final p = await _client.from('paper_sets').select('duration_minutes').eq('id', pid).maybeSingle();
          final mins = (p?['duration_minutes'] as int?) ?? 60;
          remainingSeconds = mins * 60;
        }
      } catch (_) {
        remainingSeconds = 3600;
      }
    }

    return {
      'attempt_id': response['id']?.toString(),
      'remaining_seconds': remainingSeconds,
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

    bool rpcSuccess = false;
    try {
      await _client.rpc('grade_attempt', params: {'p_attempt_id': attemptId, 'p_reason': reason});
      rpcSuccess = true;
    } catch (_) {
      // RPC may fail if PostgreSQL function has outdated references (e.g. public.papers).
      // Fallback directly to reliable client-side grading so the student never gets blocked.
    }

    if (!rpcSuccess) {
      await _gradeAttemptClientSide(attemptId, reason: reason);
    }

    return await _client
        .from('attempts')
        .select('score, total_marks, result')
        .eq('id', attemptId)
        .maybeSingle();
  }

  Future<void> _gradeAttemptClientSide(int attemptId, {String? reason}) async {
    try {
      // 1. Fetch attempt and schedule info
      final attempt = await _client
          .from('attempts')
          .select('id, schedule_id, student_id')
          .eq('id', attemptId)
          .maybeSingle();
      if (attempt == null) return;

      final scheduleId = attempt['schedule_id'] as int?;
      num marksCorrect = 1.0;
      num marksWrong = 0.0;
      num marksUnanswered = 0.0;
      int? paperId;

      if (scheduleId != null) {
        final sched = await _client
            .from('schedules')
            .select('paper_id, marks_correct, marks_wrong, marks_unanswered')
            .eq('id', scheduleId)
            .maybeSingle();
        if (sched != null) {
          paperId = sched['paper_id'] as int?;
          if (sched['marks_correct'] != null) marksCorrect = sched['marks_correct'] as num;
          if (sched['marks_wrong'] != null) marksWrong = sched['marks_wrong'] as num;
          if (sched['marks_unanswered'] != null) marksUnanswered = sched['marks_unanswered'] as num;
        }
      }

      // 2. Fetch paper set total_marks and pass_marks
      num totalMarks = 100;
      num passMarks = 33;
      if (paperId != null) {
        final paper = await _client
            .from('paper_sets')
            .select('total_marks, pass_marks')
            .eq('id', paperId)
            .maybeSingle();
        if (paper != null) {
          totalMarks = (paper['total_marks'] as num?) ?? 100;
          passMarks = (paper['pass_marks'] as num?) ?? 33;
        }
      }

      // 3. Fetch student's answers
      final answers = await _client
          .from('attempt_answers')
          .select('id, question_id, selected_option')
          .eq('attempt_id', attemptId);
      final answerList = List<Map<String, dynamic>>.from(answers as List);

      // 4. Fetch question bank details for those questions
      final qIds = answerList.map((a) => a['question_id']).whereType<int>().toList();
      final qMap = <int, Map<String, dynamic>>{};
      if (qIds.isNotEmpty) {
        final questions = await _client
            .from('question_bank')
            .select('id, correct_option, marks')
            .inFilter('id', qIds);
        for (final q in (questions as List)) {
          qMap[q['id'] as int] = Map<String, dynamic>.from(q as Map);
        }
      }

      // 5. Score answers
      num totalScore = 0.0;
      for (final a in answerList) {
        final qid = a['question_id'] as int?;
        final selectedOpt = a['selected_option'] as int?;
        final q = qid != null ? qMap[qid] : null;

        if (q != null) {
          final correctOpt = q['correct_option'] as int?;
          final qMarks = (q['marks'] as num?) ?? 1.0;
          final isCorrect = selectedOpt != null && selectedOpt == correctOpt;
          final awarded = isCorrect
              ? (qMarks * marksCorrect)
              : (selectedOpt != null ? (qMarks * marksWrong) : (qMarks * marksUnanswered));

          totalScore += awarded;

          try {
            await _client.from('attempt_answers').update({
              'is_correct': isCorrect,
              'marks_awarded': awarded,
            }).eq('id', a['id']);
          } catch (_) {}
        }
      }

      final resultStr = totalScore >= passMarks ? 'pass' : 'fail';

      // 6. Update the attempt to submitted with score
      await _client.from('attempts').update({
        'status': 'submitted',
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
        'score': totalScore,
        'total_marks': totalMarks,
        'result': resultStr,
      }).eq('id', attemptId);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getMyResults() async {
    final studentIds = await _currentStudentIds();
    if (studentIds.isEmpty) return [];

    try {
      final response = await _client
          .from('attempts')
          .select('id, score, total_marks, result, submitted_at, schedule_id, schedules(id, title, paper_id)')
          .inFilter('student_id', studentIds)
          .eq('status', 'submitted')
          .order('submitted_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(response);

      // Collect paperIds from schedules if available
      final paperIds = <int>{};
      for (final a in list) {
        final s = a['schedules'] as Map<String, dynamic>?;
        final pid = s?['paper_id'];
        if (pid is int) paperIds.add(pid);
      }

      final paperMap = <int, Map<String, dynamic>>{};
      if (paperIds.isNotEmpty) {
        try {
          final paperRows = await _client
              .from('paper_sets')
              .select('id, title, assessment_type, total_marks')
              .inFilter('id', paperIds.toList());
          for (final p in (paperRows as List)) {
            paperMap[p['id'] as int] = Map<String, dynamic>.from(p as Map);
          }
        } catch (_) {}
      }

      for (final a in list) {
        final s = a['schedules'] as Map<String, dynamic>?;
        if (s != null) {
          final pid = s['paper_id'] as int?;
          s['paper_sets'] = paperMap[pid] ?? {'title': s['title'] ?? 'Exam'};
        }
      }

      return list;
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
          .select('id, paper_id, title, start_at, end_at, status')
          .order('start_at', ascending: false);
      final scheduleList = List<Map<String, dynamic>>.from(response);
      final paperIds = scheduleList.map((s) => s['paper_id']).whereType<int>().toSet().toList();

      final paperMap = <int, Map<String, dynamic>>{};
      if (paperIds.isNotEmpty) {
        try {
          final paperRows = await _client
              .from('paper_sets')
              .select('id, title, assessment_type, total_marks')
              .inFilter('id', paperIds);
          for (final p in (paperRows as List)) {
            paperMap[p['id'] as int] = Map<String, dynamic>.from(p as Map);
          }
        } catch (_) {}
      }

      for (final s in scheduleList) {
        final pid = s['paper_id'] as int?;
        s['paper_sets'] = paperMap[pid] ?? {
          'title': s['title'] ?? 'Exam',
          'assessment_type': 'exam',
          'total_marks': 100,
        };
      }
      return scheduleList;
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
        .select('title, paper_id')
        .eq('id', scheduleId)
        .single();
    final examName = schedule['title'] as String? ?? 'Test';
    final paperId = schedule['paper_id'] as int?;

    Map<String, dynamic>? paper;
    if (paperId != null) {
      try {
        paper = await _client
            .from('paper_sets')
            .select('title, total_marks')
            .eq('id', paperId)
            .maybeSingle();
      } catch (_) {}
    }
    final subjectName = paper?['title'] as String? ?? examName;
    final totalMarks = (paper?['total_marks'] as num?)?.toDouble() ?? 100;

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
