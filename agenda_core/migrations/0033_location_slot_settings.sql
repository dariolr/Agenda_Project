-- ============================================================================
-- 0033_location_slot_settings.sql
-- Configurazione visualizzazione slot per prenotazioni online
-- ============================================================================

-- Intervallo tra slot mostrati ai clienti (es. 15, 30, 60 minuti)
ALTER TABLE locations 
  ADD COLUMN slot_interval_minutes INT UNSIGNED NOT NULL DEFAULT 15
    COMMENT 'Intervallo tra slot mostrati ai clienti online (minuti)';

-- Modalità di visualizzazione slot
-- 'all' = Mostra tutti gli slot disponibili (massima disponibilità)
-- 'min_gap' = Filtra slot che creerebbero gap troppo piccoli
ALTER TABLE locations 
  ADD COLUMN slot_display_mode ENUM('all', 'min_gap') NOT NULL DEFAULT 'all'
    COMMENT 'Modalità visualizzazione: all=tutti, min_gap=filtra gap piccoli';

-- Gap minimo consentito tra appuntamenti (usato solo se mode='min_gap')
ALTER TABLE locations 
  ADD COLUMN min_gap_minutes INT UNSIGNED NOT NULL DEFAULT 30
    COMMENT 'Gap minimo accettabile in minuti (usato solo se mode=min_gap)';
