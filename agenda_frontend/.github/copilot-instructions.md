#  AI Agent Instructions

Piattaforma in Flutter (web primary, mobile/desktop).
L'agente deve produrre **file completi** e **non rompere le funzionalità esistenti**.
L'agente deve centralizzare il codice a favore del riutilizzo. Deve sempre verificare se esiste gia un implementazione utile prima di creare nuovo codice. Eventualmente deve estendere il codice esistente.

---

## 🛠️ Comandi essenziali

```bash
# Localizzazione (dopo modifiche ai file .arb)
dart run intl_utils:generate

# Code generation (dopo modifiche a provider con @riverpod)
dart run build_runner build --delete-conflicting-outputs

# Segnala problemi nel codice
flutter analyze

# Build web
flutter build web --release --no-tree-shake-icons

# Test
flutter test
```

---

## 📁 Architettura del progetto

```
lib/
├── app/                    # Router, theme, scaffold, providers globali
│   ├── router.dart         # go_router con StatefulShellRoute.indexedStack
│   └── providers/          # formFactorProvider (breakpoint responsive)
├── core/
│   ├── l10n/               # intl_*.arb (IT/EN), l10_extension.dart
│   ├── models/             # Appointment, Booking, Staff, Service...
│   └── widgets/            # Widget riutilizzabili
└── features/
    ├── auth/             
    │   ├── data/
    │   ├── domain/
    │   ├── providers/      
    │   └── presentation/   
    ├── booking/            
    │   ├── data/
    │   ├── domain/
    │   ├── providers/      
    │   └── presentation/   
```

**Pattern per feature:** `domain/` → `data/` → `providers/` → `presentation/`

---

## 🔧 Stack tecnologico

| Tecnologia | Versione | Note |
|------------|----------|------|
| Flutter | 3.35+ | SDK 3.10+ |
| Riverpod | 3.x | `flutter_riverpod`, `riverpod_annotation` |
| go_router | 16.x | `StatefulShellRoute.indexedStack` |
| intl | 0.20+ | `flutter_intl` per generazione |


## 🎨 Pattern UI/UX

### Responsive
```dart
final formFactor = ref.watch(formFactorProvider);
// AppFormFactor.mobile / .tablet / .desktop
```
- **Desktop**: dialog/popup
- **Mobile e Tablet**: bottom sheet (`AppBottomSheet`)

### Localizzazione
```dart
import '/core/l10n/l10_extension.dart';
Text(context.l10n.nomeChiave)
```
Aggiungere chiavi in `lib/core/l10n/intl_it.arb` e `intl_en.arb`.

### Stile
- Estetica sobria: **no ripple/splash invasivi**

---

## ⚡ Provider API (IMPORTANTE - evitare loop infiniti)

I provider che fanno chiamate API **devono** usare `StateNotifier` con flag `_hasFetched`:

```dart
class ServicesDataNotifier extends StateNotifier<AsyncValue<ServicesData>> {
  final Ref _ref;
  bool _hasFetched = false;

  ServicesDataNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadData();
  }

  Future<void> _loadData() async {
    if (_hasFetched) return;  // ⚠️ PROTEZIONE DA LOOP
    _hasFetched = true;
    
    try {
      final result = await _ref.read(repositoryProvider).getData();
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _hasFetched = false;
    state = const AsyncValue.loading();
    await _loadData();
  }
}
```

**NON usare** `FutureProvider` o `AsyncNotifierProvider` per chiamate API che possono fallire!

---

## ✅ Checklist prima di modificare

1. [ ] Tutti i testi usano `context.l10n`?
2. [ ] I provider usano `ref.watch()` per UI, `ref.read()` per azioni?
3. [ ] Provider API usano `StateNotifier` con `_hasFetched`?

---

## 🚫 L'agente NON deve

