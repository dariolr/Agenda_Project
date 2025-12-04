class Business {
  final int id;
  final String name;
  final DateTime createdAt;
  final String currency;
  final String defaultPhonePrefix;

  const Business({
    required this.id,
    required this.name,
    required this.createdAt,
    this.currency = 'EUR',
    this.defaultPhonePrefix = '+39',
  });

  Business copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    String? currency,
    String? defaultPhonePrefix,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
      defaultPhonePrefix: defaultPhonePrefix ?? this.defaultPhonePrefix,
    );
  }

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      currency: json['currency'] as String? ?? 'EUR',
      defaultPhonePrefix: json['default_phone_prefix'] as String? ?? '+39',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'currency': currency,
      'default_phone_prefix': defaultPhonePrefix,
    };
  }
}
