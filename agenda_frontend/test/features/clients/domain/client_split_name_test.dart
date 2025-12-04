import 'package:agenda_frontend/features/clients/domain/clients.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Client.splitFullName', () {
    test('nome singolo -> solo firstName', () {
      final result = Client.splitFullName('Mario');
      expect(result.firstName, 'Mario');
      expect(result.lastName, isNull);
    });

    test('nome e cognome semplice', () {
      final result = Client.splitFullName('Mario Rossi');
      expect(result.firstName, 'Mario');
      expect(result.lastName, 'Rossi');
    });

    test('cognome composto con "La"', () {
      final result = Client.splitFullName('Dario La Rosa');
      expect(result.firstName, 'Dario');
      expect(result.lastName, 'La Rosa');
    });

    test('cognome composto con "De"', () {
      final result = Client.splitFullName('Giuseppe De Luca');
      expect(result.firstName, 'Giuseppe');
      expect(result.lastName, 'De Luca');
    });

    test('cognome composto con "Della"', () {
      final result = Client.splitFullName('Maria Della Valle');
      expect(result.firstName, 'Maria');
      expect(result.lastName, 'Della Valle');
    });

    test('cognome composto con "Van" (olandese)', () {
      final result = Client.splitFullName('Giovanni Van Damme');
      expect(result.firstName, 'Giovanni');
      expect(result.lastName, 'Van Damme');
    });

    test('nome composto + cognome semplice', () {
      final result = Client.splitFullName('Mario Giuseppe Rossi');
      expect(result.firstName, 'Mario Giuseppe');
      expect(result.lastName, 'Rossi');
    });

    test('nome composto + cognome composto', () {
      final result = Client.splitFullName('Anna Maria De Santis');
      expect(result.firstName, 'Anna Maria');
      expect(result.lastName, 'De Santis');
    });

    test('cognome composto con "Di"', () {
      final result = Client.splitFullName('Francesco Di Maio');
      expect(result.firstName, 'Francesco');
      expect(result.lastName, 'Di Maio');
    });

    test('cognome composto con "Lo"', () {
      final result = Client.splitFullName('Salvatore Lo Presti');
      expect(result.firstName, 'Salvatore');
      expect(result.lastName, 'Lo Presti');
    });

    test('stringa vuota -> null per entrambi', () {
      final result = Client.splitFullName('');
      expect(result.firstName, isNull);
      expect(result.lastName, isNull);
    });

    test('stringa con spazi -> null per entrambi', () {
      final result = Client.splitFullName('   ');
      expect(result.firstName, isNull);
      expect(result.lastName, isNull);
    });

    test('spazi multipli tra parole', () {
      final result = Client.splitFullName('Mario   Rossi');
      expect(result.firstName, 'Mario');
      expect(result.lastName, 'Rossi');
    });
  });
}
