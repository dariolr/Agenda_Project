import '../../../core/models/availability_exception.dart';

/// Repository per la gestione delle eccezioni alla disponibilità.
///
/// Implementazione API in `api_availability_exceptions_repository.dart`.
abstract class AvailabilityExceptionsRepository {
  /// Carica tutte le eccezioni per uno staff in un range di date.
  Future<List<AvailabilityException>> getExceptionsForStaff(
    int staffId, {
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Carica tutte le eccezioni per una data specifica (tutti gli staff).
  Future<List<AvailabilityException>> getExceptionsForDate(DateTime date);

  /// Carica un'eccezione per ID.
  Future<AvailabilityException?> getException(int id);

  /// Aggiunge una nuova eccezione.
  Future<AvailabilityException> addException(AvailabilityException exception);

  /// Aggiorna un'eccezione esistente.
  Future<AvailabilityException> updateException(
    AvailabilityException exception,
  );

  /// Elimina un'eccezione.
  Future<void> deleteException(int id);
}
