import 'package:flutter/material.dart';

import '../../models/program_day.dart';
import '../../theme/app_colors.dart';
import '../onboarding/onboarding_header.dart';

/// The page for one day of the 14-day programme (App design, Flow B).
///
/// It shows the day number, a personal title, a few short paragraphs, one main
/// action, and the three extra buttons: "Make it smaller", "Different
/// situation today" and "Why this step?". Completing the step is one tap.
///
/// This screen does not use the database. It only works with the [ProgramDay]
/// it is given, so it can be tested with fake data first.
class DailyPageScreen extends StatefulWidget {
  const DailyPageScreen({super.key, required this.day});

  final ProgramDay day;

  @override
  State<DailyPageScreen> createState() => _DailyPageScreenState();
}

class _DailyPageScreenState extends State<DailyPageScreen> {
  late ProgramDay _day = widget.day;

  // True when the user chose the smaller version of today's step.
  bool _useSmaller = false;

  bool get _isDone => _day.completedAt != null;

  void _markDone() {
    setState(() {
      _day = _day.markCompleted(
        DateTime.now(),
        usedSmallerAlternative: _useSmaller,
      );
    });
  }

  void _showSmaller() {
    _showSheet(
      title: 'Make it smaller',
      text: _day.smallerAlternative,
      actionLabel: _useSmaller ? 'Go back to the full step' : 'Do this instead',
      onAction: () {
        setState(() {
          _useSmaller = !_useSmaller;
        });
      },
    );
  }

  void _showDifferentSituation() {
    // TODO: the choices still need to be decided with the team and the
    // clients. This is placeholder text.
    _showSheet(
      title: 'Different situation today',
      text: 'Here you will be able to choose another way to do today\'s step '
          'when today is not like other days. The choices are still to be '
          'decided.',
    );
  }

  void _showWhy() {
    _showSheet(title: 'Why this step?', text: _day.whyThisStep);
  }

  void _showSheet({
    required String title,
    required String text,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingHeader(title: title),
                const SizedBox(height: 12),
                Text(text, style: Theme.of(sheetContext).textTheme.bodyLarge),
                const SizedBox(height: 24),
                if (actionLabel != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: _filledStyle,
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        onAction?.call();
                      },
                      child: Text(actionLabel),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static final ButtonStyle _filledStyle = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    var eyebrow = 'Day ${_day.dayNumber} of ${ProgramDay.totalDays}';
    if (_day.isReviewDay) {
      eyebrow = '$eyebrow · Review';
    }

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  OnboardingHeader(eyebrow: eyebrow, title: _day.title),
                  const SizedBox(height: 16),
                  for (final paragraph in _day.paragraphs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(paragraph, style: textTheme.bodyLarge),
                    ),
                  const SizedBox(height: 8),
                  _StepCard(
                    label: _useSmaller ? 'Your smaller step' : "Today's step",
                    text: _useSmaller
                        ? _day.smallerAlternative
                        : _day.primaryAction,
                  ),
                  const SizedBox(height: 16),
                  _SecondaryButton(
                    label: 'Make it smaller',
                    onPressed: _showSmaller,
                  ),
                  const SizedBox(height: 12),
                  _SecondaryButton(
                    label: 'Different situation today',
                    onPressed: _showDifferentSituation,
                  ),
                  const SizedBox(height: 12),
                  _SecondaryButton(
                    label: 'Why this step?',
                    onPressed: _showWhy,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isDone) ...[
                    Text(
                      "That's all for today. You can put your phone away now.",
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.brand,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    style: _filledStyle,
                    onPressed: _isDone ? null : _markDone,
                    icon: Icon(_isDone ? Icons.check : Icons.check_circle_outline),
                    label: Text(_isDone ? 'Done for today' : 'Mark as done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The beige card with today's step, like the cards in the wireframe.
class _StepCard extends StatelessWidget {
  const _StepCard({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.brand,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// An outlined button, like "Stap toevoegen" in the wireframe.
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppColors.brand,
        side: const BorderSide(color: AppColors.brand),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}