import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'onboarding_header.dart';
import 'onboarding_illustration.dart';
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

  // Rough sizes, used to decide how big the picture can be.
  static const double _optionHeight = 48;
  static const double _optionGap = 8;
  static const double _headerHeight = 100;
  static const double _headerWithSubtitleHeight = 125;
  static const double _gaps = 16 + 16 + 12 + 16;
  static const double _maxPictureHeight = 130;
  static const double _minPictureHeight = 64;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        // The picture gets the room that is left. On a small screen it
        // becomes smaller, or disappears, so the choices always fit without
        // scrolling.
        final optionsHeight =
            question.options.length * (_optionHeight + _optionGap) * textScale;
        final headerHeight = (question.subtitle == null
                ? _headerHeight
                : _headerWithSubtitleHeight) *
            textScale;
        final free =
            constraints.maxHeight - optionsHeight - headerHeight - _gaps;
        final pictureHeight = free.clamp(0.0, _maxPictureHeight);
        final showPicture = pictureHeight >= _minPictureHeight;

        // Still scrollable as a safety net (very large text).
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showPicture) ...[
                OnboardingIllustration(
                  icon: question.icon,
                  height: pictureHeight,
                ),
                const SizedBox(height: 12),
              ],
              OnboardingHeader(
                compact: true,
                eyebrow: eyebrow,
                title: question.title,
                subtitle: question.subtitle,
              ),
              const SizedBox(height: 16),
              for (final option in question.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: _optionGap),
                  child: _OptionTile(
                    label: option.label,
                    selected: option.value == selectedValue,
                    onTap: () => onSelected(option.value),
                  ),
                ),
            ],
          ),
        );
      },
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Expanded lets long text wrap when the user uses large text.
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: textColor),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.check, size: 20, color: textColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}