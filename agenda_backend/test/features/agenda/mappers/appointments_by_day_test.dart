import 'package:agenda_backend/core/models/appointment.dart';
import 'package:agenda_backend/features/agenda/mappers/appointments_by_day.dart';
import 'package:agenda_backend/features/agenda/utils/week_range.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    initializeDateFormatting('en');
  });

  test('mapAppointmentsByDay groups by start day and sorts entries', () {
    final weekRange = computeWeekRange(
      DateTime(2026, 3, 4, 10),
      'Europe/Rome',
      localeTag: 'en',
    );
    final appointments = [
      _appointment(
        id: 2,
        start: DateTime(2026, 3, 4, 11),
        end: DateTime(2026, 3, 4, 12),
      ),
      _appointment(
        id: 1,
        start: DateTime(2026, 3, 4, 9),
        end: DateTime(2026, 3, 4, 10),
      ),
      _appointment(
        id: 3,
        start: DateTime(2026, 3, 6, 18),
        end: DateTime(2026, 3, 7, 1),
      ),
    ];

    final grouped = mapAppointmentsByDay(appointments, weekRange: weekRange);

    expect(grouped[DateTime(2026, 3, 4)]!.map((item) => item.id), [1, 2]);
    expect(grouped[DateTime(2026, 3, 6)]!.single.id, 3);
    expect(grouped[DateTime(2026, 3, 7)], isEmpty);
  });
}

Appointment _appointment({
  required int id,
  required DateTime start,
  required DateTime end,
}) {
  return Appointment(
    id: id,
    bookingId: id,
    businessId: 1,
    locationId: 1,
    staffId: 1,
    serviceId: 1,
    serviceVariantId: 1,
    clientName: 'Client',
    serviceName: 'Service',
    startTime: start,
    endTime: end,
  );
}
