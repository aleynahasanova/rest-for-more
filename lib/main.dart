import 'package:flutter/material.dart';

import 'controllers/blocking_mode_session.dart';
import 'controllers/morning_routine_session.dart';
import 'controllers/night_routine_session.dart';
import 'database/app_database.dart';
import 'models/blocking_mode.dart';
import 'models/user.dart';
import 'screens/focusmode.dart';
import 'screens/login_screen.dart';
import 'screens/morningroutine.dart';
import 'screens/night_routine.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/program/program_overview_screen.dart';
import 'screens/reading_mode_screen.dart';
import 'services/program_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase.database;

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  State<MyApp> createState() =>
      _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final BlockingModeSession
      _focusTimerController;

  late final BlockingModeSession
      _readingSession;

  late final MorningRoutineSession
      _morningSession;

  late final NightRoutineSession
      _nightSession;

  User? _currentUser;

  @override
  void initState() {
    super.initState();

    final coordinator =
        BlockingSessionCoordinator();

    _focusTimerController =
        BlockingModeSession(
      mode: BlockingMode.focus,
      coordinator: coordinator,
    );

    _readingSession =
        BlockingModeSession(
      mode: BlockingMode.reading,
      coordinator: coordinator,
    );

    _morningSession =
        MorningRoutineSession();

    _nightSession =
        NightRoutineSession();
  }

  void _handleLogin(User user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _handleLogout() {
    setState(() {
      _currentUser = null;
    });
  }

  @override
  void dispose() {
    _focusTimerController.dispose();
    _readingSession.dispose();
    _morningSession.dispose();
    _nightSession.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rest For More',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // No logged-in user:
      // Login is the first screen.
      home: _currentUser == null
          ? LoginScreen(
              onLogin: _handleLogin,
            )

          // Logged-in user:
          // Open the actual application.
          : MyHomePage(
              user: _currentUser!,
              onLogout: _handleLogout,
              focusTimerController:
                  _focusTimerController,
              readingSession:
                  _readingSession,
              morningSession:
                  _morningSession,
              nightSession:
                  _nightSession,
            ),
    );
  }
}

class MyHomePage
    extends StatefulWidget {
  const MyHomePage({
    required this.user,
    required this.onLogout,
    required this.focusTimerController,
    required this.readingSession,
    required this.morningSession,
    required this.nightSession,
    super.key,
  });

  final User user;

  final VoidCallback onLogout;

  final BlockingModeSession
      focusTimerController;

  final BlockingModeSession
      readingSession;

  final MorningRoutineSession
      morningSession;

  final NightRoutineSession
      nightSession;

  @override
  State<MyHomePage> createState() =>
      _MyHomePageState();
}

class _MyHomePageState
    extends State<MyHomePage> {
  final ProgramService _programService =
      ProgramService();

  // null = checking
  // false = no programme
  // true = programme exists
  bool? _hasProgram;

  // Stops onboarding from opening
  // automatically more than once.
  bool _didAutoOpenOnboarding = false;

  @override
  void initState() {
    super.initState();

    _checkProgram(
      openOnboardingIfMissing: true,
    );
  }

  Future<bool>
      _readHasProgram() async {
    try {
      final program =
          await _programService
              .getActiveProgramByUserId(
        widget.user.userId,
      );

      return program != null;
    } catch (error) {
      debugPrint(
        'Could not check the programme: $error',
      );

      return false;
    }
  }

  Future<void> _checkProgram({
    bool openOnboardingIfMissing =
        false,
  }) async {
    final hasProgram =
        await _readHasProgram();

    if (!mounted) {
      return;
    }

    setState(() {
      _hasProgram = hasProgram;
    });

    if (openOnboardingIfMissing &&
        !hasProgram &&
        !_didAutoOpenOnboarding) {
      _didAutoOpenOnboarding = true;

      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          if (!mounted) {
            return;
          }

          _openOnboarding();
        },
      );
    }
  }

  Future<void>
      _openOnboarding() async {
    final finished =
        await Navigator.of(context)
            .push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            OnboardingFlowScreen(
          userId: widget.user.userId,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    // User left onboarding
    // before finishing.
    if (finished != true) {
      await _checkProgram();

      return;
    }

    // The 14-day plan is created
    // after onboarding is finished.
    // Wait until it exists.
    var hasProgram = false;

    for (
      var attempt = 0;
      attempt < 10 && !hasProgram;
      attempt++
    ) {
      hasProgram =
          await _readHasProgram();

      if (!hasProgram) {
        await Future<void>.delayed(
          const Duration(
            milliseconds: 300,
          ),
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _hasProgram = hasProgram;
    });

    // When the programme has been
    // created, show it immediately.
    if (hasProgram) {
      _openOverview();
    }
  }

  void _openOverview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ProgramOverviewScreen(
          userId: widget.user.userId,
        ),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ProfileScreen(
          user: widget.user,
          onOpenProgramme:
              _openOverview,
          onLogout:
              widget.onLogout,
        ),
      ),
    );
  }

  /// Temporary testing button.
  /// Deletes the current user's
  /// programme so onboarding can
  /// be tested again.
  Future<void> _resetPlan() async {
    try {
      final program =
          await _programService
              .getActiveProgramByUserId(
        widget.user.userId,
      );

      if (program != null) {
        await _programService
            .deleteProgram(
          program.programId,
        );
      }
    } catch (error) {
      debugPrint(
        'Could not reset the plan: $error',
      );
    }

    await _checkProgram();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                'Welcome, ${widget.user.firstName}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 8),

              const Text(
                'Ready to put your phone aside?',
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          FocusModeScreen(
                        controller: widget
                            .focusTimerController,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.timer_outlined,
                ),
                label: const Text(
                  'Start Focus Mode',
                ),
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          ReadingModeScreen(
                        session: widget
                            .readingSession,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.menu_book_outlined,
                ),
                label: const Text(
                  'Start Reading Mode',
                ),
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          MorningRoutineScreen(
                        session: widget
                            .morningSession,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.wb_sunny_outlined,
                ),
                label: const Text(
                  'Morning routine',
                ),
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          NightRoutineScreen(
                        session: widget
                            .nightSession,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.bedtime_outlined,
                ),
                label: const Text(
                  'Evening routine',
                ),
              ),

              const SizedBox(height: 12),

              // Profile replaces the old
              // Create Account button.
              OutlinedButton.icon(
                onPressed: _openProfile,
                icon: const Icon(
                  Icons.person_outline,
                ),
                label: const Text(
                  'Profile',
                ),
              ),

              // No programme yet.
              if (_hasProgram == false) ...[
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed:
                      _openOnboarding,
                  icon: const Icon(
                    Icons
                        .checklist_outlined,
                  ),
                  label: const Text(
                    'Start 14-day programme',
                  ),
                ),
              ],

              // Programme already exists.
              if (_hasProgram == true) ...[
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed:
                      _openOverview,
                  icon: const Icon(
                    Icons
                        .calendar_month_outlined,
                  ),
                  label: const Text(
                    'My 14 days',
                  ),
                ),

                const SizedBox(height: 4),

                TextButton(
                  onPressed: _resetPlan,
                  child: const Text(
                    'Reset my plan (test)',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}