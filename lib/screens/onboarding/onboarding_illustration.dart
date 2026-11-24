import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A calm picture above a question or message: a big icon on soft circles.
///
/// It is drawn in code, so no image files are needed and it always uses the
/// colours of the app. It is only decoration, so screen readers skip it.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.icon, this.height = 150});

  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: -24,
              top: -24,
              child: _Circle(size: 96, color: AppColors.brand.withOpacity(0.10)),
            ),
            Positioned(
              right: -16,
              bottom: -32,
              child: _Circle(size: 110, color: AppColors.brand.withOpacity(0.14)),
            ),
            Positioned(
              right: 48,
              top: 22,
              child: _Circle(size: 14, color: AppColors.brand.withOpacity(0.25)),
            ),
            Positioned(
              left: 56,
              bottom: 26,
              child: _Circle(size: 10, color: AppColors.brand.withOpacity(0.25)),
            ),
            Container(
              width: height * 0.62,
              height: height * 0.62,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: height * 0.32, color: AppColors.surface),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
