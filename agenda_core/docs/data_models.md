# Data Models — agenda_core

## Core Entities

### Service
- id
- business_id
- category_id
- name
- duration_minutes
- price
- is_free
- is_price_starting_from
- is_bookable_online

### Staff
- id
- business_id
- name
- surname
- is_bookable_online

### Booking
- id
- business_id
- location_id
- customer_id
- start_time
- end_time
- notes

### ServicePackage
- id
- business_id
- location_id
- category_id
- name
- description
- override_price
- override_duration_minutes
- is_active
- is_broken
- created_at
- updated_at

### ServicePackageItem
- package_id
- service_id
- sort_order

---

## User & Auth Entities

### User
- id
- email (unique, global)
- password_hash
- first_name
- last_name
- phone
- is_active
- is_superadmin
- created_at
- updated_at

### AuthSession
- id
- user_id
- refresh_token_hash (SHA-256)
- device_info
- ip_address
- last_used_at
- expires_at
- revoked_at
- created_at

---

## Business Access Control (M11)

### BusinessUser
Associa utenti a businesses con ruoli e permessi.

- id
- business_id
- user_id
- role (enum: owner, admin, manager, staff)
- staff_id (optional, link a staff record)
- can_manage_bookings
- can_manage_clients
- can_manage_services
- can_manage_staff
- can_view_reports
- is_active
- invited_by
- invited_at
- joined_at
- created_at
- updated_at

**Role Hierarchy:**
- `owner`: Full control, can delete business, manage all users
- `admin`: Full control except delete business, can manage users
- `manager`: Can manage appointments, clients, staff schedules
- `staff`: Can view/edit own appointments only

**Unique Constraint:** `(business_id, user_id)`

### BusinessInvitation
Inviti via email per nuovi operatori.

- id
- business_id
- email
- role (enum: admin, manager, staff)
- token (64-char hex, unique)
- expires_at (default: created_at + 7 days)
- status (enum: pending, accepted, expired, revoked)
- accepted_by (user_id, nullable)
- accepted_at (nullable)
- invited_by (user_id)
- created_at
- updated_at

**Unique Constraint:** `(business_id, email, status)` - un solo invito pending per email

**Indexes:**
- `token, status` - lookup per accettazione
- `business_id, status` - lista inviti pendenti
- `email, status` - ricerca inviti per email

---

## Relationships

```
User (1) ----< (N) AuthSession
User (1) ----< (N) BusinessUser >---- (1) Business
User (1) ----< (N) BusinessInvitation >---- (1) Business
Business (1) ----< (N) Location
Business (1) ----< (N) Staff
Business (1) ----< (N) Service
Business (1) ----< (N) Client
Location (1) ----< (N) Booking
```

---

## Notes

- `is_superadmin` in `users` è flag globale, non legato a nessun business
- Superadmin bypassa completamente `business_users` e può operare su qualsiasi business
- `staff_id` in `business_users` permette di collegare un operatore al suo calendario staff
