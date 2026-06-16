# Operator Permissions — Work Log & Build Guide

> **Documento autosufficiente.** Tutto ciò che serve per riprendere il lavoro in una
> conversazione pulita è qui: stato attuale, decisioni architetturali, schema DB reale,
> elenco esatto dei punti di codice da toccare, pattern da riusare e checklist ordinata.
> I percorsi sono relativi alla root del repo (`Agenda_Project/`).

---

## 0. Come usare questo documento

- **Stai riprendendo il lavoro?** Vai alla sezione **§7 Piano operativo Step 1 + Step 2** (checklist ordinata).
- **Ti serve il contesto del perché?** §1–§5.
- **Ti serve sapere dove sta una cosa nel codice?** §6 (mappa file) e §8 (riferimenti puntuali).
- Repo multi-modulo: `agenda_core` = backend PHP (API), `agenda_backend` = app Flutter (gestionale/back-office), `config/` = migrazioni + docs.

---

## 1. Modello attuale (implementato)

### Ruoli esistenti
`business_users.role` è un enum: `owner`, `admin`, `manager`, `staff`, `viewer`.

- `owner` / `admin` → controllo totale (gestiscono anche altri operatori)
- `manager` → operatività completa sul perimetro (business o sedi), nessuna restrizione su staff
- `staff` → collegato a un singolo membro del team (`staff_id`), opera solo per quel membro
- `viewer` → sola lettura

### Filtri visibilità/operatività — semantica a 3 stati
Colonne JSON su `business_users`: `allowed_service_ids` e `allowed_class_type_ids`.
- `null` (NULL in DB) → **Tutti** (nessun filtro)
- `[]` (`'[]'` in DB) → **Nessuno**
- `[1, 2, ...]` → **Solo selezionati**

I due filtri sono **indipendenti** tra loro. La decodifica avviene in
`BusinessUserRepository::decodeJsonIds()` (NULL→null, `[]`→[], `[ids]`→array int).

**Invariante:** un operatore con `can_manage_services = true` non può avere filtri
residui → `create()`/`update()` forzano `allowed_service_ids = allowed_class_type_ids = NULL`.

### Effetti dei filtri (tutti implementati)
1. **Visibilità agenda** — lato Flutter (client-side) **e** lato backend (vedi §3).
2. **Autorizzazione scrittura** — creare/modificare/cancellare eventi lezione e appuntamenti.
3. `allowed_service_ids` validato anche su create/update appuntamenti.

### Comportamento ruolo `staff` (implementato)
- Picker staff nel form programmazione lezione bloccato al membro associato.
- Backend valida che `staff_id` negli eventi/appuntamenti corrisponda al membro collegato:
  - `ClassEventsController::getLinkedStaffId()` (controlla `role === 'staff'`)
  - `BookingsController::getForcedStaffIdForStaffOperator()` (controlla `role === 'staff'`)
  - `AppointmentsController` (stesso pattern, `role === 'staff'`)

---

## 2. Filtro lettura backend — ✅ FATTO (sessione 2026-06-16)

Implementato il filtraggio lato server (prima era solo client-side, quindi aggirabile).

**Helper condivisi** in `agenda_core/src/Infrastructure/Repositories/BusinessUserRepository.php`:
- `getAllowedServiceIds(int $userId, int $businessId): ?array`
- `getAllowedClassTypeIds(int $userId, int $businessId): ?array`
- Entrambi ritornano la semantica 3-stati (`null`/`[]`/`[ids]`).

**Endpoint filtrati** (solo operatori; gli endpoint pubblici/cliente NON sono toccati):
- `ClassEventsController`: `indexTypes`, `indexByBusiness`, `show`, `participants` → `allowed_class_type_ids`
- `ServicesController::indexByLocation` → `allowed_service_ids`
  - **NB:** `ServicesController::index` è il portale clienti → nessun filtro operatore
- `BookingsController::listAll` (a livello SQL, paginazione-safe via filtro `service_ids`) e
  `BookingsController::index` (vista giorno, post-filtro PHP) → `allowed_service_ids`

**Pattern usato:**
- Liste piccole (tipi lezione, servizi, eventi del giorno) → `array_filter` post-query con `array_flip`.
- Liste paginate (`listAll`) → iniezione del filtro nel `WHERE` SQL (intersezione con eventuale
  filtro richiesto dal client; ritorno vuoto anticipato se accesso `[]` o intersezione vuota).
- **Semantica bookings = union:** una prenotazione è visibile se contiene **almeno un**
  servizio consentito.
- Superadmin e service manager (`allowed_*` = NULL) non sono mai filtrati.

Doc di riferimento: `config/docs/data_models.md` → sezione "Filter Semantics".

---

## 3. Gap ancora aperti

