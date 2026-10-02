import 'package:flutter/material.dart';

import '../models/blockable_app.dart';
import '../services/app_block_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_icon_badge.dart';
import '../widgets/focus_screen_header.dart';
import 'contemplation_screen.dart';
import 'unblock_duration_screen.dart';

class SessionBlockedAppsScreen extends StatefulWidget {
  const SessionBlockedAppsScreen({
    required this.apps,
    required this.activeUnblocks,
    super.key,
  });

  final List<BlockableApp> apps;
  final Map<String, DateTime> activeUnblocks;

  @override
  State<SessionBlockedAppsScreen> createState() =>
      _SessionBlockedAppsScreenState();
}

class _SessionBlockedAppsScreenState extends State<SessionBlockedAppsScreen> {
  late Map<String, DateTime> _activeUnblocks;

  @override
  void initState() {
    super.initState();
    _activeUnblocks = Map<String, DateTime>.from(widget.activeUnblocks);
  }

  bool _isTemporarilyUnblocked(BlockableApp app) {
    final until = _activeUnblocks[app.packageName];
    return until != null && until.isAfter(DateTime.now());
  }

  Future<void> _startUnblockFlow(BlockableApp app) async {
    if (_isTemporarilyUnblocked(app)) {
      return;
    }

    final shouldContinue = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ContemplationScreen(appName: app.name),
      ),
    );
    if (shouldContinue != true || !mounted) {
      return;
    }

    final duration = await Navigator.of(context).push<Duration>(
      MaterialPageRoute(
        builder: (context) => UnblockDurationScreen(app: app),
      ),
    );
    if (duration == null || !mounted) {
      return;
    }

    final until = DateTime.now().add(duration);
    await AppBlockService.setTemporaryUnblock(
      packageName: app.packageName,
      until: until,
    );
    setState(() => _activeUnblocks[app.packageName] = until);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_activeUnblocks);
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FocusScreenHeader(
                onBack: () => Navigator.of(context).pop(_activeUnblocks),
              ),
              const SizedBox(height: 32),
              Text(
                'Which app do you want to unblock?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose one app, then take a short pause before it becomes available.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.apps.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final app = widget.apps[index];
                    final until = _activeUnblocks[app.packageName];
                    final isUnblocked =
                        until != null && until.isAfter(DateTime.now());
                    return _BlockedAppRow(
                      app: app,
                      isTemporarilyUnblocked: isUnblocked,
                      until: isUnblocked ? until : null,
                      onTap: () => _startUnblockFlow(app),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _BlockedAppRow extends StatelessWidget {
  const _BlockedAppRow({
    required this.app,
    required this.isTemporarilyUnblocked,
    required this.onTap,
    this.until,
  });

  final BlockableApp app;
  final bool isTemporarilyUnblocked;
  final DateTime? until;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = isTemporarilyUnblocked && until != null
        ? 'Available until ${_formatTime(until!)}'
        : 'Blocked';

    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AppIconBadge(app: app),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.55),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                isTemporarilyUnblocked
                    ? Icons.check_circle_outline
                    : Icons.chevron_right,
                color: AppColors.ink.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
