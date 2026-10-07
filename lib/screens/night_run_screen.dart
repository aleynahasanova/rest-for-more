import 'package:flutter/material.dart';

import '../controllers/routine_run_controller.dart';
import '../models/routine_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class NightRunScreen extends StatefulWidget {
  const NightRunScreen({
    this.items = const [],
    this.controller,
    required this.iconFor,
    super.key,
  });

  final List<RoutineItem> items;
  final RoutineRunController? controller;
  final IconData Function(String) iconFor;

  @override
  State<NightRunScreen> createState() => _NightRunScreenState();
}

class _NightRunScreenState extends State<NightRunScreen>
    with WidgetsBindingObserver {
  late final RoutineRunController _run;

  @override
  void initState() {
    super.initState();

    _run = widget.controller ?? RoutineRunController(widget.items);

    if (widget.controller == null) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _run.refresh();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      WidgetsBinding.instance.removeObserver(this);
      _run.dispose();
    }

    super.dispose();
  }

  void _close() {
    Navigator.pop(context, _run.completedIds);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _run,
      builder: (context, _) {
        final finished = _run.status == RoutineRunStatus.finished;
        final paused = _run.status == RoutineRunStatus.paused;

        return Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: AppColors.nightBackground,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.nightBackground,
              foregroundColor: AppColors.nightText,
              elevation: 0,
            ),
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.nightBrand,
              surface: AppColors.nightSurface,
              onSurface: AppColors.nightText,
            ),
          ),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Evening routine'),
              leading: BackButton(onPressed: _close),
              actions: [
                if (!finished)
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Center(
                      child: Text(
                        'Step ${_run.index + 1} of ${_run.steps.length}',
                        style: AppTypography.bodyMuted.copyWith(
                          color: AppColors.nightTextMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 48).clamp(
                          0.0,
                          double.infinity,
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(),

                            Center(
                              child: Container(
                                width: finished ? 72 : 56,
                                height: finished ? 72 : 56,
                                decoration: BoxDecoration(
                                  color: AppColors.nightAccent.withValues(
                                    alpha: 0.16,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  finished
                                      ? Icons.bedtime_outlined
                                      : widget.iconFor(_run.current.title),
                                  size: finished ? 32 : 26,
                                  color: AppColors.nightText,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            Text(
                              finished
                                  ? (_run.stoppedEarly
                                        ? 'Your evening has ended.'
                                        : 'Your evening is complete.')
                                  : _run.current.title,
                              textAlign: TextAlign.center,
                              style: AppTypography.headline.copyWith(
                                color: AppColors.nightText,
                              ),
                            ),

                            const SizedBox(height: 24),

                            if (!finished) ...[
                              Center(
                                child: SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox.expand(
                                        child: TweenAnimationBuilder<double>(
                                          key: ValueKey(_run.index),
                                          tween: Tween(
                                            begin: 0,
                                            end: _run.progress,
                                          ),
                                          duration: const Duration(
                                            milliseconds: 600,
                                          ),
                                          curve: Curves.easeOut,
                                          builder: (context, value, _) {
                                            return CircularProgressIndicator(
                                              value: value,
                                              strokeWidth: 3,
                                              strokeCap: StrokeCap.round,
                                              color: AppColors.nightAccent,
                                              backgroundColor:
                                                  AppColors.nightSurfaceMuted,
                                              semanticsLabel:
                                                  'Current step progress',
                                            );
                                          },
                                        ),
                                      ),
                                      Text(
                                        RoutineRunController.countdown(
                                          _run.remaining,
                                        ),
                                        style: AppTypography.timer.copyWith(
                                          color: AppColors.nightText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              Text(
                                paused
                                    ? 'Paused'
                                    : (_run.upcoming == null
                                          ? 'Almost time to rest.'
                                          : 'Next: ${_run.upcoming!.title}'),
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMuted.copyWith(
                                  color: AppColors.nightTextMuted,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                '${RoutineRunController.countdown(_run.remainingTotal)} until bedtime',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMuted.copyWith(
                                  color: AppColors.nightTextMuted,
                                ),
                              ),
                            ] else
                              Text(
                                _run.stoppedEarly
                                    ? 'Take the rest of your evening at your own pace.'
                                    : 'Your routine is complete. Time to rest.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMuted.copyWith(
                                  color: AppColors.nightTextMuted,
                                ),
                              ),

                            const SizedBox(height: 24),

                            const Spacer(),

                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.nightBrand,
                                foregroundColor: AppColors.nightText,
                              ),
                              onPressed: finished ? _close : _run.advance,
                              child: Text(
                                finished
                                    ? 'Done'
                                    : (_run.upcoming == null
                                          ? 'I’m done'
                                          : 'Next step'),
                              ),
                            ),

                            if (!finished) ...[
                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: paused
                                          ? _run.resume
                                          : _run.pause,
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            AppColors.nightTextMuted,
                                      ),
                                      child: Text(paused ? 'Resume' : 'Pause'),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: _run.stop,
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            AppColors.nightTextMuted,
                                      ),
                                      child: const Text('Stop'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
