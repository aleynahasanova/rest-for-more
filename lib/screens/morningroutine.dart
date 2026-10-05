import 'package:flutter/material.dart';

import '../components/routine_item.dart';
import '../models/routine.dart';
import '../models/routine_item.dart';
import '../services/routine_service.dart';
import 'morning_run_screen.dart';
import '../controllers/morning_routine_session.dart';

class MorningRoutineScreen extends StatefulWidget {
  /// Starter content owned by the morning routine, seeded only on creation.
  static const defaultItems = <(String, String, int)>[
    ('Drink water', 'Start your morning with a glass of water.', 2),
    ('Morning stretch', 'Take a gentle movement break.', 5),
    ('Freshen up', 'Make time to get ready for the day.', 10),
    ('Have breakfast', 'Sit down and enjoy your breakfast.', 15),
    ('Plan your day', 'Choose what matters most today.', 5),
  ];

  const MorningRoutineScreen({
    this.service,
    this.userId,
    this.session,
    super.key,
  });
  final MorningRoutineSession? session;
  final RoutineService? service;
  final String? userId;
  @override
  State<MorningRoutineScreen> createState() => _MorningRoutineScreenState();
}

class _MorningRoutineScreenState extends State<MorningRoutineScreen> {
  late final RoutineService _service = widget.service ?? RoutineService();
  Routine? _routine;
  List<RoutineItem> _items = [];
  final Set<String> _completed = {};
  bool _loading = true;
  late final MorningRoutineSession _session;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? MorningRoutineSession();
    _session.addListener(_sessionChanged);
    _load();
  }

  void _sessionChanged() {
    if (!mounted) return;
    setState(() {
      final run = _session.run;
      if (run != null) {
        _completed.clear();
        _completed.addAll(run.completedIds);
      }
    });
  }

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    if (widget.session == null) _session.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final routine = await _service.ensureMorningRoutine(
        userId: widget.userId,
        defaults: MorningRoutineScreen.defaultItems,
      );
      final items = await _service.getRoutineItems(routine.routineId);
      if (!mounted) return;
      setState(() {
        _routine = routine;
        _items = items;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load your routine. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([RoutineItem? item]) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RoutineItemEditor(
        routineId: _routine!.routineId,
        item: item,
        sortOrder:
            _items.fold<int>(
              -1,
              (max, item) => item.sortOrder > max ? item.sortOrder : max,
            ) +
            1,
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
            MorningRunScreen(controller: run, iconFor: _morningActivityIcon),
      ),
    );
    if (mounted && completed != null) {
      setState(() {
        _completed.clear();
        _completed.addAll(completed);
      });
    }
  }

  // Preview starts at 07:00, as in the prototype. Explicit stored times win.
  String _scheduledTime(int index) {
    var minutes = 7 * 60;
    for (var i = 0; i <= index; i++) {
      final explicit = RoutineItemCard.clockTime(_items[i].startTime);
      if (explicit != null) {
        final parts = explicit.split(':');
        minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
      if (i == index) break;
      minutes += _items[i].durationMinutes ?? 0;
    }
    return '${(minutes ~/ 60 % 24).toString().padLeft(2, '0')}:'
        '${(minutes % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _move(int index, int direction) async {
    final reordered = List<RoutineItem>.of(_items);
    final moved = reordered.removeAt(index);
    reordered.insert(index + direction, moved);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not reorder steps. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(RoutineItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete step?'),
        content: Text('Remove "${item.title}" from your morning routine?'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this step. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Morning routine')),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: FilledButton(
        onPressed:
            !_session.isActive &&
                (_loading || _saving || _error != null || _items.isEmpty)
            ? null
            : _startRoutine,
        child: Text(
          _session.isActive ? 'Continue your morning' : 'Start your morning',
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
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Make time for your morning',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_completed.length} of ${_items.length} complete • ${_items.fold<int>(0, (sum, item) => sum + (item.durationMinutes ?? 0))} min planned',
                ),
                const SizedBox(height: 16),
                if (_saving) const LinearProgressIndicator(),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Your morning is a blank page. Add your first step.',
                    ),
                  ),
                for (final (index, item) in _items.indexed)
                  RoutineItemCard(
                    key: ValueKey(item.routineItemId),
                    item: item,
                    time: _scheduledTime(index),
                    icon: _morningActivityIcon(item.title),
                    onMoveUp: _saving || index == 0
                        ? null
                        : () => _move(index, -1),
                    onMoveDown: _saving || index == _items.length - 1
                        ? null
                        : () => _move(index, 1),
                    isCompleted: _completed.contains(item.routineItemId),
                    onCompletedChanged: _saving
                        ? null
                        : (value) => setState(() {
                            if (value) {
                              _completed.add(item.routineItemId);
                            } else {
                              _completed.remove(item.routineItemId);
                            }
                          }),
                    onEdit: _saving ? null : () => _edit(item),
                    onDelete: _saving ? null : () => _delete(item),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add step'),
                ),
              ],
            ),
    ),
  );
}

