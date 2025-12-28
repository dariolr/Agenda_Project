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
flutter build web --release --dart-define=API_BASE_URL=https://api.romeolab.it

# Deploy su SiteGround
rsync -avz --delete build/web/ siteground:www/prenota.romeolab.it/public_html/
```

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

- ✅ Selezione servizi (multi-service)
- ✅ Selezione staff (opzionale)
- ✅ Calendario disponibilità
- ✅ Riepilogo e conferma
- ✅ Login / Register
- ✅ Le mie prenotazioni
- ✅ Cancellazione / Reschedule
- ✅ Password reset
- ✅ Gestione errori API senza loop
