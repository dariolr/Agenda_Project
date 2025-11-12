import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10_extension.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navStaff)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.staffScreenPlaceholder,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StaffHubCard(
                  icon: Icons.schedule,
                  title: l10n.staffHubAvailabilityTitle,
                  subtitle: l10n.staffHubAvailabilitySubtitle,
                  onTap: () => context.go('/staff/availability'),
                ),
                _StaffHubCard(
                  icon: Icons.group,
                  title: l10n.staffHubTeamTitle,
                  subtitle: l10n.staffHubTeamSubtitle,
                  onTap: () {},
                  disabled: true,
                ),
                _StaffHubCard(
                  icon: Icons.insights,
                  title: l10n.staffHubStatsTitle,
                  subtitle: l10n.staffHubStatsSubtitle,
                  onTap: () {},
                  disabled: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffHubCard extends StatelessWidget {
  const _StaffHubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = disabled
        ? colorScheme.surfaceVariant
        : colorScheme.secondaryContainer;
    final fgColor = disabled
        ? colorScheme.onSurfaceVariant.withOpacity(0.6)
        : colorScheme.onSecondaryContainer;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        width: 260,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: fgColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: fgColor.withOpacity(0.85)),
            ),
            if (disabled)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  context.l10n.staffHubNotYetAvailable,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
