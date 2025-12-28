import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/business.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/utils/subdomain_resolver.dart';

part 'business_provider.g.dart';

/// Provider per il business corrente (caricato da slug)
///
/// Se l'URL è un sottodominio business (es. salonemario.prenota.romeolab.it),
/// carica automaticamente i dati del business.
/// Altrimenti ritorna null (l'app mostrerà una selezione manuale).
@riverpod
class CurrentBusiness extends _$CurrentBusiness {
  bool _hasFetched = false;
  Business? _cachedBusiness;
  Object? _cachedError;

  @override
  Future<Business?> build() async {
    // Protezione da loop: se già caricato, ritorna cache
    if (_hasFetched) {
      if (_cachedError != null) throw _cachedError!;
      return _cachedBusiness;
    }
    _hasFetched = true;

    final slug = SubdomainResolver.getBusinessSlug();

    if (slug == null) {
      // Non siamo su un sottodominio business
      _cachedBusiness = null;
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

  /// Ricarica il business corrente
  Future<void> refresh() async {
    _hasFetched = false;
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
@riverpod
class IsBusinessValid extends _$IsBusinessValid {
  @override
  bool build() {
    final slug = SubdomainResolver.getBusinessSlug();

    if (slug == null) {
      // Nessun slug, nessuna validazione necessaria
      return true;
    }

    final businessAsync = ref.watch(currentBusinessProvider);
    return businessAsync.value != null;
  }
}

/// Provider semplice per lo slug corrente
@riverpod
String? businessSlug(Ref ref) {
  return SubdomainResolver.getBusinessSlug();
}

/// Provider per verificare se siamo su un sottodominio business
@riverpod
bool isBusinessSubdomain(Ref ref) {
  return ref.watch(businessSlugProvider) != null;
}
