import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/clients.dart';
import '../../providers/clients_providers.dart';
import '../dialogs/client_appointments_dialog.dart';

class ClientCard extends ConsumerWidget {
  const ClientCard({super.key, required this.client, this.onTap});

  final Client client;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tags = client.tags ?? const [];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(
                    client.name.isNotEmpty
                        ? client.name.substring(0, 1).toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(client.name, style: theme.textTheme.titleMedium),
                ),
                _DeleteButton(client: client),
              ],
            ),
            const SizedBox(height: 8),
            if (client.email != null)
              Text(client.email!, style: theme.textTheme.bodySmall),
            if (client.phone != null)
              Text(client.phone!, style: theme.textTheme.bodySmall),
            // Riga con ultima visita e icona appuntamenti
            Row(
              children: [
                if (client.lastVisit != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _buildLastVisitLabel(context, client.lastVisit!),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                _AppointmentsButton(client: client),
              ],
            ),
            if (tags.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: -4,
                children: [
                  for (final t in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t, style: theme.textTheme.labelSmall),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _buildLastVisitLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Esempio coerente con altre parti dell'app (e.g. staff widgets): d MMM y
    final formatted = DateFormat('d MMM y', locale).format(date);
    // Nota: il label non è ancora in L10n; lasciamo la stringa italiana di default.
    return 'Ultima visita: $formatted';
  }
}

class _AppointmentsButton extends ConsumerWidget {
  const _AppointmentsButton({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appointments = ref.watch(clientWithAppointmentsProvider(client.id));
    final now = DateTime.now();

    final upcoming = appointments.where((a) => a.startTime.isAfter(now)).length;
    final past = appointments.length - upcoming;
    final total = appointments.length;

    return InkWell(
      onTap: () => showClientAppointmentsDialog(context, ref, client: client),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            if (total > 0) ...[
              const SizedBox(width: 6),
              // Badge appuntamenti futuri (verde)
              if (upcoming > 0)
                _AppointmentBadge(
                  count: upcoming,
                  color: Colors.green,
                  icon: Icons.arrow_upward,
                ),
              if (upcoming > 0 && past > 0) const SizedBox(width: 4),
              // Badge appuntamenti passati (grigio)
              if (past > 0)
                _AppointmentBadge(
                  count: past,
                  color: theme.colorScheme.onSurfaceVariant,
                  icon: Icons.arrow_downward,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppointmentBadge extends StatelessWidget {
  const _AppointmentBadge({
    required this.count,
    required this.color,
    required this.icon,
  });

  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.error.withOpacity(0.7),
        ),
        onPressed: () => _onDelete(context, ref),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showConfirmDialog(
      context,
      title: Text(context.l10n.deleteClientConfirmTitle),
      content: Text(context.l10n.deleteClientConfirmMessage),
      confirmLabel: context.l10n.actionDelete,
      danger: true,
    );
    if (!confirm) return;

    ref.read(clientsProvider.notifier).deleteClient(client.id);
  }
}
