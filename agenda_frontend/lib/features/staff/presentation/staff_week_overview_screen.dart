import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/widgets/staff_circle_avatar.dart';
import 'package:agenda_frontend/core/l10n/date_time_formats.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/core/models/availability_exception.dart';
import 'package:agenda_frontend/core/widgets/app_bottom_sheet.dart';
import 'package:agenda_frontend/core/widgets/app_buttons.dart';
import 'package:agenda_frontend/core/widgets/app_dialogs.dart';
import 'package:agenda_frontend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_frontend/features/agenda/domain/config/agenda_theme.dart';
import 'package:agenda_frontend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_frontend/features/staff/presentation/staff_availability_screen.dart';
import 'package:agenda_frontend/features/staff/providers/availability_exceptions_provider.dart';
import 'package:agenda_frontend/features/staff/providers/staff_providers.dart';
import 'package:agenda_frontend/features/staff/widgets/staff_top_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Lightweight range used only for the overview chips
class HourRange {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  const HourRange(
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
  );

  int get minutes =>
      (endHour * 60 + endMinute) - (startHour * 60 + startMinute);
  String label(BuildContext context) =>
      '${DtFmt.hm(context, startHour, startMinute)} - ${DtFmt.hm(context, endHour, endMinute)}';
}

/// Mock provider: staffId -> day(1..7) -> ranges
final weeklyStaffAvailabilityMockProvider =
    Provider<Map<int, Map<int, List<HourRange>>>>((ref) {
      // Simple sample data
      return {
        1: {
          1: const [HourRange(9, 30, 13, 30), HourRange(14, 0, 19, 30)],
          2: const [HourRange(9, 30, 13, 30), HourRange(14, 0, 19, 30)],
          3: const [HourRange(10, 30, 13, 30), HourRange(14, 0, 19, 30)],
          4: const [HourRange(9, 30, 13, 30), HourRange(14, 0, 19, 30)],
          5: const [HourRange(10, 30, 13, 30), HourRange(14, 0, 19, 30)],
          6: const [HourRange(9, 30, 13, 30)],
          7: const [],
        },
      };
    });

/// Real data bridge: maps the editor's weekly availability (per day) to
/// the overview shape, including exceptions for the specific week being displayed.
///
/// La disponibilità finale per ogni giorno è calcolata come:
/// 1. Base: template settimanale (es. Lun-Ven 09:00-18:00)
/// 2. + Eccezioni "available": aggiungono slot disponibili
/// 3. - Eccezioni "unavailable": rimuovono slot disponibili
final weeklyStaffAvailabilityFromEditorProvider =
    Provider<Map<int, Map<int, List<HourRange>>>>((ref) {
      final staffList = ref.watch(staffForStaffSectionProvider);
      final asyncByStaff = ref.watch(staffAvailabilityByStaffProvider);
      final layout = ref.watch(layoutConfigProvider);
      final minutesPerSlot = layout.minutesPerSlot;
      final totalSlots = layout.totalSlots;

      // Ottieni la data corrente dell'agenda per calcolare la settimana mostrata
      final agendaDate = ref.watch(agendaDateProvider);
      final monday = _mondayOfWeek(agendaDate);

      List<HourRange> slotsToHourRanges(Set<int> slots) {
        if (slots.isEmpty) return const [];
        final sorted = slots.toList()..sort();
        final List<List<int>> clusters = [];
        var current = <int>[sorted.first];
        for (int i = 1; i < sorted.length; i++) {
          if (sorted[i] == sorted[i - 1] + 1) {
            current.add(sorted[i]);
          } else {
            clusters.add(current);
            current = <int>[sorted[i]];
          }
        }
        clusters.add(current);

        final List<HourRange> ranges = [];
        for (final c in clusters) {
          final startMin = c.first * minutesPerSlot;
          // La fine è l'inizio dell'ultimo slot + la durata di uno slot
          final endMin = (c.last + 1) * minutesPerSlot;
          final sh = startMin ~/ 60;
          final sm = startMin % 60;
          final eh = endMin ~/ 60;
          final em = endMin % 60;
          ranges.add(HourRange(sh, sm, eh, em));
        }
        return ranges;
      }

      final all = asyncByStaff.value ?? const <int, Map<int, Set<int>>>{};

      // Build per-staff availability with exceptions applied for each specific date
      final Map<int, Map<int, List<HourRange>>> result = {};

      for (final s in staffList) {
        final Map<int, List<HourRange>> staffWeek = {};

        for (int d = 1; d <= 7; d++) {
          // Calcola la data specifica per questo giorno della settimana
          final specificDate = monday.add(Duration(days: d - 1));

          // 1️⃣ BASE: Template settimanale
          Set<int> baseSlots = Set<int>.from(all[s.id]?[d] ?? const <int>{});

          // 2️⃣ ECCEZIONI: Applica modifiche per la data specifica
          final exceptions = ref.watch(
            exceptionsForStaffOnDateProvider((
              staffId: s.id,
              date: specificDate,
            )),
          );

          if (exceptions.isEmpty) {
            staffWeek[d] = slotsToHourRanges(baseSlots);
          } else {
            // Applica le eccezioni in ordine
            Set<int> finalSlots = Set<int>.from(baseSlots);

            for (final exception in exceptions) {
              final exceptionSlots = exception.toSlotIndices(
                minutesPerSlot: minutesPerSlot,
                totalSlotsPerDay: totalSlots,
              );

              if (exception.type == AvailabilityExceptionType.available) {
                // AGGIUNGE disponibilità (es. turno extra)
                finalSlots = finalSlots.union(exceptionSlots);
              } else {
                // RIMUOVE disponibilità (es. ferie, malattia)
                finalSlots = finalSlots.difference(exceptionSlots);
              }
            }

            staffWeek[d] = slotsToHourRanges(finalSlots);
          }
        }

        result[s.id] = staffWeek;
      }

      return result;
    });

