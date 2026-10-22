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
  /// `TextTheme().apply(fontFamily:)` would silently do nothing: `apply` only
  /// rewrites styles that already exist, and a default-constructed TextTheme is
  /// full of nulls (ThemeData then fills the gaps from the platform typography,
  /// i.e. Roboto). So the family is set on every slot explicitly.
  static TextTheme textTheme([TextTheme? base]) {
    final source = base ?? const TextTheme();
    TextStyle? apply(TextStyle? style) =>
        style == null ? null : style.copyWith(fontFamily: family);

    return TextTheme(
      displayLarge: apply(source.displayLarge),
      displayMedium: apply(source.displayMedium),
      displaySmall: apply(source.displaySmall),
      headlineLarge: apply(source.headlineLarge),
      headlineMedium: apply(source.headlineMedium),
      headlineSmall: apply(source.headlineSmall),
      titleLarge: apply(source.titleLarge),
      titleMedium: apply(source.titleMedium),
      titleSmall: apply(source.titleSmall),
      bodyLarge: apply(source.bodyLarge),
      bodyMedium: apply(source.bodyMedium),
      bodySmall: apply(source.bodySmall),
      labelLarge: apply(source.labelLarge),
      labelMedium: apply(source.labelMedium),
      labelSmall: apply(source.labelSmall),
    );
  }
}
