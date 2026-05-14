import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/online_payment_account.dart';
import '../../../core/network/network_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/online_payment_accounts_repository.dart';

final onlinePaymentAccountsRepositoryProvider =
    Provider<OnlinePaymentAccountsRepository>((ref) {
      return OnlinePaymentAccountsRepository(
        apiClient: ref.watch(apiClientProvider),
      );
    });

final onlinePaymentAccountsProvider =
    FutureProvider<List<OnlinePaymentAccount>>((ref) async {
      // Guard against the window where businessId is restored from cache
      // but the auth token is not yet applied to HTTP requests.
      if (!ref.watch(authProvider).isAuthenticated) return const [];

      final businessId = ref.watch(currentBusinessIdProvider);
      if (businessId <= 0) return const [];

      final repository = ref.watch(onlinePaymentAccountsRepositoryProvider);
      return repository.list(businessId: businessId);
    });
