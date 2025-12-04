import 'package:agenda_frontend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/appointment.dart';
import '../../domain/clients.dart';
import '../../providers/clients_providers.dart';

/// Mostra il dialog con la cronologia appuntamenti del cliente.
Future<void> showClientAppointmentsDialog(
  BuildContext context,
  WidgetRef ref, {
  required Client client,
}) async {
  await showDialog(
    context: context,
    builder: (_) => ClientAppointmentsDialog(client: client),
  );
}

class ClientAppointmentsDialog extends ConsumerWidget {
  const ClientAppointmentsDialog({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final appointments = ref.watch(clientWithAppointmentsProvider(client.id));
    final now = DateTime.now();

    // Dividi in passati e futuri
    final upcoming =
        appointments.where((a) => a.startTime.isAfter(now)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final past =
        appointments
            .where((a) => a.startTime.isBefore(now) || a.startTime == now)
            .toList()
          ..sort(
            (a, b) => b.startTime.compareTo(a.startTime),
          ); // più recenti prima

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600 ? screenWidth * 0.95 : 500.0;

    return AlertDialog(
      title: Text(l10n.clientAppointmentsTitle(client.name)),
      content: SizedBox(
        width: dialogWidth,
        height: 400,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(
                    text:
                        '${l10n.clientAppointmentsUpcoming} (${upcoming.length})',
                  ),
                  Tab(text: '${l10n.clientAppointmentsPast} (${past.length})'),
                ],
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    _AppointmentList(
                      appointments: upcoming,
                      emptyMessage: l10n.clientAppointmentsEmpty,
                    ),
                    _AppointmentList(
                      appointments: past,
                      emptyMessage: l10n.clientAppointmentsEmpty,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionClose),
        ),
      ],
    );
  }
}

class _AppointmentList extends ConsumerWidget {
  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
  });

  final List<Appointment> appointments;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _AppointmentTile(appointment: appointment);
      },
    );
  }
}

class _AppointmentTile extends ConsumerWidget {
  const _AppointmentTile({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    // Recupera staff
    final allStaff = ref.watch(allStaffProvider);
    final staff = allStaff
        .where((s) => s.id == appointment.staffId)
        .firstOrNull;

    final dateFormat = DateFormat('EEE d MMM', locale);
    final timeFormat = DateFormat('HH:mm', locale);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data e ora
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(appointment.startTime),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeFormat.format(appointment.startTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Servizio e staff
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.serviceName,
                  style: theme.textTheme.bodyMedium,
                ),
                if (staff != null)
                  Text(
                    staff.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Durata
          Text(
            '${appointment.totalDuration} min',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
