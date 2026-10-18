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
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = dark
        ? const ColorScheme.dark(
            primary: Color(0xFFE8EAEC),
            primaryContainer: Color(0xFF343E46),
            onPrimaryContainer: Color(0xFFF0F2F4),
            secondaryContainer: Color(0xFF303A42),
            onSecondaryContainer: Color(0xFFE1E7EC),
            tertiary: Color(0xFFC0C8CF),
            onTertiary: Color(0xFF20262B),
            tertiaryContainer: Color(0xFF343E46),
            onTertiaryContainer: Color(0xFFF0F2F4),
            onPrimary: Color(0xFF141719),
            secondary: Color(0xFFB3BCC5),
            onSecondary: Color(0xFF20262B),
            surface: Color(0xFF1C2227),
            onSurface: Color(0xFFF0F2F4),
            surfaceContainerHighest: Color(0xFF2A3239),
            onSurfaceVariant: Color(0xFFB0BAC3),
            outline: Color(0xFF77838E),
            outlineVariant: Color(0xFF39434C),
            error: Color(0xFFFFA6AD),
            onError: Color(0xFF4C1720),
          )
        : const ColorScheme.light(
            primary: Color(0xFF141719),
            primaryContainer: Color(0xFFE2E7EB),
            onPrimaryContainer: Color(0xFF182026),
            secondaryContainer: Color(0xFFE9EDF0),
            onSecondaryContainer: Color(0xFF263039),
            tertiary: Color(0xFF58646E),
            onTertiary: Colors.white,
            tertiaryContainer: Color(0xFFE2E7EB),
            onTertiaryContainer: Color(0xFF182026),
            onPrimary: Colors.white,
            secondary: Color(0xFF535E68),
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textDark,
            surfaceContainerHighest: Color(0xFFE9EDF0),
            onSurfaceVariant: Color(0xFF59656F),
            outline: Color(0xFF78838C),
            outlineVariant: AppColors.line,
            error: Color(0xFFB83242),
            onError: Colors.white,
          );
    const base = TextTheme(
      displayLarge: TextStyle(
        fontSize: 42,
        height: 0.98,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        fontSize: 34,
        height: 1.04,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 23,
        height: 1.16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF12171B)
          : AppColors.background,
      colorScheme: scheme,
      textTheme: base.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      fontFamily: 'Arial',
      dividerColor: scheme.outlineVariant,
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.2),
        selectionHandleColor: scheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: scheme.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.surfaceContainerHighest,
        backgroundColor: scheme.surface,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.surfaceContainerHighest,
        selectedIconTheme: IconThemeData(color: scheme.onSurface),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(color: scheme.onSurface),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
