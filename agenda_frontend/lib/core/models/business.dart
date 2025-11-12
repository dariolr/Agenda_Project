class Business {
  final int id;
  final String name;
  final DateTime createdAt;
  final String
  currency; // 🔹 nuova proprietà: valuta di riferimento del business

  const Business({
    required this.id,
    required this.name,
    required this.createdAt,
    this.currency = 'EUR', // 🔹 default EUR per compatibilità UE
  });

  Business copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    String? currency,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
    );
  }

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      currency: json['currency'] as String? ?? 'EUR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'currency': currency,
    };
  }
}
