import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/theme/app_spacing.dart';
import 'package:agenda_frontend/core/l10n/date_time_formats.dart';
import 'package:agenda_frontend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/appointment.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../clients/domain/clients.dart';
import '../../../clients/presentation/dialogs/client_edit_dialog.dart';
import '../../../clients/providers/clients_providers.dart';
import '../../../services/providers/service_categories_provider.dart';
import '../../../services/providers/services_provider.dart';
import '../../domain/service_item_data.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/date_range_provider.dart';
import 'service_item_card.dart';

/// Show the Appointment dialog for creating or editing an appointment.
Future<void> showAppointmentDialog(
  BuildContext context,
  WidgetRef ref, {
  Appointment? initial,
  DateTime? date,
  TimeOfDay? time,
  int? initialStaffId,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final presentation = formFactor == AppFormFactor.desktop
      ? _AppointmentPresentation.dialog
      : _AppointmentPresentation.bottomSheet;

  final content = _AppointmentDialog(
    initial: initial,
    initialDate: date,
    initialTime: time,
    initialStaffId: initialStaffId,
    presentation: presentation,
  );

  if (presentation == _AppointmentPresentation.dialog) {
    await showDialog(context: context, builder: (_) => content);
  } else {
    await AppBottomSheet.show(
      context: context,
      useRootNavigator: true,
      builder: (_) => content,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      heightFactor: AppBottomSheet.defaultHeightFactor,
    );
  }
}

enum _AppointmentPresentation { dialog, bottomSheet }

class _AppointmentDialog extends ConsumerStatefulWidget {
  const _AppointmentDialog({
    this.initial,
    this.initialDate,
    this.initialTime,
    this.initialStaffId,
    required this.presentation,
  });

  final Appointment? initial;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int? initialStaffId;
  final _AppointmentPresentation presentation;

  @override
  ConsumerState<_AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends ConsumerState<_AppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  late DateTime _date;
  int? _clientId;
  String _clientName = '';

  /// ServiceItemData per il singolo servizio dell'appuntamento
  late ServiceItemData _serviceItem;

  @override
  void initState() {
    super.initState();
    final agendaDate = ref.read(agendaDateProvider);

    if (widget.initial != null) {
      final appt = widget.initial!;
      _date = DateTime(
        appt.startTime.year,
        appt.startTime.month,
        appt.startTime.day,
      );
      _clientId = appt.clientId;
      _clientName = appt.clientName;
      // Leggi le note dalla Booking associata
      final booking = ref.read(bookingsProvider)[appt.bookingId];
      _notesController.text = booking?.notes ?? '';
      // Inizializza ServiceItemData dall'appuntamento esistente
      _serviceItem = ServiceItemData(
        key: '0',
        startTime: TimeOfDay(
          hour: appt.startTime.hour,
          minute: appt.startTime.minute,
        ),
        staffId: appt.staffId,
        serviceId: appt.serviceId,
        serviceVariantId: appt.serviceVariantId,
        durationMinutes: appt.endTime.difference(appt.startTime).inMinutes,
      );
    } else {
      _date = DateUtils.dateOnly(widget.initialDate ?? agendaDate);
      final initialTime =
          widget.initialTime ?? const TimeOfDay(hour: 10, minute: 0);
      _serviceItem = ServiceItemData(
        key: '0',
        startTime: initialTime,
        staffId: widget.initialStaffId,
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.initial != null;
    final isDialog = widget.presentation == _AppointmentPresentation.dialog;

    final formFactor = ref.watch(formFactorProvider);
    final services = ref.watch(servicesProvider);
    final serviceCategories = ref.watch(serviceCategoriesProvider);
    final variants = ref.watch(serviceVariantsProvider);
    final clients = ref.watch(clientsProvider);
    final staff = ref.watch(staffForCurrentLocationProvider);

    // Get eligible staff for the selected service
    final eligibleStaffIds = _serviceItem.serviceId != null
        ? ref.watch(eligibleStaffForServiceProvider(_serviceItem.serviceId!))
        : <int>[];

    // Conta gli appuntamenti nella stessa prenotazione (per mostrare/nascondere "Elimina prenotazione")
    final bookingAppointmentsCount = isEdit
        ? ref
              .watch(appointmentsProvider)
              .where((a) => a.bookingId == widget.initial!.bookingId)
              .length
        : 0;

    final title = isEdit
        ? l10n.appointmentDialogTitleEdit
        : l10n.appointmentDialogTitleNew;

    // Il campo cliente è bloccato se in modalità edit e l'appuntamento
    // aveva già un cliente associato (clientId != null)
    final isClientLocked = isEdit && widget.initial!.clientId != null;

    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.formFirstRowSpacing),
          // Client selection (first)
          _ClientSelectionField(
            clientId: _clientId,
            clientName: _clientName,
            clients: clients,
            isLocked: isClientLocked,
            onClientSelected: (id, name) {
              setState(() {
                _clientId = id;
                _clientName = name;
              });
            },
            onClientRemoved: () {
              setState(() {
                _clientId = null;
                _clientName = '';
              });
            },
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          // Date
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.formDate,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                isDense: true,
              ),
              child: Text(DtFmt.shortDate(context, _date)),
            ),
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          // Service item card (come in booking_dialog)
          ServiceItemCard(
            index: 0,
            item: _serviceItem,
            services: services.cast(),
            categories: serviceCategories.cast(),
            variants: variants.cast(),
            eligibleStaff: eligibleStaffIds,
            allStaff: staff.cast(),
            formFactor: formFactor,
            canRemove: false,
            isServiceRequired: true,
            onChanged: (updated) {
              setState(() => _serviceItem = updated);
            },
            onRemove: () {},
            onStartTimeChanged: (time) {
              setState(() {
                _serviceItem = _serviceItem.copyWith(startTime: time);
              });
            },
            onEndTimeChanged: (time) {
              // Calcola nuova durata
              final startMinutes =
                  _serviceItem.startTime.hour * 60 +
                  _serviceItem.startTime.minute;
              final endMinutes = time.hour * 60 + time.minute;
              final newDuration = endMinutes - startMinutes;
              if (newDuration > 0) {
                setState(() {
                  _serviceItem = _serviceItem.copyWith(
                    durationMinutes: newDuration,
                  );
                });
              }
            },
            onDurationChanged: (duration) {
              setState(() {
                _serviceItem = _serviceItem.copyWith(durationMinutes: duration);
              });
            },
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          // Notes field
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: l10n.formNotes,
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            maxLines: 3,
            minLines: 2,
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
        ],
      ),
    );

    final actions = [
      if (widget.initial != null) ...[
        // "Aggiungi alla prenotazione" abilitato solo se la data è la stessa
        () {
          final originalDate = DateUtils.dateOnly(widget.initial!.startTime);
          final isSameDate = _date == originalDate;
          return AppOutlinedActionButton(
            onPressed: isSameDate
                ? () {
                    final variants = ref.read(serviceVariantsProvider);
                    final services = ref.read(servicesProvider);
                    final serviceId =
                        _serviceItem.serviceId ?? widget.initial!.serviceId;
                    final selectedVariant = variants.firstWhere(
                      (v) => v.serviceId == serviceId,
                      orElse: () => variants.first,
                    );
                    final service = services.firstWhere(
                      (s) => s.id == serviceId,
                    );

                    final start = DateTime(
                      _date.year,
                      _date.month,
                      _date.day,
                      _serviceItem.startTime.hour,
                      _serviceItem.startTime.minute,
                    );
                    final duration = _serviceItem.durationMinutes > 0
                        ? _serviceItem.durationMinutes
                        : selectedVariant.durationMinutes;
                    final end = start.add(Duration(minutes: duration));

                    ref
                        .read(appointmentsProvider.notifier)
                        .addAppointment(
                          bookingId: widget.initial!.bookingId,
                          staffId:
                              _serviceItem.staffId ?? widget.initial!.staffId,
                          serviceId: service.id,
                          serviceVariantId: selectedVariant.id,
                          clientId: widget.initial!.clientId,
                          clientName: widget.initial!.clientName,
                          serviceName: service.name,
                          start: start,
                          end: end,
                          price: selectedVariant.price,
                        );
                    Navigator.of(context).pop();
                  }
                : null,
            child: Text(l10n.actionAddToBooking),
          );
        }(),
      ],
      if (widget.initial != null)
        AppDangerButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(l10n.deleteAppointmentConfirmTitle),
                content: Text(l10n.deleteAppointmentConfirmMessage),
                actions: [
                  AppOutlinedActionButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.actionCancel),
                  ),
                  AppDangerButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.actionDelete),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              ref
                  .read(appointmentsProvider.notifier)
                  .deleteAppointment(widget.initial!.id);
              if (context.mounted) Navigator.of(context).pop();
            }
          },
          child: Text(l10n.actionDelete),
        ),
      // Mostra "Elimina prenotazione" solo se la booking ha più di un appuntamento
      if (widget.initial != null && bookingAppointmentsCount > 1)
        AppDangerButton(
          onPressed: () async {
            // Recupera gli altri appuntamenti della prenotazione (escluso quello corrente)
            final bookingAppointments =
                ref
                    .read(appointmentsProvider)
                    .where(
                      (a) =>
                          a.bookingId == widget.initial!.bookingId &&
                          a.id != widget.initial!.id,
                    )
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));

            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.deleteBookingConfirmTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.deleteBookingConfirmMessage),
                    if (bookingAppointments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.otherServicesInBooking,
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...bookingAppointments.map(
                        (appt) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text(
                                DtFmt.hm(
                                  context,
                                  appt.startTime.hour,
                                  appt.startTime.minute,
                                ),
                                style: Theme.of(ctx).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appt.serviceName,
                                  style: Theme.of(ctx).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  AppOutlinedActionButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.actionCancel),
                  ),
                  AppDangerButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.actionDeleteBooking),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              ref
                  .read(bookingsProvider.notifier)
                  .deleteBooking(widget.initial!.bookingId);
              if (context.mounted) Navigator.of(context).pop();
            }
          },
          child: Text(l10n.actionDeleteBooking),
        ),
      AppOutlinedActionButton(
        onPressed: () => Navigator.of(context).pop(),
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionCancel),
      ),
      AppFilledButton(
        onPressed: _onSave,
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionSave),
      ),
    ];

    if (isDialog) {
      return DismissibleDialog(
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Flexible(child: content),
                  const SizedBox(height: AppSpacing.formToActionsSpacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions[i],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final bottomActions = actions
        .map(
          (a) => SizedBox(width: AppButtonStyles.dialogButtonWidth, child: a),
        )
        .toList();

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            content,
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: bottomActions,
              ),
            ),
            SizedBox(height: 32 + MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }

  void _onSave() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    if (_serviceItem.serviceId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.validationRequired)));
      return;
    }
    if (_serviceItem.staffId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.validationRequired)));
      return;
    }

    final variants = ref.read(serviceVariantsProvider);
    final services = ref.read(servicesProvider);

    final selectedVariant = variants.firstWhere(
      (v) => v.serviceId == _serviceItem.serviceId,
      orElse: () => variants.first,
    );
    final service = services.firstWhere((s) => s.id == _serviceItem.serviceId);

    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _serviceItem.startTime.hour,
      _serviceItem.startTime.minute,
    );

    // Usa la durata corrente del form (che preserva eventuali modifiche)
    final duration = _serviceItem.durationMinutes > 0
        ? _serviceItem.durationMinutes
        : selectedVariant.durationMinutes;
    final end = start.add(Duration(minutes: duration));

    // Client info (può essere null se nessun cliente è associato)
    final int? clientId = _clientId;
    final String clientName = _clientName.trim();
    final String? notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    if (widget.initial == null) {
      // Nuovo appuntamento: crea SEMPRE una nuova prenotazione
      final newAppt = ref
          .read(appointmentsProvider.notifier)
          .addAppointment(
            bookingId: null,
            staffId: _serviceItem.staffId!,
            serviceId: service.id,
            serviceVariantId: selectedVariant.id,
            clientId: clientId,
            clientName: clientName,
            serviceName: service.name,
            start: start,
            end: end,
            price: selectedVariant.price,
          );
      // Salva le note nella booking appena creata
      if (notes != null && notes.isNotEmpty) {
        ref.read(bookingsProvider.notifier).setNotes(newAppt.bookingId, notes);
      }
    } else {
      // Verifica se il cliente è stato aggiunto (era null e ora non lo è)
      final initialClientId = widget.initial!.clientId;
      final clientWasAdded = initialClientId == null && clientId != null;

      // Se il cliente è stato aggiunto, verifica se ci sono altri appuntamenti
      // nella stessa prenotazione che devono essere aggiornati
      if (clientWasAdded) {
        final bookingId = widget.initial!.bookingId;
        final otherAppointments = ref
            .read(appointmentsProvider.notifier)
            .getByBookingId(bookingId)
            .where((a) => a.id != widget.initial!.id)
            .toList();

        // Se ci sono altri appuntamenti, chiedi conferma
        if (otherAppointments.isNotEmpty && mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l10n.applyClientToAllAppointmentsTitle),
              content: Text(
                l10n.applyClientToAllAppointmentsMessage(
                  otherAppointments.length,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.actionCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.actionConfirm),
                ),
              ],
            ),
          );

          if (confirmed != true) {
            // Utente ha annullato, non salvare
            return;
          }

          // Aggiorna il cliente su tutti gli appuntamenti della prenotazione
          ref
              .read(appointmentsProvider.notifier)
              .updateClientForBooking(
                bookingId: bookingId,
                clientId: clientId,
                clientName: clientName,
              );

          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }
      }

      // Aggiornamento normale (singolo appuntamento)
      final updated = widget.initial!.copyWith(
        staffId: _serviceItem.staffId!,
        serviceId: service.id,
        serviceVariantId: selectedVariant.id,
        clientId: clientId,
        clientName: clientName,
        serviceName: service.name,
        startTime: start,
        endTime: end,
        price: selectedVariant.price,
      );
      ref.read(appointmentsProvider.notifier).updateAppointment(updated);
      // Aggiorna le note nella booking associata
      ref
          .read(bookingsProvider.notifier)
          .setNotes(widget.initial!.bookingId, notes);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _ClientItem {
  final int id;
  final String name;
  const _ClientItem(this.id, this.name);
}