/// Provider che fornisce la disponibilità BASE (template settimanale) senza eccezioni.
/// Usato per confrontare con la disponibilità effettiva e identificare i turni modificati.
final weeklyStaffBaseAvailabilityProvider =
    Provider<Map<int, Map<int, List<HourRange>>>>((ref) {
      final staffList = ref.watch(staffForStaffSectionProvider);
      final asyncByStaff = ref.watch(staffAvailabilityByStaffProvider);
      final layout = ref.watch(layoutConfigProvider);
      final minutesPerSlot = layout.minutesPerSlot;

      List<HourRange> slotsToHourRanges(Set<int> slots) {
        if (slots.isEmpty) return const [];
        final sorted = slots.toList()..sort();
        final List<List<int>> clusters = [];
        var current = <int>[sorted.first];
        for (int i = 1; i < sorted.length; i++) {
          if (sorted[i] == sorted[i - 1] + 1) {
            current.add(sorted[i]);
          } else {
            clusters.add(current);
            current = <int>[sorted[i]];
          }
        }
        clusters.add(current);

        final List<HourRange> ranges = [];
        for (final c in clusters) {
          final startMin = c.first * minutesPerSlot;
          final endMin = (c.last + 1) * minutesPerSlot;
          final sh = startMin ~/ 60;
          final sm = startMin % 60;
          final eh = endMin ~/ 60;
          final em = endMin % 60;
          ranges.add(HourRange(sh, sm, eh, em));
        }
        return ranges;
      }

      final all = asyncByStaff.value ?? const <int, Map<int, Set<int>>>{};

      return {
        for (final s in staffList)
          s.id: {
            for (int d = 1; d <= 7; d++)
              d: slotsToHourRanges(all[s.id]?[d] ?? const <int>{}),
          },
      };
    });

/// Provider che traccia quali giorni della settimana hanno eccezioni per ogni staff.
/// Ritorna: `Map<staffId, Set<weekday>>` dove weekday = 1..7
final weeklyExceptionDaysProvider = Provider<Map<int, Set<int>>>((ref) {
  final staffList = ref.watch(staffForStaffSectionProvider);
  final agendaDate = ref.watch(agendaDateProvider);
  final monday = _mondayOfWeek(agendaDate);

  final Map<int, Set<int>> result = {};

  for (final s in staffList) {
    final Set<int> daysWithExceptions = {};

    for (int d = 1; d <= 7; d++) {
      final specificDate = monday.add(Duration(days: d - 1));
      final exceptions = ref.watch(
        exceptionsForStaffOnDateProvider((staffId: s.id, date: specificDate)),
      );

      if (exceptions.isNotEmpty) {
        daysWithExceptions.add(d);
      }
    }

    result[s.id] = daysWithExceptions;
  }

  return result;
});

