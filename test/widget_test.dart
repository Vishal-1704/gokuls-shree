import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gokul_shree_app/src/app.dart';
import 'package:gokul_shree_app/src/core/providers/session_provider.dart';
import 'package:gokul_shree_app/src/core/models/user_session.dart';

class MockSessionNotifier extends SessionNotifier {
  @override
  UserSession? build() {
    return null; // Guest user
  }
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame, overriding sessionProvider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => MockSessionNotifier()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app builds without crashing.
    expect(find.byType(MyApp), findsOneWidget);
  });
}

