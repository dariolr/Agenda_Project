/// Modello per le prenotazioni utente recuperate da /v1/me/bookings
class BookingItem {
  final int id;
  final int businessId;
  final String businessName;
  final String? businessSlug;
  final int locationId;
  final String locationName;
  final String? locationAddress;
  final String? locationCity;
  final List<String> serviceNames;
  final List<String?> serviceDescriptions;
  final List<int> serviceIds;
  final int? staffId;
  final String? staffName;
  final List<String> staffNames;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String? notes;
  final String source;
  final bool canModify;
  final DateTime? canModifyUntil;
  final DateTime? createdAt;

  /// Direct link slug used to create this booking, if any.
  /// When present, "Prenota di nuovo" CTAs must use this slug.
  final String? bookingDirectLinkSlug;

  /// Raw API string for `can_modify_until` (ISO8601). Useful to display the
  /// location time without device timezone conversion.
  final String? canModifyUntilRaw;
  final String? createdAtRaw;
  final String status;

  const BookingItem({
    required this.id,
    required this.businessId,
    required this.businessName,
    this.businessSlug,
    required this.locationId,
    required this.locationName,
    this.locationAddress,
    this.locationCity,
    required this.serviceNames,
    this.serviceDescriptions = const [],
    this.serviceIds = const [],
    this.staffId,
    this.staffName,
    this.staffNames = const [],
    required this.startTime,
    required this.endTime,
    this.totalPrice = 0.0,
    this.notes,
    this.source = 'manual',
    required this.canModify,
    this.canModifyUntil,
    this.createdAt,
    this.canModifyUntilRaw,
    this.createdAtRaw,
    this.bookingDirectLinkSlug,
    this.status = 'confirmed',
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    // Supporta sia formato nested (location.id) che flat (location_id)
    final location = json['location'] as Map<String, dynamic>?;
    final business = json['business'] as Map<String, dynamic>?;

    return BookingItem(
      id: json['id'] as int? ?? json['booking_id'] as int,
      businessId: business?['id'] as int? ?? json['business_id'] as int,
      businessName:
          business?['name'] as String? ?? json['business_name'] as String,
      businessSlug: json['business_slug'] as String?,
      locationId: location?['id'] as int? ?? json['location_id'] as int,
      locationName:
          location?['name'] as String? ?? json['location_name'] as String,
      locationAddress:
          location?['address'] as String? ??
          json['location_address'] as String?,
      locationCity:
          location?['city'] as String? ?? json['location_city'] as String?,
      serviceNames: _parseServiceNames(json),
      serviceDescriptions: _parseServiceDescriptions(json),
      serviceIds: _parseServiceIds(json),
      staffId: json['staff_id'] as int?,
      staffName: json['staff_name'] as String?,
      staffNames: _parseStaffNames(json),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      totalPrice:
          (json['total_price'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0.0,
      notes: json['notes'] as String?,
      source: (json['source'] as String?) ?? 'manual',
      canModify: json['can_modify'] as bool? ?? false,
      canModifyUntil: json['can_modify_until'] != null
          ? DateTime.parse(json['can_modify_until'] as String)
          : null,
      canModifyUntilRaw: json['can_modify_until'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      createdAtRaw: json['created_at'] as String?,
      bookingDirectLinkSlug: json['booking_direct_link_slug'] as String?,
      status: json['status'] as String? ?? 'confirmed',
    );
  }

  /// Parsa service_names supportando sia array che singolo valore
  static List<String> _parseServiceNames(Map<String, dynamic> json) {
    // Formato array: service_names: ["Taglio", "Piega"]
    if (json.containsKey('service_names') && json['service_names'] != null) {
      final names = json['service_names'];
      if (names is List) {
        return names.map((e) => e.toString()).toList();
      }
    }
    // Formato singolo: service_name: "Taglio + Piega"
    if (json.containsKey('service_name') && json['service_name'] != null) {
      return [json['service_name'] as String];
    }
    return [];
  }

  /// Parsa descrizioni servizi supportando array e singolo valore.
  static List<String?> _parseServiceDescriptions(Map<String, dynamic> json) {
    if (json.containsKey('service_descriptions') &&
        json['service_descriptions'] != null) {
      final descriptions = json['service_descriptions'];
      if (descriptions is List) {
        return descriptions.map((e) => e?.toString()).toList();
      }
    }
    if (json.containsKey('service_description')) {
      return [json['service_description']?.toString()];
    }
    return [];
  }

  /// Parsa service_ids supportando sia array che singolo valore
  static List<int> _parseServiceIds(Map<String, dynamic> json) {
    if (json.containsKey('service_ids') && json['service_ids'] != null) {
      final ids = json['service_ids'];
      if (ids is List) {
        return ids.map((e) => e as int).toList();
      }
    }
    return [];
  }

  /// Parsa staff_names supportando sia array che singolo valore.
  static List<String> _parseStaffNames(Map<String, dynamic> json) {
    if (json.containsKey('staff_names') && json['staff_names'] != null) {
      final names = json['staff_names'];
      if (names is List) {
        return names
            .map((e) => e.toString().trim())
            .where((name) => name.isNotEmpty)
            .toList();
      }
    }
    if (json.containsKey('staff_name') && json['staff_name'] != null) {
      final name = (json['staff_name'] as String).trim();
      return name.isEmpty ? const [] : [name];
    }
    return [];
  }

  /// Stringa formattata dei servizi
  String get servicesDisplay => serviceNames.join(' + ');
  bool get isOnlineCustomerBooking =>
      source == 'online' || source == 'onlinestaff';
  bool get shouldShowCustomerNotes =>
      isOnlineCustomerBooking && (notes?.trim().isNotEmpty ?? false);

  bool isPastAt(DateTime referenceNow) => endTime.isBefore(referenceNow);
  bool isUpcomingAt(DateTime referenceNow) => !isPastAt(referenceNow);
  bool get isCancelled => status == 'cancelled';

  bool get isModifiableStatus =>
      status != 'cancelled' &&
      status != 'completed' &&
      status != 'no_show' &&
      status != 'replaced';
  bool get canModifyEffective => canModify && isModifiableStatus;

  /// Crea copia con nuovi valori (per update locale dopo reschedule)
  BookingItem copyWith({
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    String? source,
    bool? canModify,
    DateTime? canModifyUntil,
    String? canModifyUntilRaw,
    DateTime? createdAt,
    String? createdAtRaw,
    String? status,
  }) {
    return BookingItem(
      id: id,
      businessId: businessId,
      businessName: businessName,
      locationId: locationId,
      locationName: locationName,
      locationAddress: locationAddress,
      locationCity: locationCity,
      serviceNames: serviceNames,
      serviceDescriptions: serviceDescriptions,
      serviceIds: serviceIds,
      staffId: staffId,
      staffName: staffName,
      staffNames: staffNames,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPrice: totalPrice,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      canModify: canModify ?? this.canModify,
      canModifyUntil: canModifyUntil ?? this.canModifyUntil,
      canModifyUntilRaw: canModifyUntilRaw ?? this.canModifyUntilRaw,
      createdAt: createdAt ?? this.createdAt,
      createdAtRaw: createdAtRaw ?? this.createdAtRaw,
      status: status ?? this.status,
    );
  }
}