/// Widget per la selezione del cliente con link cliccabile e hint
class _ClientSelectionField extends ConsumerWidget {
  const _ClientSelectionField({
    required this.clientId,
    required this.clientName,
    required this.clients,
    required this.onClientSelected,
    required this.onClientRemoved,
    this.isLocked = false,
  });

  final int? clientId;
  final String clientName;
  final List<Client> clients;
  final void Function(int? id, String name) onClientSelected;
  final VoidCallback onClientRemoved;
  final bool isLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasClient = clientId != null || clientName.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.formClient,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        if (hasClient)
          _SelectedClientTile(
            clientName: clientName,
            onTap: isLocked ? null : () => _showClientPicker(context, ref),
            onRemove: isLocked ? null : onClientRemoved,
          )
        else
          InkWell(
            onTap: isLocked ? null : () => _showClientPicker(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isLocked
                      ? theme.colorScheme.outline.withOpacity(0.5)
                      : theme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 20,
                    color: isLocked
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.addClientToAppointment,
                    style: TextStyle(
                      color: isLocked
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          isLocked ? l10n.clientLockedHint : l10n.clientOptionalHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _showClientPicker(BuildContext context, WidgetRef ref) async {
    while (true) {
      final result = await AppBottomSheet.show<_ClientItem?>(
        context: context,
        useRootNavigator: true,
        padding: EdgeInsets.zero,
        heightFactor: AppBottomSheet.defaultHeightFactor,
        builder: (ctx) =>
            _ClientPickerSheet(clients: clients, selectedClientId: clientId),
      );
      if (result == null) {
        // Sheet dismissed without selection, do nothing
        return;
      }
      if (result.id == -2) {
        // "Create new client" was selected
        // result.name contains the search query to pre-populate the form
        if (context.mounted) {
          Client? initialClient;
          if (result.name.isNotEmpty) {
            // Split the search query into first name and last name
            final nameParts = Client.splitFullName(result.name);
            initialClient = Client(
              id: 0,
              businessId: 0,
              firstName: nameParts.firstName,
              lastName: nameParts.lastName,
              createdAt: DateTime.now(),
            );
          }
          final newClient = await showClientEditDialog(
            context,
            ref,
            client: initialClient,
          );
          if (newClient != null) {
            // Client saved, select it and return to appointment form
            onClientSelected(newClient.id, newClient.name);
            return;
          }
          // Client creation cancelled, loop back to show picker again
          continue;
        }
        return;
      } else if (result.id == -1) {
        // "No client for appointment" was selected
        onClientRemoved();
        return;
      } else {
        onClientSelected(result.id, result.name);
        return;
      }
    }
  }
}

/// Tile che mostra il cliente selezionato con opzione per rimuoverlo
class _SelectedClientTile extends StatelessWidget {
  const _SelectedClientTile({
    required this.clientName,
    this.onTap,
    this.onRemove,
  });

  final String clientName;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = onTap == null && onRemove == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isLocked
                ? theme.colorScheme.outline.withOpacity(0.5)
                : theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isLocked ? theme.colorScheme.surfaceContainerLow : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                clientName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isLocked ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
            if (onRemove != null)
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                onPressed: onRemove,
                tooltip: context.l10n.removeClient,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              )
            else if (isLocked)
              Icon(
                Icons.lock_outline,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet per la selezione del cliente
class _ClientPickerSheet extends ConsumerStatefulWidget {
  const _ClientPickerSheet({required this.clients, this.selectedClientId});

  final List<Client> clients;
  final int? selectedClientId;

  @override
  ConsumerState<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends ConsumerState<_ClientPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Client> get _filteredClients {
    // Use live clients from provider to get updates after creation
    final clients = ref.watch(clientsProvider);
    if (_searchQuery.isEmpty) return clients;
    final q = _searchQuery.toLowerCase();
    return clients.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectClientTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.formFirstRowSpacing),
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchClientPlaceholder,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim());
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Quick actions: Create new client / No client
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person_add_outlined,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Text(l10n.createNewClient),
            onTap: () {
              // Use special marker with id = -2 to indicate "create new client"
              // Pass search query in name field to pre-populate the form
              Navigator.of(context).pop(_ClientItem(-2, _searchQuery));
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person_off_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            title: Text(l10n.noClientForAppointment),
            onTap: () {
              // Use special marker with id = -1 to indicate "no client"
              Navigator.of(context).pop(const _ClientItem(-1, ''));
            },
          ),
          const Divider(height: 1),
          // Client list
          Expanded(
            child: _filteredClients.isEmpty
                ? Center(
                    child: Text(
                      l10n.clientsEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: _filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = _filteredClients[index];
                      final isSelected = client.id == widget.selectedClientId;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                          child: Text(
                            client.name.isNotEmpty
                                ? client.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(client.name),
                        subtitle: client.phone != null
                            ? Text(
                                client.phone!,
                                style: theme.textTheme.bodySmall,
                              )
                            : null,
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pop(_ClientItem(client.id, client.name));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
