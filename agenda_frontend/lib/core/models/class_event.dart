/// Evento di classe prenotabile online (lezione di gruppo)
class ClassEvent {
  final int id;
  final int businessId;
  final int classTypeId;
  final String classTypeName;
  final String? classTypeColorHex;
  final int? classTypeServiceCategoryId;
  final String? classTypeServiceCategoryName;
  final String startsAt;
  final String? startsAtLocal;
  final String endsAt;
  final String? endsAtLocal;
  final int locationId;
  final int staffId;
  final int capacityTotal;
  final int capacityReserved;
  final int confirmedCount;
  final int waitlistCount;
  final bool waitlistEnabled;
  final String? bookingOpenAt;
  final String? bookingCloseAt;
  final int cancelCutoffMinutes;
  final String status;
  final String visibility;
  final String onlineVisibility;
  final int? priceCents;
  final bool onlinePaymentRequired;
  final String? currency;
  final int spotsLeft;
  final bool isFull;

  const ClassEvent({
    required this.id,
    required this.businessId,
    required this.classTypeId,
    required this.classTypeName,
    this.classTypeColorHex,
    this.classTypeServiceCategoryId,
    this.classTypeServiceCategoryName,
    required this.startsAt,
    this.startsAtLocal,
    required this.endsAt,
    this.endsAtLocal,
    required this.locationId,
    required this.staffId,
    required this.capacityTotal,
    this.capacityReserved = 0,
    this.confirmedCount = 0,
    this.waitlistCount = 0,
    this.waitlistEnabled = true,
    this.bookingOpenAt,
    this.bookingCloseAt,
    this.cancelCutoffMinutes = 0,
    this.status = 'SCHEDULED',
    this.visibility = 'PUBLIC',
    this.onlineVisibility = 'public',
    this.priceCents,
    this.onlinePaymentRequired = false,
    this.currency,
    required this.spotsLeft,
    required this.isFull,
  });

  factory ClassEvent.fromJson(Map<String, dynamic> json) => ClassEvent(
    id: json['id'] as int,
    businessId: json['business_id'] as int,
    classTypeId: json['class_type_id'] as int,
    classTypeName: json['class_type_name'] as String? ?? '',
    classTypeColorHex: json['class_type_color_hex'] as String?,
    classTypeServiceCategoryId: json['class_type_service_category_id'] as int?,
    classTypeServiceCategoryName:
        json['class_type_service_category_name'] as String?,
    startsAt: json['starts_at'] as String,
    startsAtLocal: json['starts_at_local'] as String?,
    endsAt: json['ends_at'] as String,
    endsAtLocal: json['ends_at_local'] as String?,
    locationId: json['location_id'] as int,
    staffId:
        json['staff_id'] as int? ?? json['instructor_staff_id'] as int? ?? 0,
    capacityTotal: json['capacity_total'] as int? ?? 1,
    capacityReserved: json['capacity_reserved'] as int? ?? 0,
    confirmedCount: json['confirmed_count'] as int? ?? 0,
    waitlistCount: json['waitlist_count'] as int? ?? 0,
    waitlistEnabled: json['waitlist_enabled'] as bool? ?? true,
    bookingOpenAt: json['booking_open_at'] as String?,
    bookingCloseAt: json['booking_close_at'] as String?,
    cancelCutoffMinutes: json['cancel_cutoff_minutes'] as int? ?? 0,
    status: json['status'] as String? ?? 'SCHEDULED',
    visibility: json['visibility'] as String? ?? 'PUBLIC',
    onlineVisibility: json['online_visibility'] as String? ?? 'public',
    priceCents: json['price_cents'] as int?,
    onlinePaymentRequired: _parseBool(json['online_payment_required']),
    currency: json['currency'] as String?,
    spotsLeft: json['spots_left'] as int? ?? 0,
    isFull: json['is_full'] as bool? ?? false,
  );

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  String get formattedPrice {
    if (priceCents == null || priceCents == 0) return 'Gratis';
    final euros = priceCents! / 100;
    final priceStr = euros.toStringAsFixed(2).replaceAll('.', ',');
    return '€$priceStr';
  }

  /// Orario da mostrare al cliente: preferisce local, fallback a UTC
  String get displayStartsAt => startsAtLocal ?? startsAt;
  String get displayEndsAt => endsAtLocal ?? endsAt;

  /// True se la finestra di prenotazione è attualmente aperta.
  /// Rispetta bookingOpenAt, bookingCloseAt e — se bookingCloseAt è null —
  /// considera l'evento non prenotabile una volta iniziato.
  bool isBookingOpenAt(DateTime now) {
    final nowUtc = now.toUtc();
    if (bookingOpenAt != null) {
      if (nowUtc.isBefore(DateTime.parse(bookingOpenAt!).toUtc())) {
        return false;
      }
    }
    if (bookingCloseAt != null) {
      if (nowUtc.isAfter(DateTime.parse(bookingCloseAt!).toUtc())) {
        return false;
      }
    } else {
      if (!nowUtc.isBefore(DateTime.parse(startsAt).toUtc())) {
        return false;
      }
    }
    return true;
  }

  /// True se l'evento rientra nella finestra massima di prenotazione anticipata.
  bool isWithinAdvanceBookingWindow(DateTime now, int maxDays) {
    final start = DateTime.parse(startsAt).toUtc();
    final limit = now.toUtc().add(Duration(days: maxDays));
    return !start.isAfter(limit);
  }
}
