# Agenda Backend (Gestionale) — Copilot Instructions

> ⚠️ **Tutte le istruzioni dettagliate per questo progetto sono nel file `AGENTS.md` nella root del progetto.**
> 
> Questo file è mantenuto per compatibilità con GitHub Copilot. Per le istruzioni complete, fare riferimento a:
> 
> **📄 [AGENTS.md](../AGENTS.md)**

---

## Riferimento rapido

### Comandi essenziali
```bash
dart run intl_utils:generate                    # Localizzazione
dart run build_runner build --delete-conflicting-outputs  # Code generation
flutter analyze                                 # Segnala problemi
flutter build web --release --no-tree-shake-icons  # Build web
flutter test                                    # Test
```

### L'agente DEVE
- Leggere `AGENTS.md` per istruzioni complete
- Produrre file completi, non snippet parziali
- Usare `Notifier` + `NotifierProvider` (MAI `StateProvider`)
- Usare `context.l10n` per tutti i testi
- Controllare `id <= 0` prima di chiamate API

### L'agente NON deve
- Aggiungere dipendenze non richieste
- Modificare route o indici senza richiesta
- Inserire/modificare/eliminare dati nel database senza richiesta esplicita