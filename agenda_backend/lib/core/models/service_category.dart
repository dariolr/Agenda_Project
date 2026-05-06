class ServiceCategory {
  final int id;
  final int businessId;
  final String name;
  final String? description;
  final int sortOrder; // 🔹 ordine di visualizzazione
  final bool hasActiveEntries;

  const ServiceCategory({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.hasActiveEntries = false,
  });

  ServiceCategory copyWith({
    int? id,
    int? businessId,
    String? name,
    String? description,
    int? sortOrder,
    bool? hasActiveEntries,
  }) => ServiceCategory(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    description: description ?? this.description,
    sortOrder: sortOrder ?? this.sortOrder,
    hasActiveEntries: hasActiveEntries ?? this.hasActiveEntries,
  );

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      ServiceCategory(
        id: json['id'] as int,
        businessId: json['business_id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        hasActiveEntries:
            (json['has_active_entries'] as bool?) ??
            ((json['has_active_entries'] as num?)?.toInt() == 1),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'name': name,
    if (description != null) 'description': description,
    'sort_order': sortOrder,
    'has_active_entries': hasActiveEntries,
  };
}
