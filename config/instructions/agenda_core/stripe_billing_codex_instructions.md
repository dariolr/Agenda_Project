# Istruzioni complete per implementazione Billing multi-provider nei progetti `agenda_core` e `agenda_backend`

## Obiettivo
Implementare un sistema di billing nei progetti `agenda_core` (API PHP) e `agenda_backend` (Flutter web gestionale) con queste caratteristiche obbligatorie:

1. **Billing opzionale per business**: non tutti i business devono pagare. Il superadmin decide per ogni business se abilitarlo o no.
2. **Importo configurabile per business**: il superadmin imposta un importo specifico per ogni business.
3. **Predisposizione per modalità future**:
   - ricorrente mensile
   - ricorrente semestrale
   - ricorrente annuale
   - una tantum
   - manuale / futuro
4. **Implementazione iniziale concreta**:
   - supportare nel comportamento reale solo:
     - `free` / non soggetto a pagamento
     - `recurring monthly`
   - predisporre però modello dati, enum, service layer e validazioni per future modalità.
5. **Provider-agnostic**:
   - il dominio interno NON deve essere Stripe-centrico
   - Stripe deve essere implementato come primo provider adapter
   - il resto del codice deve parlare con un’astrazione `BillingProviderInterface`
6. **Frontend Flutter senza Stripe SDK**:
   - `agenda_backend` deve chiamare solo le API di `agenda_core`
   - ricevere URL checkout/portal dal backend
   - aprire URL nel browser
7. **Webhook come source of truth** per stato billing/subscription.
8. **No breaking change** per il resto del sistema.
9. **Non alterare comportamenti esistenti** di agenda, business switch, auth, staff, clienti, servizi, report.

---

## Contesto reale del codice da rispettare

### `agenda_core`
- progetto PHP custom con bootstrap in `public/index.php`
- routing/kernel custom già presenti
- dipendenze Composer attuali senza Stripe
- schema DB con `businesses`, `business_users`, `business_application_settings`, ecc.
- ambiente/config già centralizzati

### `agenda_backend`
- Flutter con Riverpod 3 + GoRouter + ApiClient centralizzato
- business corrente già gestito tramite provider/router
- routing modulare già esistente
- struttura feature-based già presente

Implementare la nuova feature mantenendo lo stile esistente del progetto.

---

# PARTE 1 — REGOLE ARCHITETTURALI OBBLIGATORIE

## 1.1 Non rendere il dominio dipendente da Stripe
Usare naming neutro.

### Vietato spargere nel dominio campi come:
- `stripe_customer_id`
- `stripe_subscription_id`
- `stripe_price_id`

### Usare invece campi neutrali:
- `provider_code`
- `provider_customer_id`
- `provider_subscription_id`
- `provider_price_reference`

Stripe va confinato dentro un adapter/provider dedicato.

---

## 1.2 Separare configurazione billing da stato runtime
Non usare una sola tabella per tutto.

Separare:
1. **configurazione commerciale** del business
2. **stato attuale della subscription**
3. **eventi provider/webhook**
4. **pagamenti one-time futuri**

---

## 1.3 Supportare modalità future ma attivare solo free e mensile ricorrente adesso
Il dominio deve prevedere:
- `free`
- `recurring`
- `one_time`
- `manual`

ma per ora la UI e i flussi reali devono permettere solo:
- non soggetto a pagamento
- mensile ricorrente

---

## 1.4 Superadmin come unico configuratore
Solo il superadmin può:
- abilitare/disabilitare billing per business
- impostare importo
- impostare provider
- vedere configurazione billing globale business

Gli utenti business normali possono solo:
- vedere il proprio stato billing
- aprire checkout se richiesto
- aprire portal

---

## 1.5 Webhook come unica fonte di verità
Il redirect `success_url` non deve mai essere considerato prova di pagamento.
Tutti gli aggiornamenti stato devono derivare da webhook provider.

---

# PARTE 2 — MODELLO DATI DA IMPLEMENTARE IN `agenda_core`

