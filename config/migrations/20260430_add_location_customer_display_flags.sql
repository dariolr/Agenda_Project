ALTER TABLE locations
  ADD COLUMN show_price_to_customer TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Se 1, mostra il prezzo al cliente durante la prenotazione online',
  ADD COLUMN show_duration_to_customer TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Se 1, mostra la durata al cliente durante la prenotazione online';
