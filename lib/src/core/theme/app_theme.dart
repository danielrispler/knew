import 'package:flutter/material.dart';

class AppTheme {
  // Light Palette
  static const Color lightPageBackground = Color(0xFFF6F7F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightMainText = Color(0xFF1C2230);
  static const Color lightMutedText = Color(0xFF667085);
  static const Color lightPrimaryAction = Color(0xFF2F5D9E);

  // Dark Palette
  static const Color darkPageBackground = Color(0xFF11151C);
  static const Color darkSurface = Color(0xFF1A202B);
  static const Color darkMainText = Color(0xFFE6E9EF);
  static const Color darkMutedText = Color(0xFF98A2B3);
  static const Color darkPrimaryAction = Color(0xFF8DB0E6);

  // Stage Colors
  static const Color stageNew = Color(0xFF98A2B3);
  static const Color stageFamiliar = Color(0xFFD39B2E);
  static const Color stageLearned = Color(0xFF3F9A6B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightPageBackground,
      colorScheme: const ColorScheme.light(
        primary: lightPrimaryAction,
        surface: lightSurface,
        onSurface: lightMainText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightPageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: lightMainText,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: lightSurface,
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightPrimaryAction,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkPageBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryAction,
        surface: darkSurface,
        onSurface: darkMainText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: darkMainText,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimaryAction,
        foregroundColor: darkPageBackground,
      ),
    );
  }
}
