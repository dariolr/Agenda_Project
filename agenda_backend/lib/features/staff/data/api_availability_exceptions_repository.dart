import 'package:flutter/material.dart';

import '../../../core/models/availability_exception.dart';
import '../../../core/network/api_client.dart';
import 'availability_exceptions_repository.dart';

/// Implementazione del repository per le eccezioni che usa l'API reale.
class ApiAvailabilityExceptionsRepository
    implements AvailabilityExceptionsRepository {
  final ApiClient _apiClient;
  final int _businessId;

  // Cache locale per evitare chiamate API ripetute
  final Map<int, List<AvailabilityException>> _cache = {};
  DateTime? _cacheValidUntil;

  ApiAvailabilityExceptionsRepository({
    required ApiClient apiClient,
    required int businessId,
  }) : _apiClient = apiClient,
       _businessId = businessId;

  bool get _isCacheValid =>
      _cacheValidUntil != null && DateTime.now().isBefore(_cacheValidUntil!);

  void _invalidateCache() {
    _cache.clear();
    _cacheValidUntil = null;
  }

  /// Carica tutte le eccezioni per il business e popola la cache.
  Future<void> _loadAllExceptions({String? fromDate, String? toDate}) async {
    final result = await _apiClient.getStaffAvailabilityExceptionsAll(
      _businessId,
      fromDate: fromDate,
      toDate: toDate,
    );

    _cache.clear();
    for (final entry in result.entries) {
      _cache[entry.key] = entry.value.map(_parseException).toList();
    }
    // Cache valida per 5 minuti
    _cacheValidUntil = DateTime.now().add(const Duration(minutes: 5));
  }

  AvailabilityException _parseException(Map<String, dynamic> json) {
    final type = json['type'] == 'available'
        ? AvailabilityExceptionType.available
        : AvailabilityExceptionType.unavailable;

    final date = DateTime.parse(json['date'] as String);

    TimeOfDay? startTime;
    TimeOfDay? endTime;

    if (json['start_time'] != null) {
      final parts = (json['start_time'] as String).split(':');
      startTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    if (json['end_time'] != null) {
      final parts = (json['end_time'] as String).split(':');
      endTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    if (startTime != null && endTime != null) {
      return AvailabilityException.timeRange(
        id: json['id'] as int,
        staffId: json['staff_id'] as int,
        date: date,
        startTime: startTime,
        endTime: endTime,
        type: type,
        reasonCode: json['reason_code'] as String?,
        reason: json['reason'] as String?,
      );
    } else {
      return AvailabilityException.allDay(
        id: json['id'] as int,
        staffId: json['staff_id'] as int,
        date: date,
        type: type,
        reasonCode: json['reason_code'] as String?,
        reason: json['reason'] as String?,
      );
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<List<AvailabilityException>> getExceptionsForStaff(
    int staffId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    // Se la cache è valida, usa quella
    if (_isCacheValid && _cache.containsKey(staffId)) {
      var exceptions = _cache[staffId]!;
      if (fromDate != null) {
        exceptions = exceptions
            .where((e) => !e.date.isBefore(fromDate))
            .toList();
      }
      if (toDate != null) {
        exceptions = exceptions.where((e) => !e.date.isAfter(toDate)).toList();
      }
      return exceptions;
    }

    // Carica da API
    final result = await _apiClient.getStaffAvailabilityExceptions(
      staffId,
      fromDate: fromDate != null ? _formatDate(fromDate) : null,
      toDate: toDate != null ? _formatDate(toDate) : null,
    );

    final exceptions = result.map(_parseException).toList();
    _cache[staffId] = exceptions;

    return exceptions;
  }

  @override
  Future<List<AvailabilityException>> getExceptionsForDate(
    DateTime date,
  ) async {
    // Carica tutte le eccezioni se cache non valida
    if (!_isCacheValid) {
      await _loadAllExceptions();
    }

    final targetDate = DateUtils.dateOnly(date);
    final result = <AvailabilityException>[];

    for (final exceptions in _cache.values) {
      for (final e in exceptions) {
        if (e.isOnDate(targetDate)) {
          result.add(e);
        }
      }
    }

    return result;
  }

  @override
  Future<AvailabilityException?> getException(int id) async {
    // Cerca prima nella cache
    for (final exceptions in _cache.values) {
      for (final e in exceptions) {
        if (e.id == id) return e;
      }
    }

    // Non trovato in cache - in futuro potremmo aggiungere endpoint GET /v1/staff/availability-exceptions/{id}
    return null;
  }

  @override
  Future<AvailabilityException> addException(
    AvailabilityException exception,
  ) async {
    final result = await _apiClient.createStaffAvailabilityException(
      staffId: exception.staffId,
      date: _formatDate(exception.date),
      startTime: exception.startTime != null
          ? _formatTime(exception.startTime!)
          : null,
      endTime: exception.endTime != null
          ? _formatTime(exception.endTime!)
          : null,
      type: exception.type == AvailabilityExceptionType.available
          ? 'available'
          : 'unavailable',
      reasonCode: exception.reasonCode,
      reason: exception.reason,
    );

    final created = _parseException(result);

    // Aggiorna cache
    _cache.putIfAbsent(created.staffId, () => []);
    _cache[created.staffId]!.add(created);

    return created;
  }

  @override
  Future<AvailabilityException> updateException(
    AvailabilityException exception,
  ) async {
    final result = await _apiClient.updateStaffAvailabilityException(
      exceptionId: exception.id,
      date: _formatDate(exception.date),
      startTime: exception.startTime != null
          ? _formatTime(exception.startTime!)
          : null,
      endTime: exception.endTime != null
          ? _formatTime(exception.endTime!)
          : null,
      type: exception.type == AvailabilityExceptionType.available
          ? 'available'
          : 'unavailable',
      reasonCode: exception.reasonCode,
      reason: exception.reason,
    );

    final updated = _parseException(result);

    // Aggiorna cache
    if (_cache.containsKey(updated.staffId)) {
      final index = _cache[updated.staffId]!.indexWhere(
        (e) => e.id == updated.id,
      );
      if (index != -1) {
        _cache[updated.staffId]![index] = updated;
      }
    }

    return updated;
  }

  @override
  Future<void> deleteException(int id) async {
    await _apiClient.deleteStaffAvailabilityException(id);

    // Rimuovi dalla cache
    for (final exceptions in _cache.values) {
      exceptions.removeWhere((e) => e.id == id);
    }
  }

  /// Forza il refresh della cache.
  void refresh() {
    _invalidateCache();
  }
}
