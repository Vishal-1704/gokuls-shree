import 'package:go_router/go_router.dart';
import '../presentation/login_screen.dart';
import '../presentation/forgot_password_screen.dart';

class AuthRoutes {
  static List<GoRoute> get routes => [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
  ];
}
