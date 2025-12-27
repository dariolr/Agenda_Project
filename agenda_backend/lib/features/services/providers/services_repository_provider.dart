import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/network_providers.dart';
import '../data/services_repository.dart';

part 'services_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ServicesRepository servicesRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ServicesRepository(apiClient: apiClient);
}
