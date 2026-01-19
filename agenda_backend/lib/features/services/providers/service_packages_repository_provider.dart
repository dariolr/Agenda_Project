import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/service_packages_repository.dart';

final servicePackagesRepositoryProvider =
    Provider<ServicePackagesRepository>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return ServicePackagesRepository(apiClient: apiClient);
    });
