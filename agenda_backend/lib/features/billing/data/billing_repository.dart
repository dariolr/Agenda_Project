import '../domain/billing_config_view_model.dart';
import 'billing_api.dart';

class BillingRepository {
  const BillingRepository(this._api);

  final BillingApi _api;

  Future<BillingConfigViewModel> getSubscription(int businessId) async {
    final response = await _api.getSubscription(businessId);
    return BillingConfigViewModel.fromJson(response);
  }

  Future<String> createCheckoutSession(int businessId) {
    return _api.createCheckoutSession(businessId);
  }

  Future<String> createPortalSession(int businessId) {
    return _api.createPortalSession(businessId);
  }

  Future<BillingConfigViewModel> getAdminConfig(int businessId) async {
    final response = await _api.getAdminConfig(businessId);
    return BillingConfigViewModel.fromJson(response);
  }

  Future<void> updateAdminConfig({
    required int businessId,
    required bool billingEnabled,
    required int? amountCents,
    required String currency,
    required String? providerCode,
    String? notes,
  }) {
    return _api.updateAdminConfig(businessId, {
      'billing_enabled': billingEnabled,
      'amount_cents': amountCents,
      'currency': currency,
      'provider_code': providerCode,
      'notes': notes,
    });
  }
}
