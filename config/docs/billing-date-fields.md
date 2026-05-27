# Campi data abbonamento business

## `activation_deadline_at` — Data limite attivazione

**Dove si imposta**: dialog superadmin > sezione billing del business  
**Effetto**: lato app Flutter, non su Stripe  
**Colonna DB**: `business_billing_config.activation_deadline_at`

### Comportamento

| Condizione | Risultato |
|---|---|
| Campo null | Nessun blocco. Appare solo il banner agenda (dismissibile giornalmente) come promemoria |
| Data futura | Banner giallo nella schermata abbonamento: "Il tuo periodo gratuito termina il [data]" |
| Data passata + abbonamento non `active` | App bloccata: il business viene reindirizzato forzatamente alla schermata abbonamento e non può navigare altrove |
| Data passata + abbonamento `active` | Nessun blocco |

### Regola di blocco (server-side)

Il campo `access_blocked` viene calcolato dal backend e restituito nella risposta:

```
billing_enabled = true
AND billing_mode = recurring
AND activation_deadline_at IS NOT NULL
AND activation_deadline_at < NOW()
AND status NOT IN ('active')
```

### Caso d'uso tipico

Vuoi dare 30 giorni di prova gratuita a un business. Imposti `activation_deadline_at = 30 giugno 2026`. Dal 1 luglio 2026, se l'abbonamento non è attivo, il business non può più usare l'app.

---

## `billing_cycle_anchor_at` — Data ancoraggio ciclo Stripe

**Dove si imposta**: dialog superadmin > sezione billing del business  
**Effetto**: lato Stripe, non sull'app  
**Colonna DB**: `business_billing_config.billing_cycle_anchor_at`

### Comportamento

- Se impostata e **futura** al momento del checkout → viene passata a Stripe come `billing_cycle_anchor` con `proration_behavior = none`. Il primo ciclo di fatturazione parte da quella data; non viene addebitato nulla fino ad allora.
- Se null o già passata → Stripe usa la data di attivazione reale come inizio del ciclo (comportamento standard).

### Caso d'uso tipico

Vuoi che tutti i rinnovi avvengano il 1 del mese. Imposti `billing_cycle_anchor_at = 1 luglio 2026`. Il business attiva l'abbonamento il 15 giugno: il primo addebito parte il 1 luglio, poi rinnova ogni 1 del mese successivo.

---

## Uso combinato

Le due date sono indipendenti e si possono usare insieme:

- `activation_deadline_at = 30 giugno` → il business ha tempo fino al 30 giugno per abbonarsi, altrimenti viene bloccato
- `billing_cycle_anchor_at = 1 luglio` → se si abbona entro il 30 giugno, il primo addebito Stripe parte il 1 luglio

In questo modo il business ha un breve periodo gratuito e l'abbonamento parte in modo allineato al calendario.

---

## Note operative

- Se il superadmin **non imposta** `activation_deadline_at`, il business può usare l'app a tempo indeterminato (appare solo il banner agenda come promemoria non bloccante).
- Se il superadmin imposta `activation_deadline_at` con una data già passata, il blocco scatta immediatamente.
- `billing_cycle_anchor_at` passata al momento del checkout viene ignorata da Stripe; la logica lato backend non la invia se non è futura.
- Disabilitare il billing (flag `billing_enabled = false`) azzera entrambe le date nel DB.
