import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/online_payment_account.dart';
import '../../../core/network/network_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../data/online_payment_accounts_repository.dart';

final onlinePaymentAccountsRepositoryProvider =
    Provider<OnlinePaymentAccountsRepository>((ref) {
      return OnlinePaymentAccountsRepository(
        apiClient: ref.watch(apiClientProvider),
      );
    });

final onlinePaymentAccountsProvider =
    FutureProvider<List<OnlinePaymentAccount>>((ref) async {
      final businessId = ref.watch(currentBusinessIdProvider);
      if (businessId <= 0) return const [];

      final repository = ref.watch(onlinePaymentAccountsRepositoryProvider);
      return repository.list(businessId: businessId);
    });
