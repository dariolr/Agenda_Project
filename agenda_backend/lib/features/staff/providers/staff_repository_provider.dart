import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/network_providers.dart';
import '../data/staff_repository.dart';

part 'staff_repository_provider.g.dart';

@Riverpod(keepAlive: true)
StaffRepository staffRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StaffRepository(apiClient: apiClient);
}
