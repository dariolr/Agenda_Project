import 'class_booking.dart';

class ClassEvent {
  final int id;
  final int businessId;
  final int classTypeId;
  final DateTime startsAtUtc;
  final DateTime endsAtUtc;
  final DateTime? startsAtLocal;
  final DateTime? endsAtLocal;
  final int locationId;
  final int? resourceId;
  final int staffId;
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
    required this.businessId,
    required this.classTypeId,
    required this.startsAtUtc,
    required this.endsAtUtc,
    this.startsAtLocal,
    this.endsAtLocal,
    required this.capacityTotal,
    required this.capacityReserved,
    required this.confirmedCount,
    required this.waitlistCount,
    required this.waitlistEnabled,
    required this.cancelCutoffMinutes,
    required this.status,
    required this.visibility,
    required this.locationId,
    required this.staffId,
    this.resourceId,
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
    return ClassEvent(
      id: (json['id'] as num).toInt(),
      businessId:
          (json['business_id'] as num?)?.toInt() ??
          (json['tenant_id'] as num?)?.toInt() ??
          0,
      classTypeId: (json['class_type_id'] as num?)?.toInt() ?? 0,
      startsAtUtc: _parseUtcDateTime(
        (json['starts_at'] ?? json['starts_at_utc']) as String,
      ),
      endsAtUtc: _parseUtcDateTime(
        (json['ends_at'] ?? json['ends_at_utc']) as String,
      ),
      startsAtLocal:
          (json['starts_at_local'] as String?) != null
          ? _parseLocalDateTime(json['starts_at_local'] as String)
          : null,
      endsAtLocal:
          (json['ends_at_local'] as String?) != null
          ? _parseLocalDateTime(json['ends_at_local'] as String)
          : null,
      locationId: (json['location_id'] as num).toInt(),
      resourceId:
          (json['resource_id'] as num?)?.toInt() ??
          _firstResourceId(json['resource_requirements']),
      staffId:
          (json['staff_id'] as num?)?.toInt() ??
          (json['instructor_staff_id'] as num?)?.toInt() ??
          0,
      capacityTotal: (json['capacity_total'] as num?)?.toInt() ?? 1,
      capacityReserved: (json['capacity_reserved'] as num?)?.toInt() ?? 0,
      confirmedCount: (json['confirmed_count'] as num?)?.toInt() ?? 0,
      waitlistCount: (json['waitlist_count'] as num?)?.toInt() ?? 0,
      waitlistEnabled: (json['waitlist_enabled'] as bool?) ??
          ((json['waitlist_enabled'] as num?)?.toInt() == 1),
      bookingOpenAtUtc: (json['booking_open_at'] ?? json['booking_open_at_utc']) !=
              null
          ? _parseUtcDateTime(
              (json['booking_open_at'] ?? json['booking_open_at_utc']) as String,
            )
          : null,
      bookingCloseAtUtc:
          (json['booking_close_at'] ?? json['booking_close_at_utc']) != null
          ? _parseUtcDateTime(
              (json['booking_close_at'] ?? json['booking_close_at_utc'])
                  as String,
            )
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

  static int? _firstResourceId(dynamic rawRequirements) {
    if (rawRequirements is! List || rawRequirements.isEmpty) {
      return null;
    }
    final first = rawRequirements.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }
    return (first['resource_id'] as num?)?.toInt();
  }

  static DateTime _parseUtcDateTime(String raw) {
    final trimmed = raw.trim();
    final hasOffset =
        trimmed.endsWith('Z') ||
        trimmed.contains('+') ||
        RegExp(r'-\d{2}:\d{2}$').hasMatch(trimmed);
    if (hasOffset) {
      return DateTime.parse(trimmed).toUtc();
    }
    return DateTime.parse('${trimmed.replaceFirst(' ', 'T')}Z').toUtc();
  }

  static DateTime _parseLocalDateTime(String raw) {
    return DateTime.parse(raw.trim().replaceFirst(' ', 'T'));
  }
}
