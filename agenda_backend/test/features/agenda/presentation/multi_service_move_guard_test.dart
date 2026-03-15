import 'package:agenda_backend/core/models/appointment.dart';
import 'package:agenda_backend/features/agenda/presentation/utils/multi_service_move_guard.dart';
import 'package:flutter_test/flutter_test.dart';

Appointment _appointment({
  required int id,
  required int bookingId,
  required int staffId,
  required DateTime start,
  required DateTime end,
}) {
  return Appointment(
    id: id,
    bookingId: bookingId,
    businessId: 1,
    locationId: 1,
    staffId: staffId,
    serviceId: 10,
    serviceVariantId: 100,
    clientName: 'Cliente',
    serviceName: 'Servizio',
    startTime: start,
    endTime: end,
  );
}

void main() {
  group('multi_service_move_guard', () {
    test('isMultiServiceBooking true only for bookings with more than one item', () {
      final start = DateTime(2026, 1, 10, 9, 0);
      final single = [
        _appointment(
          id: 1,
          bookingId: 50,
          staffId: 3,
          start: start,
          end: start.add(const Duration(minutes: 30)),
        ),
      ];
      final multiple = [
        ...single,
        _appointment(
          id: 2,
          bookingId: 50,
          staffId: 4,
          start: start.add(const Duration(minutes: 30)),
          end: start.add(const Duration(minutes: 60)),
        ),
      ];

      expect(isMultiServiceBooking(single), isFalse);
      expect(isMultiServiceBooking(multiple), isTrue);
    });

    test('buildBookingMoveSession keeps all items sorted by start then id', () {
      final day = DateTime(2026, 2, 15, 0, 0);
      final apptA = _appointment(
        id: 20,
        bookingId: 77,
        staffId: 5,
        start: DateTime(2026, 2, 15, 10, 0),
        end: DateTime(2026, 2, 15, 10, 30),
      );
      final apptB = _appointment(
        id: 10,
        bookingId: 77,
        staffId: 6,
        start: DateTime(2026, 2, 15, 9, 30),
        end: DateTime(2026, 2, 15, 10, 0),
      );

      final session = buildBookingMoveSession(
        bookingId: 77,
        anchorAppointmentId: apptA.id,
        originDate: day,
        bookingAppointments: [apptA, apptB],
      );

      expect(session.bookingId, 77);
      expect(session.anchorAppointmentId, 20);
      expect(session.originDate, DateTime(2026, 2, 15));
      expect(session.items.map((i) => i.appointmentId).toList(), [10, 20]);
    });

    test('isFirstItemInBooking true only for the first sorted appointment', () {
      final first = _appointment(
        id: 1,
        bookingId: 51,
        staffId: 3,
        start: DateTime(2026, 3, 2, 9, 0),
        end: DateTime(2026, 3, 2, 9, 30),
      );
      final second = _appointment(
        id: 2,
        bookingId: 51,
        staffId: 4,
        start: DateTime(2026, 3, 2, 10, 0),
        end: DateTime(2026, 3, 2, 10, 30),
      );

      expect(
        isFirstItemInBooking(
          appointment: first,
          bookingAppointments: [second, first],
        ),
        isTrue,
      );
      expect(
        isFirstItemInBooking(
          appointment: second,
          bookingAppointments: [second, first],
        ),
        isFalse,
      );
    });
  });
}
