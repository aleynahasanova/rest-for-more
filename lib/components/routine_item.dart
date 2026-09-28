import 'package:flutter/material.dart';

import '../models/routine_item.dart';

/// One block in a guided routine checklist.
///
/// The parent owns completion, editing, and ordering. Pass [onEdit] to show an
/// edit button, and [onCompletedChanged] to enable the checkbox. Rebuild with
/// updated [item] or [isCompleted] values after handling those callbacks.
/// Accepts the model returned by RoutineService directly. Completion is local
/// session state; editing and saving remain the parent's responsibility.
class RoutineItemCard extends StatelessWidget {
  const RoutineItemCard({
    required this.item,
    this.isCompleted = false,
    this.onCompletedChanged,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final RoutineItem item;
  final bool isCompleted;
  final ValueChanged<bool>? onCompletedChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  // Stored times use HH:mm or HH:mm:ss (optionally fractional seconds).
  // Render at minute precision without modifying the model's stored value.
  static TimeOfDay? _parseStartTime(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{2}):(\d{2})(?::([0-5]\d)(?:\.\d+)?)?$')
        .firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    if (hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = item.description;
    final startTime = _parseStartTime(item.startTime);
    final durationMinutes = item.durationMinutes;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isCompleted,
              semanticLabel: item.title,
              onChanged: onCompletedChanged == null
                  ? null
                  : (value) => onCompletedChanged!(value!),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (description != null &&
                        description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(description, style: theme.textTheme.bodyMedium),
                    ],
                    if (item.startTime != null || durationMinutes != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          if (item.startTime != null)
                            Text(
                              startTime == null
                                  ? 'Start time unavailable'
                                  : 'Starts at ${startTime.format(context)}',
                              style: theme.textTheme.labelLarge,
                            ),
                          if (durationMinutes != null)
                            Text(
                              '$durationMinutes min',
                              semanticsLabel: '$durationMinutes minutes',
                              style: theme.textTheme.labelLarge,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit ${item.title}',
                icon: const Icon(Icons.edit_outlined),
              ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete ${item.title}',
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    );
  }
}
