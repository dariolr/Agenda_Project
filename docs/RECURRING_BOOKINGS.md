# Appuntamenti Ricorrenti - Specifica Implementazione

**Data**: 23 gennaio 2026  
**Stato**: Da implementare  
**Progetti coinvolti**: agenda_core, agenda_backend

---

## ⚠️ AMBIENTE DI SVILUPPO

**L'implementazione deve essere eseguita SOLO in ambiente locale (MAMP).**

- NON eseguire deploy su staging o produzione fino ad approvazione esplicita
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

### 2.3 File migrazione

Creare: `agenda_core/migrations/0030_recurring_bookings.sql`

---

## 3. Opzioni Ricorrenza

| Frequenza | `frequency` | `interval_value` | Esempio |
|-----------|-------------|------------------|---------|
| Ogni giorno | `daily` | 1 | Ogni giorno |
| Ogni X giorni | `daily` | X | Ogni 3 giorni |
| Ogni settimana | `weekly` | 1 | Ogni lunedì (stesso giorno) |
| Ogni X settimane | `weekly` | X | Ogni 2 settimane |
| Ogni mese | `monthly` | 1 | Ogni 15 del mese |
| Ogni X mesi | `monthly` | X | Ogni 2 mesi il giorno 15 |
| Personalizzata | `custom` | X | Ogni X giorni esatti |

---

## 4. Gestione Conflitti

### 4.1 Strategia `skip` (default)

- Verifica disponibilità staff per ogni data calcolata
- Se staff NON disponibile → **salta** questa occorrenza
- Continua con la data successiva
- Al termine: mostra riepilogo date create + date saltate

### 4.2 Strategia `force`

- **NON** verifica disponibilità staff
- Crea **sempre** la prenotazione anche se c'è sovrapposizione
- Imposta `has_conflict = 1` sulle prenotazioni con sovrapposizione
- L'operatore è responsabile di gestire manualmente i conflitti

### 4.3 UI per selezione strategia

```
☐ Prenotazione ricorrente

Ripeti: [Settimanale ▼]  Ogni: [1] settimane

Termina: ○ Dopo [10] occorrenze
         ○ Il [__/__/____]

⚠️ Gestione conflitti:
   ○ Salta date con staff non disponibile (consigliato)
   ○ Crea comunque (permetti sovrapposizioni)
```

---

## 5. API Endpoints (agenda_core)

### 5.1 Creazione prenotazione ricorrente

```
POST /v1/bookings/recurring
Authorization: Bearer {token}
```

**Request body:**
```json
{
  "location_id": 1,
  "client_id": 42,
  "notes": "Trattamento mensile",
  "items": [
    {
      "service_id": 1,
      "staff_id": 3,
      "start_time": "10:00"
    }
  ],
  "start_date": "2026-01-27",
  "recurrence": {
    "frequency": "weekly",
    "interval": 1,
    "max_occurrences": 10,
    "end_date": null,
    "conflict_strategy": "skip"
  }
}
```

**Response (success):**
```json
{
  "success": true,
  "data": {
    "recurrence_rule_id": 5,
    "created_bookings": [
      {"id": 101, "date": "2026-01-27", "has_conflict": false},
      {"id": 102, "date": "2026-02-03", "has_conflict": false},
      {"id": 103, "date": "2026-02-10", "has_conflict": false}
    ],
    "skipped_dates": [
      {"date": "2026-02-17", "reason": "Staff non disponibile"}
    ],
    "total_created": 3,
    "total_skipped": 1
  }
}
```

### 5.2 Ottenere serie completa

```
GET /v1/bookings/{id}/series
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "recurrence_rule": {
      "id": 5,
      "frequency": "weekly",
      "interval": 1,
      "max_occurrences": 10,
      "conflict_strategy": "skip"
    },
    "bookings": [
      {"id": 101, "date": "2026-01-27", "status": "confirmed", "recurrence_index": 0},
      {"id": 102, "date": "2026-02-03", "status": "confirmed", "recurrence_index": 1},
      {"id": 103, "date": "2026-02-10", "status": "cancelled", "recurrence_index": 2}
    ]
  }
}
```

### 5.3 Modificare serie

```
PATCH /v1/bookings/{id}/series
Authorization: Bearer {token}
```

