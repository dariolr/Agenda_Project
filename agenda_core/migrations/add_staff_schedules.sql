-- ============================================================================
-- MIGRATION: Add staff_schedules table
-- Date: 2026-01-01
-- Description: Tabella per la disponibilità settimanale dello staff
-- ============================================================================

-- ----------------------------------------------------------------------------
-- staff_schedules: Define working hours for each staff member by day of week
-- Supports multiple time ranges per day (e.g., morning + afternoon shift)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS staff_schedules (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_id INT UNSIGNED NOT NULL,
    day_of_week TINYINT UNSIGNED NOT NULL COMMENT '1=Monday, 2=Tuesday, ..., 7=Sunday (ISO 8601)',
    start_time TIME NOT NULL COMMENT 'Shift start time (e.g., 09:00:00)',
    end_time TIME NOT NULL COMMENT 'Shift end time (e.g., 13:00:00)',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_staff_schedules_staff (staff_id),
    KEY idx_staff_schedules_day (staff_id, day_of_week),
    CONSTRAINT fk_staff_schedules_staff FOREIGN KEY (staff_id) 
        REFERENCES staff(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_staff_day_of_week CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_staff_times CHECK (start_time < end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Working hours schedule for each staff member. Multiple rows per day allowed for split shifts.';

-- Example: Staff 1 works Mon-Fri 09:00-13:00 and 14:00-19:00
-- INSERT INTO staff_schedules (staff_id, day_of_week, start_time, end_time) VALUES
-- (1, 1, '09:00:00', '13:00:00'),  -- Monday morning
-- (1, 1, '14:00:00', '19:00:00'),  -- Monday afternoon
-- (1, 2, '09:00:00', '13:00:00'),  -- Tuesday morning
-- (1, 2, '14:00:00', '19:00:00');  -- Tuesday afternoon
