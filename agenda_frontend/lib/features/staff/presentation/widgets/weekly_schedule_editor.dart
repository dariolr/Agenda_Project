import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/theme/extensions.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/features/agenda/domain/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rappresenta un singolo turno di lavoro (orario inizio - orario fine).
class WorkShift {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const WorkShift({required this.startTime, required this.endTime});

  WorkShift copyWith({TimeOfDay? startTime, TimeOfDay? endTime}) {
    return WorkShift(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// Durata in minuti del turno.
  int get durationMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }

  /// Durata in ore (arrotondata).
  double get durationHours => durationMinutes / 60.0;
}

/// Rappresenta la disponibilità di un singolo giorno.
class DaySchedule {
  final bool isEnabled;
  final List<WorkShift> shifts;

  const DaySchedule({this.isEnabled = false, this.shifts = const []});

  DaySchedule copyWith({bool? isEnabled, List<WorkShift>? shifts}) {
    return DaySchedule(
      isEnabled: isEnabled ?? this.isEnabled,
      shifts: shifts ?? this.shifts,
    );
  }

  /// Totale ore lavorate nel giorno.
  int get totalHours {
    if (!isEnabled || shifts.isEmpty) return 0;
    final totalMinutes = shifts.fold<int>(
      0,
      (sum, shift) => sum + shift.durationMinutes,
    );
    return (totalMinutes / 60).round();
  }
}

/// Rappresenta la pianificazione settimanale completa.
class WeeklySchedule {
  /// Mappa giorno (1=lunedì, 7=domenica) -> DaySchedule
  final Map<int, DaySchedule> days;

  const WeeklySchedule({required this.days});

  factory WeeklySchedule.empty() {
    return WeeklySchedule(
      days: {for (int i = 1; i <= 7; i++) i: const DaySchedule()},
    );
  }

  /// Crea una pianificazione con valori di default (lun-sab 09:00-18:00).
  factory WeeklySchedule.defaultSchedule() {
    return WeeklySchedule(
      days: {
        for (int i = 1; i <= 6; i++)
          i: DaySchedule(
            isEnabled: true,
            shifts: [
              const WorkShift(
                startTime: TimeOfDay(hour: 9, minute: 0),
                endTime: TimeOfDay(hour: 18, minute: 0),
              ),
            ],
          ),
        7: const DaySchedule(isEnabled: false, shifts: []),
      },
    );
  }

  WeeklySchedule copyWith({Map<int, DaySchedule>? days}) {
    return WeeklySchedule(days: days ?? this.days);
  }

  /// Totale ore settimanali.
  int get totalHours {
    return days.values.fold<int>(0, (sum, day) => sum + day.totalHours);
  }

  /// Unifica le fasce orarie contigue (dove la fine di una coincide con l'inizio della successiva).
  /// Ritorna una nuova WeeklySchedule con le fasce unificate.
  WeeklySchedule mergeContiguousShifts() {
    final Map<int, DaySchedule> mergedDays = {};

    for (final entry in days.entries) {
      final day = entry.key;
      final schedule = entry.value;

      if (!schedule.isEnabled || schedule.shifts.length <= 1) {
        // Nessuna unificazione necessaria
        mergedDays[day] = schedule;
        continue;
      }

      // Ordina le fasce per orario di inizio
      final sortedShifts = List<WorkShift>.from(schedule.shifts)
        ..sort((a, b) {
          final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
          final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
          return aMinutes.compareTo(bMinutes);
        });

      // Unifica fasce contigue
      final List<WorkShift> mergedShifts = [];
      WorkShift? current;

      for (final shift in sortedShifts) {
        if (current == null) {
          current = shift;
        } else {
          // Controlla se la fine di current coincide con l'inizio di shift
          final currentEndMinutes =
              current.endTime.hour * 60 + current.endTime.minute;
          final shiftStartMinutes =
              shift.startTime.hour * 60 + shift.startTime.minute;

          if (currentEndMinutes == shiftStartMinutes) {
            // Fasce contigue: unisci
            current = WorkShift(
              startTime: current.startTime,
              endTime: shift.endTime,
            );
          } else {
            // Non contigue: salva current e inizia nuovo
            mergedShifts.add(current);
            current = shift;
          }
        }
      }

      // Aggiungi l'ultima fascia
      if (current != null) {
        mergedShifts.add(current);
      }

      mergedDays[day] = DaySchedule(
        isEnabled: schedule.isEnabled,
        shifts: mergedShifts,
      );
    }

    return WeeklySchedule(days: mergedDays);
  }

