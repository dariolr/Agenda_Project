import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/app_buttons.dart';

/// Risultato dell'anteprima di una serie ricorrente (prima della creazione)
class RecurringPreviewResult {
  final int totalDates;
  final List<PreviewDateItem> dates;

  const RecurringPreviewResult({required this.totalDates, required this.dates});

  factory RecurringPreviewResult.fromJson(Map<String, dynamic> json) {
    final datesList =
        (json['dates'] as List<dynamic>?)
            ?.map((d) => PreviewDateItem.fromJson(d as Map<String, dynamic>))
            .toList() ??
        [];
    return RecurringPreviewResult(
      totalDates: json['total_dates'] as int,
      dates: datesList,
    );
  }
}

/// Singola data nell'anteprima
class PreviewDateItem {
  final int recurrenceIndex;
  final DateTime startTime;
  final DateTime endTime;
  final bool hasConflict;

  const PreviewDateItem({
    required this.recurrenceIndex,
    required this.startTime,
    required this.endTime,
    required this.hasConflict,
  });

  factory PreviewDateItem.fromJson(Map<String, dynamic> json) {
    return PreviewDateItem(
      recurrenceIndex: json['recurrence_index'] as int,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      hasConflict: json['has_conflict'] as bool? ?? false,
    );
  }
}

/// Risultato della creazione di una serie ricorrente
class RecurringBookingResult {
  final int recurrenceRuleId;
  final int createdCount;
  final int skippedCount;
  final List<RecurringBookingItem> bookings;
  final List<SkippedDateItem> skippedDates;

  const RecurringBookingResult({
    required this.recurrenceRuleId,
    required this.createdCount,
    required this.skippedCount,
    required this.bookings,
    required this.skippedDates,
  });

