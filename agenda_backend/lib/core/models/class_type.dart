class ClassType {
  final int id;
  final int businessId;
  final String name;
  final String? description;
  final bool isActive;
  final List<int> locationIds;

  const ClassType({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.isActive,
    this.locationIds = const [],
  });

  factory ClassType.fromJson(Map<String, dynamic> json) {
    return ClassType(
      id: (json['id'] as num).toInt(),
      businessId: (json['business_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      description: json['description'] as String?,
      isActive:
          (json['is_active'] as bool?) ??
          ((json['is_active'] as num?)?.toInt() == 1),
      locationIds: (json['location_ids'] as List<dynamic>? ?? const [])
          .map((item) => (item as num).toInt())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'description': description,
      'is_active': isActive,
      'location_ids': locationIds,
    };
  }
}
