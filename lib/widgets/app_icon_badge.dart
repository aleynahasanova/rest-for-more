import 'package:flutter/material.dart';

import '../models/blockable_app.dart';

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    required this.app,
    this.size = 36,
    super.key,
  });

  final BlockableApp app;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: app.iconColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        app.icon,
        size: size * 0.5,
        color: app.iconColor,
      ),
    );
  }
}
