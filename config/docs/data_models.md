# Data Models — agenda_core

## Core Entities

### Service
- id
- business_id
- category_id
- name
- duration_minutes
- price
- is_free
- is_price_starting_from
- is_bookable_online

### Staff
- id
- business_id
- name
- surname
- is_bookable_online

### Booking
- id
- business_id
- location_id
- customer_id
- start_time
- end_time
- notes

### ServicePackage
- id
- business_id
- location_id
- category_id
- name
- description
- override_price
- override_duration_minutes
- is_active
- is_broken
- created_at
- updated_at

### ServicePackageItem
- package_id
- service_id
- sort_order

---

## User & Auth Entities

### User
- id
- email (unique, global)
- password_hash
- first_name
- last_name
- phone
- is_active
- is_superadmin
- created_at
- updated_at

### AuthSession
- id
- user_id
- refresh_token_hash (SHA-256)
- device_info
- ip_address
- last_used_at
- expires_at
- revoked_at
- created_at

---

## Business Access Control (M11)

### BusinessUser
Associa utenti a businesses con ruoli e permessi.

- id
- business_id
- user_id
- role (enum: owner, admin, manager, staff, viewer, custom)
- staff_id (optional, link a staff record)
- scope_type (`business` | `locations`)
- allowed_service_ids (JSON array, optional — vedi Filter Semantics)
- allowed_class_type_ids (JSON array, optional — vedi Filter Semantics)
- allowed_staff_ids (JSON array, optional — vedi Filter Semantics)
- can_manage_bookings
- can_manage_clients
- can_manage_services
- can_manage_staff
- can_view_reports
- is_active
- invited_by
- invited_at
- joined_at
- created_at
- updated_at

**Role Hierarchy:**
- `owner`: Full control, can delete business, manage all users
- `admin`: Full control except delete business, can manage users
- `manager`: Operativita completa sul perimetro assegnato (business intero o sedi assegnate)
- `staff`: Operativita limitata al membro del team associato (`staff_id`). Può schedulare eventi lezione e gestire appuntamenti solo per il proprio `staff_id`. I filtri `allowed_service_ids` / `allowed_class_type_ids` restringono ulteriormente quali servizi/tipi lezione può gestire.
- `viewer`: Sola lettura (agenda/prenotazioni/staff/servizi nel perimetro assegnato)
- `custom`: Ruolo completamente configurabile. I permessi (`can_manage_*`) e i filtri
  (`allowed_service_ids`, `allowed_class_type_ids`, `allowed_staff_ids`) sono impostati
  esplicitamente dall'UI, non derivati dal ruolo. Il vincolo "solo questi membri del team"
  deriva da `allowed_staff_ids` (insieme), **non** da `staff_id` (singolo) come per il ruolo
  `staff`: sono meccanismi distinti. La logica backend che fa `if role === 'staff'`
  (forced-staff) o `if role === 'manager'` (grant extra su staff/scope) **non** si applica a
  `custom`, che ricade interamente sui flag e sui filtri. Enforcement in scrittura
  (`staff_id` assegnato ∈ `allowed_staff_ids`) attivo in `BookingsController`,
  `AppointmentsController`, `ClassEventsController`.

**Scope Semantics:**
- `scope_type=business`: accesso a tutte le sedi del business.
- `scope_type=locations`: accesso limitato alle sedi assegnate in `business_user_locations`.

**Filter Semantics (allowed_service_ids / allowed_class_type_ids / allowed_staff_ids):**
I tre filtri sono **indipendenti** e seguono una semantica a 3 stati ciascuno:
- `null` → **Tutti**: nessun filtro, accesso completo a tutti i servizi/tipi lezione/membri del team.
- `[]` → **Nessuno**: nessun accesso (zero elementi visibili e gestibili).
- `[1, 2, ...]` → **Solo selezionati**: accesso limitato agli id esplicitamente elencati.

I tre filtri si applicano in modo ortogonale: impostarne uno non influenza gli altri.

