/// Modello Servizio prenotabile online
class Service {
  final int id;
  final int businessId;
  final int? locationId;
  final int categoryId;
  final String name;
  final String? description;
  final int sortOrder;
  final int durationMinutes;
  final int processingTime;
  final int blockedTime;
  final double price;
  final bool isFree;
  final bool isPriceStartingFrom;
  final bool onlinePaymentRequired;
  final bool isBookableOnline;
  final String onlineVisibility;
  final bool isActive;
  final int? serviceVariantId;

  const Service({
    required this.id,
    required this.businessId,
    this.locationId,
    required this.categoryId,
    required this.name,
    this.description,
    this.sortOrder = 0,
    required this.durationMinutes,
    this.processingTime = 0,
    this.blockedTime = 0,
    required this.price,
    this.isFree = false,
    this.isPriceStartingFrom = false,
    this.onlinePaymentRequired = false,
    this.isBookableOnline = true,
    this.onlineVisibility = 'public',
    this.isActive = true,
    this.serviceVariantId,
  });

  /// Durata totale incluso tempo aggiuntivo (processing + blocked)
  int get totalDurationMinutes =>
      durationMinutes + processingTime + blockedTime;

  /// Durata mostrata al cliente nel frontend:
  /// include eventuale processing_time ma esclude blocked_time.
  int get customerVisibleDurationMinutes => durationMinutes + processingTime;

  Service copyWith({
    int? id,
    int? businessId,
    int? locationId,
    int? categoryId,
    String? name,
    String? description,
    int? sortOrder,
    int? durationMinutes,
    int? processingTime,
    int? blockedTime,
    double? price,
    bool? isFree,
    bool? isPriceStartingFrom,
    bool? onlinePaymentRequired,
    bool? isBookableOnline,
    String? onlineVisibility,
    bool? isActive,
    int? serviceVariantId,
  }) => Service(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    locationId: locationId ?? this.locationId,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    description: description ?? this.description,
    sortOrder: sortOrder ?? this.sortOrder,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    processingTime: processingTime ?? this.processingTime,
    blockedTime: blockedTime ?? this.blockedTime,
    price: price ?? this.price,
    isFree: isFree ?? this.isFree,
    isPriceStartingFrom: isPriceStartingFrom ?? this.isPriceStartingFrom,
    onlinePaymentRequired: onlinePaymentRequired ?? this.onlinePaymentRequired,
    isBookableOnline: isBookableOnline ?? this.isBookableOnline,
    onlineVisibility: onlineVisibility ?? this.onlineVisibility,
    isActive: isActive ?? this.isActive,
    serviceVariantId: serviceVariantId ?? this.serviceVariantId,
  );

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] as int,
    // API può usare business_id o derivarlo dalla location
    businessId: json['business_id'] as int? ?? 0,
    locationId: json['location_id'] as int?,
    // category_id può essere null per servizi non categorizzati
    categoryId: json['category_id'] as int? ?? 0,
    name: json['name'] as String,
    description: json['description'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
    // API ritorna default_duration_minutes o duration_minutes
    durationMinutes:
        json['default_duration_minutes'] as int? ??
        json['duration_minutes'] as int? ??
        30,
    processingTime: json['processing_time'] as int? ?? 0,
    blockedTime: json['blocked_time'] as int? ?? 0,
    // API ritorna default_price o price
    price:
        (json['default_price'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0.0,
    isFree: json['is_free'] as bool? ?? false,
    isPriceStartingFrom: json['is_price_starting_from'] as bool? ?? false,
    onlinePaymentRequired: _parseBool(json['online_payment_required']),
    isBookableOnline: _parseBookableOnline(json['is_bookable_online']),
    onlineVisibility: json['online_visibility'] as String? ?? 'public',
    isActive: _parseIsActive(json['is_active']),
    serviceVariantId: json['service_variant_id'] as int?,
  );

  static bool _parseBookableOnline(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return true;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static bool _parseIsActive(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    if (locationId != null) 'location_id': locationId,
    'category_id': categoryId,
    'name': name,
    if (description != null) 'description': description,
    'sort_order': sortOrder,
    'duration_minutes': durationMinutes,
    'price': price,
    'is_free': isFree,
    'is_price_starting_from': isPriceStartingFrom,
    'is_bookable_online': isBookableOnline,
    'online_visibility': onlineVisibility,
    'is_active': isActive,
    if (serviceVariantId != null) 'service_variant_id': serviceVariantId,
  };

  String get formattedPrice {
    if (isFree) return 'Gratis';
    final priceStr = price.toStringAsFixed(2).replaceAll('.', ',');
    return isPriceStartingFrom ? 'da €$priceStr' : '€$priceStr';
  }
}
