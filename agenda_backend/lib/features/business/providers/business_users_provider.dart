import 'package:flutter/foundation.dart';
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
    final initial = const BusinessUsersState(isLoading: true);
    // Defer loading to avoid reading state before initialization.
    Future.microtask(_loadData);
    return initial;
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
      final owner = state.users.firstWhere(
        (u) => u.role == 'owner',
        orElse: () => const BusinessUser(
          id: 0,
          userId: 0,
          businessId: 0,
          role: '',
          email: '',
          firstName: '',
          lastName: '',
          status: 'active',
        ),
      );
      if (owner.userId != 0) {
        debugPrint(
          'BusinessUsersNotifier owner: userId=${owner.userId}, '
          'email=${owner.email}, '
          'firstName=${owner.firstName}, '
          'lastName=${owner.lastName}, '
          'businessId=$businessId',
        );
      }
    } catch (e) {
      debugPrint('BusinessUsersNotifier._loadData error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Ricarica i dati.
  Future<void> refresh() => _loadData();

  /// Aggiorna un operatore (ruolo e/o scope).
  Future<bool> updateUser({
    required int userId,
    required String role,
    String? scopeType,
    List<int>? locationIds,
  }) async {
    try {
      final updated = await _repository.updateUser(
        businessId: businessId,
        userId: userId,
        role: role,
        scopeType: scopeType,
        locationIds: locationIds,
      );
      state = state.copyWith(
        users: state.users
            .map((u) => u.userId == userId ? updated : u)
            .toList(),
      );
      return true;
    } catch (e) {
      debugPrint('BusinessUsersNotifier.updateUser error: $e');
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
      debugPrint('BusinessUsersNotifier.removeUser error: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Crea un nuovo invito.
  Future<BusinessInvitation?> createInvitation({
    required String email,
    required String role,
    String scopeType = 'business',
    List<int>? locationIds,
  }) async {
    try {
      final invitation = await _repository.createInvitation(
        businessId: businessId,
        email: email,
        role: role,
        scopeType: scopeType,
        locationIds: locationIds,
      );
      state = state.copyWith(invitations: [...state.invitations, invitation]);
      return invitation;
    } catch (e) {
      debugPrint('BusinessUsersNotifier.createInvitation error: $e');
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
      debugPrint('BusinessUsersNotifier.revokeInvitation error: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Pulisce l'errore.
  void clearError() {
    state = state.copyWith(error: null);
  }
}
