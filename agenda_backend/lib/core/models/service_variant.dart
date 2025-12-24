import 'service_variant_resource_requirement.dart';

class ServiceVariant {
  final int id;
  final int serviceId;
  final int locationId;
  final int durationMinutes;
  final int? processingTime; // minuti opzionali post-lavorazione
  final int? blockedTime; // minuti opzionali bloccati
  final double price;
  final String? colorHex;
  final String? currency; // 🔹 Valuta specifica (es. "EUR", "USD")
  final bool isBookableOnline;
  final bool isFree;
  final bool isPriceStartingFrom;
  final List<ServiceVariantResourceRequirement> resourceRequirements;

  const ServiceVariant({
    required this.id,
    required this.serviceId,
    required this.locationId,
    required this.durationMinutes,
    this.processingTime,
    this.blockedTime,
    required this.price,
    this.colorHex,
    this.currency,
    this.isBookableOnline = true,
    this.isFree = false,
    this.isPriceStartingFrom = false,
    this.resourceRequirements = const [],
  });

  ServiceVariant copyWith({
    int? id,
    int? serviceId,
    int? locationId,
    int? durationMinutes,
    int? processingTime,
    int? blockedTime,
    double? price,
    String? colorHex,
    String? currency,
    bool? isBookableOnline,
    bool? isFree,
    bool? isPriceStartingFrom,
    List<ServiceVariantResourceRequirement>? resourceRequirements,
  }) {
    return ServiceVariant(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      locationId: locationId ?? this.locationId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      processingTime: processingTime ?? this.processingTime,
      blockedTime: blockedTime ?? this.blockedTime,
      price: price ?? this.price,
      colorHex: colorHex ?? this.colorHex,
      currency: currency ?? this.currency,
      isBookableOnline: isBookableOnline ?? this.isBookableOnline,
      isFree: isFree ?? this.isFree,
      isPriceStartingFrom: isPriceStartingFrom ?? this.isPriceStartingFrom,
      resourceRequirements:
          resourceRequirements ?? this.resourceRequirements,
    );
  }

  factory ServiceVariant.fromJson(Map<String, dynamic> json) {
    return ServiceVariant(
      id: json['id'] as int,
      serviceId: json['service_id'] as int,
      locationId: json['location_id'] as int,
      durationMinutes: json['duration_minutes'] as int,
      processingTime: json['processing_time'] as int?,
      blockedTime: json['blocked_time'] as int?,
      price: (json['price'] as num).toDouble(),
      colorHex: json['color_hex'] as String?,
      currency: json['currency'] as String?,
      isBookableOnline: json['is_bookable_online'] as bool? ?? true,
      isFree: json['is_free'] as bool? ?? false,
      isPriceStartingFrom: json['is_price_starting_from'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'location_id': locationId,
      'duration_minutes': durationMinutes,
      if (processingTime != null) 'processing_time': processingTime,
      if (blockedTime != null) 'blocked_time': blockedTime,
      'price': price,
      if (colorHex != null) 'color_hex': colorHex,
      if (currency != null) 'currency': currency,
      'is_bookable_online': isBookableOnline,
      'is_free': isFree,
      'is_price_starting_from': isPriceStartingFrom,
    };
  }
}
