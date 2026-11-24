import 'package:flutter/material.dart';

import '../../models/program_day.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'home_widgets.dart';
import 'programme_snapshot.dart';

/// The "Insights" tab, following the wireframe: a calm empty state in a brown
/// card, and no numbers to chase.
///
/// The programme progress below it is self-reported (the user marks a step as
/// done), and it says so (App design: honest progress).
class InsightsTab extends StatelessWidget {
  const InsightsTab({
    super.key,
    required this.programme,
    required this.onOpenOverview,
  });

  /// null while the programme is still loading.
  final ProgrammeSnapshot? programme;

  final VoidCallback onOpenOverview;

  @override
  Widget build(BuildContext context) {
    final snapshot = programme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const HomeSectionLabel('This week'),
          const SizedBox(height: 8),
          Text(
            'Time for yourself',
            style: AppTypography.headline.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nothing yet this week',
                  style: AppTypography.headline.copyWith(
                    fontSize: 30,
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'As soon as you finish a moment, it shows up here. '
                  'No numbers to reach, only to look back on.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.surface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (snapshot != null && snapshot.hasProgramme) ...[
            const SizedBox(height: 30),
            const HomeSectionLabel('Your programme'),
            const SizedBox(height: 10),
            HomeRow(
              icon: Icons.calendar_month_outlined,
              title: 'My 14 days',
              subtitle: 'You marked ${snapshot.doneCount} of '
                  '${ProgramDay.totalDays} steps as done',
              onTap: onOpenOverview,
            ),
          ],
        ],
      ),
    );
  }
}
