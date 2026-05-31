import 'package:go_router/go_router.dart';
import '../presentation/verification_screen.dart';

class DocumentsRoutes {
  static List<GoRoute> get routes => [
    GoRoute(
      path: '/verify',
      builder: (context, state) => const VerificationScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => VerificationScreen(documentId: state.pathParameters['id']),
        ),
      ],
    ),
  ];
}
