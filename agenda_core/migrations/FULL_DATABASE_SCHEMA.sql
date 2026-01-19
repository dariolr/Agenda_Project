-- ============================================================================
-- FULL DATABASE SCHEMA - Agenda Platform
-- Generated: 2025-12-28
-- Description: Schema completo per deploy produzione (unico file)
-- Database: MySQL 8.0+ / MariaDB 10.5+
-- 
-- USAGE:
-- 1. Create empty database in phpMyAdmin
-- 2. Import this file
-- 3. (Optional) Run seed_data.sql for demo data
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- SECTION 1: CORE TABLES (from 0001_init.sql)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- businesses: Tenant principale
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS businesses (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    email VARCHAR(255) DEFAULT NULL,
    phone VARCHAR(50) DEFAULT NULL,
    timezone VARCHAR(50) NOT NULL DEFAULT 'Europe/Rome',
    currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
    cancellation_hours INT UNSIGNED NOT NULL DEFAULT 24 
        COMMENT 'Default hours before appointment when cancellation/modification is allowed',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_businesses_slug (slug),
    KEY idx_businesses_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- locations: Sedi fisiche di un business
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS locations (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(500) DEFAULT NULL,
    city VARCHAR(100) DEFAULT NULL,
    postal_code VARCHAR(20) DEFAULT NULL COMMENT 'Postal/ZIP code',
    region VARCHAR(100) DEFAULT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'IT',
    phone VARCHAR(50) DEFAULT NULL,
    email VARCHAR(255) DEFAULT NULL,
    latitude DECIMAL(10,8) DEFAULT NULL,
    longitude DECIMAL(11,8) DEFAULT NULL,
    timezone VARCHAR(50) DEFAULT 'Europe/Rome' COMMENT 'Location timezone',
    currency VARCHAR(3) DEFAULT NULL COMMENT 'Override business currency',
    cancellation_hours INT UNSIGNED DEFAULT NULL 
        COMMENT 'Override business cancellation policy. NULL = use business default',
    allow_customer_choose_staff TINYINT(1) NOT NULL DEFAULT 0
        COMMENT 'Allow customers to choose staff for online booking',
    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_locations_business (business_id),
    KEY idx_locations_business_default (business_id, is_default),
    KEY idx_locations_postal_code (postal_code),
    KEY idx_locations_cancellation (business_id, cancellation_hours),
    CONSTRAINT fk_locations_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- location_schedules: Define working hours for each location by day of week
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS location_schedules (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    location_id INT UNSIGNED NOT NULL,
    day_of_week TINYINT UNSIGNED NOT NULL COMMENT '0=Sunday, 1=Monday, ..., 6=Saturday',
    open_time TIME NOT NULL COMMENT 'Opening time (e.g., 09:00:00)',
    close_time TIME NOT NULL COMMENT 'Closing time (e.g., 18:00:00)',
    is_closed TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Day is closed for business',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_location_schedules (location_id, day_of_week),
    CONSTRAINT fk_location_schedules_location FOREIGN KEY (location_id) 
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_day_of_week CHECK (day_of_week BETWEEN 0 AND 6),
    CONSTRAINT chk_times CHECK (open_time < close_time OR is_closed = 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Working hours schedule for each location';

-- ----------------------------------------------------------------------------
-- service_categories: Categorie di servizi
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS service_categories (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT DEFAULT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_service_categories_business (business_id),
    KEY idx_service_categories_sort (business_id, sort_order),
    CONSTRAINT fk_service_categories_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- services: Servizi offerti
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS services (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT DEFAULT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_services_business (business_id),
    KEY idx_services_category (category_id),
    KEY idx_services_sort (business_id, category_id, sort_order),
    CONSTRAINT fk_services_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_services_category FOREIGN KEY (category_id) 
        REFERENCES service_categories(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- service_variants: Varianti per location (durata, prezzo, disponibilità)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS service_variants (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    service_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL,
    duration_minutes INT UNSIGNED NOT NULL,
    processing_time INT UNSIGNED DEFAULT NULL COMMENT 'Minuti post-lavorazione',
    blocked_time INT UNSIGNED DEFAULT NULL COMMENT 'Minuti bloccati',
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT NULL COMMENT 'Override location currency',
    color_hex VARCHAR(7) DEFAULT NULL COMMENT 'Es. #FF5733',
    is_bookable_online TINYINT(1) NOT NULL DEFAULT 1,
    is_free TINYINT(1) NOT NULL DEFAULT 0,
    is_price_starting_from TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Mostra "da €X"',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_service_variants_service_location (service_id, location_id),
    KEY idx_service_variants_location (location_id),
    KEY idx_service_variants_bookable (location_id, is_bookable_online, is_active),
    CONSTRAINT fk_service_variants_service FOREIGN KEY (service_id) 
        REFERENCES services(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_service_variants_location FOREIGN KEY (location_id) 
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- service_packages: Packages composed of ordered services
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS service_packages (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT DEFAULT NULL,
    override_price DECIMAL(10,2) DEFAULT NULL,
    override_duration_minutes INT UNSIGNED DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    is_broken TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_service_packages_business_location (business_id, location_id),
    KEY idx_service_packages_location (location_id),
    KEY idx_service_packages_category (category_id),
    CONSTRAINT fk_service_packages_business FOREIGN KEY (business_id)
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_service_packages_location FOREIGN KEY (location_id)
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_service_packages_category FOREIGN KEY (category_id)
        REFERENCES service_categories(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- service_package_items: Ordered services within a package
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS service_package_items (
    package_id INT UNSIGNED NOT NULL,
    service_id INT UNSIGNED NOT NULL,
    sort_order INT UNSIGNED NOT NULL,
    PRIMARY KEY (package_id, service_id),
    KEY idx_service_package_items_package (package_id),
    KEY idx_service_package_items_service (service_id),
    CONSTRAINT fk_service_package_items_package FOREIGN KEY (package_id)
        REFERENCES service_packages(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_service_package_items_service FOREIGN KEY (service_id)
        REFERENCES services(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- staff: Operatori/dipendenti
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS staff (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL DEFAULT '',
    color_hex VARCHAR(7) NOT NULL DEFAULT '#FFD700',
    avatar_url VARCHAR(500) DEFAULT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_default TINYINT(1) NOT NULL DEFAULT 0,
    is_bookable_online TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_staff_business (business_id),
    KEY idx_staff_sort (business_id, sort_order),
    KEY idx_staff_bookable (business_id, is_bookable_online, is_active),
    CONSTRAINT fk_staff_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- staff_locations: Relazione N:M staff <-> locations
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS staff_locations (
    staff_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (staff_id, location_id),
    KEY idx_staff_locations_location (location_id),
    CONSTRAINT fk_staff_locations_staff FOREIGN KEY (staff_id) 
        REFERENCES staff(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_staff_locations_location FOREIGN KEY (location_id) 
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- staff_services: Define which services each staff member can perform
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS staff_services (
    staff_id INT UNSIGNED NOT NULL,
    service_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (staff_id, service_id),
    KEY idx_staff_services_service (service_id),
    CONSTRAINT fk_staff_services_staff FOREIGN KEY (staff_id) 
        REFERENCES staff(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_staff_services_service FOREIGN KEY (service_id) 
        REFERENCES services(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Services that each staff member is qualified to perform';

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

-- ----------------------------------------------------------------------------
-- clients: Clienti gestiti dal business (anagrafica gestionale)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS clients (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED DEFAULT NULL COMMENT 'Link a user se registrato online',
    first_name VARCHAR(100) DEFAULT NULL,
    last_name VARCHAR(100) DEFAULT NULL,
    email VARCHAR(255) DEFAULT NULL,
    phone VARCHAR(50) DEFAULT NULL,
    gender VARCHAR(20) DEFAULT NULL,
    birth_date DATE DEFAULT NULL,
    city VARCHAR(100) DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    loyalty_points INT NOT NULL DEFAULT 0,
    last_visit TIMESTAMP NULL DEFAULT NULL,
    is_archived TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_clients_business (business_id),
    KEY idx_clients_business_email (business_id, email),
    KEY idx_clients_business_phone (business_id, phone),
    KEY idx_clients_business_archived (business_id, is_archived),
    KEY idx_clients_user (user_id),
    CONSTRAINT fk_clients_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- resources: Risorse fisiche (cabine, attrezzature) - opzionale MVP+
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS resources (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    location_id INT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 1,
    type VARCHAR(100) DEFAULT NULL,
    note TEXT DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_resources_location (location_id),
    CONSTRAINT fk_resources_location FOREIGN KEY (location_id) 
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 2: AUTHENTICATION TABLES (from 0002_auth.sql)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- users: Identità GLOBALE per autenticazione
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL COMMENT 'bcrypt or argon2id hash',
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(50) DEFAULT NULL,
    email_verified_at TIMESTAMP NULL DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    is_superadmin TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_users_email (email),
    KEY idx_users_active (is_active),
    KEY idx_users_created (created_at),
    KEY idx_users_superadmin (is_superadmin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- auth_sessions: Sessioni con refresh token
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auth_sessions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    refresh_token_hash VARCHAR(64) NOT NULL COMMENT 'SHA-256 hex of refresh token',
    user_agent VARCHAR(500) DEFAULT NULL COMMENT 'Browser/app identification',
    ip_address VARCHAR(45) DEFAULT NULL COMMENT 'IPv4 or IPv6',
    expires_at TIMESTAMP NOT NULL COMMENT 'Refresh token expiration',
    last_used_at TIMESTAMP NULL DEFAULT NULL COMMENT 'Last refresh attempt',
    revoked_at TIMESTAMP NULL DEFAULT NULL COMMENT 'Manual revocation timestamp',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_auth_sessions_token (refresh_token_hash),
    KEY idx_auth_sessions_user (user_id),
    KEY idx_auth_sessions_user_active (user_id, revoked_at, expires_at),
    KEY idx_auth_sessions_expires (expires_at),
    CONSTRAINT fk_auth_sessions_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- password_reset_tokens: Token per reset password
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS password_reset_token_users (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    token_hash VARCHAR(64) NOT NULL COMMENT 'SHA-256 hex of reset token',
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_password_reset_token (token_hash),
    KEY idx_password_reset_user (user_id),
    KEY idx_password_reset_expires (expires_at),
    CONSTRAINT fk_password_reset_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add FK from clients to users
ALTER TABLE clients
    ADD CONSTRAINT fk_clients_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE;

-- ============================================================================
-- SECTION 3: BUSINESS USERS & INVITATIONS (from 0013, 0014)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- business_users: Links users to businesses with role-based access
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS business_users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    role ENUM('owner', 'admin', 'manager', 'staff') NOT NULL DEFAULT 'staff',
    staff_id INT UNSIGNED NULL,
    can_manage_bookings TINYINT(1) NOT NULL DEFAULT 1,
    can_manage_clients TINYINT(1) NOT NULL DEFAULT 1,
    can_manage_services TINYINT(1) NOT NULL DEFAULT 0,
    can_manage_staff TINYINT(1) NOT NULL DEFAULT 0,
    can_view_reports TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    invited_by INT UNSIGNED NULL,
    invited_at TIMESTAMP NULL,
    accepted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_business_users_business 
        FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_business_users_user 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_business_users_staff 
        FOREIGN KEY (staff_id) REFERENCES staff(id) ON DELETE SET NULL,
    CONSTRAINT fk_business_users_invited_by 
        FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT uk_business_user UNIQUE (business_id, user_id),
    KEY idx_business_users_user_active (user_id, is_active),
    KEY idx_business_users_business_role (business_id, role, is_active),
    KEY idx_business_users_staff (staff_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- business_invitations: Email-based invites
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS business_invitations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    business_id INT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    role ENUM('admin', 'manager', 'staff') NOT NULL DEFAULT 'staff',
    token VARCHAR(64) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    status ENUM('pending', 'accepted', 'expired', 'revoked') NOT NULL DEFAULT 'pending',
    accepted_by INT UNSIGNED NULL,
    accepted_at TIMESTAMP NULL,
    invited_by INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_invitations_business 
        FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE,
    CONSTRAINT fk_invitations_invited_by 
        FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_invitations_accepted_by 
        FOREIGN KEY (accepted_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT uk_invitation_token UNIQUE (token),
    CONSTRAINT uk_pending_invitation UNIQUE (business_id, email, status),
    KEY idx_invitations_token (token, status),
    KEY idx_invitations_business_status (business_id, status),
    KEY idx_invitations_email_status (email, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 4: BOOKING TABLES (from 0003_booking.sql)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- bookings: Prenotazioni (contenitore di uno o più servizi)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bookings (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL,
    client_id INT UNSIGNED DEFAULT NULL COMMENT 'Client from business anagrafica',
    user_id INT UNSIGNED DEFAULT NULL COMMENT 'User who booked online',
    client_name VARCHAR(255) DEFAULT NULL COMMENT 'Fallback if no client',
    notes TEXT DEFAULT NULL,
    status ENUM('pending', 'confirmed', 'completed', 'cancelled', 'no_show', 'replaced') 
        NOT NULL DEFAULT 'confirmed',
    source ENUM('online', 'manual', 'import','onlinestaff') NOT NULL DEFAULT 'manual',
    idempotency_key VARCHAR(64) DEFAULT NULL COMMENT 'Client-provided UUID for idempotent POST',
    idempotency_expires_at TIMESTAMP NULL DEFAULT NULL COMMENT 'Key expiration (24h TTL)',
    replaces_booking_id INT UNSIGNED NULL COMMENT 'ID of booking this one replaces (for new booking)',
    replaced_by_booking_id INT UNSIGNED NULL COMMENT 'ID of booking that replaced this (for original)',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_bookings_idempotency (business_id, idempotency_key),
    KEY idx_bookings_business_location (business_id, location_id),
    KEY idx_bookings_business_location_created (business_id, location_id, created_at),
    KEY idx_bookings_client (client_id),
    KEY idx_bookings_user (user_id),
    KEY idx_bookings_status (business_id, status),
    KEY idx_bookings_idempotency_expires (idempotency_expires_at),
    KEY idx_bookings_replaces_booking_id (replaces_booking_id),
    KEY idx_bookings_replaced_by_booking_id (replaced_by_booking_id),
    CONSTRAINT fk_bookings_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bookings_location FOREIGN KEY (location_id) 
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bookings_client FOREIGN KEY (client_id) 
        REFERENCES clients(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_bookings_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_bookings_replaces_booking_id FOREIGN KEY (replaces_booking_id)
        REFERENCES bookings(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_bookings_replaced_by_booking_id FOREIGN KEY (replaced_by_booking_id)
        REFERENCES bookings(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- booking_items: Singoli appuntamenti dentro una booking
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS booking_items (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    booking_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL COMMENT 'Denormalized from bookings for availability queries',
    service_id INT UNSIGNED NOT NULL,
    service_variant_id INT UNSIGNED NOT NULL,
    staff_id INT UNSIGNED NOT NULL,
    start_time TIMESTAMP NOT NULL COMMENT 'UTC',
    end_time TIMESTAMP NOT NULL COMMENT 'UTC',
    price DECIMAL(10,2) DEFAULT NULL COMMENT 'Applied price at booking time',
    extra_blocked_minutes INT UNSIGNED NOT NULL DEFAULT 0,
    extra_processing_minutes INT UNSIGNED NOT NULL DEFAULT 0,
    service_name_snapshot VARCHAR(255) DEFAULT NULL,
    client_name_snapshot VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_booking_items_booking (booking_id),
    KEY idx_booking_items_staff_time (staff_id, start_time, end_time),
    KEY idx_booking_items_location_time (location_id, start_time, end_time),
    KEY idx_booking_items_service (service_id),
    KEY idx_booking_items_variant (service_variant_id),
    CONSTRAINT fk_booking_items_booking FOREIGN KEY (booking_id) 
        REFERENCES bookings(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_booking_items_location FOREIGN KEY (location_id) 
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_booking_items_service FOREIGN KEY (service_id) 
        REFERENCES services(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_booking_items_variant FOREIGN KEY (service_variant_id) 
        REFERENCES service_variants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_booking_items_staff FOREIGN KEY (staff_id) 
        REFERENCES staff(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- booking_replacements: Audit table linking original bookings to replacements
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS booking_replacements (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    original_booking_id INT UNSIGNED NOT NULL 
        COMMENT 'The booking that was replaced',
    new_booking_id INT UNSIGNED NOT NULL 
        COMMENT 'The booking that replaced the original',
    actor_type VARCHAR(32) NOT NULL 
        COMMENT 'customer, staff, or system',
    actor_id INT UNSIGNED NULL 
        COMMENT 'ID of the actor (client_id for customer, user_id for staff)',
    reason VARCHAR(255) NULL 
        COMMENT 'Optional reason for the modification',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_booking_replacements_original (original_booking_id),
    UNIQUE KEY uk_booking_replacements_new (new_booking_id),
    KEY idx_booking_replacements_created_at (created_at),
    CONSTRAINT fk_booking_replacements_original
        FOREIGN KEY (original_booking_id) REFERENCES bookings(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_booking_replacements_new
        FOREIGN KEY (new_booking_id) REFERENCES bookings(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Audit table linking original bookings to their replacements';

-- ----------------------------------------------------------------------------
-- booking_events: Immutable audit trail for all booking events
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS booking_events (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    booking_id INT UNSIGNED NOT NULL 
        COMMENT 'The booking this event relates to',
    event_type VARCHAR(64) NOT NULL 
        COMMENT 'Type: booking_created, booking_replaced, booking_created_by_replace, booking_cancelled, etc.',
    actor_type VARCHAR(32) NOT NULL 
        COMMENT 'customer, staff, or system',
    actor_id INT UNSIGNED NULL 
        COMMENT 'ID of the actor who caused the event',
    actor_name VARCHAR(255) NULL 
        COMMENT 'Denormalized actor name at event time (preserved even if actor deleted)',
    correlation_id VARCHAR(64) NULL 
        COMMENT 'UUID to correlate related events',
    payload_json JSON NOT NULL 
        COMMENT 'Event-specific data with before/after snapshots',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_booking_events_booking_id (booking_id),
    KEY idx_booking_events_event_type (event_type),
    KEY idx_booking_events_created_at (created_at),
    KEY idx_booking_events_correlation_id (correlation_id),
    CONSTRAINT fk_booking_events_booking
        FOREIGN KEY (booking_id) REFERENCES bookings(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Immutable audit trail for all booking events';

-- ----------------------------------------------------------------------------
-- time_blocks: Blocchi di non disponibilità (ferie, pause, riunioni)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS time_blocks (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    location_id INT UNSIGNED NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    reason VARCHAR(255) DEFAULT NULL,
    is_all_day TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_time_blocks_business_location (business_id, location_id),
    KEY idx_time_blocks_time (start_time, end_time),
    CONSTRAINT fk_time_blocks_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_time_blocks_location FOREIGN KEY (location_id) 
        REFERENCES locations(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- time_block_staff: Relazione N:M time_blocks <-> staff
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS time_block_staff (
    time_block_id INT UNSIGNED NOT NULL,
    staff_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (time_block_id, staff_id),
    KEY idx_time_block_staff_staff (staff_id),
    CONSTRAINT fk_time_block_staff_block FOREIGN KEY (time_block_id) 
        REFERENCES time_blocks(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_time_block_staff_staff FOREIGN KEY (staff_id) 
        REFERENCES staff(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SECTION 5: WEBHOOKS (from 0008_webhook_infrastructure.sql)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- webhook_endpoints: Registered webhook endpoints for businesses
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS webhook_endpoints (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    url VARCHAR(500) NOT NULL,
    secret VARCHAR(255) NOT NULL COMMENT 'Used to sign webhook payloads',
    events JSON NOT NULL COMMENT 'Array of event types to subscribe to',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_webhook_endpoints_business (business_id),
    KEY idx_webhook_endpoints_active (business_id, is_active),
    CONSTRAINT fk_webhook_endpoints_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Webhook endpoints registered by businesses';

-- ----------------------------------------------------------------------------
-- webhook_deliveries: Log of webhook delivery attempts
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS webhook_deliveries (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    webhook_endpoint_id INT UNSIGNED NOT NULL,
    event_type VARCHAR(100) NOT NULL COMMENT 'booking.created, booking.updated, etc.',
    payload JSON NOT NULL,
    http_status_code INT UNSIGNED NULL COMMENT 'HTTP response code',
    response_body TEXT NULL COMMENT 'Response from webhook endpoint',
    attempt_count INT UNSIGNED NOT NULL DEFAULT 0,
    next_retry_at TIMESTAMP NULL COMMENT 'When to retry if failed',
    delivered_at TIMESTAMP NULL COMMENT 'When successfully delivered',
    failed_at TIMESTAMP NULL COMMENT 'When permanently failed',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_webhook_deliveries_endpoint (webhook_endpoint_id),
    KEY idx_webhook_deliveries_retry (next_retry_at, delivered_at, failed_at),
    KEY idx_webhook_deliveries_event (event_type, created_at),
    CONSTRAINT fk_webhook_deliveries_endpoint FOREIGN KEY (webhook_endpoint_id) 
        REFERENCES webhook_endpoints(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Log of webhook delivery attempts with retry tracking';

-- ============================================================================
-- SECTION 6: NOTIFICATIONS (from 0015_notification_queue.sql)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- notification_queue: Queue for async notification processing
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notification_queue (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    type ENUM('email', 'sms', 'push', 'webhook') NOT NULL DEFAULT 'email',
    channel VARCHAR(50) NOT NULL COMMENT 'booking_confirmed, booking_cancelled, reminder_24h, etc.',
    recipient_type ENUM('user', 'client', 'staff') NOT NULL,
    recipient_id INT UNSIGNED NOT NULL,
    recipient_email VARCHAR(255) NULL,
    recipient_phone VARCHAR(20) NULL,
    recipient_name VARCHAR(100) NULL,
    subject VARCHAR(255) NULL COMMENT 'Email subject',
    payload JSON NOT NULL COMMENT 'Template variables and metadata',
    priority TINYINT UNSIGNED NOT NULL DEFAULT 5 COMMENT '1=highest, 10=lowest',
    scheduled_at TIMESTAMP NULL COMMENT 'For scheduled notifications like reminders',
    status ENUM('pending', 'processing', 'sent', 'failed') NOT NULL DEFAULT 'pending',
    attempts INT UNSIGNED NOT NULL DEFAULT 0,
    max_attempts INT UNSIGNED NOT NULL DEFAULT 3,
    last_attempt_at TIMESTAMP NULL,
    sent_at TIMESTAMP NULL,
    failed_at TIMESTAMP NULL,
    error_message TEXT NULL,
    business_id INT UNSIGNED NULL COMMENT 'For business-specific templates',
    booking_id INT UNSIGNED NULL COMMENT 'Reference to related booking',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_notification_pending (status, scheduled_at, priority),
    KEY idx_notification_business (business_id, channel),
    KEY idx_notification_booking (booking_id),
    KEY idx_notification_recipient (recipient_type, recipient_id),
    CONSTRAINT fk_notification_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_notification_booking FOREIGN KEY (booking_id) 
        REFERENCES bookings(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Queue for async notification processing';

-- ----------------------------------------------------------------------------
-- notification_templates: Custom templates per business
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notification_templates (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    channel VARCHAR(50) NOT NULL COMMENT 'booking_confirmed, booking_cancelled, etc.',
    type ENUM('email', 'sms') NOT NULL DEFAULT 'email',
    subject VARCHAR(255) NULL COMMENT 'Email subject with {{placeholders}}',
    body_html TEXT NULL COMMENT 'HTML body for email',
    body_text TEXT NULL COMMENT 'Plain text body for SMS or email fallback',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_business_channel_type (business_id, channel, type),
    CONSTRAINT fk_notification_templates_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Custom notification templates per business';

-- ----------------------------------------------------------------------------
-- notification_settings: Business notification preferences
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notification_settings (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    business_id INT UNSIGNED NOT NULL,
    email_enabled TINYINT(1) NOT NULL DEFAULT 1,
    email_booking_confirmed TINYINT(1) NOT NULL DEFAULT 1,
    email_booking_cancelled TINYINT(1) NOT NULL DEFAULT 1,
    email_booking_rescheduled TINYINT(1) NOT NULL DEFAULT 1,
    email_reminder_enabled TINYINT(1) NOT NULL DEFAULT 1,
    email_reminder_hours INT UNSIGNED NOT NULL DEFAULT 24 COMMENT 'Hours before appointment',
    sms_enabled TINYINT(1) NOT NULL DEFAULT 0,
    sms_reminder_enabled TINYINT(1) NOT NULL DEFAULT 0,
    sms_reminder_hours INT UNSIGNED NOT NULL DEFAULT 24,
    sender_name VARCHAR(100) NULL COMMENT 'Custom from name',
    reply_to_email VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_business (business_id),
    CONSTRAINT fk_notification_settings_business FOREIGN KEY (business_id) 
        REFERENCES businesses(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Business notification preferences';

-- ============================================================================
-- RE-ENABLE FOREIGN KEY CHECKS
-- ============================================================================
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
