import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:agenda_backend/core/l10n/date_time_formats.dart';
import 'package:agenda_backend/core/widgets/app_dividers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/appointment.dart';
import '../../../../core/widgets/app_alternating_row.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../booking_forms/domain/customer_form_submission.dart';
import '../../../booking_forms/providers/booking_forms_provider.dart';
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

  await AppForm.show<void>(
    context: context,
    formFactor: formFactor,
    useRootNavigator: true,
    padding: EdgeInsets.zero,
    heightFactor: AppForm.defaultBottomSheetHeightFactor,
    builder: (_) => formFactor == AppFormFactor.desktop
        ? ClientAppointmentsDialog(client: client)
        : ClientAppointmentsBottomSheet(client: client),
  );
}

class ClientAppointmentsDialog extends ConsumerWidget {
  const ClientAppointmentsDialog({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final asyncData = ref.watch(clientAppointmentsProvider(client.id));
    final clientNote = client.notes?.trim();

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
                length: 4,
                child: Column(
                  children: [
                    if (clientNote != null && clientNote.isNotEmpty) ...[
                      _ClientNote(note: clientNote),
                      const SizedBox(height: 8),
                    ],
                    TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(
                          text:
                              '${l10n.clientAppointmentsUpcoming} (${data.upcoming.length})',
                        ),
                        Tab(
                          text:
                              '${l10n.clientAppointmentsPast} (${data.past.length})',
                        ),
                        Tab(
                          text:
                              '${l10n.clientAppointmentsCancelled} (${data.cancelled.length})',
                        ),
                        Tab(text: l10n.clientFormsTabLabel),
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
                          _AppointmentList(
                            appointments: data.cancelled,
                            emptyMessage: l10n.clientAppointmentsEmpty,
                          ),
                          _ClientFormsTab(clientId: client.id),
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
      separatorBuilder: (_, __) => const AppDivider(height: 1),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return AppAlternatingRow(
          index: index,
          startFromSecond: true,
          child: _AppointmentTile(appointment: appointment),
        );
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
    final appointmentNote = appointment.bookingNotes?.trim();

    // Recupera staff
    final allStaff = ref.watch(sortedAllStaffProvider);
    final staff = allStaff
        .where((s) => s.id == appointment.staffId)
        .firstOrNull;

    final dateFormat = DateFormat('EEE d MMM', locale);

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
                  DtFmt.hm(
                    context,
                    appointment.startTime.hour,
                    appointment.startTime.minute,
                  ),
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
                if (appointmentNote != null && appointmentNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _AppointmentNote(note: appointmentNote),
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
    final clientNote = client.notes?.trim();

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
        length: 4,
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
              isScrollable: true,
              tabs: [
                Tab(
                  text:
                      '${l10n.clientAppointmentsUpcoming} (${data.upcoming.length})',
                ),
                Tab(
                  text: '${l10n.clientAppointmentsPast} (${data.past.length})',
                ),
                Tab(
                  text:
                      '${l10n.clientAppointmentsCancelled} (${data.cancelled.length})',
                ),
                Tab(text: l10n.clientFormsTabLabel),
              ],
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TabBarView(
              children: [
                Column(
                  children: [
                    if (clientNote != null && clientNote.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                        child: _ClientNote(note: clientNote),
                      ),
                    Expanded(
                      child: _AppointmentList(
                        appointments: data.upcoming,
                        emptyMessage: l10n.clientAppointmentsEmpty,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    if (clientNote != null && clientNote.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                        child: _ClientNote(note: clientNote),
                      ),
                    Expanded(
                      child: _AppointmentList(
                        appointments: data.past,
                        emptyMessage: l10n.clientAppointmentsEmpty,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    if (clientNote != null && clientNote.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                        child: _ClientNote(note: clientNote),
                      ),
                    Expanded(
                      child: _AppointmentList(
                        appointments: data.cancelled,
                        emptyMessage: l10n.clientAppointmentsEmpty,
                      ),
                    ),
                  ],
                ),
                _ClientFormsTab(clientId: client.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tab di sola lettura con le risposte ai moduli per-cliente.
class _ClientFormsTab extends ConsumerWidget {
  const _ClientFormsTab({required this.clientId});

  final int clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final asyncForms = ref.watch(clientFormSubmissionsProvider(clientId));

    return asyncForms.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (submissions) {
        if (submissions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.clientFormsEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: submissions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _ClientFormCard(submission: submissions[index]),
        );
      },
    );
  }
}

class _ClientFormCard extends StatelessWidget {
  const _ClientFormCard({required this.submission});

  final CustomerFormSubmission submission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              submission.formTitle,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final answer in submission.answers)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer.fieldLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      answer.displayValue,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClientNote extends StatelessWidget {
  const _ClientNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.person_pin_outlined,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${context.l10n.clientNoteLabel}: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: note),
              ],
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppointmentNote extends StatelessWidget {
  const _AppointmentNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.sticky_note_2_outlined,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${context.l10n.appointmentNoteLabel}: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: note),
              ],
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
