import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/network_providers.dart';
import '../data/business_repository.dart';

part 'business_providers.g.dart';

@riverpod
BusinessRepository businessRepository(Ref ref) {
  return BusinessRepository(apiClient: ref.watch(apiClientProvider));
}
