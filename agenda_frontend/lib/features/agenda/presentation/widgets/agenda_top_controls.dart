import 'package:agenda_frontend/app/widgets/agenda_control_components.dart';
import 'package:agenda_frontend/core/l10n/l10_extension.dart';
import 'package:agenda_frontend/features/agenda/providers/date_range_provider.dart';
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
    final locations = ref.watch(locationsProvider);
    if (locations.isEmpty) {
      return Text(l10n.agendaNoLocations);
    }
    final currentLocation = ref.watch(currentLocationProvider);
    final dateController = ref.read(agendaDateProvider.notifier);
    final locationController = ref.read(currentLocationIdProvider.notifier);

    final locale = Localizations.localeOf(context).toLanguageTag();
    final formattedDate = DateFormat('EEE d MMM', locale).format(agendaDate);

    return Row(
      children: [
        AgendaRoundedButton(
          label: l10n.agendaToday,
          onTap: dateController.setToday,
        ),
        const SizedBox(width: 12),
        AgendaDateSwitcher(
          label: formattedDate,
          onPrevious: dateController.previousDay,
          onNext: dateController.nextDay,
        ),
        const SizedBox(width: 12),
        AgendaLocationSelector(
          locations: locations,
          current: currentLocation,
          onSelected: locationController.set,
        ),
      ],
    );
  }
}
