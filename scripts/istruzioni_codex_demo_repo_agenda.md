# ISTRUZIONI COMPLETE PER CODEX
## Adattamento del repository Agenda per supportare anche l’ambiente DEMO senza duplicare il codice

### OBIETTIVO

Adattare l’attuale monorepo della piattaforma Agenda in modo che **lo stesso codicebase** possa gestire correttamente:

- `local`
- `demo`
- `staging` (se già presente o previsto)
- `production`

La demo **non deve** essere un progetto separato, **non deve** essere un branch permanente, **non deve** essere una copia del frontend/backend/core.

La demo deve essere:

- stessa applicazione
- stessa architettura
- stesso flusso funzionale
- stesso dominio di business
- stesso repository
- stessi moduli principali

ma con:

- configurazione ambiente dedicata
- DB separato
- policy server-side dedicate
- feature flags ambientali
- seed/reset dati demo
- blocchi su azioni sensibili
- UI minima demo (banner / eventuali messaggi informativi)

---

# VINCOLI OBBLIGATORI

1. **Non rompere nessun comportamento esistente** di frontend, backend e core.
2. **Non cambiare la logica di business attuale** salvo dove necessario per introdurre la gestione ambienti.
3. **Non introdurre fork del progetto**.
4. **Non creare repository separati**.
5. **Non creare branch `demo` permanente**.
6. **Non hardcodare logica demo sparsa in modo disordinato**.
7. Tutta la gestione ambiente deve essere **centralizzata, leggibile, estendibile**.
8. Tutte le azioni sensibili bloccate in demo devono essere bloccate **lato server**, non solo lato UI.
9. Le modifiche devono essere **production-grade**, robuste, pulite e coerenti con l’architettura attuale.
10. Dove possibile, riusare naming, convenzioni e struttura già esistenti nel repo.

---

# RISULTATO FINALE ATTESO

Alla fine il repo deve essere in grado di:

- avviare/deployare l’app in `production` come oggi
- avviare/deployare l’app in `demo` usando lo stesso codice
- differenziare comportamento tramite configurazione ambiente
- mostrare la demo con dati fake e resettabili
- impedire in demo azioni sensibili o reali
- mantenere il prodotto reale totalmente separato a livello di dati e integrazioni

---

# STRATEGIA ARCHITETTURALE

## Concetto chiave

La demo non è una seconda app.

La demo è:

- stesso codice
- ambiente differente
- config differente
- policy differente
- dati differiti
- integrazioni differite
- permessi differiti

## Principio

La differenza tra `demo` e `production` deve vivere solo in questi livelli:

1. **Environment configuration**
2. **Runtime flags**
3. **Server-side environment policy**
4. **Seed / reset dati**
5. **Piccole differenze UI intenzionali**

Non in copie dei moduli.

---

# STRUTTURA DA INTRODURRE NEL REPO

Adattare il monorepo mantenendo la struttura attuale e introducendo una zona esplicita per la gestione ambienti e demo.

## Struttura target minima consigliata

```text
/agenda-platform
  /agenda_frontend
  /agenda_backend
  /agenda_core
  /config
    /environments
      local
      demo
      staging
      production
  /database
    /migrations
    /seeds
    /demo
  /scripts
    /deploy
    /demo
    /db
  /docs
    architecture.md
    environments.md
    demo-environment.md
```

Se alcune cartelle esistono già, **integrarle**, non duplicarle.

---

# FASE 1 — ANALISI E MAPPATURA DEL REPO ATTUALE

Prima di modificare, fare una ricognizione completa del repository attuale e produrre una mappa interna del progetto.

## Individuare con precisione

### Nel frontend
- punto di bootstrap
- inizializzazione config/app
- definizione API base URL
- eventuale gestione flavor/build mode/env
- sistema di dependency injection / provider / config provider
- schermata login
- punti UI dove si mostrano funzioni sensibili
- eventuali servizi client per pagamenti / notifiche / export / webhook / integrazioni

