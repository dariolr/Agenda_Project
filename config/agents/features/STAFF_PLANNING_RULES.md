# Staff Planning Rules

## Source of truth disponibilità

- `staff_planning` + `staff_planning_week_template` sono la source of truth per la disponibilità staff.
- Non derivare disponibilità da altre fonti.

## Step planning

- Step planning fisso: **5 minuti** (nessun campo per-record).
- Non accoppiare con `online_booking_slot_interval_minutes` (frequenza slot online, default 15 min).
- Non accoppiare con `LayoutConfig.minutesPerSlot` (granularità visiva agenda, non source of truth).

## Validazione intervalli

- `valid_from` obbligatorio; `valid_to` nullable (null = illimitato).
- Intervalli chiusi-chiusi: `[valid_from, valid_to]`.
- `valid_to` quando presente deve essere `>= valid_from`.
- Nessuna sovrapposizione per lo stesso staff (anche un solo giorno in comune è rifiutato).
- Contiguità ammessa solo se `new.valid_from = existing.valid_to + 1 giorno`.

## Selezione planning per data D

- Filtra planning con `valid_from <= D <= valid_to` (o `valid_to = null`).
- Nessun planning trovato = staff non disponibile.
- Più di un planning = errore di consistenza.

## Calcolo settimana A/B (biweekly)

- `delta_days = D - valid_from` (giorni interi, stesso fuso del business).
- `week_index = floor(delta_days / 7)`.
- `week_index` pari → settimana A; dispari → settimana B.
- Per tipo `weekly`, usare sempre template A.

## Timezone

- Confronti data in timezone business/staff per evitare slittamenti di giorno.

## Regole UI (agenda_backend)

- Dialog eccezioni staff si apre solo se planning disponibile.
- Se planning non in cache, forzare load da API prima di aprire il dialog.
- Conversioni orario↔slot nel dialog eccezioni: usare step fisso 5 minuti.
