import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vipmind/app/routes.dart';
import 'package:vipmind/core/services/storage_service.dart';
import 'package:vipmind/data/providers/audio_provider.dart';
import 'package:vipmind/data/providers/mindmap_provider.dart';
import 'package:vipmind/data/providers/theme_provider.dart';
import 'package:vipmind/features/ai_engine/screens/image_to_mindmap_screen.dart';
import 'package:vipmind/features/ai_engine/screens/text_to_mindmap_screen.dart';
import 'package:vipmind/features/ai_engine/screens/voice_to_mindmap_screen.dart';
import 'package:vipmind/features/anki/screens/anki_deck_screen.dart';
import 'package:vipmind/features/anki/screens/flashcard_review_screen.dart';
import 'package:vipmind/features/auth/screens/login_screen.dart';
import 'package:vipmind/features/auth/screens/register_screen.dart';
import 'package:vipmind/features/home/screens/home_screen.dart';
import 'package:vipmind/features/mindmap/screens/mindmap_editor_screen.dart';
import 'package:vipmind/features/mindmap/screens/mindmap_preview_screen.dart';
import 'package:vipmind/features/presentation/screens/presentation_screen.dart';
import 'package:vipmind/features/settings/screens/settings_screen.dart';
import 'package:vipmind/features/splash/splash_screen.dart';
import 'package:vipmind/features/templates/screens/template_gallery_screen.dart';
import 'package:vipmind/features/zen_mode/zen_mode_screen.dart';

