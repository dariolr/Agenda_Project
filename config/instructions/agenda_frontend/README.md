# Agenda Frontend

App Flutter per prenotazioni online clienti finali.

## Produzione

- **URL**: https://prenota.romeolab.it
- **API**: https://api.romeolab.it

## Stack tecnologico

| Tecnologia | Versione | Note |
|------------|----------|------|
| Flutter | 3.35+ | SDK 3.10+ |
| Riverpod | 3.x | State management |
| go_router | 16.x | Navigation |
| intl | 0.20+ | Localizzazioni IT/EN |

## Comandi

```bash
# Localizzazione (dopo modifiche .arb)
dart run intl_utils:generate

# Code generation (dopo @riverpod)
dart run build_runner build --delete-conflicting-outputs

# Build web produzione
flutter build web --release --no-tree-shake-icons

# Deploy su SiteGround (copia .htaccess poi rsync)
cp web/.htaccess build/web/
rsync -avz --delete -e "ssh -p 18765" build/web/ siteground:~/www/prenota.romeolab.it/public_html/
```

## Ambienti

Configurazione runtime tramite `--dart-define` (stesso codicebase: local/demo/production).

Esempio `local`:

```bash
flutter run -d chrome \
  --dart-define=APP_ENV=local \
  --dart-define=API_BASE_URL=http://localhost:8888/agenda_core/public \
  --dart-define=FRONTEND_URL=http://localhost:3000
```

Dettagli completi: `../config/docs/agenda_frontend-environments.md`.

## Multi-Business Path-Based URL (29/12/2025)

L'app supporta più business tramite URL path-based:

| URL | Comportamento |
|-----|---------------|
| `/` | Landing page "Business non specificato" |
| `/:slug` | Redirect a `/:slug/booking` |
| `/:slug/booking` | Schermata prenotazione (auth required) |
| `/:slug/login` | Login (su web redirect a `login.html`) |
| `/:slug/register` | Registrazione |
| `/:slug/my-bookings` | Le mie prenotazioni |
| `/reset-password/:token` | Reset password (globale) |

### File chiave
- `lib/app/providers/route_slug_provider.dart` — StateProvider aggiornato dal router
- `lib/app/router.dart` — Estrae slug dal path e aggiorna provider
- `lib/features/booking/providers/business_provider.dart` — Carica business da API

### Route protette
- `/:slug/booking`
- `/:slug/my-bookings`
- `/:slug/profile`
- `/:slug/change-password`

Quando non autenticato, il router reindirizza a `/:slug/login?from={route}`.

### Login web nativo (07/02/2026)
- Su web, `/:slug/login` reindirizza a `web/login.html` (form HTML nativo).
- Obiettivo: migliore compatibilità autofill/password manager su iOS Safari e webview.
- `login.html` usa endpoint customer auth e cookie refresh (`credentials: include`).
- Per sicurezza, `login.html` NON accetta `api_base` da query string: l'API base è derivata dall'host corrente.

### ⚠️ NON usare SubdomainResolver
`SubdomainResolver.getBusinessSlug()` legge `Uri.base` (statico). Usare sempre `routeSlugProvider`.

## Multi-Location Support (30/12/2025)

Se un business ha più sedi attive, l'utente può scegliere dove prenotare.
Se il business ha una sola sede, lo step "Sede" viene saltato automaticamente.

### Provider chiave
- `locationsProvider` — Carica lista sedi dal backend
- `selectedLocationProvider` — NotifierProvider per selezione utente
- `hasMultipleLocationsProvider` — Bool, determina se mostrare step Sede
- `effectiveLocationIdProvider` — Int ID per chiamate API

### File di riferimento
| Concetto | File |
|----------|------|
| Location model | `lib/core/models/location.dart` |
| Locations provider | `lib/features/booking/providers/locations_provider.dart` |
| Location step UI | `lib/features/booking/presentation/screens/location_step.dart` |

## Architettura

```
lib/
├── app/                    # Router, theme, providers globali
├── core/
│   ├── l10n/              # Localizzazioni IT/EN
│   ├── models/            # Service, Staff, TimeSlot, etc.
│   ├── network/           # ApiClient + TokenStorage
│   └── widgets/           # Widget riutilizzabili
└── features/
    ├── auth/              # Login, Register, Password reset
    └── booking/           # Flow prenotazione completo
```

## Pattern Provider (fix loop infinito)

I provider che fanno chiamate API usano `StateNotifier` con flag `_hasFetched`:

```dart
class ServicesDataNotifier extends StateNotifier<AsyncValue<ServicesData>> {
  bool _hasFetched = false;
  
  Future<void> _loadData() async {
    if (_hasFetched) return;  // Protezione da loop
    _hasFetched = true;
    // API call...
  }
  
  Future<void> refresh() async {
    _hasFetched = false;
    state = const AsyncValue.loading();
    await _loadData();
  }
}
```

## Localizzazioni

File `.arb` in `lib/core/l10n/`:
- `intl_it.arb` - Italiano (default)
- `intl_en.arb` - Inglese

Dopo modifiche: `dart run intl_utils:generate`

## Aggiornamenti Importanti (04/04/2026)

### Booking locale: separazione `country` / `timezone` / `language`

È stata introdotta una strategia centralizzata per risolvere la lingua del booking frontend, senza usare più il paese come regola primaria.

Ordine di risoluzione:

1. query param URL `?lang=it|en`
2. `location.booking_default_locale`
3. locale browser/device (se supportata)
4. hint da `location.country` (fallback debole)
5. fallback finale deterministico: `it`

Riferimento policy: `BOOKING_LOCALE_POLICY.md`

### Nuovo campo location (API pubblica)

Le location pubbliche ora includono anche:

- `booking_default_locale` (nullable, `it|en`)

Questo campo è additivo e backward-compatible.

### App locale non hardcoded

L'app booking non è più forzata a `Locale('it')`: usa il resolver centralizzato.

## Features

- ✅ Multi-business path-based URL (`/:slug/booking`)
- ✅ Multi-location support (selezione sede)
- ✅ Selezione servizi (multi-service)
- ✅ Selezione pacchetti servizi per categoria (prezzo/durata effettivi)
- ✅ Selezione staff (opzionale)
- ✅ Calendario disponibilità
- ✅ Riepilogo e conferma
- ✅ Login / Register
- ✅ Le mie prenotazioni
- ✅ Cancellazione / Reschedule
- ✅ Password reset
- ✅ Gestione errori API senza loop
