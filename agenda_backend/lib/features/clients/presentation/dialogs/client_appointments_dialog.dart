import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/appointment.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../domain/clients.dart';
import '../../providers/clients_providers.dart';

/// Mostra il dialog con la cronologia appuntamenti del cliente.
/// Su desktop usa un AlertDialog, su tablet/mobile un modal bottom sheet.
Future<void> showClientAppointmentsDialog(
  BuildContext context,
  WidgetRef ref, {
  required Client client,
}) async {
  final formFactor = ref.read(formFactorProvider);
  ref.invalidate(clientAppointmentsProvider(client.id));

  if (formFactor == AppFormFactor.desktop) {
    await showDialog(
      context: context,
      builder: (_) => ClientAppointmentsDialog(client: client),
    );
  } else {
    await AppBottomSheet.show<void>(
      context: context,
      useRootNavigator: true,
      padding: EdgeInsets.zero,
      heightFactor: AppBottomSheet.defaultHeightFactor,
      builder: (_) => ClientAppointmentsBottomSheet(client: client),
    );
  }
}

class ClientAppointmentsDialog extends ConsumerWidget {
  const ClientAppointmentsDialog({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final asyncData = ref.watch(clientAppointmentsProvider(client.id));

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600 ? screenWidth * 0.95 : 500.0;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context, rootNavigator: true).pop(),
      },
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          title: Text(l10n.clientAppointmentsTitle(client.name)),
          content: SizedBox(
            width: dialogWidth,
            height: 400,
            child: asyncData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Errore: $e')),
              data: (data) => DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(
                          text:
                              '${l10n.clientAppointmentsUpcoming} (${data.upcoming.length})',
                        ),
                        Tab(
                          text:
                              '${l10n.clientAppointmentsPast} (${data.past.length})',
                        ),
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
                            appointments: data.upcoming,
                            emptyMessage: l10n.clientAppointmentsEmpty,
                          ),
                          _AppointmentList(
                            appointments: data.past,
                            emptyMessage: l10n.clientAppointmentsEmpty,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionClose),
            ),
          ],
        ),
      ),
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
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();

    // Recupera staff
    final allStaff = ref.watch(sortedAllStaffProvider);
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
          // Durata + prezzo
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (appointment.isCancelled)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.clientAppointmentsCancelledBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Text(
                '${appointment.totalDuration} min',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (appointment.formattedPrice.isNotEmpty)
                Text(
                  appointment.formattedPrice,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet per tablet/mobile.
class ClientAppointmentsBottomSheet extends ConsumerWidget {
  const ClientAppointmentsBottomSheet({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final asyncData = ref.watch(clientAppointmentsProvider(client.id));

    return asyncData.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(l10n.clientAppointmentsTitle(client.name)),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.clientAppointmentsTitle(client.name)),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: Center(child: Text('Errore: $e')),
      ),
      data: (data) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.clientAppointmentsTitle(client.name)),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            bottom: TabBar(
              tabs: [
                Tab(
                  text:
                      '${l10n.clientAppointmentsUpcoming} (${data.upcoming.length})',
                ),
                Tab(
                  text: '${l10n.clientAppointmentsPast} (${data.past.length})',
                ),
              ],
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
            ),
          ),
          body: TabBarView(
            children: [
              _AppointmentList(
                appointments: data.upcoming,
                emptyMessage: l10n.clientAppointmentsEmpty,
              ),
              _AppointmentList(
                appointments: data.past,
                emptyMessage: l10n.clientAppointmentsEmpty,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