1. **Nessun filtro per membro del team** — non esiste `allowed_staff_ids`. Non è possibile
   dire "questo operatore gestisce solo i membri X e Y". → **Step 1**.

2. **Ruoli sovrapposti** — `manager` e `staff` hanno gli stessi flag di permesso per default,
   differiscono solo per la restrizione su `staff_id`. Distinzione ambigua. → risolto da **Step 2**.

3. **`allowed_service_ids` ridondante per `staff`** — un operatore `staff` è già implicitamente
   vincolato ai servizi del membro a cui è collegato (`staff_id → staff member → services`).
   Per `staff` il filtro va nascosto in UI e ignorato a backend (usare i servizi del membro).
   Per il futuro ruolo `custom`, invece, `allowed_service_ids` va popolato esplicitamente
   (è proprio il senso del ruolo configurabile).

---

## 4. Decisione architetturale: nuovo ruolo `custom`

Un ruolo **completamente configurabile** che affianca i ruoli esistenti durante una fase di
transizione, per poi sostituirli (manager/staff/viewer).

### Modello del ruolo `custom`
- `can_manage_bookings` → crea/modifica/cancella prenotazioni e appuntamenti
- `can_manage_clients` → gestione anagrafica clienti
- `can_view_reports` → accesso ai report
- `allowed_staff_ids` → su quali membri del team opera (`null`=tutti, `[]`=nessuno, `[..]`=selezionati) — **nuovo, Step 1**
- `allowed_service_ids` → quali servizi gestisce (già esistente)
- `allowed_class_type_ids` → quali tipi lezione gestisce (già esistente)
- `scope_type` + `business_user_locations` → perimetro geografico (già esistente)

### Strategia di introduzione (decisa)
- Aggiungere `custom` come **nuovo valore dell'enum `role`** senza rimuovere i ruoli esistenti.
- I vecchi ruoli continuano a funzionare durante la transizione.
- **Punto critico:** tutta la logica backend che fa `if role === 'staff'` (forced staff) o
  `if role === 'manager'` NON si applica a `custom`. Per `custom` il vincolo sul membro del team
  deriva da `allowed_staff_ids`, non da `staff_id`. Vanno gestiti come meccanismi distinti.
- Quando `custom` è stabile → migrare gli utenti esistenti e deprecare i vecchi ruoli.

### Decisione su `allowed_service_ids` per `staff` vs `custom`
Vedi §3 punto 3: per `staff` redundante (nascondere/ignorare), per `custom` esplicito.

---

## 5. Schema DB reale (per Step 1)

`business_users` definito in `config/migrations/FULL_DATABASE_SCHEMA.sql` (~riga 271):

```sql
CREATE TABLE `business_users` (
  `id` int UNSIGNED NOT NULL,
  `business_id` int UNSIGNED NOT NULL,
  `user_id` int UNSIGNED NOT NULL,
  `role` enum('owner','admin','manager','staff','viewer') ... DEFAULT 'staff',
  `scope_type` enum('business','locations') ... DEFAULT 'business',
  `staff_id` int UNSIGNED DEFAULT NULL,
  `can_manage_bookings` tinyint(1) NOT NULL DEFAULT '1',
  `can_manage_clients` tinyint(1) NOT NULL DEFAULT '1',
  `can_manage_services` tinyint(1) NOT NULL DEFAULT '0',
  `can_manage_staff` tinyint(1) NOT NULL DEFAULT '0',
  `can_view_reports` tinyint(1) NOT NULL DEFAULT '0',
  `allowed_service_ids` json DEFAULT NULL,
  `allowed_class_type_ids` json DEFAULT NULL,
  ...
);
```

`business_invitations` ha le stesse colonne filtro (`allowed_service_ids`, `allowed_class_type_ids`)
e lo stesso enum `role` (i filtri sull'invito si applicano all'accettazione).

**Pattern migrazioni:** file `config/migrations/YYYYMMDD_descrizione.sql` con `ALTER TABLE`.
Esempio di riferimento (filtri servizi/lezioni): `config/migrations/20260601_business_user_service_filters.sql`:

```sql
ALTER TABLE business_users
  ADD COLUMN allowed_service_ids JSON NULL COMMENT '...',
  ADD COLUMN allowed_class_type_ids JSON NULL COMMENT '...';
ALTER TABLE business_invitations
  ADD COLUMN allowed_service_ids JSON NULL,
  ADD COLUMN allowed_class_type_ids JSON NULL;
```

> Esistono due cartelle migrazioni: `config/migrations/` (usata per le migrazioni recenti, es. i filtri)
> e `config/database/migrations/`. Seguire `config/migrations/` per coerenza con `20260601_*`.
> Aggiornare anche `FULL_DATABASE_SCHEMA.sql` (è lo snapshot completo).

