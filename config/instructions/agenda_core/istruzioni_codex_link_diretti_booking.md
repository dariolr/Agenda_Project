# Istruzioni Codex — Link diretti booking e visibilità online

## Obiettivo

Implementare nella piattaforma Agenda un sistema professionale di visibilità online e link diretti per servizi, pacchetti, eventi/classi e categorie, mantenendo compatibilità con il codice attuale.

La feature deve permettere questi casi:

- elemento visibile normalmente nella pagina booking pubblica;
- elemento nascosto dalla pagina pubblica ma prenotabile tramite link diretto;
- elemento non prenotabile online;
- categoria pubblica che mostra solo elementi pubblici;
- categoria riservata/direct-link che mostra anche elementi direct-link;
- location usata solo come filtro operativo, senza sbloccare elementi direct-link.

## Regola prodotto definitiva

Introdurre tre stati di visibilità online:

```text
public
```

Visibile nella pagina booking normale e prenotabile online.

```text
direct_link
```

Nascosto dalla pagina booking normale, ma prenotabile tramite link diretto.

```text
hidden
```

Non visibile e non prenotabile online.

## Regole di visibilità

### Pagina booking normale

URL esempio:

```text
/{businessSlug}/booking
```

Deve mostrare solo elementi con:

```text
online_visibility = 'public'
```

### Link diretto a servizio, pacchetto o evento

URL esempio:

```text
/{businessSlug}/booking?link=consulenza-vip
```

Se il link punta direttamente a un servizio/pacchetto/evento, il target è valido solo se:

```text
online_visibility IN ('public', 'direct_link')
```

Non deve mai essere valido se:

```text
online_visibility = 'hidden'
```

### Link diretto a categoria

Se il link punta a una categoria:

- categoria `public`: mostra solo figli `public`;
- categoria `direct_link`: mostra figli `public` + `direct_link`;
- categoria `hidden`: non mostra nulla e deve rispondere come link non disponibile.

### Link diretto a location

La location deve restare un filtro operativo.

Un link location non deve sbloccare elementi `direct_link`.

Quindi:

```text
/{businessSlug}/booking?location=4
```

continua a mostrare solo elementi `public` disponibili in quella location.

## Stato attuale da rispettare

Nel codice attuale esistono già:

- `service_variants.is_bookable_online`;
- `service_packages.is_bookable_online`;
- `class_events.is_bookable_online`;
- `class_events.visibility` con `PUBLIC/PRIVATE`;
- router booking path-based `/:slug/booking`;
- query param già letti dal router frontend per `location` e `lang`;
- provider `routeSlugProvider`, `urlLocationIdProvider`, `bookingUrlLangProvider`.

Non rimuovere subito `is_bookable_online`: mantenerlo per compatibilità e migrazione.

## Implementazione database

Creare una nuova migrazione in `agenda_core/../config/migrations/`.

Nome consigliato:

```text
20260429_booking_direct_links_and_online_visibility.sql
```

La migrazione deve essere idempotente e phpMyAdmin-ready, seguendo lo stile già usato nelle migrazioni recenti.

### 1. Aggiungere `online_visibility`

Aggiungere la colonna:

```sql
online_visibility ENUM('public','direct_link','hidden') NOT NULL DEFAULT 'public'
```

alle tabelle:

```text
service_variants
service_packages
class_events
service_categories
```

### 2. Migrare i dati esistenti

Per `service_variants`, `service_packages`, `class_events`:

```text
is_bookable_online = 1 -> online_visibility = 'public'
is_bookable_online = 0 -> online_visibility = 'hidden'
```

Per `service_categories`:

```text
online_visibility = 'public'
```

### 3. Creare tabella `booking_direct_links`

Creare tabella:

