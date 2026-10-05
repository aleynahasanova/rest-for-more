import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/routine_item.dart';
import '../services/android_focus_notification.dart';
import 'routine_run_controller.dart';

/// App-owned session: navigating away only detaches the view, not the timer.
class MorningRoutineSession extends ChangeNotifier with WidgetsBindingObserver {
  MorningRoutineSession({
    this.now,
    this.notification = const AndroidFocusNotification.routine(),
  }) {
    WidgetsBinding.instance.addObserver(this);
  }
  final DateTime Function()? now;
  final AndroidFocusNotification notification;
  RoutineRunController? _run;
  DateTime? _notifiedEnd;
  bool _background = false;
  RoutineRunController? get run => _run;
  bool get isActive =>
      _run != null && _run!.status != RoutineRunStatus.finished;

  RoutineRunController startOrContinue(List<RoutineItem> items) {
    _run?.refresh();
    if (isActive) return _run!;
    _run?.removeListener(_changed);
    _run?.dispose();
    _run = RoutineRunController(items, now: now);
    _run!.addListener(_changed);
    _changed();
    return _run!;
  }

  void _changed() {
    final end = _run?.finishingAt;
    if (end != _notifiedEnd) {
      _notifiedEnd = end;
      if (end == null) {
        unawaited(notification.hide());
      } else {
        unawaited(notification.show(finishingAt: end));
      }
    }
    if (_background) _run?.suspendTicks();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background = state != AppLifecycleState.resumed;
    if (_background) {
      _run?.suspendTicks();
    } else {
      _run?.resumeTicks();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _run?.removeListener(_changed);
    _run?.dispose();
    unawaited(notification.hide());
    super.dispose();
  }
}
