import 'package:agenda_frontend/app/widgets/agenda_control_components.dart';
import 'package:agenda_frontend/app/widgets/top_controls_scaffold.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/features/agenda/presentation/widgets/appointment_dialog.dart';
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
    Future<void> pickDate(BuildContext context, TopControlsData data) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: data.agendaDate,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      );
      if (picked != null) {
        data.dateController.set(DateUtils.dateOnly(picked));
      }
    }

    return TopControlsAdaptiveBuilder(
      expandToWidth: true,
      logConstraints: true,
      debugLabel: 'AgendaTopControls',
      mobileBuilder: (context, data) {
        final l10n = data.l10n;
        final agendaDate = data.agendaDate;
        final formattedDate = DateFormat(
          'EEE d MMM',
          data.locale.toLanguageTag(),
        ).format(agendaDate);
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              tooltip: l10n.agendaToday,
              icon: const Icon(Icons.today_outlined),
              iconSize: 22,
              onPressed: DateUtils.isSameDay(agendaDate, DateTime.now())
                  ? null
                  : data.dateController.setToday,
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => pickDate(context, data),
              icon: const Icon(Icons.calendar_today_outlined, size: 22),
              label: Text(formattedDate),
            ),
            const SizedBox(width: 12),
            if (data.locations.length > 1)
              IconButton(
                tooltip: l10n.agendaSelectLocation,
                icon: const Icon(Icons.place_outlined),
                iconSize: 22,
                onPressed: () async {
                  await _showLocationSheet(context, data);
                },
              ),
          ],
        );
      },
      tabletBuilder: (context, data) {
        final l10n = data.l10n;
        final agendaDate = data.agendaDate;
        final formattedDate = DateFormat(
          'EEE d MMM',
          data.locale.toLanguageTag(),
        ).format(agendaDate);
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              tooltip: l10n.agendaToday,
              icon: const Icon(Icons.today_outlined),
              iconSize: 33,
              onPressed: DateUtils.isSameDay(agendaDate, DateTime.now())
                  ? null
                  : data.dateController.setToday,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: AgendaDateSwitcher(
                label: formattedDate,
                selectedDate: agendaDate,
                onPrevious: data.dateController.previousDay,
                onNext: data.dateController.nextDay,
                onPreviousWeek: data.dateController.previousWeek,
                onNextWeek: data.dateController.nextWeek,
                onSelectDate: (date) {
                  data.dateController.set(DateUtils.dateOnly(date));
                },
              ),
            ),
            const SizedBox(width: 12),
            if (data.locations.length > 1)
              IconButton(
                tooltip: l10n.agendaSelectLocation,
                icon: const Icon(Icons.place_outlined),
                iconSize: 33,
                onPressed: () async {
                  await _showLocationSheet(context, data, tablet: true);
                },
              ),
          ],
        );
      },
      desktopBuilder: (context, data) {
        final l10n = data.l10n;
        final agendaDate = data.agendaDate;
        final formattedDate = DateFormat(
          'EEE d MMM',
          data.locale.toLanguageTag(),
        ).format(agendaDate);
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
        final trailing = <Widget>[
          const Spacer(),
          if (!externalizeAdd)
            _AddMenuButton(
              onAddAppointment: () {
                showAppointmentDialog(context, ref, date: agendaDate);
              },
            ),
        ];
        return TopControlsRow(
          todayLabel: l10n.agendaToday,
          onTodayPressed: data.dateController.setToday,
          isTodayDisabled: DateUtils.isSameDay(agendaDate, DateTime.now()),
          dateSwitcherBuilder: (context) {
            return AgendaDateSwitcher(
              label: formattedDate,
              selectedDate: agendaDate,
              onPrevious: data.dateController.previousDay,
              onNext: data.dateController.nextDay,
              onPreviousWeek: data.dateController.previousWeek,
              onNextWeek: data.dateController.nextWeek,
              onSelectDate: (date) {
                data.dateController.set(DateUtils.dateOnly(date));
              },
            );
          },
          locationSection: locationWidget,
          trailing: trailing,
          gapAfterToday: 12,
          gapAfterDate: 12,
          gapAfterLocation: 12,
        );
      },
    );
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
