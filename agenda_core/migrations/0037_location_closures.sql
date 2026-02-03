-- Migration: 0037_location_closures.sql
-- Description: Create location closures with multi-location support
-- Date: 2026-02-03

-- 1. Create closures table (without location_id - uses pivot table)
CREATE TABLE IF NOT EXISTS closures (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id INT UNSIGNED NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    
    -- Index for efficient date range queries
    INDEX idx_business_dates (business_id, start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE closures COMMENT = 'Closure periods (holidays, vacations). Can apply to one or more locations.';

-- 2. Create pivot table for closure-location relationship (N:M)
CREATE TABLE IF NOT EXISTS closure_locations (
    closure_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL,
    
    PRIMARY KEY (closure_id, location_id),
    FOREIGN KEY (closure_id) REFERENCES closures(id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
    
    INDEX idx_location_closure (location_id, closure_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE closure_locations COMMENT = 'Pivot table linking closures to locations (many-to-many).';

-- 3. Drop location_closures if it was created in a previous migration attempt
DROP TABLE IF EXISTS location_closures;
