class ClassBooking {
  final int id;
  final int tenantId;
  final int classEventId;
  final int customerId;
  final String status;
  final int? waitlistPosition;
  final DateTime bookedAtUtc;
  final DateTime? cancelledAtUtc;
  final DateTime? checkedInAtUtc;
  final String? paymentStatus;
  final String? notes;

  const ClassBooking({
    required this.id,
    required this.tenantId,
    required this.classEventId,
    required this.customerId,
    required this.status,
    required this.bookedAtUtc,
    this.waitlistPosition,
    this.cancelledAtUtc,
    this.checkedInAtUtc,
    this.paymentStatus,
    this.notes,
  });

  bool get isConfirmed => status.toUpperCase() == 'CONFIRMED';
  bool get isWaitlisted => status.toUpperCase() == 'WAITLISTED';

  factory ClassBooking.fromJson(Map<String, dynamic> json) {
    return ClassBooking(
      id: (json['id'] as num).toInt(),
      tenantId: (json['tenant_id'] as num?)?.toInt() ?? 0,
      classEventId: (json['class_event_id'] as num).toInt(),
      customerId: (json['customer_id'] as num).toInt(),
      status: (json['status'] as String? ?? 'WAITLISTED').toUpperCase(),
      waitlistPosition: (json['waitlist_position'] as num?)?.toInt(),
      bookedAtUtc: DateTime.parse(json['booked_at_utc'] as String),
      cancelledAtUtc: json['cancelled_at_utc'] != null
          ? DateTime.parse(json['cancelled_at_utc'] as String)
          : null,
      checkedInAtUtc: json['checked_in_at_utc'] != null
          ? DateTime.parse(json['checked_in_at_utc'] as String)
          : null,
      paymentStatus: json['payment_status'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
