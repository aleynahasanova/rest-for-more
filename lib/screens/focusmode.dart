import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mock_blockable_apps.dart';
import '../models/blockable_app.dart';
import '../services/android_focus_notification.dart';
import '../services/app_block_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_icon_badge.dart';
import '../widgets/focus_primary_button.dart';
import '../widgets/focus_screen_header.dart';
import 'block_apps_selection_screen.dart';
import 'blocking_permissions_screen.dart';
import 'session_blocked_apps_screen.dart';

enum FocusTimerStatus { ready, running, paused, completed }

class FocusTimerController extends ChangeNotifier
    with WidgetsBindingObserver {
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
    this._notification =
        const AndroidFocusNotification(),
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  final AndroidFocusNotification _notification;
  Duration _selectedDuration = setupDurationOptions[2];
  Duration _remaining = setupDurationOptions[2];
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
        FocusTimerStatus.running =>
          'Working and studying without distractions',
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

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({
    required this.controller,
    super.key,
  });

  final FocusTimerController controller;

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  late Set<String> _selectedAppIds;
  final Map<String, DateTime> _temporaryUnblocks = {};
  final Map<String, Timer> _relockTimers = {};

  @override
  void initState() {
    super.initState();
    _selectedAppIds = Set<String>.from(MockBlockableApps.defaultSelectedIds);
    widget.controller.addListener(_onTimerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTimerChanged);
    for (final timer in _relockTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _onTimerChanged() {
    if (widget.controller.status == FocusTimerStatus.completed) {
      unawaited(_stopBlocking());
    }
  }

  List<BlockableApp> get _selectedApps => MockBlockableApps.all
      .where((app) => _selectedAppIds.contains(app.id))
      .toList();

  Future<void> _openAppSelection() async {
    final result = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (context) => BlockAppsSelectionScreen(
          initialSelection: _selectedAppIds,
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedAppIds = result);
    }
  }

  Future<void> _startFocus() async {
    final accessibilityEnabled =
        await AppBlockService.isAccessibilityEnabled();
    if (!mounted) return;

    if (!accessibilityEnabled) {
      final granted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const BlockingPermissionsScreen(),
        ),
      );
      if (granted != true || !mounted) {
        return;
      }
    }

    await AppBlockService.setBlockedApps(
      _selectedApps.map((app) => app.packageName).toList(),
    );
    await AppBlockService.startBlocking();
    widget.controller.startSession();
  }

  Future<void> _pauseFocus() async {
    await AppBlockService.stopBlocking();
    widget.controller.pauseSession();
  }

  Future<void> _resumeFocus() async {
    await AppBlockService.startBlocking();
    widget.controller.resumeSession();
  }

  Future<void> _stopFocus() async {
    await _stopBlocking();
    widget.controller.cancelSession();
  }

  Future<void> _stopBlocking() async {
    for (final timer in _relockTimers.values) {
      timer.cancel();
    }
    _relockTimers.clear();

    for (final packageName in _temporaryUnblocks.keys) {
      await AppBlockService.clearTemporaryUnblock(packageName);
    }
    _temporaryUnblocks.clear();
    await AppBlockService.stopBlocking();
  }

  void _scheduleRelock(String packageName, DateTime until) {
    _relockTimers[packageName]?.cancel();
    final delay = until.difference(DateTime.now());
    if (delay.isNegative) {
      return;
    }

    _relockTimers[packageName] = Timer(delay, () async {
      await AppBlockService.clearTemporaryUnblock(packageName);
      if (!mounted) return;
      setState(() => _temporaryUnblocks.remove(packageName));
    });
  }

  Future<void> _openBlockedAppsManager() async {
    final result = await Navigator.of(context).push<Map<String, DateTime>>(
      MaterialPageRoute(
        builder: (context) => SessionBlockedAppsScreen(
          apps: _selectedApps,
          activeUnblocks: _temporaryUnblocks,
        ),
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _temporaryUnblocks
        ..clear()
        ..addAll(result);
    });
    for (final entry in result.entries) {
      _scheduleRelock(entry.key, entry.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return switch (widget.controller.status) {
          FocusTimerStatus.ready => _FocusSetupView(
              controller: widget.controller,
              selectedApps: _selectedApps,
              selectedCount: _selectedAppIds.length,
              onChangeApps: _openAppSelection,
              onStart: _startFocus,
            ),
          FocusTimerStatus.running || FocusTimerStatus.paused =>
            _FocusActiveView(
              controller: widget.controller,
              pausedAppCount: _selectedAppIds.length,
              onPause: _pauseFocus,
              onResume: _resumeFocus,
              onStop: _stopFocus,
              onManageApps: _openBlockedAppsManager,
            ),
          FocusTimerStatus.completed => _FocusCompletedView(
              controller: widget.controller,
            ),
        };
      },
    );
  }
}

