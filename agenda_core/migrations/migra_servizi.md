# AGENDA – AGENT TASK
## Migrazione servizi da CSV a database

### OBIETTIVO
ESEGUIRE SOLO SU ESPLICITA RICHIESTA. Leggere il CSV servizi ed eseguire direttamente le INSERT sul database di produzione tramite SSH tunnel.

---

## INPUT
1. File CSV servizi: `migra_servizi.csv` (nella stessa cartella)
2. Parametri:
   - BUSINESS_ID (default: 1)
   - LOCATION_ID (default: 4)

---

## OUTPUT ATTESO
1. Dati inseriti direttamente nel DB di produzione
2. Nessuna omissione di righe o colonne
3. Report finale con conteggi

---

## REGOLE VINCOLANTI (NON VIOLARE)
- ESEGUIRE le query sul database, NON generare file SQL
- NON omettere colonne di `service_variants`
- NON cambiare l'ordine dei servizi rispetto al CSV
- NON accorpare servizi
- NON inventare dati non presenti nel CSV
- **IMPORTARE SOLO** i servizi con campo "Risorsa" VALORIZZATO (non vuoto)

---

## METODO DI ESECUZIONE (SENZA CONFERME)

**NON creare file nel workspace** (richiedono conferma utente).

Usare questo metodo che non richiede intervento:

```bash
# 1. Creare script PHP in /tmp/ (fuori dal workspace)
cat > /tmp/import_script.php << 'EOFPHP'
<?php
// ... codice PHP ...
EOFPHP

# 2. Copiare sul server
scp /tmp/import_script.php siteground:www/api.romeolab.it/import_script.php

# 3. Eseguire sul server
ssh siteground 'cd www/api.romeolab.it && php -d display_errors=1 import_script.php'

# 4. Rimuovere dal server
ssh siteground 'rm www/api.romeolab.it/import_script.php'
```

**Nota:** Lo script PHP deve usare dotenv per le credenziali:
```php
require_once __DIR__ . '/vendor/autoload.php';
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();
$pdo = new PDO(
    "mysql:host={$_ENV['DB_HOST']};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
    $_ENV['DB_USERNAME'],
    $_ENV['DB_PASSWORD']
);
```

---

## CONNESSIONE DATABASE

Usare SSH tunnel verso SiteGround:
```bash
ssh -p 18765 -L 3307:127.0.0.1:3306 romeolab@ssh.romeolab.it
```

Poi eseguire query con:
```bash
mysql -h 127.0.0.1 -P 3307 -u <DB_USER> -p <DB_NAME>
```

Oppure usare un tool che supporta tunnel SSH diretto.

---

## MAPPATURA CSV → DATABASE

### services
- `business_id` = BUSINESS_ID
- `category_id` = lookup su `service_categories` per nome categoria
- `name` = nome servizio CSV **senza** suffisso `- From`
- `description` = colonna CSV "Descrizione" (NULL se vuota)
- `sort_order` = posizione del servizio nel CSV (0..N-1)
- `is_active` = 1

### service_categories
- Creare **tutte** le categorie trovate nel CSV
- Ordine = ordine di prima apparizione nel CSV
- `business_id` = BUSINESS_ID

### service_variants (TUTTE LE COLONNE DEVONO ESSERE PRESENTI)
- `service_id` = id del servizio appena inserito
- `location_id` = LOCATION_ID
- `duration_minutes` = da CSV "Durata" (convertire in minuti)
- `processing_time` = da CSV "Tempo supplementare" (estrarre minuti, 0 se vuoto)
- `blocked_time` = 0
- `price` = da CSV "Prezzo al dettaglio"
- `currency` = '€'
- `color_hex` = NULL
- `is_bookable_online` = 1 se CSV "Prenotazione online" = 'Abilitati', else 0
- `is_free` = 1 se price = 0, else 0
- `is_price_starting_from` = 1 se nome contiene '- From', else 0
- `is_active` = 1

---

## REGOLE DI VALORIZZAZIONE

### duration_minutes
Formati supportati: `2h 35m`, `1h`, `45m` → convertire in minuti totali

### processing_time
Estrarre da "Tempo supplementare" es. `50m tempo di attesa dopo il trattamento` → 50

### is_price_starting_from
`1` se il nome servizio CSV contiene `- From`, poi rimuovere il suffisso dal nome

---

## PROCEDURA DI ESECUZIONE

1. Leggere CSV `migra_servizi.csv`
2. Estrarre categorie uniche (in ordine di apparizione)
3. Connettersi al database
4. Eseguire cleanup (DELETE):
   - `service_variants` per location
   - `services` per business
   - `service_categories` per business
5. Inserire `service_categories`
6. Per ogni servizio nel CSV:
   - Inserire in `services`
   - Recuperare ID inserito
   - Inserire in `service_variants`
7. Stampare report finale con conteggi

---

## REPORT FINALE

Dopo l'esecuzione, mostrare:
- Numero categorie inserite
- Numero servizi inseriti
- Numero varianti inserite