## 2.1 Nuova tabella `business_billing_config`
Creare una nuova tabella dedicata.

### Scopo
Configurazione commerciale per singolo business.

### Campi
- `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- `business_id` INT UNSIGNED NOT NULL UNIQUE
- `billing_enabled` TINYINT(1) NOT NULL DEFAULT 0
- `billing_mode` ENUM('free','recurring','one_time','manual') NOT NULL DEFAULT 'free'
- `billing_interval_unit` ENUM('month','year') DEFAULT NULL
- `billing_interval_count` INT UNSIGNED DEFAULT NULL
- `amount_cents` INT UNSIGNED DEFAULT NULL
- `currency` VARCHAR(3) NOT NULL DEFAULT 'EUR'
- `provider_code` VARCHAR(32) DEFAULT NULL
- `provider_price_reference` VARCHAR(191) DEFAULT NULL
- `notes` VARCHAR(255) DEFAULT NULL
- `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
- `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

### Vincoli logici
- se `billing_enabled = 0`:
  - `billing_mode` deve essere `free`
- per implementazione attuale, se `billing_enabled = 1`:
  - consentire solo:
    - `billing_mode = recurring`
    - `billing_interval_unit = month`
    - `billing_interval_count = 1`
- `amount_cents` obbligatorio se `billing_enabled = 1`
- `provider_code` obbligatorio se `billing_enabled = 1`

### FK
- FK `business_id` → `businesses.id` ON DELETE CASCADE ON UPDATE CASCADE

---

## 2.2 Nuova tabella `business_billing_subscription`
### Scopo
Stato runtime della relazione col provider per business.

### Campi
- `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- `business_id` INT UNSIGNED NOT NULL UNIQUE
- `provider_code` VARCHAR(32) DEFAULT NULL
- `provider_customer_id` VARCHAR(191) DEFAULT NULL
- `provider_subscription_id` VARCHAR(191) DEFAULT NULL
- `provider_price_reference` VARCHAR(191) DEFAULT NULL
- `status` ENUM('not_required','inactive','pending_checkout','active','past_due','unpaid','canceled','error') NOT NULL DEFAULT 'not_required'
- `current_period_start` TIMESTAMP NULL DEFAULT NULL
- `current_period_end` TIMESTAMP NULL DEFAULT NULL
- `cancel_at_period_end` TINYINT(1) NOT NULL DEFAULT 0
- `canceled_at` TIMESTAMP NULL DEFAULT NULL
- `last_payment_at` TIMESTAMP NULL DEFAULT NULL
- `last_payment_failed_at` TIMESTAMP NULL DEFAULT NULL
- `last_checkout_session_id` VARCHAR(191) DEFAULT NULL
- `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
- `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

### Regole
- se business non soggetto a pagamento: `status = not_required`
- se business soggetto a pagamento ma mai attivato: `status = inactive`
- quando checkout creato: `status = pending_checkout`
- quando webhook conferma: `status = active`

### FK
- FK `business_id` → `businesses.id` ON DELETE CASCADE ON UPDATE CASCADE

---

## 2.3 Nuova tabella `billing_provider_events`
### Scopo
Log eventi provider e idempotenza webhook.

### Campi
- `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- `provider_code` VARCHAR(32) NOT NULL
- `provider_event_id` VARCHAR(191) NOT NULL
- `event_type` VARCHAR(120) NOT NULL
- `business_id` INT UNSIGNED DEFAULT NULL
- `payload_json` JSON NOT NULL
- `processed_at` DATETIME NOT NULL
- `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

### Indici
- UNIQUE `provider_code`,`provider_event_id`
- INDEX `business_id`
- INDEX `event_type`
- INDEX `processed_at`

### FK
- FK `business_id` → `businesses.id` ON DELETE SET NULL ON UPDATE CASCADE

---

## 2.4 Nuova tabella futura `business_billing_payments`
Implementarla già ora anche se inizialmente usata poco.

