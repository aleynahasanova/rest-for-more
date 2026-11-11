import 'package:flutter/material.dart';

import '../../controllers/blocking_mode_session.dart';
import '../../controllers/focus_timer_controller.dart';
import '../../controllers/morning_routine_session.dart';
import '../../controllers/night_routine_session.dart';
import '../../models/program_day.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/countdown_timer.dart';
import 'home_widgets.dart';
import 'programme_snapshot.dart';

/// The home screen ("Today").
///
/// When a focus or reading session is running (or paused), the big timer is
/// shown on top. When no timer is on, the "Next up" card is shown instead,
/// with the next step of the 14-day programme. Below it are the moments.
class TodayTab extends StatelessWidget {
  const TodayTab({
    super.key,
    required this.focusSession,
    required this.readingSession,
    required this.morningSession,
    required this.nightSession,
    required this.programme,
    required this.onOpenFocus,
    required this.onOpenReading,
    required this.onOpenEvening,
    required this.onOpenMorning,
    required this.onOpenStep,
    required this.onOpenOverview,
    required this.onStartProgramme,
  });

  final BlockingModeSession focusSession;
  final BlockingModeSession readingSession;
  final MorningRoutineSession morningSession;
  final NightRoutineSession nightSession;

  /// null while the programme is still loading.
  final ProgrammeSnapshot? programme;

  final VoidCallback onOpenFocus;
  final VoidCallback onOpenReading;
  final VoidCallback onOpenEvening;
  final VoidCallback onOpenMorning;
  final ValueChanged<ProgramDay> onOpenStep;
  final VoidCallback onOpenOverview;
  final VoidCallback onStartProgramme;

  static String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static bool _isOn(BlockingModeSession session) {
    return session.status == FocusTimerStatus.running ||
        session.status == FocusTimerStatus.paused;
  }

  static String _subtitle(BlockingModeSession session, String idle) {
    switch (session.status) {
      case FocusTimerStatus.running:
        return 'In progress · ${session.formattedRemaining} left';
      case FocusTimerStatus.paused:
        return 'Paused · ${session.formattedRemaining} left';
      case FocusTimerStatus.ready:
      case FocusTimerStatus.completed:
        return idle;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds every time a timer or a routine changes.
    return ListenableBuilder(
      listenable: Listenable.merge([
        focusSession,
        readingSession,
        morningSession,
        nightSession,
      ]),
      builder: (context, _) {
        BlockingModeSession? onSession;

        if (_isOn(focusSession)) {
          onSession = focusSession;
        } else if (_isOn(readingSession)) {
          onSession = readingSession;
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              HomeSectionLabel(_greeting()),
              const SizedBox(height: 8),
              Text(
                'Where do you want to make room for rest?',
                style: AppTypography.headline.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 24),

              // The timer is only shown when a timer is on.
              if (onSession != null)
                _ActiveTimer(
                  session: onSession,
                  onTap: onSession == focusSession
                      ? onOpenFocus
                      : onOpenReading,
                )
              else
                _NextUpCard(
                  programme: programme,
                  onOpenStep: onOpenStep,
                  onOpenOverview: onOpenOverview,
                  onStartProgramme: onStartProgramme,
                ),

              const SizedBox(height: 28),
              const HomeSectionLabel('Moments'),
              const SizedBox(height: 10),
              HomeRow(
                icon: Icons.work_outline,
                title: 'Focus',
                subtitle: _subtitle(
                  focusSession,
                  'Working and studying without distractions',
                ),
                onTap: onOpenFocus,
              ),
              const SizedBox(height: 10),
              HomeRow(
                icon: Icons.menu_book_outlined,
                title: 'Reading',
                subtitle: _subtitle(
                  readingSession,
                  'A book, without interruptions',
                ),
                onTap: onOpenReading,
              ),
              const SizedBox(height: 10),
              HomeRow(
                icon: Icons.bedtime_outlined,
                title: 'Evening',
                subtitle: nightSession.isActive
                    ? 'In progress'
                    : 'Wind down calmly, at your own pace',
                onTap: onOpenEvening,
              ),
              const SizedBox(height: 10),
              HomeRow(
                icon: Icons.wb_sunny_outlined,
                title: 'Morning',
                subtitle: morningSession.isActive
                    ? 'In progress'
                    : 'Start the day without a screen',
                onTap: onOpenMorning,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The big round timer, like the home screen in the wireframe.
class _ActiveTimer extends StatelessWidget {
  const _ActiveTimer({required this.session, required this.onTap});

  final BlockingModeSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final paused = session.status == FocusTimerStatus.paused;
    final title = session.mode.title;

    return Semantics(
      button: true,
      label: '$title session, ${session.formattedRemaining} left'
          '${paused ? ', paused' : ''}. Open session.',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              CountdownTimer(
                remaining: session.remaining,
                progress: session.progress,
                progressLabel: '$title session progress',
              ),
              const SizedBox(height: 14),
              HomeSectionLabel('$title · ${paused ? 'paused' : 'running'}'),
              const SizedBox(height: 6),
              Text(
                session.statusMessage,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The beige card shown when no timer is on: the next programme step.
class _NextUpCard extends StatelessWidget {
  const _NextUpCard({
    required this.programme,
    required this.onOpenStep,
    required this.onOpenOverview,
    required this.onStartProgramme,
  });

  final ProgrammeSnapshot? programme;
  final ValueChanged<ProgramDay> onOpenStep;
  final VoidCallback onOpenOverview;
  final VoidCallback onStartProgramme;

  @override
  Widget build(BuildContext context) {
    final snapshot = programme;

    // Still loading: show nothing, so the card does not jump around.
    if (snapshot == null) return const SizedBox(height: 72);

    String label;
    String text;
    String? caption;
    VoidCallback onTap;

    final now = DateTime.now();
    final day = snapshot.hasProgramme ? snapshot.nextStep(now) : null;

    if (!snapshot.hasProgramme) {
      label = 'Your plan';
      text = 'Start your 14-day programme';
      caption = 'Answer a few questions and get a plan made for you.';
      onTap = onStartProgramme;
    } else if (day == null) {
      label = 'Your plan';
      text = 'You finished the 14 days';
      caption = 'Your own routine continues.';
      onTap = onOpenOverview;
    } else {
      switch (snapshot.timingOf(day, now)) {
        case StepTiming.today:
          label = 'Today · Day ${day.dayNumber}';
          caption = 'Your step for today.';
        case StepTiming.stillOpen:
          label = 'Still open · Day ${day.dayNumber}';
          caption = 'You can pick this step up whenever you like.';
        case StepTiming.comingUp:
          label = 'Coming up · Day ${day.dayNumber}';
          caption = 'You can already read it.';
        case StepTiming.unscheduled:
          label = 'Next step · Day ${day.dayNumber}';
          caption = null;
      }

      text = day.title;
      onTap = () => onOpenStep(day);
    }

    final borderRadius = BorderRadius.circular(16);

    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.brandTint,
                        ),
                        const SizedBox(width: 6),
                        Flexible(child: HomeSectionLabel(label)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      text,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AppColors.ink,
                      ),
                    ),
                    if (caption != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        caption,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.brandTint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.brandTint),
            ],
          ),
        ),
      ),
    );
  }
}
