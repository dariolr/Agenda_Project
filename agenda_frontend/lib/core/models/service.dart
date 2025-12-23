class Service {
  final int id;
  final int businessId;
  final int categoryId;
  final String name;
  final String? description;
  final int sortOrder; // 🔹 posizione nella categoria

  const Service({
    required this.id,
    required this.businessId,
    required this.categoryId,
    required this.name,
    this.description,
    this.sortOrder = 0,
  });

  Service copyWith({
    int? id,
    int? businessId,
    int? categoryId,
    String? name,
    String? description,
    int? sortOrder,
  }) => Service(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    description: description ?? this.description,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] as int,
    businessId: json['business_id'] as int,
    categoryId: json['category_id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'category_id': categoryId,
    'name': name,
    if (description != null) 'description': description,
    'sort_order': sortOrder,
  };
}
