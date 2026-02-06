import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/network/api_client.dart';
import 'services_api.dart';

class ServicesRepository {
  ServicesRepository({required ApiClient apiClient})
    : _api = ServicesApi(apiClient: apiClient);

  final ServicesApi _api;

  /// Carica servizi e categorie dall'API
  Future<ServicesApiResult> getServicesWithCategories({
    required int locationId,
  }) => _api.fetchServicesWithCategories(locationId);

  /// Carica solo i servizi (legacy)
  Future<List<Service>> getServices({required int locationId}) =>
      _api.fetchServices(locationId);

  // ===== Services CRUD =====

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
  }) => _api.createServiceMultiLocation(
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
  }) => _api.createService(
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

  /// Updates an existing service
  Future<Service> updateService({
    required int serviceId,
    required int locationId,
    String? name,
    int? categoryId,
    bool setCategoryIdNull = false,
    String? description,
    bool setDescriptionNull = false,
    int? durationMinutes,
    double? price,
    String? colorHex,
    bool? isBookableOnline,
    bool? isPriceStartingFrom,
    int? sortOrder,
    int? processingTime,
    int? blockedTime,
  }) => _api.updateService(
    serviceId: serviceId,
    locationId: locationId,
    name: name,
    categoryId: categoryId,
    setCategoryIdNull: setCategoryIdNull,
    description: description,
    setDescriptionNull: setDescriptionNull,
    durationMinutes: durationMinutes,
    price: price,
    colorHex: colorHex,
    isBookableOnline: isBookableOnline,
    isPriceStartingFrom: isPriceStartingFrom,
    sortOrder: sortOrder,
    processingTime: processingTime,
    blockedTime: blockedTime,
  );

  /// Deletes a service
  Future<void> deleteService(int serviceId) => _api.deleteService(serviceId);

  /// Gets the location IDs where this service has an active variant
  Future<List<int>> getServiceLocations(int serviceId) =>
      _api.getServiceLocations(serviceId);

  /// Updates the locations associated with a service
  Future<List<int>> updateServiceLocations({
    required int serviceId,
    required List<int> locationIds,
  }) => _api.updateServiceLocations(
    serviceId: serviceId,
    locationIds: locationIds,
  );

  // ===== Categories CRUD =====

  /// Gets all categories for a business
  Future<List<ServiceCategory>> getCategories(int businessId) =>
      _api.fetchCategories(businessId);

  /// Creates a new category
  Future<ServiceCategory> createCategory({
    required int businessId,
    required String name,
    String? description,
  }) => _api.createCategory(
    businessId: businessId,
    name: name,
    description: description,
  );

  /// Updates an existing category
  Future<ServiceCategory> updateCategory({
    required int categoryId,
    String? name,
    String? description,
    int? sortOrder,
  }) => _api.updateCategory(
    categoryId: categoryId,
    name: name,
    description: description,
    sortOrder: sortOrder,
  );

  /// Deletes a category
  Future<void> deleteCategory(int categoryId) =>
      _api.deleteCategory(categoryId);
}
