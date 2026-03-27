import 'package:flutter/material.dart';

/// Rappresenta un singolo servizio in una prenotazione multi-servizio.
/// Usato internamente nel form di creazione/modifica prenotazione.
class ServiceItemData {
  final String key; // Chiave univoca per identificare l'item nella lista
  final int? appointmentId; // ID dell'appuntamento originale (null se nuovo)
  final int? serviceId;
  final int? serviceVariantId;
  final int? staffId;
  final TimeOfDay startTime;
  final int durationMinutes;
  final int blockedExtraMinutes;
  final int processingExtraMinutes;
  final double? listPrice; // Prezzo di listino snapshot
  final double? price; // Prezzo personalizzato (null = usa prezzo variante)
  final int? packageId; // Package usato per pricing, se presente
  final String? pricingSource; // service/package/discount/custom

  const ServiceItemData({
    required this.key,
    this.appointmentId,
    this.serviceId,
    this.serviceVariantId,
    this.staffId,
    required this.startTime,
    this.durationMinutes = 30,
    this.blockedExtraMinutes = 0,
    this.processingExtraMinutes = 0,
    this.listPrice,
    this.price,
    this.packageId,
    this.pricingSource,
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
    int? appointmentId,
    int? serviceId,
    int? serviceVariantId,
    int? staffId,
    TimeOfDay? startTime,
    int? durationMinutes,
    int? blockedExtraMinutes,
    int? processingExtraMinutes,
    double? listPrice,
    double? price,
    int? packageId,
    String? pricingSource,
  }) {
    return ServiceItemData(
      key: key ?? this.key,
      appointmentId: appointmentId ?? this.appointmentId,
      serviceId: serviceId ?? this.serviceId,
      serviceVariantId: serviceVariantId ?? this.serviceVariantId,
      staffId: staffId ?? this.staffId,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      blockedExtraMinutes: blockedExtraMinutes ?? this.blockedExtraMinutes,
      processingExtraMinutes:
          processingExtraMinutes ?? this.processingExtraMinutes,
      listPrice: listPrice ?? this.listPrice,
      price: price ?? this.price,
      packageId: packageId ?? this.packageId,
      pricingSource: pricingSource ?? this.pricingSource,
    );
  }

  /// Crea una copia azzerando il prezzo personalizzato
  ServiceItemData copyWithPriceCleared() {
    return ServiceItemData(
      key: key,
      appointmentId: appointmentId,
      serviceId: serviceId,
      serviceVariantId: serviceVariantId,
      staffId: staffId,
      startTime: startTime,
      durationMinutes: durationMinutes,
      blockedExtraMinutes: blockedExtraMinutes,
      processingExtraMinutes: processingExtraMinutes,
      listPrice: listPrice,
      price: null,
      packageId: packageId,
      pricingSource: pricingSource,
    );
  }

  /// Crea una copia con serviceId e staffId resettati a null
  ServiceItemData clearService() {
    return ServiceItemData(
      key: key,
      appointmentId: appointmentId,
      serviceId: null,
      serviceVariantId: null,
      staffId: null,
      startTime: startTime,
      durationMinutes: 30,
      blockedExtraMinutes: 0,
      processingExtraMinutes: 0,
      listPrice: null,
      price: null,
      packageId: null,
      pricingSource: null,
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
