import 'package:flutter/material.dart';

import '../data/mock_blockable_apps.dart';
import '../models/blockable_app.dart';
import '../theme/app_colors.dart';
import '../widgets/app_icon_badge.dart';
import '../widgets/focus_primary_button.dart';
import '../widgets/focus_screen_header.dart';

class BlockAppsSelectionScreen extends StatefulWidget {
  const BlockAppsSelectionScreen({
    required this.initialSelection,
    this.modeTitle = 'Focus',
    this.onSave,
    super.key,
  });

  final String modeTitle;
  final Future<void> Function(Set<String>)? onSave;

  final Set<String> initialSelection;

  @override
  State<BlockAppsSelectionScreen> createState() =>
      _BlockAppsSelectionScreenState();
}

class _BlockAppsSelectionScreenState extends State<BlockAppsSelectionScreen> {
  late Set<String> _selectedIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.initialSelection);
  }

  void _toggleApp(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final snapshot = Set<String>.from(_selectedIds);
    try {
      await widget.onSave?.call(snapshot);
      if (mounted) Navigator.of(context).pop(snapshot);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your selection. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
              FocusScreenHeader(title: widget.modeTitle),
              const SizedBox(height: 32),
              Text(
                'What do you want to pause?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These apps will be blocked during ${widget.modeTitle.toLowerCase()} mode.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.ink.withValues(alpha: 0.65)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: MockBlockableApps.all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final app = MockBlockableApps.all[index];
                    final isSelected = _selectedIds.contains(app.id);
                    return _AppSelectionRow(
                      app: app,
                      isSelected: isSelected,
                      onTap: () {
                        if (!_saving) _toggleApp(app.id);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FocusPrimaryButton(
                label: _saving ? 'Saving…' : 'Save selection',
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppSelectionRow extends StatelessWidget {
  const _AppSelectionRow({
    required this.app,
    required this.isSelected,
    required this.onTap,
  });

  final BlockableApp app;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                child: Text(
                  app.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ),
              _SelectionIndicator(isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.ink : Colors.transparent,
        border: Border.all(color: AppColors.ink, width: isSelected ? 0 : 1.5),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: AppColors.surface)
          : null,
    );
  }
}
