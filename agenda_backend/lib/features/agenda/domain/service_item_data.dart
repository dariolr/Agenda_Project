import 'package:flutter/material.dart';

/// Rappresenta un singolo servizio in una prenotazione multi-servizio.
/// Usato internamente nel form di creazione/modifica prenotazione.
class ServiceItemData {
  final String key; // Chiave univoca per identificare l'item nella lista
  final int? serviceId;
  final int? serviceVariantId;
  final int? staffId;
  final TimeOfDay startTime;
  final int durationMinutes;
  final int blockedExtraMinutes;
  final int processingExtraMinutes;

  const ServiceItemData({
    required this.key,
    this.serviceId,
    this.serviceVariantId,
    this.staffId,
    required this.startTime,
    this.durationMinutes = 30,
    this.blockedExtraMinutes = 0,
    this.processingExtraMinutes = 0,
  });

  /// Calcola l'orario di fine basato su startTime e durationMinutes
  TimeOfDay get endTime {
    final totalMinutes =
        startTime.hour * 60 + startTime.minute + durationMinutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  /// Calcola l'orario di fine con durata opzionale esterna (es. da variant)
  TimeOfDay getEndTime([int? externalDuration]) {
    final duration = externalDuration ?? durationMinutes;
    final totalMinutes = startTime.hour * 60 + startTime.minute + duration;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  /// Calcola il prossimo orario di inizio (per il servizio successivo)
  TimeOfDay get nextStartTime => endTime;

  ServiceItemData copyWith({
    String? key,
    int? serviceId,
    int? serviceVariantId,
    int? staffId,
    TimeOfDay? startTime,
    int? durationMinutes,
    int? blockedExtraMinutes,
    int? processingExtraMinutes,
  }) {
    return ServiceItemData(
      key: key ?? this.key,
      serviceId: serviceId ?? this.serviceId,
      serviceVariantId: serviceVariantId ?? this.serviceVariantId,
      staffId: staffId ?? this.staffId,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      blockedExtraMinutes: blockedExtraMinutes ?? this.blockedExtraMinutes,
      processingExtraMinutes:
          processingExtraMinutes ?? this.processingExtraMinutes,
    );
  }

  /// Crea una copia con serviceId e staffId resettati a null
  ServiceItemData clearService() {
    return ServiceItemData(
      key: key,
      serviceId: null,
      serviceVariantId: null,
      staffId: null,
      startTime: startTime,
      durationMinutes: 30,
      blockedExtraMinutes: 0,
      processingExtraMinutes: 0,
    );
  }

  bool get hasBlockedExtra => blockedExtraMinutes > 0;
  bool get hasProcessingExtra => processingExtraMinutes > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceItemData &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}
