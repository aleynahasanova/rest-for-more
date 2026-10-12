import 'package:flutter/material.dart';

import '../services/app_block_service.dart';
import '../theme/app_colors.dart';
import '../widgets/focus_primary_button.dart';
import '../widgets/focus_screen_header.dart';

class BlockingPermissionsScreen extends StatefulWidget {
  const BlockingPermissionsScreen({super.key});

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
    final enabled = await AppBlockService.isAccessibilityEnabled();
    if (!mounted) return;
    setState(() {
      _isEnabled = enabled;
      _isChecking = false;
    });
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
                'Turn on the Rest For More accessibility service so selected apps can be blocked during focus.',
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
              const Spacer(),
              if (!_isEnabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FocusPrimaryButton(
                    label: 'Open accessibility settings',
                    onPressed: () async {
                      await AppBlockService.openAccessibilitySettings();
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
