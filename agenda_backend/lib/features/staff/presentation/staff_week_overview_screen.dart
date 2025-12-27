import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:agenda_backend/core/l10n/date_time_formats.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/availability_exception.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/widgets/app_bottom_sheet.dart';
import 'package:agenda_backend/core/widgets/app_buttons.dart';
import 'package:agenda_backend/core/widgets/app_dialogs.dart';
import 'package:agenda_backend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_backend/features/agenda/domain/config/agenda_theme.dart';
import 'package:agenda_backend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_backend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_backend/features/staff/presentation/dialogs/add_exception_dialog.dart';
import 'package:agenda_backend/features/staff/presentation/staff_availability_screen.dart';
import 'package:agenda_backend/features/staff/providers/availability_exceptions_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:agenda_backend/features/staff/widgets/staff_top_controls.dart';
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

class _DisplayRange {
  _DisplayRange({
    required this.startMinutes,
    required this.endMinutes,
    required this.label,
    required this.isException,
    this.exceptionType,
    this.hourRange,
  });

  final int startMinutes;
  final int endMinutes;
  final String label;
  final bool isException;
  final AvailabilityExceptionType? exceptionType;
  final HourRange? hourRange;
}

class _DashedRoundedRectPainter extends CustomPainter {
  _DashedRoundedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 0.6;
    const dashLength = 4.0;
    const gapLength = 3.0;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

List<_DisplayRange> _mergeRangesForDisplay(
  List<HourRange> baseRanges,
  List<AvailabilityException> exceptions,
  BuildContext context, {
  bool applyUnavailableSplit = true,
  bool subtractAvailableFromBase = false,
}) {
  final items = <_DisplayRange>[];

  final availableToSubtract = subtractAvailableFromBase
      ? exceptions
            .where(
              (e) =>
                  e.type == AvailabilityExceptionType.available &&
                  e.startTime != null &&
                  e.endTime != null,
            )
            .map<({int start, int end})>(
              (e) => (
                start: e.startTime!.hour * 60 + e.startTime!.minute,
                end: e.endTime!.hour * 60 + e.endTime!.minute,
              ),
            )
            .toList()
      : const <({int start, int end})>[];

  final unavailable = applyUnavailableSplit
      ? exceptions
            .where(
              (e) =>
                  e.type == AvailabilityExceptionType.unavailable &&
                  e.startTime != null &&
                  e.endTime != null,
            )
            .map<({int start, int end})>(
              (e) => (
                start: e.startTime!.hour * 60 + e.startTime!.minute,
                end: e.endTime!.hour * 60 + e.endTime!.minute,
              ),
            )
            .toList()
      : const <({int start, int end})>[];

  for (final r in baseRanges) {
    final baseStart = r.startHour * 60 + r.startMinute;
    final baseEnd = r.endHour * 60 + r.endMinute;
    var segments = <({int start, int end})>[(start: baseStart, end: baseEnd)];

    if (availableToSubtract.isNotEmpty) {
      for (final a in availableToSubtract) {
        final next = <({int start, int end})>[];
        for (final seg in segments) {
          if (a.end <= seg.start || a.start >= seg.end) {
            next.add(seg);
            continue;
          }
          if (a.start > seg.start) {
            final leftEnd = a.start < seg.end ? a.start : seg.end;
            if (leftEnd > seg.start) {
              next.add((start: seg.start, end: leftEnd));
            }
          }
          if (a.end < seg.end) {
            final rightStart = a.end > seg.start ? a.end : seg.start;
            if (seg.end > rightStart) {
              next.add((start: rightStart, end: seg.end));
            }
          }
        }
        segments = next;
        if (segments.isEmpty) break;
      }
    }

    if (unavailable.isNotEmpty) {
      for (final u in unavailable) {
        final next = <({int start, int end})>[];
        for (final seg in segments) {
          if (u.end <= seg.start || u.start >= seg.end) {
            next.add(seg);
            continue;
          }
          if (u.start > seg.start) {
            final leftEnd = u.start < seg.end ? u.start : seg.end;
            if (leftEnd > seg.start) {
              next.add((start: seg.start, end: leftEnd));
            }
          }
          if (u.end < seg.end) {
            final rightStart = u.end > seg.start ? u.end : seg.start;
            if (seg.end > rightStart) {
              next.add((start: rightStart, end: seg.end));
            }
          }
        }
        segments = next;
        if (segments.isEmpty) break;
      }
    }

    for (final seg in segments) {
      final isAllDay = seg.start == 0 && seg.end == 24 * 60;
      final label = isAllDay
          ? context.l10n.exceptionAllDay
          : '${DtFmt.hm(context, seg.start ~/ 60, seg.start % 60)} - ${DtFmt.hm(context, seg.end ~/ 60, seg.end % 60)}';
      items.add(
        _DisplayRange(
          startMinutes: seg.start,
          endMinutes: seg.end,
          label: label,
          isException: false,
          exceptionType: null,
          hourRange: HourRange(
            seg.start ~/ 60,
            seg.start % 60,
            seg.end ~/ 60,
            seg.end % 60,
          ),
        ),
      );
    }
  }

  final allDayExceptions = exceptions.where(
    (e) => e.startTime == null && e.endTime == null,
  );
  for (final e in allDayExceptions) {
    items.add(
      _DisplayRange(
        startMinutes: 0,
        endMinutes: 24 * 60,
        label: context.l10n.exceptionAllDay,
        isException: true,
        exceptionType: e.type,
        hourRange: const HourRange(0, 0, 24, 0),
      ),
    );
  }

  for (final e in exceptions) {
    if (e.startTime == null || e.endTime == null) continue;
    final label =
        '${DtFmt.hm(context, e.startTime!.hour, e.startTime!.minute)} - ${DtFmt.hm(context, e.endTime!.hour, e.endTime!.minute)}';
    items.add(
      _DisplayRange(
        startMinutes: e.startTime!.hour * 60 + e.startTime!.minute,
        endMinutes: e.endTime!.hour * 60 + e.endTime!.minute,
        label: label,
        isException: true,
        exceptionType: e.type,
        hourRange: HourRange(
          e.startTime!.hour,
          e.startTime!.minute,
          e.endTime!.hour,
          e.endTime!.minute,
        ),
      ),
    );
  }

  // De-duplicate exact same ranges, prefer exception styling if present.
  final Map<String, _DisplayRange> unique = {};
  for (final item in items) {
    final key = '${item.startMinutes}-${item.endMinutes}';
    final existing = unique[key];
    if (existing == null) {
      unique[key] = item;
      continue;
    }
    if (!existing.isException && item.isException) {
      unique[key] = item;
    }
  }

  final result = unique.values.toList()
    ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  return result;
}

int _countSegmentsForDay(
  BuildContext context,
  List<HourRange> ranges,
  List<AvailabilityException> exceptions,
) {
  final displayRanges = _mergeRangesForDisplay(
    ranges,
    exceptions,
    context,
    applyUnavailableSplit: false,
    subtractAvailableFromBase: true,
  );
  // +1 per il chip "aggiungi eccezione"
  return displayRanges.length + 1;
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
class WeeklyExceptionsLoadKeyNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setKey(String? value) => state = value;
}

final weeklyExceptionsLoadKeyProvider =
    NotifierProvider<WeeklyExceptionsLoadKeyNotifier, String?>(
      WeeklyExceptionsLoadKeyNotifier.new,
    );

void _ensureExceptionsLoadedForWeekWithKey(
  String? lastKey,
  void Function(String? value) setKey,
  Future<void> Function(int staffId, {DateTime? fromDate, DateTime? toDate})
  loadForStaff,
  DateTime agendaDate,
  List<Staff> staffList,
) {
  if (staffList.isEmpty) return;
  final monday = _mondayOfWeek(agendaDate);
  final staffIds = staffList.map((s) => s.id).toList()..sort();
  final key =
      '${monday.toIso8601String().split('T').first}|${staffIds.join(",")}';
  if (lastKey == key) return;
  final fromDate = monday;
  final toDate = monday.add(const Duration(days: 6));
  for (final staff in staffList) {
    loadForStaff(staff.id, fromDate: fromDate, toDate: toDate);
  }
}

final weeklyStaffAvailabilityFromEditorProvider =
    Provider<Map<int, Map<int, List<HourRange>>>>((ref) {
      final staffList = ref.watch(staffForStaffSectionProvider);
      final asyncByStaff = ref.watch(staffAvailabilityByStaffProvider);
      final layout = ref.watch(layoutConfigProvider);
      final minutesPerSlot = layout.minutesPerSlot;
      final totalSlots = layout.totalSlots;

      // Ottieni la data corrente dell'agenda per calcolare la settimana mostrata
      final agendaDate = ref.watch(agendaDateProvider);
      _ensureExceptionsLoadedForWeekWithKey(
        ref.watch(weeklyExceptionsLoadKeyProvider),
        ref.read(weeklyExceptionsLoadKeyProvider.notifier).setKey,
        ref
            .read(availabilityExceptionsProvider.notifier)
            .loadExceptionsForStaff,
        agendaDate,
        staffList,
      );
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
  _ensureExceptionsLoadedForWeekWithKey(
    ref.watch(weeklyExceptionsLoadKeyProvider),
    ref.read(weeklyExceptionsLoadKeyProvider.notifier).setKey,
    ref.read(availabilityExceptionsProvider.notifier).loadExceptionsForStaff,
    agendaDate,
    staffList,
  );
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
    for (final r in list) {
      total += r.minutes;
    }
  }
  return total;
}

int _totalMinutesForStaff(Map<int, List<HourRange>> byDay) {
  int total = 0;
  for (final list in byDay.values) {
    for (final r in list) {
      total += r.minutes;
    }
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

  // Caricamento eccezioni gestito dai provider

  @override
  Widget build(BuildContext context) {
    // Data sources
    final selectedDate = ref.watch(agendaDateProvider);
    // Current location could influence future filtering (kept for clarity)
    // final location = ref.watch(currentLocationProvider); // not used yet
    final staffList = ref.watch(staffForStaffSectionProvider);
    // Use real availability coming from the editor provider, mapped to overview ranges
    final availability = ref.watch(weeklyStaffAvailabilityFromEditorProvider);
    // Track which staff/day combinations have exceptions applied
    final exceptionDays = ref.watch(weeklyExceptionDaysProvider);
    final formFactor = ref.watch(formFactorProvider);
    _ensureExceptionsLoadedForWeekWithKey(
      ref.watch(weeklyExceptionsLoadKeyProvider),
      ref.read(weeklyExceptionsLoadKeyProvider.notifier).setKey,
      ref.read(availabilityExceptionsProvider.notifier).loadExceptionsForStaff,
      selectedDate,
      staffList,
    );

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
    final weekEnd = weekStart.add(const Duration(days: 6));
    final todayDate = DateUtils.dateOnly(DateTime.now());
    //final isTodayInWeek =
    !todayDate.isBefore(weekStart) && !todayDate.isAfter(weekEnd);
    //final effectivePickerDate = isTodayInWeek ? todayDate : weekEnd;

    // Layout constants - responsive per mobile
    final isMobileLayout = formFactor == AppFormFactor.mobile;
    final staffColWidth = isMobileLayout ? 120.0 : 200.0;
    final headerHeight = 60.0;
    const chipColor = Color(0xFFECEBFF);
    const chipColorWithException = Color(
      0xFFFFE4B5,
    ); // Moccasin - colore arancione chiaro per eccezioni
    const chipColorWithAvailableException = Color(0xFFDFF5D8);
    const chipTextColorWithAvailableException = Color(0xFF0F6A36);
    const chipDisabledTextColor = Color(0xFF6B6B6B);
    const double chipHeight = 40.0;
    const double chipVGap = 3.0;
    const double chipTopPadding = 4.0;
    const double baseRowHeight = chipHeight * 2 + (chipVGap * 3) + 36.0;
    const double staffRowGap = 24.0;
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
        final exceptions = ref.watch(
          exceptionsForStaffOnDateProvider((staffId: staffId, date: d)),
        );
        final dayRanges =
            availability[staffId]?[d.weekday] ?? const <HourRange>[];
        var count = _countSegmentsForDay(context, dayRanges, exceptions);
        if (count == 0) count = 1;
        if (count > maxRanges) maxRanges = count;
      }
      if (maxRanges <= 1) return baseRowHeight; // 0 o 1 chip: altezza base
      final required =
          chipTopPadding + maxRanges * chipHeight + (maxRanges - 1) * chipVGap;
      return required > baseRowHeight ? required : baseRowHeight;
    }

    Widget buildStaffHeaderCell(int staffId) {
      final staff = staffList.firstWhere(
        (s) => s.id == staffId,
        orElse: () => staffList.first,
      );
      final minutes = _totalMinutesForStaff(availability[staffId] ?? const {});
      final isMobile = formFactor == AppFormFactor.mobile;
      void openStaffAvailability() {
        final vn = ref.read(initialStaffToEditProvider);
        vn.value = staffId;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StaffAvailabilityScreen()),
        );
      }

