# Agenda Platform Demo Environment

La demo è un ambiente ufficiale dello stesso monorepo, non un fork.

## Checklist operativa

1. Configurare variabili `APP_ENV=demo` nei 3 progetti.
   Source of truth monorepo: `config/environments/demo/`.
2. Verificare flag demo:
   - `config/scripts/demo/verify_demo_env_backend.sh`
   - `config/scripts/demo/verify_demo_env_frontend.sh`
   - `config/scripts/demo/verify_demo_env_core.sh`
3. Build frontend/backend con `--dart-define` demo.
4. Deploy su host demo separati.
5. Seed/reset DB demo in `agenda_core`.
6. Verificare risposta `demo_blocked` su endpoint sensibili API.

Wrapper monorepo utili:

- `config/scripts/db/core_prepare_demo.sh`
- `config/scripts/db/core_seed_demo.sh`
- `config/scripts/db/core_reset_demo.sh`
