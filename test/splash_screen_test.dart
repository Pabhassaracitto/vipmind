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
  /// Routes for `/home` and `/login` as inert stubs.
  ///
  /// Two reasons this exists:
  /// * without a generator for those names the splash navigation throws
  ///   "Could not find a generator for route RouteSettings(\"/login\")";
  /// * the real Home/Login screens touch Firebase, which is not initialised in a
  ///   plain widget test.
  Route<dynamic> stubRoutes(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(body: Text('stub:${settings.name}')),
    );
  }

  /// Pumps the splash screen and returns the route names it navigated to.
  ///
  /// Uses `pump(duration)` rather than `pumpAndSettle`: the splash loading
  /// indicator repeats forever, so `pumpAndSettle` can only ever time out while
  /// the splash is still on screen.
  Future<List<String>> pumpSplash(
    WidgetTester tester, {
    required bool signedIn,
    Duration delay = Duration.zero,
  }) async {
    final visited = <String>[];

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.home:
          case AppRoutes.login:
            visited.add(settings.name!);
            return stubRoutes(settings);
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

    // Past the navigation delay, plus the push transition.
    await tester.pump(delay + const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    return visited;
  }

  testWidgets('shows the VipMind branding while it is on screen',
      (tester) async {
    const delay = Duration(seconds: 3);

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.login) return stubRoutes(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => SplashScreen(
            signedInCheck: () => false,
            navigationDelay: delay,
          ),
        );
      },
    ));

    // First frame: branding is up, navigation has not happened yet.
    expect(find.text('VipMind'), findsOneWidget);
    expect(find.text('Your Brain, Amplified.'), findsOneWidget);
    expect(find.text('NeuroMindmap'), findsNothing,
        reason: 'the old product name must be gone');
    expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the timer fire and the splash be disposed, so no timer is left
    // pending at teardown.
    await tester.pump(delay + const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
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
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.login) return stubRoutes(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => SplashScreen(
            signedInCheck: () => false,
            navigationDelay: const Duration(seconds: 3),
          ),
        );
      },
    ));

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(SplashScreen), findsOneWidget,
        reason: 'navigated before the branding delay was over');

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SplashScreen), findsNothing);
  });

  test('the injectable auth check has a sensible default', () {
    // Constructing without signedInCheck must be possible (production path).
    expect(const SplashScreen(), isA<SplashScreen>());
    expect(const SplashScreen().signedInCheck, isNull);
    expect(const SplashScreen().navigationDelay, const Duration(milliseconds: 3000));
  });
}
