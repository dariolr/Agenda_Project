ALTER TABLE locations
    ADD COLUMN allow_multi_service_booking tinyint(1) NOT NULL DEFAULT 1
        COMMENT 'Se 1, il cliente può selezionare più servizi/pacchetti/eventi per prenotazione online; se 0, solo uno alla volta';