### Scopo
Predisposizione per `one_time` o pagamenti fuori subscription.

### Campi
- `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- `business_id` INT UNSIGNED NOT NULL
- `provider_code` VARCHAR(32) DEFAULT NULL
- `provider_payment_id` VARCHAR(191) DEFAULT NULL
- `payment_type` ENUM('one_time','recurring_invoice','manual') NOT NULL DEFAULT 'one_time'
- `status` ENUM('pending','paid','failed','canceled','refunded') NOT NULL DEFAULT 'pending'
- `amount_cents` INT UNSIGNED NOT NULL
- `currency` VARCHAR(3) NOT NULL DEFAULT 'EUR'
- `paid_at` TIMESTAMP NULL DEFAULT NULL
- `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
- `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

### FK
- FK `business_id` → `businesses.id` ON DELETE CASCADE ON UPDATE CASCADE

---

# PARTE 3 — ENUM E DOMINIO APPLICATIVO

## 3.1 Creare enum/constant domain neutrali
In `agenda_core` creare enum o costanti dedicate per:

### BillingMode
- `free`
- `recurring`
- `one_time`
- `manual`

### BillingIntervalUnit
- `month`
- `year`

### BillingSubscriptionStatus
- `not_required`
- `inactive`
- `pending_checkout`
- `active`
- `past_due`
- `unpaid`
- `canceled`
- `error`

### BillingProviderCode
- `stripe`
- predisposto per altri provider futuri

---

# PARTE 4 — BACKEND `agenda_core` IMPLEMENTAZIONE

## 4.1 Aggiungere dipendenza Stripe
Modificare `composer.json` aggiungendo:
- `stripe/stripe-php`

Non toccare il resto delle dipendenze.

---

## 4.2 Variabili ambiente
Aggiungere a config/env:
- `BILLING_DEFAULT_PROVIDER=stripe`
- `STRIPE_SECRET_KEY=`
- `STRIPE_WEBHOOK_SECRET=`
- `STRIPE_SUCCESS_URL=`
- `STRIPE_CANCEL_URL=`
- `STRIPE_PORTAL_RETURN_URL=`

Note:
- non usare price ids globali fissi obbligatori, perché il prezzo è per business
- il provider può dover creare/referenziare un price diverso per business

---

## 4.3 Nuova struttura cartelle/feature
Creare una feature billing dedicata.

### Struttura consigliata
- `src/Domain/Billing/...`
- `src/Infrastructure/Billing/...`
- `src/Infrastructure/Repositories/Billing/...`
- `src/Http/Controllers/Billing/...`

### File minimi da creare
- `src/Domain/Billing/BillingMode.php`
- `src/Domain/Billing/BillingIntervalUnit.php`
- `src/Domain/Billing/BillingSubscriptionStatus.php`
- `src/Domain/Billing/BillingProviderInterface.php`
- `src/Domain/Billing/BillingProviderFactory.php`
- `src/Domain/Billing/BillingConfig.php`
- `src/Domain/Billing/BillingSubscription.php`
- `src/Infrastructure/Billing/Stripe/StripeBillingProvider.php`
- `src/Infrastructure/Billing/Stripe/StripeClientFactory.php`
- `src/Infrastructure/Repositories/Billing/BusinessBillingConfigRepository.php`
- `src/Infrastructure/Repositories/Billing/BusinessBillingSubscriptionRepository.php`
- `src/Infrastructure/Repositories/Billing/BillingProviderEventRepository.php`
- `src/Http/Controllers/Billing/AdminBusinessBillingController.php`
- `src/Http/Controllers/Billing/BusinessBillingController.php`
- `src/Http/Controllers/Billing/StripeWebhookController.php`

---

## 4.4 Interfaccia provider obbligatoria
Creare `BillingProviderInterface` con metodi neutri.

### Metodi minimi
- `createSubscriptionCheckout(BillingConfig $config, BillingSubscription $subscription, array $context): array`
- `createCustomerPortal(BillingConfig $config, BillingSubscription $subscription, array $context): array`
- `cancelSubscription(BillingConfig $config, BillingSubscription $subscription, array $context): void`
- `handleWebhook(string $payload, array $headers): BillingWebhookResult`

Dove `BillingWebhookResult` è un value object neutro che contenga almeno:
- `providerEventId`
- `eventType`
- `businessId` nullable
- `providerCode`
- `providerCustomerId` nullable
- `providerSubscriptionId` nullable
- `providerPriceReference` nullable
- `targetStatus` nullable
- `currentPeriodStart` nullable
- `currentPeriodEnd` nullable
- `cancelAtPeriodEnd` nullable
- `lastPaymentAt` nullable
- `lastPaymentFailedAt` nullable
- `rawPayload`

Tutto il controller webhook deve lavorare su questo risultato neutro.

---

## 4.5 Implementazione `StripeBillingProvider`
Implementare il provider Stripe come adapter dell’interfaccia.

### Responsabilità
- creare customer Stripe se assente
- creare checkout session per subscription mensile ricorrente
- creare customer portal session
- validare firma webhook Stripe
- tradurre eventi Stripe in `BillingWebhookResult`
- mappare stati Stripe → stati interni

### Mapping stati minimo
- Stripe active/trialing → `active`
- Stripe past_due → `past_due`
- Stripe unpaid → `unpaid`
- Stripe canceled/incomplete_expired → `canceled`
- errore tecnico → `error`

### Nota sul prezzo business-specific
Poiché il prezzo è configurabile per business, il provider deve supportare una di queste due strategie:

#### Strategia consigliata
Usare `provider_price_reference` come riferimento a un Price Stripe creato o associato per quel business.

Flusso:
1. leggere `business_billing_config.amount_cents`
2. se `provider_price_reference` esiste, usarlo
3. se non esiste, creare il prodotto/prezzo Stripe necessario per quel business oppure recuperarlo secondo logica provider
4. salvare il riferimento in `business_billing_config.provider_price_reference`

Questo comportamento deve restare confinato nel provider Stripe.

---

## 4.6 Repository billing
Implementare repository dedicati, non usare query sparse nei controller.

### `BusinessBillingConfigRepository`
Metodi minimi:
- `findByBusinessId(int $businessId): ?BillingConfig`
- `createDefaultForBusiness(int $businessId): BillingConfig`
- `upsertConfig(...)`

### `BusinessBillingSubscriptionRepository`
Metodi minimi:
- `findByBusinessId(int $businessId): ?BillingSubscription`
- `findOrCreateByBusinessId(int $businessId): BillingSubscription`
- `updateAfterCheckoutCreation(...)`
- `updateFromWebhookResult(...)`
- `markNotRequired(...)`

### `BillingProviderEventRepository`
Metodi minimi:
- `exists(string $providerCode, string $providerEventId): bool`
- `storeProcessedEvent(...)`

---

## 4.7 Endpoint admin billing config
Creare endpoint superadmin per configurare billing business.

### Endpoint
- `GET /v1/admin/businesses/{businessId}/billing-config`
- `PUT /v1/admin/businesses/{businessId}/billing-config`

### Sicurezza
- accesso solo superadmin

### Response GET
Restituire:
- `business_id`
- `billing_enabled`
- `billing_mode`
- `billing_interval_unit`
- `billing_interval_count`
- `amount_cents`
- `currency`
- `provider_code`
- `provider_price_reference`
- `notes`
- `subscription_status`
- `current_period_end`

### Request PUT
Per implementazione iniziale accettare e validare:
- `billing_enabled` bool
- `amount_cents` int nullable
- `currency` string default EUR
- `provider_code` string nullable
- `notes` string nullable

### Regole server-side obbligatorie
Se `billing_enabled = false`:
- forzare:
  - `billing_mode = free`
  - `billing_interval_unit = null`
  - `billing_interval_count = null`
  - `amount_cents = null`
  - `provider_code = null`
  - `provider_price_reference = null`
- mettere subscription status a `not_required`

Se `billing_enabled = true`:
- per ora forzare:
  - `billing_mode = recurring`
  - `billing_interval_unit = month`
  - `billing_interval_count = 1`
- `amount_cents` obbligatorio e > 0
- `provider_code` obbligatorio

---

## 4.8 Endpoint business billing view
Creare endpoint per il business autenticato.

### Endpoint
- `GET /v1/billing/subscription`

### Risposta
- `billing_enabled`
- `billing_mode`
- `billing_interval_unit`
- `billing_interval_count`
- `amount_cents`
- `currency`
- `provider_code`
- `status`
- `current_period_start`
- `current_period_end`
- `cancel_at_period_end`
- `canceled_at`
- `can_start_checkout`
- `can_open_portal`

### Regole
Se billing non abilitato per il business:
- `status = not_required`
- `can_start_checkout = false`
- `can_open_portal = false`

---

## 4.9 Endpoint checkout session
### Endpoint
- `POST /v1/billing/checkout-session`

### Accesso
- utente autenticato con accesso al business corrente

### Input
Nessun input libero di prezzo.
Il prezzo va preso solo dalla config del business già salvata dal superadmin.

### Flusso
1. identificare business corrente dell’utente
2. caricare `business_billing_config`
3. se `billing_enabled = false` → errore 409/422 coerente
4. se config non valida → errore 422
5. caricare/creare `business_billing_subscription`
6. usare `BillingProviderFactory` per ottenere provider
7. chiamare `createSubscriptionCheckout(...)`
8. aggiornare `business_billing_subscription.status = pending_checkout`
9. salvare eventuale `last_checkout_session_id`
10. restituire:
   - `url`

### Nota
Per ora supportare solo `recurring` mensile. Se in config c’è altro, rispondere con errore controllato “modalità non ancora attiva”.

---

## 4.10 Endpoint portal session
### Endpoint
- `POST /v1/billing/portal-session`

### Flusso
1. identificare business corrente
2. caricare config + subscription
3. se `billing_enabled = false` → errore
4. se manca `provider_customer_id` → errore controllato
5. usare provider adapter
6. restituire `url`

---

## 4.11 Webhook Stripe
### Endpoint pubblico
- `POST /v1/stripe/webhook`

### Regole obbligatorie
- niente auth middleware
- validazione firma webhook Stripe obbligatoria
- idempotenza obbligatoria usando `billing_provider_events`
- salvataggio payload obbligatorio

### Eventi minimi da gestire
- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.paid`
- `invoice.payment_failed`

