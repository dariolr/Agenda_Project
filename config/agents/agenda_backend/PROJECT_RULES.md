# agenda_backend Agent Rules

Gestionale Flutter per operatori/admin.

Regole:

- Non rompere agenda day view.
- Non modificare drag, resize, ghost overlay, auto-scroll, scroll lock se non richiesto.
- Usare provider e repository esistenti.
- Usare `context.l10n` per nuovi testi.
- Nessun ripple/splash.
- Non introdurre mock nei provider di produzione.
- Per date/orari usare timezone tenant/location, non timezone browser.
- Dopo modifiche Riverpod eseguire build_runner se necessario.