---

## 6. Mappa file da toccare

### PHP (`agenda_core/`)
| File | Ruolo nel lavoro |
|---|---|
| `config/migrations/<nuovo>.sql` | Step 1: add `allowed_staff_ids`; Step 2: estendi enum `role` con `custom` |
| `config/migrations/FULL_DATABASE_SCHEMA.sql` | aggiornare snapshot schema |
| `src/Infrastructure/Repositories/BusinessUserRepository.php` | decode/persist `allowed_staff_ids`, helper `getAllowedStaffIds`, `defaultPermissionsForRole` + `canAssignRole` per `custom` |
| `src/Infrastructure/Repositories/BusinessInvitationRepository.php` | persist `allowed_staff_ids` + ruolo `custom` sull'invito |
| `src/Http/Controllers/BusinessUsersController.php` | accetta `allowed_staff_ids` nel body; `defaultPermissionsForRole`; validazione ruolo `custom` |
| `src/Http/Controllers/BusinessInvitationsController.php` | accetta `allowed_staff_ids` + `custom` |
| `src/Http/Controllers/BookingsController.php` | enforcement staff per `custom` (read+write), distinto dal forced-staff di `role==='staff'` |
| `src/Http/Controllers/ClassEventsController.php` | enforcement staff per `custom`; `getLinkedStaffId` resta per `staff` |
| `src/Http/Controllers/AppointmentsController.php` | enforcement staff per `custom` |
| `src/Http/Controllers/AuthController.php` | espone `role` + permessi in `/v1/me` (verificare che `custom` passi i flag) |

### Flutter (`agenda_backend/`)
| File | Ruolo nel lavoro |
|---|---|
| `lib/core/models/business_user.dart` | campo `allowedStaffIds`; label ruolo `custom`; getter (`isAdmin`, ecc.) |
| `lib/core/models/business_invitation.dart` | campo `allowedStaffIds`; ruolo `custom` |
| `lib/core/network/api_client.dart` | serializzazione `allowed_staff_ids` in create/update/invite |
| `lib/features/auth/providers/current_business_user_provider.dart` | esporre filtri/ruolo correnti |
| `lib/features/business/presentation/dialogs/role_selection_dialog.dart` | terza sezione filtro "Membri del team"; UI ruolo `custom` con tutti i toggle |
| `lib/features/business/presentation/dialogs/invite_operator_dialog.dart` | invito con ruolo `custom` + filtri |
| `lib/features/business/presentation/operators_screen.dart` | lista/scelta ruoli inclusi `custom` |
| `lib/features/agenda/providers/staff_filter_providers.dart` | filtro agenda per `allowed_staff_ids` |

### Documentazione
- `config/docs/data_models.md` — aggiornare BusinessUser/BusinessInvitation con `allowed_staff_ids` e il ruolo `custom`.
- Questo file — tenere aggiornati gli stati ✅.

---

## 7. Piano operativo Step 1 + Step 2 (checklist ordinata)

> Step 1 (`allowed_staff_ids`) e Step 2 (`custom`) sono accoppiati: conviene farli insieme,
> perché `allowed_staff_ids` ha senso solo con un ruolo che lo consuma (`custom`).

### Step 1 — `allowed_staff_ids`
1. **Migration DB**: nuovo file `config/migrations/<data>_business_user_staff_filter.sql` →
   `ALTER TABLE business_users ADD COLUMN allowed_staff_ids JSON NULL;` + idem su `business_invitations`.
   Aggiornare `FULL_DATABASE_SCHEMA.sql`.
