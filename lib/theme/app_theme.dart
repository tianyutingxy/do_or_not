import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF14141C);
  static const doGreen = Color(0xFF3DDC97);
  static const notRed = Color(0xFFFF6B6B);
  static const gold = Color(0xFFFFD166);
  static const cardWhite = Color(0xFFF8F6F0);
  static const spotlight = Color(0xFFFFF8E7);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.doGreen,
      surface: AppColors.surface,
    ),
    fontFamily: 'SF Pro Display',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white54),
    ),
  );
}
