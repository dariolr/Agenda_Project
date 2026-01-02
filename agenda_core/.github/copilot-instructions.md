# Agenda Core (Backend PHP) — Copilot Instructions

> ⚠️ **Tutte le istruzioni dettagliate per questo progetto sono nel file `AGENTS.md` nella root del progetto.**
> 
> Questo file è mantenuto per compatibilità con GitHub Copilot. Per le istruzioni complete, fare riferimento a:
> 
> **📄 [AGENTS.md](../AGENTS.md)**

---

## Riferimento rapido

### Comandi essenziali
```bash
./vendor/bin/phpunit --testdox    # Test (98 test, 195 asserzioni)
composer install                   # Installa dipendenze
php -S localhost:8000 -t public   # Server locale
```

### Deploy (SOLO queste cartelle)
```bash
rsync -avz public/ siteground:www/api.romeolab.it/public_html/
rsync -avz --delete src/ siteground:www/api.romeolab.it/src/
rsync -avz --delete vendor/ siteground:www/api.romeolab.it/vendor/
```

### L'agente DEVE
- Leggere `AGENTS.md` per istruzioni complete
- Usare `$this->db->getPdo()` (NON `pdo()`)
- Mantenere compatibilità con frontend Flutter e gestionale Flutter
- Usare JSON snake_case per API responses

### L'agente NON deve
- Deployare `docs/`, `tests/`, `migrations/`, `.git/`, `*.md`
- Rinominare modelli/campi già usati dai client Flutter
- Inserire/modificare/eliminare dati nel database senza richiesta esplicita
