import '../../../core/models/online_payment_account.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

class OnlinePaymentAccountsRepository {
  const OnlinePaymentAccountsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<OnlinePaymentAccount>> list({required int businessId}) async {
    final response = await _apiClient.get(
      ApiConfig.onlinePaymentAccounts(businessId),
    );
    final raw = response['accounts'] as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(OnlinePaymentAccount.fromJson)
        .toList();
  }

  Future<String> createOnboardingLink({
    required int businessId,
    required String providerCode,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.onlinePaymentAccountOnboardingLink(businessId, providerCode),
    );
    return response['onboarding_url']?.toString() ?? '';
  }

  Future<void> sync({
    required int businessId,
    required String providerCode,
  }) async {
    await _apiClient.post(
      ApiConfig.onlinePaymentAccountSync(businessId, providerCode),
    );
  }

  Future<void> setEnabled({
    required int businessId,
    required String providerCode,
    required bool isEnabled,
  }) async {
    await _apiClient.patch(
      ApiConfig.onlinePaymentAccount(businessId, providerCode),
      data: {'is_enabled': isEnabled},
    );
  }

  Future<void> disable({
    required int businessId,
    required String providerCode,
  }) async {
    await _apiClient.delete(
      ApiConfig.onlinePaymentAccount(businessId, providerCode),
    );
  }
}
