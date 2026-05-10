class Exam {
  final String id;
  final String title;
  final int durationMinutes;
  final int totalMarks;
  final int questionsCount;
  final String? scheduleId;
  final int maxAttempts;
  final bool shuffleOptions;
  final bool negativeMarkingEnabled;

  Exam({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.totalMarks,
    required this.questionsCount,
    this.scheduleId,
    this.maxAttempts = 1,
    this.shuffleOptions = true,
    this.negativeMarkingEnabled = false,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'],
      title: json['title'],
      durationMinutes: json['duration_minutes'],
      totalMarks: int.tryParse(json['total_marks'].toString()) ?? 0,
      questionsCount: json['questions_count'],
      scheduleId: json['schedule_id']?.toString(),
      maxAttempts: int.tryParse((json['max_attempts'] ?? 1).toString()) ?? 1,
      shuffleOptions: json['shuffle_options'] == true,
      negativeMarkingEnabled: json['negative_marking_enabled'] == true,
    );
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctOptionIndex;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      options: List<String>.from(json['options']),
      correctOptionIndex: json['correct_option_index'],
    );
  }
}
