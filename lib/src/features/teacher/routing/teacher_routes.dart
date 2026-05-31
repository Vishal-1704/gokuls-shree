import 'package:go_router/go_router.dart';
import '../presentation/teacher_dashboard_screen.dart';
import '../presentation/teacher_attendance_screen.dart';
import '../presentation/teacher_students_screen.dart';
import '../presentation/teacher_results_upload_screen.dart';
import '../../auth/presentation/account_screen.dart';

class TeacherRoutes {
  static List<StatefulShellBranch> get branches => [
    StatefulShellBranch(routes: [
      GoRoute(path: '/teacher', builder: (c, s) => const TeacherDashboardScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/teacher/attendance', builder: (c, s) => const TeacherAttendanceScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/teacher/students', builder: (c, s) => const TeacherStudentsScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/teacher/profile', builder: (c, s) => const AccountScreen()),
    ]),
  ];

  static List<GoRoute> get standaloneRoutes => [
    GoRoute(path: '/teacher/upload-results', builder: (c, s) => const TeacherResultsUploadScreen()),
  ];
}
