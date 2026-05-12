import '../../../core/network/api_client.dart';

class BillingApi {
  const BillingApi(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getSubscription(
    int businessId, {
    bool checkoutCancelled = false,
  }) {
    return _apiClient.getBillingSubscription(
      businessId: businessId,
      checkoutCancelled: checkoutCancelled,
    );
  }

  Future<String> createCheckoutSession(int businessId) {
    return _apiClient.createBillingCheckoutSession(businessId: businessId);
  }

  Future<String> createPortalSession(int businessId) {
    return _apiClient.createBillingPortalSession(businessId: businessId);
  }

  Future<Map<String, dynamic>> getAdminConfig(int businessId) {
    return _apiClient.getAdminBusinessBillingConfig(businessId);
  }

  Future<void> updateAdminConfig(int businessId, Map<String, dynamic> payload) {
    return _apiClient.updateAdminBusinessBillingConfig(businessId, payload);
  }
}
