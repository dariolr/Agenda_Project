import 'package:agenda_backend/core/models/service.dart';
import 'package:agenda_backend/core/models/service_category.dart';

class ServiceValidators {
  const ServiceValidators._();

  static bool isNonEmpty(String value) => value.trim().isNotEmpty;

  static bool isDuplicateCategoryName(
    List<ServiceCategory> categories,
    String normalizedName, {
    int? excludeId,
  }) {
    final needle = normalizedName.toLowerCase();
    return categories.any(
      (c) => c.id != excludeId && c.name.toLowerCase() == needle,
    );
  }

  static bool isDuplicateServiceName(
    List<Service> services,
    String normalizedName, {
    int? excludeId,
  }) {
    final needle = normalizedName.toLowerCase();
    return services.any(
      (s) => s.id != excludeId && s.name.toLowerCase() == needle,
    );
  }
}
