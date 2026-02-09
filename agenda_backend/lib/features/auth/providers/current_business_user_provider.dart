import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../agenda/providers/location_providers.dart';
import 'auth_provider.dart';

/// Dati del contesto business dell'utente corrente.
/// Contiene scope_type e location_ids per il filtro permessi.
class BusinessUserContext {
  final int userId;
  final int businessId;
  final String role;
  final String scopeType;
  final List<int> locationIds;
  final int? staffId;
  final bool isSuperadmin;

  const BusinessUserContext({
    required this.userId,
    required this.businessId,
    required this.role,
    required this.scopeType,
    required this.locationIds,
    required this.staffId,
    required this.isSuperadmin,
  });

  /// Indica se l'utente ha accesso a tutte le location del business.
  bool get hasBusinessScope => scopeType == 'business';

  /// Indica se l'utente ha accesso limitato a specifiche location.
  bool get hasLocationScope => scopeType == 'locations';

  /// Indica se l'utente è uno staff (ruolo staff con staffId associato).
  bool get isStaffRole => role == 'staff' && staffId != null;

  factory BusinessUserContext.fromJson(Map<String, dynamic> json) {
    return BusinessUserContext(
      userId: json['user_id'] as int,
      businessId: json['business_id'] as int,
      role: json['role'] as String,
      scopeType: json['scope_type'] as String? ?? 'business',
      locationIds:
          (json['location_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      staffId: json['staff_id'] as int?,
      isSuperadmin: json['is_superadmin'] as bool? ?? false,
    );
  }
}

/// Provider asincrono per ottenere il contesto dell'utente corrente nel business.
/// Carica da API: GET /v1/me/business/{business_id}
final currentBusinessUserContextProvider = FutureProvider<BusinessUserContext?>(
  (ref) async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) return null;

    final user = authState.user;
    if (user == null) return null;

    // Superadmin: ritorna contesto con accesso completo senza chiamata API
    if (user.isSuperadmin) {
      return BusinessUserContext(
        userId: user.id,
        businessId: 0,
        role: 'superadmin',
        scopeType: 'business',
        locationIds: const [],
        staffId: null,
        isSuperadmin: true,
      );
    }

    // Ottieni il business ID corrente
    final businessId = ref.watch(businessIdForLocationsProvider);
    if (businessId == null || businessId <= 0) return null;

    try {
      final apiClient = ref.watch(apiClientProvider);
      final data = await apiClient.getMyBusinessContext(businessId);
      return BusinessUserContext.fromJson(data);
    } catch (e) {
      debugPrint('Error loading business user context: $e');
      return null;
    }
  },
);

/// Provider per verificare se l'utente corrente ha accesso a una specifica location.
final hasLocationAccessProvider = Provider.family<bool, int>((ref, locationId) {
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  final context = contextAsync.when(
    data: (data) => data,
    loading: () => null,
    error: (_, __) => null,
  );

  // Se non caricato o errore, nega accesso per sicurezza
  if (context == null) return false;

  // Scope business = accesso a tutte le location
  if (context.hasBusinessScope) return true;

  // Scope locations = verifica se locationId è nella lista
  return context.locationIds.contains(locationId);
});

/// Provider per ottenere la lista di location IDs accessibili all'utente corrente.
/// Ritorna null se ha accesso a tutte le location (scopeType='business').
final allowedLocationIdsProvider = Provider<List<int>?>((ref) {
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  final context = contextAsync.when(
    data: (data) => data,
    loading: () => null,
    error: (_, __) => null,
  );

  // Se non ancora caricato, ritorna null (nessun filtro)
  if (context == null) return null;

  // Scope business = null significa accesso a tutte
  if (context.hasBusinessScope) return null;

  // Scope locations = ritorna la lista specifica
  return context.locationIds;
});

// ============================================================================
// PROVIDER PERMESSI RUOLO
// ============================================================================

/// Ruolo dell'utente corrente nel business.
/// Ritorna 'staff' come default se non ancora caricato.
final currentUserRoleProvider = Provider<String>((ref) {
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) => data?.role ?? 'staff',
    loading: () => 'staff',
    error: (_, __) => 'staff',
  );
});

/// Verifica se l'utente corrente è admin o owner.
/// Admin può gestire altri operatori.
final canManageOperatorsProvider = Provider<bool>((ref) {
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (data == null) return false;
      if (data.isSuperadmin) return true;
      return data.role == 'admin' || data.role == 'owner';
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Verifica se l'utente corrente può vedere tutti gli appuntamenti.
/// Admin e Manager vedono tutto, Staff vede solo i propri.
final canViewAllAppointmentsProvider = Provider<bool>((ref) {
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (data == null) return false;
      if (data.isSuperadmin) return true;
      return data.role == 'admin' ||
          data.role == 'owner' ||
          data.role == 'manager' ||
          data.role == 'viewer';
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Verifica se l'utente corrente può modificare impostazioni business.
/// Solo admin e owner.
final canManageBusinessSettingsProvider = Provider<bool>((ref) {
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (data == null) return false;
      if (data.isSuperadmin) return true;
      return data.role == 'admin' || data.role == 'owner';
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider per ottenere lo staff_id dell'utente corrente (se è uno staff).
/// Ritorna null se l'utente non è associato a uno staff.
final currentUserStaffIdProvider = Provider<int?>((ref) {
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) => data?.staffId,
    loading: () => null,
    error: (_, __) => null,
  );
});
