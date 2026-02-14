# Staff Planning Model

Documento canonico condiviso per `agenda_backend`, `agenda_frontend`, `agenda_core`.

## Modello dati

- `staff_planning`: `id`, `staff_id` (FK), `type` (`weekly`/`biweekly`), `valid_from` (date, required), `valid_to` (date nullable = "mai", inclusivo), `created_at`, `updated_at`
- `staff_planning_week_template`: `id`, `staff_planning_id` (FK), `week_label` (A/B, per `weekly` solo A), `day_of_week` (1-7), `slots` JSON (riusa struttura esistente)

## Regole di validazione

- Obbligatori: `valid_from`, `type`, template A (e B se `biweekly`)
- `valid_to` quando presente deve essere `>= valid_from`; `null` = illimitato
- Intervalli chiusi-chiusi: `[valid_from, valid_to]` (o `[valid_from, +∞)` se `valid_to` e `null`)
- Non sovrapposizione per lo stesso staff: respingere se due intervalli chiusi hanno qualunque giorno in comune
- Contiguita ammessa solo se `new.valid_from = existing.valid_to + 1 giorno` o viceversa
- In modifica: stesse regole contro tutti gli altri planning dello staff (escluso quello in modifica)
- `biweekly`: template A/B non vuoti e coerenti con il formato slot esistente

## Selezione planning valido per data D

- Filtra planning con `valid_from <= D <= valid_to` (o `valid_to = null`)
- Nessun planning -> staff non disponibile
- Piu di uno -> errore di consistenza (non dovrebbe accadere con validazione corretta)
- L'unico risultato e il planning valido

## Calcolo settimana A/B (biweekly)

- `delta_days = D - valid_from` (giorni interi, stesso fuso del business)
- `week_index = floor(delta_days / 7)`
- `week_index` pari -> settimana A
- `week_index` dispari -> settimana B
- Per `weekly`, usare sempre template A

## Edge case critici

- `valid_to < valid_from` -> rifiutare
- Due planning con `valid_to = X` e `new.valid_from = X` -> sovrapposti (giorno X doppio); consentito solo `new.valid_from = X + 1`
- Overlap con planning illimitato (`valid_to = null`) -> rifiutare
- Cancellazione che crea buco temporale -> ammesso; staff indisponibile nel buco
- Cambio type `weekly`/`biweekly` senza adeguare template -> rifiutare
- Shift di `valid_from` in biweekly altera la parita ciclo A/B per tutto l'intervallo; va segnalato
- Timezone: confronti data in timezone business/staff per evitare slittamenti di giorno
- Template giorno senza slot -> giorno non disponibile (non errore)
