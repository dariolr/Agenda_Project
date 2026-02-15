import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../agenda/providers/business_providers.dart';
import '../../business/providers/superadmin_selected_business_provider.dart';
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
  final bool canManageBookings;
  final bool canManageClients;
  final bool canManageServices;
  final bool canManageStaff;
  final bool canViewReports;
  final bool canManageClassEvents;
  final bool canReadClassEventParticipants;
  final bool canBookClassEvents;

  const BusinessUserContext({
    required this.userId,
    required this.businessId,
    required this.role,
    required this.scopeType,
    required this.locationIds,
    required this.staffId,
    required this.isSuperadmin,
    required this.canManageBookings,
    required this.canManageClients,
    required this.canManageServices,
    required this.canManageStaff,
    required this.canViewReports,
    required this.canManageClassEvents,
    required this.canReadClassEventParticipants,
    required this.canBookClassEvents,
  });

  /// Indica se l'utente ha accesso a tutte le location del business.
  bool get hasBusinessScope => scopeType == 'business';

  /// Indica se l'utente ha accesso limitato a specifiche location.
  bool get hasLocationScope => scopeType == 'locations';

  /// Indica se l'utente è uno staff (ruolo staff con staffId associato).
  bool get isStaffRole => role == 'staff' && staffId != null;

  factory BusinessUserContext.fromJson(Map<String, dynamic> json) {
    final role = (json['role'] as String? ?? 'staff').trim().toLowerCase();
    final permissions = json['permissions'];
    final defaultCanManageBookings =
        role == 'owner' ||
        role == 'admin' ||
        role == 'manager' ||
        role == 'staff';
    final defaultCanManageClients =
        role == 'owner' || role == 'admin' || role == 'manager';
    final defaultCanManageServices = role == 'owner' || role == 'admin';
    final defaultCanManageStaff = role == 'owner' || role == 'admin';
    final defaultCanViewReports = role == 'owner' || role == 'admin';
    final canManageBookings = permissions is Map
        ? _toBool(
            permissions['can_manage_bookings'],
            fallback: defaultCanManageBookings,
          )
        : defaultCanManageBookings;
    final canManageClients = permissions is Map
        ? _toBool(
            permissions['can_manage_clients'],
            fallback: defaultCanManageClients,
          )
        : defaultCanManageClients;
    final canManageServices = permissions is Map
        ? _toBool(
            permissions['can_manage_services'],
            fallback: defaultCanManageServices,
          )
        : defaultCanManageServices;
    final canManageStaff = permissions is Map
        ? _toBool(
            permissions['can_manage_staff'],
            fallback: defaultCanManageStaff,
          )
        : defaultCanManageStaff;
    final canViewReports = permissions is Map
        ? _toBool(
            permissions['can_view_reports'],
            fallback: defaultCanViewReports,
          )
        : defaultCanViewReports;
    final canManageClassEvents = permissions is Map
        ? _toBool(
            permissions['class_event.manage'] ??
                permissions['can_manage_class_events'],
            fallback: defaultCanManageBookings,
          )
        : defaultCanManageBookings;
    final canReadClassEventParticipants = permissions is Map
        ? _toBool(
            permissions['class_event.participants.read'] ??
                permissions['can_read_class_event_participants'],
            fallback: defaultCanManageBookings,
          )
        : defaultCanManageBookings;
    final canBookClassEvents = permissions is Map
        ? _toBool(
            permissions['class_event.book'] ??
                permissions['can_book_class_events'],
            fallback: defaultCanManageBookings,
          )
        : defaultCanManageBookings;

    return BusinessUserContext(
      userId: json['user_id'] as int,
      businessId: json['business_id'] as int,
      role: role,
      scopeType: json['scope_type'] as String? ?? 'business',
      locationIds:
          (json['location_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      staffId: json['staff_id'] as int?,
      isSuperadmin: json['is_superadmin'] as bool? ?? false,
      canManageBookings: canManageBookings,
      canManageClients: canManageClients,
      canManageServices: canManageServices,
      canManageStaff: canManageStaff,
      canViewReports: canViewReports,
      canManageClassEvents: canManageClassEvents,
      canReadClassEventParticipants: canReadClassEventParticipants,
      canBookClassEvents: canBookClassEvents,
    );
  }

  static bool _toBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == '1' || normalized == 'true') return true;
      if (normalized == '0' || normalized == 'false') return false;
    }
    return fallback;
  }
}

