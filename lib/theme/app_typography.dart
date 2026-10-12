import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Exact body styles used by the client's morning schedule.
abstract final class AppTypography {
  static const headline = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );
  static const timer = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 48,
    fontWeight: FontWeight.w300,
    letterSpacing: 1,
    color: AppColors.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const body = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 15,
    height: 1.55,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );
  static const bodyMuted = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.brandTint,
  );
}
