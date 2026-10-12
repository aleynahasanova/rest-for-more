import 'package:flutter/material.dart';

import '../components/night_routine_item.dart';
import '../components/routine_item_editor.dart';
import '../controllers/night_routine_session.dart';
import '../models/routine.dart';
import '../models/routine_item.dart';
import '../services/routine_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'night_run_screen.dart';

class NightRoutineScreen extends StatefulWidget {
  const NightRoutineScreen({
    this.service,
    this.session,
    this.userId,
    super.key,
  });

  final RoutineService? service;
  final NightRoutineSession? session;
  final String? userId;

  static const defaultItems = <(String, String, int)>[
    ('Phone away', 'Put your phone aside.', 5),
    ('Clean up', 'Prepare your space for tomorrow.', 10),
    ('Brush teeth', 'Get ready for bed.', 5),
    ('Read', 'Read before sleeping.', 25),
  ];

  @override
  State<NightRoutineScreen> createState() => _NightRoutineScreenState();
}

class _NightRoutineScreenState extends State<NightRoutineScreen> {
  late final RoutineService _service = widget.service ?? RoutineService();
  late final NightRoutineSession _session;

  Routine? _routine;
  List<RoutineItem> _items = [];
  final Set<String> _completed = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);

  @override
  void initState() {
    super.initState();

    _session = widget.session ?? NightRoutineSession();
    _session.addListener(_sessionChanged);

    _load();
  }

  void _sessionChanged() {
    if (!mounted) return;

    setState(() {
      final run = _session.run;

      if (run != null) {
        _completed
          ..clear()
          ..addAll(run.completedIds);
      }
    });
  }

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);

    if (widget.session == null) {
      _session.dispose();
    }

    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routine = await _service.ensureEveningRoutine(
        userId: widget.userId,
        defaults: NightRoutineScreen.defaultItems,
      );

      final items = await _service.getRoutineItems(routine.routineId);

      if (!mounted) return;

      setState(() {
        _routine = routine;
        _items = items;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load your evening routine. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  int get _totalMinutes {
    return _items.fold<int>(
      0,
      (total, item) => total + (item.durationMinutes ?? 0),
    );
  }

  int get _bedtimeMinutes => _bedtime.hour * 60 + _bedtime.minute;

  String _formatTime(int minutes) {
    minutes = ((minutes % 1440) + 1440) % 1440;

    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  String _scheduledTime(int index) {
    var minutes = _bedtimeMinutes - _totalMinutes;

    for (var i = 0; i < index; i++) {
      minutes += _items[i].durationMinutes ?? 0;
    }

    return _formatTime(minutes);
  }

  Future<void> _changeBedtime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _bedtime,
    );

    if (result != null && mounted) {
      setState(() => _bedtime = result);
    }
  }

  Future<void> _edit([RoutineItem? item]) async {
    if (_routine == null) return;

    final sortOrder =
        _items.fold<int>(
          -1,
          (max, current) => current.sortOrder > max ? current.sortOrder : max,
        ) +
        1;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RoutineItemEditor(
        routineId: _routine!.routineId,
        item: item,
        sortOrder: sortOrder,
        onSave: (result) async {
          if (item == null) {
            await _service.createRoutineItem(result);
          } else {
            await _service.updateRoutineItem(result);
          }

          if (!mounted) return;

          setState(() {
            if (item == null) {
              _items = [..._items, result];
            } else {
              _items = _items
                  .map(
                    (old) => old.routineItemId == result.routineItemId
                        ? result
                        : old,
                  )
                  .toList();
            }
          });
        },
      ),
    );
  }

  Future<void> _move(int index, int direction) async {
    final newIndex = index + direction;

    if (newIndex < 0 || newIndex >= _items.length) return;

    final reordered = List<RoutineItem>.of(_items);
    final moved = reordered.removeAt(index);

    reordered.insert(newIndex, moved);

    setState(() => _saving = true);

    try {
      await _service.reorderItems(reordered);

      if (!mounted) return;

      setState(() {
        _items = [
          for (var i = 0; i < reordered.length; i++)
            RoutineItem.fromMap({...reordered[i].toMap(), 'sort_order': i}),
        ];
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reorder steps. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete(RoutineItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete step?'),
        content: Text('Remove "${item.title}" from your evening routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);

    try {
      await _service.deleteRoutineItem(item.routineItemId);

      if (!mounted) return;

      setState(() {
        _items = _items
            .where((old) => old.routineItemId != item.routineItemId)
            .toList();

        _completed.remove(item.routineItemId);
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete this step. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _startRoutine() async {
    if (!_session.isActive &&
        _items.any((item) => (item.durationMinutes ?? 0) <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Set a duration of at least 1 minute for every step before starting.',
          ),
        ),
      );

      return;
    }

    final run = _session.startOrContinue(_items);

    final completed = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) =>
            NightRunScreen(controller: run, iconFor: _nightActivityIcon),
      ),
    );

    if (mounted && completed != null) {
      setState(() {
        _completed
          ..clear()
          ..addAll(completed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bedtime = _formatTime(_bedtimeMinutes);
    final startTime = _formatTime(_bedtimeMinutes - _totalMinutes);

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
        appBar: AppBar(title: const Text('Evening routine')),

        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: FilledButton(
            onPressed:
                !_session.isActive &&
                    (_loading || _saving || _error != null || _items.isEmpty)
                ? null
                : _startRoutine,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.nightBrand,
              foregroundColor: AppColors.nightText,
            ),
            child: Text(
              _session.isActive
                  ? 'Continue your evening'
                  : 'Start your evening',
            ),
          ),
        ),

        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.nightText),
                      ),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    InkWell(
                      onTap: _saving ? null : _changeBedtime,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.nightSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I WILL SLEEP AT',
                              style: AppTypography.bodyMuted.copyWith(
                                color: AppColors.nightTextMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bedtime,
                              style: AppTypography.headline.copyWith(
                                color: AppColors.nightText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your evening starts at $startTime'
                              ' · $_totalMinutes min',
                              style: AppTypography.bodyMuted.copyWith(
                                color: AppColors.nightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'YOUR EVENING',
                      style: AppTypography.bodyMuted.copyWith(
                        color: AppColors.nightTextMuted,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (_saving) const LinearProgressIndicator(),

                    if (_items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Your evening is a blank page. '
                          'Add your first step.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.nightText,
                          ),
                        ),
                      ),

                    for (final (index, item) in _items.indexed)
                      NightRoutineItemCard(
                        key: ValueKey(item.routineItemId),
                        item: item,
                        time: _scheduledTime(index),
                        icon: _nightActivityIcon(item.title),
                        onMoveUp: _saving || index == 0
                            ? null
                            : () => _move(index, -1),
                        onMoveDown: _saving || index == _items.length - 1
                            ? null
                            : () => _move(index, 1),
                        onEdit: _saving ? null : () => _edit(item),
                        onDelete: _saving ? null : () => _delete(item),
                      ),

                    const SizedBox(height: 8),

                    TextButton.icon(
                      onPressed: _saving ? null : () => _edit(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add step'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.nightAccent,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(
                            bedtime,
                            style: AppTypography.bodyMuted.copyWith(
                              color: AppColors.nightTextMuted,
                            ),
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.nightSurfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bedtime_outlined,
                            size: 18,
                            color: AppColors.nightAccent,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Sleep',
                          style: AppTypography.body.copyWith(
                            color: AppColors.nightText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      '${_completed.length} of ${_items.length} complete',
                      style: AppTypography.bodyMuted.copyWith(
                        color: AppColors.nightTextMuted,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

IconData _nightActivityIcon(String title) {
  final text = title.toLowerCase();

  for (final entry in <List<String>, IconData>{
    ['phone', 'screen']: Icons.phone_android_outlined,
    ['clean', 'tidy']: Icons.cleaning_services_outlined,
    ['teeth', 'tanden']: Icons.clean_hands_outlined,
    ['shower', 'douch']: Icons.shower_outlined,
    ['read', 'book', 'lezen']: Icons.menu_book_outlined,
    ['meditat', 'breathe']: Icons.self_improvement_outlined,
    ['clothes', 'dress']: Icons.checkroom_outlined,
    ['tea', 'thee']: Icons.local_cafe_outlined,
  }.entries) {
    if (entry.key.any(text.contains)) {
      return entry.value;
    }
  }

  return Icons.nightlight_outlined;
}
