import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/app_buttons.dart';

/// Risultato della creazione di una serie ricorrente
class RecurringBookingResult {
  final int recurrenceRuleId;
  final int createdCount;
  final int skippedCount;
  final List<RecurringBookingItem> bookings;

  const RecurringBookingResult({
    required this.recurrenceRuleId,
    required this.createdCount,
    required this.skippedCount,
    required this.bookings,
  });

  factory RecurringBookingResult.fromJson(Map<String, dynamic> json) {
    final bookingsList =
        (json['bookings'] as List<dynamic>?)
            ?.map(
              (b) => RecurringBookingItem.fromJson(b as Map<String, dynamic>),
            )
            .toList() ??
        [];
    return RecurringBookingResult(
      recurrenceRuleId: json['recurrence_rule_id'] as int,
      createdCount: json['created_count'] as int,
      skippedCount: json['skipped_count'] as int? ?? 0,
      bookings: bookingsList,
    );
  }
}

class RecurringBookingItem {
  final int id;
  final int recurrenceIndex;
  final DateTime startTime;
  final String status;

  const RecurringBookingItem({
    required this.id,
    required this.recurrenceIndex,
    required this.startTime,
    required this.status,
  });

  factory RecurringBookingItem.fromJson(Map<String, dynamic> json) {
    return RecurringBookingItem(
      id: json['id'] as int,
      recurrenceIndex: json['recurrence_index'] as int,
      startTime: DateTime.parse(json['start_time'] as String),
      status: json['status'] as String? ?? 'confirmed',
    );
  }
}

/// Dialog che mostra il riepilogo dopo la creazione di una serie ricorrente
class RecurrenceSummaryDialog extends StatelessWidget {
  const RecurrenceSummaryDialog({super.key, required this.result});

  final RecurringBookingResult result;

  static Future<void> show(
    BuildContext context,
    RecurringBookingResult result,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RecurrenceSummaryDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE dd MMM yyyy', 'it');
    final timeFormat = DateFormat('HH:mm', 'it');

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(l10n.recurrenceSummaryTitle),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiche
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.event_available,
                      value: '${result.createdCount}',
                      label: l10n.recurrenceSummaryCreated(result.createdCount),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (result.skippedCount > 0) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.event_busy,
                        value: '${result.skippedCount}',
                        label: l10n.recurrenceSummarySkipped(
                          result.skippedCount,
                        ),
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista appuntamenti creati
            Text('Appuntamenti:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: result.bookings.length,
                itemBuilder: (ctx, index) {
                  final booking = result.bookings[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      dateFormat.format(booking.startTime),
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: Text(
                      timeFormat.format(booking.startTime),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppFilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionClose),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
