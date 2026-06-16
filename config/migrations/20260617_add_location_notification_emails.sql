-- Aggiunge colonna notification_emails alla tabella locations
-- Contiene email separate da virgola per notificare il gestionale
-- a ogni operazione su prenotazioni (creazione, modifica, annullamento)

ALTER TABLE `locations`
  ADD COLUMN `notification_emails` text COLLATE utf8mb4_unicode_ci DEFAULT NULL
  COMMENT 'Email notifiche prenotazioni (separate da virgola)'
  AFTER `email`;
