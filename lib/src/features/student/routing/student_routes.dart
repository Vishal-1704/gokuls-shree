import 'package:go_router/go_router.dart';
import '../presentation/student_dashboard_screen.dart';
import '../../exams/presentation/exam_list_screen.dart';
import '../../documents/presentation/my_documents_screen.dart';
import '../../auth/presentation/account_screen.dart';
import '../presentation/student_fee_status_screen.dart';
import '../presentation/student_result_list_screen.dart';
import '../presentation/student_attendance_screen.dart';
import '../presentation/student_id_card_screen.dart';

class StudentRoutes {
  static List<StatefulShellBranch> get branches => [
    StatefulShellBranch(routes: [
      GoRoute(path: '/student', builder: (c, s) => const StudentDashboardScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/student/exams', builder: (c, s) => const ExamListScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/student/docs', builder: (c, s) => const MyDocumentsScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/student/profile', builder: (c, s) => const AccountScreen()),
    ]),
  ];

  static List<GoRoute> get standaloneRoutes => [
    GoRoute(path: '/fee-status', builder: (c, s) => const StudentFeeStatusScreen()),
    GoRoute(path: '/results', builder: (c, s) => const StudentResultListScreen()),
    GoRoute(path: '/attendance', builder: (c, s) => const StudentAttendanceScreen()),
    GoRoute(path: '/id-card', builder: (c, s) => const StudentIdCardScreen()),
  ];
}
