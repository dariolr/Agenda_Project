import 'class_booking.dart';

class ClassEvent {
  final int id;
  final int tenantId;
  final int classTypeId;
  final String title;
  final DateTime startsAtUtc;
  final DateTime endsAtUtc;
  final int? locationId;
  final int? resourceId;
  final int? instructorStaffId;
  final int capacityTotal;
  final int capacityReserved;
  final int confirmedCount;
  final int waitlistCount;
  final bool waitlistEnabled;
  final DateTime? bookingOpenAtUtc;
  final DateTime? bookingCloseAtUtc;
  final int cancelCutoffMinutes;
  final String status;
  final String visibility;
  final int? priceCents;
  final String? currency;
  final String? myBookingStatus;
  final ClassBooking? myBooking;

  const ClassEvent({
    required this.id,
    required this.tenantId,
    required this.classTypeId,
    required this.title,
    required this.startsAtUtc,
    required this.endsAtUtc,
    required this.capacityTotal,
    required this.capacityReserved,
    required this.confirmedCount,
    required this.waitlistCount,
    required this.waitlistEnabled,
    required this.cancelCutoffMinutes,
    required this.status,
    required this.visibility,
    this.locationId,
    this.resourceId,
    this.instructorStaffId,
    this.bookingOpenAtUtc,
    this.bookingCloseAtUtc,
    this.priceCents,
    this.currency,
    this.myBookingStatus,
    this.myBooking,
  });

  int get spotsLeft => capacityTotal - capacityReserved - confirmedCount;
  bool get isFull => spotsLeft <= 0;

  factory ClassEvent.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String?;
    final fallbackTitle = json['class_type_name'] as String?;
    return ClassEvent(
      id: (json['id'] as num).toInt(),
      tenantId: (json['tenant_id'] as num?)?.toInt() ?? 0,
      classTypeId: (json['class_type_id'] as num?)?.toInt() ?? 0,
      title: rawTitle ?? fallbackTitle ?? 'Class event',
      startsAtUtc: DateTime.parse(json['starts_at_utc'] as String),
      endsAtUtc: DateTime.parse(json['ends_at_utc'] as String),
      locationId: (json['location_id'] as num?)?.toInt(),
      resourceId: (json['resource_id'] as num?)?.toInt(),
      instructorStaffId: (json['instructor_staff_id'] as num?)?.toInt(),
      capacityTotal: (json['capacity_total'] as num?)?.toInt() ?? 1,
      capacityReserved: (json['capacity_reserved'] as num?)?.toInt() ?? 0,
      confirmedCount: (json['confirmed_count'] as num?)?.toInt() ?? 0,
      waitlistCount: (json['waitlist_count'] as num?)?.toInt() ?? 0,
      waitlistEnabled: (json['waitlist_enabled'] as bool?) ??
          ((json['waitlist_enabled'] as num?)?.toInt() == 1),
      bookingOpenAtUtc: json['booking_open_at_utc'] != null
          ? DateTime.parse(json['booking_open_at_utc'] as String)
          : null,
      bookingCloseAtUtc: json['booking_close_at_utc'] != null
          ? DateTime.parse(json['booking_close_at_utc'] as String)
          : null,
      cancelCutoffMinutes:
          (json['cancel_cutoff_minutes'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String? ?? 'SCHEDULED').toUpperCase(),
      visibility: (json['visibility'] as String? ?? 'PUBLIC').toUpperCase(),
      priceCents: (json['price_cents'] as num?)?.toInt(),
      currency: json['currency'] as String?,
      myBookingStatus: json['my_booking_status'] as String?,
      myBooking: json['my_booking'] is Map<String, dynamic>
          ? ClassBooking.fromJson(json['my_booking'] as Map<String, dynamic>)
          : null,
    );
  }
}
