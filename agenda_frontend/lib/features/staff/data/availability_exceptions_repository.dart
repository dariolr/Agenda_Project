import 'package:flutter/material.dart';

import '../../../core/models/availability_exception.dart';

/// Repository per la gestione delle eccezioni alla disponibilità.
///
/// Implementazione mock locale. In futuro può essere sostituita
/// con un'implementazione che comunica con il backend API.
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

/// Implementazione mock del repository per le eccezioni.
class MockAvailabilityExceptionsRepository
    implements AvailabilityExceptionsRepository {
  final List<AvailabilityException> _exceptions = [];
  int _nextId = 1;

  MockAvailabilityExceptionsRepository() {
    _initMockData();
  }

  void _initMockData() {
    // Dati mock di esempio
    final today = DateTime.now();

    // Eccezione: Dario non lavora domani (ferie)
    _exceptions.add(
      AvailabilityException.allDay(
        id: _nextId++,
        staffId: 1,
        date: today.add(const Duration(days: 1)),
        type: AvailabilityExceptionType.unavailable,
        reasonCode: 'vacation',
      ),
    );

    // Eccezione: Sara lavora sabato prossimo (turno extra)
    final nextSaturday = today.add(Duration(days: (6 - today.weekday + 7) % 7));
    _exceptions.add(
      AvailabilityException.timeRange(
        id: _nextId++,
        staffId: 3,
        date: nextSaturday,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
        type: AvailabilityExceptionType.available,
        reasonCode: 'extra_shift',
      ),
    );

    // Eccezione: Luca visita medica tra 3 giorni (mattina)
    _exceptions.add(
      AvailabilityException.timeRange(
        id: _nextId++,
        staffId: 2,
        date: today.add(const Duration(days: 3)),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        type: AvailabilityExceptionType.unavailable,
        reasonCode: 'medical_visit',
      ),
    );
  }

  @override
  Future<List<AvailabilityException>> getExceptionsForStaff(
    int staffId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    return _exceptions.where((e) {
      if (e.staffId != staffId) return false;
      if (fromDate != null && e.date.isBefore(fromDate)) return false;
      if (toDate != null && e.date.isAfter(toDate)) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<AvailabilityException>> getExceptionsForDate(
    DateTime date,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final targetDate = DateUtils.dateOnly(date);
    return _exceptions.where((e) => e.isOnDate(targetDate)).toList();
  }

  @override
  Future<AvailabilityException?> getException(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      return _exceptions.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AvailabilityException> addException(
    AvailabilityException exception,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final newException = exception.copyWith(id: _nextId++);
    _exceptions.add(newException);
    return newException;
  }

  @override
  Future<AvailabilityException> updateException(
    AvailabilityException exception,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final index = _exceptions.indexWhere((e) => e.id == exception.id);
    if (index == -1) {
      throw Exception('Exception not found: ${exception.id}');
    }

    _exceptions[index] = exception;
    return exception;
  }

  @override
  Future<void> deleteException(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));

    _exceptions.removeWhere((e) => e.id == id);
  }
}
