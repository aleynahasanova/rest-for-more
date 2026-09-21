import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/android_focus_notification.dart';

enum FocusTimerStatus { ready, running, paused, completed }

class FocusTimerController extends ChangeNotifier
    with WidgetsBindingObserver {
  static const minimumDurationMinutes = 1;
  static const maximumDurationMinutes = 180;

  static const durationOptions = <Duration>[
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 25),
    Duration(minutes: 45),
  ];

  FocusTimerController({
    AndroidFocusNotification notification =
        const AndroidFocusNotification(),
  }) : _notification = notification {
    WidgetsBinding.instance.addObserver(this);
  }

  final AndroidFocusNotification _notification;
  Duration _selectedDuration = durationOptions[2];
  Duration _remaining = durationOptions[2];
  DateTime? _finishingAt;
  Timer? _displayTimer;
  FocusTimerStatus _status = FocusTimerStatus.ready;

  Duration get selectedDuration => _selectedDuration;
  Duration get remaining => _remaining;
  FocusTimerStatus get status => _status;

  String get formattedRemaining {
    final totalSeconds = _remaining.inMilliseconds <= 0
        ? 0
        : (_remaining.inMilliseconds / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get statusMessage => switch (_status) {
        FocusTimerStatus.ready => 'Set aside distractions and begin.',
        FocusTimerStatus.running => 'Stay with the task in front of you.',
        FocusTimerStatus.paused => 'Your session is paused.',
        FocusTimerStatus.completed => 'You made time for what matters.',
      };

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _status == FocusTimerStatus.running) {
      _refreshRemainingTime();
      if (_status == FocusTimerStatus.running) {
        _startDisplayTimer();
      }
    } else if (state != AppLifecycleState.resumed) {
      _displayTimer?.cancel();
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
    _remaining = duration;
    notifyListeners();
  }

  void startSession() {
    _remaining = _selectedDuration;
    _finishingAt = DateTime.now().add(_remaining);
    _status = FocusTimerStatus.running;
    notifyListeners();
    _startDisplayTimer();
    unawaited(_notification.show(finishingAt: _finishingAt!));
  }

  void pauseSession() {
    _updateRemainingFromTimestamp();
    _displayTimer?.cancel();
    _finishingAt = null;
    _status = FocusTimerStatus.paused;
    notifyListeners();
    unawaited(_notification.hide());
  }

  void resumeSession() {
    _finishingAt = DateTime.now().add(_remaining);
    _status = FocusTimerStatus.running;
    notifyListeners();
    _startDisplayTimer();
    unawaited(_notification.show(finishingAt: _finishingAt!));
  }

  void cancelSession() {
    _displayTimer?.cancel();
    _finishingAt = null;
    _remaining = _selectedDuration;
    _status = FocusTimerStatus.ready;
    notifyListeners();
    unawaited(_notification.hide());
  }

  void _startDisplayTimer() {
    _displayTimer?.cancel();
    _displayTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshRemainingTime(),
    );
  }

  void _refreshRemainingTime() {
    if (_finishingAt == null) return;

    final hasFinished = _updateRemainingFromTimestamp();
    if (hasFinished) {
      _displayTimer?.cancel();
      _finishingAt = null;
      _status = FocusTimerStatus.completed;
      unawaited(_notification.hide());
    }
    notifyListeners();
  }

  bool _updateRemainingFromTimestamp() {
    final finishingAt = _finishingAt;
    if (finishingAt == null) return false;

    final difference = finishingAt.difference(DateTime.now());
    _remaining = difference.isNegative ? Duration.zero : difference;
    return difference <= Duration.zero;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _displayTimer?.cancel();
    unawaited(_notification.hide());
    super.dispose();
  }
}

class FocusModeScreen extends StatelessWidget {
  const FocusModeScreen({
    required this.controller,
    super.key,
  });

  final FocusTimerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _FocusTimerView(controller: controller),
    );
  }
}

class _FocusTimerView extends StatelessWidget {
  const _FocusTimerView({required this.controller});

  final FocusTimerController controller;

  @override
  Widget build(BuildContext context) {
    final isReady = controller.status == FocusTimerStatus.ready;
    final isCustomDuration = !FocusTimerController.durationOptions.contains(
      controller.selectedDuration,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Mode')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minimumContentHeight = constraints.maxHeight > 48
                ? constraints.maxHeight - 48
                : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: minimumContentHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Text(
                        controller.status == FocusTimerStatus.completed
                            ? 'Focus session complete'
                            : controller.formattedRemaining,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.statusMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      if (isReady) ...[
                        const Text(
                          'Choose a duration',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final duration
                                in FocusTimerController.durationOptions)
                              ChoiceChip(
                                label: Text('${duration.inMinutes} min'),
                                selected:
                                    duration == controller.selectedDuration,
                                onSelected: (_) =>
                                    controller.selectDuration(duration),
                              ),
                            ChoiceChip(
                              avatar: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                              ),
                              label: Text(
                                isCustomDuration
                                    ? 'Custom '
                                        '(${controller.selectedDuration.inMinutes} min)'
                                    : 'Custom',
                              ),
                              selected: isCustomDuration,
                              onSelected: (_) =>
                                  _chooseCustomDuration(context),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      ..._buildActions(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _chooseCustomDuration(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    var enteredMinutes = controller.selectedDuration.inMinutes.toString();

    final minutes = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        title: const Text('Custom duration'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: enteredMinutes,
            autofocus: true,
            keyboardType: TextInputType.number,
            scrollPadding: const EdgeInsets.only(bottom: 96),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => enteredMinutes = value,
            decoration: const InputDecoration(
              labelText: 'Minutes',
              helperText: 'Enter a duration from 1 to 180 minutes.',
              suffixText: 'min',
            ),
            validator: (value) {
              final parsedMinutes = int.tryParse(value ?? '');
              if (parsedMinutes == null) {
                return 'Enter a number of minutes.';
              }
              if (parsedMinutes <
                      FocusTimerController.minimumDurationMinutes ||
                  parsedMinutes >
                      FocusTimerController.maximumDurationMinutes) {
                return 'Enter a value from 1 to 180.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(
                  int.parse(enteredMinutes),
                );
              }
            },
            child: const Text('Set duration'),
          ),
        ],
      ),
    );

    if (minutes != null) {
      controller.selectDuration(Duration(minutes: minutes));
    }
  }

  List<Widget> _buildActions() {
    return switch (controller.status) {
      FocusTimerStatus.ready => [
          FilledButton.icon(
            onPressed: controller.startSession,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start session'),
          ),
        ],
      FocusTimerStatus.running => [
          FilledButton.icon(
            onPressed: controller.pauseSession,
            icon: const Icon(Icons.pause_rounded),
            label: const Text('Pause'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: controller.cancelSession,
            child: const Text('Cancel'),
          ),
        ],
      FocusTimerStatus.paused => [
          FilledButton.icon(
            onPressed: controller.resumeSession,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Resume'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: controller.cancelSession,
            child: const Text('Cancel'),
          ),
        ],
      FocusTimerStatus.completed => [
          FilledButton(
            onPressed: controller.cancelSession,
            child: const Text('Start another session'),
          ),
        ],
    };
  }
}
