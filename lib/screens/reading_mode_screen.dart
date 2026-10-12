import 'package:flutter/material.dart';

import '../controllers/blocking_mode_session.dart';
import 'focusmode.dart';

/// Reading shares the session UI and timer, with its own session and saved apps.
class ReadingModeScreen extends StatelessWidget {
  const ReadingModeScreen({required this.session, super.key});

  final BlockingModeSession session;

  @override
  Widget build(BuildContext context) => FocusModeScreen(controller: session);
}
