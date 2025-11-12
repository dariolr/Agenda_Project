import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../domain/clients.dart';

class ClientCard extends ConsumerWidget {
  const ClientCard({
    super.key,
    required this.client,
    this.onTap,
    this.onEdit,
    this.onNewBooking,
  });

  final Client client;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onNewBooking;

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
                if (onNewBooking != null)
                  IconButton(
                    icon: const Icon(Icons.event_available, size: 20),
                    tooltip: context.l10n.actionNewBooking,
                    onPressed: onNewBooking,
                  ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: context.l10n.actionEdit,
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (client.email != null)
              Text(client.email!, style: theme.textTheme.bodySmall),
            if (client.phone != null)
              Text(client.phone!, style: theme.textTheme.bodySmall),
            if (client.lastVisit != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  // Simplified date formatting for now; ideally use intl date formatting
                  'Ultima visita: ${client.lastVisit!.toIso8601String().substring(0, 10)}', // TODO localize/format date
                  style: theme.textTheme.labelSmall,
                ),
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
}
