import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/focus_primary_button.dart';
import '../widgets/focus_screen_header.dart';

class ContemplationScreen extends StatefulWidget {
  const ContemplationScreen({
    required this.appName,
    super.key,
  });

  final String appName;

  @override
  State<ContemplationScreen> createState() => _ContemplationScreenState();
}

class _ContemplationScreenState extends State<ContemplationScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(seconds: 5);

  late final AnimationController _controller;
  var _canContinue = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _canContinue = true);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                'Take a moment to breathe',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Do you still need ${widget.appName} right now?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _controller.value,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceMuted,
                      color: AppColors.ink,
                    ),
                  );
                },
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: _canContinue ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: FocusPrimaryButton(
                  label: 'Continue',
                  onPressed: _canContinue
                      ? () => Navigator.of(context).pop(true)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