  /// Converte da formato slot a WeeklySchedule.
  /// [minutesPerSlot] è tipicamente 15.
  factory WeeklySchedule.fromSlots(
    Map<int, Set<int>> slots, {
    int minutesPerSlot = 15,
  }) {
    final Map<int, DaySchedule> days = {};

    for (int day = 1; day <= 7; day++) {
      final daySlots = slots[day] ?? <int>{};
      if (daySlots.isEmpty) {
        days[day] = const DaySchedule(isEnabled: false, shifts: []);
        continue;
      }

      // Ordina e raggruppa slot consecutivi in turni
      final sortedSlots = daySlots.toList()..sort();
      final List<WorkShift> shifts = [];

      int? rangeStart;
      int? rangePrev;

      for (final slot in sortedSlots) {
        if (rangeStart == null) {
          rangeStart = slot;
          rangePrev = slot;
        } else if (slot == rangePrev! + 1) {
          // Slot consecutivo
          rangePrev = slot;
        } else {
          // Gap trovato, chiudi range precedente
          shifts.add(_slotsToShift(rangeStart, rangePrev, minutesPerSlot));
          rangeStart = slot;
          rangePrev = slot;
        }
      }

      // Aggiungi ultimo range
      if (rangeStart != null && rangePrev != null) {
        shifts.add(_slotsToShift(rangeStart, rangePrev, minutesPerSlot));
      }

      days[day] = DaySchedule(isEnabled: shifts.isNotEmpty, shifts: shifts);
    }

    return WeeklySchedule(days: days);
  }

  static WorkShift _slotsToShift(
    int startSlot,
    int endSlot,
    int minutesPerSlot,
  ) {
    final startMinutes = startSlot * minutesPerSlot;
    final endMinutes =
        (endSlot + 1) * minutesPerSlot; // +1 perché endSlot è incluso
    return WorkShift(
      startTime: TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60),
      endTime: TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60),
    );
  }

  /// Converte WeeklySchedule a formato slot.
  Map<int, Set<int>> toSlots({int minutesPerSlot = 15}) {
    final Map<int, Set<int>> result = {};

    for (final entry in days.entries) {
      final day = entry.key;
      final schedule = entry.value;

      if (!schedule.isEnabled || schedule.shifts.isEmpty) {
        result[day] = <int>{};
        continue;
      }

      final Set<int> daySlots = {};
      for (final shift in schedule.shifts) {
        final startMinutes = shift.startTime.hour * 60 + shift.startTime.minute;
        final endMinutes = shift.endTime.hour * 60 + shift.endTime.minute;

        // Converti range di minuti a slot
        for (int m = startMinutes; m < endMinutes; m += minutesPerSlot) {
          daySlots.add(m ~/ minutesPerSlot);
        }
      }
      result[day] = daySlots;
    }

    return result;
  }
}

/// Widget per la modifica della pianificazione settimanale.
class WeeklyScheduleEditor extends StatefulWidget {
  final WeeklySchedule initialSchedule;
  final ValueChanged<WeeklySchedule>? onChanged;
  final bool showHeader;

  const WeeklyScheduleEditor({
    super.key,
    required this.initialSchedule,
    this.onChanged,
    this.showHeader = true,
  });

  @override
  State<WeeklyScheduleEditor> createState() => _WeeklyScheduleEditorState();
}

class _WeeklyScheduleEditorState extends State<WeeklyScheduleEditor> {
  late WeeklySchedule _schedule;

  @override
  void initState() {
    super.initState();
    _schedule = widget.initialSchedule;
  }

