class Booking {
  final int id;
  final int businessId;
  final int locationId;
  final String customerName;
  final String? notes;

  const Booking({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.customerName,
    this.notes,
  });
}

