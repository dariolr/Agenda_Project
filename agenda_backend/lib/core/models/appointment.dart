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
  final int? extraMinutes; // tempo aggiuntivo applicato (processing+blocked)
  final ExtraMinutesType? extraMinutesType;

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
    this.extraMinutes,
    this.extraMinutesType,
  });

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
    extraMinutes: json['extra_minutes'] as int?,
    extraMinutesType: _extraMinutesTypeFromJson(
      json['extra_minutes_type'],
    ),
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
    int? extraMinutes,
    ExtraMinutesType? extraMinutesType,
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
      extraMinutes: extraMinutes ?? this.extraMinutes,
      extraMinutesType: extraMinutesType ?? this.extraMinutesType,
    );
  }

  Map<String, dynamic> toJson() {
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
      if (extraMinutes != null) 'extra_minutes': extraMinutes,
      if (extraMinutesType != null)
        'extra_minutes_type': _extraMinutesTypeToJson(extraMinutesType),
    };
  }

  int get totalDuration => endTime.difference(startTime).inMinutes;

  String get formattedPrice {
    if (price == null || price == 0) return '';
    return '${price!.toStringAsFixed(2)}€';
  }
}
