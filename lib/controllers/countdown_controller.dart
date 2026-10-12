import 'dart:async';

/// Deadline-based countdown shared by focus sessions and routine steps.
/// Suspending display ticks does not pause elapsed time.
class CountdownController {
  CountdownController({required this.onTick, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final void Function() onTick;
  final DateTime Function() _now;
  Timer? _ticker;
  DateTime? _deadline;
  Duration _remaining = Duration.zero;
  Duration _duration = Duration.zero;

  DateTime? get deadline => _deadline;
  Duration get remaining => _remaining;
  Duration get duration => _duration;

  double get progress => _duration.inMicroseconds <= 0
      ? 0
      : (1 - _remaining.inMicroseconds / _duration.inMicroseconds).clamp(
          0.0,
          1.0,
        );

  static String format(Duration value) {
    final seconds = value.inMicroseconds <= 0
        ? 0
        : (value.inMicroseconds / Duration.microsecondsPerSecond).ceil();
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void reset(Duration value) {
    suspendTicks();
    _deadline = null;
    _duration = _remaining = value;
  }

  void start(Duration value, {DateTime? endingAt}) {
    _duration = value;
    _remaining = value;
    _deadline = endingAt ?? _now().add(value);
    refresh();
    resumeTicks();
  }

  /// Returns whether the deadline has elapsed. Retains it for routine catch-up.
  bool refresh() {
    final end = _deadline;
    if (end == null) return false;
    final difference = end.difference(_now());
    _remaining = difference.isNegative ? Duration.zero : difference;
    if (difference <= Duration.zero) suspendTicks();
    return difference <= Duration.zero;
  }

  void pause() {
    refresh();
    suspendTicks();
    _deadline = null;
  }

  void resume() {
    _deadline = _now().add(_remaining);
    resumeTicks();
  }

  void suspendTicks() => _ticker?.cancel();

  void resumeTicks() {
    suspendTicks();
    if (_deadline == null || _remaining <= Duration.zero) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      refresh();
      onTick();
    });
  }

  void dispose() => suspendTicks();
}
