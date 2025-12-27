import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/network_providers.dart';
import '../data/locations_repository.dart';

part 'locations_providers.g.dart';

@riverpod
LocationsRepository locationsRepository(Ref ref) {
  return LocationsRepository(apiClient: ref.watch(apiClientProvider));
}
