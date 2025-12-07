import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/availability_exception.dart';
import '../data/availability_exceptions_repository.dart';

/// Provider per il repository delle eccezioni.
/// Utilizza un'implementazione mock, sostituibile con API reale.
final availabilityExceptionsRepositoryProvider =
    Provider<AvailabilityExceptionsRepository>((ref) {
      return MockAvailabilityExceptionsRepository();
    });

/// Provider per la gestione dello stato delle eccezioni.
///
/// Stato: `Map<staffId, List<AvailabilityException>>`
/// Carica le eccezioni on-demand quando richieste per uno staff specifico.
class AvailabilityExceptionsNotifier
    extends AsyncNotifier<Map<int, List<AvailabilityException>>> {
  @override
  Future<Map<int, List<AvailabilityException>>> build() async {
    // Inizialmente vuoto, le eccezioni vengono caricate on-demand
    return {};
  }

  AvailabilityExceptionsRepository get _repository =>
      ref.read(availabilityExceptionsRepositoryProvider);

  /// Carica le eccezioni per uno staff specifico in un range di date.
  /// Se [fromDate] e [toDate] non sono specificati, carica tutte le eccezioni.
  Future<void> loadExceptionsForStaff(
    int staffId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final current = state.value ?? {};

    final exceptions = await _repository.getExceptionsForStaff(
      staffId,
      fromDate: fromDate,
      toDate: toDate,
    );

    state = AsyncData({...current, staffId: exceptions});
  }

  /// Aggiunge una nuova eccezione.
  Future<AvailabilityException> addException({
    required int staffId,
    required DateTime date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    required AvailabilityExceptionType type,
    String? reason,
  }) async {
    final exception = startTime != null && endTime != null
        ? AvailabilityException.timeRange(
            id: 0, // Il repository assegnerà l'ID reale
            staffId: staffId,
            date: date,
            startTime: startTime,
            endTime: endTime,
            type: type,
            reason: reason,
          )
        : AvailabilityException.allDay(
            id: 0,
            staffId: staffId,
            date: date,
            type: type,
            reason: reason,
          );

    final saved = await _repository.addException(exception);

    // Aggiorna lo stato locale
    final current = state.value ?? {};
    final staffExceptions = List<AvailabilityException>.from(
      current[staffId] ?? [],
    );
    staffExceptions.add(saved);

    state = AsyncData({...current, staffId: staffExceptions});

    return saved;
  }

  /// Aggiunge eccezioni per un periodo (batch).
  /// Crea un'eccezione per ogni giorno nel range [startDate, endDate].
  Future<List<AvailabilityException>> addExceptionsForPeriod({
    required int staffId,
    required DateTime startDate,
    required DateTime endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    required AvailabilityExceptionType type,
    String? reason,
  }) async {
    final List<AvailabilityException> created = [];

    // Normalizza le date
    var currentDate = DateUtils.dateOnly(startDate);
    final lastDate = DateUtils.dateOnly(endDate);

    // Crea un'eccezione per ogni giorno
    while (!currentDate.isAfter(lastDate)) {
      final exception = startTime != null && endTime != null
          ? AvailabilityException.timeRange(
              id: 0,
              staffId: staffId,
              date: currentDate,
              startTime: startTime,
              endTime: endTime,
              type: type,
              reason: reason,
            )
          : AvailabilityException.allDay(
              id: 0,
              staffId: staffId,
              date: currentDate,
              type: type,
              reason: reason,
            );

      final saved = await _repository.addException(exception);
      created.add(saved);

      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Aggiorna lo stato locale con tutte le eccezioni create
    final current = state.value ?? {};
    final staffExceptions = List<AvailabilityException>.from(
      current[staffId] ?? [],
    );
    staffExceptions.addAll(created);

    state = AsyncData({...current, staffId: staffExceptions});

    return created;
  }

  /// Aggiorna un'eccezione esistente.
  Future<AvailabilityException> updateException(
    AvailabilityException exception,
  ) async {
    final updated = await _repository.updateException(exception);

    // Aggiorna lo stato locale
    final current = state.value ?? {};
    final staffExceptions = List<AvailabilityException>.from(
      current[exception.staffId] ?? [],
    );
    final index = staffExceptions.indexWhere((e) => e.id == exception.id);
    if (index != -1) {
      staffExceptions[index] = updated;
    }

    state = AsyncData({...current, exception.staffId: staffExceptions});

    return updated;
  }

  /// Elimina un'eccezione.
  Future<void> deleteException(int staffId, int exceptionId) async {
    await _repository.deleteException(exceptionId);

    // Aggiorna lo stato locale
    final current = state.value ?? {};
    final staffExceptions = List<AvailabilityException>.from(
      current[staffId] ?? [],
    );
    staffExceptions.removeWhere((e) => e.id == exceptionId);

    state = AsyncData({...current, staffId: staffExceptions});
  }

  /// Ottiene le eccezioni per uno staff in una data specifica (sincronamente dallo stato).
  List<AvailabilityException> getExceptionsForStaffOnDate(
    int staffId,
    DateTime date,
  ) {
    final current = state.value ?? {};
    final staffExceptions = current[staffId] ?? [];
    return staffExceptions.where((e) => e.isOnDate(date)).toList();
  }
}

final availabilityExceptionsProvider =
    AsyncNotifierProvider<
      AvailabilityExceptionsNotifier,
      Map<int, List<AvailabilityException>>
    >(AvailabilityExceptionsNotifier.new);

/// Provider derivato: eccezioni per uno staff specifico in una data specifica.
/// Utile per query puntuali nella UI.
final exceptionsForStaffOnDateProvider =
    Provider.family<
      List<AvailabilityException>,
      ({int staffId, DateTime date})
    >((ref, params) {
      final allExceptions = ref.watch(availabilityExceptionsProvider);

      return allExceptions.maybeWhen(
        data: (data) {
          final staffExceptions = data[params.staffId] ?? [];
          return staffExceptions.where((e) => e.isOnDate(params.date)).toList();
        },
        orElse: () => [],
      );
    });

/// Provider derivato: verifica se ci sono eccezioni per uno staff in una data.
final hasExceptionsForStaffOnDateProvider =
    Provider.family<bool, ({int staffId, DateTime date})>((ref, params) {
      final exceptions = ref.watch(exceptionsForStaffOnDateProvider(params));
      return exceptions.isNotEmpty;
    });

/// Provider derivato: tutte le eccezioni per uno staff (lista flat).
final allExceptionsForStaffProvider =
    Provider.family<List<AvailabilityException>, int>((ref, staffId) {
      final allExceptions = ref.watch(availabilityExceptionsProvider);

      return allExceptions.maybeWhen(
        data: (data) => data[staffId] ?? [],
        orElse: () => [],
      );
    });
