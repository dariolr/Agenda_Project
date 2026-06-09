/// Prenotazione di un cliente a un evento di classe.
/// Restituita da GET /v1/customer/class-bookings
class ClassBookingItem {
  final int id;
  final int businessId;
  final int classEventId;
  final int classTypeId;
  final String classTypeName;
  final String? classTypeColorHex;
  final int locationId;
  final String locationName;
  final String? locationAddress;
  final String? locationCity;
  final DateTime startsAt; // UTC
  final DateTime endsAt; // UTC
  final String? startsAtLocal; // "YYYY-MM-DD HH:mm:ss" local
  final String? endsAtLocal;
  final String status; // confirmed|waitlisted|cancelled_by_customer|cancelled_by_staff|no_show|attended
  final int? waitlistPosition;
  final int? priceCents;
  final String? currency;
  final bool canCancel;
  final DateTime? canCancelUntil; // UTC
  final String? notes;

  const ClassBookingItem({
    required this.id,
    required this.businessId,
    required this.classEventId,
    required this.classTypeId,
    required this.classTypeName,
    this.classTypeColorHex,
    required this.locationId,
    required this.locationName,
    this.locationAddress,
    this.locationCity,
    required this.startsAt,
    required this.endsAt,
    this.startsAtLocal,
    this.endsAtLocal,
    required this.status,
    this.waitlistPosition,
    this.priceCents,
    this.currency,
    required this.canCancel,
    this.canCancelUntil,
    this.notes,
  });

  factory ClassBookingItem.fromJson(Map<String, dynamic> json) {
    return ClassBookingItem(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      classEventId: json['class_event_id'] as int,
      classTypeId: json['class_type_id'] as int,
      classTypeName: json['class_type_name'] as String? ?? '',
      classTypeColorHex: json['class_type_color_hex'] as String?,
      locationId: json['location_id'] as int,
      locationName: json['location_name'] as String? ?? '',
      locationAddress: json['location_address'] as String?,
      locationCity: json['location_city'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      startsAtLocal: json['starts_at_local'] as String?,
      endsAtLocal: json['ends_at_local'] as String?,
      status: json['status'] as String? ?? 'confirmed',
      waitlistPosition: json['waitlist_position'] as int?,
      priceCents: json['price_cents'] as int?,
      currency: json['currency'] as String?,
      canCancel: json['can_cancel'] as bool? ?? false,
      canCancelUntil: json['can_cancel_until'] != null
          ? DateTime.parse(json['can_cancel_until'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  bool get isCancelled =>
      status == 'cancelled_by_customer' || status == 'cancelled_by_staff';
  bool get isWaitlisted => status == 'waitlisted';
  bool get isConfirmed => status == 'confirmed';

  /// DateTime da mostrare (local se disponibile, altrimenti UTC → device local)
  DateTime get displayStartsAt {
    if (startsAtLocal != null) {
      try {
        return DateTime.parse(startsAtLocal!.replaceFirst(' ', 'T'));
      } catch (_) {}
    }
    return startsAt.toLocal();
  }

  DateTime get displayEndsAt {
    if (endsAtLocal != null) {
      try {
        return DateTime.parse(endsAtLocal!.replaceFirst(' ', 'T'));
      } catch (_) {}
    }
    return endsAt.toLocal();
  }

  String get formattedPrice {
    if (priceCents == null || priceCents == 0) return 'Gratis';
    final euros = priceCents! / 100.0;
    return '€${euros.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
