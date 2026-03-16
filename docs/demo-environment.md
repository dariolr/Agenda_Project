# Agenda Platform Demo Environment

La demo è un ambiente ufficiale dello stesso monorepo, non un fork.

## Checklist operativa

1. Configurare variabili `APP_ENV=demo` nei 3 progetti.
2. Verificare flag demo:
   - `agenda_backend/scripts/demo/verify_demo_env.sh`
   - `agenda_frontend/scripts/demo/verify_demo_env.sh`
   - `agenda_core/scripts/demo/verify_demo_env.sh`
3. Build frontend/backend con `--dart-define` demo.
4. Deploy su host demo separati.
5. Seed/reset DB demo in `agenda_core`.
6. Verificare risposta `demo_blocked` su endpoint sensibili API.
