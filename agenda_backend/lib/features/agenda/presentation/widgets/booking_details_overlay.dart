import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../providers/bookings_provider.dart';

Future<void> showBookingDetailsOverlay(
  BuildContext context,
  WidgetRef ref, {
  required int bookingId,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => _BookingDetailsSheet(bookingId: bookingId),
  );
}

class _BookingDetailsSheet extends ConsumerWidget {
  const _BookingDetailsSheet({required this.bookingId});
  final int bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(bookingSummaryProvider(bookingId));
    final isSingleAppointment = summary?.itemsCount == 1;
    final deleteTitle = isSingleAppointment
        ? l10n.deleteAppointmentConfirmTitle
        : l10n.deleteBookingConfirmTitle;
    final deleteMessage = isSingleAppointment
        ? l10n.deleteAppointmentConfirmMessage
        : l10n.deleteBookingConfirmMessage;
    final bookings = ref.watch(bookingsProvider);
    final booking = bookings[bookingId];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.bookingDetails,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (summary != null) ...[
              Row(
                children: [
                  Text('${l10n.bookingItems}: '),
                  Text(
                    '${summary.itemsCount}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  Text('${l10n.bookingTotal}: '),
                  Text(
                    '${summary.totalPrice.toStringAsFixed(2)}€',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              l10n.bookingNotes,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: booking?.notes ?? '',
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => ref
                  .read(bookingsProvider.notifier)
                  .setNotes(bookingId, v.trim().isEmpty ? null : v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(deleteTitle),
                          content: Text(deleteMessage),
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
                            .deleteBooking(bookingId);
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                    child: Text(l10n.actionDeleteBooking),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
