class Booking {
  final int id;
  final int businessId;
  final int locationId;
  final int? clientId;
  final String? customerName;
  final String? notes;

  const Booking({
    required this.id,
    required this.businessId,
    required this.locationId,
    this.clientId,
    this.customerName,
    this.notes,
  });

  Booking copyWith({
    int? id,
    int? businessId,
    int? locationId,
    int? clientId,
    String? customerName,
    String? notes,
  }) {
    return Booking(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      locationId: locationId ?? this.locationId,
      clientId: clientId ?? this.clientId,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as int,
    businessId: json['business_id'] as int,
    locationId: json['location_id'] as int,
    clientId: json['client_id'] as int?,
    customerName: json['customer_name'] as String? ?? '',
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'location_id': locationId,
    if (clientId != null) 'client_id': clientId,
    'customer_name': customerName,
    if (notes != null) 'notes': notes,
  };
}
