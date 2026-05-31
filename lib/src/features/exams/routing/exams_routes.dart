import 'package:go_router/go_router.dart';
import '../presentation/exam_instructions_screen.dart';
import '../presentation/exam_quiz_screen.dart';
import '../presentation/exam_result_screen.dart';
import '../domain/exam_model.dart';

class ExamsRoutes {
  static List<GoRoute> get routes => [
    GoRoute(
      path: '/exam-instruction/:id',
      builder: (context, state) => ExamInstructionsScreen(exam: state.extra as Exam),
    ),
    GoRoute(
      path: '/exam-start/:id',
      builder: (context, state) => ExamQuizScreen(
        examId: state.pathParameters['id']!,
        examMetadata: state.extra as Exam?,
      ),
    ),
    GoRoute(
      path: '/exam-result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ExamResultScreen(
          score: extra['score'],
          totalQuestions: extra['total'],
          examTitle: extra['title'],
        );
      },
    ),
  ];
}
