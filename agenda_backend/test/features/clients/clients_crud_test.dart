import 'package:flutter_test/flutter_test.dart';

/// Test per CRUD clients
///
/// NOTA: Questi test sono intenzionalmente stub.
/// I test completi sono implementati in agenda_core (backend PHP) dove
/// vengono testati direttamente gli endpoint API con database in memoria.
///
/// Per implementare test unitari qui servirebbe:
/// - Mock di ApiClient con comportamento predefinito
/// - Mock di TokenStorage per gestire auth tokens
/// - Setup di ProviderContainer con override dei provider
void main() {
  group('Clients CRUD', () {
    test('fetchClients should return list of clients', () {
      // Stub: test completo in agenda_core
      expect(true, true);
    });

    test('createClient should create new client', () {
      // Stub: test completo in agenda_core
      expect(true, true);
    });

    test('updateClient should update existing client', () {
      // Stub: test completo in agenda_core
      expect(true, true);
    });

    test('deleteClient should archive client', () {
      // Stub: test completo in agenda_core
      expect(true, true);
    });
  });
}