class _RoutineItemEditor extends StatefulWidget {
  const _RoutineItemEditor({
    required this.routineId,
    required this.sortOrder,
    required this.onSave,
    this.item,
  });
  final String routineId;
  final int sortOrder;
  final RoutineItem? item;
  final Future<void> Function(RoutineItem) onSave;
  @override
  State<_RoutineItemEditor> createState() => _RoutineItemEditorState();
}

class _RoutineItemEditorState extends State<_RoutineItemEditor> {
  final _form = GlobalKey<FormState>();
  late final String _id = widget.item?.routineItemId ?? RoutineService.newId();
  late String _title = widget.item?.title ?? '';
  late String _description = widget.item?.description ?? '';
  late String _duration = widget.item?.durationMinutes?.toString() ?? '';
  late String _time = widget.item?.startTime ?? '';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final old = widget.item;
    try {
      await widget.onSave(
        RoutineItem(
          routineItemId: _id,
          routineId: widget.routineId,
          title: _title.trim(),
          description: _description.trim().isEmpty ? null : _description.trim(),
          startTime: _time.trim().isEmpty ? null : _time.trim(),
          durationMinutes: int.tryParse(_duration.trim()),
          sortOrder: old?.sortOrder ?? widget.sortOrder,
          isDefault: old?.isDefault ?? false,
          createdAt: old?.createdAt ?? DateTime.now(),
          updatedAt: old == null ? null : DateTime.now(),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save this step. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      scrollable: true,
      title: Text(widget.item == null ? 'Add step' : 'Edit step'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            TextFormField(
              initialValue: _title,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Title'),
              maxLength: 150,
              onChanged: (value) => _title = value,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter a title.' : null,
            ),
            TextFormField(
              initialValue: _description,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              minLines: 1,
              maxLines: 3,
              onChanged: (value) => _description = value,
            ),
            TextFormField(
              initialValue: _duration,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Duration in minutes (optional)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _duration = value,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return null;
                final minutes = int.tryParse(value!.trim());
                return minutes == null || minutes < 0
                    ? 'Enter a whole number of 0 or more.'
                    : null;
              },
            ),
            TextFormField(
              initialValue: _time,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Start time (optional)',
                helperText: '24-hour time, e.g. 07:30',
              ),
              onChanged: (value) => _time = value,
              validator: (value) {
                final time = (value ?? '').trim();
                if (time.isEmpty) return null;
                return RegExp(
                      r'^([01]\d|2[0-3]):[0-5]\d(?::[0-5]\d(?:\.\d+)?)?$',
                    ).hasMatch(time)
                    ? null
                    : 'Enter a valid time, e.g. 07:30.';
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}

// The schema has no icon field. Derive an activity icon for known titles;
// callers can override it without storing presentation details in SQLite.
IconData _morningActivityIcon(String title) {
  final text = title.toLowerCase();
  for (final entry in <List<String>, IconData>{
    ['water']: Icons.water_drop_outlined,
    ['shower', 'douch', 'freshen']: Icons.shower_outlined,
    ['teeth', 'tanden']: Icons.clean_hands_outlined,
    ['dress', 'aankleden']: Icons.checkroom_outlined,
    ['breakfast', 'ontbijt']: Icons.restaurant_outlined,
    ['coffee', 'tea', 'koffie', 'thee']: Icons.local_cafe_outlined,
    ['bed']: Icons.bed_outlined,
    ['walk', 'buiten']: Icons.directions_walk_rounded,
    ['stretch', 'exercise', 'bewegen', 'rekken']: Icons.fitness_center_outlined,
    ['breathe', 'meditat', 'stil zitten']: Icons.self_improvement_outlined,
    ['read', 'lezen']: Icons.menu_book_outlined,
    ['plan', 'write', 'schrijven']: Icons.edit_note_rounded,
  }.entries) {
    if (entry.key.any(text.contains)) return entry.value;
  }
  return Icons.check_circle_outline_rounded;
}
