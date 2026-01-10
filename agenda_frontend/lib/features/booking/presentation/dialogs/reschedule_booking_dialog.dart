import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '/core/l10n/l10_extension.dart';
import '/core/models/booking_item.dart';
import '/core/network/network_providers.dart';
import '/core/widgets/feedback_dialog.dart';
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
      final serviceIds = widget.booking.serviceIds.isNotEmpty
          ? widget.booking.serviceIds
          : [1]; // Fallback se non disponibili (backward compatibility)

      final response = await apiClient.getAvailability(
        locationId: widget.booking.locationId,
        date: dateStr,
        serviceIds: serviceIds,
      );

      final slots = response['slots'] as List<dynamic>? ?? [];
      setState(() {
        _availableSlots = slots
            .map((slot) {
              final startTime = slot['start_time'] as String;
              final dt = DateTime.parse(startTime);
              return DateFormat('HH:mm').format(dt);
            })
            .toList()
            .cast<String>();
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
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

    final success = await ref
        .read(myBookingsProvider.notifier)
        .rescheduleBooking(
          locationId: widget.booking.locationId,
          bookingId: widget.booking.id,
          newStartTime: newStartTime,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        final bookingsState = ref.read(myBookingsProvider);
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: bookingsState.error ?? context.l10n.errorGeneric,
        );
      }
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
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _selectedDate != null && _selectedTimeSlot != null
              ? _confirmReschedule
              : null,
          child: Text(context.l10n.confirmReschedule),
        ),
      ],
    );
  }
}
