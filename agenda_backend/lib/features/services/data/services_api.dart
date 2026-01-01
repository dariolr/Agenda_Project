import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/network/api_client.dart';

/// Risultato della chiamata API servizi (include categorie)
class ServicesApiResult {
  final List<Service> services;
  final List<ServiceCategory> categories;

  ServicesApiResult({required this.services, required this.categories});
}

/// API layer per Services - chiamate reali a agenda_core
class ServicesApi {
  final ApiClient _apiClient;

  ServicesApi({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /v1/services?location_id=X
  /// Ritorna sia servizi che categorie dalla risposta API
  Future<ServicesApiResult> fetchServicesWithCategories(int locationId) async {
    final data = await _apiClient.getServices(locationId);

    // Parse services
    final List<dynamic> serviceItems = data['services'] ?? [];
    final services = serviceItems
        .map((json) => Service.fromJson(json as Map<String, dynamic>))
        .toList();

    // Parse categories dalla risposta API
    final List<dynamic> categoryItems = data['categories'] ?? [];
    final categories = <ServiceCategory>[];
    int sortOrder = 0;

    for (final catJson in categoryItems) {
      final catMap = catJson as Map<String, dynamic>;
      // L'API ritorna id e name per ogni categoria
      if (catMap['id'] != null) {
        categories.add(
          ServiceCategory(
            id: catMap['id'] as int,
            businessId: 0, // Non usato nel frontend
            name: catMap['name'] as String? ?? '',
            sortOrder: sortOrder++,
          ),
        );
      }
    }

    return ServicesApiResult(services: services, categories: categories);
  }

  /// GET /v1/services?location_id=X (legacy - solo servizi)
  Future<List<Service>> fetchServices(int locationId) async {
    final result = await fetchServicesWithCategories(locationId);
    return result.services;
  }
}
