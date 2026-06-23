enum WhatsappConfigStatus { active, inactive, pending, error }

WhatsappConfigStatus whatsappConfigStatusFromString(String? raw) {
  switch ((raw ?? '').toLowerCase().trim()) {
    case 'active':
      return WhatsappConfigStatus.active;
    case 'inactive':
      return WhatsappConfigStatus.inactive;
    case 'pending':
      return WhatsappConfigStatus.pending;
    case 'error':
      return WhatsappConfigStatus.error;
    default:
      return WhatsappConfigStatus.inactive;
  }
}

String whatsappConfigStatusToString(WhatsappConfigStatus status) {
  return switch (status) {
    WhatsappConfigStatus.active => 'active',
    WhatsappConfigStatus.inactive => 'inactive',
    WhatsappConfigStatus.pending => 'pending',
    WhatsappConfigStatus.error => 'error',
  };
}

class WhatsappConfig {
  final int id;
  final int businessId;
  final String wabaId;
  final String phoneNumberId;
  final String? displayPhoneNumber;
  final String? accessTokenEncrypted;
  final WhatsappConfigStatus status;
  final bool isDefault;
  final bool templateAutoSubmitEnabled;
  final String templateDefaultLanguage;
  final String templateDefaultCategory;
  final DateTime? lastHealthCheckAt;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final bool requiresReconnect;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WhatsappConfig({
    required this.id,
    required this.businessId,
    required this.wabaId,
    required this.phoneNumberId,
    this.displayPhoneNumber,
    this.accessTokenEncrypted,
    required this.status,
    this.isDefault = false,
    this.templateAutoSubmitEnabled = false,
    this.templateDefaultLanguage = 'it',
    this.templateDefaultCategory = 'utility',
    this.lastHealthCheckAt,
    this.lastErrorCode,
    this.lastErrorMessage,
    this.requiresReconnect = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == WhatsappConfigStatus.active;
  bool get isConnectionInvalid =>
      requiresReconnect || status == WhatsappConfigStatus.error;

  factory WhatsappConfig.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    }

    return WhatsappConfig(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessId: (json['business_id'] as num?)?.toInt() ?? 0,
      wabaId: (json['waba_id'] ?? '').toString(),
      phoneNumberId: (json['phone_number_id'] ?? '').toString(),
      displayPhoneNumber: json['display_phone_number']?.toString(),
      accessTokenEncrypted: json['access_token_encrypted']?.toString(),
      status: whatsappConfigStatusFromString(json['status']?.toString()),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      templateAutoSubmitEnabled:
          json['template_auto_submit_enabled'] == true ||
          json['template_auto_submit_enabled'] == 1,
      templateDefaultLanguage:
          json['template_default_language']?.toString() ?? 'it',
      templateDefaultCategory:
          json['template_default_category']?.toString() ?? 'utility',
      lastHealthCheckAt: parseDate(json['last_health_check_at']),
      lastErrorCode: json['last_error_code']?.toString(),
      lastErrorMessage: json['last_error_message']?.toString(),
      requiresReconnect:
          json['requires_reconnect'] == true || json['requires_reconnect'] == 1,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'waba_id': wabaId,
      'phone_number_id': phoneNumberId,
      'display_phone_number': displayPhoneNumber,
      'access_token_encrypted': accessTokenEncrypted,
      'status': whatsappConfigStatusToString(status),
      'is_default': isDefault,
      'template_auto_submit_enabled': templateAutoSubmitEnabled,
      'template_default_language': templateDefaultLanguage,
      'template_default_category': templateDefaultCategory,
      'last_health_check_at': lastHealthCheckAt?.toIso8601String(),
      'last_error_code': lastErrorCode,
      'last_error_message': lastErrorMessage,
      'requires_reconnect': requiresReconnect,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
