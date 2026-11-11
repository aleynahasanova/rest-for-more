import 'package:flutter/material.dart';

import '../../controllers/blocking_mode_session.dart';
import '../../controllers/morning_routine_session.dart';
import '../../controllers/night_routine_session.dart';
import '../../models/program_day.dart';
import '../../models/user.dart';
import '../../services/program_service.dart';
import '../../theme/app_colors.dart';
import '../focusmode.dart';
import '../morningroutine.dart';
import '../night_routine.dart';
import '../onboarding/onboarding_flow_screen.dart';
import '../profile_screen.dart';
import '../program/daily_page_screen.dart';
import '../program/program_overview_screen.dart';
import '../reading_mode_screen.dart';
import 'insights_tab.dart';
import 'programme_snapshot.dart';
import 'settings_tab.dart';
import 'today_tab.dart';

/// The app after login: the three tabs (Today, Insights, Settings) with the
/// bottom navigation, and the links between all features.
///
/// It also keeps the 14-day programme: when the user has none yet, the
/// onboarding opens once; when the onboarding is finished, the user lands on
/// the home screen, where the next step of the plan is shown.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.user,
    required this.onLogout,
    required this.focusSession,
    required this.readingSession,
    required this.morningSession,
    required this.nightSession,
  });

  final User user;
  final VoidCallback onLogout;
  final BlockingModeSession focusSession;
  final BlockingModeSession readingSession;
  final MorningRoutineSession morningSession;
  final NightRoutineSession nightSession;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final ProgramService _programService = ProgramService();

  int _tab = 0;

  // null = still loading.
  ProgrammeSnapshot? _programme;

  // Stops the onboarding from opening automatically more than once.
  bool _didAutoOpenOnboarding = false;

  @override
  void initState() {
    super.initState();

    _loadProgramme(openOnboardingIfMissing: true);
  }

  // ---------------------------------------------------------------------
  // PROGRAMME
  // ---------------------------------------------------------------------

  Future<ProgrammeSnapshot> _readProgramme() async {
    try {
      final program = await _programService.getActiveProgramByUserId(
        widget.user.userId,
      );

      if (program == null) return const ProgrammeSnapshot([]);

      final days = await _programService.getProgramDays(program.programId);

      return ProgrammeSnapshot(days);
    } catch (error) {
      debugPrint('Could not load the programme: $error');

      return const ProgrammeSnapshot([]);
    }
  }

  Future<void> _loadProgramme({bool openOnboardingIfMissing = false}) async {
    final snapshot = await _readProgramme();

    if (!mounted) return;

    setState(() {
      _programme = snapshot;
    });

    if (openOnboardingIfMissing &&
        !snapshot.hasProgramme &&
        !_didAutoOpenOnboarding) {
      _didAutoOpenOnboarding = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _openOnboarding();
      });
    }
  }

  Future<void> _openOnboarding() async {
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            OnboardingFlowScreen(userId: widget.user.userId),
      ),
    );

    if (!mounted) return;

    // The user left the onboarding before the end: nothing changes.
    if (finished != true) {
      await _loadProgramme();
      return;
    }

    // The plan is made in the background right after "Finish". Wait until it
    // is saved (a few seconds at most).
    var snapshot = await _readProgramme();

    for (var attempt = 0; attempt < 10 && !snapshot.hasProgramme; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      snapshot = await _readProgramme();
    }

    if (!mounted) return;

    // The user stays on the home screen. The "Next up" card there shows the
    // first step of the new plan.
    setState(() {
      _tab = 0;
      _programme = snapshot;
    });
  }

  /// Opens a screen and reloads the programme when the user comes back, so
  /// the cards show the newest status.
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => screen),
    );

    if (!mounted) return;

    await _loadProgramme();
  }

  void _openOverview() {
    _open(ProgramOverviewScreen(userId: widget.user.userId));
  }

  void _openStep(ProgramDay day) {
    _open(DailyPageScreen(day: day));
  }

  /// TEMPORARY, for testing: deletes the plan, so the onboarding can be
  /// tested again.
  Future<void> _resetPlan() async {
    try {
      final program = await _programService.getActiveProgramByUserId(
        widget.user.userId,
      );

      if (program != null) {
        await _programService.deleteProgram(program.programId);
      }
    } catch (error) {
      debugPrint('Could not reset the plan: $error');
    }

    await _loadProgramme();
  }

  // ---------------------------------------------------------------------
  // FEATURES
  // ---------------------------------------------------------------------

  void _openFocus() {
    _open(FocusModeScreen(controller: widget.focusSession));
  }

  void _openReading() {
    _open(ReadingModeScreen(session: widget.readingSession));
  }

  void _openMorning() {
    _open(
      MorningRoutineScreen(
        session: widget.morningSession,
        userId: widget.user.userId,
      ),
    );
  }

  void _openEvening() {
    _open(
      NightRoutineScreen(
        session: widget.nightSession,
        userId: widget.user.userId,
      ),
    );
  }

  void _openProfile() {
    _open(
      ProfileScreen(
        user: widget.user,
        onOpenProgramme: _openOverview,
        onLogout: widget.onLogout,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final programme = _programme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _tab,
        children: [
          TodayTab(
            focusSession: widget.focusSession,
            readingSession: widget.readingSession,
            morningSession: widget.morningSession,
            nightSession: widget.nightSession,
            programme: programme,
            onOpenFocus: _openFocus,
            onOpenReading: _openReading,
            onOpenEvening: _openEvening,
            onOpenMorning: _openMorning,
            onOpenStep: _openStep,
            onOpenOverview: _openOverview,
            onStartProgramme: _openOnboarding,
          ),
          InsightsTab(
            programme: programme,
            onOpenOverview: _openOverview,
          ),
          SettingsTab(
            hasProgramme: programme?.hasProgramme ?? false,
            onOpenProfile: _openProfile,
            onOpenMorning: _openMorning,
            onOpenEvening: _openEvening,
            onOpenOverview: _openOverview,
            onResetPlan: _resetPlan,
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.surfaceMuted,
          elevation: 0,
          selectedIndex: _tab,
          onDestinationSelected: (index) {
            setState(() {
              _tab = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart),
              selectedIcon: Icon(Icons.show_chart),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune),
              selectedIcon: Icon(Icons.tune),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
