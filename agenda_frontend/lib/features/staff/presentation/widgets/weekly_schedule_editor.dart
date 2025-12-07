import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
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

  const WeeklyScheduleEditor({
    super.key,
    required this.initialSchedule,
    this.onChanged,
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
      children: [
        // Header con titolo e ore totali
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

        // Lista dei giorni
        ...List.generate(7, (index) {
          final day = index + 1;
          final daySchedule = _schedule.days[day]!;
          final dayName = dayNames[index];

          return _DayRow(
            day: day,
            dayName: dayName,
            schedule: daySchedule,
            onToggle: () => _toggleDay(day),
            onShiftChanged: (shiftIndex, shift) =>
                _updateShift(day, shiftIndex, shift),
            onAddShift: () => _addShift(day),
            onRemoveShift: (shiftIndex) => _removeShift(day, shiftIndex),
          );
        }),
      ],
    );
  }
}

/// Riga per un singolo giorno.
class _DayRow extends ConsumerWidget {
  final int day;
  final String dayName;
  final DaySchedule schedule;
  final VoidCallback onToggle;
  final void Function(int shiftIndex, WorkShift shift) onShiftChanged;
  final VoidCallback onAddShift;
  final void Function(int shiftIndex) onRemoveShift;

  const _DayRow({
    required this.day,
    required this.dayName,
    required this.schedule,
    required this.onToggle,
    required this.onShiftChanged,
    required this.onAddShift,
    required this.onRemoveShift,
  });

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
    // Sfondo alternato per righe pari/dispari
    final backgroundColor = day.isOdd
        ? theme.colorScheme.surfaceContainerLowest
        : theme.colorScheme.surfaceContainerLow;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: checkbox + nome giorno + ore + icone
          Row(
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

              // Nome giorno e ore
              Expanded(
                child: Row(
                  children: [
                    Text(
                      dayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
                  ],
                ),
              ),

              // Icone azioni (solo se abilitato)
              if (schedule.isEnabled)
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
          ),

          // Contenuto turni o "Non lavora" - allineato sotto la checkbox
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
                      ),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Text(
                l10n.weeklyScheduleNotWorking,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Layout desktop/tablet: orizzontale
  Widget _buildDesktopLayout(
    BuildContext context,
    dynamic l10n,
    ThemeData theme,
  ) {
    // Sfondo alternato per righe pari/dispari
    final backgroundColor = day.isOdd
        ? theme.colorScheme.surfaceContainerLowest
        : theme.colorScheme.surfaceContainerLow;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          SizedBox(
            width: 24,
            height: 48,
            child: Checkbox(
              value: schedule.isEnabled,
              onChanged: (_) => onToggle(),
              activeColor: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Nome giorno e ore
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

          // Contenuto turni o "Non lavora"
          Expanded(
            child: schedule.isEnabled
                ? Column(
                    children: [
                      for (int i = 0; i < schedule.shifts.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i < schedule.shifts.length - 1 ? 8 : 0,
                          ),
                          child: _ShiftRow(
                            shift: schedule.shifts[i],
                            onChanged: (shift) => onShiftChanged(i, shift),
                            onAdd: onAddShift,
                            onRemove: () => onRemoveShift(i),
                            showAddButton: i == schedule.shifts.length - 1,
                          ),
                        ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.weeklyScheduleNotWorking,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Riga turno per layout mobile (senza icona add, con delete)
class _ShiftRowMobile extends StatelessWidget {
  final WorkShift shift;
  final ValueChanged<WorkShift> onChanged;
  final VoidCallback onRemove;

  const _ShiftRowMobile({
    required this.shift,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Row(
      children: [
        // Orario inizio
        Expanded(
          child: _TimeDropdown(
            value: shift.startTime,
            onChanged: (time) => onChanged(shift.copyWith(startTime: time)),
          ),
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

        // Orario fine
        Expanded(
          child: _TimeDropdown(
            value: shift.endTime,
            onChanged: (time) => onChanged(shift.copyWith(endTime: time)),
          ),
        ),
        const SizedBox(width: 4),

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

  const _ShiftRow({
    required this.shift,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
    this.showAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Row(
      children: [
        // Orario inizio
        Expanded(
          flex: 3,
          child: _TimeDropdown(
            value: shift.startTime,
            onChanged: (time) => onChanged(shift.copyWith(startTime: time)),
          ),
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

        // Orario fine
        Expanded(
          flex: 3,
          child: _TimeDropdown(
            value: shift.endTime,
            onChanged: (time) => onChanged(shift.copyWith(endTime: time)),
          ),
        ),
        const SizedBox(width: 8),

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

  const _TimeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Genera opzioni ogni 30 minuti
    final options = <TimeOfDay>[];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        options.add(TimeOfDay(hour: hour, minute: minute));
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeOfDay>(
          value: _findClosestOption(value, options),
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(8),
          items: options.map((time) {
            return DropdownMenuItem(
              value: time,
              child: Text(_formatTime(time)),
            );
          }).toList(),
          onChanged: (time) {
            if (time != null) onChanged(time);
          },
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
