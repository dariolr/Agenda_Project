# AGENDA_AGENT_CRM_UPGRADE_INSTRUCTIONS.md
# Obiettivo: trasformare l’area “Clienti” della piattaforma Agenda in un CRM professionale (robusto, elegante, scalabile)
# Scope: agenda_core (API PHP + DB), agenda_backend (gestionale Flutter), agenda_frontend (customer booking web) SOLO dove utile (profilo/consensi/preferenze).
# Vincoli non negoziabili:
# - Zero breaking change su flussi prenotazioni 1:1 esistenti.
# - Ogni modifica DB deve avere migrazione coerente e rollback/forward sicuro.
# - Mantenere compatibilità con provider/repository pattern (no mock in produzione).
# - Error handling standard e contratti API documentati.
#
# Fonte bundle: “agenda_all_bundle.txt” generato il Mon Feb 23 09:41:44 +07 2026【41:3†agenda_all_bundle.txt†L1-L4】.
# Modello Client esistente (campi minimi già definiti lato contratti): id, business_id, first_name, last_name, email, phone, gender, birth_date, city, notes, created_at, last_visit, loyalty_points, tags, is_archived【45:4†agenda_all_bundle.txt†L32-L50】.
# Regole agent: non deploy produzione senza richiesta; non modificare schema senza migrazione; no breaking API; documentare in docs/api_contract_v1.md【45:2†agenda_all_bundle.txt†L62-L78】.

---

## 0) Setup operativo (obbligatorio)

1. Crea un branch dedicato: `feat/crm-pro`.
2. Esegui test baseline e salva output:
   - `agenda_core`: `composer install`, `./vendor/bin/phpunit --testdox`.
   - `agenda_backend` + `agenda_frontend`: `flutter pub get`, `flutter analyze`, `flutter test`.
3. Crea “restore point” (tag git locale) prima di iniziare: `backup/pre-crm-pro`.
4. Mantieni tutte le behavior esistenti: nessuna regressione su agenda, booking, drag, overlay, autoscroll, ecc.

---

## 1) CRM: feature-set target (definizione “professionale”)

Implementa queste macro-aree (tutte):

A. **Anagrafica Cliente 360°**
- Dati base + contatti multipli (email/telefono multipli), indirizzi, note strutturate, preferenze.
- Consensi (marketing, profilazione) + canale preferito.
- Identità e deduplica (merge contatti duplicati).

B. **Timeline / Interazioni**
- Log eventi: prenotazioni, cancellazioni, no-show, pagamenti, note operatore, chiamate, messaggi, campagne, ticket/issue.
- Allegati (facoltativo v1): link o file metadata (non serve storage binario subito).

C. **Segmentazione & Ricerca**
- Filtri combinabili: tag, città, last_visit range, spesa, numero visite, compleanni, consensi, stato (attivo/archiviato), fonte acquisizione.
- Saved segments (liste dinamiche) + export.

D. **Task & Follow-up**
- Task per staff (es: richiamare, inviare promo, recupero cliente inattivo).
- Scadenze + reminder (UI). Notifica vera può arrivare dopo (v1: lista + badge + “in ritardo”).

E. **Loyalty & RFM (base)**
- Loyalty points già presente: rendilo consistente con transazioni (ledger).
- Calcola KPI: total_spent, visits_count, avg_ticket, last_visit, recency/frequency/monetary.

F. **Comunicazioni**
- Template messaggi (WhatsApp/SMS/Email) e “message draft”.
- Log invii (anche se l’invio reale è esterno, traccia lo storico).
- Opt-out e compliance.

G. **GDPR / Privacy**
- Esportazione dati cliente (JSON/ZIP placeholder) + cancellazione/anonimizzazione.
- Audit trail: chi ha fatto cosa e quando (operatore/staff).

H. **Import/Export**
- Import CSV con mapping colonne e preview.
- Export CSV segmenti.

---

## 2) Data model: estensione DB (agenda_core)

### 2.1 Tabelle nuove (tutte multi-tenant per business_id)

Crea migrazioni SQL (file nella cartella migrazioni standard del progetto) per:

