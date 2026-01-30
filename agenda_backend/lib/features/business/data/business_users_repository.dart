import '../../../core/models/business_invitation.dart';
import '../../../core/models/business_user.dart';
import '../../../core/network/api_client.dart';

/// Repository per gestire operatori e inviti di un business.
class BusinessUsersRepository {
  BusinessUsersRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ========== OPERATORI ==========

  /// Recupera tutti gli operatori di un business.
  Future<List<BusinessUser>> getUsers(int businessId) async {
    final data = await _apiClient.getBusinessUsers(businessId);
    return data.map((json) => BusinessUser.fromJson(json)).toList();
  }

  /// Aggiorna il ruolo e lo scope di un operatore.
  Future<BusinessUser> updateUser({
    required int businessId,
    required int userId,
    required String role,
    String? scopeType,
    List<int>? locationIds,
  }) async {
    final data = await _apiClient.updateBusinessUser(
      businessId: businessId,
      userId: userId,
      role: role,
      scopeType: scopeType,
      locationIds: locationIds,
    );
    return BusinessUser.fromJson(data);
  }

  /// Rimuove un operatore dal business.
  Future<void> removeUser({
    required int businessId,
    required int userId,
  }) async {
    await _apiClient.removeBusinessUser(businessId: businessId, userId: userId);
  }

  // ========== INVITI ==========

  /// Recupera tutti gli inviti pendenti di un business.
  Future<List<BusinessInvitation>> getInvitations(int businessId) async {
    final data = await _apiClient.getBusinessInvitations(businessId);
    return data.map((json) => BusinessInvitation.fromJson(json)).toList();
  }

  /// Crea un nuovo invito.
  Future<BusinessInvitation> createInvitation({
    required int businessId,
    required String email,
    required String role,
    String scopeType = 'business',
    List<int>? locationIds,
  }) async {
    final data = await _apiClient.createBusinessInvitation(
      businessId: businessId,
      email: email,
      role: role,
      scopeType: scopeType,
      locationIds: locationIds,
    );
    return BusinessInvitation.fromJson(data);
  }

  /// Revoca un invito pendente.
  Future<void> revokeInvitation({
    required int businessId,
    required int invitationId,
  }) async {
    await _apiClient.revokeBusinessInvitation(
      businessId: businessId,
      invitationId: invitationId,
    );
  }

  /// Recupera i dettagli di un invito tramite token.
  Future<Map<String, dynamic>> getInvitationByToken(String token) async {
    return _apiClient.getInvitationByToken(token);
  }

  /// Accetta un invito.
  Future<void> acceptInvitation(String token) async {
    await _apiClient.acceptInvitation(token);
  }
}
