import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/services/storage_service.dart';
import 'data/providers/mindmap_provider.dart';
import 'data/providers/theme_provider.dart';
import 'data/providers/audio_provider.dart';
import 'data/providers/collaboration_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MindmapProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => CollaborationProvider()),
      ],
      child: const NeuroMindmapApp(),
    ),
  );
}
