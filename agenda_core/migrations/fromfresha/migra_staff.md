# AGENDA – AGENT TASK
## Migrazione staff da CSV a database

### OBIETTIVO
ESEGUIRE SOLO SU ESPLICITA RICHIESTA. Leggere il CSV employees e inserire i dati nel database di produzione.

---

## INPUT
1. File CSV: `employees_export_2026-01-02.csv` (nella stessa cartella)
2. Parametri:
   - BUSINESS_ID: 1
   - LOCATION_ID: 4

---

## FILTRI DI IMPORTAZIONE
- **Status** = "Active"
- **Appointments** = "Enabled"

Record che NON soddisfano entrambi i criteri vengono IGNORATI.

---

## MAPPATURA CSV → DATABASE

### Tabella: staff
| Campo DB | Campo CSV | Note |
|----------|-----------|------|
| business_id | - | Costante: 1 |
| name | First Name | - |
| surname | Last Name | Default '' se vuoto |
| color_hex | - | Generato casualmente o sequenziale |
| avatar_url | - | NULL |
| sort_order | - | Indice progressivo (0, 1, 2...) |
| is_default | - | 1 per il primo, 0 per gli altri |
| is_bookable_online | - | 1 (derivato da Appointments=Enabled) |
| is_active | - | 1 (derivato da Status=Active) |

### Tabella: staff_locations
Ogni staff viene associato alla LOCATION_ID specificata.

---

## RECORD DA IMPORTARE (filtrati)

| First Name | Last Name | Email | Job Title |
|------------|-----------|-------|-----------|
| Giovanni | Santoro | santoro.barber.1994@gmail.com | Accademia Artestile Nettuno |
| Giusy | (vuoto) | feolagiuseppina655@gmail.com | (vuoto) |

**Totale: 2 staff**

---

## REGOLE VINCOLANTI
- ESEGUIRE le query sul database, NON generare file SQL
- Usare dotenv per le credenziali DB
- Associare ogni staff a location_id=4
- **NON creare associazioni tra tabelle** (es. staff_services) se non esplicitate nel CSV o nelle istruzioni

---

## METODO DI ESECUZIONE (SENZA CONFERME)

**NON creare file temporanei locali** (es. in /tmp/ o nel workspace) — richiedono conferma utente.

**Creare lo script DIRETTAMENTE sul server** usando heredoc via SSH:

```bash
# 1. Creare script PHP direttamente sul server (NO file locali)
ssh siteground 'cat > www/api.romeolab.it/import_script.php << '\''EOFPHP'\'''
<?php
// ... codice PHP ...
EOFPHP
'

# 2. Eseguire sul server
ssh siteground 'cd www/api.romeolab.it && php -d display_errors=1 import_script.php'

# 3. Rimuovere dal server
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
- Usare dotenv per le credenziali DB
- Associare ogni staff a location_id=4
- Associare ogni staff a TUTTI i servizi del business_id=1
