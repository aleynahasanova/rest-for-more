import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class VerticalDurationSlider extends StatelessWidget {
  const VerticalDurationSlider({
    required this.values,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<int> values;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final maxIndex = (values.length - 1).toDouble();
    final selectedIndex = values.indexOf(selected).clamp(0, values.length - 1);

    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.ink,
                inactiveTrackColor: AppColors.surfaceMuted,
                thumbColor: AppColors.ink,
                overlayColor: AppColors.ink.withValues(alpha: 0.12),
                trackHeight: 6,
              ),
              child: Slider(
                min: 0,
                max: maxIndex,
                divisions: values.length - 1,
                value: selectedIndex.toDouble(),
                onChanged: (value) {
                  final minutes = values[value.round()];
                  if (minutes != selected) {
                    HapticFeedback.selectionClick();
                    onChanged(minutes);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final minutes in values)
              Text(
                '$minutes',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: minutes == selected
                          ? AppColors.ink
                          : AppColors.ink.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
      ],
    );
  }
}
