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
| color_hex | - | Assegnato in sequenza dalla palette staff (vedi sotto) |
| avatar_url | - | NULL |
| sort_order | - | Indice progressivo (0, 1, 2...) |
| is_default | - | 1 per il primo, 0 per gli altri |
| is_bookable_online | - | 1 (derivato da Appointments=Enabled) |
| is_active | - | 1 (derivato da Status=Active) |

### Colori Staff (Palette ufficiale)
I colori vengono assegnati **in ordine sequenziale** dallo staff index.
La palette ha 36 colori, se ci sono più staff si ricomincia dal primo.

| Index | HEX | Nome indicativo |
|-------|-----|-----------------|
| 0 | #FFC400 | Giallo |
| 1 | #FFA000 | Amber |
| 2 | #FF6D00 | Arancione |
| 3 | #FF3D00 | Arancione scuro |
| 4 | #D50000 | Rosso |
| 5 | #B71C1C | Rosso scuro |
| 6 | #F50057 | Magenta |
| 7 | #C51162 | Rosa |
| 8 | #AA00FF | Viola |
| 9 | #6200EA | Viola scuro |
| 10 | #304FFE | Indaco |
| 11 | #1A237E | Indaco scuro |
| 12 | #2962FF | Blu |
| 13 | #1565C0 | Blu scuro |
| 14 | #0091EA | Azzurro |
| 15 | #00B0FF | Azzurro chiaro |
| 16 | #00B8D4 | Ciano |
| 17 | #00838F | Ciano scuro |
| 18 | #00BFA5 | Teal |
| 19 | #00796B | Teal scuro |
| 20 | #00C853 | Verde |
| 21 | #2E7D32 | Verde scuro |
| 22 | #76FF03 | Lime |
| 23 | #AEEA00 | Verde acido |
| 24 | #FF9100 | Arancione extra |
| 25 | #E65100 | Arancione bruciato |
| 26 | #AD1457 | Rosa scuro |
| 27 | #7B1FA2 | Viola extra |
| 28 | #3949AB | Indaco extra |
| 29 | #00897B | Teal extra |
| 30 | #43A047 | Verde extra |
| 31 | #558B2F | Verde oliva |
| 32 | #01579B | Blu navy |
| 33 | #006064 | Ciano scuro extra |
| 34 | #4E342E | Marrone |
| 35 | #37474F | Grigio blu |

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
- **GESTIRE staff esistenti** per il business_id PRIMA di inserire i nuovi:
  - Staff **con booking esistenti**: soft delete (is_active=0, is_bookable_online=0)
  - Staff **senza booking**: eliminazione fisica
- L'eliminazione include sempre: staff_locations, staff_services
- **NON creare associazioni staff_services** — le associazioni servizi vengono configurate manualmente nel gestionale

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
