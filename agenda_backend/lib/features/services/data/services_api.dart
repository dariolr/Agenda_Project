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

  // ===== Services CRUD =====

  /// POST /v1/businesses/{business_id}/services
  /// Creates a new service with variants for multiple locations
  Future<Service> createServiceMultiLocation({
    required int businessId,
    required List<int> locationIds,
    required String name,
    int? categoryId,
    String? description,
    int durationMinutes = 30,
    double price = 0,
    String? colorHex,
    bool isBookableOnline = true,
    bool isPriceStartingFrom = false,
    int? processingTime,
    int? blockedTime,
  }) async {
    final data = await _apiClient.createServiceMultiLocation(
      businessId: businessId,
      locationIds: locationIds,
      name: name,
      categoryId: categoryId,
      description: description,
      durationMinutes: durationMinutes,
      price: price,
      colorHex: colorHex,
      isBookableOnline: isBookableOnline,
      isPriceStartingFrom: isPriceStartingFrom,
      processingTime: processingTime,
      blockedTime: blockedTime,
    );
    return Service.fromJson(data['service'] as Map<String, dynamic>);
  }

  /// POST /v1/locations/{location_id}/services
  /// Creates a new service (legacy, single location)
  Future<Service> createService({
    required int locationId,
    required String name,
    int? categoryId,
    String? description,
    int durationMinutes = 30,
    double price = 0,
    String? colorHex,
    bool isBookableOnline = true,
    bool isPriceStartingFrom = false,
    int? processingTime,
    int? blockedTime,
  }) async {
    final data = await _apiClient.createService(
      locationId: locationId,
      name: name,
      categoryId: categoryId,
      description: description,
      durationMinutes: durationMinutes,
      price: price,
      colorHex: colorHex,
      isBookableOnline: isBookableOnline,
      isPriceStartingFrom: isPriceStartingFrom,
      processingTime: processingTime,
      blockedTime: blockedTime,
    );
    return Service.fromJson(data['service'] as Map<String, dynamic>);
  }

  /// PUT /v1/services/{id}
  /// Updates an existing service
  Future<Service> updateService({
    required int serviceId,
    required int locationId,
    String? name,
    int? categoryId,
    bool setCategoryIdNull = false,
    String? description,
    int? durationMinutes,
    double? price,
    String? colorHex,
    bool? isBookableOnline,
    bool? isPriceStartingFrom,
    int? sortOrder,
    int? processingTime,
    int? blockedTime,
  }) async {
    final data = await _apiClient.updateService(
      serviceId: serviceId,
      locationId: locationId,
      name: name,
      categoryId: categoryId,
      setCategoryIdNull: setCategoryIdNull,
      description: description,
      durationMinutes: durationMinutes,
      price: price,
      colorHex: colorHex,
      isBookableOnline: isBookableOnline,
      isPriceStartingFrom: isPriceStartingFrom,
      sortOrder: sortOrder,
      processingTime: processingTime,
      blockedTime: blockedTime,
    );
    return Service.fromJson(data['service'] as Map<String, dynamic>);
  }

  /// DELETE /v1/services/{id}
  /// Soft deletes a service
  Future<void> deleteService(int serviceId) async {
    await _apiClient.deleteService(serviceId);
  }

  /// GET /v1/services/{id}/locations
  /// Gets the location IDs where this service has an active variant
  Future<List<int>> getServiceLocations(int serviceId) async {
    return _apiClient.getServiceLocations(serviceId);
  }

  /// PUT /v1/services/{id}/locations
  /// Updates the locations associated with a service
  Future<List<int>> updateServiceLocations({
    required int serviceId,
    required List<int> locationIds,
  }) async {
    return _apiClient.updateServiceLocations(
      serviceId: serviceId,
      locationIds: locationIds,
    );
  }

  // ===== Categories CRUD =====

  /// GET /v1/businesses/{business_id}/categories
  /// Gets all service categories for a business
  Future<List<ServiceCategory>> fetchCategories(int businessId) async {
    final data = await _apiClient.getServiceCategories(businessId);
    final List<dynamic> items = data['categories'] ?? [];
    return items
        .map((json) => ServiceCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// POST /v1/businesses/{business_id}/categories
  /// Creates a new category
  Future<ServiceCategory> createCategory({
    required int businessId,
    required String name,
    String? description,
  }) async {
    final data = await _apiClient.createServiceCategory(
      businessId: businessId,
      name: name,
      description: description,
    );
    return ServiceCategory.fromJson(data['category'] as Map<String, dynamic>);
  }

  /// PUT /v1/categories/{id}
  /// Updates an existing category
  Future<ServiceCategory> updateCategory({
    required int categoryId,
    String? name,
    String? description,
    int? sortOrder,
  }) async {
    final data = await _apiClient.updateServiceCategory(
      categoryId: categoryId,
      name: name,
      description: description,
      sortOrder: sortOrder,
    );
    return ServiceCategory.fromJson(data['category'] as Map<String, dynamic>);
  }

  /// DELETE /v1/categories/{id}
  /// Deletes a category (services become uncategorized)
  Future<void> deleteCategory(int categoryId) async {
    await _apiClient.deleteServiceCategory(categoryId);
  }
}