### Nel backend
- entrypoint
- loader config / env
- bootstrap applicazione
- autenticazione/autorizzazione
- controller o endpoint sensibili
- servizi che inviano email / whatsapp / notifiche push
- servizi che toccano billing/pagamenti
- servizi di integrazione esterna
- servizi che fanno operazioni distruttive di alto livello

### Nel core
- file/config globali
- DB config / connessione
- logica business cross-module
- zone dove introdurre le policy demo
- punti dove viene determinato il contesto business/location/utenza
- funzioni riusabili per controllo permessi o policy

## Outcome obbligatorio di questa fase
Codex deve identificare dove centralizzare:

- `AppEnvironment`
- `EnvironmentConfig`
- `EnvironmentPolicy`
- `DemoPolicy`

senza lasciare `if demo` sparsi in modo casuale.

---

# FASE 2 — INTRODUZIONE DEL MODELLO AMBIENTE CONDIVISO

## Obiettivo
Creare un modello ambiente unico e coerente che venga riconosciuto da frontend, backend e core.

## Definire un enum / set chiuso di ambienti

Ambienti supportati:

- `local`
- `demo`
- `staging`
- `production`

## Creare un oggetto/config centrale con almeno queste proprietà

- `environmentName`
- `isLocal`
- `isDemo`
- `isStaging`
- `isProduction`
- `apiBaseUrl`
- `webBaseUrl`
- `showDemoBanner`
- `allowRealEmails`
- `allowRealWhatsapp`
- `allowRealPayments`
- `allowExternalWebhooks`
- `allowDestructiveBusinessActions`
- `allowPlanChanges`
- `allowRealExports` (valutare in base al progetto)
- `demoResetExpected`
- `demoAutoLoginEnabled` (facoltativo, ma predisporre)
- `demoReadOnlySections` (se necessario)

Aggiungere eventuali altre proprietà utili se coerenti con il repo.

## Regole
- nessuna proprietà ambiente deve essere letta direttamente da variabili raw in giro per il codice
- ogni modulo deve passare dal layer centralizzato
- ogni bool sensibile deve avere naming esplicito e non ambiguo

---

# FASE 3 — CONFIGURAZIONE FRONTEND

## Obiettivo
Fare in modo che il frontend sappia in quale ambiente sta girando e si comporti di conseguenza.

## Implementazione richiesta

### 1. Centralizzare la config frontend
Creare o adattare un punto unico di configurazione runtime/build per il frontend.

Il frontend deve poter derivare da ambiente:

- nome ambiente
- API base URL
- banner demo on/off
- label ambiente
- abilitazione/disabilitazione funzioni sensibili
- eventuale auto-login demo
- eventuale testo informativo demo

### 2. Evitare condizioni sparse
Non mettere controlli demo random nelle widget/page senza passare da una config/policy centralizzata.

### 3. UI demo minima da introdurre
In ambiente `demo`:

- banner visibile persistente che segnala ambiente demo
- eventuale testo “i dati vengono resettati periodicamente”
- eventuale disabilitazione o mascheramento di azioni chiaramente non consentite
- eventuali toast/messaggi informativi quando una funzione non è disponibile in demo

### 4. Comportamenti frontend richiesti in demo
- usare API demo
- mostrare badge/banner demo
- non mostrare entrypoint a funzioni reali non supportate se questo migliora UX
- se una funzione è visibile ma vietata, gestirla elegantemente con messaggio chiaro
- non affidarsi mai al solo frontend per la sicurezza

### 5. Login demo
Predisporre il frontend per supportare entrambe le opzioni:

#### opzione A
login classico con utente demo

#### opzione B
auto-login demo o shortcut demo

Anche se l’auto-login non viene attivato subito, la struttura deve renderlo facile.

---

# FASE 4 — CONFIGURAZIONE BACKEND / CORE

## Obiettivo
Tutta la sicurezza e le limitazioni demo devono essere vere lato server.

