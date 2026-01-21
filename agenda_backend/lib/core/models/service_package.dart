class ServicePackageItem {
  final int serviceId;
  final int sortOrder;
  final String? name;
  final int? durationMinutes;
  final double? price;
  final bool serviceIsActive;
  final bool variantIsActive;

  const ServicePackageItem({
    required this.serviceId,
    required this.sortOrder,
    this.name,
    this.durationMinutes,
    this.price,
    this.serviceIsActive = true,
    this.variantIsActive = true,
  });

  factory ServicePackageItem.fromJson(Map<String, dynamic> json) {
    return ServicePackageItem(
      serviceId: json['service_id'] as int,
      sortOrder: json['sort_order'] as int? ?? 0,
      name: json['name'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      price: (json['price'] as num?)?.toDouble(),
      serviceIsActive: json['service_is_active'] as bool? ?? true,
      variantIsActive: json['variant_is_active'] as bool? ?? true,
    );
  }
}

class ServicePackage {
  final int id;
  final int businessId;
  final int locationId;
  final int categoryId;
  final int sortOrder;
  final String name;
  final String? description;
  final double? overridePrice;
  final int? overrideDurationMinutes;
  final bool isActive;
  final bool isBroken;
  final double effectivePrice;
  final int effectiveDurationMinutes;
  final List<ServicePackageItem> items;

  const ServicePackage({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.categoryId,
    required this.sortOrder,
    required this.name,
    this.description,
    this.overridePrice,
    this.overrideDurationMinutes,
    this.isActive = true,
    this.isBroken = false,
    required this.effectivePrice,
    required this.effectiveDurationMinutes,
    required this.items,
  });

  int get serviceCount => items.length;

  List<int> get orderedServiceIds {
    final ordered = [...items]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ordered.map((item) => item.serviceId).toList();
  }

  ServicePackage copyWith({
    int? id,
    int? businessId,
    int? locationId,
    int? categoryId,
    int? sortOrder,
    String? name,
    String? description,
    double? overridePrice,
    int? overrideDurationMinutes,
    bool? isActive,
    bool? isBroken,
    double? effectivePrice,
    int? effectiveDurationMinutes,
    List<ServicePackageItem>? items,
  }) => ServicePackage(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    locationId: locationId ?? this.locationId,
    categoryId: categoryId ?? this.categoryId,
    sortOrder: sortOrder ?? this.sortOrder,
    name: name ?? this.name,
    description: description ?? this.description,
    overridePrice: overridePrice ?? this.overridePrice,
    overrideDurationMinutes:
        overrideDurationMinutes ?? this.overrideDurationMinutes,
    isActive: isActive ?? this.isActive,
    isBroken: isBroken ?? this.isBroken,
    effectivePrice: effectivePrice ?? this.effectivePrice,
    effectiveDurationMinutes:
        effectiveDurationMinutes ?? this.effectiveDurationMinutes,
    items: items ?? this.items,
  );

  factory ServicePackage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return ServicePackage(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      locationId: json['location_id'] as int,
      categoryId: json['category_id'] as int? ?? 0,
      sortOrder: json['sort_order'] as int? ?? 0,
      name: json['name'] as String,
      description: json['description'] as String?,
      overridePrice: (json['override_price'] as num?)?.toDouble(),
      overrideDurationMinutes: json['override_duration_minutes'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      isBroken: json['is_broken'] as bool? ?? false,
      effectivePrice: (json['effective_price'] as num?)?.toDouble() ?? 0,
      effectiveDurationMinutes:
          json['effective_duration_minutes'] as int? ?? 0,
      items: itemsJson
          .map(
            (item) =>
                ServicePackageItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class ServicePackageExpansion {
  final int packageId;
  final int locationId;
  final List<int> serviceIds;
  final double effectivePrice;
  final int effectiveDurationMinutes;

  const ServicePackageExpansion({
    required this.packageId,
    required this.locationId,
    required this.serviceIds,
    required this.effectivePrice,
    required this.effectiveDurationMinutes,
  });

  factory ServicePackageExpansion.fromJson(Map<String, dynamic> json) {
    return ServicePackageExpansion(
      packageId: json['package_id'] as int,
      locationId: json['location_id'] as int,
      serviceIds:
          (json['service_ids'] as List<dynamic>? ?? const [])
              .map((id) => id as int)
              .toList(),
      effectivePrice: (json['effective_price'] as num?)?.toDouble() ?? 0,
      effectiveDurationMinutes:
          json['effective_duration_minutes'] as int? ?? 0,
    );
  }
}
