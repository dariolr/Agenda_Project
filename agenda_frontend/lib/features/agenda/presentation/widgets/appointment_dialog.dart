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
import '../../../clients/domain/clients.dart';
import '../../../clients/presentation/dialogs/client_edit_dialog.dart';
import '../../../clients/providers/clients_providers.dart';
import '../../../services/providers/service_categories_provider.dart';
import '../../../services/providers/services_provider.dart';
import '../../domain/config/layout_config.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/date_range_provider.dart';
import '../../providers/layout_config_provider.dart';
import 'service_picker_field.dart';

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

  late DateTime _date;
  late TimeOfDay _time;
  int? _serviceId;
  int? _serviceVariantId;
  int? _clientId;
  String _clientName = '';
  int? _staffId;

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
      _time = TimeOfDay(
        hour: appt.startTime.hour,
        minute: appt.startTime.minute,
      );
      _serviceId = appt.serviceId;
      _serviceVariantId = appt.serviceVariantId;
      _clientId = appt.clientId;
      _clientName = appt.clientName;
      _staffId = appt.staffId;
    } else {
      _date = DateUtils.dateOnly(widget.initialDate ?? agendaDate);
      _time = widget.initialTime ?? TimeOfDay(hour: 10, minute: 0);
      _staffId = widget.initialStaffId;
    }
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

    // Ensure variant aligns with chosen service
    if (_serviceId != null) {
      final matchingVariants = variants
          .where((v) => v.serviceId == _serviceId)
          .toList();
      if (matchingVariants.isEmpty) {
        _serviceVariantId = null;
      } else if (_serviceVariantId == null ||
          !matchingVariants.any((v) => v.id == _serviceVariantId)) {
        _serviceVariantId = matchingVariants.first.id;
      }
    }

    final title = isEdit
        ? l10n.appointmentDialogTitleEdit
        : l10n.appointmentDialogTitleNew;

    final content = Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: isDialog
            ? const BoxConstraints(maxWidth: 520)
            : const BoxConstraints(maxWidth: double.infinity),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.formFirstRowSpacing),
              // Client selection (first)
              _ClientSelectionField(
                clientId: _clientId,
                clientName: _clientName,
                clients: clients,
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
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: l10n.formDate,
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: Text(DtFmt.shortDate(context, _date)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: l10n.formTime,
                      child: InkWell(
                        onTap: _pickTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_time.format(context)),
                              const Icon(Icons.schedule, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.formRowSpacing),
              // Service
              _LabeledField(
                label: l10n.formService,
                child: ServicePickerField(
                  services: services,
                  categories: serviceCategories,
                  formFactor: formFactor,
                  value: _serviceId,
                  onChanged: (v) {
                    setState(() {
                      _serviceId = v;
                      _serviceVariantId = null; // recalculated in build
                    });
                  },
                  validator: (v) => v == null ? l10n.validationRequired : null,
                ),
              ),
              const SizedBox(height: AppSpacing.formRowSpacing),
              // Staff
              _LabeledField(
                label: l10n.formStaff,
                child: DropdownButtonFormField<int>(
                  value: _staffId,
                  items: [
                    for (final s in staff)
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) => setState(() => _staffId = v),
                  validator: (v) => v == null ? l10n.validationRequired : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final actions = [
      if (widget.initial != null)
        AppOutlinedActionButton(
          onPressed: () {
            final variants = ref.read(serviceVariantsProvider);
            final services = ref.read(servicesProvider);
            final selectedVariant = variants.firstWhere(
              (v) => v.serviceId == (_serviceId ?? widget.initial!.serviceId),
              orElse: () => variants.first,
            );
            final service = services.firstWhere(
              (s) => s.id == (_serviceId ?? widget.initial!.serviceId),
            );

            final start = DateTime(
              _date.year,
              _date.month,
              _date.day,
              _time.hour,
              _time.minute,
            );
            final end = start.add(
              Duration(minutes: selectedVariant.durationMinutes),
            );

            ref
                .read(appointmentsProvider.notifier)
                .addAppointment(
                  bookingId: widget.initial!.bookingId,
                  staffId: _staffId ?? widget.initial!.staffId,
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
          },
          child: Text(l10n.actionAddService),
        ),
      if (widget.initial != null)
        AppDangerButton(
          onPressed: () {
            ref
                .read(appointmentsProvider.notifier)
                .deleteAppointment(widget.initial!.id);
            Navigator.of(context).pop();
          },
          child: Text(l10n.actionDelete),
        ),
      if (widget.initial != null)
        AppDangerButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(l10n.deleteBookingConfirmTitle),
                content: Text(l10n.deleteBookingConfirmMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.actionCancel),
                  ),
                  TextButton(
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
      return AlertDialog(
        title: Text(title),
        content: content,
        actions: actions,
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

  Future<void> _pickTime() async {
    final step = ref.read(layoutConfigProvider).minutesPerSlot;
    final selected = await AppBottomSheet.show<TimeOfDay>(
      context: context,
      useRootNavigator: true,
      padding: EdgeInsets.zero,
      heightFactor: AppBottomSheet.defaultHeightFactor,
      builder: (ctx) => _TimeGridPicker(initial: _time, stepMinutes: step),
    );
    if (selected != null) {
      setState(() => _time = selected);
    }
  }

  void _onSave() {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    if (_serviceId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.validationRequired)));
      return;
    }
    if (_staffId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.validationRequired)));
      return;
    }

    final variants = ref.read(serviceVariantsProvider);
    final services = ref.read(servicesProvider);

    final selectedVariant = variants.firstWhere(
      (v) => v.serviceId == _serviceId,
      orElse: () => variants.first,
    );
    final service = services.firstWhere((s) => s.id == _serviceId);

    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final end = start.add(Duration(minutes: selectedVariant.durationMinutes));

    // Client info (può essere null se nessun cliente è associato)
    final int? clientId = _clientId;
    final String clientName = _clientName.trim();

    if (widget.initial == null) {
      // Nuovo appuntamento: crea SEMPRE una nuova prenotazione
      ref
          .read(appointmentsProvider.notifier)
          .addAppointment(
            bookingId: null,
            staffId: _staffId!,
            serviceId: service.id,
            serviceVariantId: selectedVariant.id,
            clientId: clientId,
            clientName: clientName,
            serviceName: service.name,
            start: start,
            end: end,
            price: selectedVariant.price,
          );
    } else {
      final updated = widget.initial!.copyWith(
        staffId: _staffId!,
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
    }

    Navigator.of(context).pop();
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ClientItem {
  final int id;
  final String name;
  const _ClientItem(this.id, this.name);
}

class _TimeGridPicker extends StatelessWidget {
  const _TimeGridPicker({required this.initial, required this.stepMinutes});
  final TimeOfDay initial;
  final int stepMinutes;

  @override
  Widget build(BuildContext context) {
    final entries = <TimeOfDay>[];
    for (int m = 0; m < LayoutConfig.hoursInDay * 60; m += stepMinutes) {
      final h = m ~/ 60;
      final mm = m % 60;
      entries.add(TimeOfDay(hour: h, minute: mm));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 8),
                Text(
                  MaterialLocalizations.of(context).timePickerHourLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 2.7,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final t = entries[index];
                  final isSelected =
                      t.hour == initial.hour && t.minute == initial.minute;
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : null,
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => Navigator.pop(context, t),
                    child: Text(_format(context, t)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(BuildContext ctx, TimeOfDay t) {
    return DtFmt.hm(ctx, t.hour, t.minute);
  }
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
