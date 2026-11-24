import 'package:flutter/material.dart';

import '../../dev/dev_user.dart';
import '../../models/program.dart';
import '../../models/program_day.dart';
import '../../services/program_service.dart';
import '../../theme/app_colors.dart';
import '../onboarding/onboarding_flow_screen.dart';
import '../onboarding/onboarding_header.dart';
import 'daily_page_screen.dart';

/// The overview of the personal 14-day programme (App design, Flow B).
///
/// It shows a card with the step for today, and below it the 14 days in two
/// weeks, with the steps the user marked as done. Every day can be opened.
/// There is no "failed" or "missed" label: a day in the past that is not done
/// simply says "Still open", and it stays readable (App design: missed days
/// are not failures).
///
/// After day 14 it shows "Your own routine continues", so the end of the
/// programme is not an empty screen.
class ProgramOverviewScreen extends StatefulWidget {
  const ProgramOverviewScreen({super.key, this.userId});

  /// The user whose programme is shown.
  /// TODO: remove the [DevUser] fallback when login provides the userId.
  final String? userId;

  @override
  State<ProgramOverviewScreen> createState() => _ProgramOverviewScreenState();
}

class _Loaded {
  const _Loaded(this.program, this.days);

  /// null when the user has no active programme yet.
  final Program? program;
  final List<ProgramDay> days;
}

enum _Tag { done, today, stillOpen, comingUp, none }

class _ProgramOverviewScreenState extends State<ProgramOverviewScreen> {
  final ProgramService _programService = ProgramService();

  late Future<_Loaded> _future = _load();

  Future<_Loaded> _load() async {
    final userId = widget.userId ?? await DevUser.ensure();
    final program = await _programService.getActiveProgramByUserId(userId);

    if (program == null) return const _Loaded(null, []);

    final days = await _programService.getProgramDays(program.programId);

    return _Loaded(program, days);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openDay(ProgramDay day) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => DailyPageScreen(day: day)),
    );

    // Come back with the newest status (for example "Done").
    if (!mounted) return;
    _reload();
  }

  Future<void> _startOnboarding() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OnboardingFlowScreen(userId: widget.userId),
      ),
    );

    // The plan is made in the background when onboarding is finished. Wait a
    // moment, so it is saved before the list is loaded again.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    _reload();
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// 'yyyy-MM-dd', the same text the plan generator saves.
  static String _dateKey(DateTime date) {
    return '${date.year}-${_two(date.month)}-${_two(date.day)}';
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  static String? _prettyDate(String? key) {
    if (key == null || key.isEmpty) return null;

    final date = DateTime.tryParse(key);
    if (date == null) return null;

    return '${_weekdays[date.weekday - 1]} ${date.day} '
        '${_months[date.month - 1]}';
  }

  static _Tag _tagFor(ProgramDay day, String todayKey) {
    if (day.completedAt != null) return _Tag.done;

    final key = day.scheduledDate;
    if (key == null || key.isEmpty) return _Tag.none;

    final comparison = key.compareTo(todayKey);
    if (comparison == 0) return _Tag.today;
    if (comparison < 0) return _Tag.stillOpen;
    return _Tag.comingUp;
  }

  /// The day shown in the big card: today's step first, then the earliest
  /// step that is still open, then the next one that is coming up.
  static ProgramDay? _focusDay(List<ProgramDay> days, String todayKey) {
    ProgramDay? firstWith(_Tag tag) {
      for (final day in days) {
        if (_tagFor(day, todayKey) == tag) return day;
      }
      return null;
    }

    return firstWith(_Tag.today) ??
        firstWith(_Tag.stillOpen) ??
        firstWith(_Tag.comingUp) ??
        firstWith(_Tag.none);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your programme'),
        titleTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.ink,
            ),
      ),
      body: SafeArea(
        child: FutureBuilder<_Loaded>(
          future: _future,
          builder: (context, snapshot) {
            final loaded = snapshot.data;

            if (snapshot.hasError && loaded == null) {
              return _MessageView(
                title: 'Something went wrong.',
                actionLabel: 'Try again',
                onAction: _reload,
              );
            }

            // Keep showing the old list while the new one loads.
            if (loaded == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (loaded.program == null || loaded.days.isEmpty) {
              return _MessageView(
                title: 'No plan yet',
                text: 'Answer a few questions and your 14 days will appear '
                    'here.',
                actionLabel: 'Start',
                onAction: _startOnboarding,
              );
            }

            return _buildList(context, loaded.days);
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ProgramDay> days) {
    final textTheme = Theme.of(context).textTheme;
    final todayKey = _dateKey(DateTime.now());
    final doneCount = days.where((day) => day.completedAt != null).length;
    final allDone = doneCount == ProgramDay.totalDays;
    final focusDay = allDone ? null : _focusDay(days, todayKey);

    Widget week(String label, int firstDay, int lastDay) {
      final weekDays = days
          .where((day) => day.dayNumber >= firstDay && day.dayNumber <= lastDay)
          .toList();

      if (weekDays.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _SectionLabel(label),
          const SizedBox(height: 12),
          for (final day in weekDays)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DayTile(
                day: day,
                tag: _tagFor(day, todayKey),
                dateText: _prettyDate(day.scheduledDate),
                onTap: () => _openDay(day),
              ),
            ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        OnboardingHeader(
          eyebrow: 'Your programme',
          title: 'Your 14 days',
          subtitle: 'You marked $doneCount of ${ProgramDay.totalDays} steps '
              'as done.',
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: doneCount / ProgramDay.totalDays,
            minHeight: 8,
            color: AppColors.brand,
            backgroundColor: AppColors.surfaceMuted,
            semanticsLabel: '$doneCount of ${ProgramDay.totalDays} done',
          ),
        ),
        const SizedBox(height: 24),
        if (focusDay != null)
          _FocusCard(
            day: focusDay,
            tag: _tagFor(focusDay, todayKey),
            dateText: _prettyDate(focusDay.scheduledDate),
            onTap: () => _openDay(focusDay),
          ),
        week('Week 1', 1, 7),
        week('Week 2', 8, 14),
        const SizedBox(height: 16),
        Text(
          allDone
              ? 'You finished the 14 days. Your own routine continues.'
              : 'After day 14, your own routine continues.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'The steps are not a test. They stay here, so you can read them '
          'again whenever you like.',
          style: textTheme.bodySmall?.copyWith(color: AppColors.brand),
        ),
      ],
    );
  }
}

/// A small capital label above a group, like "MOMENTEN" in the wireframe.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.brand,
            letterSpacing: 1.4,
          ),
    );
  }
}

