import 'package:go_router/go_router.dart';
import '../presentation/verification_screen.dart';

class DocumentsRoutes {
  static List<GoRoute> get routes => [
    GoRoute(
      path: '/verify',
      builder: (context, state) => const VerificationScreen(),
      routes: [
        GoRoute(
          path: ':type/:id',
          builder: (context, state) => VerificationScreen(
            documentType: state.pathParameters['type'],
            documentId: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
  ];
}
