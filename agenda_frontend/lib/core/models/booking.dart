class Booking {
  final int id;
  final int businessId;
  final int locationId;
  final int? clientId; // opzionale: collegamento al Client
  final String customerName;
  final String? notes;

  const Booking({
    required this.id,
    required this.businessId,
    required this.locationId,
    this.clientId,
    required this.customerName,
    this.notes,
  });
}
