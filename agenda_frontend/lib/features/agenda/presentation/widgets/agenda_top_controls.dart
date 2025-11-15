import 'dart:math' as math;

import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/widgets/agenda_control_components.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/features/agenda/presentation/widgets/appointment_dialog.dart';
import 'package:agenda_frontend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/layout_config_provider.dart';
import 'package:agenda_frontend/features/agenda/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AgendaTopControls extends ConsumerWidget {
  const AgendaTopControls({
    super.key,
    this.externalizeAdd = false,
    this.compact = false,
  });

  /// Se true, il pulsante "Aggiungi" non viene renderizzato qui
  /// perché verrà fornito tra le AppBar actions.
  final bool externalizeAdd;

  /// Variante compatta per mobile: mostra controlli ridotti (Oggi + Data)
  final bool compact;

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
    final railInset = formFactor != AppFormFactor.mobile
        ? railWidth + railDividerWidth
        : 0.0;

    final leftInset = math.max(0.0, baseInset + railInset);

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: agendaDate,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      );
      if (picked != null) {
        dateController.set(DateUtils.dateOnly(picked));
      }
    }

    Widget buildCompactControls() {
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          IconButton(
            tooltip: l10n.agendaToday,
            icon: const Icon(Icons.today_outlined),
            iconSize: 22,
            onPressed: DateUtils.isSameDay(agendaDate, DateTime.now())
                ? null
                : dateController.setToday,
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 22),
            label: Text(formattedDate),
          ),
          const SizedBox(width: 12),
          if (locations.length > 1)
            IconButton(
              tooltip: l10n.agendaSelectLocation,
              icon: const Icon(Icons.place_outlined),
              iconSize: 22,
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return SafeArea(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final loc in locations)
                            ListTile(
                              leading: Icon(
                                loc.id == currentLocation.id
                                    ? Icons.check_circle_outline
                                    : Icons.place_outlined,
                              ),
                              title: Text(loc.name),
                              onTap: () {
                                locationController.set(loc.id);
                                Navigator.of(context).pop();
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
        ],
      );
    }

    Widget buildTabletControls() {
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          IconButton(
            tooltip: l10n.agendaToday,
            icon: const Icon(Icons.today_outlined),
            iconSize: 33,
            onPressed: DateUtils.isSameDay(agendaDate, DateTime.now())
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
          if (locations.length > 1)
            IconButton(
              tooltip: l10n.agendaSelectLocation,
              icon: const Icon(Icons.place_outlined),
              iconSize: 33,
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return SafeArea(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final loc in locations)
                            ListTile(
                              leading: const Icon(Icons.place_outlined),
                              title: Text(loc.name),
                              onTap: () {
                                locationController.set(loc.id);
                                Navigator.of(context).pop();
                              },
                              trailing: loc.id == currentLocation.id
                                  ? const Icon(Icons.check)
                                  : null,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
        ],
      );
    }

    Widget buildDesktopControls() {
      return Row(
        children: [
          AgendaRoundedButton(
            label: l10n.agendaToday,
            onTap: DateUtils.isSameDay(agendaDate, DateTime.now())
                ? null
                : dateController.setToday,
          ),
          const SizedBox(width: 16),
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
          const SizedBox(width: 16),
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
          const SizedBox(width: 16),
          const Spacer(),
          if (!externalizeAdd)
            _AddMenuButton(
              onAddAppointment: () {
                showAppointmentDialog(context, ref, date: agendaDate);
              },
            ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(start: leftInset),
      child: SizedBox(
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            debugPrint(
              'AgendaTopControls - constraints.maxWidth: ${constraints.maxWidth}, formFactor: $formFactor',
            );
            switch (formFactor) {
              case AppFormFactor.mobile:
                return buildCompactControls();
              case AppFormFactor.tablet:
                return buildTabletControls();
              case AppFormFactor.desktop:
                return buildDesktopControls();
            }
          },
        ),
      ),
    );
  }
}

class _AddMenuButton extends StatelessWidget {
  const _AddMenuButton({required this.onAddAppointment});
  final VoidCallback onAddAppointment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.agendaAdd,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'appointment',
          child: Text(l10n.agendaAddAppointment),
        ),
        PopupMenuItem(value: 'block', child: Text(l10n.agendaAddBlock)),
      ],
      onSelected: (value) {
        if (value == 'appointment') {
          onAddAppointment();
        } else if (value == 'block') {
          // Placeholder: future versions
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.agendaAddBlock)));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_outlined, size: 22),
            const SizedBox(width: 6),
            Text(l10n.agendaAdd),
          ],
        ),
      ),
    );
  }
}
