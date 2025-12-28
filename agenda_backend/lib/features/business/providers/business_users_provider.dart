import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/business_invitation.dart';
import '../../../core/models/business_user.dart';
import '../../../core/network/network_providers.dart';
import '../data/business_users_repository.dart';

part 'business_users_provider.g.dart';

/// Provider per il repository degli operatori.
@riverpod
BusinessUsersRepository businessUsersRepository(Ref ref) {
  return BusinessUsersRepository(apiClient: ref.watch(apiClientProvider));
}

/// Stato per la gestione degli operatori di un business.
class BusinessUsersState {
  final List<BusinessUser> users;
  final List<BusinessInvitation> invitations;
  final bool isLoading;
  final String? error;

  const BusinessUsersState({
    this.users = const [],
    this.invitations = const [],
    this.isLoading = false,
    this.error,
  });

  BusinessUsersState copyWith({
    List<BusinessUser>? users,
    List<BusinessInvitation>? invitations,
    bool? isLoading,
    String? error,
  }) => BusinessUsersState(
    users: users ?? this.users,
    invitations: invitations ?? this.invitations,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  /// Utenti attivi (escluso l'utente corrente).
  List<BusinessUser> get activeUsers =>
      users.where((u) => u.status == 'active').toList();

  /// Numero totale di membri (utenti attivi + inviti pendenti).
  int get totalMembers => activeUsers.length + invitations.length;
}

/// Notifier per gestire gli operatori di un business.
@riverpod
class BusinessUsersNotifier extends _$BusinessUsersNotifier {
  @override
  BusinessUsersState build(int businessId) {
    _loadData();
    return const BusinessUsersState(isLoading: true);
  }

  BusinessUsersRepository get _repository =>
      ref.read(businessUsersRepositoryProvider);

  /// Carica operatori e inviti.
  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repository.getUsers(businessId),
        _repository.getInvitations(businessId),
      ]);
      state = state.copyWith(
        users: results[0] as List<BusinessUser>,
        invitations: results[1] as List<BusinessInvitation>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Ricarica i dati.
  Future<void> refresh() => _loadData();

  /// Aggiorna il ruolo di un operatore.
  Future<bool> updateUserRole(int userId, String newRole) async {
    try {
      final updated = await _repository.updateUserRole(
        businessId: businessId,
        userId: userId,
        role: newRole,
      );
      state = state.copyWith(
        users: state.users
            .map((u) => u.userId == userId ? updated : u)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Rimuove un operatore.
  Future<bool> removeUser(int userId) async {
    try {
      await _repository.removeUser(businessId: businessId, userId: userId);
      state = state.copyWith(
        users: state.users.where((u) => u.userId != userId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Crea un nuovo invito.
  Future<BusinessInvitation?> createInvitation({
    required String email,
    required String role,
  }) async {
    try {
      final invitation = await _repository.createInvitation(
        businessId: businessId,
        email: email,
        role: role,
      );
      state = state.copyWith(invitations: [...state.invitations, invitation]);
      return invitation;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Revoca un invito.
  Future<bool> revokeInvitation(int invitationId) async {
    try {
      await _repository.revokeInvitation(
        businessId: businessId,
        invitationId: invitationId,
      );
      state = state.copyWith(
        invitations: state.invitations
            .where((i) => i.id != invitationId)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Pulisce l'errore.
  void clearError() {
    state = state.copyWith(error: null);
  }
}
