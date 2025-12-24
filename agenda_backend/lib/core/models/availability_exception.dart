import 'package:flutter/material.dart';

/// Tipo di eccezione alla disponibilità settimanale.
enum AvailabilityExceptionType {
  /// Lo staff è DISPONIBILE in questa fascia (aggiunge disponibilità).
  available,

  /// Lo staff NON è DISPONIBILE in questa fascia (rimuove disponibilità).
  unavailable,
}

/// Rappresenta un'eccezione alla disponibilità settimanale di uno staff.
///
/// A differenza del template settimanale che definisce gli orari ricorrenti,
/// le eccezioni permettono di:
/// - Aggiungere disponibilità extra in giorni/fasce specifiche
/// - Rimuovere disponibilità in giorni/fasce specifiche (ferie, malattia, ecc.)
///
/// Esempio:
/// - Template: Lun-Ven 09:00-18:00
/// - Eccezione "available": Sabato 14/12 dalle 10:00 alle 14:00 (lavoro extra)
/// - Eccezione "unavailable": Mercoledì 18/12 tutto il giorno (ferie)
class AvailabilityException {
  final int id;
  final int staffId;

  /// Data specifica dell'eccezione.
  final DateTime date;

  /// Orario di inizio. Se null insieme a [endTime], l'eccezione copre l'intera giornata.
  final TimeOfDay? startTime;

  /// Orario di fine. Se null insieme a [startTime], l'eccezione copre l'intera giornata.
  final TimeOfDay? endTime;

  /// Tipo di eccezione: disponibile o non disponibile.
  final AvailabilityExceptionType type;

  /// Codice motivo opzionale (es. "vacation", "medical_visit", "extra_shift").
  final String? reasonCode;

  /// Motivo opzionale (es. "Ferie", "Visita medica", "Turno extra").
  final String? reason;

  const AvailabilityException({
    required this.id,
    required this.staffId,
    required this.date,
    this.startTime,
    this.endTime,
    required this.type,
    this.reasonCode,
    this.reason,
  });

  /// Se true, l'eccezione copre l'intera giornata.
  bool get isAllDay => startTime == null && endTime == null;

  /// Crea un'eccezione per l'intera giornata.
  factory AvailabilityException.allDay({
    required int id,
    required int staffId,
    required DateTime date,
    required AvailabilityExceptionType type,
    String? reasonCode,
    String? reason,
  }) {
    return AvailabilityException(
      id: id,
      staffId: staffId,
      date: DateUtils.dateOnly(date),
      startTime: null,
      endTime: null,
      type: type,
      reasonCode: reasonCode,
      reason: reason,
    );
  }

  /// Crea un'eccezione per una fascia oraria specifica.
  factory AvailabilityException.timeRange({
    required int id,
    required int staffId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required AvailabilityExceptionType type,
    String? reasonCode,
    String? reason,
  }) {
    return AvailabilityException(
      id: id,
      staffId: staffId,
      date: DateUtils.dateOnly(date),
      startTime: startTime,
      endTime: endTime,
      type: type,
      reasonCode: reasonCode,
      reason: reason,
    );
  }

  AvailabilityException copyWith({
    int? id,
    int? staffId,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    AvailabilityExceptionType? type,
    String? reasonCode,
    String? reason,
    bool clearStartTime = false,
    bool clearEndTime = false,
    bool clearReasonCode = false,
    bool clearReason = false,
  }) {
    return AvailabilityException(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      date: date ?? this.date,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      type: type ?? this.type,
      reasonCode: clearReasonCode ? null : (reasonCode ?? this.reasonCode),
      reason: clearReason ? null : (reason ?? this.reason),
    );
  }

  factory AvailabilityException.fromJson(Map<String, dynamic> json) {
    return AvailabilityException(
      id: json['id'] as int,
      staffId: json['staff_id'] as int,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] != null
          ? _timeOfDayFromString(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? _timeOfDayFromString(json['end_time'] as String)
          : null,
      type: AvailabilityExceptionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AvailabilityExceptionType.unavailable,
      ),
      reasonCode: json['reason_code'] as String?,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'staff_id': staffId,
    'date': date.toIso8601String().split('T').first,
    if (startTime != null) 'start_time': _timeOfDayToString(startTime!),
    if (endTime != null) 'end_time': _timeOfDayToString(endTime!),
    'type': type.name,
    if (reasonCode != null) 'reason_code': reasonCode,
    if (reason != null) 'reason': reason,
  };

  static TimeOfDay _timeOfDayFromString(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Verifica se l'eccezione è per una data specifica.
  bool isOnDate(DateTime targetDate) {
    final target = DateUtils.dateOnly(targetDate);
    final excDate = DateUtils.dateOnly(date);
    return excDate == target;
  }

  /// Converte l'eccezione in un set di slot index.
  /// [minutesPerSlot] è tipicamente 15.
  /// Per eccezioni "all day", copre tutti gli slot della giornata.
  Set<int> toSlotIndices({
    required int minutesPerSlot,
    required int totalSlotsPerDay,
  }) {
    if (isAllDay) {
      // Tutti gli slot della giornata
      return {for (int i = 0; i < totalSlotsPerDay; i++) i};
    }

    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;

    final startSlot = startMinutes ~/ minutesPerSlot;
    final endSlot = endMinutes ~/ minutesPerSlot;

    return {for (int i = startSlot; i < endSlot; i++) i};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityException &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    final timeStr = isAllDay
        ? 'all day'
        : '${_timeOfDayToString(startTime!)}-${_timeOfDayToString(endTime!)}';
    return 'AvailabilityException(id: $id, staffId: $staffId, date: ${date.toIso8601String().split('T').first}, $timeStr, type: ${type.name}, reasonCode: $reasonCode, reason: $reason)';
  }
}
