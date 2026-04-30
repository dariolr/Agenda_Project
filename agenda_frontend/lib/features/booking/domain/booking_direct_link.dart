class BookingDirectLink {
  final int businessId;
  final String businessSlug;
  final String linkSlug;
  final int locationId;
  final String targetType;
  final int targetId;
  final String? childVisibilityScope;
  final Map<String, dynamic> target;

  const BookingDirectLink({
    required this.businessId,
    required this.businessSlug,
    required this.linkSlug,
    required this.locationId,
    required this.targetType,
    required this.targetId,
    this.childVisibilityScope,
    required this.target,
  });

  factory BookingDirectLink.fromJson(Map<String, dynamic> json) {
    return BookingDirectLink(
      businessId: (json['business_id'] as num).toInt(),
      businessSlug: json['business_slug'] as String,
      linkSlug: json['link_slug'] as String,
      locationId: (json['location_id'] as num?)?.toInt() ?? 0,
      targetType: json['target_type'] as String,
      targetId: (json['target_id'] as num).toInt(),
      childVisibilityScope: json['child_visibility_scope'] as String?,
      target: Map<String, dynamic>.from(
        json['target'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
