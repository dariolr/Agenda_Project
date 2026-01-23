# Migrazione Clienti da Fresha

## Prerequisiti

1. File CSV esportato da Fresha: `export_customer_list.csv`
2. Business già creato nel DB (business_id = 2 per Ego3Estetica)
3. PHP 8.x con estensione PDO

## Configurazione

Modificare le costanti in `import_clients.php`:

```php
const BUSINESS_ID = 2;  // ID del business di destinazione
const CSV_FILE = 'export_customer_list_2026-01-23.csv';
const SKIP_BLOCKED = false;  // true = salta clienti bloccati, false = importa come archiviati
```

## Mapping CSV → Database

| Campo CSV | Campo DB | Trasformazione |
|-----------|----------|----------------|
| Client ID | - | Non importato (ID Fresha) |
| First Name | first_name | Trim |
| Last Name | last_name | Trim |
| Email | email | Lowercase, trim |
| Mobile Number | phone | Rimuovi spazi, aggiungi + |
| Telephone | phone | Fallback se Mobile vuoto |
| Gender | gender | Trim |
| Date of Birth | birth_date | Formato YYYY-MM-DD |
| City | city | Trim |
| Note | notes | Trim |
| Blocked | is_archived | "Yes" → 1, altrimenti 0 |
| Added | created_at | Data creazione |

## Regole di importazione

1. **Duplicati email**: I clienti con email già presente nel DB vengono saltati
2. **Clienti bloccati**: Se `SKIP_BLOCKED = true` vengono saltati, altrimenti importati con `is_archived = 1`
3. **Righe senza nome**: Saltate automaticamente
4. **Telefono**: Normalizzato rimuovendo spazi e aggiungendo prefisso `+`
5. **Password**: Non impostata (`password_hash = NULL`), i clienti dovranno registrarsi

## Esecuzione

```bash
cd /path/to/agenda_core
php migrations/fromfresha/import_clients.php
```

## Output atteso

```
Connessione DB OK

Headers CSV: Client ID, First Name, Last Name, ...

Clienti da importare: 1234
Clienti bloccati saltati: 5
Righe senza nome saltate: 2

Email già presenti nel DB: 0

=== REPORT FINALE ===
Clienti inseriti: 1227
Duplicati email saltati: 0
Business ID: 2
=====================
```

## Note

- I clienti importati NON hanno password impostata
- Per prenotare online dovranno registrarsi con la stessa email
- Il sistema collegherà automaticamente il profilo esistente al nuovo account (match per email)
- I clienti con `is_archived = 1` non appaiono nelle liste ma restano nel DB