1) `client_contacts`
- id PK
- business_id (idx)
- client_id (idx)
- type ENUM('email','phone','whatsapp','instagram','facebook','other')
- value VARCHAR
- is_primary TINYINT
- is_verified TINYINT
- created_at, updated_at
- UNIQUE(business_id, type, value) per prevenire duplicati hard.

2) `client_addresses`
- id PK
- business_id, client_id (idx)
- label (es: casa/lavoro)
- line1, line2, city, province, postal_code, country
- created_at, updated_at

3) `client_consents`
- id PK
- business_id, client_id (idx)
- marketing_opt_in TINYINT
- profiling_opt_in TINYINT
- preferred_channel ENUM('whatsapp','sms','email','phone','none')
- updated_by_user_id (nullable)
- updated_at
- source VARCHAR (es: “frontend-form”, “backend-operator”)

4) `client_tags`
- id PK
- business_id (idx)
- name VARCHAR (case-insensitive unique per business)
- color VARCHAR nullable (solo UI)
- created_at

5) `client_tag_links`
- business_id (idx)
- client_id (idx)
- tag_id (idx)
- created_at
- UNIQUE(business_id, client_id, tag_id)

6) `client_events` (timeline)
- id PK
- business_id (idx)
- client_id (idx)
- event_type ENUM('booking_created','booking_cancelled','booking_no_show','payment','note','task','message','campaign','merge','gdpr_export','gdpr_delete')
- payload JSON (schema per tipo)
- occurred_at DATETIME (idx)
- created_by_user_id (nullable)
- created_at

7) `client_tasks`
- id PK
- business_id (idx)
- client_id (idx)
- assigned_staff_id (idx, nullable)
- title VARCHAR
- description TEXT nullable
- due_at DATETIME (idx)
- status ENUM('open','done','cancelled') (idx)
- priority ENUM('low','medium','high')
- created_by_user_id
- created_at, updated_at, completed_at nullable

8) `client_loyalty_ledger`
- id PK
- business_id (idx)
- client_id (idx)
- delta_points INT (positivo/negativo)
- reason ENUM('manual','booking','promotion','refund','adjustment')
- ref_type ENUM('booking','appointment','payment','other') nullable
- ref_id INT nullable
- created_by_user_id nullable
- created_at
- NOTE: dopo il ledger, `clients.loyalty_points` diventa un cache/denormalizzato (aggiornato transazionalmente).

9) `client_merge_map` (dedup/merge)
- id PK
- business_id (idx)
- source_client_id (idx)
- target_client_id (idx)
- merged_at
- merged_by_user_id
- UNIQUE(business_id, source_client_id)

### 2.2 Estensioni tabella `clients` (senza rompere contratti esistenti)
Aggiungi campi (tutti nullable o con default safe):
- `status` ENUM('lead','active','inactive','lost') DEFAULT 'active'
- `source` VARCHAR nullable (es: “walk-in”, “instagram”, “ads”)
- `company_name` VARCHAR nullable (B2B/aziende)
- `vat_number` VARCHAR nullable
- `address_city` (se già c’è `city` mantieni `city` come primary; non rinominare nulla)
- `deleted_at` DATETIME nullable (soft delete per GDPR)
- `updated_at` DATETIME

Non eliminare `tags` JSON/list se già usata nei client DTO: mantienila compatibile e poi migra internamente verso `client_tags` (vedi 2.4).

### 2.3 Indici e performance
- Indice composto per ricerche frequenti:
  - `clients(business_id, is_archived, last_visit)`
  - `client_events(business_id, client_id, occurred_at)`
  - `client_tasks(business_id, status, due_at)`
  - `client_contacts(business_id, type, value)`
- Fulltext (opzionale) su `clients(first_name,last_name,email,phone,notes)` se MySQL config lo consente; altrimenti LIKE ottimizzato.

### 2.4 Migrazione dati “tags”
- Se `clients.tags` esiste come lista stringhe (da contract【45:4†agenda_all_bundle.txt†L48-L49】):
  1. Popola `client_tags` con i tag distinti per business.
  2. Popola `client_tag_links` per ogni cliente.
  3. Mantieni `clients.tags` in output API per retrocompatibilità, ricostruendolo da join.
  4. Mantieni in input API la possibilità di inviare `tags: []` e sincronizza links.