  @override
  void didUpdateWidget(WeeklyScheduleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSchedule != oldWidget.initialSchedule) {
      _schedule = widget.initialSchedule;
    }
  }

  void _updateSchedule(WeeklySchedule newSchedule) {
    setState(() => _schedule = newSchedule);
    widget.onChanged?.call(newSchedule);
  }

  void _toggleDay(int day) {
    final currentDay = _schedule.days[day]!;
    final newDay = currentDay.copyWith(
      isEnabled: !currentDay.isEnabled,
      shifts: !currentDay.isEnabled && currentDay.shifts.isEmpty
          ? [
              const WorkShift(
                startTime: TimeOfDay(hour: 9, minute: 0),
                endTime: TimeOfDay(hour: 18, minute: 0),
              ),
            ]
          : currentDay.shifts,
    );
    _updateSchedule(_schedule.copyWith(days: {..._schedule.days, day: newDay}));
  }

  void _updateShift(int day, int shiftIndex, WorkShift newShift) {
    final currentDay = _schedule.days[day]!;
    final newShifts = List<WorkShift>.from(currentDay.shifts);
    newShifts[shiftIndex] = newShift;
    _updateSchedule(
      _schedule.copyWith(
        days: {
          ..._schedule.days,
          day: currentDay.copyWith(shifts: newShifts),
        },
      ),
    );
  }

  void _addShift(int day) {
    final currentDay = _schedule.days[day]!;
    final lastShift = currentDay.shifts.isNotEmpty
        ? currentDay.shifts.last
        : null;
    final newStartHour = lastShift != null ? lastShift.endTime.hour + 1 : 9;
    final newShift = WorkShift(
      startTime: TimeOfDay(hour: newStartHour.clamp(0, 22), minute: 0),
      endTime: TimeOfDay(hour: (newStartHour + 1).clamp(1, 23), minute: 0),
    );
    _updateSchedule(
      _schedule.copyWith(
        days: {
          ..._schedule.days,
          day: currentDay.copyWith(shifts: [...currentDay.shifts, newShift]),
        },
      ),
    );
  }

  void _removeShift(int day, int shiftIndex) {
    final currentDay = _schedule.days[day]!;
    final newShifts = List<WorkShift>.from(currentDay.shifts)
      ..removeAt(shiftIndex);
    // Se non ci sono più turni, disabilita il giorno
    final isEnabled = newShifts.isNotEmpty;
    _updateSchedule(
      _schedule.copyWith(
        days: {
          ..._schedule.days,
          day: currentDay.copyWith(shifts: newShifts, isEnabled: isEnabled),
        },
      ),
    );
  }

  List<String> _getDayNames(BuildContext context) {
    final l10n = context.l10n;
    return [
      l10n.dayMondayFull,
      l10n.dayTuesdayFull,
      l10n.dayWednesdayFull,
      l10n.dayThursdayFull,
      l10n.dayFridayFull,
      l10n.daySaturdayFull,
      l10n.daySundayFull,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dayNames = _getDayNames(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header con titolo e ore totali (opzionale)
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.weeklyScheduleTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.weeklyScheduleTotalHours(_schedule.totalHours),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

        // Lista dei giorni - sfondo a tutta larghezza, contenuto centrato
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(7, (index) {
            final day = index + 1;
            final daySchedule = _schedule.days[day]!;
            final dayName = dayNames[index];

            return _DayRow(
              day: day,
              dayName: dayName,
              allDayNames: dayNames,
              schedule: daySchedule,
              onToggle: () => _toggleDay(day),
              onShiftChanged: (shiftIndex, shift) =>
                  _updateShift(day, shiftIndex, shift),
              onAddShift: () => _addShift(day),
              onRemoveShift: (shiftIndex) => _removeShift(day, shiftIndex),
              isFirst: index == 0,
            );
          }),
        ),
      ],
    );
  }
}

/// Riga per un singolo giorno.
class _DayRow extends ConsumerWidget {
  final int day;
  final String dayName;
  final List<String> allDayNames;
  final DaySchedule schedule;
  final VoidCallback onToggle;
  final void Function(int shiftIndex, WorkShift shift) onShiftChanged;
  final VoidCallback onAddShift;
  final void Function(int shiftIndex) onRemoveShift;
  final bool isFirst;

  const _DayRow({
    required this.day,
    required this.dayName,
    required this.allDayNames,
    required this.schedule,
    required this.onToggle,
    required this.onShiftChanged,
    required this.onAddShift,
    required this.onRemoveShift,
    this.isFirst = false,
  });

  /// Calcola la larghezza massima tra tutti i nomi dei giorni
  double _getMaxDayNameWidth(BuildContext context, TextStyle? style) {
    double maxWidth = 0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final name in allDayNames) {
      textPainter.text = TextSpan(text: name, style: style);
      textPainter.layout();
      if (textPainter.width > maxWidth) {
        maxWidth = textPainter.width;
      }
    }
    return maxWidth;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formFactor = ref.watch(formFactorProvider);
    final isMobile = formFactor == AppFormFactor.mobile;