/// Guard for the bug that made half the app unreachable: 9 of the 15 routes in
/// `AppRoutes.generateRoute` were commented out, so every tap on Templates /
/// AI / Flashcards / Zen / Settings silently fell through to `default:` and
/// pushed the user back to Home.
///
/// The route *table* assertions below do not build widgets — Login, Register,
/// Home, Splash, Preview and Editor all touch Firebase and cannot be pumped in
/// a plain test. The Firebase-free screens are pumped at the end.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.setInstanceForTesting(
      await SharedPreferences.getInstance(),
    );
  });

  tearDown(() => StorageService.setInstanceForTesting(null));

  Widget buildPageFor(String? name, [Object? arguments]) {
    final route = AppRoutes.generateRoute(RouteSettings(
      name: name,
      arguments: arguments,
    ));
    expect(route, isA<PageRouteBuilder<dynamic>>(), reason: 'route "$name"');
    return (route as PageRouteBuilder<dynamic>).buildPage(
      _StubBuildContext(),
      const AlwaysStoppedAnimation<double>(0),
      const AlwaysStoppedAnimation<double>(0),
    );
  }

  group('every route constant resolves to its own screen', () {
    test('splash', () => expect(buildPageFor(AppRoutes.splash), isA<SplashScreen>()));
    test('login', () => expect(buildPageFor(AppRoutes.login), isA<LoginScreen>()));
    test('register',
        () => expect(buildPageFor(AppRoutes.register), isA<RegisterScreen>()));
    test('home', () => expect(buildPageFor(AppRoutes.home), isA<HomeScreen>()));
    test('mindmapEditor', () => expect(
        buildPageFor(AppRoutes.mindmapEditor, {'mindmapId': 'x'}),
        isA<MindmapEditorScreen>()));
    test('mindmapPreview', () => expect(
        buildPageFor(AppRoutes.mindmapPreview, {'mindmapId': 'x'}),
        isA<MindmapPreviewScreen>()));
    test('textToMindmap', () => expect(
        buildPageFor(AppRoutes.textToMindmap), isA<TextToMindmapScreen>()));
    test('voiceToMindmap', () => expect(
        buildPageFor(AppRoutes.voiceToMindmap), isA<VoiceToMindmapScreen>()));
    test('imageToMindmap', () => expect(
        buildPageFor(AppRoutes.imageToMindmap), isA<ImageToMindmapScreen>()));
    test('templateGallery', () => expect(
        buildPageFor(AppRoutes.templateGallery), isA<TemplateGalleryScreen>()));
    test('presentation', () => expect(
        buildPageFor(AppRoutes.presentation, {'mindmapId': 'x'}),
        isA<PresentationScreen>()));
    test('ankiDeck',
        () => expect(buildPageFor(AppRoutes.ankiDeck), isA<AnkiDeckScreen>()));
    test('flashcardReview', () => expect(
        buildPageFor(AppRoutes.flashcardReview, {'deckId': 'd'}),
        isA<FlashcardReviewScreen>()));
    test('zenMode',
        () => expect(buildPageFor(AppRoutes.zenMode), isA<ZenModeScreen>()));
    test('settings',
        () => expect(buildPageFor(AppRoutes.settingsRoute), isA<SettingsScreen>()));
  });

  test('route constants are unique (a duplicate would shadow a screen)', () {
    const names = <String>[
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.home,
      AppRoutes.mindmapEditor,
      AppRoutes.mindmapPreview,
      AppRoutes.textToMindmap,
      AppRoutes.voiceToMindmap,
      AppRoutes.imageToMindmap,
      AppRoutes.templateGallery,
      AppRoutes.presentation,
      AppRoutes.ankiDeck,
      AppRoutes.flashcardReview,
      AppRoutes.zenMode,
      AppRoutes.settingsRoute,
    ];
    expect(names.toSet().length, names.length);
    expect(names.length, 15);
  });

  test('an unregistered route is reported, not silently redirected to Home', () {
    expect(buildPageFor('/does-not-exist'), isA<UnknownRouteScreen>());
  });

  test('missing arguments degrade to an empty id instead of throwing', () {
    expect(() => buildPageFor(AppRoutes.mindmapPreview), returnsNormally);
    expect(() => buildPageFor(AppRoutes.presentation), returnsNormally);
    expect(() => buildPageFor(AppRoutes.flashcardReview), returnsNormally);
    expect(() => buildPageFor(AppRoutes.mindmapEditor), returnsNormally);
  });

  group('Firebase-free screens actually render', () {
    /// Pumps the real route table with the real providers, the way `main()`
    /// does, then navigates to [name].
    Future<void> pumpRoute(WidgetTester tester, String name) async {
      final themeProvider = ThemeProvider();
      final audioProvider = AudioProvider();
      final mindmapProvider = MindmapProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
            ChangeNotifierProvider<MindmapProvider>.value(
                value: mindmapProvider),
          ],
          child: MaterialApp(
            onGenerateRoute: AppRoutes.generateRoute,
            initialRoute: name,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
    }

    testWidgets('zen mode shows the focus timer and the capture field',
        (tester) async {
      await pumpRoute(tester, AppRoutes.zenMode);

      expect(find.text('Zen Mode'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Nothing captured yet'), findsOneWidget);
    });

    testWidgets('zen mode keeps a captured thought on screen', (tester) async {
      await pumpRoute(tester, AppRoutes.zenMode);

      await tester.enterText(find.byType(TextField), 'Buy milk');
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('Nothing captured yet'), findsNothing);
      expect(StorageService.getStringList('zen_captured_ideas'), ['Buy milk']);
    });

    testWidgets('zen mode honours the focus length saved in Settings',
        (tester) async {
      await StorageService.setInt('settings_focus_minutes', 45);
      await pumpRoute(tester, AppRoutes.zenMode);

      expect(find.text('45:00'), findsOneWidget);
    });

    testWidgets('settings shows theme, sound and focus controls',
        (tester) async {
      await pumpRoute(tester, AppRoutes.settingsRoute);

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Follow system'), findsOneWidget);
      expect(find.text('Interface sounds'), findsOneWidget);
      expect(find.text('Focus session length'), findsOneWidget);
      expect(find.text('VipMind'), findsOneWidget);
    });

    testWidgets('settings toggles interface sounds', (tester) async {
      final audioProvider = AudioProvider();
      expect(audioProvider.isSoundEnabled, isTrue);

      await pumpRoute(tester, AppRoutes.settingsRoute);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((widget) =>
          widget is SwitchListTile && widget.value == false), findsOneWidget);
    });

    testWidgets('text-to-mindmap states what is planned', (tester) async {
      await pumpRoute(tester, AppRoutes.textToMindmap);

      expect(find.text('Turn text into a mindmap'), findsOneWidget);
      expect(find.text('Status: not implemented yet'), findsOneWidget);
    });

    testWidgets('voice-to-mindmap states what is planned', (tester) async {
      await pumpRoute(tester, AppRoutes.voiceToMindmap);
      expect(find.text('Speak your ideas, get a map'), findsOneWidget);
    });

    testWidgets('image-to-mindmap states what is planned', (tester) async {
      await pumpRoute(tester, AppRoutes.imageToMindmap);
      expect(find.text('Scan a page into a mindmap'), findsOneWidget);
    });

    testWidgets('flashcard deck screen renders', (tester) async {
      await pumpRoute(tester, AppRoutes.ankiDeck);
      expect(find.text('Flashcards from your mindmap'), findsOneWidget);
    });

    testWidgets('unknown route screen offers a way home', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        onGenerateRoute: AppRoutes.generateRoute,
        initialRoute: '/nope',
      ));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(find.text('Page not found'), findsOneWidget);
      expect(find.textContaining('No route registered'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });
  });
}

/// `buildPage` receives a BuildContext that these screens never dereference
/// while being constructed, so a stub keeps the table test cheap.
class _StubBuildContext extends Fake implements BuildContext {}