bool _isContextForCurrentBusiness(
  BusinessUserContext? context,
  int currentBusinessId,
) {
  if (context == null) return false;
  if (context.isSuperadmin) return true;
  return currentBusinessId > 0 && context.businessId == currentBusinessId;
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
        canManageBookings: true,
        canManageClients: true,
        canManageServices: true,
        canManageStaff: true,
        canViewReports: true,
        canManageClassEvents: true,
        canReadClassEventParticipants: true,
        canBookClassEvents: true,
      );
    }

    // Ottieni il business ID corrente
    final isSuperadmin = user.isSuperadmin;
    final businessId = isSuperadmin
        ? ref.watch(superadminSelectedBusinessProvider)
        : ref.watch(currentBusinessIdProvider);
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
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  final context = contextAsync.when(
    data: (data) => data,
    loading: () => null,
    error: (_, __) => null,
  );

  if (!_isContextForCurrentBusiness(context, currentBusinessId)) {
    return false;
  }

  // Scope business = accesso a tutte le location
  if (context!.hasBusinessScope) return true;

  // Scope locations = verifica se locationId è nella lista
  return context.locationIds.contains(locationId);
});

/// Provider per ottenere la lista di location IDs accessibili all'utente corrente.
/// Ritorna null se ha accesso a tutte le location (scopeType='business').
final allowedLocationIdsProvider = Provider<List<int>?>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  final context = contextAsync.when(
    data: (data) => data,
    loading: () => null,
    error: (_, __) => null,
  );

  if (!_isContextForCurrentBusiness(context, currentBusinessId)) {
    return null;
  }

  // Scope business = null significa accesso a tutte
  if (context!.hasBusinessScope) return null;

  // Scope locations = ritorna la lista specifica
  return context.locationIds;
});

// ============================================================================
// PROVIDER PERMESSI RUOLO
// ============================================================================

/// Ruolo dell'utente corrente nel business.
/// Ritorna 'staff' come default se non ancora caricato.
final currentUserRoleProvider = Provider<String>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) => _isContextForCurrentBusiness(data, currentBusinessId)
        ? data!.role
        : 'staff',
    loading: () => 'staff',
    error: (_, __) => 'staff',
  );
});

/// Verifica se l'utente corrente è admin o owner.
/// Admin può gestire altri operatori.
final canManageOperatorsProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.role == 'admin' || data.role == 'owner';
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Verifica se l'utente corrente può vedere tutti gli appuntamenti.
/// Admin e Manager vedono tutto, Staff vede solo i propri.
final canViewAllAppointmentsProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
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
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.role == 'admin' || data.role == 'owner';
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Verifica se l'utente corrente può gestire agenda/prenotazioni.
final currentUserCanManageBookingsProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.canManageBookings;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Verifica se l'utente corrente può gestire clienti.
final currentUserCanManageClientsProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.canManageClients;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Verifica se l'utente corrente può gestire servizi.
final currentUserCanManageServicesProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.canManageServices;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Verifica se l'utente corrente può visualizzare servizi.
/// Include chi può gestire e il ruolo viewer.
final currentUserCanViewServicesProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.canManageServices || data.role == 'viewer';
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Verifica se l'utente corrente può gestire staff.
final currentUserCanManageStaffProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.canManageStaff;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Verifica se l'utente corrente può visualizzare staff.
/// Include chi può gestire e il ruolo viewer.
final currentUserCanViewStaffProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.canManageStaff ||
          data.role == 'manager' ||
          data.role == 'viewer' ||
          data.role == 'staff';
    },
    loading: () => true,
    error: (_, __) => false,
  );
});

/// Provider per ottenere lo staff_id dell'utente corrente (se è uno staff).
/// Ritorna null se l'utente non è associato a uno staff.
final currentUserStaffIdProvider = Provider<int?>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) => _isContextForCurrentBusiness(data, currentBusinessId)
        ? data!.staffId
        : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Verifica se l'utente corrente può visualizzare report in base ai permessi.
final currentUserCanViewReportsProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.canViewReports;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

final currentUserCanManageClassEventsProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.canManageClassEvents;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

final currentUserCanReadClassParticipantsProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.canReadClassEventParticipants;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

final currentUserCanBookClassEventsProvider = Provider<bool>((ref) {
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final contextAsync = ref.watch(currentBusinessUserContextProvider);
  return contextAsync.when(
    data: (data) {
      if (!_isContextForCurrentBusiness(data, currentBusinessId)) return false;
      if (data!.isSuperadmin) return true;
      return data.canBookClassEvents;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

final currentUserCanAccessClassEventsProvider = Provider<bool>((ref) {
  final canManage = ref.watch(currentUserCanManageClassEventsProvider);
  final canReadParticipants = ref.watch(
    currentUserCanReadClassParticipantsProvider,
  );
  final canBook = ref.watch(currentUserCanBookClassEventsProvider);
  return canManage || canReadParticipants || canBook;
});
