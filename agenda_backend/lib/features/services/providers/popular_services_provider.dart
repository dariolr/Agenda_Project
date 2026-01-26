import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/popular_service.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/providers/auth_provider.dart';

/// Provider famiglia per i servizi popolari (top 5 più prenotati) per uno staff.
/// Ritorna [PopularServicesResult.empty] se:
/// - L'utente non è autenticato
/// - La location dello staff ha meno di 25 servizi
/// - Non ci sono dati disponibili
final popularServicesProvider = FutureProvider.autoDispose.family<PopularServicesResult, int>(
  (ref, staffId) async {
    // Verifica autenticazione
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return PopularServicesResult.empty;
    }

    if (staffId <= 0) {
      return PopularServicesResult.empty;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.getPopularServices(staffId);

      return PopularServicesResult.fromJson(data);
    } catch (e) {
      // In caso di errore, ritorna risultato vuoto (non mostra la sezione)
      return PopularServicesResult.empty;
    }
  },
);
