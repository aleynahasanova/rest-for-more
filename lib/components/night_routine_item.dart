import 'package:flutter/material.dart';

import '../models/routine_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class NightRoutineItemCard extends StatelessWidget {
  const NightRoutineItemCard({
    required this.item,
    required this.time,
    this.icon = Icons.nightlight_outlined,
    this.onEdit,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
    super.key,
  });

  final RoutineItem item;
  final String time;
  final IconData icon;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  String get _duration {
    final minutes = item.durationMinutes;

    if (minutes == null) return 'Duration not set';
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    return remainder == 0 ? '$hours hr' : '$hours hr $remainder min';
  }

  @override
  Widget build(BuildContext context) {
    final hasActions =
        onEdit != null ||
        onDelete != null ||
        onMoveUp != null ||
        onMoveDown != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              time,
              style: AppTypography.bodyMuted.copyWith(
                color: AppColors.nightTextMuted,
              ),
            ),
          ),

          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.nightSurfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.nightAccent),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.body.copyWith(
                      color: AppColors.nightText,
                    ),
                  ),
                  Text(
                    _duration,
                    style: AppTypography.bodyMuted.copyWith(
                      color: AppColors.nightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (hasActions)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.nightTextMuted,
              ),
              color: AppColors.nightSurface,
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit?.call();
                    break;
                  case 'up':
                    onMoveUp?.call();
                    break;
                  case 'down':
                    onMoveDown?.call();
                    break;
                  case 'delete':
                    onDelete?.call();
                    break;
                }
              },
              itemBuilder: (_) => [
                if (onEdit != null)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (onMoveUp != null)
                  const PopupMenuItem(value: 'up', child: Text('Move up')),
                if (onMoveDown != null)
                  const PopupMenuItem(value: 'down', child: Text('Move down')),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }
}
