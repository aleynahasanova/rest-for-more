import 'package:flutter/material.dart';

import '../models/routine_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A reusable flat routine step row, backed by the existing database model.
/// Descriptions stay available in the editor. Completion lives in the menu so
/// the schedule retains the prototype's icon rather than a checkbox.
class RoutineItemCard extends StatelessWidget {
  const RoutineItemCard({
    required this.item,
    this.time,
    this.icon,
    this.isCompleted = false,
    this.onCompletedChanged,
    this.onEdit,
    this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
    super.key,
  });
  final RoutineItem item;
  final String? time;
  final IconData? icon;
  final bool isCompleted;
  final ValueChanged<bool>? onCompletedChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  static String? clockTime(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)(?::[0-5]\d(?:\.\d+)?)?$')
        .firstMatch(value.trim());
    return match == null ? null : '${match[1]}:${match[2]}';
  }

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
        onMoveDown != null ||
        onCompletedChanged != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              time ?? clockTime(item.startTime) ?? '—',
              style: AppTypography.bodyMuted,
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.check_circle_outline_rounded,
              size: 18,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Semantics(
              button: onEdit != null,
              child: GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTypography.body),
                    Text(_duration, style: AppTypography.bodyMuted),
                  ],
                ),
              ),
            ),
          ),
          if (hasActions)
            PopupMenuButton<String>(
              tooltip: 'Options for ${item.title}',
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: AppColors.brandTint,
              ),
              color: AppColors.surface,
              onSelected: (value) {
                switch (value) {
                  case 'duration':
                  case 'rename':
                    onEdit?.call();
                  case 'up':
                    onMoveUp?.call();
                  case 'down':
                    onMoveDown?.call();
                  case 'remove':
                    onDelete?.call();
                  case 'complete':
                    onCompletedChanged?.call(!isCompleted);
                }
              },
              itemBuilder: (_) => [
                if (onEdit != null) ...[
                  const PopupMenuItem(
                    value: 'duration',
                    child: Text('Change duration'),
                  ),
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                ],
                if (onMoveUp != null)
                  const PopupMenuItem(value: 'up', child: Text('Move up')),
                if (onMoveDown != null)
                  const PopupMenuItem(value: 'down', child: Text('Move down')),
                if (onDelete != null)
                  const PopupMenuItem(value: 'remove', child: Text('Delete')),
                if (onCompletedChanged != null)
                  PopupMenuItem(
                    value: 'complete',
                    child: Text(
                      isCompleted ? 'Mark incomplete' : 'Mark complete',
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
