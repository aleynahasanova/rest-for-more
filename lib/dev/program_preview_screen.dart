import 'package:flutter/material.dart';

import '../screens/program/daily_page_screen.dart';
import 'sample_program.dart';

/// TEMPORARY: a list of the 14 sample days, to open and test the daily page.
/// It will be replaced by the real overview screen.
class ProgramPreviewScreen extends StatelessWidget {
  const ProgramPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programme preview (test)')),
      body: ListView.builder(
        itemCount: SampleProgram.days.length,
        itemBuilder: (context, index) {
          final day = SampleProgram.days[index];

          return ListTile(
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
          );
        },
      ),
    );
  }
}
