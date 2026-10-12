import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The top of an onboarding page, in the style of the wireframe: a small
/// capital label, a large serif title and a quiet line of help text.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final eyebrow = this.eyebrow;
    final subtitle = this.subtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.brand,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            // 'serif' uses the phone's own serif font. To use the exact font
            // of the wireframe, add it to pubspec.yaml and use its name here.
            style: textTheme.headlineMedium?.copyWith(
              fontFamily: 'serif',
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.brand),
          ),
        ],
      ],
    );
  }
}
