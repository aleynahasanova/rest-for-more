import 'package:flutter/material.dart';

import 'database/app_database.dart';
import 'dev/dev_user.dart';

import 'screens/focusmode.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';
import 'screens/program/program_overview_screen.dart';
import 'screens/registration_screen.dart';
import 'services/program_service.dart';
import 'theme/app_theme.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.database;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FocusTimerController _focusTimerController;

  @override
  void initState() {
    super.initState();
    _focusTimerController = FocusTimerController();
  }

  @override
  void dispose() {
    _focusTimerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Mode',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MyHomePage(focusTimerController: _focusTimerController),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.focusTimerController, super.key});

  final FocusTimerController focusTimerController;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ProgramService _programService = ProgramService();

  // null = still checking, false = no plan yet, true = the user has a plan.
  bool? _hasProgram;

  @override
  void initState() {
    super.initState();
    _checkProgram();
  }

  /// Does the user have an active 14-day programme?
  /// TODO: use the real userId when login is connected (DevUser is temporary).
  Future<bool> _readHasProgram() async {
    try {
      final userId = await DevUser.ensure();
      final program = await _programService.getActiveProgramByUserId(userId);

      return program != null;
    } catch (error) {
      debugPrint('Could not check the programme: $error');
      return false;
    }
  }

  Future<void> _checkProgram() async {
    final hasProgram = await _readHasProgram();

    if (!mounted) return;

    setState(() {
      _hasProgram = hasProgram;
    });
  }

  Future<void> _openOnboarding() async {
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const OnboardingFlowScreen(),
      ),
    );

    if (!mounted) return;

    // The user left the onboarding before the end: nothing changes.
    if (finished != true) {
      await _checkProgram();
      return;
    }

    // The plan is made in the background right after "Finish". Wait until it
    // is saved (a few seconds at most).
    var hasProgram = false;

    for (var attempt = 0; attempt < 10 && !hasProgram; attempt++) {
      hasProgram = await _readHasProgram();

      if (!hasProgram) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }

    if (!mounted) return;

    setState(() {
      _hasProgram = hasProgram;
    });

    // Show the 14 days straight away.
    if (hasProgram) _openOverview();
  }

  void _openOverview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ProgramOverviewScreen(),
      ),
    );
  }

  /// TEMPORARY, for testing: deletes the plan, so the onboarding shows again.
  Future<void> _resetPlan() async {
    try {
      final userId = await DevUser.ensure();
      final program = await _programService.getActiveProgramByUserId(userId);

      if (program != null) {
        await _programService.deleteProgram(program.programId);
      }
    } catch (error) {
      debugPrint('Could not reset the plan: $error');
    }

    await _checkProgram();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ready to put your phone aside?'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => FocusModeScreen(
                      controller: widget.focusTimerController,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Start Focus Mode'),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const RegistrationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Create Account'),
            ),

            // No plan yet: the onboarding is offered. When it is finished and
            // the plan exists, this button is gone and "My 14 days" shows.
            if (_hasProgram == false) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openOnboarding,
                icon: const Icon(Icons.checklist_outlined),
                label: const Text('Onboarding'),
              ),
            ],

            if (_hasProgram == true) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openOverview,
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('My 14 days'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _resetPlan,
                child: const Text('Reset my plan (test)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}