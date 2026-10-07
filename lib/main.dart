import 'package:flutter/material.dart';

import 'database/app_database.dart';
import 'controllers/morning_routine_session.dart';
import 'controllers/night_routine_session.dart';

import 'screens/focusmode.dart';
import 'screens/morningroutine.dart';
import 'screens/night_routine.dart';
import 'screens/registration_screen.dart';
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
  late final MorningRoutineSession _morningSession;
  late final NightRoutineSession _nightSession;

  @override
  void initState() {
    super.initState();
    _focusTimerController = FocusTimerController();
    _morningSession = MorningRoutineSession();
    _nightSession = NightRoutineSession();
  }

  @override
  void dispose() {
    _focusTimerController.dispose();
    _morningSession.dispose();
    _nightSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Mode',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MyHomePage(
        focusTimerController: _focusTimerController,
        morningSession: _morningSession,
        nightSession: _nightSession,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    required this.focusTimerController,
    required this.morningSession,
    required this.nightSession,
    super.key,
  });
  final MorningRoutineSession morningSession;

  final FocusTimerController focusTimerController;
  final NightRoutineSession nightSession;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        MorningRoutineScreen(session: widget.morningSession),
                  ),
                );
              },
              icon: const Icon(Icons.wb_sunny_outlined),
              label: const Text('Morning routine'),
            ),

            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        NightRoutineScreen(session: widget.nightSession),
                  ),
                );
              },
              icon: const Icon(Icons.bedtime_outlined),
              label: const Text('Evening routine'),
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
          ],
        ),
      ),
    );
  }
}