2. **Repository PHP** (`BusinessUserRepository`):
   - aggiungere `allowed_staff_ids` alle `SELECT` di `findByUserAndBusiness` e `findUsersByBusinessId`;
   - decodificarlo con `decodeJsonIds()`;
   - persisterlo in `create()` e `update()` (mirror esatto di `allowed_service_ids`, inclusa l'invariante service-manager);
   - helper `getAllowedStaffIds(int $userId, int $businessId): ?array`.
   - stesso lavoro su `BusinessInvitationRepository` (persist all'invito).
3. **Controller PHP**: `BusinessUsersController` e `BusinessInvitationsController` leggono
   `allowed_staff_ids` dal body (3-stati: assente/null=Tutti, `[]`=Nessuno, `[ids]`=selezionati).
4. **Flutter model + serializzazione**: `business_user.dart`, `business_invitation.dart`, `api_client.dart`.
5. **UI** (`role_selection_dialog.dart`): terza sezione filtro "Membri del team accessibili",
   stesso widget 3-stati delle altre due (riusa `_FilterCategorySection`). Stringhe via l10n
   (ARB IT+EN + `dart run intl_utils:generate`, mai modificare i Dart generati).
6. **Enforcement**:
   - **Read**: filtrare l'agenda per `allowed_staff_ids` (`staff_filter_providers.dart` lato Flutter;
     e/o backend in `BookingsController::index`/`listAll` su `staff_id` degli item, e
     `ClassEventsController::indexByBusiness` su `staff_id` evento).
   - **Write**: in create/update di booking ed eventi, lo `staff_id` assegnato deve appartenere
     a `allowed_staff_ids` (per ruolo `custom`).

### Step 2 — ruolo `custom`
7. **Migration DB**: estendere enum →
   `enum('owner','admin','manager','staff','viewer','custom')` su `business_users` e `business_invitations`.
   Aggiornare `FULL_DATABASE_SCHEMA.sql`.
8. **Repository PHP** (`BusinessUserRepository`):
   - `defaultPermissionsForRole()`: case `'custom'` → tutti i flag `false` di default (poi configurabili dall'UI);
   - `canAssignRole()`: consentire a `owner`/`admin` di assegnare `custom`;
   - `update()` deve già persistere i singoli flag + filtri (verificare che `custom` passi per quel path).
9. **Logica autorizzazione backend** — il punto delicato:
   - Il vincolo "solo il mio staff" per `custom` deriva da `allowed_staff_ids`, **non** da `staff_id`.
   - `getForcedStaffIdForStaffOperator()` / `getLinkedStaffId()` restano specifici per `role === 'staff'`.
   - Aggiungere il controllo `allowed_staff_ids` come ramo separato per `custom` in:
     `BookingsController`, `ClassEventsController`, `AppointmentsController`.
   - I check `can_manage_*` e i filtri `allowed_service_ids`/`allowed_class_type_ids` valgono già per `custom`
     (sono per-flag/per-filtro, non per-ruolo) — verificare che nessun `if role===...` li scavalchi.
10. **Flutter UI** (`role_selection_dialog.dart`, `invite_operator_dialog.dart`, `operators_screen.dart`,
    `business_user.dart` label): quando il ruolo è `custom`, mostrare tutti i toggle permessi +
    le 3 sezioni filtro (servizi, tipi lezione, membri team). Label IT: "Operatore personalizzato".
11. **Doc**: aggiornare `data_models.md` (enum role, nuovo campo, semantica) e gli stati in questo file.

### Verifica finale
- `php -l` su ogni file PHP modificato; eseguire la suite test backend se presente.
- `dart analyze` sul modulo Flutter; rigenerare l10n.
- Test manuale: creare un operatore `custom` con filtri parziali e verificare visibilità +
  blocco scrittura su servizi/tipi/membri non consentiti.

---

## 8. Riferimenti puntuali — dove i ruoli sono cablati nel codice

Tutti i punti che fanno branching per ruolo (da rivedere quando si introduce `custom`):

**PHP — forced staff (`role === 'staff'`):**
- `BookingsController::getForcedStaffIdForStaffOperator()`
- `ClassEventsController::getLinkedStaffId()` (~riga 1380)
- `AppointmentsController` (~riga 87)
- `StaffPlanningController` (~righe 442/448), `StaffController` (~righe 197/200/288)

**PHP — read-only (`role === 'viewer'`):**
- `BookingsController` (~riga 71), `AppointmentsController` (~riga 58), `BookingPaymentsController` (~riga 278)

**PHP — assegnazione/permessi per ruolo:**
- `BusinessUserRepository::defaultPermissionsForRole()` (~391), `canAssignRole()` (~589)
- `BusinessUsersController::defaultPermissionsForRole()` (~529), validazione role in create/update (~96,124,202-222,306,311)
- `BusinessInvitationRepository` (~44,61), `BusinessInvitationsController` (~149)

**Flutter — ruoli:**
- `business_user.dart`: `isAdmin`/`canManageUsers` (~45-48), switch label ruolo (~58-62)
- UI scelta ruolo: `operators_screen.dart`, `invite_operator_dialog.dart`, `role_selection_dialog.dart`

---

## 9. Vincoli di processo (dalle memorie utente)

- **L10n**: aggiungere chiavi in **entrambi** gli ARB (`intl_it.arb` + `intl_en.arb`),
  rigenerare con `dart run intl_utils:generate`, usare `context.l10n.key`. Mai modificare i Dart generati.
- **Firme `Response`**: verificare sempre la firma di `Response::error`/`validationError` prima dell'uso
  (`$traceId` viene prima di `$params`).
- **Route esistenti**: non rimuovere/spostare route; aggiungere campi ai controller esistenti.
  `/v1/me/` appartiene ad `AuthController`.
- **Comportamento agente**: rispondere alle domande senza eseguire azioni finché non c'è conferma esplicita.