### Flusso
1. leggere raw payload
2. validare firma con `STRIPE_WEBHOOK_SECRET`
3. mappare evento tramite `StripeBillingProvider::handleWebhook()`
4. controllare se `provider_event_id` già processato
5. se già processato restituire 200 idempotente
6. aggiornare `business_billing_subscription`
7. salvare evento in `billing_provider_events`
8. restituire 200

---

## 4.12 Stati interni dopo eventi
### Se business non soggetto a billing
- mantenere `status = not_required`

### Se checkout creato
- `pending_checkout`

### Se subscription attiva
- `active`

### Se pagamento fallito
- `past_due` o `unpaid` in base al mapping provider

### Se cancellata
- `canceled`

---

## 4.13 Feature gating
Non introdurre hard lock globale ora.

### Implementazione iniziale
- nessun blocco funzionale duro
- opzionale: esporre stato billing al frontend
- opzionale: futuro banner/UI warning

Non bloccare agenda o altre feature in questa implementazione.

---

# PARTE 5 — ROUTING / REGISTRAZIONE API IN `agenda_core`

## 5.1 Registrare le route nuove rispettando il sistema esistente
Aggiungere nel router/kernel i nuovi endpoint senza rompere quelli esistenti.

### Route protette
- `GET /v1/billing/subscription`
- `POST /v1/billing/checkout-session`
- `POST /v1/billing/portal-session`
- `GET /v1/admin/businesses/{businessId}/billing-config`
- `PUT /v1/admin/businesses/{businessId}/billing-config`

