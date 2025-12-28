/// Modello Servizio prenotabile online
class Service {
  final int id;
  final int businessId;
  final int categoryId;
  final String name;
  final String? description;
  final int sortOrder;
  final int durationMinutes;
  final double price;
  final bool isFree;
  final bool isPriceStartingFrom;
  final bool isBookableOnline;

  const Service({
    required this.id,
    required this.businessId,
    required this.categoryId,
    required this.name,
    this.description,
    this.sortOrder = 0,
    required this.durationMinutes,
    required this.price,
    this.isFree = false,
    this.isPriceStartingFrom = false,
    this.isBookableOnline = true,
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
    bool? isFree,
    bool? isPriceStartingFrom,
    bool? isBookableOnline,
  }) => Service(
    id: id ?? this.id,
    businessId: businessId ?? this.businessId,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    description: description ?? this.description,
    sortOrder: sortOrder ?? this.sortOrder,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    price: price ?? this.price,
    isFree: isFree ?? this.isFree,
    isPriceStartingFrom: isPriceStartingFrom ?? this.isPriceStartingFrom,
    isBookableOnline: isBookableOnline ?? this.isBookableOnline,
  );

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: json['id'] as int,
    // API può usare business_id o derivarlo dalla location
    businessId: json['business_id'] as int? ?? 1,
    categoryId: json['category_id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
    // API ritorna default_duration_minutes o duration_minutes
    durationMinutes:
        json['default_duration_minutes'] as int? ??
        json['duration_minutes'] as int? ??
        30,
    // API ritorna default_price o price
    price:
        (json['default_price'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0.0,
    isFree: json['is_free'] as bool? ?? false,
    isPriceStartingFrom: json['is_price_starting_from'] as bool? ?? false,
    isBookableOnline: json['is_bookable_online'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'category_id': categoryId,
    'name': name,
    if (description != null) 'description': description,
    'sort_order': sortOrder,
    'duration_minutes': durationMinutes,
    'price': price,
    'is_free': isFree,
    'is_price_starting_from': isPriceStartingFrom,
    'is_bookable_online': isBookableOnline,
  };

  String get formattedPrice {
    if (isFree) return 'Gratis';
    final priceStr = price.toStringAsFixed(2).replaceAll('.', ',');
    return isPriceStartingFrom ? 'da €$priceStr' : '€$priceStr';
  }
}
