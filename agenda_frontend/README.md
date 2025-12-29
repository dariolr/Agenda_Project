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

## Multi-Business Path-Based URL (29/12/2025)

L'app supporta più business tramite URL path-based:

| URL | Comportamento |
|-----|---------------|
| `/` | Landing page "Business non specificato" |
| `/:slug` | Redirect a `/:slug/booking` |
| `/:slug/booking` | Schermata prenotazione |
| `/:slug/login` | Login |
| `/:slug/register` | Registrazione |
| `/:slug/my-bookings` | Le mie prenotazioni |
| `/reset-password/:token` | Reset password (globale) |

### File chiave
- `lib/app/providers/route_slug_provider.dart` — StateProvider aggiornato dal router
- `lib/app/router.dart` — Estrae slug dal path e aggiorna provider
- `lib/features/booking/providers/business_provider.dart` — Carica business da API

### ⚠️ NON usare SubdomainResolver
`SubdomainResolver.getBusinessSlug()` legge `Uri.base` (statico). Usare sempre `routeSlugProvider`.

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

## Features

- ✅ Multi-business path-based URL (`/:slug/booking`)
- ✅ Selezione servizi (multi-service)
- ✅ Selezione staff (opzionale)
- ✅ Calendario disponibilità
- ✅ Riepilogo e conferma
- ✅ Login / Register
- ✅ Le mie prenotazioni
- ✅ Cancellazione / Reschedule
- ✅ Password reset
- ✅ Gestione errori API senza loop
