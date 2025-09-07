import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF2A73FF); // Bright Blue
  static const Color secondary = Color(0xFF34C759); // Green
  static const Color accent = Color(0xFFFF9500); // Orange
  static const Color error = Color(0xFFFF3B30); // Red

  // Backgrounds
  static const Color lightBackground = Color(0xFFFFFFFF); // White
  static const Color lightSurface = Color(0xFFF5F7FA); // Light Grey
  static const Color darkBackground = Color(0xFF121212); // Dark Grey/Black
  static const Color darkSurface = Color(0xFF1E1E1E); // Slightly lighter dark

  // Text
  static const Color textLightPrimary = Color(0xFF1C1C1E); // Almost black
  static const Color textLightSecondary = Color(0xFF6E6E73); // Medium grey
  static const Color textDarkPrimary = Color(0xFFF5F5F7); // Almost white
  static const Color textDarkSecondary = Color(0xFFA1A1AA); // Grey
}

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightSurface,
    dividerColor: Colors.grey.shade400,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textLightPrimary),
      bodyMedium: TextStyle(color: AppColors.textLightSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white, // White text on blue
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkSurface,
    dividerColor: Colors.grey.shade600,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textDarkPrimary),
      bodyMedium: TextStyle(color: AppColors.textDarkSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white, // White text on blue
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
    ),
  );
}
