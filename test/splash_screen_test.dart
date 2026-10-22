import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vipmind/app/routes.dart';
import 'package:vipmind/features/splash/splash_screen.dart';

/// The splash screen decides between Home and Login. That decision used to read
/// `FirebaseAuth.instance.currentUser` directly, which throws when Firebase is
/// not initialised — so the decision and the branding are tested through the
/// injectable [SplashScreen.signedInCheck] / [SplashScreen.navigationDelay].
///
/// Every test uses a delay of zero or lets the delay elapse: a SplashScreen
/// left in the tree with a pending timer fails the test with "timer still
/// pending", which is exactly what we want to notice.
void main() {
  /// Pumps the splash screen with stub routes for `/home` and `/login`, so the
  /// test observes the navigation *decision* without building Firebase screens.
  Future<List<String>> pumpSplash(
    WidgetTester tester, {
    required bool signedIn,
    Duration delay = Duration.zero,
    Duration settle = const Duration(seconds: 5),
  }) async {
    final visited = <String>[];

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.home:
          case AppRoutes.login:
            visited.add(settings.name!);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(body: Text('stub:${settings.name}')),
            );
          default:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => SplashScreen(
                signedInCheck: () => signedIn,
                navigationDelay: delay,
              ),
            );
        }
      },
    ));

    await tester.pumpAndSettle(settle);
    return visited;
  }

  testWidgets('shows the VipMind branding while it is on screen',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(
        signedInCheck: () => false,
        navigationDelay: const Duration(seconds: 3),
      ),
    ));

    // First frame: branding is up, navigation has not happened yet.
    expect(find.text('VipMind'), findsOneWidget);
    expect(find.text('Your Brain, Amplified.'), findsOneWidget);
    expect(find.text('NeuroMindmap'), findsNothing,
        reason: 'the old product name must be gone');
    expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the timer run out so no timer is left pending at teardown.
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('a signed-in user goes straight to Home', (tester) async {
    final visited = await pumpSplash(tester, signedIn: true);

    expect(visited, [AppRoutes.home]);
    expect(find.text('stub:/home'), findsOneWidget);
  });

  testWidgets('a signed-out user goes to Login', (tester) async {
    final visited = await pumpSplash(tester, signedIn: false);

    expect(visited, [AppRoutes.login]);
    expect(find.text('stub:/login'), findsOneWidget);
  });

  testWidgets('it does not navigate before the delay has elapsed',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SplashScreen(
        signedInCheck: () => false,
        navigationDelay: const Duration(seconds: 3),
      ),
    ));

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(SplashScreen), findsOneWidget,
        reason: 'navigated before the branding delay was over');

    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(SplashScreen), findsNothing);
  });

  test('the injectable auth check has a sensible default', () {
    // Constructing without signedInCheck must be possible (production path).
    expect(const SplashScreen(), isA<SplashScreen>());
    expect(const SplashScreen().signedInCheck, isNull);
    expect(const SplashScreen().navigationDelay, const Duration(milliseconds: 3000));
  });
}
