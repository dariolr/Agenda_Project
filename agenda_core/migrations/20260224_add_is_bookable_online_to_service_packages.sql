-- Aggiunge il campo is_bookable_online alla tabella service_packages.
-- Permette di rendere un pacchetto non prenotabile online mantenendolo
-- visibile internamente, in analogia con il campo omonimo su service_variants.
ALTER TABLE `service_packages`
  ADD COLUMN `is_bookable_online` tinyint(1) NOT NULL DEFAULT '1'
    AFTER `is_active`;
