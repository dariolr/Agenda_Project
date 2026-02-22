import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/app/theme/app_spacing.dart';
import 'package:agenda_backend/core/widgets/app_bottom_sheet.dart';
import 'package:agenda_backend/core/widgets/labeled_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/availability_exception.dart';
import '../../../../core/models/staff_planning.dart' show StaffPlanning;
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_dividers.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../../../core/widgets/local_loading_overlay.dart';
import '../../../../core/services/staff_planning_selector.dart' show PlanningFound;
import '../../providers/availability_exceptions_provider.dart';
import '../../providers/staff_planning_provider.dart';
import '../../providers/staff_weekly_availability_provider.dart';

/// Mostra il dialog per creare o modificare un'eccezione alla disponibilità.
Future<void> showAddExceptionDialog(
  BuildContext context,
  WidgetRef ref, {
  AvailabilityException? initial,
  DateTime? date,
  TimeOfDay? time,
  required int staffId,
}) async {
  // Le eccezioni devono usare sempre lo stesso passo del planning staff.
  // Se il planning non è disponibile, non apriamo il dialog.
  var plannings = ref.read(planningsForStaffProvider(staffId));
  if (plannings.isEmpty) {
    await ref.read(staffPlanningsProvider.notifier).loadPlanningsForStaff(staffId);
    if (!context.mounted) return;
    plannings = ref.read(planningsForStaffProvider(staffId));
  }
  if (plannings.isEmpty) {
    await FeedbackDialog.showError(
      context,
      title: context.l10n.planningListTitle,
      message: context.l10n.planningListEmpty,
    );
    return;
  }

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
  String? _timeError;
  String? _validationError;
  bool _isSaving = false;
  Map<DateTime, String> _lastSkippedReasons = {};

  @override
  void initState() {
    super.initState();

    if (widget.initial != null) {
      final exc = widget.initial!;
      _date = DateTime(exc.date.year, exc.date.month, exc.date.day);
      _startDate = _date;
      _endDate = _date;
      if (exc.isAllDay) {
        _startTime = const TimeOfDay(hour: 0, minute: 0);
        _endTime = const TimeOfDay(hour: 24, minute: 0);
      } else {
        _startTime = exc.startTime ?? const TimeOfDay(hour: 9, minute: 0);
        _endTime = exc.endTime ?? const TimeOfDay(hour: 18, minute: 0);
      }
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
              setState(() {
                _type = selected.first;
                _validationError = null;
              });
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
                setState(() {
                  _periodMode = selected.first;
                  _validationError = null;
                });
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
                    onChanged: (v) => setState(() {
                      _durationDays = v;
                      _validationError = null;
                    }),
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

        // Orari
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
        if (_validationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              _validationError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 12),

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
        child: Text(l10n.actionSave),
      ),
    ];

    final bottomActions = actions
        .map(
          (a) => SizedBox(width: AppButtonStyles.dialogButtonWidth, child: a),
        )
        .toList();

    if (isDialog) {
      return DismissibleDialog(
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 500, maxWidth: 600),
            child: LocalLoadingOverlay(
              isLoading: _isSaving,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
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
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
          return LocalLoadingOverlay(
            isLoading: _isSaving,
            child: SizedBox(
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          content,
                          const SizedBox(height: 24),
                          const SizedBox(height: AppSpacing.formRowSpacing),
                        ],
                      ),
                    ),
                  ),
                  if (!isKeyboardOpen) ...[
                    const AppDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                      child: Align(
                        alignment: bottomActions.length == 3
                            ? Alignment.center
                            : Alignment.centerRight,
                        child: Wrap(
                          alignment: bottomActions.length == 3
                              ? WrapAlignment.center
                              : WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: bottomActions,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
                ],
              ),
            ),
          );
        },
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

  int _planningSlotMinutesForDate(DateTime date) {
    final allPlannings = ref.read(planningsForStaffProvider(widget.staffId));
    if (allPlannings.isEmpty) {
      return StaffPlanning.defaultPlanningSlotMinutes;
    }
    final selector = ref.read(staffPlanningSelectorProvider);
    final lookup = selector.findPlanningForDate(
      staffId: widget.staffId,
      date: date,
      allPlannings: allPlannings,
    );
    if (lookup is PlanningFound) {
      final minutes = lookup.planning.planningSlotMinutes;
      return minutes > 0 ? minutes : StaffPlanning.defaultPlanningSlotMinutes;
    }
    return StaffPlanning.defaultPlanningSlotMinutes;
  }

  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _date = DateUtils.dateOnly(picked);
        _validationError = null;
      });
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
        _validationError = null;
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
      setState(() {
        _endDate = DateUtils.dateOnly(picked);
        _validationError = null;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final referenceDate = widget.initial != null || _periodMode == _PeriodMode.single
        ? _date
        : _startDate;
    final step = _planningSlotMinutesForDate(referenceDate);
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
        _validationError = null;
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

  List<DateTime>? _validatedDates() {
    final l10n = context.l10n;
    setState(() {
      _validationError = null;
      _timeError = null;
    });

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      setState(() => _timeError = l10n.exceptionTimeError);
      return null;
    }

    final availabilityByStaff = ref
        .read(staffAvailabilityByStaffProvider)
        .value;
    if (availabilityByStaff == null) {
      if (widget.initial != null || _periodMode == _PeriodMode.single) {
        return <DateTime>[_date];
      }
      final DateTime startDate;
      final DateTime endDate;
      if (_periodMode == _PeriodMode.range) {
        startDate = _startDate;
        endDate = _endDate;
      } else {
        startDate = _startDate;
        endDate = _startDate.add(Duration(days: _durationDays - 1));
      }
      final dates = <DateTime>[];
      for (
        var d = startDate;
        !d.isAfter(endDate);
        d = d.add(const Duration(days: 1))
      ) {
        dates.add(d);
      }
      return dates;
    }

    Set<int> exceptionSlots(int minutesPerSlot) {
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = _endTime.hour * 60 + _endTime.minute;
      final startSlot = startMinutes ~/ minutesPerSlot;
      final endSlot = endMinutes ~/ minutesPerSlot;
      return {for (int i = startSlot; i < endSlot; i++) i};
    }

    String? validateDate(DateTime date) {
      final minutesPerSlot = _planningSlotMinutesForDate(date);
      final baseSlots =
          availabilityByStaff[widget.staffId]?[date.weekday] ?? <int>{};
      final excSlots = exceptionSlots(minutesPerSlot);
      if (_type == AvailabilityExceptionType.unavailable) {
        if (baseSlots.isEmpty) {
          return l10n.exceptionUnavailableNoBase;
        }
        if (baseSlots.intersection(excSlots).isEmpty) {
          return l10n.exceptionUnavailableNoOverlap;
        }
      } else {
        if (excSlots.difference(baseSlots).isEmpty) {
          return l10n.exceptionAvailableNoEffect;
        }
      }
      return null;
    }

    if (widget.initial != null || _periodMode == _PeriodMode.single) {
      final error = validateDate(_date);
      if (error != null) {
        setState(() => _validationError = error);
        return null;
      }
      return <DateTime>[_date];
    }

    final DateTime startDate;
    final DateTime endDate;
    if (_periodMode == _PeriodMode.range) {
      startDate = _startDate;
      endDate = _endDate;
    } else {
      startDate = _startDate;
      endDate = _startDate.add(Duration(days: _durationDays - 1));
    }

    final validDates = <DateTime>[];
    final skippedReasons = <DateTime, String>{};
    String? firstError;
    for (
      var d = startDate;
      !d.isAfter(endDate);
      d = d.add(const Duration(days: 1))
    ) {
      final error = validateDate(d);
      if (error == null) {
        validDates.add(d);
      } else {
        firstError ??= error;
        skippedReasons[d] = error;
      }
    }

    if (validDates.isEmpty) {
      setState(() => _validationError = firstError);
      return null;
    }

    _lastSkippedReasons = {
      for (final entry in skippedReasons.entries)
        DateUtils.dateOnly(entry.key): entry.value,
    };
    return validDates;
  }

  Future<void> _onSave() async {
    final validDates = _validatedDates();
    if (validDates == null || validDates.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(availabilityExceptionsProvider.notifier);
      final reason = _reasonController.text.trim();

      if (widget.initial != null) {
        // Modifica eccezione esistente (solo singolo giorno)
        final updated = widget.initial!.copyWith(
          date: validDates.first,
          startTime: _startTime,
          endTime: _endTime,
          type: _type,
          reason: reason.isEmpty ? null : reason,
          clearReason: reason.isEmpty,
        );
        await notifier.updateException(updated);
      } else {
        // Nuova eccezione - gestisci in base alla modalità
        if (_periodMode == _PeriodMode.single) {
          // Singolo giorno
          await notifier.addException(
            staffId: widget.staffId,
            date: validDates.first,
            startTime: _startTime,
            endTime: _endTime,
            type: _type,
            reason: reason.isEmpty ? null : reason,
          );
        } else {
          // Periodo (range o durata) - salva solo le date congruenti
          final DateTime startDate;
          final DateTime endDate;
          if (_periodMode == _PeriodMode.range) {
            startDate = _startDate;
            endDate = _endDate;
          } else {
            startDate = _startDate;
            endDate = _startDate.add(Duration(days: _durationDays - 1));
          }
          var totalDays = 0;
          final skippedDates = <DateTime>[];
          final skippedDetails = <String>[];
          for (
            var d = startDate;
            !d.isAfter(endDate);
            d = d.add(const Duration(days: 1))
          ) {
            totalDays++;
          }
          for (final d in validDates) {
            await notifier.addException(
              staffId: widget.staffId,
              date: d,
              startTime: _startTime,
              endTime: _endTime,
              type: _type,
              reason: reason.isEmpty ? null : reason,
            );
          }
          if (validDates.length < totalDays) {
            for (
              var d = startDate;
              !d.isAfter(endDate);
              d = d.add(const Duration(days: 1))
            ) {
              final isValid = validDates.any((v) => DateUtils.isSameDay(v, d));
              if (!isValid) {
                skippedDates.add(d);
              }
            }
          }
          if (mounted && skippedDates.isNotEmpty) {
            final locale = Localizations.localeOf(context).toLanguageTag();
            final formatter = DateFormat('d MMM', locale);
            for (final d in skippedDates) {
              final reason = _lastSkippedReasons[DateUtils.dateOnly(d)] ?? '';
              final dateLabel = formatter.format(d);
              if (reason.isEmpty) {
                skippedDetails.add(dateLabel);
              } else {
                skippedDetails.add('$dateLabel — $reason');
              }
            }
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(ctx.l10n.exceptionPartialSaveTitle),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ctx.l10n.exceptionPartialSaveMessage),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: skippedDetails.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) => Text(
                            '• ${skippedDetails[index]}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(ctx.l10n.actionConfirm),
                  ),
                ],
              ),
            );
          }
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
  late final ScrollController _scrollController;
  late final List<TimeOfDay?> _times;
  late final int _scrollToIndex;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _scrollController = ScrollController();

    // Genera tutte le opzioni di orario con 4 colonne per riga
    _times = <TimeOfDay?>[];
    for (int h = 0; h < 24; h++) {
      for (int m = 0; m < 60; m += widget.stepMinutes) {
        _times.add(TimeOfDay(hour: h, minute: m));
      }
    }
    // Aggiungi 24:00 come opzione finale
    _times.add(const TimeOfDay(hour: 24, minute: 0));

    // Verifica se l'orario iniziale è già nella lista
    int exactIndex = _times.indexWhere(
      (t) =>
          t != null &&
          t.hour == widget.initial.hour &&
          t.minute == widget.initial.minute,
    );

    if (exactIndex >= 0) {
      // L'orario è già presente
      _scrollToIndex = exactIndex;
    } else {
      // L'orario non è presente: inserisci una NUOVA RIGA con l'orario
      // nella colonna corretta e le altre colonne vuote
      final columnsPerRow = 60 ~/ widget.stepMinutes;
      final targetColumn = widget.initial.minute ~/ widget.stepMinutes;
      final baseIndex = (widget.initial.hour + 1) * columnsPerRow;

      // Crea la nuova riga con 4 elementi (solo uno valorizzato)
      final newRow = List<TimeOfDay?>.filled(columnsPerRow, null);
      newRow[targetColumn] = widget.initial;

      // Inserisci la nuova riga
      final insertIndex = baseIndex.clamp(0, _times.length);
      _times.insertAll(insertIndex, newRow);

      // L'indice dell'orario selezionato è la posizione nella nuova riga
      _scrollToIndex = insertIndex + targetColumn;
    }

    // Scroll all'orario dopo il primo frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;

    const crossAxisCount = 4;
    const mainAxisSpacing = 8.0;
    const childAspectRatio = 2.5;
    const padding = 8.0;

    // Usa la larghezza effettiva del context
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - padding * 2;
    final itemWidth =
        (availableWidth - (crossAxisCount - 1) * 8) / crossAxisCount;
    final itemHeight = itemWidth / childAspectRatio;
    final rowHeight = itemHeight + mainAxisSpacing;

    final targetRow = _scrollToIndex ~/ crossAxisCount;

    final viewportHeight = _scrollController.position.viewportDimension;
    // Offset aggiuntivo per centrare meglio (compensa header visivo)
    const headerOffset = 40.0;
    final targetOffset =
        (targetRow * rowHeight) -
        (viewportHeight / 2) +
        (rowHeight / 2) +
        headerOffset;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              const SizedBox.shrink(),
            ],
          ),
        ),
        const AppDivider(),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _times.length,
            itemBuilder: (context, index) {
              final time = _times[index];
              // Se la cella è vuota, mostra uno spazio vuoto
              if (time == null) {
                return const SizedBox.shrink();
              }
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
                  onTap: () => Navigator.of(context).pop(time),
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
