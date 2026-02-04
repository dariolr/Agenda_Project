import 'service_variant_resource_requirement.dart';

class Service {
  final int id;
  final int businessId;
  final int?
  locationId; // Location a cui appartiene il servizio (da service_variants)
  final int categoryId;
  final String name;
  final String? description;
  final int sortOrder; // 🔹 posizione nella categoria
  final int? durationMinutes; // da API
  final int? processingTime; // tempo aggiuntivo processing (da API)
  final int? blockedTime; // tempo aggiuntivo bloccato (da API)
  final double? price; // da API
  final String? color; // da API
  final bool isBookableOnline; // prenotabile online
  final bool isPriceStartingFrom; // "a partire da" flag
  final int? serviceVariantId; // ID della variante per location (da API)
  final List<ServiceVariantResourceRequirement>
  resourceRequirements; // risorse richieste

  const Service({
    required this.id,
    required this.businessId,
    this.locationId,
    required this.categoryId,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.durationMinutes,
    this.processingTime,
    this.blockedTime,
    this.price,
    this.color,
    this.isBookableOnline = true,
    this.isPriceStartingFrom = false,
    this.serviceVariantId,
    this.resourceRequirements = const [],
  });

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
    String? color,
    bool? isBookableOnline,
    bool? isPriceStartingFrom,
    int? serviceVariantId,
    List<ServiceVariantResourceRequirement>? resourceRequirements,
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
    color: color ?? this.color,
    isBookableOnline: isBookableOnline ?? this.isBookableOnline,
    isPriceStartingFrom: isPriceStartingFrom ?? this.isPriceStartingFrom,
    serviceVariantId: serviceVariantId ?? this.serviceVariantId,
    resourceRequirements: resourceRequirements ?? this.resourceRequirements,
  );

  factory Service.fromJson(Map<String, dynamic> json) {
    final resourceRequirementsJson =
        json['resource_requirements'] as List<dynamic>? ?? [];
    final resourceRequirements = resourceRequirementsJson
        .map(
          (r) => ServiceVariantResourceRequirement.fromJson(
            r as Map<String, dynamic>,
          ),
        )
        .toList();

    return Service(
      id: json['id'] as int,
      businessId: json['business_id'] as int? ?? 1,
      locationId: json['location_id'] as int?,
      categoryId: json['category_id'] as int? ?? 0,
      name: json['name'] as String,
      description: json['description'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      durationMinutes: json['duration_minutes'] as int?,
      processingTime: json['processing_time'] as int?,
      blockedTime: json['blocked_time'] as int?,
      price: (json['price'] as num?)?.toDouble(),
      color: json['color'] as String?,
      isBookableOnline: json['is_bookable_online'] as bool? ?? true,
      isPriceStartingFrom: json['is_price_starting_from'] as bool? ?? false,
      serviceVariantId: json['service_variant_id'] as int?,
      resourceRequirements: resourceRequirements,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    if (locationId != null) 'location_id': locationId,
    'category_id': categoryId,
    'name': name,
    if (description != null) 'description': description,
    'sort_order': sortOrder,
    if (durationMinutes != null) 'duration_minutes': durationMinutes,
    if (price != null) 'price': price,
    if (color != null) 'color': color,
    'is_bookable_online': isBookableOnline,
    'is_price_starting_from': isPriceStartingFrom,
    if (serviceVariantId != null) 'service_variant_id': serviceVariantId,
  };
}
