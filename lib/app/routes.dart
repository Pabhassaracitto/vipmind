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
import '../features/presentation/presentation_screen.dart';
import '../features/settings/screens/settings_screen.dart';
// Import all screens
import '../features/splash/splash_screen.dart';
import '../features/templates/screens/template_gallery_screen.dart';
import '../features/zen_mode/zen_mode_screen.dart';

// Routes class
class AppRoutes {
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
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case register:
        return _buildRoute(const RegisterScreen(), settings);
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case mindmapEditor:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          MindmapEditorScreen(mindmapId: args?['mindmapId']),
          settings,
        );
      case mindmapPreview:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          MindmapPreviewScreen(mindmapId: args['mindmapId']),
          settings,
        );
      case textToMindmap:
        return _buildRoute(const TextToMindmapScreen(), settings);
      case voiceToMindmap:
        return _buildRoute(const VoiceToMindmapScreen(), settings);
      case imageToMindmap:
        return _buildRoute(const ImageToMindmapScreen(), settings);
      case templateGallery:
        return _buildRoute(const TemplateGalleryScreen(), settings);
      case presentation:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          PresentationScreen(mindmapId: args['mindmapId']),
          settings,
        );
      case ankiDeck:
        return _buildRoute(const AnkiDeckScreen(), settings);
      case flashcardReview:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          FlashcardReviewScreen(deckId: args['deckId']),
          settings,
        );
      case zenMode:
        return _buildRoute(const ZenModeScreen(), settings);
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);
      default:
        return _buildRoute(const HomeScreen(), settings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
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
