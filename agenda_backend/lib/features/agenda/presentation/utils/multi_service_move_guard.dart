import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/appointment.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/booking_reschedule_provider.dart';

enum MultiServiceMoveDecision {
  moveWholeBooking,
  splitSingleService,
  cancel,
}

class MoveConfirmResult {
  const MoveConfirmResult({
    required this.confirmed,
    required this.notifyClient,
  });

  final bool confirmed;
  final bool notifyClient;
}

bool isMultiServiceBooking(List<Appointment> bookingAppointments) {
  return bookingAppointments.length > 1;
}

DateTime? bookingFirstStart(List<Appointment> bookingAppointments) {
  if (bookingAppointments.isEmpty) return null;
  final sorted = [...bookingAppointments]
    ..sort((a, b) {
      final byStart = a.startTime.compareTo(b.startTime);
      if (byStart != 0) return byStart;
      return a.id.compareTo(b.id);
    });
  return sorted.first.startTime;
}

bool isFirstItemInBooking({
  required Appointment appointment,
  required List<Appointment> bookingAppointments,
}) {
  final sorted = [...bookingAppointments]
    ..sort((a, b) {
      final byStart = a.startTime.compareTo(b.startTime);
      if (byStart != 0) return byStart;
      return a.id.compareTo(b.id);
    });

  if (sorted.isEmpty) {
    return false;
  }

  return sorted.first.id == appointment.id;
}

bool willBookingFirstStartChangeOnSingleMove({
  required Appointment movingAppointment,
  required DateTime newStart,
  required List<Appointment> bookingAppointments,
}) {
  final previous = bookingFirstStart(bookingAppointments);
  if (previous == null) return false;

  DateTime next = previous;
  if (movingAppointment.startTime.isAtSameMomentAs(previous)) {
    next = newStart;
    for (final appt in bookingAppointments) {
      if (appt.id == movingAppointment.id) continue;
      if (appt.startTime.isBefore(next)) {
        next = appt.startTime;
      }
    }
  } else if (newStart.isBefore(previous)) {
    next = newStart;
  }

  return !next.isAtSameMomentAs(previous);
}

bool willBookingFirstStartChangeOnWholeMove({
  required Appointment anchorAppointment,
  required DateTime targetStart,
  required List<Appointment> bookingAppointments,
}) {
  final previous = bookingFirstStart(bookingAppointments);
  if (previous == null) return false;
  final delta = targetStart.difference(anchorAppointment.startTime);
  final next = previous.add(delta);
  return !next.isAtSameMomentAs(previous);
}

bool willBookingFirstStartChangeForRescheduleSession({
  required BookingRescheduleSession session,
  required DateTime targetStart,
}) {
  if (session.items.isEmpty) return false;
  DateTime previous = session.items.first.startTime;
  for (final item in session.items) {
    if (item.startTime.isBefore(previous)) {
      previous = item.startTime;
    }
  }
  return !targetStart.isAtSameMomentAs(previous);
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
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.multiServiceMoveDecisionTitle),
      content: Text(l10n.multiServiceMoveDecisionMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(
            dialogContext,
            rootNavigator: true,
          ).pop(MultiServiceMoveDecision.cancel),
          child: Text(l10n.actionCancel),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(
            dialogContext,
            rootNavigator: true,
          ).pop(MultiServiceMoveDecision.splitSingleService),
          child: Text(l10n.multiServiceMoveDecisionSplitService),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(
            dialogContext,
            rootNavigator: true,
          ).pop(MultiServiceMoveDecision.moveWholeBooking),
          child: Text(l10n.multiServiceMoveDecisionMoveBooking),
        ),
      ],
    ),
  );
  return result ?? MultiServiceMoveDecision.cancel;
}

Future<MoveConfirmResult> showMoveConfirmDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
  required String confirmLabel,
  required String cancelLabel,
  required bool showNotifyOption,
  bool notifyDefault = true,
}) async {
  if (!showNotifyOption) {
    final confirmed = await showConfirmDialog(
      context,
      title: title,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    );
    return MoveConfirmResult(confirmed: confirmed, notifyClient: true);
  }

  bool notifyClient = notifyDefault;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: title,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => notifyClient = !notifyClient),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: notifyClient,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) {
                              setState(() => notifyClient = value ?? true);
                            },
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(context.l10n.moveConfirmNotifyCheckbox),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext, rootNavigator: true).pop(false),
                child: Text(cancelLabel),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(dialogContext, rootNavigator: true).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      );
    },
  );

  return MoveConfirmResult(
    confirmed: result == true,
    notifyClient: notifyClient,
  );
}

Future<void> showSplitMoveNotAvailableGuardrail(BuildContext context) async {
  final l10n = context.l10n;
  await FeedbackDialog.showError(
    context,
    title: l10n.multiServiceMoveSplitUnavailableTitle,
    message: l10n.multiServiceMoveSplitUnavailableMessage,
  );
}

Future<void> showNonFirstServiceMoveBlockedGuardrail(BuildContext context) async {
  final l10n = context.l10n;
  await FeedbackDialog.showError(
    context,
    title: l10n.multiServiceNonFirstMoveBlockedTitle,
    message: l10n.multiServiceNonFirstMoveBlockedMessage,
  );
}

Future<MoveBookingByAnchorResult> moveWholeBookingFromAnchor({
  required WidgetRef ref,
  required BuildContext context,
  required Appointment anchorAppointment,
  required DateTime targetStart,
  required int targetStaffId,
  required List<Appointment> bookingAppointments,
  bool notifyClient = true,
}) async {
  final session = buildBookingMoveSession(
    bookingId: anchorAppointment.bookingId,
    anchorAppointmentId: anchorAppointment.id,
    originDate: anchorAppointment.startTime,
    bookingAppointments: bookingAppointments,
  );

  final result = await ref.read(appointmentsProvider.notifier).moveBookingByAnchor(
        session: session,
        targetStart: targetStart,
        targetStaffId: targetStaffId,
        notifyClient: notifyClient,
      );

  if (result != MoveBookingByAnchorResult.success && context.mounted) {
    final l10n = context.l10n;
    final message = result == MoveBookingByAnchorResult.outOfTargetDay
        ? l10n.bookingRescheduleOutOfDayBlocked
        : l10n.bookingRescheduleMoveFailed;
    await FeedbackDialog.showError(
      context,
      title: l10n.errorTitle,
      message: message,
    );
  }
  return result;
}
