class BookingDirectLink {
  final int businessId;
  final String businessSlug;
  final String linkSlug;
  final int locationId;
  final String scopeType;
  final bool requiresLocationSelection;
  final List<int> compatibleLocationIds;
  final String targetType;
  final int targetId;
  final String? childVisibilityScope;
  final Map<String, dynamic> target;

  const BookingDirectLink({
    required this.businessId,
    required this.businessSlug,
    required this.linkSlug,
    required this.locationId,
    this.scopeType = 'location',
    this.requiresLocationSelection = false,
    this.compatibleLocationIds = const [],
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
      scopeType: json['scope_type'] as String? ?? 'location',
      requiresLocationSelection:
          json['requires_location_selection'] as bool? ?? false,
      compatibleLocationIds:
          (json['compatible_location_ids'] as List<dynamic>? ?? const [])
              .map((value) => (value as num).toInt())
              .where((id) => id > 0)
              .toList(),
      targetType: json['target_type'] as String,
      targetId: (json['target_id'] as num).toInt(),
      childVisibilityScope: json['child_visibility_scope'] as String?,
      target: Map<String, dynamic>.from(
        json['target'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  bool get isLocationScoped => scopeType == 'location';
  bool get isBusinessScoped => scopeType == 'business';
  bool get isCategoryLink => targetType == 'service_category';
  bool get isStaffLink => targetType == 'staff';
  bool get locksLocation => isLocationScoped && locationId > 0;
  bool get locksStaff => isStaffLink;
  int? get lockedStaffId => locksStaff && targetId > 0 ? targetId : null;
}
