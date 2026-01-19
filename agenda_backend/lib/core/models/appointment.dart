enum ExtraMinutesType { processing, blocked }

ExtraMinutesType? _extraMinutesTypeFromJson(Object? value) {
  if (value is String) {
    for (final type in ExtraMinutesType.values) {
      if (type.name == value) {
        return type;
      }
    }
  }
  return null;
}

String? _extraMinutesTypeToJson(ExtraMinutesType? value) {
  return value?.name;
}

class Appointment {
  final int id;
  final int bookingId;
  final int businessId;
  final int locationId;
  final int staffId;
  final int serviceId;
  final int serviceVariantId;
  final int? clientId; // opzionale: collegamento al Client
  final String clientName;
  final String serviceName;
  final DateTime startTime;
  final DateTime endTime;
  final double? price; // prezzo applicato al singolo appuntamento
  final String? bookingSource;
  final String? bookingStatus; // pending, confirmed, replaced, cancelled
  // Legacy single extra fields (kept for backward compatibility)
  final int? extraMinutes;
  final ExtraMinutesType? extraMinutesType;
  // New split extras
  final int? extraBlockedMinutes;
  final int? extraProcessingMinutes;

  const Appointment({
    required this.id,
    required this.bookingId,
    required this.businessId,
    required this.locationId,
    required this.staffId,
    required this.serviceId,
    required this.serviceVariantId,
    this.clientId,
    required this.clientName,
    required this.serviceName,
    required this.startTime,
    required this.endTime,
    this.price,
    this.bookingSource,
    this.bookingStatus,
    this.extraMinutes,
    this.extraMinutesType,
    this.extraBlockedMinutes,
    this.extraProcessingMinutes,
  });

  /// Returns true if this appointment's booking was cancelled
  bool get isCancelled => bookingStatus == 'cancelled';

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as int,
    bookingId: json['booking_id'] as int,
    businessId: json['business_id'] as int,
    locationId: json['location_id'] as int,
    staffId: json['staff_id'] as int,
    serviceId: json['service_id'] as int,
    serviceVariantId: json['service_variant_id'] as int,
    clientId: json['client_id'] as int?,
    clientName: json['client_name'] as String? ?? '',
    serviceName: json['service_name'] as String? ?? '',
    startTime: DateTime.parse(json['start_time'] as String),
    endTime: DateTime.parse(json['end_time'] as String),
    price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    bookingSource: json['source'] as String?,
    bookingStatus: json['booking_status'] as String?,
    extraMinutes: json['extra_minutes'] as int?,
    extraMinutesType: _extraMinutesTypeFromJson(json['extra_minutes_type']),
    extraBlockedMinutes: json['extra_blocked_minutes'] as int?,
    extraProcessingMinutes: json['extra_processing_minutes'] as int?,
  );

  Appointment copyWith({
    int? id,
    int? bookingId,
    int? businessId,
    int? locationId,
    int? staffId,
    int? serviceId,
    int? serviceVariantId,
    int? clientId,
    String? clientName,
    String? serviceName,
    DateTime? startTime,
    DateTime? endTime,
    double? price,
    String? bookingSource,
    String? bookingStatus,
    int? extraMinutes,
    ExtraMinutesType? extraMinutesType,
    int? extraBlockedMinutes,
    int? extraProcessingMinutes,
  }) {
    return Appointment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      businessId: businessId ?? this.businessId,
      locationId: locationId ?? this.locationId,
      staffId: staffId ?? this.staffId,
      serviceId: serviceId ?? this.serviceId,
      serviceVariantId: serviceVariantId ?? this.serviceVariantId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      serviceName: serviceName ?? this.serviceName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      price: price ?? this.price,
      bookingSource: bookingSource ?? this.bookingSource,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      extraMinutes: extraMinutes ?? this.extraMinutes,
      extraMinutesType: extraMinutesType ?? this.extraMinutesType,
      extraBlockedMinutes: extraBlockedMinutes ?? this.extraBlockedMinutes,
      extraProcessingMinutes:
          extraProcessingMinutes ?? this.extraProcessingMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    final blocked = blockedExtraMinutes;
    final processing = processingExtraMinutes;
    final legacyType = blocked > 0
        ? ExtraMinutesType.blocked
        : (processing > 0 ? ExtraMinutesType.processing : null);
    final legacyMinutes = legacyType == ExtraMinutesType.blocked
        ? blocked
        : (legacyType == ExtraMinutesType.processing ? processing : null);
    return {
      'id': id,
      'booking_id': bookingId,
      'business_id': businessId,
      'location_id': locationId,
      'staff_id': staffId,
      'service_id': serviceId,
      'service_variant_id': serviceVariantId,
      if (clientId != null) 'client_id': clientId,
      'client_name': clientName,
      'service_name': serviceName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      if (price != null) 'price': price,
      if (bookingSource != null) 'source': bookingSource,
      if (legacyMinutes != null) 'extra_minutes': legacyMinutes,
      if (legacyType != null)
        'extra_minutes_type': _extraMinutesTypeToJson(legacyType),
      if (extraBlockedMinutes != null)
        'extra_blocked_minutes': extraBlockedMinutes,
      if (extraProcessingMinutes != null)
        'extra_processing_minutes': extraProcessingMinutes,
    };
  }

  int get blockedExtraMinutes {
    if (extraBlockedMinutes != null) return extraBlockedMinutes!;
    if (extraMinutesType == ExtraMinutesType.blocked) {
      return extraMinutes ?? 0;
    }
    return 0;
  }

  int get processingExtraMinutes {
    if (extraProcessingMinutes != null) return extraProcessingMinutes!;
    if (extraMinutesType == ExtraMinutesType.processing) {
      return extraMinutes ?? 0;
    }
    return 0;
  }

  int get totalDuration => endTime.difference(startTime).inMinutes;

  String get formattedPrice {
    if (price == null || price == 0) return '';
    return '${price!.toStringAsFixed(2)}€';
  }
}
