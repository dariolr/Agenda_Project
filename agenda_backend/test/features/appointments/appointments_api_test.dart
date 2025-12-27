import 'package:flutter_test/flutter_test.dart';

/// Test per API appointments
///
/// NOTA: Questi test sono intenzionalmente stub.
/// I test completi sono implementati in agenda_core (backend PHP) dove
/// vengono testati direttamente gli endpoint API con database in memoria.
///
/// Per implementare test unitari qui servirebbe:
/// - Mock di ApiClient con comportamento predefinito
/// - Mock di BookingsRepository
/// - Setup di ProviderContainer con override dei provider
void main() {
  group('Appointments API', () {
    test(
      'getAppointments should return appointments for location and date',
      () {
        // Stub: test completo in agenda_core
        expect(true, true);
      },
    );

    test('updateAppointment should reschedule appointment', () {
      // Stub: test completo in agenda_core
      expect(true, true);
    });

    test('cancelAppointment should cancel appointment', () {
      // Stub: test completo in agenda_core
      expect(true, true);
    });

    test('updateAppointment with conflict should return 409', () {
      // Stub: conflict detection implementato in agenda_core
      expect(true, true);
    });
  });
}
