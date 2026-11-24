import 'package:flutter/material.dart';

import '../models/program_day.dart';
import '../screens/program/daily_page_screen.dart';
import '../services/program_service.dart';
import 'dev_user.dart';
import 'sample_program.dart';

/// TEMPORARY: a list of the 14 days, to open and test the daily page.
///
/// It shows the user's own programme (made when onboarding was finished). When
/// there is none yet, it shows the fake sample days instead. It will be
/// replaced by the real overview screen.
class ProgramPreviewScreen extends StatefulWidget {
  const ProgramPreviewScreen({super.key});

  @override
  State<ProgramPreviewScreen> createState() => _ProgramPreviewScreenState();
}

class _Loaded {
  const _Loaded(this.programId, this.days);

  /// null when the sample days are shown.
  final String? programId;
  final List<ProgramDay> days;
}

class _ProgramPreviewScreenState extends State<ProgramPreviewScreen> {
  final ProgramService _programService = ProgramService();

  late Future<_Loaded> _future = _load();

  Future<_Loaded> _load() async {
    try {
      final userId = await DevUser.ensure();
      final program = await _programService.getActiveProgramByUserId(userId);

      if (program != null) {
        final days = await _programService.getProgramDays(program.programId);

        if (days.isNotEmpty) return _Loaded(program.programId, days);
      }
    } catch (error) {
      debugPrint('Could not load the programme: $error');
    }

    return _Loaded(null, SampleProgram.days);
  }

  Future<void> _deleteProgram(String programId) async {
    await _programService.deleteProgram(programId);

    if (!mounted) return;

    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Loaded>(
      future: _future,
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        final programId = loaded?.programId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Programme preview (test)'),
            actions: [
              if (programId != null)
                IconButton(
                  tooltip: 'Delete this programme (test)',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteProgram(programId),
                ),
            ],
          ),
          body: loaded == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        programId != null
                            ? 'Your plan, made from your answers.'
                            : 'Sample days. Finish the onboarding to see '
                                'your own plan.',
                      ),
                    ),
                    for (final day in loaded.days)
                      ListTile(
                        title: Text('Day ${day.dayNumber}'),
                        subtitle: Text(day.title),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => DailyPageScreen(day: day),
                            ),
                          );
                        },
                      ),
                  ],
                ),
        );
      },
    );
  }
}
