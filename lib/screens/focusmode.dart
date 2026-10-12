import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/focus_timer_controller.dart';
import '../controllers/blocking_mode_session.dart';
import '../models/blockable_app.dart';
import '../services/app_block_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_icon_badge.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/focus_primary_button.dart';
import '../widgets/focus_screen_header.dart';
import 'block_apps_selection_screen.dart';
import 'blocking_permissions_screen.dart';
import 'session_blocked_apps_screen.dart';

export '../controllers/focus_timer_controller.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({required this.controller, super.key});

  final BlockingModeSession controller;

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  String? _loadError;
  Set<String> get _selectedAppIds => widget.controller.selectedAppIds;
  List<BlockableApp> get _selectedApps => widget.controller.selectedApps;

  @override
  void initState() {
    super.initState();
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    setState(() => _loadError = null);
    try {
      await widget.controller.loadSelection();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = 'Could not load your app selection.');
      }
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      final message = error is StateError
          ? error.message.toString()
          : 'Could not update your session. Please try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openAppSelection() async {
    final result = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (context) => BlockAppsSelectionScreen(
          initialSelection: _selectedAppIds,
          modeTitle: widget.controller.mode.title,
          onSave: widget.controller.saveSelection,
        ),
      ),
    );
    if (result != null && mounted) setState(() {});
  }

  Future<void> _startFocus() => _runAction(() async {
    final accessibilityEnabled = await AppBlockService.isAccessibilityEnabled();
    if (!mounted) return;
    if (!accessibilityEnabled) {
      final granted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => BlockingPermissionsScreen(
            modeTitle: widget.controller.mode.title,
          ),
        ),
      );
      if (granted != true || !mounted) return;
    }
    await widget.controller.startBlockingSession();
  });

  Future<void> _pauseFocus() =>
      _runAction(widget.controller.pauseBlockingSession);
  Future<void> _resumeFocus() =>
      _runAction(widget.controller.resumeBlockingSession);
  Future<void> _stopFocus() =>
      _runAction(widget.controller.stopBlockingSession);

  Future<void> _openBlockedAppsManager() async {
    final result = await Navigator.of(context).push<Map<String, DateTime>>(
      MaterialPageRoute(
        builder: (context) => SessionBlockedAppsScreen(
          apps: _selectedApps,
          activeUnblocks: widget.controller.temporaryUnblocks,
          modeTitle: widget.controller.mode.title,
          isSessionActive: () =>
              widget.controller.status == FocusTimerStatus.running ||
              widget.controller.status == FocusTimerStatus.paused,
          onUnblocksChanged: widget.controller.updateTemporaryUnblocks,
        ),
      ),
    );
    if (result != null &&
        (widget.controller.status == FocusTimerStatus.running ||
            widget.controller.status == FocusTimerStatus.paused)) {
      widget.controller.updateTemporaryUnblocks(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (!widget.controller.selectionLoaded) {
          return Scaffold(
            appBar: AppBar(title: Text('${widget.controller.mode.title} Mode')),
            body: Center(
              child: _loadError == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!),
                        TextButton(
                          onPressed: _loadSelection,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
            ),
          );
        }
        return AbsorbPointer(
          absorbing: widget.controller.busy,
          child: switch (widget.controller.status) {
            FocusTimerStatus.ready => _FocusSetupView(
              controller: widget.controller,
              selectedApps: _selectedApps,
              selectedCount: _selectedAppIds.length,
              onChangeApps: _openAppSelection,
              onStart: _startFocus,
            ),
            FocusTimerStatus.running ||
            FocusTimerStatus.paused => _FocusActiveView(
              controller: widget.controller,
              pausedAppCount: _selectedAppIds.length,
              onPause: _pauseFocus,
              onResume: _resumeFocus,
              onStop: _stopFocus,
              onManageApps: _openBlockedAppsManager,
            ),
            FocusTimerStatus.completed => _FocusCompletedView(
              controller: widget.controller,
              onRestart: _stopFocus,
            ),
          },
        );
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

  final BlockingModeSession controller;
  final List<BlockableApp> selectedApps;
  final int selectedCount;
  final VoidCallback onChangeApps;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isCustomDuration = !FocusTimerController.setupDurationOptions
        .contains(controller.selectedDuration);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: _SessionColumn(
            children: [
              FocusScreenHeader(title: controller.mode.title),
              const SizedBox(height: 32),
              Text(
                'How long do you want to ${controller.mode.activity}?',
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
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.ink.withValues(alpha: 0.65)),
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

  final BlockingModeSession controller;

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
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.ink.withValues(alpha: 0.65)),
                )
              else
                SizedBox(
                  height: 36,
                  width: selectedApps.length > 3
                      ? 96
                      : 36.0 * selectedApps.length,
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

  final BlockingModeSession controller;
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
          child: _SessionColumn(
            children: [
              FocusScreenHeader(
                title: controller.mode.title,
                trailing: Text(
                  'of ${controller.selectedDurationLabel}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.ink.withValues(alpha: 0.55)),
                ),
              ),
              const Spacer(),
              CountdownTimer(
                remaining: controller.remaining,
                progress: controller.progress,
              ),
              const SizedBox(height: 20),
              Text(
                controller.cleanupError ?? controller.statusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.ink.withValues(alpha: 0.7)),
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
                style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                child: const Text('Stop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PausedAppsBadge extends StatelessWidget {
  const _PausedAppsBadge({required this.count, required this.onTap});

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
  const _FocusCompletedView({
    required this.controller,
    required this.onRestart,
  });

  final BlockingModeSession controller;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: _SessionColumn(
            children: [
              FocusScreenHeader(title: controller.mode.title),
              const Spacer(),
              Text(
                '${controller.mode.title} session complete',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                controller.cleanupError ?? controller.statusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.ink.withValues(alpha: 0.65)),
              ),
              const Spacer(),
              FocusPrimaryButton(
                label: controller.cleanupError == null
                    ? 'Start another session'
                    : 'Release blocked apps',
                onPressed: onRestart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps the session controls reachable on short screens and large text sizes.
class _SessionColumn extends StatelessWidget {
  const _SessionColumn({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}