### Route pubblica
- `POST /v1/stripe/webhook`

---

# PARTE 6 — FRONTEND `agenda_backend`

## 6.1 Regola fondamentale
Non integrare Stripe SDK nel frontend.
Il frontend deve usare solo API di `agenda_core`.

---

## 6.2 Nuova feature Flutter `billing`
Creare una feature dedicata.

### Struttura consigliata
- `lib/features/billing/data/billing_api.dart`
- `lib/features/billing/data/billing_repository.dart`
- `lib/features/billing/domain/billing_config_view_model.dart`
- `lib/features/billing/providers/billing_provider.dart`
- `lib/features/billing/presentation/billing_screen.dart`
- `lib/features/billing/presentation/admin_business_billing_config_dialog.dart`

---

## 6.3 Estendere `ApiClient`
Aggiungere metodi API dedicati.

### Metodi minimi business
- `Future<Map<String, dynamic>> getBillingSubscription()`
- `Future<String> createBillingCheckoutSession()`
- `Future<String> createBillingPortalSession()`

### Metodi minimi superadmin
- `Future<Map<String, dynamic>> getAdminBusinessBillingConfig(int businessId)`
- `Future<void> updateAdminBusinessBillingConfig(int businessId, Map<String, dynamic> payload)`

Mantenere stile e convenzioni attuali di `ApiClient`.

