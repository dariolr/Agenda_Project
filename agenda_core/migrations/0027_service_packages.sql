-- ============================================================================
-- Migration 0027: Service Packages (composed services)
-- ============================================================================
-- Adds service_packages and service_package_items tables.
-- Packages are aliases of ordered services (no booking payload changes).
-- ============================================================================

CREATE TABLE service_packages (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  business_id INT UNSIGNED NOT NULL,
  location_id INT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  override_price DECIMAL(10,2) NULL,
  override_duration_minutes INT UNSIGNED NULL,
  is_active TINYINT(1) DEFAULT 1,
  is_broken TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_service_packages_business_location (business_id, location_id),
  INDEX idx_service_packages_location (location_id),
  CONSTRAINT fk_service_packages_business FOREIGN KEY (business_id)
    REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_service_packages_location FOREIGN KEY (location_id)
    REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE service_package_items (
  package_id INT UNSIGNED NOT NULL,
  service_id INT UNSIGNED NOT NULL,
  sort_order INT UNSIGNED NOT NULL,
  PRIMARY KEY (package_id, service_id),
  INDEX idx_service_package_items_package (package_id),
  INDEX idx_service_package_items_service (service_id),
  CONSTRAINT fk_service_package_items_package FOREIGN KEY (package_id)
    REFERENCES service_packages(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_service_package_items_service FOREIGN KEY (service_id)
    REFERENCES services(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
