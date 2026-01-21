import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service_package.dart';
import '../../agenda/providers/location_providers.dart';
import '../../auth/providers/auth_provider.dart';
import 'service_packages_repository_provider.dart';

class ServicePackagesNotifier extends AsyncNotifier<List<ServicePackage>> {
  @override
  Future<List<ServicePackage>> build() async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return [];
    }

    final location = ref.watch(currentLocationProvider);
    if (location.id <= 0) {
      return [];
    }

    final repository = ref.watch(servicePackagesRepositoryProvider);
    return repository.getPackages(locationId: location.id);
  }

  Future<void> refresh() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      return;
    }

    final location = ref.read(currentLocationProvider);
    if (location.id <= 0) {
      return;
    }

    state = const AsyncLoading();
    try {
      final repository = ref.read(servicePackagesRepositoryProvider);
      final packages = await repository.getPackages(locationId: location.id);
      state = AsyncData(packages);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<ServicePackage?> createPackage({
    required String name,
    required int categoryId,
    required List<int> serviceIds,
    String? description,
    double? overridePrice,
    int? overrideDurationMinutes,
    bool isActive = true,
  }) async {
    final location = ref.read(currentLocationProvider);
    if (location.id <= 0) return null;

    try {
      final repository = ref.read(servicePackagesRepositoryProvider);
      var created = await repository.createPackage(
        locationId: location.id,
        name: name,
        categoryId: categoryId,
        serviceIds: serviceIds,
        description: description,
        overridePrice: overridePrice,
        overrideDurationMinutes: overrideDurationMinutes,
        isActive: isActive,
      );
      if (created.categoryId == 0 && categoryId > 0) {
        created = created.copyWith(categoryId: categoryId);
      }

      final current = state.value ?? [];
      state = AsyncData([...current, created]);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<ServicePackage?> updatePackage({
    required int packageId,
    String? name,
    int? categoryId,
    String? description,
    double? overridePrice,
    int? overrideDurationMinutes,
    bool setOverridePriceNull = false,
    bool setOverrideDurationNull = false,
    bool? isActive,
    List<int>? serviceIds,
  }) async {
    final location = ref.read(currentLocationProvider);
    if (location.id <= 0) return null;

    try {
      final repository = ref.read(servicePackagesRepositoryProvider);
      var updated = await repository.updatePackage(
        locationId: location.id,
        packageId: packageId,
        name: name,
        categoryId: categoryId,
        description: description,
        overridePrice: overridePrice,
        overrideDurationMinutes: overrideDurationMinutes,
        setOverridePriceNull: setOverridePriceNull,
        setOverrideDurationNull: setOverrideDurationNull,
        isActive: isActive,
        serviceIds: serviceIds,
      );
      if (updated.categoryId == 0 && categoryId != null && categoryId > 0) {
        updated = updated.copyWith(categoryId: categoryId);
      }

      final current = state.value ?? [];
      final index = current.indexWhere((p) => p.id == packageId);
      if (index >= 0) {
        final updatedList = [...current];
        updatedList[index] = updated;
        state = AsyncData(updatedList);
      } else {
        state = AsyncData([...current, updated]);
      }

      return updated;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> deletePackage(int packageId) async {
    final location = ref.read(currentLocationProvider);
    if (location.id <= 0) return;

    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != packageId).toList());

    try {
      final repository = ref.read(servicePackagesRepositoryProvider);
      await repository.deletePackage(
        locationId: location.id,
        packageId: packageId,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void setPackages(List<ServicePackage> packages) {
    state = AsyncData(packages);
  }
}

final servicePackagesProvider =
    AsyncNotifierProvider<ServicePackagesNotifier, List<ServicePackage>>(
      ServicePackagesNotifier.new,
    );