    if (isMobile) {
      return _buildMobileLayout(context, l10n, theme);
    }
    return _buildDesktopLayout(context, l10n, theme);
  }

  /// Layout mobile: verticale (header sopra, turni sotto)
  Widget _buildMobileLayout(
    BuildContext context,
    dynamic l10n,
    ThemeData theme,
  ) {
    // Sfondo alternato: trasparente per dispari, colorato per pari
    final interactionColors = theme.extension<AppInteractionColors>();
    final backgroundColor = day.isEven
        ? interactionColors?.alternatingRowFill
        : null;

    final dayNameStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
    );
    final maxDayNameWidth = _getMaxDayNameWidth(context, dayNameStyle);

    return Container(
      color: backgroundColor,
      padding: EdgeInsets.only(top: isFirst ? 16 : 8, bottom: 8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: checkbox + nome giorno + ore + icone
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Checkbox inline con il nome
                    Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: schedule.isEnabled,
                        onChanged: (_) => onToggle(),
                        activeColor: theme.colorScheme.primary,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),

                    // Nome giorno con larghezza fissa (calcolata dinamicamente)
                    SizedBox(
                      width: maxDayNameWidth,
                      child: Text(dayName, style: dayNameStyle),
                    ),
                    if (schedule.isEnabled && schedule.totalHours > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${schedule.totalHours}h',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    // Icone azioni (solo se abilitato)
                    if (schedule.isEnabled) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onAddShift,
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: theme.colorScheme.primary,
                        ),
                        tooltip: l10n.weeklyScheduleAddShift,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                        iconSize: 22,
                      ),
                    ],
                  ],
                ),

                // Contenuto turni o "Non lavora"
                if (schedule.isEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        for (int i = 0; i < schedule.shifts.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i < schedule.shifts.length - 1 ? 8 : 0,
                            ),
                            child: _ShiftRowMobile(
                              shift: schedule.shifts[i],
                              onChanged: (shift) => onShiftChanged(i, shift),
                              onRemove: () => onRemoveShift(i),
                              previousShiftEndTime: i > 0
                                  ? schedule.shifts[i - 1].endTime
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.weeklyScheduleNotWorking,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Layout desktop/tablet: orizzontale
  Widget _buildDesktopLayout(
    BuildContext context,
    dynamic l10n,
    ThemeData theme,
  ) {
    // Sfondo alternato: trasparente per dispari, colorato per pari
    final interactionColors = theme.extension<AppInteractionColors>();
    final backgroundColor = day.isEven
        ? interactionColors?.alternatingRowFill
        : null;

    final dayNameStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
    );
    final maxDayNameWidth = _getMaxDayNameWidth(context, dayNameStyle);

    return Container(
      color: backgroundColor,
      padding: EdgeInsets.only(top: isFirst ? 16 : 8, bottom: 8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicWidth(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox
                Checkbox(
                  value: schedule.isEnabled,
                  onChanged: (_) => onToggle(),
                  activeColor: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),

                // Nome giorno e ore con larghezza fissa (calcolata dinamicamente)
                SizedBox(
                  width: maxDayNameWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(dayName, style: dayNameStyle),
                      if (schedule.isEnabled && schedule.totalHours > 0)
                        Text(
                          '${schedule.totalHours}h',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Contenuto turni o "Non lavora" - larghezza minima fissa per allineamento
                // Larghezza: 2 dropdown (100*2) + 3 spacing (12*3) + testo "per" (~30) + 2 pulsanti (40*2)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth:
                        _TimeDropdown.dropdownWidth * 2 + 12 * 3 + 30 + 40 * 2,
                  ),
                  child: schedule.isEnabled
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < schedule.shifts.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: i < schedule.shifts.length - 1
                                      ? 8
                                      : 0,
                                ),
                                child: _ShiftRow(
                                  shift: schedule.shifts[i],
                                  onChanged: (shift) =>
                                      onShiftChanged(i, shift),
                                  onAdd: onAddShift,
                                  onRemove: () => onRemoveShift(i),
                                  showAddButton:
                                      i == schedule.shifts.length - 1,
                                  previousShiftEndTime: i > 0
                                      ? schedule.shifts[i - 1].endTime
                                      : null,
                                ),
                              ),
                          ],
                        )
                      : Text(
                          l10n.weeklyScheduleNotWorking,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Riga turno per layout mobile (senza icona add, con delete)
class _ShiftRowMobile extends StatelessWidget {
  final WorkShift shift;
  final ValueChanged<WorkShift> onChanged;
  final VoidCallback onRemove;

  /// Orario di fine della fascia precedente (se esiste).
  /// Usato per impostare il minimo dell'orario di inizio.
  final TimeOfDay? previousShiftEndTime;

  const _ShiftRowMobile({
    required this.shift,
    required this.onChanged,
    required this.onRemove,
    this.previousShiftEndTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Orario inizio - minimo = fine fascia precedente (se esiste)
        _TimeDropdown(
          value: shift.startTime,
          minTime: previousShiftEndTime,
          onChanged: (time) => onChanged(shift.copyWith(startTime: time)),
        ),
        const SizedBox(width: 8),

        // "per"
        Text(
          l10n.weeklyScheduleFor,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),

        // Orario fine - minimo = orario inizio corrente
        _TimeDropdown(
          value: shift.endTime,
          minTime: shift.startTime,
          onChanged: (time) => onChanged(shift.copyWith(endTime: time)),
        ),
        const SizedBox(width: 8),

        // Pulsante rimuovi
        IconButton(
          onPressed: onRemove,
          icon: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          tooltip: l10n.weeklyScheduleRemoveShift,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

/// Riga per un singolo turno con dropdown orari.
class _ShiftRow extends StatelessWidget {
  final WorkShift shift;
  final ValueChanged<WorkShift> onChanged;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool showAddButton;

  /// Orario di fine della fascia precedente (se esiste).
  /// Usato per impostare il minimo dell'orario di inizio.
  final TimeOfDay? previousShiftEndTime;

  const _ShiftRow({
    required this.shift,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
    this.showAddButton = false,
    this.previousShiftEndTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Orario inizio - minimo = fine fascia precedente (se esiste)
        _TimeDropdown(
          value: shift.startTime,
          minTime: previousShiftEndTime,
          onChanged: (time) => onChanged(shift.copyWith(startTime: time)),
        ),
        const SizedBox(width: 12),

        // "per"
        Text(
          l10n.weeklyScheduleFor,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),

        // Orario fine - minimo = orario inizio corrente
        _TimeDropdown(
          value: shift.endTime,
          minTime: shift.startTime,
          onChanged: (time) => onChanged(shift.copyWith(endTime: time)),
        ),
        const SizedBox(width: 12),

        // Pulsante aggiungi (solo sull'ultimo turno)
        if (showAddButton)
          IconButton(
            onPressed: onAdd,
            icon: Icon(
              Icons.add_circle_outline,
              color: theme.colorScheme.primary,
            ),
            tooltip: l10n.weeklyScheduleAddShift,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          )
        else
          const SizedBox(width: 40),

        // Pulsante rimuovi
        IconButton(
          onPressed: onRemove,
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          tooltip: l10n.weeklyScheduleRemoveShift,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

/// Dropdown per la selezione dell'orario.
class _TimeDropdown extends StatelessWidget {
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  /// Orario minimo selezionabile (incluso). Se null, parte da 00:00.
  final TimeOfDay? minTime;

  /// Larghezza del dropdown (formato HH:MM + padding + icona)
  static const double dropdownWidth = 100.0;

  const _TimeDropdown({
    required this.value,
    required this.onChanged,
    this.minTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Genera opzioni con incremento pari a minutesPerSlotConst
    final allOptions = <TimeOfDay>[];
    for (int hour = 0; hour < 24; hour++) {
      for (
        int minute = 0;
        minute < 60;
        minute += LayoutConfig.minutesPerSlotConst
      ) {
        allOptions.add(TimeOfDay(hour: hour, minute: minute));
      }
    }

    // Filtra le opzioni in base a minTime
    final options = allOptions.where((time) {
      final timeMinutes = time.hour * 60 + time.minute;
      if (minTime != null) {
        final minMinutes = minTime!.hour * 60 + minTime!.minute;
        if (timeMinutes < minMinutes) return false;
      }
      return true;
    }).toList();

    // Se non ci sono opzioni valide, usa tutte le opzioni
    final effectiveOptions = options.isEmpty ? allOptions : options;

    return SizedBox(
      width: dropdownWidth,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<TimeOfDay>(
            value: _findClosestOption(value, effectiveOptions),
            isExpanded: true,
            alignment: Alignment.center,
            borderRadius: BorderRadius.circular(8),
            icon: const SizedBox.shrink(),
            items: effectiveOptions.map((time) {
              return DropdownMenuItem(
                value: time,
                alignment: Alignment.center,
                child: Text(_formatTime(time)),
              );
            }).toList(),
            onChanged: (time) {
              if (time != null) onChanged(time);
            },
          ),
        ),
      ),
    );
  }

  TimeOfDay _findClosestOption(TimeOfDay value, List<TimeOfDay> options) {
    // Trova l'opzione più vicina al valore attuale
    TimeOfDay closest = options.first;
    int minDiff = _timeDiff(value, closest).abs();

    for (final option in options) {
      final diff = _timeDiff(value, option).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = option;
      }
    }
    return closest;
  }

  int _timeDiff(TimeOfDay a, TimeOfDay b) {
    return (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
