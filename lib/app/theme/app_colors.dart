import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF4A6FA5);
  static const Color primaryBlueDark = Color(0xFF3A5A8C);
  static const Color primaryBlueLight = Color(0xFF6B8FC5);

  // Accent Colors
  static const Color accentYellow = Color(0xFFFFD166);
  static const Color accentYellowDark = Color(0xFFE5B84D);
  static const Color accentYellowLight = Color(0xFFFFE599);

  // Secondary Colors
  static const Color calmGreen = Color(0xFF06D6A0);
  static const Color calmGreenDark = Color(0xFF05B386);
  static const Color calmGreenLight = Color(0xFF4EECC0);

  static const Color creativePurple = Color(0xFF9D4EDD);
  static const Color creativePurpleDark = Color(0xFF7B3DB5);
  static const Color creativePurpleLight = Color(0xFFB87CEE);

  // Alert Colors
  static const Color errorRed = Color(0xFFEF476F);
  static const Color warningOrange = Color(0xFFF77F00);
  static const Color successGreen = Color(0xFF06D6A0);
  static const Color infoBlue = Color(0xFF118AB2);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF0D1B2A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1B2838);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFF8F9FA);
  static const Color textLightSecondary = Color(0xFFB0B8C4);

  // Node Colors (for mindmap)
  static const List<Color> nodeColors = [
    Color(0xFF4A6FA5), // Blue
    Color(0xFF06D6A0), // Green
    Color(0xFFFFD166), // Yellow
    Color(0xFF9D4EDD), // Purple
    Color(0xFFEF476F), // Red/Pink
    Color(0xFFF77F00), // Orange
    Color(0xFF118AB2), // Teal
    Color(0xFF073B4C), // Dark Blue
  ];

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, creativePurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentYellow, warningOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calmGradient = LinearGradient(
    colors: [calmGreen, infoBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [backgroundDark, surfaceDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Get color by index (for nodes)
  static Color getNodeColor(int index) {
    return nodeColors[index % nodeColors.length];
  }

  // Get gradient by color
  static LinearGradient getNodeGradient(Color baseColor) {
    return LinearGradient(
      colors: [
        baseColor,
        baseColor.withOpacity(0.7),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}