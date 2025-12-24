class ServiceStaffEligibility {
  final int serviceId;
  final int staffId;
  final int? locationId; // null => valido per tutte le location del servizio

  const ServiceStaffEligibility({
    required this.serviceId,
    required this.staffId,
    this.locationId,
  });
}

