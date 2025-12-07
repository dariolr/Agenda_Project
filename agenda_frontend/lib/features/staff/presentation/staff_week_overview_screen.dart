import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/widgets/staff_circle_avatar.dart';
import 'package:agenda_frontend/core/l10n/date_time_formats.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/core/widgets/app_bottom_sheet.dart';
import 'package:agenda_frontend/core/widgets/app_dialogs.dart';
import 'package:agenda_frontend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_frontend/features/agenda/domain/config/agenda_theme.dart';
import 'package:agenda_frontend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_frontend/features/staff/presentation/staff_availability_screen.dart';
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
/// the overview shape, duplicating the same weekly template for all staff
/// in the current location. This is a stopgap until per-staff persistence is available.
final weeklyStaffAvailabilityFromEditorProvider =
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

      // Build per-staff availability using their own weekly slot data
      return {
        for (final s in staffList)
          s.id: {
            for (int d = 1; d <= 7; d++)
              d: slotsToHourRanges(all[s.id]?[d] ?? const <int>{}),
          },
      };
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

    // Layout constants
    const staffColWidth = 200.0;
    final headerHeight = 60.0;
    const chipColor = Color(0xFFECEBFF);
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

    // Helper: mostra menu opzioni per una fascia oraria
    void showShiftOptionsMenu(
      int staffId,
      int weekday,
      int shiftIndex,
      HourRange range,
    ) {
      final l10n = context.l10n;
      final isMobile = formFactor == AppFormFactor.mobile;

      // Lista opzioni (senza titolo, usato da entrambe le modalità)
      Widget buildOptionsList(BuildContext ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.actionEdit),
              onTap: () {
                Navigator.pop(ctx);
                final vn = ref.read(initialStaffToEditProvider);
                vn.value = staffId;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StaffAvailabilityScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                l10n.actionDelete,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await deleteShift(staffId, weekday, shiftIndex);
              },
            ),
          ],
        );
      }

      if (isMobile) {
        // Mobile: AppBottomSheet con titolo interno
        AppBottomSheet.show(
          context: context,
          heightFactor: null, // Auto-size
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                range.label(ctx),
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              buildOptionsList(ctx),
            ],
          ),
        );
      } else {
        // Desktop/Tablet: AppFormDialog (titolo già nel dialog)
        showDialog(
          context: context,
          builder: (ctx) => AppFormDialog(
            title: Text(range.label(ctx)),
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

    Widget buildDayCell(List<HourRange> ranges, int staffId, int weekday) {
      if (ranges.isEmpty) return const SizedBox.shrink();
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
                  showShiftOptionsMenu(staffId, weekday, i, ranges[i]);
                },
                child: Container(
                  height: chipHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: chipColor,
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
                const SizedBox(width: staffColWidth),
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
                                        s.id,
                                        d.weekday,
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
