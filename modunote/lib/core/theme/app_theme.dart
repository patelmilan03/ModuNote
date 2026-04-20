import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Produces ThemeData for light and dark modes.
/// Phase 1: minimal viable config — Color seed + fonts.
/// Phase 9: will flesh out NavigationBar, Card, Chip, FAB themes fully.
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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightOutline, width: 0.5),
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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkOutline, width: 0.5),
        ),
      ),
    );
  }
}