---

## 3) API design (agenda_core)

### 3.1 Endpoints nuovi (versione v1, no breaking)
Aggiungi sotto `/v1/businesses/{businessId}`:

**Client master**
- GET `/clients` con query params:
  - `q` (search)
  - `status`, `is_archived`
  - `tag_ids`, `tag_names`
  - `last_visit_from`, `last_visit_to`
  - `spent_from`, `spent_to`
  - `visits_from`, `visits_to`
  - `birthday_month`
  - `marketing_opt_in`, `profiling_opt_in`
  - `sort` (es: `last_visit_desc`, `name_asc`, `spent_desc`)
  - `page`, `page_size`
- POST `/clients` create
- GET `/clients/{clientId}`
- PATCH `/clients/{clientId}` update parziale
- POST `/clients/{clientId}/archive`
- POST `/clients/{clientId}/unarchive`

**Contacts**
- GET `/clients/{clientId}/contacts`
- POST `/clients/{clientId}/contacts`
- PATCH `/clients/{clientId}/contacts/{contactId}`
- DELETE `/clients/{clientId}/contacts/{contactId}`
- POST `/clients/{clientId}/contacts/{contactId}/make-primary`

**Consents**
- GET `/clients/{clientId}/consents`
- PUT `/clients/{clientId}/consents` (idempotente)

**Tags**
- GET `/client-tags`
- POST `/client-tags`
- DELETE `/client-tags/{tagId}` (solo se non linkato, oppure con `force=true` che rimuove links)
- PUT `/clients/{clientId}/tags` (sostituzione completa)
- POST `/clients/{clientId}/tags/{tagId}` (add)
- DELETE `/clients/{clientId}/tags/{tagId}` (remove)

**Timeline / Events**
- GET `/clients/{clientId}/events` (paginato, sort occurred_at desc)
- POST `/clients/{clientId}/events` (solo `note` e `message` manuali; gli altri eventi sono generati da sistema)

**Tasks**
- GET `/clients/{clientId}/tasks`
- POST `/clients/{clientId}/tasks`
- PATCH `/clients/{clientId}/tasks/{taskId}`
- POST `/clients/{clientId}/tasks/{taskId}/complete`
- POST `/clients/{clientId}/tasks/{taskId}/reopen`

**Loyalty**
- GET `/clients/{clientId}/loyalty` (points + ledger)
- POST `/clients/{clientId}/loyalty/adjust` (delta + reason manual)

**Merge / Dedup**
- GET `/clients/dedup/suggestions?q=...` (ritorna possibili duplicati per email/phone/similarity)
- POST `/clients/{sourceClientId}/merge-into/{targetClientId}`

**GDPR**
- POST `/clients/{clientId}/gdpr/export` → ritorna jobId o direttamente JSON se piccolo
- POST `/clients/{clientId}/gdpr/delete` → soft delete + anonymize + event log

### 3.2 Contratto errori
- Usa formato error standard del progetto (identico agli endpoint esistenti). Per ogni endpoint:
  - 400 validation
  - 401/403 auth/permessi
  - 404 not found
  - 409 conflict (duplicate contact, merge invalid, tag in uso)
  - 422 business rules (es: cannot delete tag used without force)
  - 500 unexpected
- Non esporre stacktrace.

### 3.3 Permission model
- Tutte le query sono sempre filtrate per `business_id` (multi-tenant).
- Client visibili solo al business (già richiesto nel docs snippet)【41:5†agenda_all_bundle.txt†L1-L4】.
- Log events e tasks: rispettare same boundary.

### 3.4 Event sourcing minimo (hook sugli eventi esistenti)
Quando accadono:
- booking created/updated/cancelled
- appointment rescheduled
- payment recorded (se esiste)
scrivi su `client_events` in transazione o subito dopo commit.
Nota: esiste “webhook infrastructure” preparatoria e non ancora il dispatcher【41:5†agenda_all_bundle.txt†L5-L15】. Non implementare dispatcher ora: limita a scrivere `client_events` e (opzionale) a registrare un “pending delivery” se già previsto.

