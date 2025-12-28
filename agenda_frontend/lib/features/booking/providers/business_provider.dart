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
  @override
  Future<Business?> build() async {
    final slug = SubdomainResolver.getBusinessSlug();

    if (slug == null) {
      // Non siamo su un sottodominio business
      return null;
    }

    final apiClient = ref.watch(apiClientProvider);

    try {
      final data = await apiClient.getBusinessBySlug(slug);
      return Business.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Business non trovato - slug non valido
        return null;
      }
      rethrow;
    }
  }

  /// Ricarica il business corrente
  Future<void> refresh() async {
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
