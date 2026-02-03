import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/app/widgets/agenda_control_components.dart';
import '/core/l10n/l10_extension.dart';
import '/core/models/location.dart';
import '/features/agenda/providers/location_providers.dart';
import '../providers/closures_filter_provider.dart';
import '../providers/location_closures_provider.dart';

/// Header widget for Closures screen with period controls.
class ClosuresHeader extends ConsumerWidget {
  const ClosuresHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filterState = ref.watch(closuresFilterProvider);
    final filterNotifier = ref.read(closuresFilterProvider.notifier);

    // Location data
    final locations = ref.watch(locationsProvider);
    final currentLocation = ref.watch(currentLocationProvider);
    final showLocationSelector = locations.length > 1;

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: _ClosuresControls(
        selectedPreset: filterState.selectedPreset,
        startDate: filterState.startDate,
        endDate: filterState.endDate,
        onPresetChanged: (preset) {
          if (preset == 'custom') {
            _showDateRangePicker(context, ref);
          } else {
            filterNotifier.applyPreset(preset);
          }
        },
        onDateRangeSelected: () => _showDateRangePicker(context, ref),
        // Location selector props
        showLocationSelector: showLocationSelector,
        locations: locations,
        currentLocation: currentLocation,
        onLocationSelected: (id) {
          ref.read(currentLocationIdProvider.notifier).set(id);
          // Refresh closures after location change
          ref.invalidate(locationClosuresProvider);
        },
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final filterState = ref.read(closuresFilterProvider);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      initialDateRange: DateTimeRange(
        start: filterState.startDate,
        end:
            filterState.endDate.isBefore(
              DateTime.now().add(const Duration(days: 365)),
            )
            ? filterState.endDate
            : DateTime.now().add(const Duration(days: 365)),
      ),
      saveText: l10n.actionApply,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: colorScheme.copyWith(
              onPrimary: colorScheme.onPrimary,
              onSurface: colorScheme.onSurface,
            ),
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: colorScheme.primary.withOpacity(
                0.2,
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colorScheme.onPrimary;
                }
                if (states.contains(WidgetState.disabled)) {
                  return colorScheme.onSurface.withOpacity(0.38);
                }
                return colorScheme.onSurface;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colorScheme.primary;
                }
                return null;
              }),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(closuresFilterProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }
}

class _ClosuresControls extends StatelessWidget {
  const _ClosuresControls({
    required this.selectedPreset,
    required this.startDate,
    required this.endDate,
    required this.onPresetChanged,
    required this.onDateRangeSelected,
    required this.showLocationSelector,
    required this.locations,
    required this.currentLocation,
    required this.onLocationSelected,
  });

  final String selectedPreset;
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<String> onPresetChanged;
  final VoidCallback onDateRangeSelected;
  final bool showLocationSelector;
  final List<Location> locations;
  final Location currentLocation;
  final void Function(int) onLocationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yy');

    // For "from_today", show only start date
    final showEndDate = selectedPreset != 'from_today';

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Location selector only if multiple locations
        if (showLocationSelector)
          AgendaLocationSelector(
            locations: locations,
            current: currentLocation,
            onSelected: onLocationSelected,
          ),
        // Preset dropdown
        _PresetDropdown(value: selectedPreset, onChanged: onPresetChanged),

        // Date range display - only show when not "from_today"
        if (selectedPreset == 'custom' ||
            selectedPreset == 'year' ||
            selectedPreset == 'last_year')
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDateRangeSelected,
              borderRadius: kAgendaPillRadius,
              child: Container(
                height: kAgendaControlHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: kAgendaControlHorizontalPadding,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.35)),
                  borderRadius: kAgendaPillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      showEndDate
                          ? '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}'
                          : dateFormat.format(startDate),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PresetDropdown extends StatelessWidget {
  const _PresetDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      height: kAgendaControlHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: kAgendaControlHorizontalPadding,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.35)),
        borderRadius: kAgendaPillRadius,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down),
          style: theme.textTheme.bodyMedium,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: [
            DropdownMenuItem(
              value: 'custom',
              child: Text(l10n.reportsPresetCustom),
            ),
            DropdownMenuItem(
              value: 'from_today',
              child: Text(l10n.closuresFilterFromToday),
            ),
            DropdownMenuItem(
              value: 'year',
              child: Text(l10n.reportsPresetYear),
            ),
            DropdownMenuItem(
              value: 'last_year',
              child: Text(l10n.reportsPresetLastYear),
            ),
            DropdownMenuItem(value: 'all', child: Text(l10n.closuresFilterAll)),
          ],
        ),
      ),
    );
  }
}