### 3.5 Documentazione
Aggiorna `docs/api_contract_v1.md` con:
- nuovi endpoint
- esempi request/response JSON
- paginazione standard
- note retrocompatibilità `Client.tags` list in output【45:4†agenda_all_bundle.txt†L48-L49】.

---

## 4) Backend UI (agenda_backend): CRM completo

### 4.1 IA di navigazione
Aggiungi sezione menu: **CRM** con sottosezioni:
- Clienti
- Segmenti
- Task
- Tag
- Import/Export

### 4.2 Schermate richieste (tutte)
1) **Clienti (lista)**
- Search box (q) + filtri avanzati + sort
- Bulk actions: aggiungi tag, archivia, export CSV
- Colonne: Nome, Contatto primario, Ultima visita, Spesa totale, Visite, Stato, Tag
- Paginazione “infinite scroll” o paged.

2) **Cliente dettaglio (tabs)**
- Overview: KPI + stato + tag + consensi + note rapide
- Timeline: `client_events` (infinite scroll)
- Prenotazioni: lista booking/appointments correlati (riusa provider esistenti)
- Task: CRUD + assegnazione staff + scadenze
- Contatti/Indirizzi
- Loyalty: saldo + ledger + adjustment
- GDPR: export, delete (con doppia conferma)

3) **Tag management**
- Lista tag + create/edit colore + delete con guardrail

4) **Task board**
- Vista per staff/cliente + filtri “oggi”, “in ritardo”, “questa settimana”
- Azioni rapide complete/reopen

5) **Segment builder**
- UI per salvare un segmento (nome + filtri)
- Preview count
- Export segmento

6) **Import CSV**
- Upload file (web) / choose file (desktop)
- Mapping colonne → preview 20 righe
- Validazione e report errori
- Dry-run + commit
- Post-import: dedup suggerimenti.

### 4.3 Architettura Riverpod (coerente con esistente)
- Modelli in `lib/core/models`:
  - `Client`, `ClientContact`, `ClientAddress`, `ClientConsent`, `ClientEvent`, `ClientTask`, `ClientTag`, `ClientLoyaltyEntry`, `ClientKpi`.
- ApiClient in `lib/core/network/api_client.dart`: aggiungi metodi per i nuovi endpoint.
- Repository dedicati:
  - `clients_repository.dart`
  - `client_tags_repository.dart`
  - `client_tasks_repository.dart`
  - `client_events_repository.dart`
  - `client_loyalty_repository.dart`
  - `client_import_repository.dart`
- Provider:
  - `clientsProvider` (lista + filtri)
  - `clientDetailProvider(clientId)`
  - `clientEventsProvider(clientId)`
  - `clientTasksProvider(clientId)`
  - `clientTagsProvider`
  - `overdueTasksProvider`
- Controller Notifier:
  - `ClientUpsertController`
  - `ClientMergeController`
  - `ClientTaskController`
  - `ClientTagController`
  - `ClientConsentController`
  - `ClientImportController`
- Invalidate mirata come già fatto per Class Events (pattern di invalidazione)【41:0†agenda_all_bundle.txt†L46-L49】.

### 4.4 UX Quality bar
- Empty/error states curati.
- Loading skeleton (senza shimmer/splash/ripple: nessun effetto tap).
- Dialog conferma per azioni distruttive.
- Accessibility: focus order, label, keyboard web.
- Performance: debounce search (300ms), cache provider keepAlive dove serve.

---

## 5) Frontend booking (agenda_frontend): solo ciò che serve al CRM

Implementa solo:
- Gestione consensi (marketing/profilazione) nel profilo cliente se esiste login/identità cliente.
- Preferenze canale contatto (preferred_channel).
- Self-service data export request (facoltativo v1).

Non introdurre nuove dipendenze né cambiare flow di prenotazione.

---

## 6) Dedup & Merge: regole

### 6.1 Suggestion engine (server-side)
- Heuristics:
  - match esatto su email normalizzata (lowercase, trim)
  - match esatto su phone normalizzato (E.164 se possibile; altrimenti digits-only)
  - similarity su (first_name,last_name,birth_date,city) con score.
- Endpoint `dedup/suggestions` deve restituire:
  - candidate_client_id
  - match_reasons []
  - score 0..100
  - preview fields (nome, contatto, last_visit)

