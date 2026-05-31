import 'package:go_router/go_router.dart';
import '../presentation/contact_screen.dart';
import '../presentation/centre_finder_screen.dart';

class ContactRoutes {
  static List<GoRoute> get routes => [
    GoRoute(
      path: '/contact',
      builder: (context, state) => const ContactScreen(),
    ),
    GoRoute(
      path: '/centre-finder',
      builder: (context, state) => const CentreFinderScreen(),
    ),
  ];
}
