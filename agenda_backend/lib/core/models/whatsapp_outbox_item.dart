enum WhatsappOutboxStatus { queued, sent, delivered, read, failed }

WhatsappOutboxStatus whatsappOutboxStatusFromString(String? raw) {
  switch ((raw ?? '').toLowerCase().trim()) {
    case 'queued':
      return WhatsappOutboxStatus.queued;
    case 'sent':
      return WhatsappOutboxStatus.sent;
    case 'delivered':
      return WhatsappOutboxStatus.delivered;
    case 'read':
      return WhatsappOutboxStatus.read;
    case 'failed':
      return WhatsappOutboxStatus.failed;
    default:
      return WhatsappOutboxStatus.queued;
  }
}

String whatsappOutboxStatusToString(WhatsappOutboxStatus status) {
  return switch (status) {
    WhatsappOutboxStatus.queued => 'queued',
    WhatsappOutboxStatus.sent => 'sent',
    WhatsappOutboxStatus.delivered => 'delivered',
    WhatsappOutboxStatus.read => 'read',
    WhatsappOutboxStatus.failed => 'failed',
  };
}

class WhatsappOutboxItem {
  final int id;
  final int businessId;
  final int? bookingId;
  final int? locationId;
  final int? whatsappConfigId;
  final String recipientPhone;
  final String templateName;
  final String templateLanguage;
  final WhatsappOutboxStatus status;
  final int attempts;
  final int maxAttempts;
  final String? providerMessageId;
  final String? errorMessage;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WhatsappOutboxItem({
    required this.id,
    required this.businessId,
    this.bookingId,
    this.locationId,
    this.whatsappConfigId,
    required this.recipientPhone,
    required this.templateName,
    required this.templateLanguage,
    required this.status,
    this.attempts = 0,
    this.maxAttempts = 3,
    this.providerMessageId,
    this.errorMessage,
    this.scheduledAt,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.createdAt,
    this.updatedAt,
  });

  factory WhatsappOutboxItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    }

    return WhatsappOutboxItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessId: (json['business_id'] as num?)?.toInt() ?? 0,
      bookingId: (json['booking_id'] as num?)?.toInt(),
      locationId: (json['location_id'] as num?)?.toInt(),
      whatsappConfigId: (json['whatsapp_config_id'] as num?)?.toInt(),
      recipientPhone: (json['recipient_phone'] ?? '').toString(),
      templateName: (json['template_name'] ?? '').toString(),
      templateLanguage: (json['template_language'] ?? 'it').toString(),
      status: whatsappOutboxStatusFromString(json['status']?.toString()),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      maxAttempts: (json['max_attempts'] as num?)?.toInt() ?? 3,
      providerMessageId: json['provider_message_id']?.toString(),
      errorMessage: json['error_message']?.toString(),
      scheduledAt: parseDate(json['scheduled_at']),
      sentAt: parseDate(json['sent_at']),
      deliveredAt: parseDate(json['delivered_at']),
      readAt: parseDate(json['read_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'booking_id': bookingId,
      'location_id': locationId,
      'whatsapp_config_id': whatsappConfigId,
      'recipient_phone': recipientPhone,
      'template_name': templateName,
      'template_language': templateLanguage,
      'status': whatsappOutboxStatusToString(status),
      'attempts': attempts,
      'max_attempts': maxAttempts,
      'provider_message_id': providerMessageId,
      'error_message': errorMessage,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
