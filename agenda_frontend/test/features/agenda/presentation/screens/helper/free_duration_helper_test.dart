import 'package:agenda_frontend/core/models/appointment.dart';
import 'package:agenda_frontend/features/agenda/domain/config/layout_config.dart';
import 'package:agenda_frontend/features/agenda/presentation/screens/helper/free_duration_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeFreeDurationForSlot', () {
    final layout = LayoutConfig.initial; // 15 min slots, 96 total

    DateTime day(int h, int m) => DateTime(2025, 1, 1, h, m);

    test('returns extended free minutes when slot is totally free', () {
      // No appointments; for index corresponding to 09:00 (index 36),
      // free duration should be until end of day.
      final index0900 = (9 * 60) ~/ layout.minutesPerSlot; // 36
      final result = computeFreeDurationForSlot(index0900, const [], layout);
      final expectedMinutes =
          (layout.totalSlots - index0900) * layout.minutesPerSlot;
      expect(result.inMinutes, expectedMinutes);
    });

    test('returns partial free minutes when slot is partially occupied', () {
      // Slot 09:00-09:15 (index 36). Appointment from 09:05 to 09:10 occupies 5 minutes.
      // Free minutes inside the slot should be 10.
      final index0900 = (9 * 60) ~/ layout.minutesPerSlot; // 36
      final appts = [
        Appointment(
          id: 1,
          bookingId: 1,
          businessId: 1,
          locationId: 1,
          staffId: 1,
          serviceId: 1,
          serviceVariantId: 1,
          clientName: 'A',
          serviceName: 'S',
          startTime: day(9, 5),
          endTime: day(9, 10),
        ),
      ];

      final result = computeFreeDurationForSlot(index0900, appts, layout);
      expect(result.inMinutes, 10);
    });

    test('returns zero when slot is fully occupied', () {
      // Slot 09:00-09:15 (index 36). Appointment fully covers the slot.
      final index0900 = (9 * 60) ~/ layout.minutesPerSlot; // 36
      final appts = [
        Appointment(
          id: 1,
          bookingId: 1,
          businessId: 1,
          locationId: 1,
          staffId: 1,
          serviceId: 1,
          serviceVariantId: 1,
          clientName: 'A',
          serviceName: 'S',
          startTime: day(9, 0),
          endTime: day(9, 15),
        ),
      ];

      final result = computeFreeDurationForSlot(index0900, appts, layout);
      expect(result.inMinutes, 0);
    });
  });
}
