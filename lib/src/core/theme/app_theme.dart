import 'package:flutter/material.dart';

class AppColors {
  static const brandBlack = Color(0xFF071119);
  static const deepNavy = Color(0xFF09131C);
  static const darkSurface = Color(0xFF101A23);
  static const darkCard = Color(0xFF0C151E);
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const primaryGreen = Color(0xFF20E57A);
  static const textDark = Color(0xFF0A1118);
  static const textMuted = Color(0xFF68737D);
  static const line = Color(0xFFE5E9EE);
  static const blue = Color(0xFF5CA7F7);
  static const purple = Color(0xFF8D76F6);
  static const amber = Color(0xFFE6A93C);
  static const red = Color(0xFFD85F68);
}

class AppSpacing {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
}

class AppRadii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
}

class AppTheme {
  static ThemeData get light {
    const base = TextTheme(
      displayLarge: TextStyle(fontSize: 42, height: 0.98, fontWeight: FontWeight.w800, letterSpacing: 0),
      displayMedium: TextStyle(fontSize: 34, height: 1.04, fontWeight: FontWeight.w800, letterSpacing: 0),
      headlineLarge: TextStyle(fontSize: 28, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: 0),
      headlineMedium: TextStyle(fontSize: 23, height: 1.16, fontWeight: FontWeight.w800, letterSpacing: 0),
      headlineSmall: TextStyle(fontSize: 20, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: 0),
      titleLarge: TextStyle(fontSize: 17, height: 1.25, fontWeight: FontWeight.w700, letterSpacing: 0),
      titleMedium: TextStyle(fontSize: 15, height: 1.35, fontWeight: FontWeight.w700, letterSpacing: 0),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500, letterSpacing: 0),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, letterSpacing: 0),
      bodySmall: TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w600, letterSpacing: 0),
      labelLarge: TextStyle(fontSize: 14, height: 1, fontWeight: FontWeight.w800, letterSpacing: 0),
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        brightness: Brightness.light,
        primary: AppColors.primaryGreen,
        surface: AppColors.surface,
      ),
      textTheme: base.apply(bodyColor: AppColors.textDark, displayColor: AppColors.textDark),
      fontFamily: 'Arial',
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: Color(0xFFE7FBEF),
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
