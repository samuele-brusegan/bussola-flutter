import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens ported from the web app's `app-shell.css`.
class AppColors {
  AppColors._();

  // Light
  static const lightInk = Color(0xFF10231F);
  static const lightMuted = Color(0xFF64736F);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFF2F6F4);
  static const lightBorder = Color(0xFFDBE5E1);
  static const lightGreen = Color(0xFF008F5B);
  static const lightGreenDark = Color(0xFF006E46);
  static const lightBlue = Color(0xFF0759B8);
  static const lightBlueDark = Color(0xFF064694);

  // Dark
  static const darkInk = Color(0xFFEDF7F2);
  static const darkMuted = Color(0xFFA6B8B1);
  static const darkSurface = Color(0xFF17221F);
  static const darkSurface2 = Color(0xFF0D1513);
  static const darkBorder = Color(0xFF30423C);
  static const darkGreen = Color(0xFF20B878);
  static const darkGreenDark = Color(0xFF15935E);
  static const darkBlue = Color(0xFF4C9AF0);
  static const darkBlueDark = Color(0xFF77B5FF);

  // Brand accents (shared)
  static const red = Color(0xFFFA2020);
  static const actvRed = Color(0xFFE30613);
  static const orange = Color(0xFFFF9800);
  static const gold = Color(0xFFFFD700);
  static const nightBlue = Color(0xFF002B57);
}

extension AppPalette on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get ink => isDark ? AppColors.darkInk : AppColors.lightInk;
  Color get muted => isDark ? AppColors.darkMuted : AppColors.lightMuted;
  Color get surface => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get surface2 => isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
  Color get border => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get green => isDark ? AppColors.darkGreen : AppColors.lightGreen;
  Color get greenDark => isDark ? AppColors.darkGreenDark : AppColors.lightGreenDark;
  Color get blue => isDark ? AppColors.darkBlue : AppColors.lightBlue;
  Color get blueDark => isDark ? AppColors.darkBlueDark : AppColors.lightBlueDark;
}

class AppTheme {
  static const double radius = 18.0;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final ink = dark ? AppColors.darkInk : AppColors.lightInk;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final surface2 = dark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final blue = dark ? AppColors.darkBlue : AppColors.lightBlue;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;

    final base = ThemeData(brightness: brightness).textTheme;
    final textTheme = GoogleFonts.interTextTheme(base).apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: surface2,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: blue,
        onPrimary: Colors.white,
        secondary: dark ? AppColors.darkGreen : AppColors.lightGreen,
        onSecondary: Colors.white,
        error: AppColors.red,
        onError: Colors.white,
        surface: surface,
        onSurface: ink,
        surfaceContainerHighest: surface2,
        outline: border,
      ),
      textTheme: textTheme,
      cardColor: surface,
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: blue, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          foregroundColor: ink,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: surface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: dark ? AppColors.darkGreen : AppColors.lightGreen,
      ),
      listTileTheme: ListTileThemeData(
        textColor: ink,
        iconColor: muted,
      ),
    );
  }
}
