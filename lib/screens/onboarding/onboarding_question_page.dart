import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'onboarding_header.dart';
import 'onboarding_questions.dart';

/// Shows one question with its choices. Used for every choose-one question,
/// so the look is only written once.
class OnboardingQuestionPage extends StatelessWidget {
  const OnboardingQuestionPage({
    super.key,
    required this.question,
    required this.eyebrow,
    required this.selectedValue,
    required this.onSelected,
  });

  final OnboardingQuestion question;

  /// Small label above the title, for example "Question 3 of 8".
  final String eyebrow;

  /// The value of the chosen option, or null when nothing is chosen yet.
  final String? selectedValue;

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        OnboardingHeader(
          eyebrow: eyebrow,
          title: question.title,
          subtitle: question.subtitle,
        ),
        const SizedBox(height: 24),
        for (final option in question.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionTile(
              label: option.label,
              selected: option.value == selectedValue,
              onTap: () => onSelected(option.value),
            ),
          ),
      ],
    );
  }
}

/// A choice. Like the time chips in the wireframe: soft beige when not chosen,
/// brown when chosen. A check mark is added too, so the choice is not shown
/// by colour alone.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);
    final textColor = selected ? AppColors.surface : AppColors.ink;

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? AppColors.brand : AppColors.surfaceMuted,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Expanded lets long text wrap when the user uses large text.
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: textColor),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.check, color: textColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
