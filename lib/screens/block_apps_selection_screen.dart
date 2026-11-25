import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/blockable_app.dart';
import '../services/app_block_service.dart';
import '../services/installed_apps_service.dart';
import '../services/ios_app_blocking_service.dart';
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
  var _saving = false;
  var _iosBusy = false;
  var _iosCount = 0;
  var _loadingApps = !AppBlockService.isIOS;
  var _appsError = false;
  var _query = '';
  List<BlockableApp> _apps = const [];

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.initialSelection);
    if (AppBlockService.isIOS) {
      _loadIOSCount();
    } else {
      _loadInstalledApps();
    }
  }

  Future<void> _loadInstalledApps() async {
    try {
      final apps = await InstalledAppsService.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _apps = apps;
        _loadingApps = false;
        _appsError = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _apps = InstalledAppsService.apps;
        _loadingApps = false;
        _appsError = _apps.isEmpty;
      });
    }
  }

  Future<void> _loadIOSCount() async {
    try {
      final count = await IOSAppBlockingService.selectionCount();
      if (mounted) {
        setState(() => _iosCount = count);
      }
    } catch (_) {
      // The picker can still be used if the count is unavailable.
    }
  }

  List<BlockableApp> get _filteredApps {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _apps;
    }
    return [
      for (final app in _apps)
        if (app.name.toLowerCase().contains(query)) app,
    ];
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

  bool _areAllSelected(List<BlockableApp> apps) {
    if (apps.isEmpty) {
      return false;
    }
    for (final app in apps) {
      if (!_selectedIds.contains(app.id)) {
        return false;
      }
    }
    return true;
  }

  void _toggleSelectAll(List<BlockableApp> apps) {
    if (_saving || apps.isEmpty) {
      return;
    }
    setState(() {
      if (_areAllSelected(apps)) {
        for (final app in apps) {
          _selectedIds.remove(app.id);
        }
      } else {
        for (final app in apps) {
          _selectedIds.add(app.id);
        }
      }
    });
  }

  Future<void> _selectIOSApps() async {
    if (_iosBusy) {
      return;
    }
    setState(() => _iosBusy = true);
    try {
      if (!await IOSAppBlockingService.isAuthorized()) {
        await IOSAppBlockingService.requestPermission();
      }
      final count = await IOSAppBlockingService.selectApps();
      if (!mounted || count == null) {
        return;
      }
      setState(() => _iosCount = count);
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'Could not select apps. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _iosBusy = false);
      }
    }
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    if (AppBlockService.isIOS && _iosCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose apps or categories in Screen Time first.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final snapshot = AppBlockService.isIOS
        ? <String>{IOSAppBlockingService.selectionToken}
        : Set<String>.from(_selectedIds);
    try {
      await widget.onSave?.call(snapshot);
      if (mounted) {
        Navigator.of(context).pop(snapshot);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your selection. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = AppBlockService.isIOS;
    final filteredApps = _filteredApps;

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
                isIOS
                    ? 'iPhone uses Screen Time to choose the real apps and categories to pause.'
                    : 'These apps will be blocked during ${widget.modeTitle.toLowerCase()} mode.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 24),
              if (isIOS)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.phone_iphone,
                        size: 48,
                        color: AppColors.ink,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _iosCount == 0
                            ? 'No apps or categories selected yet.'
                            : '$_iosCount apps or categories selected.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(height: 24),
                      FocusPrimaryButton(
                        label: _iosBusy
                            ? 'Opening Screen Time...'
                            : 'Choose apps and categories',
                        onPressed: _iosBusy ? null : _selectIOSApps,
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: _loadingApps
                      ? const Center(child: CircularProgressIndicator())
                      : _appsError
                          ? Center(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _loadingApps = true;
                                    _appsError = false;
                                  });
                                  _loadInstalledApps();
                                },
                                child: const Text(
                                  'Could not load apps. Try again',
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                TextField(
                                  onChanged: (value) {
                                    setState(() => _query = value);
                                  },
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: 'Search apps',
                                    prefixIcon: const Icon(Icons.search),
                                    filled: true,
                                    fillColor: AppColors.surfaceMuted,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed:
                                        _saving || filteredApps.isEmpty
                                            ? null
                                            : () =>
                                                _toggleSelectAll(filteredApps),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.ink,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    child: Text(
                                      _areAllSelected(filteredApps)
                                          ? 'Deselect all'
                                          : 'Select all',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: filteredApps.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No apps match your search.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  color: AppColors.ink
                                                      .withValues(alpha: 0.65),
                                                ),
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: filteredApps.length,
                                          separatorBuilder: (_, _) =>
                                              const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            final app = filteredApps[index];
                                            return _AppSelectionRow(
                                              app: app,
                                              isSelected:
                                                  _selectedIds.contains(app.id),
                                              onTap: () {
                                                if (!_saving) {
                                                  _toggleApp(app.id);
                                                }
                                              },
                                            );
                                          },
                                        ),
                                ),
                              ],
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