---

## 6.4 Schermata business `Abbonamento`
Aggiungere una schermata nuova.

### Route consigliata
- `/altro/abbonamento`

### Inserimento UI
Aggiungere card/link dalla schermata `Altro` esistente.

### Comportamento schermata
Se `billing_enabled = false`:
- mostra messaggio informativo: business non soggetto a pagamento
- non mostra pulsanti checkout/portal

Se `billing_enabled = true`:
- mostra importo mensile
- mostra currency
- mostra stato
- mostra prossima scadenza se presente
- se `status` in `inactive` o `pending_checkout`: mostra pulsante “Attiva abbonamento”
- se `status` in `active`, `past_due`, `unpaid`, `canceled`: mostra pulsante “Gestisci abbonamento” quando disponibile

### Apertura URL
Quando API ritorna `url`:
- aprire nel browser/tab esterna compatibile con Flutter web
- nessun SDK Stripe lato client

---

## 6.5 UI superadmin configurazione billing per business
Integrare in schermata business admin esistente, o tramite dialog dedicato aperto dalla lista business.

### Requisiti UI minimi
- toggle `Soggetto a pagamento`
- campo importo mensile in euro
- currency (default EUR)
- provider (per ora predefinito `stripe`, ma struttura pronta)
- note opzionali
- visualizzazione stato corrente subscription

### Regole UI
Se toggle OFF:
- disabilitare/nascondere campi importo/provider

Se toggle ON:
- richiedere importo > 0
- non esporre ancora semestrale/annuale/una tantum in UI
- l’architettura deve però rimanere compatibile

---

## 6.6 Provider Riverpod
Creare provider dedicati per:
- fetch stato billing business corrente
- trigger checkout
- trigger portal
- fetch/update config billing superadmin

Mantenere pattern Riverpod già usato nel progetto.

---

# PARTE 7 — VALIDAZIONI E REGOLE OBBLIGATORIE

## 7.1 Sicurezza input prezzo
Il business non deve mai inviare il prezzo checkout.
Il prezzo viene solo dal backend dalla config salvata dal superadmin.

---

## 7.2 Business non soggetto a pagamento
Se `billing_enabled = false`:
- nessuna checkout session
- nessuna portal session
- stato `not_required`

---

## 7.3 Solo provider supportato ora
Anche se il dominio è multi-provider, in questa implementazione concreta:
- supportare davvero solo `stripe`
- se arriva altro provider non supportato → errore controllato esplicito

---

## 7.4 Nessun lock funzionale duro
Non introdurre ora blocchi API o UI che impediscano uso piattaforma per mancato pagamento.
Preparare solo lo stato.