## Implementazione richiesta

### 1. Environment resolver server-side
Creare/adattare una risoluzione centralizzata dell’ambiente corrente nel backend/core.

### 2. Policy centralizzata
Introdurre una policy server-side chiara, con API tipo:

- `isDemoEnvironment()`
- `canSendRealEmails()`
- `canSendRealWhatsapp()`
- `canUseRealPayments()`
- `canExecuteDestructiveBusinessActions()`
- `canChangeSubscriptionPlan()`
- `canCallExternalWebhooks()`
- `canDeleteBusiness()`
- `canDeleteLocation()` se rilevante
- `canDeleteCriticalData()` se rilevante
- `canRunRealNotifications()`

Le policy devono derivare dall’ambiente, non da controlli sparsi.

### 3. Blocchi obbligatori lato server in demo
In `demo` bloccare almeno:

- creazione di nuovi business reali se non desiderata per la demo
- cancellazione business
- cancellazione location critiche se distruttiva
- modifica piano/abbonamento
- chiamate a provider di pagamento reali
- invio email reali
- invio whatsapp reali
- webhook esterni reali
- integrazioni esterne che generano effetti reali
- eventuale creazione utenti globali reali se non prevista per la demo

Valutare nel repo quali endpoint/servizi mappano questi casi e proteggerli uno per uno.

### 4. Gestione uniforme del rifiuto
Quando una funzione non è permessa in demo, restituire una risposta standardizzata e pulita.

Serve una gestione coerente di:
- codice errore
- messaggio leggibile
- eventuale flag `demo_blocked = true`

Non usare errori casuali o non strutturati.

---

# FASE 5 — FEATURE FLAGS AMBIENTALI

## Obiettivo
Separare chiaramente ciò che è reale da ciò che è simulato.

## Variabili/flag minime da introdurre

A livello backend/core e, dove serve, frontend:

- `APP_ENV`
- `DEMO_MODE`
- `API_BASE_URL`
- `WEB_BASE_URL`
- `ALLOW_REAL_EMAILS`
- `ALLOW_REAL_WHATSAPP`
- `ALLOW_REAL_PAYMENTS`
- `ALLOW_EXTERNAL_WEBHOOKS`
- `ALLOW_DESTRUCTIVE_BUSINESS_ACTIONS`
- `ALLOW_PLAN_CHANGES`
- `SHOW_DEMO_BANNER`
- `DEMO_RESET_EXPECTED`
- `DEMO_AUTO_LOGIN_ENABLED`

Usare naming coerente col progetto, ma conservare questo significato.

## Regole
- validare le variabili ambiente in bootstrap
- fallire velocemente se una config critica manca
- non usare default pericolosi
- in assenza di config esplicita, preferire comportamento safe

---

# FASE 6 — DATABASE DEMO E SEPARAZIONE DATI

## Obiettivo
Separare completamente i dati demo dai dati di produzione.

## Richiesto
- DB demo separato
- credenziali demo separate
- nessuna tabella condivisa con production
- nessuna scrittura cross-environment

## Non fare
- usare production con flag demo
- usare lo stesso DB con dati promiscui reali/fake
- mischiare utenti reali e demo

## Adattamenti richiesti nel core
- rendere la connessione DB dipendente dall’ambiente
- centralizzare risoluzione host/db/user/password
- predisporre config separate per local/demo/staging/production

---

# FASE 7 — SEED DEMO

## Obiettivo
Costruire un dataset demo realistico, stabile e reimportabile.

## Struttura dati demo minima
Preparare seed dedicati che creino:

### business demo
- 1 business principale demo

### location demo
- 1 o più location demo, coerenti col dominio del progetto

### staff demo
almeno 2–4 membri staff realistici

### servizi demo
set realistico di servizi con durate/prezzi coerenti

### clienti demo
set di clienti fake

### prenotazioni demo
agenda popolata e credibile

### eventuali report/demo entities
qualsiasi entità necessaria per mostrare bene il prodotto

