import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/appointment.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/booking_reschedule_provider.dart';

enum MultiServiceMoveDecision {
  moveWholeBooking,
  splitSingleService,
  cancel,
}

bool isMultiServiceBooking(List<Appointment> bookingAppointments) {
  return bookingAppointments.length > 1;
}

BookingRescheduleSession buildBookingMoveSession({
  required int bookingId,
  required int anchorAppointmentId,
  required DateTime originDate,
  required List<Appointment> bookingAppointments,
}) {
  final sorted = [...bookingAppointments]
    ..sort((a, b) {
      final byStart = a.startTime.compareTo(b.startTime);
      if (byStart != 0) return byStart;
      return a.id.compareTo(b.id);
    });

  return BookingRescheduleSession(
    bookingId: bookingId,
    originDate: DateUtils.dateOnly(originDate),
    anchorAppointmentId: anchorAppointmentId,
    items: [
      for (final appt in sorted)
        BookingRescheduleItemSnapshot(
          appointmentId: appt.id,
          staffId: appt.staffId,
          startTime: appt.startTime,
          endTime: appt.endTime,
          blockedExtraMinutes: appt.blockedExtraMinutes,
        ),
    ],
  );
}

Future<MultiServiceMoveDecision> showMultiServiceMoveDecisionDialog(
  BuildContext context,
) async {
  final l10n = context.l10n;
  final result = await showDialog<MultiServiceMoveDecision>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(l10n.multiServiceMoveDecisionTitle),
      content: Text(l10n.multiServiceMoveDecisionMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(MultiServiceMoveDecision.cancel),
          child: Text(l10n.actionCancel),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(MultiServiceMoveDecision.splitSingleService),
          child: Text(l10n.multiServiceMoveDecisionSplitService),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(MultiServiceMoveDecision.moveWholeBooking),
          child: Text(l10n.multiServiceMoveDecisionMoveBooking),
        ),
      ],
    ),
  );
  return result ?? MultiServiceMoveDecision.cancel;
}

Future<void> showSplitMoveNotAvailableGuardrail(BuildContext context) async {
  final l10n = context.l10n;
  await FeedbackDialog.showError(
    context,
    title: l10n.multiServiceMoveSplitUnavailableTitle,
    message: l10n.multiServiceMoveSplitUnavailableMessage,
  );
}

Future<bool> moveWholeBookingFromAnchor({
  required WidgetRef ref,
  required BuildContext context,
  required Appointment anchorAppointment,
  required DateTime targetStart,
  required int targetStaffId,
  required List<Appointment> bookingAppointments,
}) async {
  final session = buildBookingMoveSession(
    bookingId: anchorAppointment.bookingId,
    anchorAppointmentId: anchorAppointment.id,
    originDate: anchorAppointment.startTime,
    bookingAppointments: bookingAppointments,
  );

  final success = await ref.read(appointmentsProvider.notifier).moveBookingByAnchor(
        session: session,
        targetStart: targetStart,
        targetStaffId: targetStaffId,
      );

  if (!success && context.mounted) {
    final l10n = context.l10n;
    await FeedbackDialog.showError(
      context,
      title: l10n.errorTitle,
      message: l10n.bookingRescheduleMoveFailed,
    );
  }
  return success;
}