---

## 7.5 Idempotenza webhook obbligatoria
Ogni evento provider deve essere processato una sola volta.

---

# PARTE 8 — COMPORTAMENTO FUTURO GIÀ PREDISPOSTO

Questa implementazione deve lasciare il codice pronto per:

## 8.1 Annuale
Possibile attivazione futura impostando:
- `billing_mode = recurring`
- `billing_interval_unit = year`
- `billing_interval_count = 1`

## 8.2 Semestrale
Possibile attivazione futura impostando:
- `billing_mode = recurring`
- `billing_interval_unit = month`
- `billing_interval_count = 6`

## 8.3 One-time
Possibile attivazione futura impostando:
- `billing_mode = one_time`

Con uso prevalente di `business_billing_payments` invece di subscription.

## 8.4 Manual
Possibile gestione futura fuori provider automatizzati.

---

# PARTE 9 — MIGRAZIONI / SCHEMA

## 9.1 Non modificare brutalmente `FULL_DATABASE_SCHEMA.sql` senza coerenza
Aggiungere le nuove tabelle in modo coerente con il progetto.
Rispettare naming, engine, charset, collations e convenzioni già usate.

## 9.2 Creare migrazione o patch schema coerente
Se il progetto usa uno schema unico, aggiornare lo schema in modo consistente.
Se ci sono istruzioni/migrazioni separate, seguire lo stile esistente.

---

# PARTE 10 — TEST DA ESEGUIRE

## 10.1 Test backend minimi
Verificare:
1. superadmin può leggere config billing business
2. superadmin può salvare config billing OFF
3. superadmin può salvare config billing ON con prezzo valido
4. business con billing OFF riceve `not_required`
5. business con billing ON e no subscription riceve `inactive`
6. checkout session viene creata solo per business abilitati
7. portal session richiede customer/provider presenti
8. webhook Stripe aggiornano correttamente stato
9. idempotenza webhook funziona

## 10.2 Test frontend minimi
Verificare:
1. schermata `Abbonamento` si apre correttamente
2. business billing OFF mostra solo messaggio informativo
3. business billing ON mostra importo/stato
4. pulsante checkout apre URL
5. pulsante portal apre URL
6. UI superadmin salva configurazione billing business

---

# PARTE 11 — UX / TESTO UI MINIMO CONSIGLIATO

## Business screen
### Stato OFF
- “Questo business non è soggetto a fatturazione.”

### Stato ON ma non attivo
- “Abbonamento richiesto”
- mostra importo mensile
- CTA: “Attiva abbonamento”

### Stato attivo
- “Abbonamento attivo”
- mostra rinnovo
- CTA: “Gestisci abbonamento”

### Stato pagamento fallito
- “Pagamento non riuscito” / “Abbonamento in ritardo”
- CTA: “Gestisci abbonamento”

---

# PARTE 12 — VINCOLI FINALI NON NEGOZIABILI

1. Non rompere auth/router/business switching esistenti.
2. Non introdurre Stripe SDK nel frontend.
3. Non usare il frontend per decidere prezzo o provider.
4. Non rendere il dominio dipendente da Stripe.
5. Implementare Stripe come primo adapter concreto.
6. Lasciare il modello dati pronto per annuale/semestrale/one-time/manual.
7. Attivare concretamente ora solo:
   - non soggetto a pagamento
   - recurring monthly
8. Nessun hard lock funzionale per ora.
9. Webhook idempotenti obbligatori.
10. Tutto il codice nuovo deve essere coerente con lo stile esistente dei due progetti.

---

# DELIVERABLE RICHIESTI A FINE IMPLEMENTAZIONE

1. Modifiche complete `agenda_core`
2. Modifiche complete `agenda_backend`
3. Aggiornamento schema DB coerente
4. Endpoint funzionanti
5. UI business funzionante
6. UI superadmin funzionante
7. Nessuna regressione delle feature esistenti

