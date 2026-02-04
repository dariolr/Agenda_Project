#!/usr/bin/env python3
"""
Script per aggiungere il provider authenticatedBusinessIdProvider
che espone l'ID del business per cui l'utente è autenticato.
"""

import os

# 1. Aggiungo il provider al file network_providers.dart
network_file = '/Users/dariolarosa/Documents/Romeo_lab/Agenda_Project/agenda_frontend/lib/core/network/network_providers.dart'

with open(network_file, 'r') as f:
    content = f.read()

# Controllo se il provider esiste già
if 'authenticatedBusinessIdProvider' not in content:
    # Aggiungo il provider alla fine del file
    new_provider = '''

/// Provider per l'ID del business per cui l'utente è autenticato.
/// Legge il businessId salvato in localStorage dopo il login.
/// Ritorna null se l'utente non è autenticato.
final authenticatedBusinessIdProvider = FutureProvider<int?>((ref) async {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return tokenStorage.getBusinessId();
});
'''
    content += new_provider
    
    with open(network_file, 'w') as f:
        f.write(content)
    print(f"Aggiunto authenticatedBusinessIdProvider a {network_file}")
else:
    print("authenticatedBusinessIdProvider già presente")

# 2. Aggiungo il provider isAuthenticatedForCurrentBusinessProvider
# al file business_provider.dart
business_file = '/Users/dariolarosa/Documents/Romeo_lab/Agenda_Project/agenda_frontend/lib/features/booking/providers/business_provider.dart'

with open(business_file, 'r') as f:
    content = f.read()

# Controllo se il provider esiste già
if 'isAuthenticatedForCurrentBusinessProvider' not in content:
    # Aggiungo l'import
    if "import '../../../core/network/network_providers.dart';" in content:
        pass  # import già presente
    
    # Aggiungo il provider alla fine del file
    new_provider = '''

/// Provider che verifica se l'utente è autenticato per il business corrente.
/// 
/// Restituisce:
/// - `null` se l'utente non è autenticato
/// - `true` se l'utente è autenticato per il business corrente
/// - `false` se l'utente è autenticato per un business diverso
/// 
/// Utile per mostrare un messaggio quando l'utente naviga su un business
/// diverso da quello per cui si è autenticato.
@riverpod
class IsAuthenticatedForCurrentBusiness extends _$IsAuthenticatedForCurrentBusiness {
  @override
  Future<bool?> build() async {
    final currentBusinessAsync = ref.watch(currentBusinessProvider);
    final authenticatedBusinessIdAsync = ref.watch(authenticatedBusinessIdProvider);
    
    // Attendo entrambi i valori
    final currentBusiness = currentBusinessAsync.value;
    final authenticatedBusinessId = authenticatedBusinessIdAsync.value;
    
    // Se l'utente non è autenticato, ritorna null
    if (authenticatedBusinessId == null) {
      return null;
    }
    
    // Se il business corrente non è caricato, attendo
    if (currentBusiness == null) {
      return null;
    }
    
    // Verifica se il business corrente corrisponde a quello autenticato
    return currentBusiness.id == authenticatedBusinessId;
  }
}
'''
    content += new_provider
    
    with open(business_file, 'w') as f:
        f.write(content)
    print(f"Aggiunto isAuthenticatedForCurrentBusinessProvider a {business_file}")
else:
    print("isAuthenticatedForCurrentBusinessProvider già presente")

print("\nFatto! Ora esegui: cd agenda_frontend && dart run build_runner build --delete-conflicting-outputs")