**Request body:**
```json
{
  "scope": "this_and_future",
  "changes": {
    "staff_id": 4,
    "start_time": "11:00"
  }
}
```

**Valori `scope`:**
- `this_only` - Solo questa occorrenza
- `this_and_future` - Questa e tutte le future
- `all` - Tutta la serie (anche passate non completate)

### 5.4 Cancellare serie

```
DELETE /v1/bookings/{id}/series?scope=this_and_future
Authorization: Bearer {token}
```

---

## 6. Use Cases (agenda_core)

### 6.1 CreateRecurringBooking

**File:** `src/UseCases/Booking/CreateRecurringBooking.php`

**Logica:**
```
1. Valida input (location, client, items, recurrence)
2. Crea record in booking_recurrence_rules
3. Calcola tutte le date in base a frequency/interval/max_occurrences/end_date
4. Per ogni data:
   a. Se conflict_strategy == 'skip':
      - Verifica disponibilità con ComputeAvailability
      - Se NON disponibile: aggiungi a skipped_dates, continua
   b. Crea booking con:
      - recurrence_rule_id
      - recurrence_index
      - is_recurrence_parent = true (solo per index 0)
      - has_conflict = true (se force e c'era conflitto)
   c. Crea booking_items
   d. Accoda notifica email (se configurato)
5. Ritorna riepilogo
```

### 6.2 ModifyRecurringSeries

**File:** `src/UseCases/Booking/ModifyRecurringSeries.php`

### 6.3 DeleteRecurringSeries

**File:** `src/UseCases/Booking/DeleteRecurringSeries.php`

---

## 7. UI Gestionale (agenda_backend)

### 7.1 Modifiche a `booking_dialog.dart`

1. **Aggiungere sezione ricorrenza** (collassabile, sotto la data):
   ```dart
   ExpansionTile(
     title: Text('Prenotazione ricorrente'),
     leading: Icon(Icons.repeat),
     children: [
       // Dropdown frequenza
       // Campo intervallo
       // Radio termina dopo X / termina il
       // Radio strategia conflitti
       // Preview date
     ],
   )
   ```

2. **Provider per calcolo preview date:**
   ```dart
   final recurrencePreviewProvider = Provider.family<List<DateTime>, RecurrenceParams>(...);
   ```

3. **Al salvataggio:**
   - Se ricorrenza attiva: chiama `POST /v1/bookings/recurring`
   - Mostra dialog riepilogo con date create/saltate

### 7.2 Visualizzazione in agenda

1. **Icona ricorrenza** su `AppointmentCard`:
   ```dart
   if (appointment.booking?.recurrenceRuleId != null)
     Icon(Icons.repeat, size: 12)
   ```

2. **Tooltip con info serie:**
   ```
   "Appuntamento ricorrente (3/10)
   Serie: Ogni settimana
   Prossimo: 03/02/2026"
   ```

3. **Menu contestuale** (click destro o long press):
   - "Modifica solo questo"
   - "Modifica questo e futuri"
   - "Modifica tutta la serie"
   - "Cancella solo questo"
   - "Cancella questo e futuri"
   - "Cancella tutta la serie"

### 7.3 Nuovi file da creare

```
lib/features/agenda/presentation/widgets/
├── recurrence_picker.dart          # Widget selezione ricorrenza
├── recurrence_preview.dart         # Preview date calcolate
└── recurrence_summary_dialog.dart  # Riepilogo post-creazione

lib/features/agenda/domain/
└── recurrence_rule.dart            # Model RecurrenceRule

lib/features/agenda/providers/
└── recurrence_providers.dart       # Provider per ricorrenza
```

---

## 8. Model Dart

### 8.1 RecurrenceRule

```dart
enum RecurrenceFrequency { daily, weekly, monthly, custom }
enum ConflictStrategy { skip, force }

class RecurrenceRule {
  final int? id;
  final RecurrenceFrequency frequency;
  final int interval;
  final int? maxOccurrences;
  final DateTime? endDate;
  final ConflictStrategy conflictStrategy;

  // Calcolate
  List<DateTime> calculateDates(DateTime startDate) { ... }
}
```

### 8.2 Estensione Booking

