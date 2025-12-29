import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/route_slug_provider.dart';
import '../../../core/models/business.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';

part 'business_provider.g.dart';

/// Provider per il business corrente (caricato da slug nel path URL)
///
/// L'URL segue il pattern: /{slug}/booking, /{slug}/login, ecc.
/// Il router estrae lo slug e lo aggiorna in routeSlugProvider.
/// Questo provider reagisce ai cambi di slug e carica il business.
@riverpod
class CurrentBusiness extends _$CurrentBusiness {
  String? _lastSlug;
  Business? _cachedBusiness;
  Object? _cachedError;

  @override
  Future<Business?> build() async {
    // Legge lo slug dal path URL (gestito dal router)
    final slug = ref.watch(routeSlugProvider);

    // Se lo slug non è cambiato, ritorna la cache
    if (_lastSlug == slug && _cachedBusiness != null) {
      return _cachedBusiness;
    }

    // Se c'era un errore per questo slug, rilancia
    if (_lastSlug == slug && _cachedError != null) {
      throw _cachedError!;
    }

    _lastSlug = slug;
    _cachedBusiness = null;
    _cachedError = null;

    if (slug == null) {
      // Nessun slug nel path → landing page
      return null;
    }

    final apiClient = ref.watch(apiClientProvider);

    try {
      final data = await apiClient.getBusinessBySlug(slug);
      _cachedBusiness = Business.fromJson(data);
      return _cachedBusiness;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Business non trovato - slug non valido
        // Non è un errore, ritorna null e l'app mostrerà "business non trovato"
        _cachedBusiness = null;
        return null;
      }
      _cachedError = e;
      rethrow;
    } catch (e) {
      _cachedError = e;
      rethrow;
    }
  }

  /// Ricarica il business corrente (forza refresh)
  Future<void> refresh() async {
    _lastSlug = null;
    _cachedBusiness = null;
    _cachedError = null;
    ref.invalidateSelf();
  }
}

/// Provider per l'ID del business corrente (sincrono, utility)
@riverpod
class CurrentBusinessId extends _$CurrentBusinessId {
  @override
  int? build() {
    final businessAsync = ref.watch(currentBusinessProvider);
    return businessAsync.value?.id;
  }
}

/// Provider per verificare se il business slug è valido
/// (slug presente e business trovato nel database)
@riverpod
class IsBusinessValid extends _$IsBusinessValid {
  @override
  bool build() {
    final slug = ref.watch(routeSlugProvider);

    if (slug == null) {
      // Nessun slug nel path → landing page, non è un errore
      return true;
    }

    // Se c'è uno slug, verifica che il business esista
    final businessAsync = ref.watch(currentBusinessProvider);
    return businessAsync.value != null;
  }
}

/// Provider semplice per lo slug corrente (letto dal path URL)
@riverpod
String? businessSlug(Ref ref) {
  return ref.watch(routeSlugProvider);
}

/// Provider per verificare se siamo su un sottodominio business
@riverpod
bool isBusinessSubdomain(Ref ref) {
  return ref.watch(businessSlugProvider) != null;
}
