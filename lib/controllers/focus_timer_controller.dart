import 'dart:async';

import 'package:flutter/material.dart';

import '../services/android_focus_notification.dart';
import 'countdown_controller.dart';

enum FocusTimerStatus { ready, running, paused, completed }

class FocusTimerController extends ChangeNotifier with WidgetsBindingObserver {
  static const minimumDurationMinutes = 1;
  static const maximumDurationMinutes = 180;

  static const setupDurationOptions = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
    Duration(minutes: 120),
  ];

  /// Kept for compatibility with existing timer logic.
  static const durationOptions = setupDurationOptions;

  FocusTimerController({
    this.notification = const AndroidFocusNotification(),
    DateTime Function()? now,
  }) {
    _countdown = CountdownController(onTick: _refreshRemainingTime, now: now);
    _countdown.reset(_selectedDuration);
    WidgetsBinding.instance.addObserver(this);
  }

  final AndroidFocusNotification notification;
  Duration _selectedDuration = setupDurationOptions[2];
  late final CountdownController _countdown;
  FocusTimerStatus _status = FocusTimerStatus.ready;

  Duration get selectedDuration => _selectedDuration;
  Duration get remaining => _countdown.remaining;
  double get progress => _countdown.progress;
  FocusTimerStatus get status => _status;

  String get formattedRemaining => CountdownController.format(remaining);

  String get statusMessage => switch (_status) {
    FocusTimerStatus.ready => 'Set aside distractions and begin.',
    FocusTimerStatus.running => 'Working and studying without distractions',
    FocusTimerStatus.paused => 'Your session is paused.',
    FocusTimerStatus.completed => 'You made time for what matters.',
  };

  String get selectedDurationLabel {
    final minutes = _selectedDuration.inMinutes;
    if (minutes >= 60 && minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return '$minutes min';
  }

  String get startButtonLabel => 'Start $selectedDurationLabel';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _status == FocusTimerStatus.running) {
      _refreshRemainingTime();
      if (_status == FocusTimerStatus.running) {
        _startDisplayTimer();
      }
    } else if (state != AppLifecycleState.resumed) {
      _countdown.suspendTicks();
    }
  }

  void selectDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final isWholeMinute = duration == Duration(minutes: minutes);
    if (!isWholeMinute ||
        minutes < minimumDurationMinutes ||
        minutes > maximumDurationMinutes) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Duration must be a whole number of minutes between '
            '$minimumDurationMinutes and $maximumDurationMinutes.',
      );
    }

    _selectedDuration = duration;
    _countdown.reset(duration);
    notifyListeners();
  }

  void startSession() {
    _countdown.start(_selectedDuration);
    _status = FocusTimerStatus.running;
    notifyListeners();
    _startDisplayTimer();
    unawaited(notification.show(finishingAt: _countdown.deadline!));
  }

  void pauseSession() {
    _refreshRemainingTime();
    if (_status != FocusTimerStatus.running) return;
    _countdown.pause();
    _status = FocusTimerStatus.paused;
    notifyListeners();
    unawaited(notification.hide());
  }

  void resumeSession() {
    _countdown.resume();
    _status = FocusTimerStatus.running;
    notifyListeners();
    _startDisplayTimer();
    unawaited(notification.show(finishingAt: _countdown.deadline!));
  }

  void cancelSession() {
    final wasActive =
        _status == FocusTimerStatus.running ||
        _status == FocusTimerStatus.paused;
    _countdown.reset(_selectedDuration);
    _status = FocusTimerStatus.ready;
    notifyListeners();
    if (wasActive) unawaited(notification.hide());
  }

  void _startDisplayTimer() => _countdown.resumeTicks();

  void _refreshRemainingTime() {
    if (_status != FocusTimerStatus.running) return;
    if (_countdown.refresh()) {
      _countdown.reset(Duration.zero);
      _status = FocusTimerStatus.completed;
      unawaited(notification.hide());
    }
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdown.dispose();
    if (_status == FocusTimerStatus.running ||
        _status == FocusTimerStatus.paused) {
      unawaited(notification.hide());
    }
    super.dispose();
  }
}
