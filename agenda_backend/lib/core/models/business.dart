class Business {
  final int id;
  final String name;
  final String? slug;
  final String? email;
  final String? phone;
  final String? timezone;
  final DateTime createdAt;
  final String currency;
  final String defaultPhonePrefix;
  final String? adminEmail; // Email dell'admin proprietario

  const Business({
    required this.id,
    required this.name,
    this.slug,
    this.email,
    this.phone,
    this.timezone,
    required this.createdAt,
    this.currency = 'EUR',
    this.defaultPhonePrefix = '+39',
    this.adminEmail,
  });

  Business copyWith({
    int? id,
    String? name,
    String? slug,
    String? email,
    String? phone,
    String? timezone,
    DateTime? createdAt,
    String? currency,
    String? defaultPhonePrefix,
    String? adminEmail,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
      defaultPhonePrefix: defaultPhonePrefix ?? this.defaultPhonePrefix,
      adminEmail: adminEmail ?? this.adminEmail,
    );
  }

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      timezone: json['timezone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      currency: json['currency'] as String? ?? 'EUR',
      defaultPhonePrefix: json['default_phone_prefix'] as String? ?? '+39',
      adminEmail: json['admin_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'email': email,
      'phone': phone,
      'timezone': timezone,
      'created_at': createdAt.toIso8601String(),
      'currency': currency,
      'default_phone_prefix': defaultPhonePrefix,
      'admin_email': adminEmail,
    };
  }
}
