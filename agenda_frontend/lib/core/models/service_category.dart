class ServiceCategory {
  final int id;
  final int businessId;
  final String name;
  final String? description;

  const ServiceCategory({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
  });
}
