---
name: feedback-sql-migrations
description: Regola su come gestire i file di migration SQL — non modificare mai quelli esistenti
metadata:
  type: feedback
---

Non modificare MAI i file migration con timestamp (es. `20260601_*.sql`). Le migration precedenti possono essere già state eseguite in produzione.

**Regola**:
- Per ogni modifica allo schema DB → creare SEMPRE un nuovo file migration con timestamp progressivo (es. `20260602_nome_modifica.sql`)
- `FULL_DATABASE_SCHEMA.sql` è l'unico file SQL che va aggiornato direttamente — è il riferimento completo dello schema attuale, non una migration incrementale

**Why:** Le migration con timestamp vengono eseguite in ordine cronologico sui vari ambienti. Modificarle dopo l'esecuzione causa disallineamento tra codice e DB reale. `FULL_DATABASE_SCHEMA.sql` invece è sempre la fotografia aggiornata dello schema completo.

**How to apply:** Ogni volta che si aggiunge/modifica/droppa qualcosa: 1) nuovo file migration con timestamp, 2) aggiorna `FULL_DATABASE_SCHEMA.sql`.
