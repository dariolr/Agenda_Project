import 'dart:math' as math;

import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/widgets/agenda_control_components.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AgendaTopControls extends ConsumerWidget {
  const AgendaTopControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final agendaDate = ref.watch(agendaDateProvider);
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final locations = ref.watch(locationsProvider);
    if (locations.isEmpty) {
      return Text(l10n.agendaNoLocations);
    }
    final currentLocation = ref.watch(currentLocationProvider);
    final dateController = ref.read(agendaDateProvider.notifier);
    final locationController = ref.read(currentLocationIdProvider.notifier);

    final locale = Localizations.localeOf(context).toLanguageTag();
    final formattedDate = DateFormat('EEE d MMM', locale).format(agendaDate);

    final railTheme = NavigationRailTheme.of(context);
    final railWidth = railTheme.minWidth ?? 72.0;
    const railDividerWidth = 1.0;

    final baseInset =
        layoutConfig.hourColumnWidth - NavigationToolbar.kMiddleSpacing;
    final railInset = formFactor == AppFormFactor.tabletOrDesktop
        ? railWidth + railDividerWidth
        : 0.0;

    final leftInset = math.max(0.0, baseInset + railInset);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: leftInset),
        child: Row(
          children: [
            AgendaRoundedButton(
              label: l10n.agendaToday,
              onTap: DateUtils.isSameDay(agendaDate, DateTime.now())
                  ? null
                  : dateController.setToday,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: AgendaDateSwitcher(
                label: formattedDate,
                selectedDate: agendaDate,
                onPrevious: dateController.previousDay,
                onNext: dateController.nextDay,
                onPreviousWeek: dateController.previousWeek,
                onNextWeek: dateController.nextWeek,
                onSelectDate: (date) {
                  dateController.set(DateUtils.dateOnly(date));
                },
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AgendaLocationSelector(
                  locations: locations,
                  current: currentLocation,
                  onSelected: locationController.set,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
