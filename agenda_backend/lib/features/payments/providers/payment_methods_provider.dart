import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/business_payment_method.dart';
import '../../../core/network/network_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../data/payment_methods_repository.dart';

final paymentMethodsRepositoryProvider = Provider<PaymentMethodsRepository>((
  ref,
) {
  return PaymentMethodsRepository(apiClient: ref.watch(apiClientProvider));
});

final paymentMethodsProvider = FutureProvider<List<BusinessPaymentMethod>>((
  ref,
) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) return const [];

  final repository = ref.watch(paymentMethodsRepositoryProvider);
  return repository.list(businessId: businessId);
});

final paymentMethodsWithInactiveProvider =
    FutureProvider<List<BusinessPaymentMethod>>((ref) async {
      final businessId = ref.watch(currentBusinessIdProvider);
      if (businessId <= 0) return const [];

      final repository = ref.watch(paymentMethodsRepositoryProvider);
      return repository.list(businessId: businessId, includeInactive: true);
    });
