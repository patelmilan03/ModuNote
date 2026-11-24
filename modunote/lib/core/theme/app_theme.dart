import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Produces ThemeData for light and dark modes.
/// UI revamp 2026-11: "Tangerine Pop" — ink primary, coral secondary.
/// [ColorScheme.secondary] is the theme-aware coral (capture, send, record).
abstract class AppTheme {
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.lightPrimary,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.lightBg,
      surfaceContainerLow: AppColors.lightSurfaceContainer,
      surfaceContainer: AppColors.lightSurfaceContainer,
      surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
      primary: AppColors.lightPrimary,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.lightOnPrimaryContainer,
      onSurface: AppColors.lightOnSurface,
      onSurfaceVariant: AppColors.lightOnSurfaceVariant,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineStrong,
      onPrimary: AppColors.lightBg,
      secondary: AppColors.lightAccent,
      onSecondary: AppColors.accentOn,
      secondaryContainer: AppColors.lightSurfaceContainer,
      onSecondaryContainer: AppColors.lightOnSurface,
      error: AppColors.lightRecordRed,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: AppTypography.buildTextTheme(),
      scaffoldBackgroundColor: AppColors.lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.lightOutline, width: 1),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.lightPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.darkBg,
      surfaceContainerLow: AppColors.darkSurfaceContainer,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
      primary: AppColors.darkPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineStrong,
      onPrimary: AppColors.ink,
      secondary: AppColors.darkAccent,
      onSecondary: AppColors.accentOn,
      secondaryContainer: AppColors.darkSurfaceContainer,
      onSecondaryContainer: AppColors.darkOnSurface,
      error: AppColors.darkRecordRed,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: AppTypography.buildTextTheme(),
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.darkOutline, width: 1),
        ),
      ),
    );
  }
}
