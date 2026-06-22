class WhatsappTemplateAssignment {
  final int id;
  final int businessId;
  final int? locationId;
  final String messageType;
  final String languageCode;
  final int whatsappTemplateId;
  final bool isActive;
  final String? templateName;
  final String? templateStatus;

  const WhatsappTemplateAssignment({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.messageType,
    required this.languageCode,
    required this.whatsappTemplateId,
    required this.isActive,
    this.templateName,
    this.templateStatus,
  });

  factory WhatsappTemplateAssignment.fromJson(Map<String, dynamic> json) {
    return WhatsappTemplateAssignment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessId: (json['business_id'] as num?)?.toInt() ?? 0,
      locationId: (json['location_id'] as num?)?.toInt(),
      messageType: (json['message_type'] ?? '').toString(),
      languageCode: (json['language_code'] ?? 'it').toString(),
      whatsappTemplateId: (json['whatsapp_template_id'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      templateName: json['template_name']?.toString(),
      templateStatus: json['template_status']?.toString(),
    );
  }
}
