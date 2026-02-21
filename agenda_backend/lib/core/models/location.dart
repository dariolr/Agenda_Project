class Location {
  final int id;
  final int businessId;
  final String name;
  final String? address;
  final String? city;
  final String? region;
  final String? country;
  final String? phone;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String? currency;
  final String timezone;
  final int minBookingNoticeHours;
  final int maxBookingAdvanceDays;
  final bool allowCustomerChooseStaff;
  final int? cancellationHours;
  final int onlineBookingSlotIntervalMinutes;
  final String slotDisplayMode;
  final int minGapMinutes;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;

  const Location({
    required this.id,
    required this.businessId,
    required this.name,
    this.address,
    this.city,
    this.region,
    this.country,
    this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.currency,
    this.timezone = 'Europe/Rome',
    this.minBookingNoticeHours = 1,
    this.maxBookingAdvanceDays = 90,
    this.allowCustomerChooseStaff = false,
    this.cancellationHours,
    this.onlineBookingSlotIntervalMinutes = 15,
    this.slotDisplayMode = 'all',
    this.minGapMinutes = 30,
    this.isDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
  });

  Location copyWith({
    int? id,
    int? businessId,
    String? name,
    String? address,
    String? city,
    String? region,
    String? country,
    String? phone,
    String? email,
    double? latitude,
    double? longitude,
    String? currency,
    String? timezone,
    int? minBookingNoticeHours,
    int? maxBookingAdvanceDays,
    bool? allowCustomerChooseStaff,
    int? cancellationHours,
    int? onlineBookingSlotIntervalMinutes,
    String? slotDisplayMode,
    int? minGapMinutes,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
  }) {
    return Location(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      minBookingNoticeHours:
          minBookingNoticeHours ?? this.minBookingNoticeHours,
      maxBookingAdvanceDays:
          maxBookingAdvanceDays ?? this.maxBookingAdvanceDays,
      allowCustomerChooseStaff:
          allowCustomerChooseStaff ?? this.allowCustomerChooseStaff,
      cancellationHours: cancellationHours ?? this.cancellationHours,
      onlineBookingSlotIntervalMinutes:
          onlineBookingSlotIntervalMinutes ??
          this.onlineBookingSlotIntervalMinutes,
      slotDisplayMode: slotDisplayMode ?? this.slotDisplayMode,
      minGapMinutes: minGapMinutes ?? this.minGapMinutes,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      timezone: json['timezone'] as String? ?? 'Europe/Rome',
      minBookingNoticeHours: json['min_booking_notice_hours'] as int? ?? 1,
      maxBookingAdvanceDays: json['max_booking_advance_days'] as int? ?? 90,
      allowCustomerChooseStaff:
          json['allow_customer_choose_staff'] as bool? ?? false,
      cancellationHours: json['cancellation_hours'] as int?,
      onlineBookingSlotIntervalMinutes:
          json['online_booking_slot_interval_minutes'] as int? ?? 15,
      slotDisplayMode: json['slot_display_mode'] as String? ?? 'all',
      minGapMinutes: json['min_gap_minutes'] as int? ?? 30,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (region != null) 'region': region,
      if (country != null) 'country': country,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (currency != null) 'currency': currency,
      'timezone': timezone,
      'min_booking_notice_hours': minBookingNoticeHours,
      'max_booking_advance_days': maxBookingAdvanceDays,
      'allow_customer_choose_staff': allowCustomerChooseStaff,
      if (cancellationHours != null) 'cancellation_hours': cancellationHours,
      'online_booking_slot_interval_minutes':
          onlineBookingSlotIntervalMinutes,
      'slot_display_mode': slotDisplayMode,
      'min_gap_minutes': minGapMinutes,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }
}
