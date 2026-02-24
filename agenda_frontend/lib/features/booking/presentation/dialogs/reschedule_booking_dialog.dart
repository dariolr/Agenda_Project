import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '/core/l10n/l10_extension.dart';
import '/core/models/booking_item.dart';
import '/core/network/network_providers.dart';
import '/core/services/tenant_time_service.dart';
import '/core/widgets/feedback_dialog.dart';
import '../../providers/locations_provider.dart';
import '../../providers/my_bookings_provider.dart';

/// Dialog per riprogrammare una prenotazione esistente
class RescheduleBookingDialog extends ConsumerStatefulWidget {
  const RescheduleBookingDialog({required this.booking, super.key});

  final BookingItem booking;

  @override
  ConsumerState<RescheduleBookingDialog> createState() =>
      _RescheduleBookingDialogState();
}

class _RescheduleBookingDialogState
    extends ConsumerState<RescheduleBookingDialog> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;
  String? _error;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.booking.notes ?? '';
    // Imposta data corrente della prenotazione
    _selectedDate = widget.booking.startTime;
    _loadAvailability(_selectedDate!);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _error = null;
      _selectedTimeSlot = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // Recupera service IDs dalla prenotazione corrente
      final serviceIds = widget.booking.serviceIds;
      final staffId = widget.booking.staffId;

      // Debug info
      debugPrint('RESCHEDULE - locationId: ${widget.booking.locationId}');
      debugPrint('RESCHEDULE - serviceIds: $serviceIds');
      debugPrint('RESCHEDULE - staffId: $staffId');
      debugPrint('RESCHEDULE - bookingId: ${widget.booking.id}');
      debugPrint('RESCHEDULE - date: $dateStr');

      if (serviceIds.isEmpty) {
        setState(() {
          _error = 'Impossibile recuperare i servizi della prenotazione';
          _isLoadingSlots = false;
        });
        return;
      }

      // Passa exclude_booking_id per escludere la prenotazione originale dai conflitti
      // Passa staffId per mostrare solo slot disponibili per quello specifico operatore
      final response = await apiClient.getAvailability(
        locationId: widget.booking.locationId,
        date: dateStr,
        serviceIds: serviceIds,
        staffId: staffId,
        excludeBookingId: widget.booking.id,
      );

      debugPrint(
        'RESCHEDULE - response slots count: ${(response['slots'] as List?)?.length ?? 0}',
      );

      final slots = response['slots'] as List<dynamic>? ?? [];
      final original = widget.booking.startTime;
      final isSameDayAsOriginal =
          date.year == original.year &&
          date.month == original.month &&
          date.day == original.day;
      final originalTimeSlot = isSameDayAsOriginal
          ? DateFormat('HH:mm').format(original)
          : null;
      setState(() {
        _availableSlots = slots
            .map((slot) {
              final startTime = slot['start_time'] as String;
              // Estrai orario ignorando timezone (orario della location, non locale utente)
              final dt = TenantTimeService.parseAsLocationTime(startTime);
              return DateFormat('HH:mm').format(dt);
            })
            // Non mostrare lo stesso identico orario (data+ora) della prenotazione originale
            // quando si sta modificando la prenotazione sulla stessa data.
            .where((t) => originalTimeSlot == null || t != originalTimeSlot)
            .toList()
            .cast<String>();
        _isLoadingSlots = false;
      });
    } catch (e) {
      debugPrint('RESCHEDULE - error: $e');
      setState(() {
        _error = e.toString();
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final now = ref.read(locationNowProvider);
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 90));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('it'),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadAvailability(picked);
    }
  }

  Future<void> _confirmReschedule() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      return;
    }
    if (_isSubmitting) return;

    final serviceIds = widget.booking.serviceIds;
    if (serviceIds.isEmpty) {
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: 'Impossibile recuperare i servizi della prenotazione',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Costruisci nuovo start_time ISO8601
    final timeParts = _selectedTimeSlot!.split(':');
    final newDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    final newStartTime = newDateTime.toIso8601String();

    // Genera idempotency key per il replace
    final idempotencyKey = const Uuid().v4();

    // Usa il pattern atomic replace
    try {
      final result = await ref
          .read(myBookingsProvider.notifier)
          .replaceBooking(
            originalBookingId: widget.booking.id,
            locationId: widget.booking.locationId,
            serviceIds: serviceIds,
            startTime: newStartTime,
            idempotencyKey: idempotencyKey,
            notes: _notesController.text.isNotEmpty
                ? _notesController.text
                : null,
          );

      if (!mounted) return;

      if (result.success) {
        Navigator.of(context).pop(true);
      } else {
        final bookingsState = ref.read(myBookingsProvider);
        // Messaggio specifico per conflitto slot (spec C6)
        final errorMessage = bookingsState.errorCode == 'slot_conflict'
            ? context.l10n.slotNoLongerAvailable
            : bookingsState.errorCode == 'not_modifiable'
            ? context.l10n.bookingErrorNotModifiable
            : (bookingsState.error ?? context.l10n.errorGeneric);
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: errorMessage,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'it');

    return AlertDialog(
      title: Text(context.l10n.rescheduleBookingTitle),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info prenotazione corrente
              Text(
                context.l10n.currentBooking,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.booking.serviceNames.join(', ')} - ${dateFormat.format(widget.booking.startTime)} ${DateFormat('HH:mm').format(widget.booking.startTime)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Divider(height: 24),

              // Selezione nuova data
              Text(
                context.l10n.selectNewDate,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDate != null
                      ? dateFormat.format(_selectedDate!)
                      : context.l10n.selectDate,
                ),
              ),
              const SizedBox(height: 16),

              // Slot disponibili
              if (_isLoadingSlots)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red))
              else if (_availableSlots.isEmpty)
                Text(context.l10n.dateTimeNoSlots)
              else ...[
                Text(
                  context.l10n.selectNewTime,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSlots.map((slot) {
                    final isSelected = _selectedTimeSlot == slot;
                    return ChoiceChip(
                      label: Text(slot),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTimeSlot = selected ? slot : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),

              // Note
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: context.l10n.summaryNotes,
                  hintText: context.l10n.summaryNotesHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: (_selectedDate != null && _selectedTimeSlot != null)
              ? (_isSubmitting ? null : _confirmReschedule)
              : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.confirmReschedule),
        ),
      ],
    );
  }
}