/// The big brown card with the step for today, like the brown card in the
/// wireframe.
class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.day,
    required this.tag,
    required this.dateText,
    required this.onTap,
  });

  final ProgramDay day;
  final _Tag tag;
  final String? dateText;
  final VoidCallback onTap;

  String get _label {
    switch (tag) {
      case _Tag.today:
        return 'Today · Day ${day.dayNumber}';
      case _Tag.stillOpen:
        return 'Still open · Day ${day.dayNumber}';
      case _Tag.comingUp:
        return 'Coming up · Day ${day.dayNumber}';
      case _Tag.done:
      case _Tag.none:
        return 'Next step · Day ${day.dayNumber}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isUpcoming = tag == _Tag.comingUp;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.surface.withValues(alpha: 0.75),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            day.title,
            style: textTheme.headlineSmall?.copyWith(
              fontFamily: 'serif',
              fontWeight: FontWeight.w400,
              color: AppColors.surface,
            ),
          ),
          if (isUpcoming && dateText != null) ...[
            const SizedBox(height: 8),
            Text(
              'Starts $dateText',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.surface.withValues(alpha: 0.8),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.brand,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isUpcoming ? 'Read it already' : 'Open this step'),
          ),
        ],
      ),
    );
  }
}

/// One row: the day number (or a check), the title, the date and the status.
class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.tag,
    required this.dateText,
    required this.onTap,
  });

  final ProgramDay day;
  final _Tag tag;
  final String? dateText;
  final VoidCallback onTap;

  String get _tagText {
    switch (tag) {
      case _Tag.done:
        return 'Done';
      case _Tag.today:
        return 'Today';
      case _Tag.stillOpen:
        return 'Still open';
      case _Tag.comingUp:
        return 'Coming up';
      case _Tag.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderRadius = BorderRadius.circular(14);

    final details = [
      if (dateText != null) dateText!,
      if (_tagText.isNotEmpty) _tagText,
    ].join(' · ');

    final semanticsLabel = 'Day ${day.dayNumber}, ${day.title}'
        '${day.isReviewDay ? ', review' : ''}'
        '${details.isEmpty ? '' : ', $details'}';

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _DayBadge(number: day.dayNumber, tag: tag),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (details.isNotEmpty || day.isReviewDay) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (details.isNotEmpty)
                              Text(
                                details,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.brand,
                                ),
                              ),
                            if (day.isReviewDay) const _ReviewChip(),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.brand),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The round badge at the start of a row.
class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.number, required this.tag});

  final int number;
  final _Tag tag;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;

    if (tag == _Tag.done) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: AppColors.surface),
      );
    }

    final isToday = tag == _Tag.today;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isToday ? AppColors.accent : AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Review',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.ink,
            ),
      ),
    );
  }
}

/// A short message with one button, for "no plan yet" and errors.
class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.title,
    this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String? text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final text = this.text;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OnboardingHeader(title: title, subtitle: text),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
