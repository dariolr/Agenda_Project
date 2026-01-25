import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/recurrence_rule.dart';

/// Widget che mostra un'anteprima delle date ricorrenti calcolate
class RecurrencePreview extends StatelessWidget {
  const RecurrencePreview({
    super.key,
    required this.startDate,
    required this.config,
    this.maxVisible = 6,
  });

  final DateTime startDate;
  final RecurrenceConfig config;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dates = config.calculateOccurrences(startDate);
    final visibleDates = dates.take(maxVisible).toList();
    final hasMore = dates.length > maxVisible;
    final totalCount = config.maxOccurrences ?? dates.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.event_repeat,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.recurrencePreviewTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                l10n.recurrencePreviewCount(totalCount),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...visibleDates.asMap().entries.map((entry) {
                final index = entry.key;
                final date = entry.value;
                final isFirst = index == 0;
                return _DateChip(date: date, isFirst: isFirst, theme: theme);
              }),
              if (hasMore)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${dates.length - maxVisible}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),

          // Riepilogo frequenza
          const SizedBox(height: 8),
          Text(
            config.toReadableString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.isFirst,
    required this.theme,
  });

  final DateTime date;
  final bool isFirst;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM', 'it');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFirst
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateFormat.format(date),
        style: theme.textTheme.labelSmall?.copyWith(
          color: isFirst
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: isFirst ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

extension on RecurrenceConfig {
  String toReadableString() {
    final interval = intervalValue;
    switch (frequency) {
      case RecurrenceFrequency.daily:
        if (interval == 1) return 'Ogni giorno';
        return 'Ogni $interval giorni';
      case RecurrenceFrequency.weekly:
        if (interval == 1) return 'Ogni settimana';
        return 'Ogni $interval settimane';
      case RecurrenceFrequency.monthly:
        if (interval == 1) return 'Ogni mese';
        return 'Ogni $interval mesi';
      case RecurrenceFrequency.custom:
        return 'Ogni $interval giorni';
    }
  }
}
