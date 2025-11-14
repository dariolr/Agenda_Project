Ho letto le istruzioni in agent.md e propongo un piano di rifattorizzazione fedele 1:1 alla UI/UX e alla logica esistente, senza cambiare provider, firme o comportamento.

## Plan: Refactor “Services” 1:1

Obiettivo: scomporre `services_screen.dart` in moduli chiari senza alterare nulla a livello visivo o funzionale. Manteniamo Riverpod, ValueNotifier, drag/reorder, ghost overlay, auto‑scroll, even/odd, formattazione prezzi e provider esistenti. `services_screen.dart` rimane l’entry pubblico e diventa un orchestratore che importa i nuovi componenti.

### Sintesi vincoli e obiettivi
- Nessun cambiamento funzionale, di UI/UX o stile; niente ripple/Material3.
- Architettura e convenzioni: Flutter Web, Riverpod 3, struttura modulare per feature.
- Invarianti: hover/selected state, drag & drop (categorie/servizi), ghost overlay, auto‑scroll durante drag, scroll lock (se pertinente), even/odd, formattazione prezzi, ricerca/sorting.
- Baseline e provider: compatibilità con repo ufficiale, nessun rename o cambio firma di provider/classi/simboli.
- `services_screen.dart` resta la route pubblica; solo alleggerito a orchestratore.

### Struttura target proposta
- `features/services/presentation/screens/services_screen.dart`: orchestratore pubblico della schermata (route/export invariati).
- `features/services/presentation/widgets/categories_list.dart`: lista categorie con drag/reorder e selezione/hover.
- `features/services/presentation/widgets/category_item.dart`: render di una singola categoria (hover/selected, handle drag).
- `features/services/presentation/widgets/services_list.dart`: lista servizi per categoria, con drag/reorder e filtri/ricerca applicati.
- `features/services/presentation/widgets/service_item.dart`: render di un singolo servizio (hover/selected, prezzo formattato).
- `features/services/presentation/widgets/empty_state.dart`: stato vuoto coerente con l’attuale UI.
- `features/services/presentation/dialogs/category_dialog.dart`: dialog creazione/modifica categoria (stesse validazioni).
- `features/services/presentation/dialogs/service_dialog.dart`: dialog creazione/modifica servizio (stessi formatter/validator).
- `features/services/controllers/services_reorder_controller.dart`: logiche di reorder dei servizi (drag, ghost, autoscroll).
- `features/services/controllers/categories_reorder_controller.dart`: logiche di reorder delle categorie (drag, ghost, autoscroll).
- `features/services/utils/service_validators.dart`: validatori estratti e riusati da dialog/form (nessun cambiamento di logica).
- `features/services/utils/service_formatters.dart`: formatter (incluso prezzo) estratti e riusati (nessuna modifica).

### Piano di rifattorizzazione (passi)
1. Creazione cartelle e file vuoti: `presentation/widgets`, `presentation/dialogs`, `controllers`, `utils` con stubs e import minimi; nessuna logica cambiata.
2. Estrarre util: spostare funzioni pure correnti in `service_formatters.dart` e `service_validators.dart`, poi re‑importarle da `services_screen.dart` per verificare parità.
3. Estrarre `category_item.dart`: isolare il widget di una singola categoria mantenendo identici i GestureDetector/MouseRegion/Keys e le dipendenze (hover/selected, callback drag).
4. Estrarre `categories_list.dart`: spostare il ListView/CustomScroll o l’equivalente della lista categorie; iniettare i provider tramite `WidgetRef` o callback, non cambiare la logica di selezione/sort/hover.
5. Estrarre `service_item.dart`: isolare il widget di un singolo servizio con formatter prezzo esistente e gli stessi gesti/keys/hover/selected.
6. Estrarre `services_list.dart`: spostare la lista servizi con gli stessi filtri/ricerca/sorting e wiring drag&drop; passare gli stessi controller/scrollController/keys.
7. Estrarre `category_dialog.dart`: spostare dialog creando/aggiornando categorie; mantenere stessi provider/validator e return types; non cambiare la firma degli entrypoint.
8. Estrarre `service_dialog.dart`: spostare dialog servizi; riusare formatter/validator estratti; garantire stesso comportamento su conferma/annulla/validazioni.
9. Estrarre `categories_reorder_controller.dart`: isolare la logica di reorder categorie (ghost overlay, autoscroll, update `sortOrder`); esporre le stesse API usate dalla lista.
10. Estrarre `services_reorder_controller.dart`: isolare la logica di reorder servizi con le stesse API e side‑effects (aggiornamento provider/sortOrder).
11. Sfoltire `services_screen.dart`: sostituire blocchi UI con import dei nuovi widget/dialog/controller; conservare route, firma pubblica, e provider wiring globale.
12. Ripulire import ridondanti: mantenere import minimi, senza rimuovere nulla di necessario ai side‑effects; verificare analyzer.
13. Pass consistency: controllare che ogni `ValueNotifier`/`ScrollController`/`FocusNode` creato a livello di screen continui a essere passato (no duplicati) ai widget estratti.
14. Verifica manuale in app: confronto visivo e comportamentale per ogni punto in “Validation plan”.

