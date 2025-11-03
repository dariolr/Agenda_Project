class ServiceVariant {
  final int id;
  final int serviceId;
  final int locationId;
  final int durationMinutes;
  final double price;
  final String? colorHex;

  const ServiceVariant({
    required this.id,
    required this.serviceId,
    required this.locationId,
    required this.durationMinutes,
    required this.price,
    this.colorHex,
  });
}

