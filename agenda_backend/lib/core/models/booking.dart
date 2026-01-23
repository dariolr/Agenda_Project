class Booking {
  final int id;
  final int businessId;
  final int locationId;
  final int? clientId;
  final String? clientName;
  final String? notes;
  final String status;
  final int? replacesBookingId;
  final int? replacedByBookingId;

  // Campi ricorrenza
  final int? recurrenceRuleId;
  final int? recurrenceIndex;
  final bool isRecurrenceParent;
  final bool hasConflict;

  const Booking({
    required this.id,
    required this.businessId,
    required this.locationId,
    this.clientId,
    this.clientName,
    this.notes,
    this.status = 'confirmed',
    this.replacesBookingId,
    this.replacedByBookingId,
    this.recurrenceRuleId,
    this.recurrenceIndex,
    this.isRecurrenceParent = false,
    this.hasConflict = false,
  });

  /// Indica se questa prenotazione è parte di una serie ricorrente
  bool get isRecurring => recurrenceRuleId != null;

  /// Indica se questa prenotazione è stata sostituita da un'altra
  bool get isReplaced => status == 'replaced' || replacedByBookingId != null;

  /// Indica se questa prenotazione sostituisce un'altra
  bool get isReplacement => replacesBookingId != null;

  Booking copyWith({
    int? id,
    int? businessId,
    int? locationId,
    int? clientId,
    String? clientName,
    String? notes,
    String? status,
    int? replacesBookingId,
    int? replacedByBookingId,
    int? recurrenceRuleId,
    int? recurrenceIndex,
    bool? isRecurrenceParent,
    bool? hasConflict,
  }) {
    return Booking(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      locationId: locationId ?? this.locationId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      replacesBookingId: replacesBookingId ?? this.replacesBookingId,
      replacedByBookingId: replacedByBookingId ?? this.replacedByBookingId,
      recurrenceRuleId: recurrenceRuleId ?? this.recurrenceRuleId,
      recurrenceIndex: recurrenceIndex ?? this.recurrenceIndex,
      isRecurrenceParent: isRecurrenceParent ?? this.isRecurrenceParent,
      hasConflict: hasConflict ?? this.hasConflict,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as int,
    businessId: json['business_id'] as int,
    locationId: json['location_id'] as int,
    clientId: json['client_id'] as int?,
    clientName: json['client_name'] as String? ?? '',
    notes: json['notes'] as String?,
    status: json['status'] as String? ?? 'confirmed',
    replacesBookingId: json['replaces_booking_id'] as int?,
    replacedByBookingId: json['replaced_by_booking_id'] as int?,
    recurrenceRuleId: json['recurrence_rule_id'] as int?,
    recurrenceIndex: json['recurrence_index'] as int?,
    isRecurrenceParent: (json['is_recurrence_parent'] as int? ?? 0) == 1,
    hasConflict: (json['has_conflict'] as int? ?? 0) == 1,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'location_id': locationId,
    if (clientId != null) 'client_id': clientId,
    'client_name': clientName,
    if (notes != null) 'notes': notes,
    'status': status,
    if (replacesBookingId != null) 'replaces_booking_id': replacesBookingId,
    if (replacedByBookingId != null)
      'replaced_by_booking_id': replacedByBookingId,
    if (recurrenceRuleId != null) 'recurrence_rule_id': recurrenceRuleId,
    if (recurrenceIndex != null) 'recurrence_index': recurrenceIndex,
    'is_recurrence_parent': isRecurrenceParent ? 1 : 0,
    'has_conflict': hasConflict ? 1 : 0,
  };
}