## Regole di qualità del seed
- nomi fake ma realistici
- dati coerenti
- agenda non vuota
- slot liberi e occupati entrambi presenti
- nessun dato personale reale
- nessun contatto reale
- nessuna integrazione reale

## Posizionamento
I seed demo devono stare in cartelle dedicate e non mischiati ai seed standard se il repo già distingue ambienti.

---

# FASE 8 — RESET DEMO

## Obiettivo
Predisporre il repository per il reset periodico della demo.

## Script richiesti
Creare script dedicati per:

- reset completo DB demo oppure
- reset parziale controllato (preferibile se il progetto lo consente)

## Approccio consigliato
Preferire reset **parziale e deterministico** se tecnicamente sostenibile:

- eliminare prenotazioni demo mutate
- eliminare clienti creati in demo
- ripristinare seed demo di prenotazioni/clienti
- mantenere entità strutturali stabili come business/location/staff/servizi

Se nel tuo progetto attuale è più sicuro fare reimport completo del DB demo, va bene, ma documentarlo bene.

## Output atteso
Script utilizzabili da cron/deploy, ad esempio:

- prepare demo
- seed demo
- reset demo
- verify demo

Non è obbligatorio fissare i nomi sopra, ma il repo deve avere una struttura equivalente.

---

# FASE 9 — ENDPOINT / SERVIZI DA METTERE SOTTO POLICY DEMO

Codex deve trovare e proteggere tutti i punti del progetto che possono produrre effetti reali o distruttivi.

## Categorie da cercare e coprire obbligatoriamente

### billing / subscription
- cambio piano
- upgrade/downgrade
- cancellazione abbonamento
- checkout
- token/provider pagamento

### messaging
- email
- whatsapp
- sms
- push esterne se rilevanti

### external integrations
- webhook
- crm esterni
- analytics write se impattanti
- provider terzi

### destructive admin actions
- delete business
- delete location
- delete staff critico se rompe l’assetto demo
- delete utenti chiave demo
- reset dati globali non consentiti

### export / document generation
Valutare:
- se restano consentiti con dati fake
- se vanno simulati
- se vanno bloccati

### automation / scheduler
- job automatici reali
- reminder reali
- notifiche reali
- code/queue esterne

Tutto deve passare da policy ambiente.

---

# FASE 10 — UX DEMO

## Obiettivo
Rendere chiaro che l’utente è in demo, senza peggiorare la percezione del prodotto.

## Richiesto nel frontend demo

### banner persistente
Testo del tipo:
- ambiente demo
- dati resettati periodicamente

### messaggi chiari
Quando una funzione è vietata:
- niente errore tecnico sporco
- messaggio semplice e pulito

### evitare frustrazione inutile
Se una funzione è sicuramente indisponibile in demo e non ha valore mostrarla attiva, valutarne disabilitazione o hide UI.

### non alterare UX base
Il resto dell’app deve sembrare reale.

---

# FASE 11 — FILE DI CONFIGURAZIONE PER AMBIENTE

## Obiettivo
Avere config chiare, versionabili e facili da deployare.

## Richiesto
Creare/adattare config separate per:

- local
- demo
- staging
- production

## Per ciascun ambiente gestire almeno
- URL frontend
- URL backend/API
- credenziali DB
- flag demo
- flag integrazioni
- flag policy distruttive
- eventuali chiavi provider differenziate

## Regole
- nessun segreto reale hardcodato nel repo
- commitare solo template/esempi se necessario
- usare file env o sistema equivalente già coerente col progetto
- documentare chiaramente quali variabili servono

---

# FASE 12 — BOOTSTRAP E VALIDAZIONE CONFIG

## Obiettivo
Fallire subito se la config ambiente è incoerente.

## Implementazione richiesta
Nel bootstrap di frontend/backend/core introdurre una validazione che controlli:

- ambiente riconosciuto
- URL obbligatori presenti
- DB config valida
- flag sensibili coerenti
- in `demo`, blocchi sensibili non accidentalmente aperti

