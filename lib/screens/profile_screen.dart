import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.user,
    required this.onOpenProgramme,
    required this.onLogout,
    super.key,
  });

  final User user;
  final VoidCallback onOpenProgramme;
  final VoidCallback onLogout;

  void _logout(BuildContext context) {
    // Return to the first route before switching the app back to Login.
    Navigator.of(context).popUntil((route) => route.isFirst);

    onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _SectionLabel('Account'),

            const SizedBox(height: 8),

            Text(
              'Your profile',
              style: AppTypography.headline.copyWith(fontSize: 34),
            ),

            const SizedBox(height: 24),

            // User information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.brand,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.brandTint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const _SectionLabel('Your programme'),

            const SizedBox(height: 10),

            _ProfileRow(
              icon: Icons.calendar_month_outlined,
              title: 'My 14 days',
              subtitle: 'View your personal programme',
              onTap: onOpenProgramme,
            ),

            const SizedBox(height: 30),

            const _SectionLabel('Account'),

            const SizedBox(height: 10),

            _ProfileRow(
              icon: Icons.logout,
              title: 'Log out',
              subtitle: 'Return to the login screen',
              onTap: () {
                _logout(context);
              },
            ),

            const SizedBox(height: 32),

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
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
        color: AppColors.brandTint,
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.brand),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.brandTint,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: AppColors.brandTint),
            ],
          ),
        ),
      ),
    );
  }
}