`allowed_staff_ids` indica su quali membri del team l'operatore può operare. È mostrato in UI
solo per i ruoli diversi da admin/owner (accesso totale) e da `staff` (già vincolato al membro
collegato via `staff_id`). Invariante speculare a quella dei servizi: chi ha `can_manage_staff`
non può avere un filtro residuo → `allowed_staff_ids` viene forzato a `NULL` (`create`) o rifiutato
(`update`). Enforcement in lettura: l'agenda mostra solo i membri consentiti
(`staff_filter_providers.dart` → `filteredStaffProvider`). L'enforcement in scrittura
(`staff_id` assegnato ∈ `allowed_staff_ids`) arriverà con il ruolo `custom` (Step 2).

**Effetti del filtro:**
- Visibilità nell'agenda (lato Flutter e lato backend)
- Autorizzazione a creare/modificare/cancellare eventi del tipo corrispondente (lato backend)
- Per `allowed_service_ids`: validato anche su creazione e modifica appuntamenti

**Filtro lettura backend (implementato):** gli endpoint di lettura per operatori applicano il filtro a 3 stati:
- `allowed_class_type_ids` → `ClassEventsController`: `indexTypes`, `indexByBusiness`, `show`, `participants`
- `allowed_service_ids` → `ServicesController::indexByLocation`; `BookingsController::listAll` (a livello SQL, paginazione-safe) e `index` (vista giorno agenda)
- Semantica bookings: una prenotazione è visibile se contiene **almeno un** servizio consentito (union).
- Gli endpoint pubblici/cliente (`ServicesController::index`, portale prenotazioni) NON applicano il filtro operatore.
- Superadmin e service manager (`allowed_*` = NULL) non sono mai filtrati.

**Relazione con `can_manage_services`:**
`can_manage_services` controlla la gestione della **configurazione** (creare/modificare/eliminare tipi di servizio e tipi di lezione). È ortogonale ai filtri: un operatore con filtri attivi ha `can_manage_services = false` per default, ma può comunque schedulare eventi per i tipi a cui ha accesso.

**Unique Constraint:** `(business_id, user_id)`

### BusinessInvitation
Inviti via email per nuovi operatori.

- id
- business_id
- email
- role (enum: admin, manager, staff, viewer, custom)
- scope_type (`business` | `locations`)
- staff_id (nullable, obbligatorio quando `role=staff`)
- token (64-char hex, unique)
- expires_at (default: created_at + 7 days)
- status (enum: pending, accepted, expired, declined, revoked)
- accepted_by (user_id, nullable)
- accepted_at (nullable)
- invited_by (user_id)
- allowed_service_ids / allowed_class_type_ids / allowed_staff_ids (JSON array, optional — filtri salvati sull'invito e applicati alla creazione del BusinessUser all'accettazione; stessa semantica 3-stati. NB: su invito `[]` è collassato a `null` = Tutti)
- can_manage_bookings / can_manage_clients / can_manage_services / can_manage_staff / can_view_reports (tinyint nullable — permessi granulari salvati sull'invito, valorizzati solo per `role=custom`. `NULL` = non specificato → all'accettazione si applica il default del ruolo)
- created_at
- updated_at

**Unique Constraint:** `(business_id, email, status)` - un solo invito pending per email

**Indexes:**
- `token, status` - lookup per accettazione
- `business_id, status` - lista inviti pendenti
- `email, status` - ricerca inviti per email

**Note operative:**
- In caso di reinvio invito, i token precedenti vengono invalidati marcando gli inviti precedenti come `revoked`.
- Per `role=staff` l'invito mantiene anche l'associazione allo `staff_id` selezionato.

---

## Relationships

```
User (1) ----< (N) AuthSession
User (1) ----< (N) BusinessUser >---- (1) Business
User (1) ----< (N) BusinessInvitation >---- (1) Business
Business (1) ----< (N) Location
Business (1) ----< (N) Staff
Business (1) ----< (N) Service
Business (1) ----< (N) Client
Location (1) ----< (N) Booking
```

---

## Notes

- `is_superadmin` in `users` è flag globale, non legato a nessun business
- Superadmin bypassa completamente `business_users` e può operare su qualsiasi business
- `staff_id` in `business_users` permette di collegare un operatore al suo calendario staff
