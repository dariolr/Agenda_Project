# Appuntamenti Ricorrenti - Specifica Implementazione

**Data**: 23 gennaio 2026  
**Stato**: In corso - Fase 2 completata  
**Progetti coinvolti**: agenda_core, agenda_backend

---

## ⚠️ AMBIENTE DI SVILUPPO

**L'implementazione deve essere eseguita SOLO in ambiente locale (MAMP).**

- NON eseguire deploy su produzione fino ad approvazione esplicita
- Testare tutte le funzionalità su `http://localhost:8888/api/`
- Database locale: MySQL su porta 8889 (MAMP)
- Usare `./scripts/deploy-local.sh` per deploy locale

---

## 1. Obiettivo

Permettere agli operatori del gestionale di creare prenotazioni ricorrenti (giornaliere, settimanali, mensili o ogni X giorni) con possibilità di gestire i conflitti di disponibilità.

---

## 2. Schema Database

### 2.1 Nuova tabella: `booking_recurrence_rules`

```sql
CREATE TABLE booking_recurrence_rules (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    
    -- Pattern ricorrenza
    frequency ENUM('daily', 'weekly', 'monthly', 'custom') NOT NULL,
    interval_value INT UNSIGNED NOT NULL DEFAULT 1 
        COMMENT 'Ogni X giorni/settimane/mesi',
    
    -- Limiti
    max_occurrences INT UNSIGNED DEFAULT NULL 
        COMMENT 'Numero massimo di ripetizioni (NULL = infinito)',
    end_date DATE DEFAULT NULL 
        COMMENT 'Data fine ricorrenza (NULL = usa max_occurrences)',
    
    -- Gestione conflitti
    conflict_strategy ENUM('skip', 'force') NOT NULL DEFAULT 'skip'
        COMMENT 'skip = salta date con conflitto, force = crea comunque con sovrapposizione',
    
    -- Opzioni avanzate (per estensioni future)
    days_of_week JSON DEFAULT NULL 
        COMMENT 'Per weekly multi-day: [1,3,5] = Lun,Mer,Ven',
    day_of_month INT UNSIGNED DEFAULT NULL 
        COMMENT 'Per monthly: giorno del mese (1-31)',
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id),
    KEY idx_recurrence_business (business_id),
    CONSTRAINT fk_recurrence_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Regole di ricorrenza per prenotazioni ripetute';
```

### 2.2 Modifica tabella `bookings`

```sql
ALTER TABLE bookings 
ADD COLUMN recurrence_rule_id INT UNSIGNED DEFAULT NULL 
    COMMENT 'FK a booking_recurrence_rules se ricorrente',
ADD COLUMN recurrence_index INT UNSIGNED DEFAULT NULL 
    COMMENT 'Indice occorrenza nella serie (0 = prima, 1 = seconda, ...)',
ADD COLUMN is_recurrence_parent TINYINT(1) NOT NULL DEFAULT 0 
    COMMENT 'True se è la prenotazione "madre" della serie',
ADD COLUMN has_conflict TINYINT(1) NOT NULL DEFAULT 0
    COMMENT 'True se creata con conflict_strategy=force nonostante sovrapposizione',
ADD KEY idx_bookings_recurrence (recurrence_rule_id),
ADD KEY idx_bookings_recurrence_parent (recurrence_rule_id, is_recurrence_parent),
ADD CONSTRAINT fk_bookings_recurrence FOREIGN KEY (recurrence_rule_id) 
    REFERENCES booking_recurrence_rules(id) ON DELETE SET NULL;
```

---

## 3. API Endpoints

### 3.1 Creare Serie Ricorrente

```
POST /v1/locations/{location_id}/bookings/recurring
Authorization: Bearer {token}
```

**Payload (staff singolo):**
```json
{
  "service_ids": [148, 149],
  "staff_id": 14,
  "start_time": "2026-01-15T10:00:00",
  "client_id": 42,
  "notes": "Cliente abituale",
  "frequency": "weekly",
  "interval_value": 2,
  "max_occurrences": 6,
  "end_date": null,
  "conflict_strategy": "skip"
}
```

**Payload (multi-staff per servizio):** 🆕
```json
{
  "service_ids": [148, 149],
  "staff_by_service": {
    "148": 14,
    "149": 15
  },
  "start_time": "2026-01-15T10:00:00",
  "client_id": 42,
  "notes": "Cliente abituale",
  "frequency": "weekly",
  "interval_value": 2,
  "max_occurrences": 6
}
```

