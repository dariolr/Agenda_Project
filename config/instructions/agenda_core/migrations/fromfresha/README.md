# Migrazione Dati da Fresha

Questa directory contiene gli script per importare dati da Fresha.

## ⚡ Quick Start

1. **Configura `config.php`** con i tuoi ID business e location
2. Posiziona i file CSV esportati da Fresha in questa directory
3. Esegui gli script in ordine:
   - `php import_services.php` (prima i servizi)
   - `php import_staff.php` (poi lo staff)
   - `php import_clients.php` (infine i clienti)

## 📁 File di Configurazione

### `config.php`

Modifica questo file PRIMA di eseguire gli script:

```php
return [
    // ID del business di destinazione (tabella businesses)
    'business_id' => 5,
    
    // ID della location di destinazione (tabella locations)
    'location_id' => 5,
    
    // Nomi file CSV
    'csv_clients' => 'export_customer_list.csv',
    'csv_services' => 'export_service_list.csv',
    'csv_staff' => 'employees_export.csv',
    
    // Se true, salta i clienti bloccati in Fresha
    'skip_blocked_clients' => false,
    
    // Se true, esegue solo una simulazione senza scrivere nel DB
    'dry_run' => false,
];
```

## 📋 Script di Importazione

### 1. `import_services.php`
Importa categorie e servizi da `export_service_list.csv`.
- Crea categorie con colori dalla palette ufficiale
- Crea servizi con durata e prezzo
- Crea service_variants per ogni servizio

### 2. `import_staff.php`
Importa operatori da `employees_export.csv`.
- Assegna colori dalla palette staff ufficiale
- Associa staff alla location configurata
- Gestisce soft-delete per staff con prenotazioni esistenti

### 3. `import_clients.php`
Importa clienti da `export_customer_list.csv`.
- Salta duplicati per email
- Gestisce clienti bloccati (is_archived)
- Normalizza telefoni e date

## 📊 File CSV Richiesti

Esporta i seguenti file da Fresha:

| File | Contenuto |
|------|-----------|
| `export_service_list.csv` | Servizi con categorie, durata, prezzo |
| `employees_export.csv` | Lista operatori |
| `export_customer_list.csv` | Lista clienti |

## ⚠️ Regole Importanti

1. **Ordine di esecuzione**: Servizi → Staff → Clienti
2. **NON creare associazioni staff-servizi**: Le abilitazioni vanno configurate manualmente nel gestionale
3. **Backup prima di importare**: Gli script eliminano dati esistenti per il business

## 🔍 Come Trovare business_id e location_id

```sql
-- Trova il tuo business
SELECT id, name FROM businesses;

-- Trova le location del business
SELECT id, name, business_id FROM locations WHERE business_id = <id_business>;
```

## 📖 Documentazione Dettagliata

- [Migrazione Clienti](migra_clienti.md)
- [Migrazione Servizi](migra_servizi.md)
- [Migrazione Staff](migra_staff.md)
