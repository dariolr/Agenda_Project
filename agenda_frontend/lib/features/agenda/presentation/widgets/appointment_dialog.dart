import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/theme/app_spacing.dart';
import 'package:agenda_frontend/core/l10n/date_time_formats.dart';
import 'package:agenda_frontend/core/widgets/no_scrollbar_behavior.dart';
import 'package:agenda_frontend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/appointment.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../clients/domain/clients.dart';
import '../../../clients/presentation/dialogs/client_edit_dialog.dart';
import '../../../clients/providers/clients_providers.dart';
import '../../../services/providers/service_categories_provider.dart';
import '../../../services/providers/services_provider.dart';
import '../../domain/service_item_data.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/layout_config_provider.dart';
import '../../providers/staff_slot_availability_provider.dart';
import 'service_item_card.dart';

/// Show the Appointment dialog for editing an existing appointment.
/// For creating new appointments, use [showBookingDialog] instead.
Future<void> showAppointmentDialog(
  BuildContext context,
  WidgetRef ref, {
  required Appointment initial,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final presentation = formFactor == AppFormFactor.desktop
      ? _AppointmentPresentation.dialog
      : _AppointmentPresentation.bottomSheet;

  final content = _AppointmentDialog(
    initial: initial,
    presentation: presentation,
  );

  if (presentation == _AppointmentPresentation.dialog) {
    await showDialog(context: context, builder: (_) => content);
  } else {
    await AppBottomSheet.show(
      context: context,
      useRootNavigator: true,
      builder: (_) => content,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      heightFactor: AppBottomSheet.defaultHeightFactor,
    );
  }
}

enum _AppointmentPresentation { dialog, bottomSheet }

class _AppointmentDialog extends ConsumerStatefulWidget {
  const _AppointmentDialog({required this.initial, required this.presentation});

  final Appointment initial;
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
  late final bool _bookingHasSingleAppointment;

  /// Lista di ServiceItemData per i servizi dell'appuntamento
  final List<ServiceItemData> _serviceItems = [];

  /// Contatore per generare chiavi univoche
  int _itemKeyCounter = 0;

  bool _warningDismissed = false;

  /// Stato iniziale per rilevare modifiche
  late DateTime _initialDate;
  late int? _initialClientId;
  late String _initialClientName;
  late String _initialNotes;
  late List<ServiceItemData> _initialServiceItems;

  @override
  void initState() {
    super.initState();

    final appt = widget.initial;
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

    // Carica tutti gli appuntamenti della stessa prenotazione
    final bookingAppointments = ref
        .read(appointmentsProvider.notifier)
        .getByBookingId(appt.bookingId);
    _bookingHasSingleAppointment = bookingAppointments.length <= 1;

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

    // Se non ci sono appointments (caso raro), aggiungi un item vuoto
    if (_serviceItems.isEmpty) {
      final initialTime = TimeOfDay.fromDateTime(appt.startTime);
      _serviceItems.add(
        ServiceItemData(
          key: _nextItemKey(),
          startTime: initialTime,
          staffId: appt.staffId,
        ),
      );
    }

    // Salva stato iniziale per rilevare modifiche
    _initialDate = _date;
    _initialClientId = _clientId;
    _initialClientName = _clientName;
    _initialNotes = _notesController.text;
    // Copia profonda dei servizi per confronto
    _initialServiceItems = _serviceItems
        .map(
          (s) => ServiceItemData(
            key: s.key,
            startTime: s.startTime,
            staffId: s.staffId,
            serviceId: s.serviceId,
            serviceVariantId: s.serviceVariantId,
            durationMinutes: s.durationMinutes,
          ),
        )
        .toList();
  }

  String _nextItemKey() => 'item_${_itemKeyCounter++}';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Verifica se ci sono modifiche non salvate
  bool get _hasUnsavedChanges {
    if (_date != _initialDate) return true;
    if (_clientId != _initialClientId) return true;
    if (_clientName != _initialClientName) return true;
    if (_notesController.text != _initialNotes) return true;
    if (_serviceItems.length != _initialServiceItems.length) return true;

    // Confronto dettagliato dei servizi
    for (int i = 0; i < _serviceItems.length; i++) {
      final current = _serviceItems[i];
      final initial = _initialServiceItems[i];
      if (current.serviceId != initial.serviceId) return true;
      if (current.staffId != initial.staffId) return true;
      if (current.startTime != initial.startTime) return true;
      if (current.durationMinutes != initial.durationMinutes) return true;
    }

    return false;
  }

  /// Gestisce la chiusura del dialog con controllo modifiche
  Future<void> _handleClose() async {
    if (_hasUnsavedChanges) {
      final l10n = context.l10n;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.discardChangesTitle),
          content: Text(l10n.discardChangesMessage),
          actions: [
            AppOutlinedActionButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionKeepEditing),
            ),
            AppDangerButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.actionDiscard),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDialog = widget.presentation == _AppointmentPresentation.dialog;

    final formFactor = ref.watch(formFactorProvider);
    final services = ref.watch(servicesProvider);
    final serviceCategories = ref.watch(serviceCategoriesProvider);
    final variants = ref.watch(serviceVariantsProvider);
    final clients = ref.watch(clientsProvider);
    final staff = ref.watch(staffForCurrentLocationProvider);

    final title = l10n.appointmentDialogTitleEdit;

    // Il campo cliente è bloccato se l'appuntamento
    // aveva già un cliente associato (clientId != null)
    final isClientLocked = widget.initial.clientId != null;

    final content = ScrollConfiguration(
      behavior: const NoScrollbarBehavior(),
      child: SingleChildScrollView(
        child: Form(
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
              // Services list
              ..._buildServiceItems(
                services: services,
                categories: serviceCategories,
                variants: variants,
                allStaff: staff,
                formFactor: formFactor,
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
        ),
      ),
    );

    final actions = [
      AppDangerButton(
        onPressed: () async {
          final deleteTitle = _bookingHasSingleAppointment
              ? l10n.deleteAppointmentConfirmTitle
              : l10n.deleteBookingConfirmTitle;
          final deleteMessage = _bookingHasSingleAppointment
              ? l10n.deleteAppointmentConfirmMessage
              : l10n.deleteBookingConfirmMessage;
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(deleteTitle),
              content: Text(deleteMessage),
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
                .read(bookingsProvider.notifier)
                .deleteBooking(widget.initial.bookingId);
            if (context.mounted) Navigator.of(context).pop();
          }
        },
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionDelete),
      ),
      AppOutlinedActionButton(
        onPressed: _handleClose,
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
      final hasConflicts = _hasAvailabilityConflicts();
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _handleClose();
        },
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
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.formFirstRowSpacing,
                    ),
                    child: _warningBanner(8, hasConflicts),
                  ),
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
    const horizontalPadding = 20.0;
    final hasConflicts = _hasAvailabilityConflicts();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleClose();
      },
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                12,
              ),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: content,
              ),
            ),
            _warningBanner(horizontalPadding, hasConflicts),
            const Divider(height: 1, thickness: 0.5, color: Color(0x1F000000)),
            Padding(
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
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
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

  Widget _warningBanner(double horizontalPadding, bool hasConflicts) {
    if (!hasConflicts || _warningDismissed) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        12,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Attenzione: l’orario selezionato include fasce non disponibili per lo staff scelto.',
              style: TextStyle(
                color: Color(0xFF8A4D00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: const Color(0xFF8A4D00),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: () {
              setState(() => _warningDismissed = true);
            },
          ),
        ],
      ),
    );
  }

  bool _hasAvailabilityConflicts() {
    final layout = ref.watch(layoutConfigProvider);
    final Map<int, Set<int>> cache = {};

    for (final item in _serviceItems) {
      final staffId = item.staffId;
      if (staffId == null) continue;

      final available = cache.putIfAbsent(
        staffId,
        () => ref.watch(staffSlotAvailabilityProvider(staffId)),
      );

      if (available.isEmpty) return true;

      final startMinutes = item.startTime.hour * 60 + item.startTime.minute;
      final endMinutes = startMinutes + item.durationMinutes;
      final startSlot = startMinutes ~/ layout.minutesPerSlot;
      final endSlot = (endMinutes / layout.minutesPerSlot).ceil();

      for (int slot = startSlot; slot < endSlot; slot++) {
        if (!available.contains(slot)) return true;
      }
    }
    return false;
  }

  void _addService() {
    // Calcola l'orario di inizio per il nuovo servizio
    TimeOfDay nextStart;
    if (_serviceItems.isEmpty) {
      // Caso raro: usa l'orario dell'appuntamento originale
      nextStart = TimeOfDay.fromDateTime(widget.initial.startTime);
    } else {
      // Prendi l'ultimo servizio e calcola il suo orario di fine
      final lastItem = _serviceItems.last;
      nextStart = lastItem.endTime;
    }

    // Smart staff selection: usa lo staff dell'ultimo servizio aggiunto
    int? smartStaffId = _serviceItems.isNotEmpty
        ? _serviceItems.last.staffId
        : widget.initial.staffId;

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
  /// 1. Primo staff eligible disponibile
  /// 2. null per selezione manuale
  int? _findBestStaff(int serviceId) {
    final eligibleIds = ref.read(eligibleStaffForServiceProvider(serviceId));
    if (eligibleIds.isEmpty) return null;

    // Prendi il primo eligible
    return eligibleIds.first;
  }

  void _onSave() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    // Verifica che ci sia almeno un servizio selezionato
    final validItems = _serviceItems
        .where((item) => item.serviceId != null && item.staffId != null)
        .toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.validationRequired)));
      return;
    }

    final variants = ref.read(serviceVariantsProvider);
    final services = ref.read(servicesProvider);

    // Client info (può essere null se nessun cliente è associato)
    final int? clientId = _clientId;
    final String clientName = _clientName.trim();
    final String? notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    // Modifica appuntamento esistente
    final bookingId = widget.initial.bookingId;

    // Ottieni gli appuntamenti esistenti per questa prenotazione
    final existingAppointments = ref
        .read(appointmentsProvider.notifier)
        .getByBookingId(bookingId);

    // Verifica se il cliente è stato aggiunto (era null e ora non lo è)
    final initialClientId = widget.initial.clientId;
    final clientWasAdded = initialClientId == null && clientId != null;

    // Se il cliente è stato aggiunto e ci sono altri appuntamenti
    if (clientWasAdded && existingAppointments.length > 1 && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.applyClientToAllAppointmentsTitle),
          content: Text(
            l10n.applyClientToAllAppointmentsMessage(
              existingAppointments.length - 1,
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

      if (confirmed == true) {
        // Aggiorna il cliente su tutti gli appuntamenti della prenotazione
        ref
            .read(appointmentsProvider.notifier)
            .updateClientForBooking(
              bookingId: bookingId,
              clientId: clientId,
              clientName: clientName,
            );
      } else if (confirmed == null) {
        // Utente ha annullato, non salvare
        return;
      }
    }

    // Aggiorna tutti i servizi
    final existingIds = existingAppointments.map((a) => a.id).toSet();
    final processedIds = <int>{};

    for (int i = 0; i < validItems.length; i++) {
      final item = validItems[i];
      final selectedVariant = variants.firstWhere(
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

      final duration = item.durationMinutes > 0
          ? item.durationMinutes
          : selectedVariant.durationMinutes;
      final end = start.add(Duration(minutes: duration));

      if (i < existingAppointments.length) {
        // Aggiorna appuntamento esistente
        final existing = existingAppointments[i];
        processedIds.add(existing.id);

        final updated = existing.copyWith(
          staffId: item.staffId!,
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
      } else {
        // Crea nuovo appuntamento (aggiunto durante la modifica)
        ref
            .read(appointmentsProvider.notifier)
            .addAppointment(
              bookingId: bookingId,
              staffId: item.staffId!,
              serviceId: service.id,
              serviceVariantId: selectedVariant.id,
              clientId: clientId,
              clientName: clientName,
              serviceName: service.name,
              start: start,
              end: end,
              price: selectedVariant.price,
            );
      }
    }

    // Elimina appuntamenti rimossi
    for (final id in existingIds.difference(processedIds)) {
      ref.read(appointmentsProvider.notifier).deleteAppointment(id);
    }

    // Aggiorna le note nella booking associata
    ref.read(bookingsProvider.notifier).setNotes(bookingId, notes);

    // Rimuovi la booking se vuota
    ref.read(bookingsProvider.notifier).removeIfEmpty(bookingId);

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
