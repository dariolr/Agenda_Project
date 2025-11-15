import 'package:agenda_frontend/app/widgets/agenda_control_components.dart';
import 'package:agenda_frontend/app/widgets/top_controls_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StaffTopControls extends ConsumerWidget {
  const StaffTopControls({super.key, this.todayLabel, this.labelOverride});

  /// Override opzionale per l'etichetta del pulsante "Oggi".
  final String? todayLabel;

  /// Etichetta personalizzata per la data; se valorizzata sostituisce la label calcolata.
  final String? labelOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TopControlsAdaptiveBuilder(
      mobileBuilder: (context, data) => _buildStaffControlsRow(
        context,
        data,
        gapAfterToday: 10,
        gapAfterDate: 10,
      ),
      tabletBuilder: (context, data) => _buildStaffControlsRow(
        context,
        data,
        gapAfterToday: 12,
        gapAfterDate: 12,
        gapAfterLocation: 12,
      ),
      desktopBuilder: (context, data) => _buildStaffControlsRow(
        context,
        data,
        gapAfterToday: 14,
        gapAfterDate: 14,
        gapAfterLocation: 16,
      ),
    );
  }

  Widget _buildStaffControlsRow(
    BuildContext context,
    TopControlsData data, {
    double gapAfterToday = 12,
    double gapAfterDate = 12,
    double gapAfterLocation = 12,
  }) {
    final l10n = data.l10n;
    final agendaDate = data.agendaDate;
    final weekMeta = _resolveWeekMeta(data);

    final locationWidget = data.locations.length > 1
        ? Flexible(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AgendaLocationSelector(
                locations: data.locations,
                current: data.currentLocation,
                onSelected: data.locationController.set,
              ),
            ),
          )
        : null;

    return TopControlsRow(
      todayLabel: todayLabel ?? l10n.agendaToday,
      onTodayPressed: data.dateController.setToday,
      isTodayDisabled: DateUtils.isSameDay(agendaDate, DateTime.now()),
      dateSwitcherBuilder: (context) {
        return AgendaDateSwitcher(
          label: weekMeta.label,
          selectedDate: weekMeta.effectivePickerDate,
          useWeekRangePicker: true,
          onPrevious: data.dateController.previousWeek,
          onNext: data.dateController.nextWeek,
          onPreviousMonth: data.dateController.previousMonth,
          onNextMonth: data.dateController.nextMonth,
          onSelectDate: (date) {
            data.dateController.set(DateUtils.dateOnly(date));
          },
        );
      },
      locationSection: locationWidget,
      gapAfterToday: gapAfterToday,
      gapAfterDate: gapAfterDate,
      gapAfterLocation: gapAfterLocation,
    );
  }

  _StaffWeekMeta _resolveWeekMeta(TopControlsData data) {
    final agendaDate = data.agendaDate;
    final locale = Intl.canonicalizedLocale(data.locale.toString());

    String buildWeekRangeLabel(DateTime start, DateTime end, String localeTag) {
      final sameYear = start.year == end.year;
      final sameMonth = sameYear && start.month == end.month;
      if (sameMonth) {
        final d1 = DateFormat('d', localeTag).format(start);
        final d2m = DateFormat('d MMM', localeTag).format(end);
        return '$d1–$d2m';
      }
      if (sameYear) {
        final s = DateFormat('d MMM', localeTag).format(start);
        final e = DateFormat('d MMM', localeTag).format(end);
        return '$s – $e';
      }
      final s = DateFormat('d MMM y', localeTag).format(start);
      final e = DateFormat('d MMM y', localeTag).format(end);
      return '$s – $e';
    }

    final deltaToMonday = (agendaDate.weekday - DateTime.monday) % 7;
    final pickerInitialDate = DateUtils.dateOnly(
      agendaDate.subtract(Duration(days: deltaToMonday)),
    );
    final todayDate = DateUtils.dateOnly(DateTime.now());
    final weekStart = pickerInitialDate;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final defaultLabel = buildWeekRangeLabel(weekStart, weekEnd, locale);
    final formattedDate = labelOverride ?? defaultLabel;
    final isTodayInWeek =
        !todayDate.isBefore(weekStart) && !todayDate.isAfter(weekEnd);
    final effectivePickerDate = isTodayInWeek ? todayDate : weekEnd;

    return _StaffWeekMeta(
      label: formattedDate,
      effectivePickerDate: effectivePickerDate,
    );
  }
}

class _StaffWeekMeta {
  const _StaffWeekMeta({
    required this.label,
    required this.effectivePickerDate,
  });

  final String label;
  final DateTime effectivePickerDate;
}
