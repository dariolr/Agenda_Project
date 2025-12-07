import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/widgets/agenda_control_components.dart';
import 'package:agenda_frontend/app/widgets/agenda_staff_filter_selector.dart';
import 'package:agenda_frontend/app/widgets/top_controls_scaffold.dart';
import 'package:agenda_frontend/core/models/location.dart';
import 'package:agenda_frontend/core/widgets/app_bottom_sheet.dart';
import 'package:agenda_frontend/features/staff/providers/staff_providers.dart';
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
    final formFactor = ref.watch(formFactorProvider);

    return TopControlsScaffold(
      applyLayoutInset: formFactor != AppFormFactor.mobile,
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
              await _showLocationSheet(context, data, ref);
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
              await _showLocationSheet(context, data, ref, tablet: true);
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
          if (mode == TopControlsMode.staff)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StaffLocationSelector(
                locations: data.locations,
                currentLocationId: ref.watch(staffSectionLocationIdProvider),
                onSelected:
                    ref.read(staffSectionLocationIdProvider.notifier).set,
              ),
            )
          else
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
    TopControlsData data,
    WidgetRef ref, {
    bool tablet = false,
  }) async {
    final isStaffMode = mode == TopControlsMode.staff;
    final currentStaffLocationId =
        isStaffMode ? ref.read(staffSectionLocationIdProvider) : null;

    final result = await AppBottomSheet.show<int?>(
      context: context,
      builder: (ctx) => _LocationSheetContent(
        locations: data.locations,
        currentLocationId:
            isStaffMode ? currentStaffLocationId : data.currentLocation.id,
        title: data.l10n.agendaSelectLocation,
        onSelected: (id) => Navigator.of(ctx).pop(id),
        showAllLocationsOption: isStaffMode,
        allLocationsLabel: data.l10n.allLocations,
      ),
      useRootNavigator: true,
      padding: EdgeInsets.zero,
    );

    if (result != null || (isStaffMode && result == null)) {
      if (isStaffMode) {
        ref.read(staffSectionLocationIdProvider.notifier).set(result);
      } else if (result != null) {
        data.locationController.set(result);
      }
    }
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

/// Content widget for the location bottom sheet, consistent with other dropdowns.
class _LocationSheetContent extends StatelessWidget {
  const _LocationSheetContent({
    required this.locations,
    required this.currentLocationId,
    required this.title,
    required this.onSelected,
    this.showAllLocationsOption = false,
    this.allLocationsLabel,
  });

  final List<Location> locations;
  final int? currentLocationId; // null = "Tutte le sedi" se showAllLocationsOption
  final String title;
  final ValueChanged<int?> onSelected;
  final bool showAllLocationsOption;
  final String? allLocationsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    final itemCount =
        locations.length + (showAllLocationsOption ? 1 : 0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.35)),
          Expanded(
            child: ListView.builder(
              itemCount: itemCount,
              itemBuilder: (ctx, index) {
                // Prima voce: "Tutte le sedi" se abilitato
                if (showAllLocationsOption && index == 0) {
                  final isSelected = currentLocationId == null;
                  return InkWell(
                    onTap: () => onSelected(null),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      color: isSelected
                          ? colorScheme.primary.withOpacity(0.08)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              allLocationsLabel ?? 'All locations',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                }

                final locationIndex =
                    showAllLocationsOption ? index - 1 : index;
                final loc = locations[locationIndex];
                final isSelected = loc.id == currentLocationId;
                return InkWell(
                  onTap: () => onSelected(loc.id),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    color: isSelected
                        ? colorScheme.primary.withOpacity(0.08)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            loc.name,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}
