import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10_extension.dart';
import 'widgets/staff_hub_card.dart';

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
                StaffHubCard(
                  icon: Icons.schedule,
                  title: l10n.staffHubAvailabilityTitle,
                  subtitle: l10n.staffHubAvailabilitySubtitle,
                  onTap: () => context.go('/staff/availability'),
                ),
                StaffHubCard(
                  icon: Icons.group,
                  title: l10n.staffHubTeamTitle,
                  subtitle: l10n.staffHubTeamSubtitle,
                  onTap: () {},
                  disabled: true,
                ),
                StaffHubCard(
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
