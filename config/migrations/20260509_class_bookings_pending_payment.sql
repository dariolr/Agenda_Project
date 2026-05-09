-- Aggiunge lo stato PENDING_PAYMENT alla colonna status di class_bookings.
-- Viene usato quando un class event richiede pagamento online: il posto viene
-- riservato (confirmed_count incrementato) ma la prenotazione rimane sospesa
-- finché il pagamento non è confermato via webhook o polling status.
-- Backward-compatible: nessuna colonna rimossa, nessun valore esistente alterato.

ALTER TABLE `class_bookings`
  MODIFY `status` ENUM(
    'CONFIRMED',
    'WAITLISTED',
    'CANCELLED_BY_CUSTOMER',
    'CANCELLED_BY_STAFF',
    'NO_SHOW',
    'ATTENDED',
    'PENDING_PAYMENT'
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
