import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/core/widgets/app_bottom_sheet.dart';
import 'package:agenda_frontend/core/widgets/labeled_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/availability_exception.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../agenda/providers/layout_config_provider.dart';
import '../../providers/availability_exceptions_provider.dart';

/// Mostra il dialog per creare o modificare un'eccezione alla disponibilità.
Future<void> showAddExceptionDialog(
  BuildContext context,
  WidgetRef ref, {
  AvailabilityException? initial,
  DateTime? date,
  TimeOfDay? time,
  required int staffId,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;

  final dialog = _AddExceptionDialog(
    initial: initial,
    initialDate: date,
    initialTime: time,
    staffId: staffId,
    presentation: isDesktop
        ? _ExceptionDialogPresentation.dialog
        : _ExceptionDialogPresentation.bottomSheet,
  );

  if (isDesktop) {
    await showDialog(context: context, builder: (_) => dialog);
  } else {
    await AppBottomSheet.show(
      context: context,
      useRootNavigator: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      builder: (_) => dialog,
    );
  }
}

enum _ExceptionDialogPresentation { dialog, bottomSheet }

/// Modalità di selezione del periodo
enum _PeriodMode { single, range, duration }

class _AddExceptionDialog extends ConsumerStatefulWidget {
  const _AddExceptionDialog({
    this.initial,
    this.initialDate,
    this.initialTime,
    required this.staffId,
    required this.presentation,
  });

  final AvailabilityException? initial;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int staffId;
  final _ExceptionDialogPresentation presentation;

  @override
  ConsumerState<_AddExceptionDialog> createState() =>
      _AddExceptionDialogState();
}

class _AddExceptionDialogState extends ConsumerState<_AddExceptionDialog> {
  // Modalità periodo (solo per nuove eccezioni)
  _PeriodMode _periodMode = _PeriodMode.single;

  // Date
  late DateTime _date; // Per singolo giorno
  late DateTime _startDate; // Per range/durata
  late DateTime _endDate; // Per range
  int _durationDays = 7; // Per durata

  // Orari
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late AvailabilityExceptionType _type;
  final _reasonController = TextEditingController();
  bool _isAllDay = false;
  String? _timeError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.initial != null) {
      final exc = widget.initial!;
      _date = DateTime(exc.date.year, exc.date.month, exc.date.day);
      _startDate = _date;
      _endDate = _date;
      _isAllDay = exc.isAllDay;
      _startTime = exc.startTime ?? const TimeOfDay(hour: 9, minute: 0);
      _endTime = exc.endTime ?? const TimeOfDay(hour: 18, minute: 0);
      _type = exc.type;
      _reasonController.text = exc.reason ?? '';
    } else {
      _date = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
      _startDate = _date;
      _endDate = _date.add(const Duration(days: 6)); // Default 1 settimana
      _startTime = widget.initialTime ?? const TimeOfDay(hour: 9, minute: 0);
      _endTime = TimeOfDay(
        hour: _startTime.hour + 1,
        minute: _startTime.minute,
      );
      _type = AvailabilityExceptionType.unavailable;
      _isAllDay = true; // Default giornata intera per periodi
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.initial != null;
    final isDialog = widget.presentation == _ExceptionDialogPresentation.dialog;

    final title = isEdit
        ? l10n.exceptionDialogTitleEdit
        : l10n.exceptionDialogTitleNew;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipo eccezione
        LabeledFormField(
          label: l10n.exceptionType,
          child: SegmentedButton<AvailabilityExceptionType>(
            segments: [
              ButtonSegment(
                value: AvailabilityExceptionType.unavailable,
                label: Text(l10n.exceptionTypeUnavailable),
                icon: const Icon(Icons.block, size: 18),
              ),
              ButtonSegment(
                value: AvailabilityExceptionType.available,
                label: Text(l10n.exceptionTypeAvailable),
                icon: const Icon(Icons.check_circle_outline, size: 18),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (selected) {
              setState(() => _type = selected.first);
            },
          ),
        ),
        const SizedBox(height: 16),

        // Modalità periodo (solo per nuove eccezioni)
        if (!isEdit) ...[
          LabeledFormField(
            label: l10n.exceptionPeriodMode,
            child: SegmentedButton<_PeriodMode>(
              segments: [
                ButtonSegment(
                  value: _PeriodMode.single,
                  label: Text(l10n.exceptionPeriodSingle),
                ),
                ButtonSegment(
                  value: _PeriodMode.range,
                  label: Text(l10n.exceptionPeriodRange),
                ),
                ButtonSegment(
                  value: _PeriodMode.duration,
                  label: Text(l10n.exceptionPeriodDuration),
                ),
              ],
              selected: {_periodMode},
              onSelectionChanged: (selected) {
                setState(() => _periodMode = selected.first);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Sezione date in base alla modalità
        if (isEdit || _periodMode == _PeriodMode.single) ...[
          // Data singola
          LabeledFormField(
            label: l10n.formDate,
            child: InkWell(
              onTap: () => _pickSingleDate(),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(_date)),
                    const Icon(Icons.calendar_today, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ] else if (_periodMode == _PeriodMode.range) ...[
          // Range date: Da - A
          Row(
            children: [
              Expanded(
                child: LabeledFormField(
                  label: l10n.exceptionDateFrom,
                  child: InkWell(
                    onTap: () => _pickStartDate(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(_startDate)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledFormField(
                  label: l10n.exceptionDateTo,
                  child: InkWell(
                    onTap: () => _pickEndDate(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(_endDate)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Info giorni totali
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.exceptionDurationDays(_calculateDays()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ] else if (_periodMode == _PeriodMode.duration) ...[
          // Durata: Data inizio + numero giorni
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: LabeledFormField(
                  label: l10n.exceptionDateFrom,
                  child: InkWell(
                    onTap: () => _pickStartDate(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(_startDate)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledFormField(
                  label: l10n.exceptionDuration,
                  child: _DurationDropdown(
                    value: _durationDays,
                    onChanged: (v) => setState(() => _durationDays = v),
                  ),
                ),
              ),
            ],
          ),
          // Info data fine calcolata
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '→ ${_formatDate(_startDate.add(Duration(days: _durationDays - 1)))}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Giornata intera switch
        Row(
          children: [
            Switch(
              value: _isAllDay,
              onChanged: (v) => setState(() => _isAllDay = v),
            ),
            const SizedBox(width: 8),
            Text(l10n.exceptionAllDay),
          ],
        ),
        const SizedBox(height: 12),

        // Orari
        if (!_isAllDay) ...[
          Row(
            children: [
              Expanded(
                child: LabeledFormField(
                  label: l10n.exceptionStartTime,
                  child: InkWell(
                    onTap: () => _pickTime(isStart: true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        enabledBorder: _timeError != null
                            ? OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatTime(_startTime)),
                          const Icon(Icons.schedule, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledFormField(
                  label: l10n.exceptionEndTime,
                  child: InkWell(
                    onTap: () => _pickTime(isStart: false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        enabledBorder: _timeError != null
                            ? OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatTime(_endTime)),
                          const Icon(Icons.schedule, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_timeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                _timeError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],

        // Motivo opzionale
        LabeledFormField(
          label: l10n.exceptionReason,
          child: TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: l10n.exceptionReasonHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );

    final actions = [
      if (isEdit)
        AppDangerButton(
          onPressed: _isSaving ? null : _onDelete,
          padding: AppButtonStyles.dialogButtonPadding,
          child: Text(l10n.actionDelete),
        ),
      AppOutlinedActionButton(
        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionCancel),
      ),
      AppFilledButton(
        onPressed: _isSaving ? null : _onSave,
        padding: AppButtonStyles.dialogButtonPadding,
        child: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.actionSave),
      ),
    ];

    final bottomActions = actions
        .map(
          (a) => SizedBox(width: AppButtonStyles.dialogButtonWidth, child: a),
        )
        .toList();

    if (isDialog) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 500, maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Flexible(child: SingleChildScrollView(child: content)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isEdit) ...[
                      bottomActions.first,
                      const Spacer(),
                      bottomActions[1],
                    ] else
                      bottomActions[0],
                    const SizedBox(width: 8),
                    bottomActions.last,
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            content,
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: bottomActions,
              ),
            ),
            SizedBox(height: 32 + MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int _calculateDays() {
    return _endDate.difference(_startDate).inDays + 1;
  }

  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateUtils.dateOnly(picked);
        // Se la data di fine è prima della data di inizio, aggiornala
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(Duration(days: _durationDays - 1));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _endDate = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final step = ref.read(layoutConfigProvider).minutesPerSlot;
    final selected = await AppBottomSheet.show<TimeOfDay>(
      context: context,
      useRootNavigator: true,
      padding: EdgeInsets.zero,
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.7;
        return SizedBox(
          height: height,
          child: _TimeGridPicker(
            initial: isStart ? _startTime : _endTime,
            stepMinutes: step,
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        _timeError = null;
        if (isStart) {
          _startTime = selected;
          // Se l'orario di fine è prima dell'inizio, aggiustalo
          final startMinutes = _startTime.hour * 60 + _startTime.minute;
          final endMinutes = _endTime.hour * 60 + _endTime.minute;
          if (endMinutes <= startMinutes) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1).clamp(0, 23),
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = selected;
        }
      });
    }
  }

  bool _validate() {
    final l10n = context.l10n;

    if (!_isAllDay) {
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = _endTime.hour * 60 + _endTime.minute;
      if (endMinutes <= startMinutes) {
        setState(() => _timeError = l10n.exceptionTimeError);
        return false;
      }
    }

    return true;
  }

  Future<void> _onSave() async {
    if (!_validate()) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(availabilityExceptionsProvider.notifier);
      final reason = _reasonController.text.trim();

      if (widget.initial != null) {
        // Modifica eccezione esistente (solo singolo giorno)
        final updated = widget.initial!.copyWith(
          date: _date,
          startTime: _isAllDay ? null : _startTime,
          endTime: _isAllDay ? null : _endTime,
          type: _type,
          reason: reason.isEmpty ? null : reason,
          clearStartTime: _isAllDay,
          clearEndTime: _isAllDay,
          clearReason: reason.isEmpty,
        );
        await notifier.updateException(updated);
      } else {
        // Nuova eccezione - gestisci in base alla modalità
        if (_periodMode == _PeriodMode.single) {
          // Singolo giorno
          await notifier.addException(
            staffId: widget.staffId,
            date: _date,
            startTime: _isAllDay ? null : _startTime,
            endTime: _isAllDay ? null : _endTime,
            type: _type,
            reason: reason.isEmpty ? null : reason,
          );
        } else {
          // Periodo (range o durata) - calcola le date
          final DateTime startDate;
          final DateTime endDate;

          if (_periodMode == _PeriodMode.range) {
            startDate = _startDate;
            endDate = _endDate;
          } else {
            // duration mode
            startDate = _startDate;
            endDate = _startDate.add(Duration(days: _durationDays - 1));
          }

          await notifier.addExceptionsForPeriod(
            staffId: widget.staffId,
            startDate: startDate,
            endDate: endDate,
            startTime: _isAllDay ? null : _startTime,
            endTime: _isAllDay ? null : _endTime,
            type: _type,
            reason: reason.isEmpty ? null : reason,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _onDelete() async {
    if (widget.initial == null) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exceptionDeleteTitle),
        content: Text(l10n.exceptionDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(availabilityExceptionsProvider.notifier)
          .deleteException(widget.staffId, widget.initial!.id);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

/// Semplice picker griglia per selezionare un orario.
class _TimeGridPicker extends StatefulWidget {
  const _TimeGridPicker({required this.initial, required this.stepMinutes});

  final TimeOfDay initial;
  final int stepMinutes;

  @override
  State<_TimeGridPicker> createState() => _TimeGridPickerState();
}

class _TimeGridPickerState extends State<_TimeGridPicker> {
  late TimeOfDay _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Genera tutte le opzioni di orario
    final times = <TimeOfDay>[];
    for (int h = 0; h < 24; h++) {
      for (int m = 0; m < 60; m += widget.stepMinutes) {
        times.add(TimeOfDay(hour: h, minute: m));
      }
    }
    // Aggiungi 24:00 come opzione finale
    times.add(const TimeOfDay(hour: 24, minute: 0));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.exceptionSelectTime,
                style: theme.textTheme.titleMedium,
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text(context.l10n.actionConfirm),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: times.length,
            itemBuilder: (context, index) {
              final time = times[index];
              final isSelected =
                  time.hour == _selected.hour &&
                  time.minute == _selected.minute;
              final label = time.hour == 24
                  ? '24:00'
                  : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

              return Material(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => setState(() => _selected = time),
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget dropdown per selezionare la durata in giorni.
class _DurationDropdown extends StatelessWidget {
  const _DurationDropdown({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const List<int> _options = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    10,
    14,
    21,
    30,
    60,
    90,
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: _options.contains(value) ? value : 7,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: _options.map((days) {
        return DropdownMenuItem(value: days, child: Text('$days'));
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
