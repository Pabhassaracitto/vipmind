import 'package:flutter/material.dart';

// Import all screens
import '../features/splash/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/mindmap/screens/mindmap_editor_screen.dart';

// Temporary placeholder screens (create these files)
class MindmapPreviewScreen extends StatelessWidget {
  final String mindmapId;
  const MindmapPreviewScreen({super.key, required this.mindmapId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Center(child: Text('Preview: $mindmapId')),
    );
  }
}

class TextToMindmapScreen extends StatelessWidget {
  const TextToMindmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text to Mindmap')),
      body: const Center(child: Text('Coming Soon')),
    );
  }
}

class VoiceToMindmapScreen extends StatelessWidget {
  const VoiceToMindmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice to Mindmap')),
      body: const Center(child: Text('Coming Soon')),
    );
  }
}

class ImageToMindmapScreen extends StatelessWidget {
  const ImageToMindmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image to Mindmap')),
      body: const Center(child: Text('Coming Soon')),
    );
  }
}

class TemplateGalleryScreen extends StatelessWidget {
  const TemplateGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: const Center(child: Text('Coming Soon')),
    );
  }
}

class PresentationScreen extends StatelessWidget {
  final String mindmapId;
  const PresentationScreen({super.key, required this.mindmapId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presentation')),
      body: Center(child: Text('Presenting: $mindmapId')),
    );
  }
}

class AnkiDeckScreen extends StatelessWidget {
  const AnkiDeckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anki Deck')),
      body: const Center(child: Text('Coming Soon')),
    );
  }
}

class FlashcardReviewScreen extends StatelessWidget {
  final String deckId;
  const FlashcardReviewScreen({super.key, required this.deckId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: Center(child: Text('Reviewing: $deckId')),
    );
  }
}

class ZenModeScreen extends StatelessWidget {
  const ZenModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text('Zen Mode',
            style: TextStyle(color: Colors.white, fontSize: 32)),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings')),
    );
  }
}

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
      /*case textToMindmap:
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
        return _buildRoute(const HomeScreen(), settings);*/
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
