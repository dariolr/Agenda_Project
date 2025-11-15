class ServiceVariantResourceRequirement {
  final int id;
  final int serviceVariantId;
  final int resourceId;
  final int unitsRequired;

  const ServiceVariantResourceRequirement({
    required this.id,
    required this.serviceVariantId,
    required this.resourceId,
    required this.unitsRequired,
  });

  ServiceVariantResourceRequirement copyWith({
    int? id,
    int? serviceVariantId,
    int? resourceId,
    int? unitsRequired,
  }) {
    return ServiceVariantResourceRequirement(
      id: id ?? this.id,
      serviceVariantId: serviceVariantId ?? this.serviceVariantId,
      resourceId: resourceId ?? this.resourceId,
      unitsRequired: unitsRequired ?? this.unitsRequired,
    );
  }

  factory ServiceVariantResourceRequirement.fromJson(
    Map<String, dynamic> json,
  ) {
    return ServiceVariantResourceRequirement(
      id: json['id'] as int,
      serviceVariantId: json['service_variant_id'] as int,
      resourceId: json['resource_id'] as int,
      unitsRequired: json['units_required'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_variant_id': serviceVariantId,
      'resource_id': resourceId,
      'units_required': unitsRequired,
    };
  }
}