### 6.2 Merge operation
- `source` → `target`
- Move:
  - contacts, addresses, tags links (merge unique)
  - tasks, events (repoint to target_client_id)
  - bookings/appointments: NON spostare id storici se vincolati, ma assicurare che le viste “cliente” includano anche source (via merge map) oppure repoint se safe. Scegli una sola strategia e applicala ovunque:
    - Strategia consigliata: repoint in DB tutte le foreign key su client_id dove possibile; per tabelle legacy dove non vuoi toccare, usa `client_merge_map` per risolvere “effective client id” in query.
- Logga `client_events` tipo `merge` con payload {source,target,by}.
- Marca source come `is_archived=1` e `status='lost'` + `deleted_at` NULL (non GDPR delete).
- Protezioni:
  - impedisci merge cross-business
  - impedisci merge se source==target
  - gestisci conflict su contatti unique.

---

## 7) KPI & Reporting (CRM analytics base)

### 7.1 KPI per cliente (server-side, cache)
- `visits_count` (numero booking completate)
- `total_spent`
- `avg_ticket`
- `last_visit`
- `no_show_count`
- `cancellation_rate` (opzionale)
- `rfm_segment` (A/B/C o 1..5)
Persisti in tabella `client_kpis` (opzionale) oppure calcola on demand con caching in memory. Se DB grande, usa tabella.

### 7.2 Segmenti salvati
- Tabella `client_segments`:
  - id, business_id, name, filters_json, created_at, updated_at
- Endpoint list/create/update/delete.
- UI builder: salva filtri esattamente come query params.

---

## 8) Compliance & audit

1. Aggiungi audit min:
- In `client_events` per note/task/consent: `created_by_user_id` o `updated_by_user_id`.
2. GDPR delete:
- Anonimizza PII: first_name, last_name, email, phone, addresses, contacts -> null/placeholder.
- Conserva solo dati aggregati non identificanti (per contabilità interna, se richiesto).
- Imposta `deleted_at` e `status='lost'`, `is_archived=1`.
- Log event `gdpr_delete`.

---

## 9) Test (agenda_core) — obbligatori

Scrivi test PHPUnit per:
- Creazione/Update client con validation.
- Contacts unique constraint e make-primary.
- Consents idempotency.
- Tags CRUD + link/unlink + retro `tags` list.
- Events create note, list pagination.
- Tasks CRUD + overdue query.
- Loyalty ledger adjust e aggiornamento cache points.
- Dedup suggestion e merge (incl. conflict).
- GDPR export e delete (anonimizzazione).

Frontend: test minimi di rendering + provider compile (no test pesanti).

---

## 10) Deliverables finali (output richiesto)

1. Migrazioni DB complete + note rollback.
2. Endpoint API implementati + aggiornamento `docs/api_contract_v1.md`.
3. UI CRM in agenda_backend completa (lista, dettaglio tabs, task board, tags, segments, import).
4. Nessuna regressione: test suite verde.
5. Changelog tecnico: `docs/CRM_PRO_CHANGELOG.md` con:
   - tabelle nuove
   - endpoint
   - scelte di merge strategy
   - limiti noti v1.

---

## 11) Sequenza di lavoro consigliata (evita caos)

1) DB migrazioni + model/repo server (no UI)
2) Endpoint list/detail client + tags + consents
3) Timeline events auto-hook su booking
4) Tasks + overdue
5) Loyalty ledger
6) Dedup/merge
7) GDPR
8) Segmenti salvati
9) Import CSV
10) UI completa + rifiniture

---

## 12) Acceptance checklist (tutto deve essere vero)

- [ ] GET clients con filtri combinati funziona e scala.
- [ ] Client dettaglio mostra KPI e timeline coerente.
- [ ] Tag gestiti centralmente, sync con output `Client.tags`.
- [ ] Task: scadenze, overdue, complete, reopen.
- [ ] Merge: nessun dato perso, log evento, no duplicati contatto.
- [ ] GDPR delete: PII rimossa e non recuperabile via API.
- [ ] Tutti i test core passano.
- [ ] Nessun mock reintrodotto.
- [ ] Nessuna breaking change su booking/agenda.