```dart
class Booking {
  // ... campi esistenti ...
  
  // Nuovi campi
  final int? recurrenceRuleId;
  final int? recurrenceIndex;
  final bool isRecurrenceParent;
  final bool hasConflict;
  
  bool get isRecurring => recurrenceRuleId != null;
}
```

---

## 9. Localizzazione

### Chiavi da aggiungere in `intl_it.arb` e `intl_en.arb`:

```json
{
  "recurringBooking": "Prenotazione ricorrente",
  "repeatEvery": "Ripeti ogni",
  "days": "giorni",
  "weeks": "settimane", 
  "months": "mesi",
  "endAfterOccurrences": "Termina dopo {count} occorrenze",
  "endOnDate": "Termina il",
  "conflictStrategySkip": "Salta date con staff non disponibile",
  "conflictStrategyForce": "Crea comunque (permetti sovrapposizioni)",
  "recurrenceSummaryTitle": "Riepilogo prenotazioni",
  "bookingsCreated": "{count} prenotazioni create",
  "datesSkipped": "{count} date saltate per indisponibilità",
  "modifyOnlyThis": "Modifica solo questa",
  "modifyThisAndFuture": "Modifica questa e future",
  "modifyAllSeries": "Modifica tutta la serie",
  "cancelOnlyThis": "Cancella solo questa",
  "cancelThisAndFuture": "Cancella questa e future",
  "cancelAllSeries": "Cancella tutta la serie",
  "recurringAppointment": "Appuntamento ricorrente ({current}/{total})",
  "hasConflictWarning": "⚠️ Sovrapposizione con altro appuntamento"
}
```

---

## 10. Limiti e Validazioni

| Parametro | Limite | Motivo |
|-----------|--------|--------|
| `max_occurrences` | Max 52 | ~1 anno settimanale |
| `end_date` | Max 1 anno da oggi | Evita creazione massiva |
| `interval_value` | 1-365 per daily, 1-52 per weekly, 1-12 per monthly | Valori ragionevoli |
| Prenotazioni per singola chiamata | Max 52 | Performance |

---

## 11. Notifiche Email

- **Creazione serie**: Email singola di riepilogo al cliente con tutte le date
- **Reminder**: Reminder standard per ogni singola occorrenza
- **Cancellazione serie**: Email con elenco date cancellate
- **Conflitti (force)**: Nessuna notifica automatica (gestione manuale)

---

## 12. Ordine di Implementazione

### Fase 1: Database + API base (agenda_core)
1. [ ] Creare migrazione `0030_recurring_bookings.sql`
2. [ ] Eseguire migrazione su DB locale
3. [ ] Creare model `RecurrenceRule` in PHP
4. [ ] Creare `RecurrenceRuleRepository`
5. [ ] Estendere `BookingRepository` con campi ricorrenza
6. [ ] Creare `CreateRecurringBooking` UseCase
7. [ ] Creare endpoint `POST /v1/bookings/recurring`
8. [ ] Test con curl/Postman

### Fase 2: API complete (agenda_core)
9. [ ] Creare `GetBookingSeries` UseCase
10. [ ] Creare endpoint `GET /v1/bookings/{id}/series`
11. [ ] Creare `ModifyRecurringSeries` UseCase
12. [ ] Creare endpoint `PATCH /v1/bookings/{id}/series`
13. [ ] Creare `DeleteRecurringSeries` UseCase
14. [ ] Creare endpoint `DELETE /v1/bookings/{id}/series`

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
29. [ ] Deploy staging
30. [ ] Test su staging
31. [ ] Deploy produzione

---

## 13. Note Implementazione

### Da NON fare:
- NON modificare il flow di prenotazione esistente (single booking)
- NON creare ricorrenze dal frontend clienti (solo gestionale)
- NON inviare notifiche per date saltate
- NON permettere ricorrenza su prenotazioni già esistenti

### Attenzione a:
- Timezone: tutte le date devono rispettare timezone della location
- Performance: usare batch insert per le prenotazioni
- Idempotenza: ogni booking della serie ha il proprio `idempotency_key`
- Audit: registrare evento `booking_series_created` in `booking_events`

---

**Per avviare l'implementazione, richiedere esplicitamente quale fase eseguire.**
