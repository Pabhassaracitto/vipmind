import 'package:flutter/material.dart';

/// Local typography.
///
/// The Inter font ships in `assets/fonts/` and is registered in `pubspec.yaml`,
/// so text rendering never depends on a network fetch. (The project used to
/// call `GoogleFonts.inter(...)`, which downloads fonts at runtime and added a
/// dependency for nothing — offline first paint, CI and tests all benefit.)
class AppFonts {
  AppFonts._();

  /// Family name declared under `flutter: fonts:` in pubspec.yaml.
  static const String family = 'Inter';

  /// Drop-in replacement for `GoogleFonts.inter(...)`.
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }

  /// Drop-in replacement for `GoogleFonts.interTextTheme()`.
  ///
  /// Two traps this avoids:
  /// * `TextTheme().apply(fontFamily:)` silently does nothing — `apply` only
  ///   rewrites styles that already exist, and a default-constructed TextTheme
  ///   is full of nulls (ThemeData then fills the gaps from the platform
  ///   typography, i.e. Roboto);
  /// * a TextTheme with *some* null slots loses the family for those slots when
  ///   it is merged, so every one of the 15 slots is filled — from [base] when
  ///   given, otherwise from the Material defaults.
  static TextTheme textTheme([TextTheme? base]) {
    final TextTheme source = base ?? ThemeData.light().textTheme;

    TextStyle fill(TextStyle? style) =>
        (style ?? const TextStyle()).copyWith(fontFamily: family);

    return TextTheme(
      displayLarge: fill(source.displayLarge),
      displayMedium: fill(source.displayMedium),
      displaySmall: fill(source.displaySmall),
      headlineLarge: fill(source.headlineLarge),
      headlineMedium: fill(source.headlineMedium),
      headlineSmall: fill(source.headlineSmall),
      titleLarge: fill(source.titleLarge),
      titleMedium: fill(source.titleMedium),
      titleSmall: fill(source.titleSmall),
      bodyLarge: fill(source.bodyLarge),
      bodyMedium: fill(source.bodyMedium),
      bodySmall: fill(source.bodySmall),
      labelLarge: fill(source.labelLarge),
      labelMedium: fill(source.labelMedium),
      labelSmall: fill(source.labelSmall),
    );
  }
}
