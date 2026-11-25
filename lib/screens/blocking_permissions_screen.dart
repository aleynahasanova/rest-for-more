import 'package:flutter/material.dart';

import '../services/app_block_service.dart';
import '../theme/app_colors.dart';
import '../widgets/focus_primary_button.dart';
import '../widgets/focus_screen_header.dart';

class BlockingPermissionsScreen extends StatefulWidget {
  const BlockingPermissionsScreen({this.modeTitle = 'Focus', super.key});

  final String modeTitle;

  @override
  State<BlockingPermissionsScreen> createState() =>
      _BlockingPermissionsScreenState();
}

class _BlockingPermissionsScreenState extends State<BlockingPermissionsScreen>
    with WidgetsBindingObserver {
  var _isEnabled = false;
  var _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    bool enabled;
    try {
      enabled = await AppBlockService.isAccessibilityEnabled();
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
      enabled = false;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isEnabled = enabled;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = AppBlockService.isIOS;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FocusScreenHeader(title: widget.modeTitle),
              const SizedBox(height: 32),
              Text(
                'Allow Rest For More to pause apps',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isIOS
                    ? 'Allow Screen Time access to pause the apps and categories you choose during your session.'
                    : 'Turn on the Rest For More accessibility service so selected apps can be blocked during your session.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _isChecking
                      ? 'Checking permission…'
                      : _isEnabled
                          ? 'App blocking is enabled.'
                          : 'App blocking is not enabled yet.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (!isIOS && !_isEnabled) ...[
                const SizedBox(height: 20),
                const Expanded(child: _AccessibilityGuide()),
                const SizedBox(height: 16),
              ] else
                const Spacer(),
              if (!_isEnabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FocusPrimaryButton(
                    label: isIOS
                        ? 'Allow Screen Time access'
                        : 'Open accessibility settings',
                    onPressed: () async {
                      try {
                        await AppBlockService.openAccessibilitySettings();
                        await _refreshStatus();
                      } on Exception catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$error')),
                        );
                      }
                    },
                  ),
                ),
              FocusPrimaryButton(
                label: _isEnabled ? 'Continue' : 'Not now',
                onPressed: () => Navigator.of(context).pop(_isEnabled),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessibilityGuide extends StatelessWidget {
  const _AccessibilityGuide();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Guide: open Installed apps, tap Rest for More, then turn it on.',
      image: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/accessibility_guide.gif',
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
