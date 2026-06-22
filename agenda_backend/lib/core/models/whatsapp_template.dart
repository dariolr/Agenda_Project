class WhatsappTemplate {
  final int id;
  final int? businessId;
  final String templateName;
  final String languageCode;
  final String category;
  final String status;
  final String? messageType;
  final String? bodyPreview;

  const WhatsappTemplate({
    required this.id,
    required this.businessId,
    required this.templateName,
    required this.languageCode,
    required this.category,
    required this.status,
    this.messageType,
    this.bodyPreview,
  });

  bool get isApproved => status == 'approved';

  factory WhatsappTemplate.fromJson(Map<String, dynamic> json) {
    return WhatsappTemplate(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessId: (json['business_id'] as num?)?.toInt(),
      templateName: (json['template_name'] ?? '').toString(),
      languageCode: (json['language_code'] ?? 'it').toString(),
      category: (json['category'] ?? 'utility').toString(),
      status: (json['status'] ?? 'draft').toString(),
      messageType: json['message_type']?.toString(),
      bodyPreview: json['body_preview']?.toString(),
    );
  }
}