      if (isMobile) {
        // Mobile: avatar, nome e totale ore raggruppati al centro
        return GestureDetector(
          onTap: openStaffAvailability,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    StaffCircleAvatar(
                      height: 40,
                      color: staff.color,
                      isHighlighted: false,
                      initials: staff.initials,
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
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
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  staff.displayName,
                  maxLines: 1,
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
            ),
          ),
        );
      }

      // Desktop/Tablet: layout orizzontale
      return GestureDetector(
        onTap: openStaffAvailability,
        child: Row(
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
              onPressed: openStaffAvailability,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
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
      AvailabilityException? findAllDayException() {
        final exceptions = ref.read(
          exceptionsForStaffOnDateProvider((staffId: staffId, date: date)),
        );
        for (final exc in exceptions) {
          if (exc.isAllDay) return exc;
        }
        return null;
      }

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
              leading: const Icon(Icons.edit_calendar_outlined),
              title: Text(l10n.exceptionEditShift),
              subtitle: Text(
                l10n.exceptionEditShiftDesc,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              onTap: () async {
                final exc = findAllDayException();
                if (exc == null) return;
                Navigator.pop(ctx);
                await showAddExceptionDialog(
                  context,
                  ref,
                  staffId: staffId,
                  initial: exc,
                );
              },
            ),
            const Divider(height: 1),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          Future<void> addDeltaException(
            int startMinutes,
            int endMinutes,
            AvailabilityExceptionType type,
          ) async {
            if (endMinutes <= startMinutes) return;
            await ref
                .read(availabilityExceptionsProvider.notifier)
                .addException(
                  staffId: staffId,
                  date: date,
                  startTime: TimeOfDay(
                    hour: startMinutes ~/ 60,
                    minute: startMinutes % 60,
                  ),
                  endTime: TimeOfDay(
                    hour: endMinutes ~/ 60,
                    minute: endMinutes % 60,
                  ),
                  type: type,
                  reason: null,
                );
          }

          final baseStartMinutes = range.startHour * 60 + range.startMinute;
          final baseEndMinutes = range.endHour * 60 + range.endMinute;
          final newStartMinutes =
              result.startTime.hour * 60 + result.startTime.minute;
          final newEndMinutes =
              result.endTime.hour * 60 + result.endTime.minute;

          // Rimuovi le ore tolte rispetto al turno base
          if (newStartMinutes > baseStartMinutes) {
            await addDeltaException(
              baseStartMinutes,
              newStartMinutes,
              AvailabilityExceptionType.unavailable,
            );
          }
          if (newEndMinutes < baseEndMinutes) {
            await addDeltaException(
              newEndMinutes,
              baseEndMinutes,
              AvailabilityExceptionType.unavailable,
            );
          }

          // Aggiungi eventuali estensioni rispetto al turno base
          if (newStartMinutes < baseStartMinutes) {
            await addDeltaException(
              newStartMinutes,
              baseStartMinutes,
              AvailabilityExceptionType.available,
            );
          }
          if (newEndMinutes > baseEndMinutes) {
            await addDeltaException(
              baseEndMinutes,
              newEndMinutes,
              AvailabilityExceptionType.available,
            );
          }
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
        final isAllDayRange =
            range.startHour == 0 &&
            range.startMinute == 0 &&
            range.endHour == 24 &&
            range.endMinute == 0;
        // Cerca l'eccezione che corrisponde a questo range orario
        for (final exc in exceptions) {
          if (isAllDayRange && exc.isAllDay) return exc;
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

        if (exc.isAllDay) {
          await showAddExceptionDialog(
            context,
            ref,
            staffId: staffId,
            initial: exc,
          );
          return;
        }

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

    // _DisplayRange è definita a livello di file per poter essere usata nel sort.

    Widget buildDayCell(
      List<HourRange> ranges,
      List<AvailabilityException> exceptions,
      int staffId,
      int weekday,
      DateTime date, {
      bool hasException = false,
    }) {
      final displayRanges = _mergeRangesForDisplay(
        ranges,
        exceptions,
        context,
        applyUnavailableSplit: false,
        subtractAvailableFromBase: true,
      );
      final hasAllDayAvailable = exceptions.any(
        (e) =>
            e.type == AvailabilityExceptionType.available &&
            e.startTime == null &&
            e.endTime == null,
      );

      Widget buildAllDayChip() {
        final bgColor = hasAllDayAvailable
            ? chipColorWithAvailableException
            : chipColorWithException.withOpacity(0.45);
        final textColor = hasAllDayAvailable
            ? chipTextColorWithAvailableException
            : chipDisabledTextColor.withOpacity(0.7);
        final borderRadius = BorderRadius.circular(6);
        final borderColor = AgendaTheme.appointmentBorder.withOpacity(0.4);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              // Mostra menu per eccezione "tutto il giorno"
              showAllDayExceptionMenu(staffId, weekday, date);
            },
            child: CustomPaint(
              painter: hasAllDayAvailable
                  ? null
                  : _DashedRoundedRectPainter(color: borderColor, radius: 6),
              child: Container(
                height: chipHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: borderRadius,
                  border: hasAllDayAvailable
                      ? Border.all(
                          color: AgendaTheme.appointmentBorder,
                          width: 0.6,
                        )
                      : null,
                ),
                child: Text(
                  context.l10n.exceptionAllDay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      Widget buildChipForRange(_DisplayRange range) {
        final isAvailableException =
            range.exceptionType == AvailabilityExceptionType.available;
        final isUnavailableException =
            range.exceptionType == AvailabilityExceptionType.unavailable;
        final bgColor = range.isException
            ? (isAvailableException
                  ? chipColorWithAvailableException
                  : chipColorWithException.withOpacity(0.45))
            : chipColor;
        final textColor = range.isException
            ? (isAvailableException
                  ? chipTextColorWithAvailableException
                  : chipDisabledTextColor.withOpacity(0.7))
            : Colors.black87;
        final borderRadius = BorderRadius.circular(6);
        final borderColor = AgendaTheme.appointmentBorder.withOpacity(0.4);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              if (range.hourRange != null) {
                final isAllDayRange =
                    range.hourRange!.startHour == 0 &&
                    range.hourRange!.startMinute == 0 &&
                    range.hourRange!.endHour == 24 &&
                    range.hourRange!.endMinute == 0;
                if (range.isException && isAllDayRange) {
                  AvailabilityException? exc;
                  for (final e in exceptions) {
                    if (e.isAllDay) {
                      exc = e;
                      break;
                    }
                  }
                  if (exc != null) {
                    showAddExceptionDialog(
                      context,
                      ref,
                      staffId: staffId,
                      initial: exc,
                    );
                    return;
                  }
                }
                if (range.isException && !isAllDayRange) {
                  AvailabilityException? exc;
                  for (final e in exceptions) {
                    if (e.startTime == null || e.endTime == null) continue;
                    if (e.startTime!.hour == range.hourRange!.startHour &&
                        e.startTime!.minute == range.hourRange!.startMinute &&
                        e.endTime!.hour == range.hourRange!.endHour &&
                        e.endTime!.minute == range.hourRange!.endMinute) {
                      exc = e;
                      break;
                    }
                  }
                  if (exc != null) {
                    showAddExceptionDialog(
                      context,
                      ref,
                      staffId: staffId,
                      initial: exc,
                    );
                    return;
                  }
                }
                showShiftOptionsMenu(
                  staffId,
                  weekday,
                  0,
                  range.hourRange!,
                  date,
                  isException: range.isException,
                );
              }
            },
            child: CustomPaint(
              painter: isUnavailableException
                  ? _DashedRoundedRectPainter(color: borderColor, radius: 6)
                  : null,
              child: Container(
                height: chipHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: borderRadius,
                  border: isUnavailableException
                      ? null
                      : Border.all(
                          color: AgendaTheme.appointmentBorder,
                          width: 0.6,
                        ),
                ),
                child: Text(
                  range.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: chipTopPadding),
          if (displayRanges.isEmpty && hasException) ...[
            buildAllDayChip(),
            SizedBox(height: chipVGap),
          ],
          for (int i = 0; i < displayRanges.length; i++) ...[
            buildChipForRange(displayRanges[i]),
            SizedBox(height: chipVGap),
          ],
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                showAddExceptionDialog(
                  context,
                  ref,
                  staffId: staffId,
                  date: date,
                );
              },
              child: Container(
                height: chipHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AgendaTheme.appointmentBorder.withOpacity(0.6),
                    width: 0.6,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: const BackButton(),
        title: Padding(
          padding: EdgeInsets.only(
            left: formFactor == AppFormFactor.mobile ? staffColWidth - 64.0 : 0,
          ),
          child: StaffTopControls(
            todayLabel: context.l10n.currentWeek,
            labelOverride: weekLabel,
            compact: formFactor != AppFormFactor.desktop,
          ),
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
            const SizedBox(height: 12),
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
                          for (int i = 0; i < staffList.length; i++) ...[
                            Container(
                              height: rowHeightForStaff(staffList[i].id),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              alignment: Alignment.centerLeft,
                              child: buildStaffHeaderCell(staffList[i].id),
                            ),
                            divider,
                            if (i < staffList.length - 1)
                              const SizedBox(height: staffRowGap),
                          ],
                        ],
                      ),
                    ),
                    // Gap column with matching row dividers
                    SizedBox(
                      width: 8,
                      child: Column(
                        children: [
                          for (int i = 0; i < staffList.length; i++) ...[
                            SizedBox(
                              height: rowHeightForStaff(staffList[i].id),
                            ),
                            divider,
                            if (i < staffList.length - 1)
                              const SizedBox(height: staffRowGap),
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
                            for (int i = 0; i < staffList.length; i++) ...[
                              // Row of day cells + vertical gaps
                              Row(
                                children: [
                                  for (final d in days) ...[
                                    SizedBox(
                                      width: dayColumnWidth,
                                      height: rowHeightForStaff(
                                        staffList[i].id,
                                      ),
                                      child: buildDayCell(
                                        (availability[staffList[i].id]?[d
                                                .weekday]) ??
                                            const <HourRange>[],
                                        ref.watch(
                                          exceptionsForStaffOnDateProvider((
                                            staffId: staffList[i].id,
                                            date: d,
                                          )),
                                        ),
                                        staffList[i].id,
                                        d.weekday,
                                        d,
                                        hasException:
                                            exceptionDays[staffList[i].id]
                                                ?.contains(d.weekday) ??
                                            false,
                                      ),
                                    ),
                                    if (d != days.last)
                                      SizedBox(
                                        width: 8,
                                        height: rowHeightForStaff(
                                          staffList[i].id,
                                        ),
                                      ),
                                  ],
                                  SizedBox(
                                    width: rightPadding,
                                    height: rowHeightForStaff(staffList[i].id),
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
                              if (i < staffList.length - 1)
                                const SizedBox(height: staffRowGap),
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
      /*bottomNavigationBar: formFactor != AppFormFactor.mobile
          ? null
          : SafeArea(
              top: false,
              bottom: true,
              minimum: const EdgeInsets.only(bottom: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AgendaHorizontalDivider(),
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: formFactor == AppFormFactor.mobile
                          ? 0
                          : staffColWidth + 8,
                      top: 15,
                      bottom: 1,
                    ),
                    child: AgendaDateSwitcher(
                      label: weekLabel,
                      selectedDate: effectivePickerDate,
                      onPreviousWeek: ref
                          .read(agendaDateProvider.notifier)
                          .previousWeek,
                      onNextWeek: ref
                          .read(agendaDateProvider.notifier)
                          .nextWeek,
                      onSelectDate: (date) {
                        ref
                            .read(agendaDateProvider.notifier)
                            .set(DateUtils.dateOnly(date));
                      },
                      useWeekRangePicker: true,
                      isCompact: true,
                    ),
                  ),
                ],
              ),
            ),*/
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
  final ScrollController _scrollController = ScrollController();
  late final List<TimeOfDay?> _times;
  late final int _scrollToIndex;

  @override
  void initState() {
    super.initState();

    // Genera lista di orari con step specificato (da 00:00 a 24:00)
    _times = <TimeOfDay?>[];
    for (int m = 0; m <= 24 * 60; m += widget.stepMinutes) {
      final h = m ~/ 60;
      final min = m % 60;
      _times.add(TimeOfDay(hour: h, minute: min));
    }

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
    const crossAxisCount = 4;
    const mainAxisSpacing = 8.0;
    const crossAxisSpacing = 8.0;
    const padding = 8.0;

    // Calcola la riga in cui si trova l'elemento selezionato
    final row = _scrollToIndex ~/ crossAxisCount;

    // Stima l'altezza di ogni cella basandosi su una larghezza ragionevole
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
            itemCount: _times.length,
            itemBuilder: (context, index) {
              final time = _times[index];
              // Se la cella è vuota, mostra uno spazio vuoto
              if (time == null) {
                return const SizedBox.shrink();
              }
              final isSelected = index == _scrollToIndex;
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
