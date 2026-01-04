class Booking {
  final int id;
  final int businessId;
  final int locationId;
  final int? clientId;
  final String? clientName;
  final String? notes;

  const Booking({
    required this.id,
    required this.businessId,
    required this.locationId,
    this.clientId,
    this.clientName,
    this.notes,
  });

  Booking copyWith({
    int? id,
    int? businessId,
    int? locationId,
    int? clientId,
    String? clientName,
    String? notes,
  }) {
    return Booking(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      locationId: locationId ?? this.locationId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      notes: notes ?? this.notes,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as int,
    businessId: json['business_id'] as int,
    locationId: json['location_id'] as int,
    clientId: json['client_id'] as int?,
    clientName: json['client_name'] as String? ?? '',
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'location_id': locationId,
    if (clientId != null) 'client_id': clientId,
    'client_name': clientName,
    if (notes != null) 'notes': notes,
  };
}
