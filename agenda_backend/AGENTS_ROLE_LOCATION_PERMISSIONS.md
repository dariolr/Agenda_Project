# Agenda Backend — Role Scope per Location (AI Agent Instructions)

## 🚨 Scopo
Implementare la gestione **scope ruolo** per utente: il ruolo può essere valido **su tutto il business** oppure **solo su un sottoinsieme di location**.

**Progetto interessato:** `agenda_backend` (gestionale) + `agenda_core` (API)

**Non toccare:** `agenda_frontend`

---

## ✅ Requisiti funzionali
- Un admin può assegnare un ruolo con:
  - **Scope = business** (tutte le location)
  - **Scope = locations** (solo location selezionate)
- Per gli inviti, lo scope viene salvato e applicato al momento dell’accettazione.
- L’accesso a dati/azioni è **filtrato per location** quando scope=locations.
- Nessun fallback locale: se la location non è permessa, l’API deve negare.

---

## 🗄️ Modello dati (agenda_core)

### 1) Modifica `business_users`
Aggiungere:
- `scope_type ENUM('business','locations') NOT NULL DEFAULT 'business'`

### 2) Nuova tabella `business_user_locations`
```
- id (PK)
- business_user_id (FK → business_users.id)
- location_id (FK → locations.id)
- created_at
UNIQUE(business_user_id, location_id)
```

### 3) Inviti (consigliato pivot)
Nuova tabella `business_invitation_locations`:
```
- id (PK)
- invitation_id (FK → business_invitations.id)
- location_id (FK → locations.id)
- created_at
UNIQUE(invitation_id, location_id)
```

### 4) Migrazioni
- Nuova migrazione SQL in `agenda_core/migrations/`.
- Aggiornare `agenda_core/migrations/FULL_DATABASE_SCHEMA.sql`.
- Backfill: `scope_type='business'` per record esistenti.

---

## 🔌 API (agenda_core)

### Business Users
- `GET /v1/businesses/{business_id}/users`
  - Includere `scope_type` e `location_ids`.

- `POST /v1/businesses/{business_id}/users`
  - Accettare `scope_type` e `location_ids`.

- `PATCH /v1/businesses/{business_id}/users/{user_id}`
  - Aggiornare `scope_type` e `location_ids`.

### Invitations
- `GET /v1/businesses/{business_id}/invitations`
  - Includere `scope_type` e `location_ids`.

- `POST /v1/businesses/{business_id}/invitations`
  - Accettare `scope_type` e `location_ids`.

- `POST /v1/invitations/{token}/accept`
  - Creare `business_users` con lo stesso scope/location.

---

## 🛡️ Enforcement accesso per location (agenda_core)

### Regola
Se `scope_type=locations`, l’utente può accedere solo alle `location_id` presenti nel mapping.

### Dove applicare
- Middleware dedicato (consigliato) **oppure** estensione di `BusinessAccessMiddleware`.
- Applicare a tutte le route con `location_path` e `location_query` in `agenda_core/src/Http/Kernel.php`.

---

## 🖥️ Backend Flutter (agenda_backend)

### Modelli
- `lib/core/models/business_user.dart` → aggiungere `scopeType`, `locationIds`.
- `lib/core/models/business_invitation.dart` → aggiungere `scopeType`, `locationIds`.

### API Client
- `lib/core/network/api_client.dart`
  - Inviare/ricevere `scope_type` + `location_ids`.

### Provider
- `lib/features/business/providers/business_users_provider.dart`
  - Salvare/aggiornare scope e location_ids.

### UI gestione operatori
- `lib/features/business/presentation/dialogs/invite_operator_dialog.dart`
- `lib/features/business/presentation/dialogs/role_selection_dialog.dart`
- `lib/features/business/presentation/operators_screen.dart`

**UI richiesta:**
- Toggle: “Intero business” / “Solo alcune sedi”.
- Multi‑select location quando “Solo alcune sedi”.
- Mostrare sedi assegnate in lista utenti e inviti.

### Filtri location
- `lib/features/agenda/providers/location_providers.dart`
  - Filtrare lista location e `currentLocationIdProvider` in base alle location consentite.

### Gating sezioni
- Agenda / Clienti / Servizi / Staff / Report
  - Disabilitare o nascondere azioni se l’utente non ha accesso alla location corrente.

---

## 📊 Reportistica
- Se `scope_type=locations`, i report devono essere filtrati per location consentite.
- Verificare `agenda_core/src/Http/Controllers/ReportsController.php` e `agenda_backend/lib/features/reports/providers/reports_provider.dart`.

---

## ✅ Checklist finale
- [x] Migrazioni SQL create + FULL_DATABASE_SCHEMA aggiornato
- [x] API ritorna scope/location
- [x] Inviti gestiscono scope/location
- [ ] Middleware blocca location non autorizzate (TODO: enforcement lato API)
- [x] UI permette selezione scope/location
- [ ] App filtra location e azioni (TODO: filtro location_providers)
- [ ] Report filtrati per location (TODO: ReportsController)

