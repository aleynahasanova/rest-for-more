import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/routine_item.dart';

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
    _remaining = _duration(0);
    _endsAt = _now().add(_remaining);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => refresh());
  }
  final List<RoutineItem> steps;
  final DateTime Function() _now;
  Timer? _ticker;
  DateTime? _endsAt;
  int _index = 0;
  Duration _remaining = Duration.zero;
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
  Duration get remaining => _remaining;
  DateTime? get finishingAt {
    if (_status != RoutineRunStatus.running) return null;
    var end = _endsAt!;
    for (var i = _index + 1; i < steps.length; i++) {
      end = end.add(_duration(i));
    }
    return end;
  }

  void suspendTicks() => _ticker?.cancel();
  void resumeTicks() {
    refresh();
    _ticker?.cancel();
    if (_status != RoutineRunStatus.finished) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => refresh());
    }
  }

  Duration _duration(int index) =>
      Duration(minutes: steps[index].durationMinutes!);
  Duration get remainingTotal {
    if (_status == RoutineRunStatus.finished) return Duration.zero;
    var total = _remaining;
    for (var i = _index + 1; i < steps.length; i++) {
      total += _duration(i);
    }
    return total;
  }

  double get progress =>
      (1 - _remaining.inMilliseconds / _duration(_index).inMilliseconds).clamp(
        0.0,
        1.0,
      );
  static String countdown(Duration value) {
    final seconds = (value.inMilliseconds / 1000).ceil();
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void refresh() {
    if (_status != RoutineRunStatus.running) return;
    final now = _now();
    while (!now.isBefore(_endsAt!)) {
      _completed.add(current.routineItemId);
      if (_index == steps.length - 1) {
        _finish();
        notifyListeners();
        return;
      }
      _index++;
      _endsAt = _endsAt!.add(_duration(_index));
    }
    _remaining = _endsAt!.difference(now);
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
      _remaining = _duration(_index);
      _endsAt = _now().add(_remaining);
      _status = RoutineRunStatus.running;
    }
    notifyListeners();
  }

  void pause() {
    if (_status != RoutineRunStatus.running) return;
    refresh();
    if (_status == RoutineRunStatus.finished) return;
    _status = RoutineRunStatus.paused;
    _endsAt = null;
    notifyListeners();
  }

  void resume() {
    if (_status != RoutineRunStatus.paused) return;
    _endsAt = _now().add(_remaining);
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
    _remaining = Duration.zero;
    _endsAt = null;
    _ticker?.cancel();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
