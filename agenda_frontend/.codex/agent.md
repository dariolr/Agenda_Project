# AGENT.md -- Gestione Risorse per Location (Versione Completa)

## Contesto Generale del Progetto

L'applicazione è una web app Flutter complessa, web-first, basata su
Riverpod. Supporta: - multi-location\
- multi-staff\
- services + variants per location\
- agenda giornaliera\
- UI interattiva con drag, hover, ghost overlay\
- gestione appuntamenti e disponibilità staff

Questo file definisce tutte le istruzioni necessarie per implementare la
**gestione risorse per location**.

------------------------------------------------------------------------

## 1. Modelli da Implementare

### 1.1 `Resource`

File: `lib/core/models/resource.dart`

Campi: - id\
- locationId\
- name\
- quantity\
- type (optional)\
- note (optional)

Include: fromJson, toJson, copyWith.

------------------------------------------------------------------------

### 1.2 `ServiceVariantResourceRequirement`

File: `lib/core/models/service_variant_resource_requirement.dart`

Campi: - id\
- serviceVariantId\
- resourceId\
- unitsRequired

Relazione 1:N con ServiceVariant.

------------------------------------------------------------------------

### 1.3 Aggiornare `ServiceVariant`

Aggiungere lista: -
`List<ServiceVariantResourceRequirement> resourceRequirements`

Nessuna altra modifica.

------------------------------------------------------------------------

## 2. Provider da Introdurre

### 2.1 `resourcesProvider`

Carica tutte le risorse del sistema.

### 2.2 `locationResourcesProvider(locationId)`

Restituisce solo le risorse della location.

### 2.3 `serviceVariantResourcesProvider(serviceVariantId)`

Restituisce tutte le risorse dal servizio variant.

### 2.4 `resourceBookingsProvider(resourceId, date)`

Restituisce gli appuntamenti che occupano quella risorsa.

### 2.5 `resourceAvailabilityProvider(serviceVariantId, staffId, start, end)`

Determina se le risorse sono disponibili.

------------------------------------------------------------------------

## 3. Logica di Disponibilità Risorse

Per ogni appuntamento: 
1. Determinare la location\
2. Determinare il `serviceVariantId`\
3. Caricare risorse\
4. Per ogni risorsa: - caricare booking resource - verificare conflitti
orari - verificare quantity

Se una risorsa non è disponibile → bloccare il booking.

------------------------------------------------------------------------

## 4. Integrazione nel Dialog di Creazione Appuntamento

Aggiungere: - sezione "risorse"\
- badge disponibile / non disponibile\
- blocco pulsante conferma se conflitto\
- aggiornamento in tempo reale cambiando orario/servizio

------------------------------------------------------------------------

## 5. Integrazione nell'Agenda

Aggiungere: - overlay conflitto risorse\
- highlight in hover\
- icona risorse dentro gli appuntamenti\
- nessuna nuova animazione

------------------------------------------------------------------------

## 6. UI Gestione Risorse per Location

Creare nuova sezione: - lista risorse\
- aggiungi/modifica/elimina\
- gestione quantity\
- tutto filtrato per location\
- nessun ripple

------------------------------------------------------------------------

## 7. UI Associazione Risorse ai Service Variant

Nella schermata ServicesScreen: - mostra risorse della location\
- checkbox + unitsRequired\
- salvataggio tramite provider\
- aggiornamento real-time

------------------------------------------------------------------------

## 8. Backend (Linee Guida API)

Endpoints previsti:

    GET /resources?locationId
    GET /service-variant/{id}/resources
    POST /resource
    PUT /resource/{id}
    DELETE /resource/{id}
    POST /service-variant-resource
    DELETE /service-variant-resource/{id}
    GET /resource-bookings?resourceId&date

------------------------------------------------------------------------

## 9. Regole Obbligatorie per Codex

Codex deve: - mantenere tutte le logiche esistenti\
- non rompere: drag, hover, ghost overlay, scroll-sync, resize lock\
- usare Riverpod\
- mantenere file modulari\
- evitare ripple\
- garantire piena responsività web\
- generare file completi, mai snippet

------------------------------------------------------------------------

## 10. Checklist Interna per Codex

### Modelli

-   [ ] resource.dart\
-   [ ] service_variant_resource_requirement.dart\
-   [ ] aggiornamento ServiceVariant

### Provider

-   [ ] resourcesProvider\
-   [ ] locationResourcesProvider\
-   [ ] serviceVariantResourcesProvider\
-   [ ] resourceBookingsProvider\
-   [ ] resourceAvailabilityProvider\
-   [ ] CRUD risorse

### UI

-   [ ] gestione risorse\
-   [ ] associazione risorse\
-   [ ] controllo risorse nel booking dialog\
-   [ ] overlay conflitti in agenda\
-   [ ] icone risorse\
-   [ ] hover risorse

### Logica

-   [ ] controllo unità disponibili\
-   [ ] supporto qty \> 1\
-   [ ] supporto risorse multiple\
-   [ ] compatibilità multi-location

------------------------------------------------------------------------

## 11. Esempi di Prompt per Codex

### Esempio 1

"Genera il modello `resource.dart` secondo agent.md"

### Esempio 2

"Aggiungi in ServicesScreen la sezione risorse per serviceVariant"

### Esempio 3

"Implementa resourceAvailabilityProvider seguendo agent.md"

### Esempio 4

"Aggiorna il dialog di creazione appuntamento per includere il controllo
risorse"

------------------------------------------------------------------------

# 📘 Come Usarlo con Codex in 5 Step

### **1. Copia `agent.md` nella root del workspace**

Consigliato:

    .vscode/agent.md

### **2. Ricarica la finestra VS Code**

Codex leggerà automaticamente il file come contesto permanente.

### **3. Inizia dalla parte MODEL**

Chiedi:

    Genera resource.dart seguendo agent.md

### **4. Procedi con i provider nell'ordine indicato**

Chiedi:

    Genera resources_provider.dart seguendo agent.md

### **5. Integra la UI (ultima fase)**

Chiedi:

    Aggiungi la UI per la gestione risorse per location seguendo agent.md

Questo ordine evita errori e permette a Codex di lavorare con dipendenze
già pronte.

------------------------------------------------------------------------

# Fine del documento
