import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'routes.dart';
import 'theme/app_theme.dart';
import '../data/providers/theme_provider.dart';
import '../features/splash/splash_screen.dart';

class NeuroMindmapApp extends StatelessWidget {
  const NeuroMindmapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'NeuroMindmap',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}