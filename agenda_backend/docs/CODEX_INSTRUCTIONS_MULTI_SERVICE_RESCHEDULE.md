# CODEX Instructions — Multi-Service Reschedule (Agenda Backend)

## Scope
Queste istruzioni guidano Codex nell’implementazione robusta della riprogrammazione per prenotazioni multi-servizio (`booking` con più `booking_item`) nel progetto `agenda_backend`.

Valido per tutte le viste UI (giorno/settimana).

---

## Mandatory Rules
1. Non introdurre split impliciti dello stesso `booking_id` su date diverse.
2. La riprogrammazione standard deve spostare l’intero booking (atomica).
3. Lo spostamento di un singolo servizio in booking multi-servizio è consentito solo con split esplicito e confermato dall’operatore.
4. Non rompere logiche esistenti di drag/drop, resize, scroll sync.
5. Ogni operazione deve preservare coerenza notifiche/promemoria.

---

## Required Behavior
## A. Reschedule Mode (booking-level)
- Quando la sessione `bookingRescheduleSessionProvider` è attiva:
  - click slot deve spostare **tutti** gli item del booking (via `moveBookingByAnchor` o equivalente).
  - non creare nuovi appuntamenti.

## B. Single Item Move/Edit (outside reschedule mode)
- Se booking ha 1 item: procedi normalmente.
- Se booking ha >1 item: mostra dialog decisionale obbligatorio:
  - `Sposta intera prenotazione` (default/raccomandata)
  - `Sposta solo questo servizio (crea nuova prenotazione)`
  - `Annulla`

## C. Split Flow (single service only)
- Mai fare split implicito.
- Se l’operatore seleziona “solo questo servizio”:
  - creare nuovo booking,
  - spostare item selezionato sul nuovo booking,
  - lasciare gli altri item sul booking originale,
  - mostrare feedback con ID nuovo booking.

---

## Data Integrity Contract
Codex deve garantire:
1. Un `booking_item` appartiene a un solo booking.
2. `first_start_time`/`last_end_time` (o equivalente) coerenti con item effettivi del booking.
3. Totali economici coerenti dopo split/spostamento.
4. Cache/provider invalidati su entrambe le entità coinvolte.

Minimo da invalidare dopo operazioni:
- `appointmentsProvider`
- `weeklyAppointmentsProvider(...)` della/e settimana/e coinvolte
- `bookingsProvider`

---

## Notifications & Reminder Contract
Codex deve implementare/rispettare:
1. Reschedule intero booking:
   - evento notifica `booking_rescheduled` coerente col booking.
2. Split:
   - booking originale aggiornato,
   - nuovo booking con evento coerente (`booking_confirmed` o canale dedicato concordato),
   - reminder invalidati e rigenerati su entrambi.
3. Idempotenza invio notifiche/reminder (chiave operazione).

Se il backend attuale non supporta uno di questi punti, Codex deve:
- inserire guardrail lato frontend,
- documentare gap API con TODO espliciti,
- evitare comportamenti ambigui lato utente.

---

## Implementation Steps (Codex Execution Order)
1. Mappare tutti i punti d’ingresso che spostano appointment:
   - reschedule mode,
   - drag/drop card,
   - edit/save da dialog.
2. Introdurre funzione comune di decisione per booking multi-servizio (no logica duplicata).
3. Applicare gate obbligatorio su single-item move in multi-servizio.
4. Implementare split esplicito solo se API disponibile; altrimenti mostrare blocco informativo professionale.
5. Aggiornare localizzazioni `it/en` per nuovi messaggi UX.
6. Aggiungere test automatici.
7. Eseguire `flutter analyze` e test area agenda.

---

## Test Requirements (Must Pass)
## Unit
- booking multi-servizio in reschedule mode => move all items.
- single-item move su multi-servizio => dialog decisionale.
- split esplicito => nuovo booking creato, item rimosso dal vecchio.

## Integration
- comportamento identico in vista giorno e settimana.
- cross-day reschedule non produce “booking non trovato”.
- provider/cache coerenti dopo operazione.

## Regression
- drag/drop esistente invariato per booking mono-servizio.
- resize invariato.
- no regressioni su selezione card/interazioni hover.

---

## Done Criteria
Task completato solo se:
1. Nessuno split implicito rimasto nel codice.
2. Decision path operatore esplicito e tracciabile.
3. Notifiche/promemoria coerenti o gap bloccati con guardrail dichiarato.
4. `flutter analyze` pulito.
5. Test richiesti verdi.

---

## Non-Goals
- Nessun deploy produzione.
- Nessuna modifica DB reale diretta.
- Nessuna modifica route shell indices.

---

## Notes for Codex
- Terminologia: DB `bookings`; modello Flutter `Appointment` = `booking_item`.
- Se manca un endpoint backend per split atomico, non improvvisare workaround non transazionali.
- In caso di dubbio, privilegiare consistenza dati rispetto alla comodità UX.
