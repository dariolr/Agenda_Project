import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../data/billing_api.dart';
import '../data/billing_repository.dart';
import '../domain/billing_config_view_model.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(BillingApi(ref.watch(apiClientProvider)));
});

final billingSubscriptionProvider = FutureProvider<BillingConfigViewModel>((
  ref,
) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId <= 0) {
    return BillingConfigViewModel.fromJson(const {});
  }

  return ref.watch(billingRepositoryProvider).getSubscription(businessId);
});

final adminBusinessBillingConfigProvider =
    FutureProvider.family<BillingConfigViewModel, int>((ref, businessId) async {
      return ref.watch(billingRepositoryProvider).getAdminConfig(businessId);
    });