  factory RecurringBookingResult.fromJson(Map<String, dynamic> json) {
    final bookingsList =
        (json['bookings'] as List<dynamic>?)
            ?.map(
              (b) => RecurringBookingItem.fromJson(b as Map<String, dynamic>),
            )
            .toList() ??
        [];
    final skippedList =
        (json['skipped_dates'] as List<dynamic>?)
            ?.map((s) => SkippedDateItem.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    return RecurringBookingResult(
      recurrenceRuleId: json['recurrence_rule_id'] as int,
      createdCount: json['created_count'] as int,
      skippedCount: json['skipped_count'] as int? ?? 0,
      bookings: bookingsList,
      skippedDates: skippedList,
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

/// Data saltata per conflitto
class SkippedDateItem {
  final int recurrenceIndex;
  final DateTime startTime;
  final String reason;

  const SkippedDateItem({
    required this.recurrenceIndex,
    required this.startTime,
    required this.reason,
  });

  factory SkippedDateItem.fromJson(Map<String, dynamic> json) {
    return SkippedDateItem(
      recurrenceIndex: json['recurrence_index'] as int,
      startTime: DateTime.parse(json['start_time'] as String),
      reason: json['reason'] as String? ?? 'conflict',
    );
  }
}

/// Dialog che mostra il riepilogo dopo la creazione di una serie ricorrente
class RecurrenceSummaryDialog extends StatefulWidget {
  const RecurrenceSummaryDialog({
    super.key,
    required this.result,
    this.onDeleteBooking,
  });

  final RecurringBookingResult result;
  final Future<bool> Function(int bookingId)? onDeleteBooking;

  static Future<void> show(
    BuildContext context,
    RecurringBookingResult result, {
    Future<bool> Function(int bookingId)? onDeleteBooking,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RecurrenceSummaryDialog(
        result: result,
        onDeleteBooking: onDeleteBooking,
      ),
    );
  }

  @override
  State<RecurrenceSummaryDialog> createState() =>
      _RecurrenceSummaryDialogState();
}

class _RecurrenceSummaryDialogState extends State<RecurrenceSummaryDialog> {
  late List<RecurringBookingItem> _activeBookings;
  late List<int> _deletedBookingIds;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _activeBookings = List.from(widget.result.bookings);
    _deletedBookingIds = [];
  }

  Future<void> _deleteBooking(RecurringBookingItem booking) async {
    if (_isDeleting || widget.onDeleteBooking == null) return;

    setState(() => _isDeleting = true);

    try {
      final success = await widget.onDeleteBooking!(booking.id);
      if (success && mounted) {
        setState(() {
          _activeBookings.removeWhere((b) => b.id == booking.id);
          _deletedBookingIds.add(booking.id);
        });
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE dd MMM yyyy', 'it');
    final timeFormat = DateFormat('HH:mm', 'it');

    // Combina tutte le date (create, eliminate, saltate) ordinate per data
    final allDates = <_CombinedDateItem>[];

    // Aggiungi booking attivi
    for (final booking in _activeBookings) {
      allDates.add(
        _CombinedDateItem(
          recurrenceIndex: booking.recurrenceIndex,
          startTime: booking.startTime,
          type: _DateType.created,
          bookingId: booking.id,
        ),
      );
    }

    // Aggiungi booking eliminati (mostrati come disabilitati)
    for (final booking in widget.result.bookings) {
      if (_deletedBookingIds.contains(booking.id)) {
        allDates.add(
          _CombinedDateItem(
            recurrenceIndex: booking.recurrenceIndex,
            startTime: booking.startTime,
            type: _DateType.deleted,
          ),
        );
      }
    }

    // Aggiungi date saltate
    for (final skipped in widget.result.skippedDates) {
      allDates.add(
        _CombinedDateItem(
          recurrenceIndex: skipped.recurrenceIndex,
          startTime: skipped.startTime,
          type: _DateType.skipped,
        ),
      );
    }

    // Ordina per recurrence_index
    allDates.sort((a, b) => a.recurrenceIndex.compareTo(b.recurrenceIndex));

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.recurrenceSummaryTitle)),
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
                      value: '${_activeBookings.length}',
                      label: l10n.recurrenceSummaryCreated(
                        _activeBookings.length,
                      ),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (widget.result.skippedCount > 0 ||
                      _deletedBookingIds.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.event_busy,
                        value:
                            '${widget.result.skippedCount + _deletedBookingIds.length}',
                        label: l10n.recurrenceSummarySkipped(
                          widget.result.skippedCount +
                              _deletedBookingIds.length,
                        ),
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista tutte le date
            Text(
              l10n.recurrenceSummaryAppointments,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allDates.length,
                itemBuilder: (ctx, index) {
                  final item = allDates[index];
                  final isDisabled =
                      item.type == _DateType.skipped ||
                      item.type == _DateType.deleted;

                  return Opacity(
                    opacity: isDisabled ? 0.5 : 1.0,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isDisabled
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.primaryContainer,
                        child: isDisabled
                            ? Icon(
                                item.type == _DateType.skipped
                                    ? Icons.block
                                    : Icons.delete_outline,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              )
                            : Text(
                                '${index + 1}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                      ),
                      title: Text(
                        dateFormat.format(item.startTime),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: isDisabled
                              ? TextDecoration.lineThrough
                              : null,
                          color: isDisabled
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      subtitle: isDisabled
                          ? Text(
                              item.type == _DateType.skipped
                                  ? l10n.recurrenceSummaryConflict
                                  : l10n.recurrenceSummaryDeleted,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeFormat.format(item.startTime),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDisabled
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.primary,
                              fontWeight: isDisabled ? null : FontWeight.w600,
                            ),
                          ),
                          if (!isDisabled &&
                              widget.onDeleteBooking != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: _isDeleting
                                  ? null
                                  : () => _deleteBooking(
                                      _activeBookings.firstWhere(
                                        (b) => b.id == item.bookingId,
                                      ),
                                    ),
                              tooltip: l10n.actionDelete,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ],
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

enum _DateType { created, skipped, deleted }

class _CombinedDateItem {
  final int recurrenceIndex;
  final DateTime startTime;
  final _DateType type;
  final int? bookingId;

  const _CombinedDateItem({
    required this.recurrenceIndex,
    required this.startTime,
    required this.type,
    this.bookingId,
  });
}

/// Dialog che mostra l'ANTEPRIMA delle date PRIMA della creazione
/// Permette di escludere date prima di confermare
/// Ritorna la lista degli indici da ESCLUDERE, oppure null se annullato
class RecurrencePreviewDialog extends StatefulWidget {
  const RecurrencePreviewDialog({
    super.key,
    required this.preview,
    this.titleText,
    this.hintText,
    this.confirmLabelBuilder,
    this.excludeConflictsByDefault = true,
  });

  final RecurringPreviewResult preview;
  final String? titleText;
  final String? hintText;
  final String Function(int count)? confirmLabelBuilder;
  final bool excludeConflictsByDefault;

  /// Mostra il dialog e ritorna la lista degli indici da escludere.
  /// Ritorna null se l'utente annulla.
  static Future<List<int>?> show(
    BuildContext context,
    RecurringPreviewResult preview, {
    String? titleText,
    String? hintText,
    String Function(int count)? confirmLabelBuilder,
    bool excludeConflictsByDefault = true,
  }) async {
    return showDialog<List<int>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RecurrencePreviewDialog(
        preview: preview,
        titleText: titleText,
        hintText: hintText,
        confirmLabelBuilder: confirmLabelBuilder,
        excludeConflictsByDefault: excludeConflictsByDefault,
      ),
    );
  }

  @override
  State<RecurrencePreviewDialog> createState() =>
      _RecurrencePreviewDialogState();
}

class _RecurrencePreviewDialogState extends State<RecurrencePreviewDialog> {
  late Set<int> _excludedIndices;

  @override
  void initState() {
    super.initState();
    _excludedIndices = widget.excludeConflictsByDefault
        ? widget.preview.dates
              .where((d) => d.hasConflict)
              .map((d) => d.recurrenceIndex)
              .toSet()
        : <int>{};
  }

  void _toggleDate(int index) {
    setState(() {
      if (_excludedIndices.contains(index)) {
        _excludedIndices.remove(index);
      } else {
        _excludedIndices.add(index);
      }
    });
  }

  void _confirm() {
    final selectedCount = widget.preview.dates.length - _excludedIndices.length;
    if (selectedCount == 0) {
      return; // Non permettere creazione senza date selezionate
    }
    Navigator.of(context).pop(_excludedIndices.toList());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE dd MMM yyyy', 'it');
    final timeFormat = DateFormat('HH:mm', 'it');

    final selectedCount = widget.preview.dates.length - _excludedIndices.length;
    final conflictCount = widget.preview.dates
        .where((d) => d.hasConflict)
        .length;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.preview, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.titleText ?? l10n.recurrencePreviewTitle)),
        ],
      ),
      content: SizedBox(
        width: 450,
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
                      value: '$selectedCount',
                      label: l10n.recurrencePreviewSelected(selectedCount),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (conflictCount > 0) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.warning_amber,
                        value: '$conflictCount',
                        label: l10n.recurrencePreviewConflicts(conflictCount),
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hint per escludere date
            Text(
              widget.hintText ?? l10n.recurrencePreviewHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // Lista date con checkbox
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.preview.dates.length,
                itemBuilder: (ctx, index) {
                  final date = widget.preview.dates[index];
                  final isExcluded = _excludedIndices.contains(
                    date.recurrenceIndex,
                  );
                  final hasConflict = date.hasConflict;

                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: !isExcluded,
                    onChanged: (val) => _toggleDate(date.recurrenceIndex),
                    secondary: hasConflict
                        ? Tooltip(
                            message: l10n.recurrenceSummaryConflict,
                            child: Icon(
                              Icons.warning_amber,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                          )
                        : null,
                    title: Text(
                      dateFormat.format(date.startTime),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: isExcluded
                            ? TextDecoration.lineThrough
                            : null,
                        color: isExcluded
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    subtitle: hasConflict
                        ? Text(
                            isExcluded
                                ? l10n.recurrencePreviewConflictSkip
                                : l10n.recurrencePreviewConflictForce,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isExcluded
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          )
                        : Text(
                            timeFormat.format(date.startTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isExcluded
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.primary,
                              fontWeight: isExcluded ? null : FontWeight.w600,
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.actionCancel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: selectedCount > 0 ? _confirm : null,
          child: Text(
            widget.confirmLabelBuilder?.call(selectedCount) ??
                l10n.recurrencePreviewConfirm(selectedCount),
          ),
        ),
      ],
    );
  }
}
