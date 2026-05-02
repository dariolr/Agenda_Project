# Deploy agenda_core

## Script ufficiali

```bash
# Sync public/ → public_html/
rsync -avz public/ siteground:www/api.romeolab.it/public_html/

# Sync src/
rsync -avz --delete src/ siteground:www/api.romeolab.it/src/

# Sync vendor/
rsync -avz --delete vendor/ siteground:www/api.romeolab.it/vendor/

# (Opzionale) Sync bin/ per worker notifiche
rsync -avz --delete bin/ siteground:www/api.romeolab.it/bin/
```

## Verifiche pre deploy

- `.env` corretto sull'ambiente target
- DB target corretto
- `APP_ENV` coerente
- nessun segreto committato

## Verifiche post deploy

- health check API: `curl https://api.romeolab.it/health`
- login test
- endpoint pubblico servizi: `curl https://api.romeolab.it/v1/services?location_id=1`
- log errori

## Non deployare

- docs
- tests
- file `.md`
- `.env.example`
- `.git`
- bundle locali
- `lib/` (cartella vuota legacy)
- `phpunit.xml`

