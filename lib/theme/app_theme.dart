import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: Brightness.light,
        ).copyWith(
          surface: AppColors.surface,
          primary: AppColors.brand,
          onPrimary: AppColors.surface,
          secondary: AppColors.brandTint,
          tertiary: AppColors.accent,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.ink,
          outline: AppColors.brandTint,
          outlineVariant: AppColors.border,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      cardTheme: const CardThemeData(
        color: AppColors.surfaceMuted,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.ink),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
