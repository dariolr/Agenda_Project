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

class StaffTopControls extends ConsumerWidget {
  const StaffTopControls({super.key, this.todayLabel, this.labelOverride});

  /// Override opzionale per l'etichetta del pulsante "Oggi".
  final String? todayLabel;

  /// Etichetta personalizzata per la data; se valorizzata sostituisce la label calcolata.
  final String? labelOverride;

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

    // Usa una locale canonicalizzata per intl (es. it_IT) per evitare edge case
    // con i tag BCP-47 (it-IT).
    final locale = Intl.canonicalizedLocale(
      Localizations.localeOf(context).toString(),
    );
    // Etichetta: mostra il range della settimana (es. 11–17 nov)
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

    // Calcola il primo giorno della settimana (Lunedì) in modo deterministico.
    // Questo evita ambiguità legate alla locale e garantisce coerenza
    // per la vista settimanale in Italia (settimana Lun-Dom).
    final deltaToMonday = (agendaDate.weekday - DateTime.monday) % 7;
    final pickerInitialDate = DateUtils.dateOnly(
      agendaDate.subtract(Duration(days: deltaToMonday)),
    );
    // Se "oggi" ricade nella settimana corrente, usa oggi come data selezionata
    // altrimenti mantieni l'inizio settimana.
    final todayDate = DateUtils.dateOnly(DateTime.now());
    final weekStart = pickerInitialDate;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final defaultLabel = buildWeekRangeLabel(weekStart, weekEnd, locale);
    final formattedDate = labelOverride ?? defaultLabel;
    final isTodayInWeek =
        !todayDate.isBefore(weekStart) && !todayDate.isAfter(weekEnd);
    final effectivePickerDate = isTodayInWeek ? todayDate : weekEnd;

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
              label: todayLabel ?? l10n.agendaToday,
              onTap: DateUtils.isSameDay(agendaDate, DateTime.now())
                  ? null
                  : dateController.setToday,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: AgendaDateSwitcher(
                label: formattedDate,
                // Nel date picker mostriamo selezionato l'inizio settimana
                // coerente con la locale (es. Lun in it-IT).
                selectedDate: effectivePickerDate,
                useWeekRangePicker: true,
                // Frecce singole: cambio settimana
                onPrevious: dateController.previousWeek,
                onNext: dateController.nextWeek,
                // Frecce doppie: cambio mese
                onPreviousMonth: dateController.previousMonth,
                onNextMonth: dateController.nextMonth,
                onSelectDate: (date) {
                  dateController.set(DateUtils.dateOnly(date));
                },
              ),
            ),
            const SizedBox(width: 12),
            if (locations.length > 1)
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
