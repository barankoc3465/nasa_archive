import 'package:flutter/material.dart';

abstract final class AppColors {
  static const pale = Color(0xFFFEFECC);
  static const cream = Color(0xFFFFF6AA);
  static const peach = Color(0xFFFDCB88);
  static const coral = Color(0xFFFFA988);
  static const rose = Color(0xFFFF8E99);
  static const pink = Color(0xFFF1618F);
  static const magenta = Color(0xFFBB44AE);
  static const violet = Color(0xFF9332BD);
  static const deepViolet = Color(0xFF6426A3);

  static const ink = Color(0xFF171020);
  static const panel = Color(0xFF261632);
  static const mutedText = Color(0xFFD9CDE2);
}

abstract final class AppTheme {
  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.pink,
          brightness: Brightness.dark,
          surface: AppColors.panel,
        ).copyWith(
          primary: AppColors.pink,
          onPrimary: AppColors.ink,
          secondary: AppColors.peach,
          onSecondary: AppColors.ink,
          surface: AppColors.panel,
          onSurface: AppColors.pale,
          error: AppColors.coral,
        );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ink,
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.pale,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel.withValues(alpha: 0.86),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.pale,
          side: const BorderSide(color: AppColors.pink),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.cream),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.panel,
        selectedColor: AppColors.pink,
        labelStyle: const TextStyle(color: AppColors.pale),
        secondaryLabelStyle: const TextStyle(color: AppColors.ink),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.ink,
        selectedItemColor: AppColors.cream,
        unselectedItemColor: AppColors.mutedText,
        type: BottomNavigationBarType.fixed,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.cream,
      ),
    );
  }
}
