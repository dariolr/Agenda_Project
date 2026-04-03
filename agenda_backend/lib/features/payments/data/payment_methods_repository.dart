import '../../../core/models/business_payment_method.dart';
import '../../../core/network/api_client.dart';

class PaymentMethodsRepository {
  const PaymentMethodsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<BusinessPaymentMethod>> list({
    required int businessId,
    bool includeInactive = false,
  }) async {
    final response = await _apiClient.getBusinessPaymentMethods(
      businessId: businessId,
      includeInactive: includeInactive,
    );

    final methodsRaw = response['methods'] as List<dynamic>? ?? const [];
    return methodsRaw
        .whereType<Map<String, dynamic>>()
        .map(BusinessPaymentMethod.fromJson)
        .toList();
  }

  Future<BusinessPaymentMethod> create({
    required int businessId,
    required String name,
    String? code,
    int? sortOrder,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
      if (sortOrder != null) 'sort_order': sortOrder,
    };

    final response = await _apiClient.createBusinessPaymentMethod(
      businessId: businessId,
      payload: payload,
    );

    return BusinessPaymentMethod.fromJson(
      response['method'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<BusinessPaymentMethod> update({
    required int businessId,
    required int methodId,
    required String name,
    int? sortOrder,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
    };

    final response = await _apiClient.updateBusinessPaymentMethod(
      businessId: businessId,
      methodId: methodId,
      payload: payload,
    );

    return BusinessPaymentMethod.fromJson(
      response['method'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> delete({required int businessId, required int methodId}) async {
    await _apiClient.deleteBusinessPaymentMethod(
      businessId: businessId,
      methodId: methodId,
    );
  }
}
