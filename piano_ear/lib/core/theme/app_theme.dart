import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _accent  = Color(0xFF6750FF);
  static const Color success  = Color(0xFF22C55E);
  static const Color error    = Color(0xFFEF4444);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
        seedColor: _accent, brightness: Brightness.light);
    return _base(scheme).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF7F7FA));
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
        seedColor: _accent, brightness: Brightness.dark);
    return _base(scheme).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F13));
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: scheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}