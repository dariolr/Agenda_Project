import '../../../core/models/service_package.dart';
import '../../../core/network/api_client.dart';
import 'service_packages_api.dart';

class ServicePackagesRepository {
  ServicePackagesRepository({required ApiClient apiClient})
    : _api = ServicePackagesApi(apiClient: apiClient);

  final ServicePackagesApi _api;

  Future<List<ServicePackage>> getPackages({required int locationId}) =>
      _api.fetchPackages(locationId);

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
  }) => _api.createPackage(
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
  }) => _api.updatePackage(
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

  Future<void> deletePackage({
    required int locationId,
    required int packageId,
  }) => _api.deletePackage(locationId: locationId, packageId: packageId);

  Future<void> reorderPackages({
    required List<Map<String, dynamic>> packages,
  }) => _api.reorderPackages(packages: packages);

  Future<ServicePackageExpansion> expandPackage({
    required int locationId,
    required int packageId,
  }) => _api.expandPackage(locationId: locationId, packageId: packageId);
}
