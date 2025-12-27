import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/network_providers.dart';
import '../data/bookings_repository.dart';

part 'bookings_repository_provider.g.dart';

@Riverpod(keepAlive: true)
BookingsRepository bookingsRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingsRepository(apiClient: apiClient);
}
