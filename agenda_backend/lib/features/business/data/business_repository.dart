import '../../../core/models/business.dart';
import '../../../core/network/api_client.dart';

class BusinessRepository {
  BusinessRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Business>> getAll() async {
    final data = await _apiClient.getBusinesses();
    return data.map((json) => Business.fromJson(json)).toList();
  }

  /// Superadmin: lista tutti i business.
  Future<List<Business>> getAllAdmin({String? search}) async {
    final data = await _apiClient.getAdminBusinesses(search: search);
    return data.map((json) => Business.fromJson(json)).toList();
  }

  /// Superadmin: crea un nuovo business.
  Future<Business> createBusiness({
    required String name,
    required String slug,
    required int ownerUserId,
    String? email,
    String? phone,
    String timezone = 'Europe/Rome',
    String currency = 'EUR',
  }) async {
    final data = await _apiClient.createAdminBusiness(
      name: name,
      slug: slug,
      ownerUserId: ownerUserId,
      email: email,
      phone: phone,
      timezone: timezone,
      currency: currency,
    );
    // API ritorna { business: {...}, ... }
    final businessJson = data['business'] as Map<String, dynamic>? ?? data;
    return Business.fromJson(businessJson);
  }

  /// Superadmin: aggiorna un business esistente.
  Future<Business> updateBusiness({
    required int businessId,
    String? name,
    String? slug,
    String? email,
    String? phone,
    String? timezone,
    String? currency,
  }) async {
    final data = await _apiClient.updateAdminBusiness(
      businessId: businessId,
      name: name,
      slug: slug,
      email: email,
      phone: phone,
      timezone: timezone,
      currency: currency,
    );
    // API ritorna { business: {...} }
    final businessJson = data['business'] as Map<String, dynamic>? ?? data;
    return Business.fromJson(businessJson);
  }
}
