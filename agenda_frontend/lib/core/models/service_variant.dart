class ServiceVariant {
  final int id;
  final int serviceId;
  final int locationId;
  final int durationMinutes;
  final double price;
  final String? colorHex;
  final String? currency; // 🔹 Valuta specifica (es. "EUR", "USD")

  const ServiceVariant({
    required this.id,
    required this.serviceId,
    required this.locationId,
    required this.durationMinutes,
    required this.price,
    this.colorHex,
    this.currency,
  });

  ServiceVariant copyWith({
    int? id,
    int? serviceId,
    int? locationId,
    int? durationMinutes,
    double? price,
    String? colorHex,
    String? currency,
  }) {
    return ServiceVariant(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      locationId: locationId ?? this.locationId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      colorHex: colorHex ?? this.colorHex,
      currency: currency ?? this.currency,
    );
  }

  factory ServiceVariant.fromJson(Map<String, dynamic> json) {
    return ServiceVariant(
      id: json['id'] as int,
      serviceId: json['service_id'] as int,
      locationId: json['location_id'] as int,
      durationMinutes: json['duration_minutes'] as int,
      price: (json['price'] as num).toDouble(),
      colorHex: json['color_hex'] as String?,
      currency: json['currency'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'location_id': locationId,
      'duration_minutes': durationMinutes,
      'price': price,
      if (colorHex != null) 'color_hex': colorHex,
      if (currency != null) 'currency': currency,
    };
  }
}