| Campo | Tipo | Obbligatorio | Descrizione |
|-------|------|--------------|-------------|
| `service_ids` | int[] | ✅ | Lista ID servizi |
| `staff_id` | int | ⚠️ | Staff unico per tutti i servizi (alternativo a `staff_by_service`) |
| `staff_by_service` | object | ⚠️ | Mappa service_id → staff_id per multi-staff |
| `start_time` | ISO8601 | ✅ | Data/ora prima occorrenza |
| `client_id` | int | ❌ | ID cliente (opzionale) |
| `notes` | string | ❌ | Note prenotazione |
| `frequency` | enum | ✅ | `daily`, `weekly`, `monthly`, `custom` |
| `interval_value` | int | ❌ | Intervallo (default 1) |
| `max_occurrences` | int | ❌ | Numero massimo ripetizioni |
| `end_date` | date | ❌ | Data fine (alternativa a `max_occurrences`) |
| `conflict_strategy` | enum | ❌ | `skip` (default) o `force` |

⚠️ **Nota**: Specificare `staff_id` OPPURE `staff_by_service`, non entrambi.

**Response:**
```json
{
  "recurrence_rule_id": 5,
  "created_count": 6,
  "skipped_count": 0,
  "bookings": [
    {
      "id": 101,
      "recurrence_index": 0,
      "start_time": "2026-01-15T10:00:00",
      "status": "confirmed"
    },
    ...
  ]
}
```

### 3.2 Leggere Serie

```
GET /v1/bookings/recurring/{rule_id}
Authorization: Bearer {token}
```

**Response:**
```json
{
  "rule": {
    "id": 5,
    "frequency": "weekly",
    "interval_value": 2,
    "max_occurrences": 6,
    "end_date": null,
    "conflict_strategy": "skip"
  },
  "bookings": [
    {
      "id": 101,
      "recurrence_index": 0,
      "start_time": "2026-01-15T10:00:00",
      "status": "confirmed",
      "items": [...]
    },
    ...
  ],
  "total_count": 6
}
```

### 3.3 Modificare Serie

```
PATCH /v1/bookings/recurring/{rule_id}
Authorization: Bearer {token}
```

**Query params:**
- `scope` = `all` | `future` (obbligatorio)
- `from_index` = N (obbligatorio se scope=future)

**Payload:**
```json
{
  "staff_id": 15,
  "notes": "Note aggiornate",
  "time": "11:30"
}
```

| Campo | Descrizione |
|-------|-------------|
| `staff_id` | Cambia staff per tutti gli item della serie |
| `notes` | Aggiorna note di tutti i booking |
| `time` | Cambia orario (mantiene la data originale) |

**Esempi:**
```bash
# Cambia staff per TUTTA la serie
PATCH /v1/bookings/recurring/5?scope=all
{"staff_id": 15}

# Cambia orario solo dal booking index 2 in poi
PATCH /v1/bookings/recurring/5?scope=future&from_index=2
{"time": "14:00"}
```

### 3.4 Cancellare Serie

```
DELETE /v1/bookings/recurring/{rule_id}?scope=all|future&from_index=N
Authorization: Bearer {token}
```

**Query params:**
- `scope` = `all` (cancella tutta la serie) | `future` (cancella da index in poi)
- `from_index` = N (obbligatorio se scope=future)

**Response:**
```json
{
  "cancelled_count": 4,
  "message": "Bookings cancelled successfully"
}
```

---

## 4. Supporto Multi-Staff 🆕

### 4.1 Comportamento Attuale

L'implementazione attuale usa **un solo `staff_id`** per tutti i servizi nella serie:

```php
// CreateRecurringBooking.php - linea 237
'staff_id' => $staffId,  // Stesso staff per ogni booking_item
```

### 4.2 Proposta Estensione Multi-Staff

Per supportare staff diversi per servizio, estendere il payload:

```json
{
  "service_ids": [148, 149, 150],
  "staff_by_service": {
    "148": 14,
    "149": 15,
    "150": 14
  },
  "start_time": "2026-01-15T10:00:00",
  ...
}
```

**Logica:**
1. Se presente `staff_by_service`, usare la mappa per ogni servizio
2. Se presente solo `staff_id`, usarlo per tutti i servizi (backward compatible)
3. Se entrambi presenti, `staff_by_service` ha priorità

### 4.3 Impatto su UseCase

`CreateRecurringBooking.php` deve essere modificato:

