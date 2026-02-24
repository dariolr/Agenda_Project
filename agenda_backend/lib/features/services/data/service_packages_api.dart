import '../../../core/models/service_package.dart';
import '../../../core/network/api_client.dart';

class ServicePackagesApi {
  final ApiClient _apiClient;

  ServicePackagesApi({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<ServicePackage>> fetchPackages(int locationId) async {
    final data = await _apiClient.getServicePackages(locationId);
    final items = data['packages'] as List<dynamic>? ?? const [];
    return items
        .map((json) => ServicePackage.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ServicePackage> createPackage({
    required int locationId,
    required String name,
    required int categoryId,
    required List<int> serviceIds,
    String? description,
    double? overridePrice,
    int? overrideDurationMinutes,
    bool isActive = true,
    bool isBookableOnline = true,
  }) async {
    final data = await _apiClient.createServicePackage(
      locationId: locationId,
      name: name,
      categoryId: categoryId,
      serviceIds: serviceIds,
      description: description,
      overridePrice: overridePrice,
      overrideDurationMinutes: overrideDurationMinutes,
      isActive: isActive,
      isBookableOnline: isBookableOnline,
    );
    return ServicePackage.fromJson(data['package'] as Map<String, dynamic>);
  }

  Future<ServicePackage> updatePackage({
    required int locationId,
    required int packageId,
    String? name,
    int? categoryId,
    String? description,
    double? overridePrice,
    int? overrideDurationMinutes,
    bool setOverridePriceNull = false,
    bool setOverrideDurationNull = false,
    bool? isActive,
    bool? isBookableOnline,
    List<int>? serviceIds,
  }) async {
    final data = await _apiClient.updateServicePackage(
      locationId: locationId,
      packageId: packageId,
      name: name,
      categoryId: categoryId,
      description: description,
      overridePrice: overridePrice,
      overrideDurationMinutes: overrideDurationMinutes,
      setOverridePriceNull: setOverridePriceNull,
      setOverrideDurationNull: setOverrideDurationNull,
      isActive: isActive,
      isBookableOnline: isBookableOnline,
      serviceIds: serviceIds,
    );
    return ServicePackage.fromJson(data['package'] as Map<String, dynamic>);
  }

  Future<void> deletePackage({
    required int locationId,
    required int packageId,
  }) async {
    await _apiClient.deleteServicePackage(
      locationId: locationId,
      packageId: packageId,
    );
  }

  Future<void> reorderPackages({
    required List<Map<String, dynamic>> packages,
  }) async {
    await _apiClient.reorderServicePackages(packages: packages);
  }

  Future<ServicePackageExpansion> expandPackage({
    required int locationId,
    required int packageId,
  }) async {
    final data = await _apiClient.expandServicePackage(
      locationId: locationId,
      packageId: packageId,
    );
    return ServicePackageExpansion.fromJson(data);
  }
}