### Mappa dipendenze (alto livello)
- `presentation/screens/services_screen.dart`
  - Importa: `categories_list.dart`, `services_list.dart`, `category_dialog.dart`, `service_dialog.dart`, controller di reorder, utils formatter/validator.
  - Dipende da: provider esistenti per categorie/servizi/ricerche/filtri/stato selezioni; eventuali `ValueNotifier` e `ScrollController` condivisi.
- `presentation/widgets/categories_list.dart`
  - Dipende da: provider categorie (lista + sortOrder), eventuale provider di selezione categoria, `categories_reorder_controller.dart`, `category_item.dart`.
- `presentation/widgets/category_item.dart`
  - Dipende da: modello Categoria, notifiers hover/selected passati dal parent, callback drag/start/end, eventuale `ValueKey` dal modello per stabilità.
- `presentation/widgets/services_list.dart`
  - Dipende da: provider servizi filtrati per categoria e ricerca, provider di ordinamento, `services_reorder_controller.dart`, `service_item.dart`, stessi `ScrollController` e autoscroll hooks.
- `presentation/widgets/service_item.dart`
  - Dipende da: modello Servizio, notifiers hover/selected, formatter prezzo da `service_formatters.dart`.
- `presentation/widgets/empty_state.dart`
  - Dipende da: nulla o da input booleani; UI statica coerente.
- `presentation/dialogs/category_dialog.dart`
  - Dipende da: provider per create/update categoria, validator da `service_validators.dart`, modelli Categoria.
- `presentation/dialogs/service_dialog.dart`
  - Dipende da: provider per create/update servizio, formatter e validator, modelli Servizio.
- `controllers/categories_reorder_controller.dart`
  - Dipende da: provider categorie (read/write), modelli Categoria; esporta funzioni/metodi invocati dalla lista.
- `controllers/services_reorder_controller.dart`
  - Dipende da: provider servizi (read/write), modelli Servizio, logica ghost/auto‑scroll.
- `utils/service_formatters.dart` / `utils/service_validators.dart`
  - Dipendono da: eventuali util/Intl già in `core/utils` o `core/l10n`; nessun provider.

### Rischi e salvaguardie
- Gesti drag/handle persi: preservare gli stessi `GestureDetector`/`LongPressDraggable` e le stesse `keys`; copiare pari‑pari i builder di feedback (ghost overlay).
- Ghost overlay inconsistente: riusare gli stessi widget di feedback/childWhenDragging, stessi size/constraints e layer.
- Auto‑scroll non attivo: mantenere e iniettare gli stessi `ScrollController`/listener; non crearne di nuovi nei figli.
- Scroll lock durante resize: preservare flag/stato e identico ciclo start/end.
- Hover/selected persi: non spostare la creazione dei notifiers; passarli ai figli; mantenere `MouseRegion`/`InkWell` identici.
- Alternanza even/odd errata: calcolare su stessi indici/origine; evitare indici locali incoerenti dopo filtri.
- Formattazione prezzi cambiata: riusare funzioni/Intl esistenti; nessuna nuova dipendenza.
- Ricerca/sorting alterati: spostare funzioni pure senza modificarle; ordine per `sortOrder` + categoria invariato.
- Provider scope/regressioni: non spostare `ProviderScope`; usare `ConsumerWidget`/`ref` come prima; evitare doppie inizializzazioni.
- Duplicazione state locali: mantenere `ValueNotifier`/state al livello screen; passarli ai figli come riferimenti.

### Validation plan (parità funzionale)
- Visual: layout, padding, colori, hover, selected, even/odd identici.
- Reorder categorie: drag + ghost + autoscroll; `sortOrder` invariato; selezione coerente dopo reorder.
- Reorder servizi: drag intra/inter categoria, ghost, autoscroll, lock corretto.
- Dialog categoria: apertura dai punti previsti, validazioni, salvataggio/update, chiusura/annulla identici.
- Dialog servizio: apertura, validazioni, prezzo, salvataggio/update identici.
- Ricerca/filtri: risultati e ordinamenti identici digitando/filtrando.
- Interazioni micro: hover, click selezione, focus/tastiera, nessun ripple.
- Performance: nessun jank aggiuntivo; rebuild invariati.
- Analyzer/log: nessun nuovo warning o errore; import/nullability invariati.
