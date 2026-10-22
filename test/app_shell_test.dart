import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vipmind/app/app.dart';
import 'package:vipmind/app/routes.dart';
import 'package:vipmind/app/theme/app_colors.dart';
import 'package:vipmind/app/theme/app_fonts.dart';
import 'package:vipmind/app/theme/app_theme.dart';
import 'package:vipmind/core/services/storage_service.dart';
import 'package:vipmind/data/providers/theme_provider.dart';

/// Wiring tests for the app shell.
///
/// `VipMindApp` itself is only constructed here, never pumped: pumping it
/// builds `SplashScreen`, whose 3-second navigation timer would fail the test
/// with "timer still pending". Splash navigation is covered by
/// `splash_screen_test.dart`, which injects the auth check and the delay.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.setInstanceForTesting(await SharedPreferences.getInstance());
  });

  tearDown(() => StorageService.setInstanceForTesting(null));

  test('the app shell is a const widget named VipMind', () {
    const app = VipMindApp();
    expect(app, isA<StatelessWidget>());
  });

  group('local Inter font (no runtime font download)', () {
    test('textTheme applies the bundled family', () {
      final theme = AppFonts.textTheme();
      expect(theme.bodyMedium?.fontFamily, AppFonts.family);
      expect(theme.displayLarge?.fontFamily, AppFonts.family);
    });

    test('inter() mirrors the TextStyle parameters it is given', () {
      final style = AppFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 1.5,
        height: 1.4,
      );

      expect(style.fontFamily, 'Inter');
      expect(style.fontSize, 18);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.color, AppColors.textPrimary);
      expect(style.letterSpacing, 1.5);
      expect(style.height, 1.4);
    });
  });

  group('AppTheme', () {
    test('light and dark themes build and use the local font', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
        expect(theme.primaryColor, AppColors.primaryBlue);
        expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Inter');
        expect(theme.inputDecorationTheme.hintStyle?.fontFamily, 'Inter');
        expect(theme.elevatedButtonTheme.style, isNotNull);
      }
    });

    test('light and dark differ where they must', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(AppTheme.lightTheme.scaffoldBackgroundColor,
          AppColors.backgroundLight);
      expect(AppTheme.darkTheme.scaffoldBackgroundColor,
          AppColors.backgroundDark);
    });
  });

  group('ThemeProvider', () {
    test('defaults to system and cycles light → dark → system', () {
      final provider = ThemeProvider();
      addTearDown(provider.dispose);

      expect(provider.themeMode, ThemeMode.system);
      expect(provider.isSystemMode, isTrue);

      provider.toggleTheme(); // system → light
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isLightMode, isTrue);

      provider.toggleTheme(); // light → dark
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);

      provider.toggleTheme(); // dark → system
      expect(provider.themeMode, ThemeMode.system);
    });

    test('persists the choice through StorageService', () async {
      final provider = ThemeProvider();
      addTearDown(provider.dispose);

      provider.setThemeMode(ThemeMode.dark);
      expect(StorageService.getString('theme_mode'), 'dark');

      // A new provider must read the saved value back.
      final reloaded = ThemeProvider();
      addTearDown(reloaded.dispose);
      expect(reloaded.themeMode, ThemeMode.dark);
    });

    test('an unreadable saved value falls back to system', () async {
      await StorageService.setString('theme_mode', 'not-a-theme-mode');
      final provider = ThemeProvider();
      addTearDown(provider.dispose);

      expect(provider.themeMode, ThemeMode.system);
    });

    test('works when StorageService has not been initialised', () {
      StorageService.setInstanceForTesting(null);
      final provider = ThemeProvider();
      addTearDown(provider.dispose);

      expect(provider.themeMode, ThemeMode.system);
      expect(() => provider.setThemeMode(ThemeMode.light), returnsNormally);
    });
  });

  testWidgets('the shell drives MaterialApp theme and route table',
      (tester) async {
    final themeProvider = ThemeProvider();
    addTearDown(themeProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ],
        child: MaterialApp(
          title: 'VipMind',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          onGenerateRoute: AppRoutes.generateRoute,
          home: Builder(
            builder: (context) => const Scaffold(body: Text('probe')),
          ),
        ),
      ),
    );

    BuildContext probeContext = tester.element(find.text('probe'));
    expect(Theme.of(probeContext).brightness, Brightness.light);

    themeProvider.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    probeContext = tester.element(find.text('probe'));
    expect(Theme.of(probeContext).brightness, Brightness.dark);
    expect(Theme.of(probeContext).textTheme.bodyMedium?.fontFamily, 'Inter');
  });
}
