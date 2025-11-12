import 'package:agenda_frontend/core/l10n/date_time_formats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/appointment.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../clients/providers/clients_providers.dart';
import '../../../services/providers/services_provider.dart';
import '../../domain/config/layout_config.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/date_range_provider.dart';
import '../../providers/layout_config_provider.dart';
// location_providers not needed directly here
import '../../providers/staff_providers.dart';

/// Show the Appointment dialog for creating or editing an appointment.
Future<void> showAppointmentDialog(
  BuildContext context,
  WidgetRef ref, {
  Appointment? initial,
  DateTime? date,
  TimeOfDay? time,
  int? initialStaffId,
}) async {
  await showDialog(
    context: context,
    builder: (_) => _AppointmentDialog(
      initial: initial,
      initialDate: date,
      initialTime: time,
      initialStaffId: initialStaffId,
    ),
  );
}

class _AppointmentDialog extends ConsumerStatefulWidget {
  const _AppointmentDialog({
    this.initial,
    this.initialDate,
    this.initialTime,
    this.initialStaffId,
  });

  final Appointment? initial;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int? initialStaffId;

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

    final services = ref.watch(servicesProvider);
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

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                          child: Text(
                            '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                          ),
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
              const SizedBox(height: 12),
              // Service
              _LabeledField(
                label: l10n.formService,
                child: DropdownButtonFormField<int>(
                  value: _serviceId,
                  items: [
                    for (final s in services)
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _serviceId = v;
                      _serviceVariantId = null; // recalculated in build
                    });
                  },
                  validator: (v) => v == null ? l10n.validationRequired : null,
                ),
              ),
              const SizedBox(height: 12),
              // Client (autocomplete)
              _LabeledField(
                label: l10n.formClient,
                child: Autocomplete<_ClientItem>(
                  optionsBuilder: (TextEditingValue te) {
                    final q = te.text.trim().toLowerCase();
                    final list = clients;
                    final results = <_ClientItem>[
                      for (final c in list)
                        if (q.isEmpty || c.name.toLowerCase().contains(q))
                          _ClientItem(c.id, c.name),
                    ];
                    return results;
                  },
                  displayStringForOption: (o) => o.name,
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        if (_clientName.isNotEmpty && controller.text.isEmpty) {
                          controller.text = _clientName;
                        }
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            _clientName = v;
                            _clientId = null;
                          },
                        );
                      },
                  onSelected: (item) {
                    setState(() {
                      _clientId = item.id;
                      _clientName = item.name;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
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
      actions: [
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
          child: Text(l10n.actionCancel),
        ),
        AppFilledButton(onPressed: _onSave, child: Text(l10n.actionSave)),
      ],
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
    final selected = await showModalBottomSheet<TimeOfDay>(
      context: context,
      builder: (ctx) {
        return _TimeGridPicker(initial: _time, stepMinutes: step);
      },
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

    if (widget.initial == null) {
      // Nuovo appuntamento: crea SEMPRE una nuova prenotazione
      ref
          .read(appointmentsProvider.notifier)
          .addAppointment(
            bookingId: null,
            staffId: _staffId!,
            serviceId: service.id,
            serviceVariantId: selectedVariant.id,
            clientId: _clientId,
            clientName: _clientName,
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
        clientId: _clientId,
        clientName: _clientName,
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
  _ClientItem(this.id, this.name);
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
          mainAxisSize: MainAxisSize.min,
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
            SizedBox(
              height: 300,
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
