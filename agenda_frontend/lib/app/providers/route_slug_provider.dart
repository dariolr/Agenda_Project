import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider per lo slug del business estratto dalla route corrente.
///
/// Questo provider viene utilizzato per passare lo slug dal router
/// ai provider che ne hanno bisogno (es. currentBusinessProvider).
///
/// A differenza di SubdomainResolver.getBusinessSlug() che legge Uri.base
/// (statico al caricamento pagina), questo provider viene aggiornato
/// dinamicamente quando la route cambia.
final routeSlugProvider = StateProvider<String?>((ref) => null);

/// Provider per verificare se siamo in una route con business slug
final hasRouteSlugProvider = Provider<bool>((ref) {
  return ref.watch(routeSlugProvider) != null;
});
