import 'package:agenda_frontend/app/widgets/agenda_control_components.dart';
import 'package:agenda_frontend/app/widgets/agenda_staff_filter_selector.dart';
import 'package:agenda_frontend/app/widgets/top_controls_scaffold.dart';
import 'package:agenda_frontend/features/agenda/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum TopControlsMode { agenda, staff }

class TopControls extends ConsumerWidget {
  const TopControls.agenda({super.key, this.compact = false})
    : mode = TopControlsMode.agenda,
      todayLabel = null,
      labelOverride = null;

  const TopControls.staff({
    super.key,
    this.todayLabel,
    this.labelOverride,
    this.compact = false,
  }) : mode = TopControlsMode.staff;

  final TopControlsMode mode;

  final bool compact;
  final String? todayLabel;
  final String? labelOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TopControlsScaffold(
      builder: TopControlsBuilder.adaptive(
        mobile: (context, data) => _buildMobile(context, data, ref),
        tablet: (context, data) => _buildTablet(context, data, ref),
        desktop: (context, data) => _buildDesktop(context, data, ref),
      ),
    );
  }

  Widget _buildMobile(
    BuildContext context,
    TopControlsData data,
    WidgetRef ref,
  ) {
    _StaffWeekMeta? weekMeta;
    String label;
    DateTime selectedDate;
    if (mode == TopControlsMode.agenda) {
      label = _formatSingleDate(data);
      selectedDate = data.agendaDate;
    } else {
      weekMeta = _resolveWeekMeta(data);
      label = weekMeta.label;
      selectedDate = weekMeta.effectivePickerDate;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: todayLabel ?? data.l10n.agendaToday,
          icon: const Icon(Icons.today_outlined),
          iconSize: 22,
          onPressed: data.isToday ? null : data.dateController.setToday,
        ),
        const SizedBox(width: 8),
        AgendaDateSwitcher(
          label: label,
          selectedDate: selectedDate,
          onPrevious: mode == TopControlsMode.agenda
              ? data.dateController.previousDay
              : data.dateController.previousWeek,
          onNext: mode == TopControlsMode.agenda
              ? data.dateController.nextDay
              : data.dateController.nextWeek,
          onPreviousWeek: mode == TopControlsMode.agenda
              ? data.dateController.previousWeek
              : null,
          onNextWeek: mode == TopControlsMode.agenda
              ? data.dateController.nextWeek
              : null,
          onPreviousMonth: mode == TopControlsMode.agenda
              ? null
              : data.dateController.previousMonth,
          onNextMonth: mode == TopControlsMode.agenda
              ? null
              : data.dateController.nextMonth,
          onSelectDate: (date) {
            data.dateController.set(DateUtils.dateOnly(date));
          },
          useWeekRangePicker: mode == TopControlsMode.staff,
          isCompact: compact,
        ),
        const SizedBox(width: 8),
        if (data.locations.length > 1)
          IconButton(
            tooltip: data.l10n.agendaSelectLocation,
            icon: const Icon(Icons.place_outlined),
            iconSize: 22,
            onPressed: () async {
              await _showLocationSheet(context, data);
            },
          ),
        if (mode == TopControlsMode.agenda &&
            ref.watch(staffForCurrentLocationProvider).length > 1)
          const AgendaStaffFilterSelector(),
      ],
    );
  }

  Widget _buildTablet(
    BuildContext context,
    TopControlsData data,
    WidgetRef ref,
  ) {
    _StaffWeekMeta? weekMeta;
    String label;
    DateTime selectedDate;
    if (mode == TopControlsMode.agenda) {
      label = _formatSingleDate(data);
      selectedDate = data.agendaDate;
    } else {
      weekMeta = _resolveWeekMeta(data);
      label = weekMeta.label;
      selectedDate = weekMeta.effectivePickerDate;
    }
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        IconButton(
          tooltip: todayLabel ?? data.l10n.agendaToday,
          icon: const Icon(Icons.today_outlined),
          iconSize: 33,
          onPressed: data.isToday ? null : data.dateController.setToday,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: AgendaDateSwitcher(
            label: label,
            selectedDate: selectedDate,
            onPrevious: mode == TopControlsMode.agenda
                ? data.dateController.previousDay
                : data.dateController.previousWeek,
            onNext: mode == TopControlsMode.agenda
                ? data.dateController.nextDay
                : data.dateController.nextWeek,
            onPreviousWeek: mode == TopControlsMode.agenda
                ? data.dateController.previousWeek
                : null,
            onNextWeek: mode == TopControlsMode.agenda
                ? data.dateController.nextWeek
                : null,
            onPreviousMonth: mode == TopControlsMode.agenda
                ? null
                : data.dateController.previousMonth,
            onNextMonth: mode == TopControlsMode.agenda
                ? null
                : data.dateController.nextMonth,
            onSelectDate: (date) {
              data.dateController.set(DateUtils.dateOnly(date));
            },
            useWeekRangePicker: mode == TopControlsMode.staff,
          ),
        ),
        const SizedBox(width: 12),
        if (data.locations.length > 1)
          IconButton(
            tooltip: data.l10n.agendaSelectLocation,
            icon: const Icon(Icons.place_outlined),
            iconSize: 33,
            onPressed: () async {
              await _showLocationSheet(context, data, tablet: true);
            },
          ),
        if (mode == TopControlsMode.agenda &&
            ref.watch(staffForCurrentLocationProvider).length > 1)
          const AgendaStaffFilterSelector(),
      ],
    );
  }

  Widget _buildDesktop(
    BuildContext context,
    TopControlsData data,
    WidgetRef ref,
  ) {
    _StaffWeekMeta? weekMeta;
    String label;
    DateTime selectedDate;
    if (mode == TopControlsMode.agenda) {
      label = _formatSingleDate(data);
      selectedDate = data.agendaDate;
    } else {
      weekMeta = _resolveWeekMeta(data);
      label = weekMeta.label;
      selectedDate = weekMeta.effectivePickerDate;
    }
    return Row(
      children: [
        AgendaRoundedButton(
          label: todayLabel ?? data.l10n.agendaToday,
          onTap: data.isToday ? null : data.dateController.setToday,
        ),
        const SizedBox(width: 16),
        Flexible(
          child: AgendaDateSwitcher(
            label: label,
            selectedDate: selectedDate,
            onPrevious: mode == TopControlsMode.agenda
                ? data.dateController.previousDay
                : data.dateController.previousWeek,
            onNext: mode == TopControlsMode.agenda
                ? data.dateController.nextDay
                : data.dateController.nextWeek,
            onPreviousWeek: data.dateController.previousWeek,
            onNextWeek: data.dateController.nextWeek,
            onPreviousMonth: mode == TopControlsMode.agenda
                ? null
                : data.dateController.previousMonth,
            onNextMonth: mode == TopControlsMode.agenda
                ? null
                : data.dateController.nextMonth,
            onSelectDate: (date) {
              data.dateController.set(DateUtils.dateOnly(date));
            },
            useWeekRangePicker: mode == TopControlsMode.staff,
          ),
        ),
        const SizedBox(width: 16),
        if (data.locations.length > 1) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AgendaLocationSelector(
              locations: data.locations,
              current: data.currentLocation,
              onSelected: data.locationController.set,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (mode == TopControlsMode.agenda &&
            ref.watch(staffForCurrentLocationProvider).length > 1)
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: AgendaStaffFilterSelector(isCompact: false),
          ),
      ],
    );
  }

  String _formatSingleDate(TopControlsData data) {
    final localeTag = data.locale.toLanguageTag();
    return DateFormat('EEE d MMM', localeTag).format(data.agendaDate);
  }

  Future<void> _showLocationSheet(
    BuildContext context,
    TopControlsData data, {
    bool tablet = false,
  }) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final loc in data.locations)
                ListTile(
                  leading: tablet
                      ? const Icon(Icons.place_outlined)
                      : Icon(
                          loc.id == data.currentLocation.id
                              ? Icons.check_circle_outline
                              : Icons.place_outlined,
                        ),
                  title: Text(loc.name),
                  onTap: () {
                    data.locationController.set(loc.id);
                    Navigator.of(context).pop();
                  },
                  trailing: tablet && loc.id == data.currentLocation.id
                      ? const Icon(Icons.check)
                      : null,
                ),
            ],
          ),
        );
      },
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
