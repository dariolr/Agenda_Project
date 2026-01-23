import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/recurrence_rule.dart';

/// Widget per selezionare la configurazione di ricorrenza
class RecurrencePicker extends StatefulWidget {
  const RecurrencePicker({
    super.key,
    required this.startDate,
    this.initialConfig,
    required this.onChanged,
  });

  final DateTime startDate;
  final RecurrenceConfig? initialConfig;
  final ValueChanged<RecurrenceConfig?> onChanged;

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  bool _isEnabled = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.weekly;
  int _intervalValue = 1;
  _EndType _endType = _EndType.count;
  int _occurrenceCount = 6;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialConfig != null) {
      _isEnabled = true;
      _frequency = widget.initialConfig!.frequency;
      _intervalValue = widget.initialConfig!.intervalValue;
      if (widget.initialConfig!.maxOccurrences != null) {
        _endType = _EndType.count;
        _occurrenceCount = widget.initialConfig!.maxOccurrences!;
      } else if (widget.initialConfig!.endDate != null) {
        _endType = _EndType.date;
        _endDate = widget.initialConfig!.endDate;
      } else {
        _endType = _EndType.never;
      }
    }
  }

  void _notifyChange() {
    if (!_isEnabled) {
      widget.onChanged(null);
      return;
    }

    widget.onChanged(
      RecurrenceConfig(
        frequency: _frequency,
        intervalValue: _intervalValue,
        maxOccurrences: _endType == _EndType.count ? _occurrenceCount : null,
        endDate: _endType == _EndType.date ? _endDate : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con checkbox
        InkWell(
          onTap: () {
            setState(() {
              _isEnabled = !_isEnabled;
            });
            _notifyChange();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _isEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isEnabled = value ?? false;
                    });
                    _notifyChange();
                  },
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.repeat,
                  size: 20,
                  color: _isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.recurrenceRepeatBooking,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _isEnabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Contenuto espandibile
        if (_isEnabled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Frequenza
                _buildFrequencySelector(context),
                const SizedBox(height: 16),

                // Termine
                _buildEndSelector(context),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFrequencySelector(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recurrenceFrequency,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(l10n.recurrenceEvery, style: theme.textTheme.bodyMedium),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: DropdownButtonFormField<int>(
                value: _intervalValue,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (i) => i + 1)
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _intervalValue = value);
                    _notifyChange();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<RecurrenceFrequency>(
                value: _frequency,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: RecurrenceFrequency.daily,
                    child: Text(
                      _intervalValue == 1
                          ? l10n.recurrenceDay
                          : l10n.recurrenceDays,
                    ),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceFrequency.weekly,
                    child: Text(
                      _intervalValue == 1
                          ? l10n.recurrenceWeek
                          : l10n.recurrenceWeeks,
                    ),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceFrequency.monthly,
                    child: Text(
                      _intervalValue == 1
                          ? l10n.recurrenceMonth
                          : l10n.recurrenceMonths,
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _frequency = value);
                    _notifyChange();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEndSelector(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recurrenceEnds,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        // Opzione: Mai
        RadioListTile<_EndType>(
          value: _EndType.never,
          groupValue: _endType,
          onChanged: (value) {
            setState(() => _endType = value!);
            _notifyChange();
          },
          title: Text(l10n.recurrenceNever),
          dense: true,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),

        // Opzione: Dopo N occorrenze
        RadioListTile<_EndType>(
          value: _EndType.count,
          groupValue: _endType,
          onChanged: (value) {
            setState(() => _endType = value!);
            _notifyChange();
          },
          title: Row(
            children: [
              Text(l10n.recurrenceAfter),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: DropdownButtonFormField<int>(
                  value: _occurrenceCount,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: [3, 4, 5, 6, 8, 10, 12, 24, 52]
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: _endType == _EndType.count
                      ? (value) {
                          if (value != null) {
                            setState(() => _occurrenceCount = value);
                            _notifyChange();
                          }
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(l10n.recurrenceOccurrences),
            ],
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),

        // Opzione: Data fine
        RadioListTile<_EndType>(
          value: _EndType.date,
          groupValue: _endType,
          onChanged: (value) {
            setState(() => _endType = value!);
            _notifyChange();
          },
          title: Row(
            children: [
              Text(l10n.recurrenceOnDate),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _endType == _EndType.date
                      ? () => _pickEndDate(context)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : l10n.recurrenceSelectDate,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? widget.startDate.add(const Duration(days: 90)),
      firstDate: widget.startDate,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _notifyChange();
    }
  }
}

enum _EndType { never, count, date }
