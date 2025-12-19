import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/theme/app_spacing.dart';
import 'package:agenda_frontend/core/l10n/date_time_formats.dart';
import 'package:agenda_frontend/core/widgets/labeled_form_field.dart';
import 'package:agenda_frontend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_frontend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/booking.dart';
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

/// Show the Booking dialog for creating a new multi-service booking.
Future<void> showBookingDialog(
  BuildContext context,
  WidgetRef ref, {
  Booking? existing,
  DateTime? date,
  TimeOfDay? time,
  int? initialStaffId,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final presentation = formFactor == AppFormFactor.desktop
      ? _BookingPresentation.dialog
      : _BookingPresentation.bottomSheet;

  final content = _BookingDialog(
    existing: existing,
    initialDate: date,
    initialTime: time,
    initialStaffId: initialStaffId,
    presentation: presentation,
  );

  if (presentation == _BookingPresentation.dialog) {
    await showDialog(
      context: context,
      builder: (_) => content,
      barrierDismissible: false,
    );
  } else {
    await AppBottomSheet.show(
      context: context,
      useRootNavigator: true,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      builder: (_) => content,
      heightFactor: AppBottomSheet.defaultHeightFactor,
    );
  }
}

enum _BookingPresentation { dialog, bottomSheet }

class _BookingDialog extends ConsumerStatefulWidget {
  const _BookingDialog({
    this.existing,
    this.initialDate,
    this.initialTime,
    this.initialStaffId,
    required this.presentation,
  });

  final Booking? existing;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int? initialStaffId;
  final _BookingPresentation presentation;

  @override
  ConsumerState<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends ConsumerState<_BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  late DateTime _date;
  int? _clientId;

  /// Nome cliente personalizzato (usato solo per clienti nuovi non ancora salvati)
  String _customClientName = '';

  /// Lista di servizi nella prenotazione
  final List<ServiceItemData> _serviceItems = [];

  /// Contatore per generare chiavi univoche
  int _itemKeyCounter = 0;

  @override
  void initState() {
    super.initState();
    final agendaDate = ref.read(agendaDateProvider);

    if (widget.existing != null) {
      // Editing existing booking
      _date = DateUtils.dateOnly(widget.initialDate ?? agendaDate);
      _notesController.text = widget.existing!.notes ?? '';
      _clientId = widget.existing!.clientId;
      _customClientName = widget.existing!.customerName ?? '';

      // Load existing appointments into _serviceItems
      final bookingAppointments = ref
          .read(appointmentsProvider.notifier)
          .getByBookingId(widget.existing!.id);

      for (final appointment in bookingAppointments) {
        _serviceItems.add(
          ServiceItemData(
            key: _nextItemKey(),
            startTime: TimeOfDay.fromDateTime(appointment.startTime),
            staffId: appointment.staffId,
            serviceId: appointment.serviceId,
            serviceVariantId: appointment.serviceVariantId,
            durationMinutes: appointment.endTime
                .difference(appointment.startTime)
                .inMinutes,
          ),
        );
      }

      // Se non ci sono appointments, aggiungi un item vuoto
      if (_serviceItems.isEmpty) {
        final initialTime =
            widget.initialTime ?? const TimeOfDay(hour: 10, minute: 0);
        _serviceItems.add(
          ServiceItemData(key: _nextItemKey(), startTime: initialTime),
        );
      }
    } else {
      _date = DateUtils.dateOnly(widget.initialDate ?? agendaDate);

      // Aggiungi un primo servizio vuoto
      final initialTime =
          widget.initialTime ?? const TimeOfDay(hour: 10, minute: 0);
      _serviceItems.add(
        ServiceItemData(
          key: _nextItemKey(),
          startTime: initialTime,
          staffId: widget.initialStaffId,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _nextItemKey() => 'item_${_itemKeyCounter++}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.existing != null;
    final isDialog = widget.presentation == _BookingPresentation.dialog;

    final formFactor = ref.watch(formFactorProvider);
    final services = ref.watch(servicesProvider);
    final serviceCategories = ref.watch(serviceCategoriesProvider);
    final variants = ref.watch(serviceVariantsProvider);
    final clients = ref.watch(clientsProvider);
    final clientsById = ref.watch(clientsByIdProvider);
    final allStaff = ref.watch(staffForCurrentLocationProvider);

    // Deriva il nome del cliente dal provider se _clientId è impostato,
    // altrimenti usa il nome personalizzato (per clienti nuovi)
    final clientName = _clientId != null
        ? (clientsById[_clientId]?.name ?? _customClientName)
        : _customClientName;

    final title = isEdit
        ? l10n.appointmentDialogTitleEdit
        : l10n.appointmentDialogTitleNew;

    final isDesktop = widget.presentation == _BookingPresentation.dialog;
    final content = Form(
      key: _formKey,
      child: ConstrainedBox(
        // Su desktop, limita la larghezza del form. Su mobile, usa tutta la larghezza.
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 340 : double.infinity,
        ),
        child: ScrollConfiguration(
          behavior: const NoScrollbarBehavior(),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.formFirstRowSpacing),

                // Client selection
                _ClientSelectionField(
                  clientId: _clientId,
                  clientName: clientName,
                  clients: clients,
                  onClientSelected: (id, name) {
                    setState(() {
                      _clientId = id;
                      _customClientName = name;
                    });
                  },
                  onClientRemoved: () {
                    setState(() {
                      _clientId = null;
                      _customClientName = '';
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.formRowSpacing),

                // Date and Time selector (row)
                LabeledFormField(
                  label: l10n.formDate,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DtFmt.shortDate(context, _date)),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.formRowSpacing),

                // Services section header
                // Services list
                ..._buildServiceItems(
                  services: services,
                  categories: serviceCategories,
                  variants: variants,
                  allStaff: allStaff,
                  formFactor: formFactor,
                ),

                const SizedBox(height: AppSpacing.formRowSpacing),

                // Notes field
                LabeledFormField(
                  label: l10n.formNotes,
                  child: TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: l10n.notesPlaceholder,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(height: AppSpacing.formRowSpacing),
              ],
            ),
          ),
        ),
      ),
    );

    final actions = [
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
                        SizedBox(
                          width: AppButtonStyles.dialogButtonWidth,
                          child: actions[i],
                        ),
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

    // Bottom sheet layout
    const horizontalPadding = 20.0;
    final titlePadding = EdgeInsets.fromLTRB(
      horizontalPadding,
      0,
      horizontalPadding,
      12,
    );

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: titlePadding,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: content,
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x1F000000), width: 0.5),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.formFirstRowSpacing,
                horizontalPadding,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    SizedBox(
                      width: AppButtonStyles.dialogButtonWidth,
                      child: actions[i],
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }

  List<Widget> _buildServiceItems({
    required List<dynamic> services,
    required List<dynamic> categories,
    required List<dynamic> variants,
    required List<dynamic> allStaff,
    required AppFormFactor formFactor,
  }) {
    final widgets = <Widget>[];

    // Conta servizi effettivamente selezionati
    final selectedCount = _serviceItems
        .where((s) => s.serviceId != null)
        .length;

    for (int i = 0; i < _serviceItems.length; i++) {
      final item = _serviceItems[i];

      // Get eligible staff for this service
      final eligibleStaffIds = item.serviceId != null
          ? ref.watch(eligibleStaffForServiceProvider(item.serviceId!))
          : <int>[];

      final isFirst = i == 0;
      final isLast = i == _serviceItems.length - 1;
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isFirst) ...[
              Row(
                children: [
                  Text(
                    selectedCount > 0
                        ? context.l10n.servicesSelectedCount(selectedCount)
                        : context.l10n.formServices,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ServiceItemCard(
                index: i,
                item: item,
                services: services.cast(),
                categories: categories.cast(),
                variants: variants.cast(),
                eligibleStaff: eligibleStaffIds,
                allStaff: allStaff.cast(),
                formFactor: formFactor,
                canRemove: _serviceItems.length > 1,
                // Obbligatorio solo se non ci sono altri servizi selezionati
                isServiceRequired: selectedCount == 0,
                onChanged: (updated) => _updateServiceItem(i, updated),
                onRemove: () => _removeServiceItem(i),
                onStartTimeChanged: (time) => _updateServiceStartTime(i, time),
                onEndTimeChanged: (time) => _updateServiceEndTime(i, time),
                onDurationChanged: (duration) =>
                    _updateServiceDuration(i, duration),
              ),
            ),
            if (isLast && item.serviceId != null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: AppOutlinedActionButton(
                  onPressed: _addService,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 18),
                      const SizedBox(width: 8),
                      Text(context.l10n.addService),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    }

    if (_serviceItems.isEmpty) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              context.l10n.noServicesAdded,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  void _addService() {
    // Calcola l'orario di inizio per il nuovo servizio
    TimeOfDay nextStart;
    if (_serviceItems.isEmpty) {
      nextStart = widget.initialTime ?? const TimeOfDay(hour: 10, minute: 0);
    } else {
      // Prendi l'ultimo servizio e calcola il suo orario di fine
      final lastItem = _serviceItems.last;
      nextStart = lastItem.endTime;
    }

    // Smart staff selection:
    // 1. Try initial staff if eligible
    // 2. Leave null for user selection
    int? smartStaffId = widget.initialStaffId;

    setState(() {
      _serviceItems.add(
        ServiceItemData(
          key: _nextItemKey(),
          startTime: nextStart,
          staffId: smartStaffId,
        ),
      );
    });
  }

  void _removeServiceItem(int index) {
    if (_serviceItems.length <= 1) return;

    final variants = ref.read(serviceVariantsProvider);

    setState(() {
      _serviceItems.removeAt(index);

      // Ricalcola gli orari per i servizi successivi
      _recalculateTimesFrom(index, variants.cast());
    });
  }

  void _updateServiceItem(int index, ServiceItemData updated) {
    final variants = ref.read(serviceVariantsProvider);

    setState(() {
      _serviceItems[index] = updated;

      // Se cambia il servizio, potremmo dover aggiornare lo staff
      // e ricalcolare gli orari successivi
      _recalculateTimesFrom(index + 1, variants.cast());

      // Smart staff selection se lo staff corrente non è più eligible
      if (updated.serviceId != null && updated.staffId != null) {
        final eligibleIds = ref.read(
          eligibleStaffForServiceProvider(updated.serviceId!),
        );
        if (!eligibleIds.contains(updated.staffId)) {
          // Staff non eligible, proviamo a trovarne uno valido
          final newStaffId = _findBestStaff(updated.serviceId!);
          _serviceItems[index] = updated.copyWith(staffId: newStaffId);
        }
      }
    });
  }

  void _updateServiceStartTime(int index, TimeOfDay newTime) {
    final variants = ref.read(serviceVariantsProvider);

    setState(() {
      _serviceItems[index] = _serviceItems[index].copyWith(startTime: newTime);

      // Ricalcola gli orari per i servizi successivi
      _recalculateTimesFrom(index + 1, variants.cast());
    });
  }

  void _updateServiceEndTime(int index, TimeOfDay newEndTime) {
    setState(() {
      final item = _serviceItems[index];

      // Calcola la nuova durata basata sulla differenza tra end e start
      final startMinutes = item.startTime.hour * 60 + item.startTime.minute;
      final endMinutes = newEndTime.hour * 60 + newEndTime.minute;
      var newDuration = endMinutes - startMinutes;

      // Se la durata è negativa o zero, imposta un minimo di 15 minuti
      if (newDuration <= 0) {
        newDuration = 15;
      }

      _serviceItems[index] = item.copyWith(durationMinutes: newDuration);

      // Ricalcola gli orari per i servizi successivi
      final variants = ref.read(serviceVariantsProvider);
      _recalculateTimesFrom(index + 1, variants.cast());
    });
  }

  void _updateServiceDuration(int index, int newDuration) {
    setState(() {
      _serviceItems[index] = _serviceItems[index].copyWith(
        durationMinutes: newDuration,
      );

      // Ricalcola gli orari per i servizi successivi
      final variants = ref.read(serviceVariantsProvider);
      _recalculateTimesFrom(index + 1, variants.cast());
    });
  }

  void _recalculateTimesFrom(int fromIndex, List<dynamic> variants) {
    if (fromIndex <= 0 || fromIndex >= _serviceItems.length) return;

    for (int i = fromIndex; i < _serviceItems.length; i++) {
      final prevItem = _serviceItems[i - 1];
      final prevEnd = prevItem.endTime;
      _serviceItems[i] = _serviceItems[i].copyWith(startTime: prevEnd);
    }
  }

  /// Trova lo staff migliore per un servizio:
  /// 1. initialStaffId se eligible
  /// 2. Primo staff eligible disponibile
  /// 3. null per selezione manuale
  int? _findBestStaff(int serviceId) {
    final eligibleIds = ref.read(eligibleStaffForServiceProvider(serviceId));
    if (eligibleIds.isEmpty) return null;

    // Se initialStaffId è eligible, usalo
    if (widget.initialStaffId != null &&
        eligibleIds.contains(widget.initialStaffId)) {
      return widget.initialStaffId;
    }

    // Altrimenti prendi il primo eligible
    return eligibleIds.first;
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

  void _onSave() {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    // Verifica che ci sia almeno un servizio con dati completi
    final validItems = _serviceItems
        .where((item) => item.serviceId != null && item.staffId != null)
        .toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.atLeastOneServiceRequired)));
      return;
    }

    final variants = ref.read(serviceVariantsProvider);
    final services = ref.read(servicesProvider);
    final clientsById = ref.read(clientsByIdProvider);
    final appointmentsNotifier = ref.read(appointmentsProvider.notifier);
    final bookingsNotifier = ref.read(bookingsProvider.notifier);

    // Deriva il nome del cliente dal provider se _clientId è impostato
    final clientName = _clientId != null
        ? (clientsById[_clientId]?.name ?? _customClientName)
        : _customClientName;

    // Create a new booking
    final bookingId = bookingsNotifier.createBooking(
      clientId: _clientId,
      customerName: clientName.isNotEmpty ? clientName : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    // Add appointments for each service
    for (final item in validItems) {
      final variant = variants.firstWhere(
        (v) => v.serviceId == item.serviceId,
        orElse: () => variants.first,
      );
      final service = services.firstWhere((s) => s.id == item.serviceId);

      final start = DateTime(
        _date.year,
        _date.month,
        _date.day,
        item.startTime.hour,
        item.startTime.minute,
      );
      final durationMinutes = item.durationMinutes > 0
          ? item.durationMinutes
          : variant.durationMinutes;
      final end = start.add(Duration(minutes: durationMinutes));

      appointmentsNotifier.addAppointment(
        bookingId: bookingId,
        staffId: item.staffId!,
        serviceId: service.id,
        serviceVariantId: variant.id,
        clientId: _clientId,
        clientName: clientName,
        serviceName: service.name,
        start: start,
        end: end,
        price: variant.price,
      );
    }

    Navigator.of(context).pop();
  }
}

// ============================================================================
// Helper Widgets
// ============================================================================

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
  });

  final int? clientId;
  final String clientName;
  final List<Client> clients;
  final void Function(int? id, String name) onClientSelected;
  final VoidCallback onClientRemoved;

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
            onTap: () => _showClientPicker(context, ref),
            onRemove: onClientRemoved,
          )
        else
          InkWell(
            onTap: () => _showClientPicker(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.addClientToAppointment,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          l10n.clientOptionalHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _showClientPicker(BuildContext context, WidgetRef ref) async {
    final formFactor = ref.read(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;

    while (true) {
      if (!context.mounted) return;
      _ClientItem? result;
      if (isDesktop) {
        result = await showDialog<_ClientItem?>(
          context: context,
          builder: (ctx) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 600,
                maxWidth: 720,
                maxHeight: 600,
              ),
              child: _ClientPickerSheet(
                clients: clients,
                selectedClientId: clientId,
              ),
            ),
          ),
        );
      } else {
        result = await AppBottomSheet.show<_ClientItem?>(
          context: context,
          useRootNavigator: true,
          padding: EdgeInsets.zero,
          heightFactor: AppBottomSheet.defaultHeightFactor,
          builder: (ctx) =>
              _ClientPickerSheet(clients: clients, selectedClientId: clientId),
        );
      }
      if (result == null) {
        return;
      }
      if (result.id == -2) {
        // "Create new client" was selected
        if (context.mounted) {
          Client? initialClient;
          if (result.name.isNotEmpty) {
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
            onClientSelected(newClient.id, newClient.name);
            return;
          }
          continue;
        }
        return;
      } else if (result.id == -1) {
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
    required this.onTap,
    required this.onRemove,
  });

  final String clientName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
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
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: theme.colorScheme.error),
              onPressed: onRemove,
              tooltip: context.l10n.removeClient,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
    final clients = ref
        .watch(clientsProvider)
        .where((c) => !c.isArchived)
        .toList();
    if (_searchQuery.isEmpty) return clients;
    final q = _searchQuery.toLowerCase();
    return clients.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
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
            // Quick actions
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
                Navigator.of(context).pop(const _ClientItem(-1, ''));
              },
            ),
            const Divider(height: 1),
            // Client list
            Flexible(
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () async {
                                  await showClientEditDialog(
                                    context,
                                    ref,
                                    client: client,
                                  );
                                },
                                tooltip: l10n.clientsEdit,
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                ),
                            ],
                          ),
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
      ),
    );
  }
}
