import 'package:flutter/material.dart';

import '../models/blockable_app.dart';
import '../theme/app_colors.dart';
import '../widgets/focus_screen_header.dart';
import '../widgets/vertical_duration_slider.dart';

class UnblockDurationScreen extends StatefulWidget {
  const UnblockDurationScreen({
    required this.app,
    super.key,
  });

  final BlockableApp app;

  static const durationOptions = [1, 5, 10, 15];

  @override
  State<UnblockDurationScreen> createState() => _UnblockDurationScreenState();
}

class _UnblockDurationScreenState extends State<UnblockDurationScreen> {
  var _selectedMinutes = 5;

  DateTime get _availableUntil =>
      DateTime.now().add(Duration(minutes: _selectedMinutes));

  String get _untilLabel {
    final time = _availableUntil;
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
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
              const SizedBox(height: 32),
              Text(
                'How long do you need ${widget.app.name}?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'You selected $_selectedMinutes minutes. This app will be available until $_untilLabel.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: VerticalDurationSlider(
                        values: UnblockDurationScreen.durationOptions,
                        selected: _selectedMinutes,
                        onChanged: (minutes) {
                          setState(() => _selectedMinutes = minutes);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      child: Text(
                        '$_selectedMinutes min',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      Duration(minutes: _selectedMinutes),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Unblock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
