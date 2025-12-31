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
  /// Se adminEmail fornito, invia email di benvenuto all'admin.
  Future<Business> createBusiness({
    required String name,
    required String slug,
    String? adminEmail,
    String? email,
    String? phone,
    String timezone = 'Europe/Rome',
    String currency = 'EUR',
    String? adminFirstName,
    String? adminLastName,
  }) async {
    final data = await _apiClient.createAdminBusiness(
      name: name,
      slug: slug,
      adminEmail: adminEmail,
      email: email,
      phone: phone,
      timezone: timezone,
      currency: currency,
      adminFirstName: adminFirstName,
      adminLastName: adminLastName,
    );
    // API ritorna { business: {...}, ... }
    final businessJson = data['business'] as Map<String, dynamic>? ?? data;
    return Business.fromJson(businessJson);
  }

  /// Superadmin: aggiorna un business esistente.
  /// Se adminEmail cambia, trasferisce ownership e invia email al nuovo admin.
  Future<Business> updateBusiness({
    required int businessId,
    String? name,
    String? slug,
    String? email,
    String? phone,
    String? timezone,
    String? currency,
    String? adminEmail,
  }) async {
    final data = await _apiClient.updateAdminBusiness(
      businessId: businessId,
      name: name,
      slug: slug,
      email: email,
      phone: phone,
      timezone: timezone,
      currency: currency,
      adminEmail: adminEmail,
    );
    // API ritorna { business: {...} }
    final businessJson = data['business'] as Map<String, dynamic>? ?? data;
    return Business.fromJson(businessJson);
  }

  /// Superadmin: reinvia email di invito all'admin.
  Future<void> resendAdminInvite(int businessId) async {
    await _apiClient.resendAdminInvite(businessId);
  }
}
