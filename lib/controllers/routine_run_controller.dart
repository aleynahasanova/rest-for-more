import 'package:flutter/foundation.dart';

import '../models/routine_item.dart';
import 'countdown_controller.dart';

enum RoutineRunStatus { running, paused, finished }

/// A snapshot of a routine. Timestamps keep elapsed time accurate after the
/// app is suspended; the next refresh catches up across every elapsed step.
class RoutineRunController extends ChangeNotifier {
  RoutineRunController(List<RoutineItem> items, {DateTime Function()? now})
    : steps = List.unmodifiable(items),
      _now = now ?? DateTime.now {
    if (steps.isEmpty || steps.any((s) => (s.durationMinutes ?? 0) <= 0)) {
      throw ArgumentError('A run requires steps with positive durations.');
    }
    _countdown = CountdownController(onTick: refresh, now: _now);
    _countdown.start(_duration(0));
  }
  final List<RoutineItem> steps;
  final DateTime Function() _now;
  late final CountdownController _countdown;
  int _index = 0;
  RoutineRunStatus _status = RoutineRunStatus.running;
  final Set<String> _completed = {};
  bool _stoppedEarly = false;

  RoutineRunStatus get status => _status;
  int get index => _index;
  bool get stoppedEarly => _stoppedEarly;
  Set<String> get completedIds => Set.unmodifiable(_completed);
  RoutineItem get current => steps[_index];
  RoutineItem? get upcoming =>
      _index + 1 < steps.length ? steps[_index + 1] : null;
  Duration get remaining => _countdown.remaining;
  DateTime? get finishingAt {
    if (_status != RoutineRunStatus.running) return null;
    var end = _countdown.deadline!;
    for (var i = _index + 1; i < steps.length; i++) {
      end = end.add(_duration(i));
    }
    return end;
  }

  void suspendTicks() => _countdown.suspendTicks();
  void resumeTicks() {
    refresh();
    if (_status == RoutineRunStatus.running) _countdown.resumeTicks();
  }

  Duration _duration(int index) =>
      Duration(minutes: steps[index].durationMinutes!);
  Duration get remainingTotal {
    if (_status == RoutineRunStatus.finished) return Duration.zero;
    var total = _countdown.remaining;
    for (var i = _index + 1; i < steps.length; i++) {
      total += _duration(i);
    }
    return total;
  }

  double get progress => _countdown.progress;
  static String countdown(Duration value) => CountdownController.format(value);

  void refresh() {
    if (_status != RoutineRunStatus.running) return;
    final now = _now();
    while (!now.isBefore(_countdown.deadline!)) {
      _completed.add(current.routineItemId);
      if (_index == steps.length - 1) {
        _finish();
        notifyListeners();
        return;
      }
      _index++;
      _countdown.start(
        _duration(_index),
        endingAt: _countdown.deadline!.add(_duration(_index)),
      );
    }
    _countdown.refresh();
    notifyListeners();
  }

  void advance() {
    if (_status == RoutineRunStatus.finished) return;
    final previousIndex = _index;
    refresh();
    // A tap at a step boundary must not accidentally skip the next step too.
    if (_status == RoutineRunStatus.finished || previousIndex != _index) return;
    _completed.add(current.routineItemId);
    if (_index == steps.length - 1) {
      _finish();
    } else {
      _index++;
      _countdown.start(_duration(_index));
      _status = RoutineRunStatus.running;
    }
    notifyListeners();
  }

  void pause() {
    if (_status != RoutineRunStatus.running) return;
    refresh();
    if (_status == RoutineRunStatus.finished) return;
    _status = RoutineRunStatus.paused;
    _countdown.pause();
    notifyListeners();
  }

  void resume() {
    if (_status != RoutineRunStatus.paused) return;
    _countdown.resume();
    _status = RoutineRunStatus.running;
    notifyListeners();
  }

  void stop() {
    if (_status == RoutineRunStatus.finished) return;
    refresh();
    if (_status == RoutineRunStatus.finished) return;
    _stoppedEarly = true;
    _finish();
    notifyListeners();
  }

  void _finish() {
    _status = RoutineRunStatus.finished;
    _countdown.reset(Duration.zero);
  }

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }
}
