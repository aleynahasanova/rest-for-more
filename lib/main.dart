import 'package:flutter/material.dart';

import 'screens/focusmode.dart';
import 'theme/app_theme.dart';

void main() {
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
  const MyHomePage({
    required this.focusTimerController,
    super.key,
  });

  final FocusTimerController focusTimerController;

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
          ],
        ),
      ),
    );
  }
}
