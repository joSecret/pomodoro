import 'package:flutter/material.dart';

/// Color tokens for the app. All screens read from here so the look stays
/// consistent on every platform.
class AppColors {
  static const bgTop = Color(0xFF1C1A3A);
  static const bgBottom = Color(0xFF22212E);
  static const surface = Color(0xFF26243A);
  static const surfaceHigh = Color(0xFF302D4C);
  static const cardBorder = Color(0x22FFFFFF);
  static const accent = Color(0xFF5B50EE);
  static const accentSoft = Color(0xFF7C73F5);
  static const textPrimary = Color(0xFFF2F1F8);
  static const textSecondary = Color(0xFFA9A7BD);
  static const textMuted = Color(0xFF75738A);
  static const ringTrack = Color(0xFF55536B);
  static const divider = Color(0x1FFFFFFF);
  static const success = Color(0xFF34C77B);
  static const danger = Color(0xFFE5484D);

  /// Heatmap intensity levels, from empty to most active.
  static const heat = [
    Color(0xFF2B2944),
    Color(0xFF3B3570),
    Color(0xFF4A3F9A),
    Color(0xFF5649C6),
    Color(0xFF6A5CF5),
  ];
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      primary: AppColors.accent,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    splashFactory: NoSplash.splashFactory,
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 12),
    ),
  );
}

const tabularFigures = [FontFeature.tabularFigures()];
