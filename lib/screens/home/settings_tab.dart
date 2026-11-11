import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'home_widgets.dart';

/// The "Settings" tab, following the wireframe ("Your rhythm"). It only has
/// rows for screens that exist, so nothing here is an unfinished button.
class SettingsTab extends StatelessWidget {
  const SettingsTab({
    super.key,
    required this.hasProgramme,
    required this.onOpenProfile,
    required this.onOpenMorning,
    required this.onOpenEvening,
    required this.onOpenOverview,
    required this.onResetPlan,
  });

  final bool hasProgramme;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenMorning;
  final VoidCallback onOpenEvening;
  final VoidCallback onOpenOverview;
  final VoidCallback onResetPlan;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const HomeSectionLabel('Settings'),
          const SizedBox(height: 8),
          Text(
            'Your rhythm',
            style: AppTypography.headline.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 24),
          HomeRow(
            icon: Icons.wb_sunny_outlined,
            title: 'Morning routine',
            subtitle: 'Steps, order and times',
            onTap: onOpenMorning,
          ),
          const SizedBox(height: 10),
          HomeRow(
            icon: Icons.bedtime_outlined,
            title: 'Evening routine',
            subtitle: 'Steps, order and bedtime',
            onTap: onOpenEvening,
          ),
          if (hasProgramme) ...[
            const SizedBox(height: 10),
            HomeRow(
              icon: Icons.calendar_month_outlined,
              title: 'My 14 days',
              subtitle: 'View your personal programme',
              onTap: onOpenOverview,
            ),
          ],
          const SizedBox(height: 30),
          const HomeSectionLabel('Account'),
          const SizedBox(height: 10),
          HomeRow(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Your details and log out',
            onTap: onOpenProfile,
          ),

          // TEMPORARY, for testing: deletes the plan, so the onboarding
          // shows again. Remove before the final version.
          if (hasProgramme) ...[
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: onResetPlan,
                child: const Text('Reset my plan'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Rest For More',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.brandTint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
