class BusinessWhatsappSettings {
  final int? id;
  final int businessId;
  final bool whatsappEnabled;
  final bool messagesEnabled;
  final bool businessMessagesEnabled;
  final bool effectiveMessagesEnabled;
  final bool allowLocationMapping;
  final String defaultChannelMode;
  final String existingClientsOptInPolicy;
  final String? existingClientsOptInAssumedAt;
  final String status;
  final String? lastGoLiveCheckAt;
  final String? lastErrorCode;
  final String? lastErrorMessage;

  const BusinessWhatsappSettings({
    required this.id,
    required this.businessId,
    required this.whatsappEnabled,
    required this.messagesEnabled,
    required this.businessMessagesEnabled,
    required this.effectiveMessagesEnabled,
    required this.allowLocationMapping,
    required this.defaultChannelMode,
    required this.existingClientsOptInPolicy,
    this.existingClientsOptInAssumedAt,
    required this.status,
    this.lastGoLiveCheckAt,
    this.lastErrorCode,
    this.lastErrorMessage,
  });

  bool get canOnboard => whatsappEnabled;
  bool get canSendMessages => effectiveMessagesEnabled;

  factory BusinessWhatsappSettings.fromJson(Map<String, dynamic> json) {
    bool asBool(dynamic value) => value == true || value == 1 || value == '1';

    return BusinessWhatsappSettings(
      id: (json['id'] as num?)?.toInt(),
      businessId: (json['business_id'] as num?)?.toInt() ?? 0,
      whatsappEnabled: asBool(json['whatsapp_enabled']),
      messagesEnabled: asBool(json['messages_enabled']),
      businessMessagesEnabled: asBool(json['business_messages_enabled'] ?? 1),
      effectiveMessagesEnabled: asBool(
        json['effective_messages_enabled'] ??
            (asBool(json['whatsapp_enabled']) &&
                asBool(json['messages_enabled']) &&
                asBool(json['business_messages_enabled'] ?? 1)),
      ),
      allowLocationMapping: asBool(json['allow_location_mapping']),
      defaultChannelMode:
          json['default_channel_mode']?.toString() ?? 'business_default',
      existingClientsOptInPolicy:
          json['existing_clients_opt_in_policy']?.toString() ?? 'explicit_only',
      existingClientsOptInAssumedAt: json['existing_clients_opt_in_assumed_at']
          ?.toString(),
      status: json['status']?.toString() ?? 'not_enabled',
      lastGoLiveCheckAt: json['last_go_live_check_at']?.toString(),
      lastErrorCode: json['last_error_code']?.toString(),
      lastErrorMessage: json['last_error_message']?.toString(),
    );
  }
}
