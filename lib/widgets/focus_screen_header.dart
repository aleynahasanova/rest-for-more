import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FocusScreenHeader extends StatelessWidget {
  const FocusScreenHeader({
    this.trailing,
    this.onBack,
    super.key,
  });

  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back,
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Text(
          'Focus',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.ink),
        ),
      ),
    );
  }
}
