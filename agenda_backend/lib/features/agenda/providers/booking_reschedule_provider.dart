import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/appointment.dart';

@immutable
class BookingRescheduleItemSnapshot {
  const BookingRescheduleItemSnapshot({
    required this.appointmentId,
    required this.staffId,
    required this.startTime,
    required this.endTime,
    required this.blockedExtraMinutes,
  });

  final int appointmentId;
  final int staffId;
  final DateTime startTime;
  final DateTime endTime;
  final int blockedExtraMinutes;
}

@immutable
class BookingRescheduleSession {
  const BookingRescheduleSession({
    required this.bookingId,
    required this.originDate,
    required this.anchorAppointmentId,
    required this.items,
  });

  final int bookingId;
  final DateTime originDate;
  final int anchorAppointmentId;
  final List<BookingRescheduleItemSnapshot> items;
}

class BookingRescheduleNotifier extends Notifier<BookingRescheduleSession?> {
  @override
  BookingRescheduleSession? build() => null;

  void start({
    required int bookingId,
    required DateTime originDate,
    required List<Appointment> bookingAppointments,
  }) {
    final sorted = [...bookingAppointments]
      ..sort((a, b) {
        final byStart = a.startTime.compareTo(b.startTime);
        if (byStart != 0) return byStart;
        return a.id.compareTo(b.id);
      });
    if (sorted.isEmpty) return;

    final items = sorted
        .map(
          (a) => BookingRescheduleItemSnapshot(
            appointmentId: a.id,
            staffId: a.staffId,
            startTime: a.startTime,
            endTime: a.endTime,
            blockedExtraMinutes: a.blockedExtraMinutes,
          ),
        )
        .toList(growable: false);

    state = BookingRescheduleSession(
      bookingId: bookingId,
      originDate: DateUtils.dateOnly(originDate),
      anchorAppointmentId: sorted.first.id,
      items: items,
    );
  }

  void clear() {
    state = null;
  }

  bool get isActive => state != null;
}

final bookingRescheduleSessionProvider =
    NotifierProvider<BookingRescheduleNotifier, BookingRescheduleSession?>(
      BookingRescheduleNotifier.new,
    );
