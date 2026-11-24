import 'package:flutter/material.dart';

import '../controllers/countdown_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// One countdown appearance for every session; timing belongs to the controller.
class CountdownTimer extends StatelessWidget {
  const CountdownTimer({
    required this.remaining,
    required this.progress,
    this.textColor = AppColors.ink,
    this.progressColor = AppColors.accent,
    this.trackColor = AppColors.surfaceMuted,
    this.progressLabel = 'Session progress',
    super.key,
  });

  final Duration remaining;
  final double progress;
  final Color textColor;
  final Color progressColor;
  final Color trackColor;
  final String progressLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                color: progressColor,
                backgroundColor: trackColor,
                semanticsLabel: progressLabel,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                CountdownController.format(remaining),
                style: AppTypography.timer.copyWith(color: textColor),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
