class BusinessWhatsappSettings {
  final int? id;
  final int businessId;
  final bool whatsappEnabled;
  final bool activationAllowed;
  final bool messagesEnabled;
  final bool allowBusinessSelfOnboarding;
  final bool allowLocationMapping;
  final String defaultChannelMode;
  final String status;
  final String? lastGoLiveCheckAt;
  final String? lastErrorCode;
  final String? lastErrorMessage;

  const BusinessWhatsappSettings({
    required this.id,
    required this.businessId,
    required this.whatsappEnabled,
    required this.activationAllowed,
    required this.messagesEnabled,
    required this.allowBusinessSelfOnboarding,
    required this.allowLocationMapping,
    required this.defaultChannelMode,
    required this.status,
    this.lastGoLiveCheckAt,
    this.lastErrorCode,
    this.lastErrorMessage,
  });

  bool get canOnboard =>
      whatsappEnabled && activationAllowed && allowBusinessSelfOnboarding;

  factory BusinessWhatsappSettings.fromJson(Map<String, dynamic> json) {
    bool asBool(dynamic value) => value == true || value == 1 || value == '1';

    return BusinessWhatsappSettings(
      id: (json['id'] as num?)?.toInt(),
      businessId: (json['business_id'] as num?)?.toInt() ?? 0,
      whatsappEnabled: asBool(json['whatsapp_enabled']),
      activationAllowed: asBool(json['activation_allowed']),
      messagesEnabled: asBool(json['messages_enabled']),
      allowBusinessSelfOnboarding: asBool(
        json['allow_business_self_onboarding'],
      ),
      allowLocationMapping: asBool(json['allow_location_mapping']),
      defaultChannelMode:
          json['default_channel_mode']?.toString() ?? 'business_default',
      status: json['status']?.toString() ?? 'not_enabled',
      lastGoLiveCheckAt: json['last_go_live_check_at']?.toString(),
      lastErrorCode: json['last_error_code']?.toString(),
      lastErrorMessage: json['last_error_message']?.toString(),
    );
  }
}
