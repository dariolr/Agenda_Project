class Business {
  final int id;
  final String name;
  final String? slug;
  final String? email;
  final String? phone;
  final String? onlineBookingsNotificationEmail;
  final String serviceColorPalette;
  final String? timezone;
  final DateTime createdAt;
  final String currency;
  final String defaultPhonePrefix;
  final String? adminEmail; // Email dell'admin proprietario
  final bool isSuspended; // Business sospeso (visibile ma non operativo)
  final String? suspensionMessage; // Messaggio da mostrare quando sospeso
  final String? userRole; // Ruolo dell'utente corrente nel business
  final String? userScopeType; // Scope dell'utente corrente nel business

  const Business({
    required this.id,
    required this.name,
    this.slug,
    this.email,
    this.phone,
    this.onlineBookingsNotificationEmail,
    this.serviceColorPalette = 'legacy',
    this.timezone,
    required this.createdAt,
    this.currency = 'EUR',
    this.defaultPhonePrefix = '+39',
    this.adminEmail,
    this.isSuspended = false,
    this.suspensionMessage,
    this.userRole,
    this.userScopeType,
  });

  Business copyWith({
    int? id,
    String? name,
    String? slug,
    String? email,
    String? phone,
    String? onlineBookingsNotificationEmail,
    String? serviceColorPalette,
    String? timezone,
    DateTime? createdAt,
    String? currency,
    String? defaultPhonePrefix,
    String? adminEmail,
    bool? isSuspended,
    String? suspensionMessage,
    String? userRole,
    String? userScopeType,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      onlineBookingsNotificationEmail:
          onlineBookingsNotificationEmail ??
          this.onlineBookingsNotificationEmail,
      serviceColorPalette: serviceColorPalette ?? this.serviceColorPalette,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
      defaultPhonePrefix: defaultPhonePrefix ?? this.defaultPhonePrefix,
      adminEmail: adminEmail ?? this.adminEmail,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionMessage: suspensionMessage ?? this.suspensionMessage,
      userRole: userRole ?? this.userRole,
      userScopeType: userScopeType ?? this.userScopeType,
    );
  }

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      onlineBookingsNotificationEmail:
          json['online_bookings_notification_email'] as String?,
      serviceColorPalette: json['service_color_palette'] as String? ?? 'legacy',
      timezone: json['timezone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      currency: json['currency'] as String? ?? 'EUR',
      defaultPhonePrefix: json['default_phone_prefix'] as String? ?? '+39',
      adminEmail: json['admin_email'] as String?,
      isSuspended: json['is_suspended'] == true || json['is_suspended'] == 1,
      suspensionMessage: json['suspension_message'] as String?,
      userRole: json['user_role'] as String?,
      userScopeType: json['user_scope_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'email': email,
      'phone': phone,
      'online_bookings_notification_email': onlineBookingsNotificationEmail,
      'service_color_palette': serviceColorPalette,
      'timezone': timezone,
      'created_at': createdAt.toIso8601String(),
      'currency': currency,
      'default_phone_prefix': defaultPhonePrefix,
      'admin_email': adminEmail,
      'is_suspended': isSuspended,
      'suspension_message': suspensionMessage,
      'user_role': userRole,
      'user_scope_type': userScopeType,
    };
  }
}
