import 'package:flutter/material.dart';

import '../features/ai_engine/screens/image_to_mindmap_screen.dart';
import '../features/ai_engine/screens/text_to_mindmap_screen.dart';
import '../features/ai_engine/screens/voice_to_mindmap_screen.dart';
import '../features/anki/screens/anki_deck_screen.dart';
import '../features/anki/screens/flashcard_review_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/mindmap/screens/mindmap_editor_screen.dart';
import '../features/mindmap/screens/mindmap_preview_screen.dart';
import '../features/presentation/screens/presentation_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/templates/screens/template_gallery_screen.dart';
import '../features/zen_mode/zen_mode_screen.dart';

/// All named routes of the app.
///
/// Rules:
/// * every route constant below MUST have a `case` in [generateRoute] —
///   otherwise navigation silently falls back to Home;
/// * screens live in `lib/features/**` and are imported here. Do NOT declare
///   placeholder widgets in this file (that used to create duplicate classes).
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String mindmapEditor = '/mindmap/editor';
  static const String mindmapPreview = '/mindmap/preview';
  static const String textToMindmap = '/ai/text-to-mindmap';
  static const String voiceToMindmap = '/ai/voice-to-mindmap';
  static const String imageToMindmap = '/ai/image-to-mindmap';
  static const String templateGallery = '/templates';
  static const String presentation = '/presentation';
  static const String ankiDeck = '/anki';
  static const String flashcardReview = '/anki/review';
  static const String zenMode = '/zen-mode';
  /// Named `settingsRoute`, not `settings`: inside `generateRoute` a case
  /// label written `settings` would be a *variable pattern* in Dart 3 — it
  /// binds instead of comparing, so it would swallow every remaining route.
  static const String settingsRoute = '/settings';

  // The parameter is NOT called `settings`: a switch case like
  // `case settings:` would bind a *variable* pattern (Dart 3) and silently
  // match everything, and `case AppRoutes.settings:` is rejected because a
  // constant pattern may not be a prefixed identifier. With the parameter
  // renamed, every case below is a plain constant pattern.
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), routeSettings);

      case login:
        return _buildRoute(const LoginScreen(), routeSettings);

      case register:
        return _buildRoute(const RegisterScreen(), routeSettings);

      case home:
        return _buildRoute(const HomeScreen(), routeSettings);

      case mindmapEditor:
        return _buildRoute(
          MindmapEditorScreen(mindmapId: _arg<String>(routeSettings, 'mindmapId')),
          routeSettings,
        );

      case mindmapPreview:
        return _buildRoute(
          MindmapPreviewScreen(
            mindmapId: _requiredArg(routeSettings, 'mindmapId'),
          ),
          routeSettings,
        );

      case textToMindmap:
        return _buildRoute(const TextToMindmapScreen(), routeSettings);

      case voiceToMindmap:
        return _buildRoute(const VoiceToMindmapScreen(), routeSettings);

      case imageToMindmap:
        return _buildRoute(const ImageToMindmapScreen(), routeSettings);

      case templateGallery:
        return _buildRoute(const TemplateGalleryScreen(), routeSettings);

      case presentation:
        return _buildRoute(
          PresentationScreen(
            mindmapId: _requiredArg(routeSettings, 'mindmapId'),
          ),
          routeSettings,
        );

      case ankiDeck:
        return _buildRoute(const AnkiDeckScreen(), routeSettings);

      case flashcardReview:
        return _buildRoute(
          FlashcardReviewScreen(
            deckId: _requiredArg(routeSettings, 'deckId'),
          ),
          routeSettings,
        );

      case zenMode:
        return _buildRoute(const ZenModeScreen(), routeSettings);

      case settingsRoute:
        return _buildRoute(const SettingsScreen(), routeSettings);

      default:
        return _buildRoute(UnknownRouteScreen(routeName: routeSettings.name), routeSettings);
    }
  }

  /// Reads an optional route argument.
  static T? _arg<T>(RouteSettings settings, String key) {
    final args = settings.arguments;
    if (args is Map && args[key] is T) return args[key] as T;
    return null;
  }

  /// Reads a required route argument; returns an empty string instead of
  /// throwing, so a missing argument never crashes the app.
  static String _requiredArg(RouteSettings settings, String key) {
    return _arg<String>(settings, key) ?? '';
  }

  static PageRouteBuilder<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Shown when code navigates to a route that does not exist.
///
/// Deliberately loud: an unregistered route is a bug, and silently landing on
/// Home hides it.
class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key, this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_off_rounded, size: 56),
              const SizedBox(height: 16),
              Text(
                'No route registered for "${routeName ?? '?'}"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Register it in lib/app/routes.dart → AppRoutes.generateRoute',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
