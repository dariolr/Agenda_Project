class ServiceVariantResourceRequirement {
  final int id;
  final int? serviceVariantId;
  final int resourceId;
  final String? resourceName;
  final int unitsRequired;

  const ServiceVariantResourceRequirement({
    required this.id,
    this.serviceVariantId,
    required this.resourceId,
    this.resourceName,
    required this.unitsRequired,
  });

  ServiceVariantResourceRequirement copyWith({
    int? id,
    int? serviceVariantId,
    int? resourceId,
    String? resourceName,
    int? unitsRequired,
  }) {
    return ServiceVariantResourceRequirement(
      id: id ?? this.id,
      serviceVariantId: serviceVariantId ?? this.serviceVariantId,
      resourceId: resourceId ?? this.resourceId,
      resourceName: resourceName ?? this.resourceName,
      unitsRequired: unitsRequired ?? this.unitsRequired,
    );
  }

  factory ServiceVariantResourceRequirement.fromJson(
    Map<String, dynamic> json,
  ) {
    return ServiceVariantResourceRequirement(
      id: json['id'] as int,
      serviceVariantId: json['service_variant_id'] as int?,
      resourceId: json['resource_id'] as int,
      resourceName: json['resource_name'] as String?,
      // API returns 'quantity', model uses 'unitsRequired'
      unitsRequired:
          json['quantity'] as int? ?? json['units_required'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (serviceVariantId != null) 'service_variant_id': serviceVariantId,
      'resource_id': resourceId,
      if (resourceName != null) 'resource_name': resourceName,
      'quantity': unitsRequired,
    };
  }
}
