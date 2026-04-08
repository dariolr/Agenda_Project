class BusinessPaymentMethod {
  const BusinessPaymentMethod({
    required this.id,
    required this.businessId,
    required this.code,
    required this.name,
    required this.sortOrder,
    this.iconKey,
    required this.isRevenue,
    required this.isActive,
  });

  final int id;
  final int businessId;
  final String code;
  final String name;
  final int sortOrder;
  final String? iconKey;
  final bool isRevenue;
  final bool isActive;

  factory BusinessPaymentMethod.fromJson(Map<String, dynamic> json) {
    return BusinessPaymentMethod(
      id: json['id'] as int? ?? 0,
      businessId: json['business_id'] as int? ?? 0,
      code: (json['code'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      sortOrder: json['sort_order'] as int? ?? 0,
      iconKey: json['icon_key'] as String?,
      isRevenue: _parseBool(json['is_revenue'], defaultValue: true),
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  static bool _parseBool(dynamic value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
        return true;
      }
      if (normalized == '0' || normalized == 'false' || normalized == 'no') {
        return false;
      }
    }
    return defaultValue;
  }
}
