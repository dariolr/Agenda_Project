# agenda_backend

**Gestionale multi-staff Flutter** per la piattaforma Agenda elettronica.

Applicazione desktop/web per la gestione completa di appuntamenti, clienti, servizi e staff di un'attività multi-sede.

---

## 🎯 Overview

agenda_backend è il **pannello di amministrazione** della piattaforma Agenda. Permette a operatori e manager di:

- 📅 **Gestire appuntamenti** tramite vista calendario drag & drop
- 👥 **Amministrare clienti** con anagrafica completa e storico
- 💇 **Configurare servizi** per ogni location con prezzi e durate
- 👤 **Organizzare staff** con disponibilità e skill
- 🏢 **Multi-business/multi-location** supporto nativo

**Stack tecnologico:**
- Flutter 3.35+ (web primary, desktop ready)
- Riverpod 3.x per state management
- go_router 16.x per navigation
- API REST backend (agenda_core PHP)

---

## 🏗️ Architettura

### Pattern Feature-Based
```
lib/
├── app/                    # Router, theme, providers globali
│   ├── router.dart         # go_router con StatefulShellRoute.indexedStack
│   ├── theme/              # Theme config e provider
│   └── providers/          # formFactorProvider (responsive breakpoints)
├── core/
│   ├── l10n/               # Localizzazione IT/EN (intl)
│   ├── models/             # Domain models condivisi
│   ├── network/            # ApiClient, error handling
│   └── widgets/            # Widget riutilizzabili
└── features/
    ├── agenda/             # FEATURE PRINCIPALE - Calendario
    │   ├── domain/         # Layout config, business rules
    │   ├── data/           # Repositories (API calls)
    │   ├── providers/      # Riverpod state (drag, resize, scroll, bookings)
    │   └── presentation/   # Screens, widgets, dialogs
    ├── clients/            # Gestione anagrafica clienti
    ├── services/           # Configurazione servizi
    ├── staff/              # Amministrazione staff
    └── business/           # Business/Locations management
```

### Repository Pattern
Ogni feature ha un repository dedicato che astrae le chiamate API:
```dart
// Example: BusinessRepository
class BusinessRepository {
  final ApiClient _apiClient;
  
  Future<List<Business>> getAll() => _apiClient.getBusinesses();
  Future<Business> getById(int id) => _apiClient.getBusiness(id);
}
```

### State Management con Riverpod
- **FutureProvider**: Per dati read-only asincroni
- **Notifier**: Per state mutabile con async initialization
- **NO AsyncNotifier**: Per compatibilità con logica sincrona esistente

---

## 🚀 Getting Started

### Prerequisites
```bash
flutter --version  # 3.35+
dart --version     # 3.10+
```

### Setup

1. **Clone e dipendenze**:
```bash
cd agenda_backend
flutter pub get
```

2. **Code generation** (provider Riverpod):
```bash
dart run build_runner build --delete-conflicting-outputs
```

3. **Localizzazione** (dopo modifiche .arb):
```bash
dart run intl_utils:generate
```

4. **Configurazione API**:
Modifica [lib/core/network/api_config.dart](lib/core/network/api_config.dart):
```dart
static const String baseUrl = 'http://your-api-host/v1';
```

### Run

**Web (development)**:
```bash
flutter run -d chrome
```

**Web (production build)**:
```bash
flutter build web --release --no-tree-shake-icons
```

**Desktop**:
```bash
flutter run -d macos  # o windows/linux
```

---

## ⚙️ Configurazione Backend

agenda_backend richiede [agenda_core](../agenda_core/) backend in esecuzione.

**Endpoint richiesti:**
- Auth: `/v1/auth/login`, `/v1/auth/refresh`, `/v1/auth/logout`
- Businesses: `/v1/businesses`, `/v1/businesses/{id}/locations`
- Appointments: `/v1/locations/{id}/appointments`
- Clients: `/v1/clients`
- Services: `/v1/services`
- Staff: `/v1/staff`

Vedere [agenda_core/docs/api_contract_v1.md](../agenda_core/docs/api_contract_v1.md) per contratto completo.

---

## 📱 Features

### 1. Calendario Interattivo
- **Drag & Drop**: Sposta appuntamenti tra staff e orari
- **Resize**: Modifica durata appuntamenti trascinando i bordi
- **Scroll sincronizzato**: Timeline oraria e colonne staff
- **Multi-view**: Giorno singolo, settimana, mese