DateTime _mondayOfWeek(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

String _dayHeaderLabel(BuildContext context, DateTime day) {
  final locale = Intl.getCurrentLocale();
  return DateFormat('EEE, d MMM', locale).format(day);
}

int _totalMinutesForDay(Iterable<List<HourRange>> rangesPerStaff) {
  int total = 0;
  for (final list in rangesPerStaff) {
    for (final r in list) total += r.minutes;
  }
  return total;
}

int _totalMinutesForStaff(Map<int, List<HourRange>> byDay) {
  int total = 0;
  for (final list in byDay.values) {
    for (final r in list) total += r.minutes;
  }
  return total;
}

String _formatTotalHM(BuildContext context, int minutes) {
  if (minutes == 0) return '';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return context.l10n.hoursHoursOnly(h);
  return context.l10n.hoursMinutesCompact(h, m);
}

class StaffWeekOverviewScreen extends ConsumerStatefulWidget {
  const StaffWeekOverviewScreen({super.key});

  @override
  ConsumerState<StaffWeekOverviewScreen> createState() =>
      _StaffWeekOverviewScreenState();
}

class _StaffWeekOverviewScreenState
    extends ConsumerState<StaffWeekOverviewScreen> {
  // Inizializzazione immediata per evitare LateInitializationError
  final ScrollController _headerHController = ScrollController();
  final ScrollController _bodyHController = ScrollController();
  final ScrollController _vScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Sync header position from body only (unidirectional) per evitare conflitti di inerzia.
    _bodyHController.addListener(() {
      if (!_bodyHController.hasClients) return;
      final off = _bodyHController.offset;
      if (_headerHController.hasClients && _headerHController.offset != off) {
        // jumpTo è immediato: per una transizione più fluida si potrebbe usare animateTo con durata breve.
        _headerHController.jumpTo(off);
      }
    });
  }

  @override
  void dispose() {
    _headerHController.dispose();
    _bodyHController.dispose();
    _vScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Data sources
    final selectedDate = ref.watch(agendaDateProvider);
    // Current location could influence future filtering (kept for clarity)
    // final location = ref.watch(currentLocationProvider); // not used yet
    final staffList = ref.watch(staffForStaffSectionProvider);
    // Use real availability coming from the editor provider, mapped to overview ranges
    final availability = ref.watch(weeklyStaffAvailabilityFromEditorProvider);
    // Base availability (without exceptions) for comparison
    final baseAvailability = ref.watch(weeklyStaffBaseAvailabilityProvider);
    // Track which staff/day combinations have exceptions applied
    final exceptionDays = ref.watch(weeklyExceptionDaysProvider);
    final formFactor = ref.watch(formFactorProvider);

    // Week days (Mon..Sun)
    final weekStart = _mondayOfWeek(selectedDate);
    final days = [for (int i = 0; i < 7; i++) weekStart.add(Duration(days: i))];

    // Week label builder: include year on boundaries
    String buildWeekRangeLabel() {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final locale = Intl.getCurrentLocale();
      final sameMonth =
          weekStart.month == weekEnd.month && weekStart.year == weekEnd.year;
      final sameYear = weekStart.year == weekEnd.year;

      if (sameMonth) {
        final startDay = DateFormat('d', locale).format(weekStart);
        final endDay = DateFormat('d', locale).format(weekEnd);
        final endMonthShort = DateFormat('MMM', locale).format(weekEnd);
        return '$startDay–$endDay $endMonthShort';
      }
      if (sameYear) {
        final startDay = DateFormat('d', locale).format(weekStart);
        final endDay = DateFormat('d', locale).format(weekEnd);
        final startMonthShort = DateFormat('MMM', locale).format(weekStart);
        final endMonthShort = DateFormat('MMM', locale).format(weekEnd);
        return '$startDay $startMonthShort – $endDay $endMonthShort';
      }
      final startFull = DateFormat('d MMM y', locale).format(weekStart);
      final endFull = DateFormat('d MMM y', locale).format(weekEnd);
      return '$startFull – $endFull';
    }

    final weekLabel = buildWeekRangeLabel();

    // Layout constants - responsive per mobile
    final isMobileLayout = formFactor == AppFormFactor.mobile;
    final staffColWidth = isMobileLayout ? 120.0 : 200.0;
    final headerHeight = 60.0;
    const chipColor = Color(0xFFECEBFF);
    const chipColorWithException = Color(
      0xFFFFE4B5,
    ); // Moccasin - colore arancione chiaro per eccezioni
    const double chipHeight = 40.0;
    const double chipVGap = 3.0;
    const double baseRowHeight = chipHeight * 2 + (chipVGap * 3) + 5.0;
    const double dayColumnWidth = 100.0;
    const double rightPadding = 5.0;
    final dividerColor = Colors.transparent; // vertical separators
    final divider = Container(height: 0.5, color: dividerColor);
    // Controller già inizializzati in state

    Widget buildDayHeaderCell(DateTime day) {
      final dayIndex = day.weekday; // 1..7
      final totalMin = _totalMinutesForDay(
        availability.values.map((byDay) {
          return byDay[dayIndex] ?? const <HourRange>[];
        }),
      );
      final hasAny = totalMin > 0;
      // Center widget per centrare l'header nella colonna
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: dayColumnWidth),
          child: Container(
            height: headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AgendaTheme.staffHeaderBackground(
                hasAny ? Colors.teal : Colors.blueGrey,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _dayHeaderLabel(context, day),
                  style: AgendaTheme.staffHeaderTextStyle,
                  textAlign: TextAlign.center,
                ),
                if (hasAny)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatTotalHM(context, totalMin),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    double rowHeightForStaff(int staffId) {
      int maxRanges = 0;
      for (final d in days) {
        final count =
            (availability[staffId]?[d.weekday] ?? const <HourRange>[]).length;
        if (count > maxRanges) maxRanges = count;
      }
      if (maxRanges <= 1) return baseRowHeight; // 0 o 1 chip: altezza base
      final required = maxRanges * chipHeight + (maxRanges - 1) * chipVGap;
      return required > baseRowHeight ? required : baseRowHeight;
    }

    Widget buildStaffHeaderCell(int staffId) {
      final staff = staffList.firstWhere(
        (s) => s.id == staffId,
        orElse: () => staffList.first,
      );
      final minutes = _totalMinutesForStaff(availability[staffId] ?? const {});
      final isMobile = formFactor == AppFormFactor.mobile;

      if (isMobile) {
        // Mobile: avatar sopra, nome sotto, icona modifica
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar con icona modifica in overlay
            Stack(
              children: [
                StaffCircleAvatar(
                  height: 42,
                  color: staff.color,
                  isHighlighted: false,
                  initials: staff.initials,
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: GestureDetector(
                    onTap: () {
                      final vn = ref.read(initialStaffToEditProvider);
                      vn.value = staffId;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StaffAvailabilityScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              staff.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (minutes > 0)
              Text(
                _formatTotalHM(context, minutes),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.black54),
              ),
          ],
        );
      }

      // Desktop/Tablet: layout orizzontale
      return Row(
        children: [
          StaffCircleAvatar(
            height: 42,
            color: staff.color,
            isHighlighted: false,
            initials: staff.initials,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  staff.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (minutes > 0)
                  Text(
                    _formatTotalHM(context, minutes),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.black54),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.staffEditHours,
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            onPressed: () {
              // store staff id then navigate to availability editor
              final vn = ref.read(initialStaffToEditProvider);
              vn.value = staffId;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StaffAvailabilityScreen(),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      );
    }

    // Helper: converte slots in HourRange list
    List<HourRange> slotsToRanges(Set<int> slots, int minutesPerSlot) {
      if (slots.isEmpty) return const [];
      final sorted = slots.toList()..sort();
      final List<List<int>> clusters = [];
      var current = <int>[sorted.first];
      for (int i = 1; i < sorted.length; i++) {
        if (sorted[i] == sorted[i - 1] + 1) {
          current.add(sorted[i]);
        } else {
          clusters.add(current);
          current = <int>[sorted[i]];
        }
      }
      clusters.add(current);

      final List<HourRange> ranges = [];
      for (final c in clusters) {
        final startMin = c.first * minutesPerSlot;
        final endMin = (c.last + 1) * minutesPerSlot;
        final sh = startMin ~/ 60;
        final sm = startMin % 60;
        final eh = endMin ~/ 60;
        final em = endMin % 60;
        ranges.add(HourRange(sh, sm, eh, em));
      }
      return ranges;
    }

    // Helper: elimina una fascia oraria
    Future<void> deleteShift(int staffId, int weekday, int shiftIndex) async {
      final layout = ref.read(layoutConfigProvider);
      final asyncByStaff = ref.read(staffAvailabilityByStaffProvider);
      final allData = asyncByStaff.value;
      if (allData == null) return;

      final staffData = allData[staffId];
      if (staffData == null) return;

      final daySlots = staffData[weekday];
      if (daySlots == null || daySlots.isEmpty) return;

      // Converti slots in ranges per identificare quale eliminare
      final ranges = slotsToRanges(daySlots, layout.minutesPerSlot);
      if (shiftIndex >= ranges.length) return;

      final rangeToDelete = ranges[shiftIndex];

      // Rimuovi gli slot corrispondenti a questa fascia
      final newSlots = Set<int>.from(daySlots);
      final startSlot =
          (rangeToDelete.startHour * 60 + rangeToDelete.startMinute) ~/
          layout.minutesPerSlot;
      final endSlot =
          (rangeToDelete.endHour * 60 + rangeToDelete.endMinute) ~/
          layout.minutesPerSlot;
      for (int slot = startSlot; slot < endSlot; slot++) {
        newSlots.remove(slot);
      }

      // Aggiorna il provider
      final newStaffData = Map<int, Set<int>>.from(staffData);
      newStaffData[weekday] = newSlots;

      await ref
          .read(staffAvailabilityByStaffProvider.notifier)
          .saveForStaff(staffId, newStaffData);
    }

    // Helper: mostra menu per eccezione "tutto il giorno"
    void showAllDayExceptionMenu(int staffId, int weekday, DateTime date) {
      final l10n = context.l10n;
      final isMobile = formFactor == AppFormFactor.mobile;
      final locale = Intl.getCurrentLocale();
      final dateLabel = DateFormat('EEEE d MMMM', locale).format(date);
      final staff = staffList.firstWhere(
        (s) => s.id == staffId,
        orElse: () => staffList.first,
      );
      final staffName = staff.displayName;

      // Trova tutte le eccezioni per questa data
      Future<void> deleteAllDayException() async {
        final exceptions = ref.read(
          exceptionsForStaffOnDateProvider((staffId: staffId, date: date)),
        );
        // Elimina tutte le eccezioni per questa data
        for (final exc in exceptions) {
          await ref
              .read(availabilityExceptionsProvider.notifier)
              .deleteException(staffId, exc.id);
        }
      }

      Widget buildContent(BuildContext ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(
                Icons.restore_outlined,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                l10n.exceptionDeleteShift,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              subtitle: Text(
                l10n.exceptionDeleteShiftDesc,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await deleteAllDayException();
              },
            ),
          ],
        );
      }

      if (isMobile) {
        AppBottomSheet.show(
          context: context,
          heightFactor: null,
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    StaffCircleAvatar(
                      height: 48,
                      color: staff.color,
                      isHighlighted: false,
                      initials: staff.initials,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      staffName,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: Theme.of(ctx).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              buildContent(ctx),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AppFormDialog(
            title: Center(
              child: Column(
                children: [
                  StaffCircleAvatar(
                    height: 48,
                    color: staff.color,
                    isHighlighted: false,
                    initials: staff.initials,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    staffName,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: Theme.of(ctx).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            content: buildContent(ctx),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.actionCancel),
              ),
            ],
          ),
        );
      }
    }

    // Helper: mostra menu opzioni per una fascia oraria
    void showShiftOptionsMenu(
      int staffId,
      int weekday,
      int shiftIndex,
      HourRange range,
      DateTime date, {
      bool isException = false,
    }) {
      final l10n = context.l10n;
      final isMobile = formFactor == AppFormFactor.mobile;
      final locale = Intl.getCurrentLocale();
      // Data in formato completo: "lunedì 1 dicembre"
      final dateLabel = DateFormat('EEEE d MMMM', locale).format(date);
      final dayName = DateFormat(
        'EEEE',
        locale,
      ).format(date); // Nome giorno completo
      // Nome completo dello staff
      final staff = staffList.firstWhere(
        (s) => s.id == staffId,
        orElse: () => staffList.first,
      );
      final staffName = staff.displayName;

      // Helper per eliminare solo questo turno (crea eccezione)
      Future<void> deleteThisOnly() async {
        await ref
            .read(availabilityExceptionsProvider.notifier)
            .addException(
              staffId: staffId,
              date: date,
              startTime: TimeOfDay(
                hour: range.startHour,
                minute: range.startMinute,
              ),
              endTime: TimeOfDay(hour: range.endHour, minute: range.endMinute),
              type: AvailabilityExceptionType.unavailable,
              reason: null,
            );
      }

      // Helper per eliminare tutti i turni (dalla disponibilità settimanale)
      Future<void> deleteAll() async {
        await deleteShift(staffId, weekday, shiftIndex);
      }

      // Helper per modificare solo questo turno (apre dialog per eccezione)
      Future<void> editThisOnly() async {
        final result = await _showEditShiftDialog(
          context: context,
          ref: ref,
          range: range,
          dateLabel: dateLabel,
          formFactor: formFactor,
        );
        if (result != null) {
          // Crea eccezione di disponibilità con i nuovi orari
          await ref
              .read(availabilityExceptionsProvider.notifier)
              .addException(
                staffId: staffId,
                date: date,
                startTime: result.startTime,
                endTime: result.endTime,
                type: AvailabilityExceptionType.available,
                reason: null,
              );
        }
      }

      // Helper per modificare tutti i turni (naviga all'editor settimanale)
      void editAll() {
        final vn = ref.read(initialStaffToEditProvider);
        vn.value = staffId;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StaffAvailabilityScreen()),
        );
      }

      // Helper per trovare l'eccezione corrispondente a questo range
      AvailabilityException? findMatchingException() {
        final monday = _mondayOfWeek(ref.read(agendaDateProvider));
        final specificDate = monday.add(Duration(days: weekday - 1));
        final exceptions = ref.read(
          exceptionsForStaffOnDateProvider((
            staffId: staffId,
            date: specificDate,
          )),
        );
        // Cerca l'eccezione che corrisponde a questo range orario
        for (final exc in exceptions) {
          if (exc.startTime != null &&
              exc.endTime != null &&
              exc.startTime!.hour == range.startHour &&
              exc.startTime!.minute == range.startMinute &&
              exc.endTime!.hour == range.endHour &&
              exc.endTime!.minute == range.endMinute) {
            return exc;
          }
        }
        return null;
      }

      // Helper per eliminare un'eccezione
      Future<void> deleteException() async {
        final exc = findMatchingException();
        if (exc != null) {
          await ref
              .read(availabilityExceptionsProvider.notifier)
              .deleteException(staffId, exc.id);
        }
      }

      // Helper per modificare un'eccezione
      Future<void> editException() async {
        final exc = findMatchingException();
        if (exc == null) return;

        final result = await _showEditShiftDialog(
          context: context,
          ref: ref,
          range: range,
          dateLabel: dateLabel,
          formFactor: formFactor,
        );
        if (result != null) {
          // Aggiorna l'eccezione esistente con i nuovi orari
          final updatedExc = exc.copyWith(
            startTime: result.startTime,
            endTime: result.endTime,
          );
          await ref
              .read(availabilityExceptionsProvider.notifier)
              .updateException(updatedExc);
        }
      }

      // Lista opzioni
      Widget buildOptionsList(BuildContext ctx) {
        // Se è un'eccezione, mostra solo modifica/elimina eccezione
        if (isException) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modifica eccezione
              ListTile(
                leading: const Icon(Icons.edit_calendar_outlined),
                title: Text(l10n.exceptionEditShift),
                subtitle: Text(
                  l10n.exceptionEditShiftDesc,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await editException();
                },
              ),
              const Divider(height: 1),
              // Elimina eccezione
              ListTile(
                leading: Icon(
                  Icons.restore_outlined,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  l10n.exceptionDeleteShift,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                subtitle: Text(
                  l10n.exceptionDeleteShiftDesc,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await deleteException();
                },
              ),
            ],
          );
        }

        // Menu standard per turni base
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modifica solo questo turno
            ListTile(
              leading: const Icon(Icons.edit_calendar_outlined),
              title: Text(l10n.shiftEditThisOnly),
              subtitle: Text(
                l10n.shiftEditThisOnlyDesc(dateLabel),
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await editThisOnly();
              },
            ),
            // Modifica tutti questi turni
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.shiftEditAll),
              subtitle: Text(
                l10n.shiftEditAllDesc(dayName),
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              onTap: () {
                Navigator.pop(ctx);
                editAll();
              },
            ),
            const Divider(height: 1),
            // Elimina solo questo turno
            ListTile(
              leading: Icon(
                Icons.event_busy_outlined,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                l10n.shiftDeleteThisOnly,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              subtitle: Text(
                l10n.shiftDeleteThisOnlyDesc(dateLabel),
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await deleteThisOnly();
              },
            ),
            // Elimina tutti questi turni
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                l10n.shiftDeleteAll,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              subtitle: Text(
                l10n.shiftDeleteAllDesc(dayName),
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await deleteAll();
              },
            ),
          ],
        );
      }

      if (isMobile) {
        // Mobile: AppBottomSheet con avatar e nome
        AppBottomSheet.show(
          context: context,
          heightFactor: null, // Auto-size
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar con nome sotto
              Center(
                child: Column(
                  children: [
                    StaffCircleAvatar(
                      height: 48,
                      color: staff.color,
                      isHighlighted: false,
                      initials: staff.initials,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      staffName,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${range.label(ctx)} • $dateLabel',
                style: Theme.of(ctx).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              buildOptionsList(ctx),
            ],
          ),
        );
      } else {
        // Desktop/Tablet: AppFormDialog con avatar centrato
        showDialog(
          context: context,
          builder: (ctx) => AppFormDialog(
            title: Center(
              child: Column(
                children: [
                  StaffCircleAvatar(
                    height: 48,
                    color: staff.color,
                    isHighlighted: false,
                    initials: staff.initials,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    staffName,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${range.label(ctx)} • $dateLabel',
                    style: Theme.of(ctx).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            content: buildOptionsList(ctx),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.actionCancel),
              ),
            ],
          ),
        );
      }
    }

    Widget buildDayCell(
      List<HourRange> ranges,
      List<HourRange> baseRanges,
      int staffId,
      int weekday,
      DateTime date, {
      bool hasException = false,
    }) {
      // Verifica se un range è presente nella disponibilità base
      bool isInBase(HourRange range) {
        return baseRanges.any(
          (base) =>
              base.startHour == range.startHour &&
              base.startMinute == range.startMinute &&
              base.endHour == range.endHour &&
              base.endMinute == range.endMinute,
        );
      }

      // Se non ci sono fasce orarie ma c'è un'eccezione, mostra uno slot vuoto arancione
      if (ranges.isEmpty) {
        if (hasException) {
          // Slot arancione vuoto per indicare "non lavora" a causa di eccezione
          return Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  // Mostra menu per eccezione "tutto il giorno"
                  showAllDayExceptionMenu(staffId, weekday, date);
                },
                child: Container(
                  height: chipHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: chipColorWithException,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AgendaTheme.appointmentBorder,
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    '—',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < ranges.length; i++) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  final isExceptionChip = !isInBase(ranges[i]);
                  showShiftOptionsMenu(
                    staffId,
                    weekday,
                    i,
                    ranges[i],
                    date,
                    isException: isExceptionChip,
                  );
                },
                child: Container(
                  height: chipHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isInBase(ranges[i])
                        ? chipColor
                        : chipColorWithException,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AgendaTheme.appointmentBorder,
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    ranges[i].label(context),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            if (i < ranges.length - 1) SizedBox(height: chipVGap),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: StaffTopControls(
          todayLabel: context.l10n.currentWeek,
          labelOverride: weekLabel,
          compact: formFactor != AppFormFactor.desktop,
        ),
      ),
      body: ScrollConfiguration(
        behavior: const NoScrollbarBehavior(),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: staffColWidth),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerHController,
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final d in days) ...[
                          SizedBox(
                            width: dayColumnWidth,
                            child: buildDayHeaderCell(d),
                          ),
                          if (d != days.last) const SizedBox(width: 8),
                        ],
                        const SizedBox(width: rightPadding),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                controller: _vScrollController,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Staff column
                    SizedBox(
                      width: staffColWidth,
                      child: Column(
                        children: [
                          for (final s in staffList) ...[
                            Container(
                              height: rowHeightForStaff(s.id),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              alignment: Alignment.centerLeft,
                              child: buildStaffHeaderCell(s.id),
                            ),
                            divider,
                          ],
                        ],
                      ),
                    ),
                    // Gap column with matching row dividers
                    SizedBox(
                      width: 8,
                      child: Column(
                        children: [
                          for (final s in staffList) ...[
                            SizedBox(height: rowHeightForStaff(s.id)),
                            divider,
                          ],
                        ],
                      ),
                    ),
                    // Days grid (with vertical separators between columns)
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _bodyHController,
                        physics: const ClampingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          children: [
                            for (final s in staffList) ...[
                              // Row of day cells + vertical gaps
                              Row(
                                children: [
                                  for (final d in days) ...[
                                    SizedBox(
                                      width: dayColumnWidth,
                                      height: rowHeightForStaff(s.id),
                                      child: buildDayCell(
                                        (availability[s.id]?[d.weekday]) ??
                                            const <HourRange>[],
                                        (baseAvailability[s.id]?[d.weekday]) ??
                                            const <HourRange>[],
                                        s.id,
                                        d.weekday,
                                        d,
                                        hasException:
                                            exceptionDays[s.id]?.contains(
                                              d.weekday,
                                            ) ??
                                            false,
                                      ),
                                    ),
                                    if (d != days.last)
                                      SizedBox(
                                        width: 8,
                                        height: rowHeightForStaff(s.id),
                                      ),
                                  ],
                                  SizedBox(
                                    width: rightPadding,
                                    height: rowHeightForStaff(s.id),
                                  ),
                                ],
                              ),
                              // Single full-width horizontal divider spanning day cells + gaps
                              Builder(
                                builder: (context) {
                                  final daysRowWidth =
                                      days.length * dayColumnWidth +
                                      (days.length - 1) * 8 +
                                      rightPadding;
                                  return SizedBox(
                                    width: daysRowWidth,
                                    child: divider,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Risultato della modifica di un turno.
class _EditShiftResult {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const _EditShiftResult({required this.startTime, required this.endTime});
}

/// Mostra il dialog per modificare un turno (solo gli orari).
Future<_EditShiftResult?> _showEditShiftDialog({
  required BuildContext context,
  required WidgetRef ref,
  required HourRange range,
  required String dateLabel,
  required AppFormFactor formFactor,
}) async {
  final isMobile = formFactor == AppFormFactor.mobile;

  if (isMobile) {
    return AppBottomSheet.show<_EditShiftResult>(
      context: context,
      heightFactor: null,
      builder: (ctx) => _EditShiftContent(range: range, dateLabel: dateLabel),
    );
  } else {
    return showDialog<_EditShiftResult>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _EditShiftContent(
            range: range,
            dateLabel: dateLabel,
            isDialog: true,
          ),
        ),
      ),
    );
  }
}

/// Widget per il contenuto del dialog di modifica turno.
class _EditShiftContent extends ConsumerStatefulWidget {
  const _EditShiftContent({
    required this.range,
    required this.dateLabel,
    this.isDialog = false,
  });

  final HourRange range;
  final String dateLabel;
  final bool isDialog;

  @override
  ConsumerState<_EditShiftContent> createState() => _EditShiftContentState();
}

class _EditShiftContentState extends ConsumerState<_EditShiftContent> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay(
      hour: widget.range.startHour,
      minute: widget.range.startMinute,
    );
    _endTime = TimeOfDay(
      hour: widget.range.endHour,
      minute: widget.range.endMinute,
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime({required bool isStart}) async {
    final layout = ref.read(layoutConfigProvider);
    final step = layout.minutesPerSlot;
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
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      setState(() => _timeError = l10n.exceptionTimeError);
      return false;
    }
    return true;
  }

  void _onSave() {
    if (!_validate()) return;
    Navigator.of(
      context,
    ).pop(_EditShiftResult(startTime: _startTime, endTime: _endTime));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Riga orari
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.shiftStartTime,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _pickTime(isStart: true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        enabledBorder: _timeError != null
                            ? OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: colorScheme.error,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatTime(_startTime)),
                          const Icon(Icons.access_time, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.shiftEndTime,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _pickTime(isStart: false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        enabledBorder: _timeError != null
                            ? OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: colorScheme.error,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatTime(_endTime)),
                          const Icon(Icons.access_time, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_timeError != null) ...[
          const SizedBox(height: 8),
          Text(
            _timeError!,
            style: TextStyle(color: colorScheme.error, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        // Bottoni
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppOutlinedActionButton(
              onPressed: () => Navigator.of(context).pop(),
              padding: AppButtonStyles.dialogButtonPadding,
              child: Text(l10n.actionCancel),
            ),
            const SizedBox(width: 8),
            AppFilledButton(
              onPressed: _onSave,
              padding: AppButtonStyles.dialogButtonPadding,
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ],
    );

    if (widget.isDialog) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shiftEditTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              widget.dateLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.shiftEditTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(widget.dateLabel, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        content,
      ],
    );
  }
}

/// Widget per la selezione dell'orario con griglia.
class _TimeGridPicker extends StatefulWidget {
  const _TimeGridPicker({required this.initial, required this.stepMinutes});

  final TimeOfDay initial;
  final int stepMinutes;

  @override
  State<_TimeGridPicker> createState() => _TimeGridPickerState();
}

class _TimeGridPickerState extends State<_TimeGridPicker> {
  late TimeOfDay _selected;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    // Scrolla all'orario preimpostato dopo il primo frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    // Calcola l'indice dell'orario selezionato
    final selectedMinutes = _selected.hour * 60 + _selected.minute;
    final index = selectedMinutes ~/ widget.stepMinutes;

    // Calcola l'altezza di ogni riga (4 elementi per riga)
    // childAspectRatio = 2.5, mainAxisSpacing = 8
    // L'altezza dipende dalla larghezza disponibile, ma possiamo stimarla
    const crossAxisCount = 4;
    const mainAxisSpacing = 8.0;
    const crossAxisSpacing = 8.0;
    const padding = 8.0;

    // Calcola la riga in cui si trova l'elemento selezionato
    final row = index ~/ crossAxisCount;

    // Stima l'altezza di ogni cella basandosi su una larghezza ragionevole
    // Per un calcolo più preciso, usiamo un valore tipico
    if (_scrollController.hasClients) {
      final viewportWidth = _scrollController.position.viewportDimension > 0
          ? MediaQuery.of(context).size.width - padding * 2
          : 300.0;
      final cellWidth =
          (viewportWidth - crossAxisSpacing * (crossAxisCount - 1)) /
          crossAxisCount;
      final cellHeight = cellWidth / 2.5; // childAspectRatio = 2.5
      final rowHeight = cellHeight + mainAxisSpacing;

      // Calcola l'offset per centrare l'elemento selezionato
      final targetOffset = row * rowHeight;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final scrollTo = targetOffset.clamp(0.0, maxScroll);

      _scrollController.animateTo(
        scrollTo,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    // Genera lista di orari con step specificato (da 00:00 a 24:00)
    final times = <TimeOfDay>[];
    for (int m = 0; m <= 24 * 60; m += widget.stepMinutes) {
      final h = m ~/ 60;
      final min = m % 60;
      times.add(TimeOfDay(hour: h, minute: min));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.exceptionSelectTime,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
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
                  onTap: () {
                    // Chiudi immediatamente con il valore selezionato
                    Navigator.of(context).pop(time);
                  },
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
