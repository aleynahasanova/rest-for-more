import 'package:flutter/material.dart';

import '../models/routine_item.dart';
import '../services/routine_service.dart';

class RoutineItemEditor extends StatefulWidget {
  const RoutineItemEditor({
    required this.routineId,
    required this.sortOrder,
    required this.onSave,
    this.item,
    super.key,
  });

  final String routineId;
  final int sortOrder;
  final RoutineItem? item;
  final Future<void> Function(RoutineItem) onSave;

  @override
  State<RoutineItemEditor> createState() => _RoutineItemEditorState();
}

class _RoutineItemEditorState extends State<RoutineItemEditor> {
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

      if (mounted) {
        Navigator.pop(context);
      }
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
  Widget build(BuildContext context) {
    return PopScope(
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
                  if ((value ?? '').trim().isEmpty) {
                    return null;
                  }

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

                  if (time.isEmpty) {
                    return null;
                  }

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
}