**Provider critici** (NON modificare senza conoscenza):
- `dragSessionProvider` — Gestione drag & drop
- `resizingProvider` — Stato resize attivo
- `agendaScrollProvider` — Controller scroll condivisi
- `bookingsProvider` — CRUD bookings con validazione

### 2. Gestione Clienti
- Anagrafica completa (nome, email, telefono, note)
- Storico appuntamenti
- Search e filtri avanzati
- Soft delete (archiviazione)

### 3. Servizi e Prezzi
- Organizzazione per categorie
- Durata e prezzo per location
- Colori personalizzati per UI
- Disponibilità online booking

### 4. Staff Management
- Configurazione disponibilità
- Skill e servizi erogabili
- Vista settimanale carico lavoro

### 5. Multi-Business
- Gestione multiple attività
- Locations indipendenti
- Timezone e currency per location

---

## 🎨 UI/UX Guidelines

### Responsive Design
```dart
final formFactor = ref.watch(formFactorProvider);

switch (formFactor) {
  case AppFormFactor.desktop:
    // Dialog/popup
  case AppFormFactor.tablet:
  case AppFormFactor.mobile:
    // Bottom sheet
}
```

**Breakpoints:**
- Desktop: > 840px
- Tablet: 600px - 840px
- Mobile: < 600px

### Localizzazione
Tutti i testi usano `context.l10n`:
```dart
import '/core/l10n/l10_extension.dart';

Text(context.l10n.appointments)  // "Appuntamenti" (IT) / "Appointments" (EN)
```

Aggiungere chiavi in:
- [lib/core/l10n/intl_it.arb](lib/core/l10n/intl_it.arb)
- [lib/core/l10n/intl_en.arb](lib/core/l10n/intl_en.arb)

### Stile
- **Estetica sobria**: No ripple/splash invasivi
- **Const constructors**: Dove possibile per performance
- **Widget extraction**: Evitare build() > 200 righe

---

## 🧪 Testing

```bash
# Run tutti i test
flutter test

# Coverage
flutter test --coverage

# Analyze
flutter analyze
```

**Test strategy:**
- Test unitari per provider e business logic
- Widget test per UI components critici
- Integration test opzionali contro backend reale
- **Mock eliminati**: Tutti i provider usano API reali

Vedere file INTEGRATION_COMPLETE.md per dettagli integrazione API.

---

## 📚 Documentazione

| File | Descrizione |
|------|-------------|
| [AGENTS.md](AGENTS.md) | Istruzioni per AI agents |
| [INTEGRATION_COMPLETE.md](INTEGRATION_COMPLETE.md) | Storia integrazione API |

**Documentazione backend:**
- [agenda_core/docs/decisions.md](../agenda_core/docs/decisions.md) — Decisioni architetturali
- [agenda_core/docs/api_contract_v1.md](../agenda_core/docs/api_contract_v1.md) — Contratto API
- [agenda_core/docs/milestones.md](../agenda_core/docs/milestones.md) — Roadmap progetto

---

## 🚧 Development Guidelines

### Prima di modificare codice

1. ✅ Leggere [AGENTS.md](AGENTS.md) per regole architetturali
2. ✅ Verificare provider critici (drag, resize, scroll)
3. ✅ Usare `context.l10n` per tutti i testi
4. ✅ Mantenere pattern repository per API calls
5. ✅ NO mock data in provider di produzione

### Code generation workflow

Dopo modifiche a file con annotazioni `@riverpod`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Dopo modifiche a file `.arb`:
```bash
dart run intl_utils:generate
```

### Commit checklist

- [ ] `flutter analyze` passa senza issue
- [ ] `flutter test` passa tutti i test
- [ ] Code generation eseguito se necessario
- [ ] Localizzazione aggiornata se nuovi testi
- [ ] README aggiornato se nuove feature

---

## 🔧 Troubleshooting

### "Provider not found"
```bash
dart run build_runner build --delete-conflicting-outputs
```

### "Missing localizations"
```bash
dart run intl_utils:generate
flutter clean && flutter pub get
```

### "API connection refused"
Verifica che agenda_core backend sia in esecuzione:
```bash
cd ../agenda_core
php -S localhost:8000 -t public
```

### Drag & drop non funziona
Verifica che `agendaScrollProvider` e `dragSessionProvider` non siano stati modificati. Questi provider sono critici.

---

## 📄 License

Proprietario — Romeo Lab

---

## 👥 Team

Sviluppo: Romeo Lab  
Contatti: dariolarosa@gmail.com