```php
// Determinare staff per ogni servizio
$staffByService = $params['staff_by_service'] ?? null;
$defaultStaffId = $params['staff_id'] ?? null;

foreach ($serviceIds as $serviceId) {
    $itemStaffId = $staffByService[$serviceId] ?? $defaultStaffId;
    // ... crea booking_item con $itemStaffId
}
```

### 4.4 Impatto su UI (BookingDialog)

Il `BookingDialog` in agenda_backend **già supporta** staff diversi per servizio tramite `ServiceItemData`:

```dart
class ServiceItemData {
  final int? serviceId;
  final int? staffId;  // Staff specifico per questo servizio
  final TimeOfDay startTime;
  // ...
}
```

Quando si crea una serie ricorrente, costruire `staff_by_service` dai `ServiceItemData`:

```dart
final staffByService = <String, int>{};
for (final item in _serviceItems) {
  if (item.serviceId != null && item.staffId != null) {
    staffByService[item.serviceId.toString()] = item.staffId!;
  }
}

// Payload API
{
  "service_ids": serviceIds,
  "staff_by_service": staffByService,
  // ...
}
```

### 4.5 Stato Implementazione Multi-Staff

| Componente | Stato | Note |
|------------|-------|------|
| API POST (staff singolo) | ✅ | Funzionante |
| API POST (staff_by_service) | ⏳ TODO | Da implementare in CreateRecurringBooking |
| API PATCH (staff singolo) | ✅ | Funzionante |
| API PATCH (staff_by_service) | ⏳ TODO | Da implementare in ModifyRecurringSeries |
| UI BookingDialog | ⏳ TODO | Già supporta multi-staff, serve integrazione API |

---

## 12. Ordine di Implementazione

### Fase 1: Database + API base (agenda_core) ✅ COMPLETATA
1. [x] Creare migrazione `0030_recurring_bookings.sql`
2. [x] Eseguire migrazione su DB locale
3. [x] Creare model `RecurrenceRule` in PHP
4. [x] Creare `RecurrenceRuleRepository`
5. [x] Estendere `BookingRepository` con campi ricorrenza
6. [x] Creare `CreateRecurringBooking` UseCase
7. [x] Creare endpoint `POST /v1/locations/{location_id}/bookings/recurring`
8. [x] Test con curl - TUTTI PASSATI (23/01/2026)

### Fase 2: API complete (agenda_core) ✅ COMPLETATA
9. [x] Creare endpoint `GET /v1/bookings/recurring/{rule_id}` - implementato come `showRecurringSeries`
10. [ ] ~~Creare endpoint `GET /v1/bookings/{id}/series`~~ (alternativo, non necessario)
11. [x] `ModifyRecurringSeries` UseCase implementato
12. [x] Endpoint `PATCH /v1/bookings/recurring/{rule_id}` - supporta modifiche bulk (staff, notes, time)
13. [x] Endpoint DELETE implementato con scope=all|future e from_index
14. [x] `DELETE /v1/bookings/recurring/{rule_id}?scope=all|future&from_index=N`

**Endpoint implementati:**
```
POST   /v1/locations/{location_id}/bookings/recurring  - Crea serie ricorrente
GET    /v1/bookings/recurring/{rule_id}                - Legge serie completa  
PATCH  /v1/bookings/recurring/{rule_id}                - Modifica serie (scope=all|future, staff/notes/time)
DELETE /v1/bookings/recurring/{rule_id}                - Cancella serie (scope=all|future)
```

**Test completati (23/01/2026):**
- ✅ PATCH scope=all: modifica staff e note per tutta la serie
- ✅ PATCH scope=future: modifica orario solo per booking futuri (from_index)
- ✅ Verifica modifiche persistenti nel database

### Fase 3: UI creazione (agenda_backend)
15. [ ] Creare model `RecurrenceRule` Dart
16. [ ] Estendere model `Booking` con campi ricorrenza
17. [ ] Creare widget `RecurrencePicker`
18. [ ] Creare widget `RecurrencePreview`
19. [ ] Integrare in `BookingDialog`
20. [ ] Creare `RecurrenceSummaryDialog`
21. [ ] Aggiungere chiavi localizzazione

### Fase 4: UI visualizzazione e gestione (agenda_backend)
22. [ ] Mostrare icona ricorrenza su appuntamenti
23. [ ] Implementare tooltip serie
24. [ ] Implementare menu contestuale serie
25. [ ] Dialog conferma modifica/cancella serie

### Fase 5: Notifiche (agenda_core)
26. [ ] Template email riepilogo serie
27. [ ] Logica invio email serie

### Fase 6: Test e deploy
28. [ ] Test end-to-end su ambiente locale
29. [ ] Deploy produzione
