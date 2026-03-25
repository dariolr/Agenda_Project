class WhatsappLocationMapping {
  final int id;
  final int businessId;
  final int locationId;
  final int whatsappConfigId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WhatsappLocationMapping({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.whatsappConfigId,
    this.createdAt,
    this.updatedAt,
  });

  factory WhatsappLocationMapping.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    }

    return WhatsappLocationMapping(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessId: (json['business_id'] as num?)?.toInt() ?? 0,
      locationId: (json['location_id'] as num?)?.toInt() ?? 0,
      whatsappConfigId: (json['whatsapp_config_id'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'location_id': locationId,
      'whatsapp_config_id': whatsappConfigId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
