# Operator Permissions — Work Log

## Contesto

Questo documento riassume le decisioni architetturali e lo stato del lavoro sul sistema di permessi operatori. È pensato come punto di partenza per conversazioni future.

---

## Modello attuale (implementato)

### Ruoli esistenti
- `owner` / `admin` → controllo totale
- `manager` → operatività completa sul perimetro (business o sedi), nessuna restrizione su staff
- `staff` → collegato a un singolo membro del team (`staff_id`), opera solo per quel membro
- `viewer` → sola lettura

### Filtri visibilità/operatività (implementati in questa sessione)
Tre stati per `allowed_service_ids` e `allowed_class_type_ids`:
- `null` → Tutti
- `[]` → Nessuno
- `[1, 2, ...]` → Solo selezionati

I due filtri sono **indipendenti** tra loro.

**Effetti:**
- Controllano la visibilità nell'agenda (lato Flutter, client-side)
- Autorizzano o bloccano creazione/modifica/cancellazione eventi e appuntamenti (lato backend, implementato)
- Il filtro lettura lato backend (query SQL) **non è ancora implementato** (punto aperto)

### Comportamento ruolo staff (implementato)
- Il picker staff nel form di creazione programmazione lezione è bloccato al membro associato
- Il backend valida che `staff_id` negli eventi corrisponda al `linked_staff_id` dell'operatore

---

## Gap identificati nel modello attuale

1. **Nessun filtro per membro del team** — `allowed_service_ids` e `allowed_class_type_ids` controllano cosa gestisce l'operatore, ma non per quale membro del team. Non è possibile dire "questo operatore gestisce solo team A e B".

2. **Ruoli sovrapposti** — `manager` e `staff` hanno gli stessi flag di permesso per default, differiscono solo per la restrizione su `staff_id`. La distinzione è ambigua.

3. **Filtro lettura backend mancante** — gli endpoint di lettura restituiscono tutti i dati; il filtraggio avviene solo lato Flutter.

4. **`allowed_service_ids` ridondante per il ruolo `staff`** — un operatore staff è già implicitamente vincolato ai servizi del membro del team a cui è collegato (`staff_id → staff member → services`). Il filtro `allowed_service_ids` su un record `business_user` con ruolo `staff` è quindi ridondante: se si vuole restringere il perimetro, la modifica va fatta sui servizi assegnati allo staff member, non aggiungendo un secondo filtro sull'operatore. Di conseguenza, `allowed_service_ids` va nascosto dall'UI per il ruolo `staff` e ignorato nella logica di validazione backend (che deve invece usare i servizi del membro collegato).

---

## Direzione futura decisa

### Nuovo ruolo: `custom` (o `custom_operator`)
Un ruolo completamente configurabile che affiancherà i ruoli esistenti durante una fase di transizione, per poi sostituirli.

**Modello:**
- `can_manage_bookings` → può creare/modificare/cancellare prenotazioni e appuntamenti
- `can_view_reports` → accesso ai report
- `allowed_staff_ids` → su quali membri del team opera (`null`=tutti, `[]`=nessuno, `[..]`=selezionati)
- `allowed_service_ids` → quali servizi gestisce
- `allowed_class_type_ids` → quali tipi lezione gestisce
- `scope_type` + sedi → perimetro geografico

**Strategia di introduzione:**
- Aggiungere `custom` come nuovo valore dell'enum `role` senza rimuovere i ruoli esistenti
- I vecchi ruoli continuano a funzcionare durante la transizione
- Tutti i controlli backend che fanno `if role === 'staff'` o `if role === 'manager'` non si applicano al nuovo ruolo — vanno gestiti separatamente
- Quando il nuovo ruolo è stabile, migrare gli utenti esistenti e deprecare i vecchi ruoli

---

## Prossimi passi

1. **Aggiungere `allowed_staff_ids`** al modello `business_users` (DB + repository PHP + model Flutter + provider)
2. **Implementare il ruolo `custom`**:
   - Aggiungere `custom` all'enum role nel DB e nei controller PHP
   - UI per creare/modificare operatori custom con tutti i flag e filtri configurabili
   - Logica di autorizzazione backend per il nuovo ruolo
3. **Filtro lettura backend** — aggiungere WHERE clause sui filtri negli endpoint di lettura (`ClassEventsController::indexTypes`, `indexByBusiness`, `ServicesController::index`, `indexByLocation`, `BookingsController::index`)

---

## File coinvolti

**PHP (agenda_core):**
- `src/Infrastructure/Repositories/BusinessUserRepository.php`
- `src/Http/Controllers/BusinessUsersController.php`
- `src/Http/Controllers/AuthController.php`
- `src/Http/Controllers/ClassEventsController.php`
- `src/Http/Controllers/AppointmentsController.php`
- `src/Http/Controllers/BookingsController.php`

**Flutter (agenda_backend):**
- `lib/core/models/business_user.dart`
- `lib/core/models/business_invitation.dart`
- `lib/core/network/api_client.dart`
- `lib/features/auth/providers/current_business_user_provider.dart`
- `lib/features/business/presentation/dialogs/role_selection_dialog.dart`
- `lib/features/business/presentation/dialogs/invite_operator_dialog.dart`
- `lib/features/business/presentation/operators_screen.dart`
- `lib/features/class_events/presentation/class_events_screen.dart`
- `lib/features/agenda/providers/staff_filter_providers.dart`

**Documentazione:**
- `config/docs/data_models.md` — aggiornato con nuova semantica filtri
