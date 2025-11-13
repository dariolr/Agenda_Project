# Copilot instructions — Agenda Platform (Flutter)

These rules teach AI coding agents how to work productively in this repo. Keep it concise, code-first, and consistent with existing patterns.

## 📌 1. Architettura del Progetto

-   Il progetto utilizza **Flutter/Dart** con focus principale sul
    **deploy Web**.
-   Gestione stato con **Riverpod** (providers, notifiers, family,
    autoDispose).
-   Struttura modulare orientata per feature:

```{=html}
<!-- -->
```
    features/
      agenda/
      services/
      clients/
      staff/
    core/
      widgets/
      utils/
      l10n/
    domain/
      models/
      config/

-   Separazione chiara:
    -   **presentation/** → UI, screen, widget\
    -   **domain/** → modelli, costanti, logiche pure\
    -   **providers/** → Riverpod\
    -   **controllers/** → logiche operative (drag, reorder,
        availability...)\
    -   **utils/** → helper, formatter, validator

------------------------------------------------------------------------

## 📌 2. Invarianti del Progetto (da NON modificare mai)

Copilot deve preservare sempre:

### 🟦 *UI/UX*

-   Nessun ripple, nessuno splash, nessun effetto Material3.
-   Layout responsive desktop-first.
-   Padding, spacing, colori e stile esistenti NON vanno modificati.
-   Hover, selected state e highlight devono rimanere invariati.

### 🟪 *Agenda / Gestione slot*

-   Sincronizzazione scroll verticale/orizzontale.
-   Drag & drop con ghost overlay.
-   Auto-scroll durante il drag.
-   Scroll lock durante resize.
-   Gestione offset e position invariata.
-   Nessun cambiamento alla logica degli slot.

### 🟩 *Servizi / Categorie*

-   Reorder categorie e servizi basato su `sortOrder`.
-   Logiche di editing esistenti devono rimanere le stesse.
-   Formattazione prezzi invariata.
-   Logica di visualizzazione even/odd invariata.

### 🟧 *Form / Dialog / Ricerca*

-   Nessun cambiamento nella UX.
-   Validatori e formatter devono stare in file dedicati.
-   Tipi, nomi e firma dei provider NON vanno modificati.

------------------------------------------------------------------------

## 📌 3. Regole per la Rifattorizzazione

Quando Copilot rifattorizza, deve:

-   Estrarre codice in file più piccoli **senza cambiare behavior**.
-   NON modificare provider, parametri, tipi o logiche.
-   Creare file completi e coerenti, niente snippet isolati.
-   Adeguarsi sempre al pattern e ai nomi già presenti nel progetto.
-   Usare solo librerie già usate nel progetto.

### Esempi di rifattorizzazione accettabile

-   Spostare widget complessi in `widgets/`.
-   Spostare logiche reorder in `controllers/`.
-   Estrarre formatter in `utils/`.
-   Spostare dialog in `dialogs/`.

### Esempi di rifattorizzazione NON accettabile

-   Cambiare comportamento o firme.
-   Rinominare provider.
-   Aggiungere animazioni non richieste.
-   Modificare layout o stile.

------------------------------------------------------------------------

## 📌 4. Linee Guida di Codice

Copilot deve mantenere:

### ✔️ Consistenza

-   Stesse convenzioni di naming.
-   Stesso stile architecturale.
-   Stessi provider e stesso modello mentale.

### ✔️ Pulizia

-   Zero warning inutili.
-   Import puliti.
-   Nessuna dipendenza aggiuntiva senza richiesta.

### ✔️ Completezza

-   Ogni file generato deve includere:
    -   import corretti
    -   classi complete
    -   definizioni dei widget
    -   controller, provider o modelli se necessari

------------------------------------------------------------------------

## 📌 5. Compatibilità con la Baseline Ufficiale del Progetto

La baseline ufficiale del progetto è il repository GitHub:

👉 **https://github.com/dariolr/Agenda_Project**

Copilot deve:

-   Considerare questo repository come **fonte autorevole** della
    struttura del progetto.\
-   Mantenere piena compatibilità con:
    -   **naming** dei file,
    -   **struttura delle cartelle**,
    -   **pattern di organizzazione** (features, providers, domain,
        core).
-   Verificare che ogni modifica, refactor o nuovo file rispetti:
    -   gli stessi pattern usati nel repository,
    -   la stessa struttura logica,
    -   la stessa impostazione dei provider e dei controllers.
-   Non introdurre variazioni che potrebbero rompere la coerenza con il
    codice già presente nel repository.
-   Generare nuovo codice rispettando i modelli, i provider, i config e
    le utilities già definiti nella baseline.

In caso di refactoring, Copilot deve assumere che **tutto ciò presente
nel repository è la fonte di verità**, e ogni intervento deve integrarsi
senza disallineare la struttura generale.

------------------------------------------------------------------------

## 📌 6. Quando Copilot Implementa una Nuova Feature

Deve: - Allinearsi ai pattern esistenti. - Integrare provider nella
forma già utilizzata. - Generare file modulari secondo struttura del
progetto. - Evitare duplicazioni di logiche già presenti.

------------------------------------------------------------------------

## 📌 7. Best Practice Specifiche del Progetto

-   Nessun accesso a DB o API deve essere hardcoded.
-   Tutte le funzioni devono essere testabili.
-   Le feature devono essere facili da estendere.
-   Le feature devono essere coerenti tra loro (Agenda, Servizi,
    Clienti, Staff).

------------------------------------------------------------------------

## 📌 8. Regole Generatrici Universali per Copilot

1.  Non cambiare comportamento esistente.
2.  Non creare regressioni.
3.  Non introdurre nuove dipendenze.
4.  Mantenere tutto responsive.
5.  Evitare ripple e animazioni aggiuntive.
6.  Mantenere compatibilità con provider e logiche attuali.
7.  Mantenere un codice leggibile, modulare e allineato al progetto.

------------------------------------------------------------------------

## 📌 9. Output Richiesto da Copilot

Quando Copilot genera codice: - Deve fornire **file interi**, non
porzioni. - Deve usare import *precisi* già esistenti nel progetto. -
Deve garantire compatibilità con tutto il sistema. - Deve evitare
personalizzazioni arbitrarie. - Può proporre miglioramenti, mai
modificarli senza conferma.

------------------------------------------------------------------------

## 📌 10. Filosofia del Progetto

> "Ogni parte del sistema deve essere modulare, leggibile, stabile e
> prevedibile.\
> Nessuna feature deve mai rompere ciò che già funziona."

