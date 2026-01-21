# instructions.md

## STATO
Implementato in agenda_core, agenda_backend, agenda_frontend (18/01/2026).

## OBIETTIVO
Implementare la funzionalità **Pacchetti di Servizi** come composizione di servizi esistenti, senza introdurre nuove entità nel motore di prenotazione e senza modificare il payload di booking esistente.
Il pacchetto è esclusivamente un alias di selezione che viene sempre risolto in una lista ordinata di servizi.

---

## PRINCIPI VINCOLANTI (NON VIOLABILI)

1. Nel booking engine esistono SOLO servizi
2. I pacchetti NON vengono mai salvati nelle prenotazioni
3. Il payload booking REST NON cambia
4. Le prenotazioni sono snapshot immutabili
5. I pacchetti dipendono dai servizi, mai il contrario
6. Selezionare un pacchetto produce lo stesso identico risultato della selezione maleggi enuale dei servizi nello stesso ordine
7. Nessuna logica di availability, staff, pricing viene duplicata
8. Nessun effetto retroattivo su prenotazioni già create
9. Nessuna rinomina di campi, endpoint o modelli esistenti

---

## TERMINOLOGIA OBBLIGATORIA

- core / API → progetto `agenda_core`
- backend → progetto Flutter `agenda_backend`
- frontend → progetto Flutter `agenda_frontend`

---

## DATABASE (agenda_core)

### service_packages
CREATE TABLE service_packages (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL,
  location_id INT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  override_price DECIMAL(10,2) NULL,
  override_duration_minutes INT UNSIGNED NULL,
  is_active TINYINT(1) DEFAULT 1,
  is_broken TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (business_id, location_id),
  INDEX (category_id)
);

### service_package_items
CREATE TABLE service_package_items (
  package_id INT UNSIGNED NOT NULL,
  service_id INT UNSIGNED NOT NULL,
  sort_order INT UNSIGNED NOT NULL,
  PRIMARY KEY (package_id, service_id),
  INDEX (package_id),
  INDEX (service_id),
  FOREIGN KEY (package_id) REFERENCES service_packages(id) ON DELETE CASCADE
);

---

## REGOLE DI DOMINIO

- Ogni pacchetto deve essere risolto in una lista ordinata di service_id
- L’ordine è determinato da sort_order
- Il booking engine non deve mai ricevere package_id
- Prezzo e durata default = somma dei servizi
- Override sostituisce il totale ma non modifica i servizi
- Override non viene salvato nelle prenotazioni
- Servizio disattivato/eliminato → pacchetto is_broken = 1
- Il pacchetto ha una categoria per raggruppamento, ma può includere servizi di categorie diverse
- Prenotazioni salvano solo booking_items

---

## API (agenda_core)

GET /v1/locations/{location_id}/service-packages
POST /v1/locations/{location_id}/service-packages
PUT /v1/locations/{location_id}/service-packages/{id}
DELETE /v1/locations/{location_id}/service-packages/{id}
GET /v1/locations/{location_id}/service-packages/{id}/expand

Expand ritorna service_ids ordinati, effective_price, effective_duration_minutes.

---

## BOOKING ENGINE

- Nessuna modifica a POST /bookings o availability
- Booking riceve solo service_ids
- Pacchetti espansi prima della prenotazione

---

## FRONTEND CLIENTI

- Mostrare pacchetti insieme ai servizi nella stessa categoria
- Selezione pacchetto → inserire servizi (senza logica aggiuntiva)
- Conferma invia solo service_ids

---

## BACKEND GESTIONALE

- CRUD pacchetti con categoria obbligatoria
- Ordinamento drag & drop
- Selezione pacchetto in agenda = selezione servizi

---

## TEST FINALI

- Nessuna regressione ammessa
- Availability e staff invariati
- Ordine servizi sempre rispettato

FINE FILE
