import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/providers/theme_provider.dart';
import '../features/splash/splash_screen.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

/// Application shell: theme + navigation.
///
/// Every provider it reads is optional ([Consumer] / `watch` with a default) so
/// the widget can also be pumped in tests without the full MultiProvider setup.
class VipMindApp extends StatelessWidget {
  const VipMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'VipMind',
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