class _FocusSetupView extends StatelessWidget {
  const _FocusSetupView({
    required this.controller,
    required this.selectedApps,
    required this.selectedCount,
    required this.onChangeApps,
    required this.onStart,
  });

  final FocusTimerController controller;
  final List<BlockableApp> selectedApps;
  final int selectedCount;
  final VoidCallback onChangeApps;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isCustomDuration =
        !FocusTimerController.setupDurationOptions.contains(
      controller.selectedDuration,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FocusScreenHeader(),
              const SizedBox(height: 32),
              Text(
                'How long do you want to focus?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can always pause or stop along the way.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 28),
              _DurationGrid(controller: controller),
              const SizedBox(height: 12),
              _CustomTimeRow(
                isCustom: isCustomDuration,
                customLabel: isCustomDuration
                    ? controller.selectedDurationLabel
                    : null,
                onTap: () => _chooseCustomDuration(context),
              ),
              const SizedBox(height: 28),
              Text(
                'APPS TO PAUSE',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.45),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 10),
              _AppsToPauseCard(
                selectedApps: selectedApps,
                selectedCount: selectedCount,
                onChange: onChangeApps,
              ),
              const Spacer(),
              FocusPrimaryButton(
                label: controller.startButtonLabel,
                onPressed: selectedCount > 0 ? onStart : null,
              ),
            ],
          ),
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: const Text('Custom time'),
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
              if (parsedMinutes < FocusTimerController.minimumDurationMinutes ||
                  parsedMinutes > FocusTimerController.maximumDurationMinutes) {
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
                Navigator.of(dialogContext).pop(int.parse(enteredMinutes));
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
}

class _DurationGrid extends StatelessWidget {
  const _DurationGrid({required this.controller});

  final FocusTimerController controller;

  String _labelFor(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes >= 60 && minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final duration in FocusTimerController.setupDurationOptions)
          _DurationPill(
            label: _labelFor(duration),
            isSelected: duration == controller.selectedDuration,
            onTap: () => controller.selectDuration(duration),
          ),
      ],
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.ink : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.surface : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomTimeRow extends StatelessWidget {
  const _CustomTimeRow({
    required this.isCustom,
    required this.onTap,
    this.customLabel,
  });

  final bool isCustom;
  final String? customLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 22,
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isCustom && customLabel != null
                      ? 'Custom time ($customLabel)'
                      : 'Custom time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.ink.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppsToPauseCard extends StatelessWidget {
  const _AppsToPauseCard({
    required this.selectedApps,
    required this.selectedCount,
    required this.onChange,
  });

  final List<BlockableApp> selectedApps;
  final int selectedCount;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onChange,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              if (selectedApps.isEmpty)
                Text(
                  'No apps selected',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.65),
                      ),
                )
              else
                SizedBox(
                  height: 36,
                  width: selectedApps.length > 3 ? 96 : 36.0 * selectedApps.length,
                  child: Stack(
                    children: [
                      for (var i = 0; i < selectedApps.length && i < 3; i++)
                        Positioned(
                          left: i * 22.0,
                          child: AppIconBadge(app: selectedApps[i]),
                        ),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedCount == 1
                      ? '1 app selected'
                      : '$selectedCount apps selected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                ),
              ),
              TextButton(
                onPressed: onChange,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusActiveView extends StatelessWidget {
  const _FocusActiveView({
    required this.controller,
    required this.pausedAppCount,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onManageApps,
  });

  final FocusTimerController controller;
  final int pausedAppCount;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onManageApps;

  @override
  Widget build(BuildContext context) {
    final isPaused = controller.status == FocusTimerStatus.paused;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FocusScreenHeader(
                trailing: Text(
                  'of ${controller.selectedDurationLabel}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.55),
                      ),
                ),
              ),
              const Spacer(),
              _TimerDisplay(time: controller.formattedRemaining),
              const SizedBox(height: 20),
              Text(
                controller.statusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 16),
              Center(
                child: _PausedAppsBadge(
                  count: pausedAppCount,
                  onTap: onManageApps,
                ),
              ),
              const Spacer(),
              FocusPrimaryButton(
                label: isPaused ? 'Resume' : 'Pause',
                onPressed: isPaused ? onResume : onPause,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onStop,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ink,
                ),
                child: const Text('Stop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.ink.withValues(alpha: 0.15),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          time,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w300,
                fontSize: 56,
                letterSpacing: 1,
                color: AppColors.ink,
              ),
        ),
      ),
    );
  }
}

class _PausedAppsBadge extends StatelessWidget {
  const _PausedAppsBadge({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 app paused' : '$count apps paused';

    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: AppColors.ink.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusCompletedView extends StatelessWidget {
  const _FocusCompletedView({required this.controller});

  final FocusTimerController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FocusScreenHeader(),
              const Spacer(),
              Text(
                'Focus session complete',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                controller.statusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.65),
                    ),
              ),
              const Spacer(),
              FocusPrimaryButton(
                label: 'Start another session',
                onPressed: controller.cancelSession,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
