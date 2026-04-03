class BusinessPaymentMethod {
  const BusinessPaymentMethod({
    required this.id,
    required this.businessId,
    required this.code,
    required this.name,
    required this.sortOrder,
    this.iconKey,
    required this.isActive,
  });

  final int id;
  final int businessId;
  final String code;
  final String name;
  final int sortOrder;
  final String? iconKey;
  final bool isActive;

  factory BusinessPaymentMethod.fromJson(Map<String, dynamic> json) {
    return BusinessPaymentMethod(
      id: json['id'] as int? ?? 0,
      businessId: json['business_id'] as int? ?? 0,
      code: (json['code'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      sortOrder: json['sort_order'] as int? ?? 0,
      iconKey: json['icon_key'] as String?,
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}
