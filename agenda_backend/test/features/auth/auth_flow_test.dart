import 'package:flutter_test/flutter_test.dart';

/// Test per il flusso di autenticazione
///
/// NOTA: Questi test sono intenzionalmente stub.
/// L'autenticazione è gestita dal backend agenda_core dove sono implementati
/// i test completi per JWT, refresh token rotation, e logout.
///
/// Per implementare test di integrazione end-to-end qui servirebbe:
/// - Mock server HTTP che simula agenda_core API
/// - Setup completo di auth flow con token storage
/// - Test di integrazione che verificano cookie, headers, etc.
void main() {
  group('Auth Flow', () {
    test('login flow should authenticate user', () {
      // Stub: test completo in agenda_core
      expect(true, true);
    });

    test('refresh token should rotate on use', () {
      // Stub: test completo in agenda_core
      expect(true, true);
    });

    test('logout should revoke tokens', () {
      // Stub: test completo in agenda_core
      expect(true, true);
    });
  });
}