- Aggiungere dipendenze non richieste
- Modificare indici route o `router.dart` senza richiesta esplicita
- Produrre snippet parziali invece di file completi
- Usare `ref.watch()` in loop pesanti o callback
- Introdurre animazioni/effetti non richiesti
- Usare `FutureProvider` per API calls (causa loop su errore)
- **Inserire/modificare/eliminare dati nel database** senza richiesta esplicita dell'utente

---

## ✅ L'agente DEVE

- Usare `StateNotifier` con `_hasFetched` per provider API
- Favorire il riutilizzo del codice
- Favorire l'uso di costruttori const
- Estrarre widget privati da `build()` lunghi

---

## 🔗 Multi-Business Path-Based URL (29/12/2025)

### Struttura URL
```
/                      → Landing page (business non specificato)
/:slug                 → Redirect a /:slug/booking
/:slug/booking         → Schermata prenotazione
/:slug/login           → Login
/:slug/register        → Registrazione
/:slug/my-bookings     → Le mie prenotazioni
/reset-password/:token → Reset password (globale, no slug)
```

### Provider chiave
- `routeSlugProvider` — StateProvider aggiornato dal router con lo slug corrente
- `currentBusinessProvider` — Legge slug da `routeSlugProvider` e carica business da API

### Path riservati (NON sono slug di business)
`reset-password`, `login`, `register`, `booking`, `my-bookings`, `change-password`, `privacy`, `terms`

### ⚠️ NON usare SubdomainResolver per lo slug
`SubdomainResolver.getBusinessSlug()` legge `Uri.base` che è **statico** al caricamento JS.
Usare sempre `ref.watch(routeSlugProvider)` per ottenere lo slug corrente.

### File di riferimento
| Concetto | File |
|----------|------|
| Route slug | `lib/app/providers/route_slug_provider.dart` |
| Router | `lib/app/router.dart` |
| Business provider | `lib/features/booking/providers/business_provider.dart` |

---

## 🌐 Flutter Web URL Strategy (30/12/2025)

### usePathUrlStrategy() OBBLIGATORIO
Per usare URL path-based (senza `#`) su Flutter Web:

```dart
// main.dart
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy(); // PRIMA di runApp!
  runApp(const ProviderScope(child: MyApp()));
}
```

### Dipendenza richiesta
```yaml
# pubspec.yaml
dependencies:
  flutter_web_plugins:
    sdk: flutter
```

### .htaccess per SPA routing
```apache
# web/.htaccess (copiare in build/web prima del deploy)
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^ index.html [L]
```

### API_BASE_URL
- Default in `api_config.dart`: `https://api.romeolab.it`
- Override locale via `--dart-define=API_BASE_URL=http://localhost:8000`
- Due configurazioni in `.vscode/launch.json`: produzione e locale

---

## 📍 Multi-Location Support (30/12/2025)

### Funzionalità
Se un business ha più sedi attive, l'utente può scegliere dove prenotare.
Se il business ha una sola sede, lo step "Sede" viene saltato automaticamente.

### Provider chiave
- `locationsProvider` — Carica lista sedi dal backend via API
- `selectedLocationProvider` — NotifierProvider per selezione utente
- `hasMultipleLocationsProvider` — Bool, determina se mostrare step Sede
- `effectiveLocationProvider` — Location effettiva (scelta o default)
- `effectiveLocationIdProvider` — Int ID per chiamate API

### Booking Flow con location
```dart
enum BookingStep { location, services, staff, dateTime, summary }
// location step mostrato solo se hasMultipleLocations == true
```

### Endpoint API
`GET /v1/businesses/{business_id}/locations/public`
- Ritorna solo sedi attive (`is_active = 1`)
- Campi limitati: id, business_id, name, address, city, phone, timezone, is_default

### File di riferimento
| Concetto | File |
|----------|------|
| Location model | `lib/core/models/location.dart` |
| Locations provider | `lib/features/booking/providers/locations_provider.dart` |
| Location step UI | `lib/features/booking/presentation/screens/location_step.dart` |
| Booking flow | `lib/features/booking/providers/booking_provider.dart` |