```sql
CREATE TABLE booking_direct_links (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL,
  slug VARCHAR(160) NOT NULL,
  target_type ENUM('service_variant','service_package','class_event','service_category') NOT NULL,
  target_id INT UNSIGNED NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_booking_direct_links_business_slug (business_id, slug),
  KEY idx_booking_direct_links_business_active (business_id, is_active),
  KEY idx_booking_direct_links_target (target_type, target_id),
  CONSTRAINT fk_booking_direct_links_business
    FOREIGN KEY (business_id) REFERENCES businesses(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Non mettere foreign key dinamiche verso le singole tabelle target: `target_type + target_id` viene validato lato repository/service.

### 4. Aggiornare `FULL_DATABASE_SCHEMA.sql`

Aggiornare anche `config/migrations/FULL_DATABASE_SCHEMA.sql`, come richiesto dalle regole del progetto.

## Slug diretto

Lo slug deve essere unico per business.

Esempi validi:

```text
consulenza-vip
percorsi-sposa
pilates-avanzato
```

Regole slug:

- lowercase;
- solo lettere, numeri e trattini;
- niente spazi;
- niente slash;
- lunghezza massima 160;
- generazione automatica da nome target;
- in caso di collisione aggiungere suffisso `-2`, `-3`, ecc.

Esempio:

```text
consulenza-vip
consulenza-vip-2
```

## Backend `agenda_core`

### 1. Nuovo repository `BookingDirectLinkRepository`

Creare repository dedicato, ad esempio:

```text
src/Infrastructure/Persistence/BookingDirectLinkRepository.php
```

Responsabilità:

- `findByBusinessAndSlug(int $businessId, string $slug): ?array`
- `findByTarget(int $businessId, string $targetType, int $targetId): ?array`
- `createOrUpdateForTarget(...)`
- `deactivateForTarget(...)`
- `generateUniqueSlug(int $businessId, string $baseName): string`
- validare `target_type` contro la whitelist.

### 2. Endpoint pubblico resolve link

Aggiungere endpoint pubblico:

```text
GET /v1/public/booking-direct-links/resolve?business_slug={slug}&link={directSlug}
```

Response success:

```json
{
  "success": true,
  "data": {
    "business_id": 1,
    "business_slug": "romeolab",
    "link_slug": "consulenza-vip",
    "target_type": "service_variant",
    "target_id": 123,
    "target": { }
  }
}
```

Response errore:

```json
{
  "success": false,
  "error": {
    "code": "booking_direct_link_not_available",
    "message": "Booking direct link is not available"
  }
}
```

Status consigliati:

- `404` se link inesistente;
- `409` se link esistente ma target non prenotabile;
- `400` se parametri invalidi.

### 3. Validazione resolver

Il resolver deve:

1. trovare business da `business_slug`;
2. trovare record attivo in `booking_direct_links`;
3. caricare il target in base a `target_type`;
4. verificare che il target appartenga allo stesso business;
5. verificare che il target sia attivo/schedulato/non cancellato;
6. verificare `online_visibility`;
7. restituire payload minimo per preselezione frontend.

### 4. Regole target specifiche

#### `service_variant`

Valido se:

- variante attiva;
- servizio padre attivo;
- location attiva;
- `online_visibility IN ('public','direct_link')`;
- vecchio `is_bookable_online = 1` oppure compatibilità coerente con `online_visibility`.

#### `service_package`

Valido se:

- pacchetto attivo;
- non rotto (`is_broken = 0`);
- location attiva;
- `online_visibility IN ('public','direct_link')`.

#### `class_event`

Valido se:

- `status = 'SCHEDULED'`;
- location attiva;
- evento non passato;
- finestra booking rispettata;
- `online_visibility IN ('public','direct_link')`;
- mantenere compatibilità con `visibility = 'PUBLIC'` solo se oggi è già usata come vincolo reale nel booking pubblico.

Nota importante: non usare più `visibility = PRIVATE` come sinonimo automatico di link diretto. La nuova fonte di verità per il booking online deve essere `online_visibility`.

#### `service_category`

Valida se:

- categoria esistente nello stesso business;
- `online_visibility IN ('public','direct_link')`.

Payload resolver deve indicare:

```json
{
  "target_type": "service_category",
  "target_id": 10,
  "child_visibility_scope": "public_only"
}
```

oppure:

```json
{
  "target_type": "service_category",
  "target_id": 10,
  "child_visibility_scope": "public_and_direct_link"
}
```

Dove:

- categoria `public` -> `public_only`;
- categoria `direct_link` -> `public_and_direct_link`.

### 5. Endpoint pubblici esistenti

Tutti gli endpoint pubblici che alimentano la booking page normale devono filtrare:

```sql
online_visibility = 'public'
```

Non basta più filtrare solo `is_bookable_online = 1`.

Per retrocompatibilità usare temporaneamente entrambi:

```sql
is_bookable_online = 1
AND online_visibility = 'public'
```

Dove si gestisce un link diretto risolto, consentire:

```sql
online_visibility IN ('public','direct_link')
```

### 6. Creazione/modifica servizio, pacchetto, evento, categoria

Aggiornare repository/controller per accettare `online_visibility`.

Validare solo valori:

```text
public
direct_link
hidden
```

Quando `online_visibility = hidden`, impostare anche `is_bookable_online = 0` per compatibilità.

Quando `online_visibility IN ('public','direct_link')`, impostare `is_bookable_online = 1` per compatibilità.

### 7. Gestione automatica link diretto

Quando un target viene impostato a `direct_link`, creare automaticamente un record in `booking_direct_links` se non esiste.

Quando torna a `public`, mantenere il link esistente attivo: il link resta valido ma il target è anche pubblico.

Quando diventa `hidden`, non cancellare il link, ma il resolver deve considerarlo non disponibile.

Quando un target viene disattivato/cancellato, disattivare o rendere non disponibile il link.

## Frontend booking `agenda_frontend`

### 1. Router

Nel router `agenda_frontend/lib/app/router.dart`, leggere anche il query param:

```text
link
```

Oggi sono già letti `location` e `lang`. Aggiungere provider dedicato:

```text
bookingDirectLinkSlugProvider
```

Da aggiornare nello stesso `Future.microtask` già usato per slug, location e lang.

### 2. Provider link diretto

Creare provider che:

- legge `routeSlugProvider`;
- legge `bookingDirectLinkSlugProvider`;
- se il link è null non fa nulla;
- se presente chiama endpoint resolve;
- espone stato `loading/success/error`.

Nome consigliato:

```text
bookingDirectLinkProvider
```

### 3. ApiClient

Aggiungere metodo:

```text
resolveBookingDirectLink({required String businessSlug, required String linkSlug})
```

Chiamata:

```text
GET /v1/public/booking-direct-links/resolve?business_slug=...&link=...
```

### 4. Preselezione target

Se il resolver torna:

```text
service_variant
```

preselezionare quel servizio/variante.

Se torna:

```text
service_package
```

preselezionare quel pacchetto.

Se torna:

```text
class_event
```

preselezionare quell’evento e impedire selezione contemporanea di servizi/pacchetti, rispettando la logica già esistente.

Se torna:

```text
service_category
```

filtrare la lista servizi/pacchetti a quella categoria e applicare `child_visibility_scope`:

- `public_only` -> mostra solo figli `public`;
- `public_and_direct_link` -> mostra figli `public` + `direct_link`.

### 5. UI booking

Se link diretto non disponibile:

- mostrare stato errore chiaro;
- testo IT: `Questo link di prenotazione non è più disponibile.`;
- testo EN: `This booking link is no longer available.`;
- non mostrare lista generale come fallback automatico, per evitare confusione.

Se link diretto valido:

- non mostrare elementi `hidden`;
- non sbloccare direct_link tramite location;
- non mostrare direct_link di altre categorie;
- non permettere manipolazione URL per accedere a target hidden.

## Gestionale `agenda_backend`

### 1. Modelli Dart

Aggiornare modelli per includere:

```text
onlineVisibility
bookingDirectLinkUrl / directLinkSlug se utile
```

Su:

- service variant/service model;
- service package model;
- class event model;
- service category model.

### 2. Form servizi

Nel form servizio/variante aggiungere campo:

```text
Prenotazione online
```

Opzioni:

```text
Visibile nella pagina pubblica
Solo tramite link diretto
Non prenotabile online
```

Mapping:

```text
Visibile nella pagina pubblica -> public
Solo tramite link diretto -> direct_link
Non prenotabile online -> hidden
```

Rimuovere dalla UI finale la vecchia logica binaria se crea confusione. Internamente può ancora aggiornare `is_bookable_online` per compatibilità.

### 3. Form pacchetti

Stessa logica dei servizi.

### 4. Form eventi/classi

Aggiungere stesso campo su evento programmato.

Non confondere con `visibility PUBLIC/PRIVATE`. Se `visibility` resta in UI, chiarire che riguarda la logica interna/gestionale, non il link diretto.

### 5. Form categorie

Aggiungere `online_visibility` anche alla categoria.

Spiegazione UI breve:

```text
Se la categoria è “Solo tramite link diretto”, il suo link può mostrare anche servizi e pacchetti riservati.
```

### 6. Pulsante copia link

Per ogni elemento con `online_visibility = direct_link` o `public`, mostrare azione:

```text
Copia link diretto
```

URL generato:

```text
{FRONTEND_URL}/{businessSlug}/booking?link={slug}
```

Usare il valore frontend configurato, non hardcodare domini.

Se il link non esiste ancora, il backend deve generarlo al salvataggio o fornire endpoint `createOrGet`.

### 7. Traduzioni

Aggiungere chiavi IT/EN per:

- `Visibile nella pagina pubblica`;
- `Solo tramite link diretto`;
- `Non prenotabile online`;
- `Copia link diretto`;
- `Link copiato`;
- `Questo link di prenotazione non è più disponibile`.

## API admin

Aggiungere/estendere endpoint admin per leggere e gestire link diretti.

Minimo necessario:

```text
GET /v1/businesses/{business_id}/booking-direct-links?target_type=...&target_id=...
POST /v1/businesses/{business_id}/booking-direct-links/create-or-get
PATCH /v1/businesses/{business_id}/booking-direct-links/{id}
```

Payload `create-or-get`:

```json
{
  "target_type": "service_variant",
  "target_id": 123
}
```

Response:

```json
{
  "id": 1,
  "slug": "consulenza-vip",
  "target_type": "service_variant",
  "target_id": 123,
  "url": "https://prenota.romeolab.it/romeolab/booking?link=consulenza-vip"
}
```

## Compatibilità con `is_bookable_online`

Non eliminare i campi esistenti.

Durante questa implementazione:

```text
online_visibility = public       -> is_bookable_online = 1
online_visibility = direct_link  -> is_bookable_online = 1
online_visibility = hidden       -> is_bookable_online = 0
```

Tutte le nuove decisioni di prodotto devono però leggere `online_visibility` come fonte principale.

## Sicurezza

Il link diretto non è una password.

Non trattarlo come accesso personale riservato.

Il resolver deve comunque impedire:

- accesso cross-business;
- target hidden;
- target inattivi;
- eventi cancellati/completati/passati;
- pacchetti rotti;
- location inattive;
- slug non validi;
- target type non ammessi.

Non usare id numerici nei link pubblici.

## Test obbligatori backend

Aggiungere test o casi verificabili per:

1. booking page normale mostra solo `public`;
2. servizio `direct_link` non compare nella pagina normale;
3. servizio `direct_link` è risolvibile dal proprio link;
4. servizio `hidden` non è risolvibile dal proprio link;
5. categoria `public` mostra solo figli `public`;
6. categoria `direct_link` mostra figli `public + direct_link`;
7. location non sblocca figli `direct_link`;
8. slug duplicato genera suffisso;
9. link cross-business non risolve;
10. class_event cancellato/completato/passato non risolve;
11. pacchetto rotto non risolve;
12. valori invalidi di `online_visibility` vengono rifiutati.

## Test frontend booking

Verificare manualmente o con test:

1. apertura `/{slug}/booking` senza link;
2. apertura `/{slug}/booking?link=servizio-vip`;
3. apertura link scaduto/non valido;
4. apertura link categoria pubblica;
5. apertura link categoria direct_link;
6. cambio lingua con `lang` insieme a `link`;
7. location query param insieme a `link`;
8. refresh pagina con link diretto;
9. deep link da WhatsApp/SMS/email.

## Vincoli tecnici

- Non introdurre breaking change API.
- Non rimuovere `is_bookable_online`.
- Non cambiare il comportamento della disponibilità/staff planning.
- Non rompere multi-service booking.
- Non rompere class events/waitlist.
- Non cambiare le route principali esistenti.
- Non usare mock data.
- Aggiornare sempre schema, API contract e traduzioni.
- Non eseguire deploy produzione.

## File/aree da controllare

### `agenda_core`

- migrations;
- `FULL_DATABASE_SCHEMA.sql`;
- repository servizi/pacchetti/categorie/eventi;
- controller pubblici booking;
- controller class events;
- router API;
- api contract;
- test PHP.

### `agenda_frontend`

- `lib/app/router.dart`;
- provider booking URL params;
- API client;
- provider servizi/pacchetti/eventi;
- booking screen/flow selezione;
- l10n IT/EN.

### `agenda_backend`

- modelli servizi/pacchetti/eventi/categorie;
- dialog form servizio;
- dialog form pacchetto;
- dialog form evento/classe;
- dialog categoria;
- API client;
- l10n IT/EN;
- azione copia link diretto.

## Definizione di completato

L’implementazione è completa solo se:

- esiste `online_visibility` sulle quattro tabelle richieste;
- esiste `booking_direct_links`;
- il booking pubblico mostra solo `public`;
- i link diretti funzionano tramite `?link=slug`;
- categoria `direct_link` sblocca figli `direct_link`;
- location non sblocca figli `direct_link`;
- `hidden` non è mai prenotabile online;
- gestionale permette di scegliere i tre stati;
- gestionale permette di copiare link diretto;
- frontend booking gestisce link non disponibile;
- vecchi flag `is_bookable_online` restano coerenti;
- schema, API contract e traduzioni sono aggiornati;
- test/verifiche principali passano.
