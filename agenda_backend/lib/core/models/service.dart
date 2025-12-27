class Service {
  final int id;
  final int businessId;
  final int categoryId;
  final String name;
  final String? description;
  final int sortOrder; // 🔹 posizione nella categoria
  final int? durationMinutes; // da API
  final double? price; // da API
  final String? color; // da API

  const Service({
    required this.id,
    required this.businessId,
    required this.categoryId,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.durationMinutes,
    this.price,
    this.color,
  });

  Service copyWith({
    int? id,
    int? businessId,
    int? categoryId,
    String? name,
    String? description,
    int? sortOrder,
    int? durationMinutes,
    double? price,
    String? color,
  }) => Service(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    description: description ?? this.description,
    sortOrder: sortOrder ?? this.sortOrder,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    price: price ?? this.price,
    color: color ?? this.color,
  );

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] as int,
    businessId: json['business_id'] as int? ?? 1,
    categoryId: json['category_id'] as int? ?? 0,
    name: json['name'] as String,
    description: json['description'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
    durationMinutes: json['duration_minutes'] as int?,
    price: (json['price'] as num?)?.toDouble(),
    color: json['color'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'category_id': categoryId,
    'name': name,
    if (description != null) 'description': description,
    'sort_order': sortOrder,
    if (durationMinutes != null) 'duration_minutes': durationMinutes,
    if (price != null) 'price': price,
    if (color != null) 'color': color,
  };
}
