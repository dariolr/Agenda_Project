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

---

## ✅ L'agente DEVE

- Usare `StateNotifier` con `_hasFetched` per provider API
- Favorire il riutilizzo del codice
- Favorire l'uso di costruttori const
- Estrarre widget privati da `build()` lunghi

---
