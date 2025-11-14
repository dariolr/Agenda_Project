import 'package:agenda_frontend/core/models/service.dart';
import 'package:agenda_frontend/core/models/service_category.dart';

/// Utils e validatori per Services/Categories (estratti 1:1 dalla screen)
class ServiceTextUtils {
  const ServiceTextUtils._();

  /// Normalizza il nome in "Title Case" con la stessa logica usata nello screen.
  static String normalizeTitleCased(String raw) {
    final trimmed = raw.trim();
    final parts = trimmed.split(' ');
    return parts
        .map(
          (w) => w.isEmpty
              ? ''
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

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
