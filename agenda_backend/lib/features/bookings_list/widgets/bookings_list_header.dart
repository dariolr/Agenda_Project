import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/app/providers/form_factor_provider.dart';
import '/app/widgets/agenda_control_components.dart';
import '/core/l10n/l10_extension.dart';
import '/features/agenda/providers/tenant_time_provider.dart';
import '../providers/bookings_list_filter_provider.dart';

/// Header widget for BookingsList screen with period controls only (title and refresh are in AppBar).
class BookingsListHeader extends ConsumerWidget {
  const BookingsListHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formFactor = ref.watch(formFactorProvider);
    final isCompact = formFactor != AppFormFactor.desktop;
    final filterState = ref.watch(bookingsListFilterProvider);
    final filterNotifier = ref.read(bookingsListFilterProvider.notifier);

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: _BookingsListControls(
        selectedPreset: filterState.selectedPreset,
        startDate: filterState.startDate,
        endDate: filterState.endDate,
        isCompact: isCompact,
        onPresetChanged: (preset) {
          if (preset == 'custom') {
            _showDateRangePicker(context, ref);
          } else {
            filterNotifier.applyPreset(preset);
          }
        },
        onDateRangeSelected: () => _showDateRangePicker(context, ref),
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final filterState = ref.read(bookingsListFilterProvider);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: ref.read(tenantNowProvider).add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: filterState.startDate,
        end: filterState.endDate,
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
          .read(bookingsListFilterProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }
}

class _BookingsListControls extends StatelessWidget {
  const _BookingsListControls({
    required this.selectedPreset,
    required this.startDate,
    required this.endDate,
    required this.isCompact,
    required this.onPresetChanged,
    required this.onDateRangeSelected,
  });

  final String selectedPreset;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompact;
  final ValueChanged<String> onPresetChanged;
  final VoidCallback onDateRangeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yy');

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Preset dropdown
        _PresetDropdown(value: selectedPreset, onChanged: onPresetChanged),

        // Date range display - always visible
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
                    '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
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
              value: 'today',
              child: Text(l10n.reportsPresetToday),
            ),
            DropdownMenuItem(
              value: 'month',
              child: Text(l10n.reportsPresetMonth),
            ),
            DropdownMenuItem(
              value: 'quarter',
              child: Text(l10n.reportsPresetQuarter),
            ),
            DropdownMenuItem(
              value: 'semester',
              child: Text(l10n.reportsPresetSemester),
            ),
            DropdownMenuItem(
              value: 'year',
              child: Text(l10n.reportsPresetYear),
            ),
            DropdownMenuItem(
              value: 'last_month',
              child: Text(l10n.reportsPresetLastMonth),
            ),
            DropdownMenuItem(
              value: 'last_3_months',
              child: Text(l10n.reportsPresetLast3Months),
            ),
            DropdownMenuItem(
              value: 'last_6_months',
              child: Text(l10n.reportsPresetLast6Months),
            ),
            DropdownMenuItem(
              value: 'last_year',
              child: Text(l10n.reportsPresetLastYear),
            ),
          ],
        ),
      ),
    );
  }
}