## Esempi di inconsistenze da impedire
- `APP_ENV=demo` con `ALLOW_REAL_PAYMENTS=true`
- `APP_ENV=demo` con `ALLOW_REAL_EMAILS=true`
- `APP_ENV=demo` con DB production
- banner demo off in ambiente demo se la policy richiede on

Quando la config è pericolosa, bootstrap deve fallire.

---

# FASE 13 — LOGGING E OSSERVABILITÀ

## Obiettivo
Distinguere facilmente i log demo da quelli di produzione.

## Richiesto
- aggiungere etichetta ambiente nei log
- differenziare output/log path se il progetto lo consente
- tracciare quando una funzione viene bloccata per policy demo
- mantenere log leggibili

Esempi di eventi utili:
- boot in demo
- blocco invio email reale in demo
- blocco pagamento reale in demo
- reset demo eseguito
- seed demo applicato

---

# FASE 14 — TEST

## Obiettivo
Assicurare che production non sia rotta e demo sia davvero protetta.

## Test richiesti

### Test di configurazione
- ambiente local riconosciuto
- ambiente demo riconosciuto
- ambiente production riconosciuto
- config invalida rifiutata

### Test policy
In demo:
- pagamenti reali bloccati
- email reali bloccate
- whatsapp reali bloccati
- webhook reali bloccati
- azioni distruttive bloccate

In production:
- policy non devono bloccare comportamenti leciti

### Test UI/integrazione
- banner demo visibile solo in demo
- API base URL corretto per ambiente
- eventuale login demo coerente
- messaggi demo su funzioni bloccate

Se la codebase ha già test framework/unit/integration, estenderli. Se è carente, introdurre almeno test mirati sui layer nuovi.

---

# FASE 15 — DEPLOY

## Obiettivo
Rendere possibile il deploy dei due ambienti dallo stesso repo.

## Richiesto
Preparare/adattare script o documentazione per:

### production
- dominio reale
- env production
- DB production

### demo
- sottodominio demo
- env demo
- DB demo
- flag demo attivi
- integrazioni reali disattive

## Regole
- nessun passaggio manuale ambiguo
- separazione credenziali netta
- facile ripetibilità

---

# FASE 16 — DOCUMENTAZIONE TECNICA DA AGGIUNGERE NEL REPO

Codex deve aggiungere o aggiornare documentazione minima obbligatoria.

## 1. `docs/environments.md`
Deve spiegare:
- ambienti supportati
- differenze tra ambienti
- variabili richieste
- bootstrap config
- principi di sicurezza

## 2. `docs/demo-environment.md`
Deve spiegare:
- cos’è la demo
- cosa è bloccato
- come fare seed/reset
- come deployarla
- come verificare che sia sicura

## 3. eventuale update `README.md`
Aggiungere sezione:
- ambienti
- avvio demo
- deploy demo
- note importanti

La documentazione deve essere coerente con il codice implementato, non teorica.

---

# FASE 17 — CHECKLIST IMPLEMENTATIVA OBBLIGATORIA

Codex deve eseguire tutte le attività seguenti.

## A. Environment foundation
- [ ] individuare bootstrap frontend/backend/core
- [ ] introdurre enum/identificatore ambienti
- [ ] introdurre config centralizzata
- [ ] introdurre validazione config

## B. Frontend
- [ ] centralizzare lettura ambiente
- [ ] centralizzare API base URL
- [ ] introdurre banner demo
- [ ] introdurre eventuali messaggi demo
- [ ] evitare condizioni sparse e disordinate

## C. Backend/Core
- [ ] centralizzare risoluzione ambiente
- [ ] introdurre `EnvironmentPolicy` / equivalente
- [ ] proteggere servizi sensibili
- [ ] standardizzare risposta “bloccato in demo”

## D. Database
- [ ] predisporre DB demo separato
- [ ] predisporre config connessione demo
- [ ] impedire uso accidentale di DB production in demo

