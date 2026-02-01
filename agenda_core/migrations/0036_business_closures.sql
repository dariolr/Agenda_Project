-- Migration: 0036_business_closures.sql
-- Description: Add business_closures table for business-wide closure periods (holidays, vacations, etc.)
-- Date: 2026-02-01

CREATE TABLE IF NOT EXISTS business_closures (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id INT UNSIGNED NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    
    -- Index for efficient date range queries
    INDEX idx_business_dates (business_id, start_date, end_date),
    
    -- Prevent overlapping closures for same business
    -- Note: MySQL doesn't support exclusion constraints, so we'll handle this in application logic
    INDEX idx_business_closure_lookup (business_id, start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add comment
ALTER TABLE business_closures COMMENT = 'Business-wide closure periods (holidays, vacations). Affects all staff availability.';