## E. Seed/Reset
- [ ] creare seed demo
- [ ] creare reset demo
- [ ] predisporre script richiamabili
- [ ] documentare uso e scopo

## F. Deploy
- [ ] rendere possibile deploy demo e production dallo stesso repo
- [ ] differenziare config/env
- [ ] documentare i passaggi

## G. Testing
- [ ] test policy demo
- [ ] test config ambienti
- [ ] test base integrazione frontend/backend per demo

## H. Docs
- [ ] aggiornare documentazione ambienti
- [ ] aggiungere documentazione demo
- [ ] aggiornare README se necessario

---

# FASE 18 — CRITERI DI ACCETTAZIONE

Il lavoro è accettabile solo se tutti i punti seguenti risultano veri.

## Architettura
- esiste un solo codicebase
- non esistono copie demo dei moduli
- l’ambiente è centralizzato e leggibile

## Sicurezza
- in demo le azioni reali/sensibili sono bloccate lato server
- non è possibile colpire accidentalmente production dalla demo
- le config pericolose vengono rifiutate in bootstrap

## UX
- l’ambiente demo è chiaramente identificabile
- l’app demo resta credibile e usabile
- le funzioni bloccate hanno messaggi puliti

## Operatività
- esiste una procedura chiara per seed/reset demo
- esiste una procedura chiara per deploy demo
- production continua a funzionare

## Qualità codice
- niente hardcode demo caotici
- niente if sparsi non centralizzati
- naming coerente
- refactor localizzato e pulito
- documentazione aggiornata

---

# FASE 19 — REGOLE DI IMPLEMENTAZIONE

## Regole tecniche obbligatorie
1. Conservare tutti i comportamenti esistenti non correlati.
2. Non introdurre regressioni.
3. Non fare refactor estetici inutili fuori scope.
4. Limitare le modifiche alle aree necessarie.
5. Se serve refactor, farlo solo per centralizzare bene config/policy.
6. Ogni nuova astrazione deve avere scopo reale.
7. Evitare soluzioni “temporary hack”.
8. Evitare duplicazioni di logica tra frontend/backend/core.
9. Privilegiare naming espliciti.
10. Documentare tutto ciò che viene introdotto.

---

# FASE 20 — OUTPUT FINALE CHE CODEX DEVE PRODURRE

A fine lavoro Codex deve consegnare:

## 1. Codice aggiornato
Con tutte le modifiche necessarie nel repo.

## 2. Elenco file modificati/creati
Con breve motivazione per ciascuno.

## 3. Spiegazione sintetica dell’architettura introdotta
Molto concreta, niente teoria inutile.

## 4. Istruzioni operative finali
Con:
- come configurare `demo`
- come configurare `production`
- come fare seed demo
- come fare reset demo
- come verificare che i blocchi demo funzionino

## 5. Verifica finale esplicita
Con checklist di conformità rispetto a:
- no duplicazione codice
- demo lato server protetta
- config ambienti centralizzata
- deploy multi-environment possibile

---

# PRIORITÀ ASSOLUTE

Se ci sono trade-off, rispettare queste priorità in ordine:

1. sicurezza e separazione demo/production
2. nessuna rottura del prodotto reale
3. pulizia architetturale
4. facilità di deploy multi-environment
5. UX demo pulita
6. estendibilità futura

---

# NOTA CONCLUSIVA PER CODEX

Lavora **sul repository esistente** e **adatta l’architettura attuale**, senza reinventare il progetto.

Devi ottenere un repo in cui:

- la piattaforma reale continua a funzionare
- la demo è gestita come ambiente ufficiale
- la demo usa lo stesso codicebase
- la separazione è affidabile
- il setup è professionale, robusto ed estendibile

Non lasciare parti a metà.
Non lasciare TODO vaghi.
Non lasciare logica demo incompleta.
Non dare per scontato nulla: trova nel repo i punti corretti e integrali in modo coerente.
