# Class Appointments (Group Bookings) — Implementation Plan (Agent Codex)

## Objective
Implement **Class Appointments** (group sessions with limited capacity + optional waitlist) in the existing agenda system **without changing or breaking any existing Appointment logic/behavior**. Add a parallel feature set that integrates into calendar views and booking flows while preserving all current behavior for 1:1 appointments.

## Hard Constraints
- Do **not** modify existing `Appointment` behavior, validation rules, scheduling, drag/resize logic, ghost overlays, autoscroll, scroll-lock, conflict rules, notifications, or existing API contracts.
- Add new entities, endpoints, UI routes/components in a **backward-compatible** manner.
- All operations that affect capacity and waitlist must be **transactional and race-safe**.
- Multi-tenant safe: every new row must be scoped by `tenant_id`.
- Timezone safe: store datetimes in UTC, display in tenant/user timezone.
- Provide robust tests and rollout steps.

---

## Deliverables
1. **Database**: new tables + indexes + constraints; migration scripts.
2. **Backend**: new endpoints + service layer (transactional booking, cancel, promote from waitlist).
3. **Frontend**: class event creation/edit (admin), class listing/detail (customer), book/cancel, participants list (staff).
4. **Permissions**: role-based access for admin/staff/customer.
5. **Notifications**: hooks/events for confirmation, waitlist, promotion, cancellation (optional if existing notification pipeline exists).
6. **Observability**: logs + metrics for booking conflicts, promotions, capacity.
7. **Tests**: concurrency tests + business rule tests + API contract tests.
8. **Feature flag**: optional toggles for safe rollout.

---

## Scope Definitions

### New Core Objects
- **ClassEvent**: a calendar entity representing a group session (fitness class, lesson, etc.)
- **ClassBooking**: a participant’s reservation for a ClassEvent
- **ClassSeries (optional, phase 2)**: recurrence template; generates ClassEvents

### Booking States
Use a small finite state set:
- `CONFIRMED`
- `WAITLISTED`
- `CANCELLED_BY_CUSTOMER`
- `CANCELLED_BY_STAFF`
- `NO_SHOW` (optional)
- `ATTENDED` (optional)

---

## Database (MySQL) — Schema & Rules

### Table: `class_events`
Create a new table, do not reuse/extend existing appointments table.

**Columns**
- `id` (PK, bigint/uuid consistent with existing patterns)
- `tenant_id` (FK/required)
- `class_type_id` (FK to your service/type table; required)
- `starts_at_utc` (datetime; required)
- `ends_at_utc` (datetime; required)
- `location_id` (nullable if not used)
- `resource_id` (nullable; e.g., room)
- `instructor_staff_id` (nullable/required per business)
- `capacity_total` (int; required; >= 1)
- `capacity_reserved` (int; default 0; >= 0; <= capacity_total)
- `waitlist_enabled` (tinyint; default 1)
- `booking_open_at_utc` (datetime; nullable; if null → always open)
- `booking_close_at_utc` (datetime; nullable; if null → open until starts_at)
- `cancel_cutoff_minutes` (int; default 0)
- `status` (enum/varchar: `SCHEDULED`, `CANCELLED`, `COMPLETED`)
- `visibility` (enum/varchar: `PUBLIC`, `PRIVATE`)
- `price_cents` (nullable int)
- `currency` (nullable char(3))
- `created_at_utc`, `updated_at_utc`

**Indexes**
- `(tenant_id, starts_at_utc)`
- `(tenant_id, resource_id, starts_at_utc)`
- `(tenant_id, instructor_staff_id, starts_at_utc)`
- `(tenant_id, class_type_id, starts_at_utc)`
- `(tenant_id, status, starts_at_utc)`

**Constraints**
- `capacity_total >= 1`
- `capacity_reserved BETWEEN 0 AND capacity_total`
- `ends_at_utc > starts_at_utc`

### Table: `class_bookings`
**Columns**
- `id` (PK)
- `tenant_id` (required)
- `class_event_id` (FK required)
- `customer_id` (FK required)
- `status` (as defined above; required)
- `waitlist_position` (int nullable; required only when WAITLISTED)
- `booked_at_utc` (datetime required)
- `cancelled_at_utc` (datetime nullable)
- `checked_in_at_utc` (datetime nullable)
- `payment_status` (nullable enum/varchar if monetization exists)
- `notes` (nullable)
- `created_at_utc`, `updated_at_utc`

**Indexes**
- `(tenant_id, class_event_id, status)`
- `(tenant_id, class_event_id, customer_id)`
- `(tenant_id, customer_id, status)`
- `(tenant_id, class_event_id, waitlist_position)`

**Uniqueness**
- Enforce **one active booking per customer per event**:
  - Either a partial unique index (if supported in your MySQL version) or enforce via transactional checks.
  - Practical approach: unique constraint on `(tenant_id, class_event_id, customer_id)` and allow only one row; use status transitions instead of inserting multiple rows. This is preferred.

### Counter Strategy (Race-Safe Capacity)
To avoid counting rows under heavy load:
- Add to `class_events`:
  - `confirmed_count` (int default 0)
  - `waitlist_count` (int default 0)
Maintain these counters only inside transactions to make booking O(1) and race-safe.

**Additional Columns**
- `confirmed_count` (int default 0; always <= capacity_total - capacity_reserved)
- `waitlist_count` (int default 0)

**Constraint**
- `confirmed_count >= 0`, `waitlist_count >= 0`
- Enforce via application logic; DB check constraints only if your MySQL version supports and you already use them.

### Migration Requirements
- Add migrations in your existing migration framework.
- Write **up** and **down** migrations.
- Add seed/reference data only if required (e.g., class types).

---

## Backend — Contracts & Services

### Endpoint Set (New, Non-Breaking)
Create a new route group (e.g., `/class-events`) to avoid changing existing appointment routes.

#### Public/Customer
- `GET /class-events?from=...&to=...&location_id=&class_type_id=`
  - Returns list with `spots_left`, `is_full`, `my_booking_status`
- `GET /class-events/{id}`
  - Returns details + counts + booking window + cancel cutoff + `my_booking_status`
- `POST /class-events/{id}/book`
  - Body: `{ seats: 1 }` (optional; default 1; if you do not support multi-seat, ignore and always 1)
  - Returns: `{ result: CONFIRMED|WAITLISTED, spots_left, waitlist_position? }`
- `POST /class-events/{id}/cancel`
  - Returns: `{ cancelled: true, promoted_customer_id?: ..., promotion_result?: ... }` (promotion details for staff logs)

#### Staff/Admin
- `POST /class-events`
- `PATCH /class-events/{id}`
- `POST /class-events/{id}/cancel-event`
- `GET /class-events/{id}/participants`
- `POST /class-events/{id}/checkin` (optional)
- `POST /class-events/{id}/mark-no-show` (optional)

### Authorization
- Customer endpoints: require authenticated customer.
- Staff endpoints: require staff/admin roles.
- Participants list: staff/admin only.
- For `visibility=PRIVATE`, allow booking only for permitted customers (if you have customer groups); otherwise keep feature disabled.

---

## Core Business Rules (Implement Exactly)

### Availability Computation
Define:
- `effective_capacity = capacity_total - capacity_reserved`
- `spots_left = max(0, effective_capacity - confirmed_count)`

### Booking Window
Booking allowed when:
- `class_event.status == SCHEDULED`
- Current time `now_utc >= booking_open_at_utc` if set
- Current time `now_utc <= booking_close_at_utc` if set else `now_utc < starts_at_utc`
- Optional: disallow booking if `now_utc >= starts_at_utc`

### Cancel Cutoff
Customer cancel allowed when:
- `now_utc <= starts_at_utc - cancel_cutoff_minutes`

### Booking Idempotency
- If customer already has booking for this event:
  - If status `CONFIRMED` or `WAITLISTED`, return current status (do not create duplicate).
  - If status is cancelled/no-show/attended, treat as new booking only if policy allows re-booking; default: allow re-book until close time (or deny; pick one and implement consistently).

---

## Transactional Algorithms (Race-Safe)

### Book Flow (MUST be one DB transaction)
1. Start DB transaction.
2. Load `class_events` row FOR UPDATE by `(tenant_id, id)`.
3. Validate event status and booking window.
4. Load or create `class_bookings` row for `(tenant_id, class_event_id, customer_id)` FOR UPDATE.
5. If already `CONFIRMED` or `WAITLISTED`, return status (idempotent).
6. Compute `spots_left = effective_capacity - confirmed_count`.
7. If `spots_left >= 1`:
   - Set booking `status=CONFIRMED`, clear `waitlist_position`.
   - Increment `confirmed_count += 1`.
   - Commit.
   - Emit event `CLASS_BOOKING_CONFIRMED`.
8. Else if `waitlist_enabled`:
   - Assign `waitlist_position = waitlist_count + 1`.
   - Set booking `status=WAITLISTED`.
   - Increment `waitlist_count += 1`.
   - Commit.
   - Emit event `CLASS_BOOKING_WAITLISTED`.
9. Else:
   - Rollback and return “FULL”.

### Cancel Flow (Customer Cancel) (MUST be one DB transaction)
1. Start transaction.
2. Lock `class_events` FOR UPDATE.
3. Lock customer `class_bookings` FOR UPDATE.
4. Validate cancel cutoff.
5. If booking is `CONFIRMED`:
   - Set status `CANCELLED_BY_CUSTOMER`, set `cancelled_at_utc`.
   - Decrement `confirmed_count -= 1`.
   - Promote from waitlist (if any):
     - Find the smallest `waitlist_position` booking with `WAITLISTED` for the event FOR UPDATE.
     - If found:
       - Set promoted booking `status=CONFIRMED`, clear waitlist_position.
       - Decrement `waitlist_count -= 1`.
       - Increment `confirmed_count += 1`.
       - Re-pack waitlist positions (see below) OR maintain gaps and only rely on ordering; prefer re-pack for cleanliness.
       - Emit `CLASS_BOOKING_PROMOTED`.
6. If booking is `WAITLISTED`:
   - Set status `CANCELLED_BY_CUSTOMER`, set `cancelled_at_utc`.
   - Decrement `waitlist_count -= 1`.
   - Re-pack waitlist positions.
7. Commit.
8. Emit `CLASS_BOOKING_CANCELLED`.

### Waitlist Re-Pack (Inside Same Transaction)
- After removing/promoting a waitlisted booking, normalize positions for that event:
  - Recompute ordering by `waitlist_position ASC, booked_at_utc ASC`.
  - Update positions sequentially from 1..N.
- Keep this in one transaction while holding event lock, to prevent duplication.

### Counter Integrity
- Counters are modified only inside the same transaction that modifies booking states.
- Add a periodic integrity job (optional) to reconcile counts vs actual rows and log anomalies.

---

## Backend Implementation Tasks (Agent Checklist)

### A. Add DB Migrations
- Add `class_events` table.
- Add `class_bookings` table.
- Add necessary FKs (tenant, class_type/service, staff, location/resource, customer).
- Add indexes listed above.
- Add new counters (`confirmed_count`, `waitlist_count`) to `class_events`.
- Add unique constraint on `(tenant_id, class_event_id, customer_id)` in `class_bookings`.

### B. Add Domain Layer
Create new domain modules/files (names follow your project conventions):
- `ClassEvent` entity/model + repository/DAO
- `ClassBooking` entity/model + repository/DAO
- `ClassBookingService` implementing transactional algorithms
- `ClassEventService` (create/update/cancel-event, participants list)

### C. Add API Layer
- Add new controllers/routes under `/class-events`.
- Ensure responses include:
  - `spots_left`, `confirmed_count`, `waitlist_count`
  - `my_booking_status` (computed via booking table)
  - `booking_open_at_utc`, `booking_close_at_utc`, `cancel_cutoff_minutes`
- Return consistent error codes:
  - 404 event not found / wrong tenant
  - 409 conflict (FULL, WINDOW_CLOSED, CANCEL_CUTOFF)
  - 403 forbidden (role)
  - 422 validation errors

### D. Add Permissions
- Extend existing RBAC/ACL with:
  - `class_event.manage` (admin)
  - `class_event.participants.read` (staff/admin)
  - `class_event.book` (customer)
- Ensure tenant scoping is enforced everywhere.

### E. Add Notifications (If Existing Pipeline)
- Emit domain events; connect to notification handler:
  - Confirmed
  - Waitlisted
  - Promoted
  - Event cancelled
- If you do not have notifications infrastructure, implement event logging only.

### F. Add Observability
- Log structured events with ids: tenant_id, class_event_id, customer_id, outcome.
- Add metrics counters:
  - booking_confirmed_total
  - booking_waitlisted_total
  - booking_full_total
  - booking_cancel_total
  - booking_promoted_total
  - booking_race_retry_total (if you implement retry)

---

## Frontend (Flutter Web/Mobile) — Non-Breaking Integration

### Principle
- Add a new calendar item type: **ClassEventItem**
- Do not alter existing Appointment rendering, interactions, or gestures.
- Compose calendar timeline with two datasets: appointments + class events.

### Customer UX
1. **Classes List** view:
   - Filter by date range + location + class type
   - Show: title, time, instructor, spots left / sold out, CTA button
2. **Class Detail** view:
   - All fields + cancel policy + booking window
   - CTA:
     - “Prenota” if available
     - “Lista d’attesa” if full and waitlist enabled
     - “Cancella” if booked and within cutoff
3. **My Bookings** view (optional):
   - Show confirmed + waitlisted
   - Quick cancel

### Staff/Admin UX
1. **Create/Edit Class Event**:
   - time, duration, location/resource, instructor, capacity, reserved, waitlist enabled, booking window, cancel cutoff, visibility, price
2. **Participants** list:
   - Two sections: confirmed + waitlist
   - Check-in toggles (optional)
   - Manual promotion (optional; phase 2)
3. **Calendar**:
   - Display class events as distinct blocks; open details on tap/click.

### Frontend Integration Tasks (Agent Checklist)
- Add API client methods for new endpoints.
- Add models for `ClassEventDTO`, `ClassBookingDTO`.
- Add new screens/routes.
- Update calendar data loader to fetch class events alongside appointments.
- Add a renderer for class events; ensure all existing appointment interactions remain unchanged.
- Add caching/invalidation on book/cancel to refresh counts and booking status.

---

## Compatibility Guarantees
- No changes to:
  - appointment tables
  - appointment endpoints
  - appointment scheduling logic
  - UI behaviors for appointments
- All class events are separate objects and only optionally shown in shared calendar views.

---

## Testing Requirements (Must Pass)

### Unit Tests
- Booking flow:
  - confirms when spots available
  - waitlists when full and enabled
  - rejects when full and waitlist disabled
  - respects booking windows
  - idempotency (double book returns same)
- Cancel flow:
  - confirmed cancel decrements count and promotes first waitlisted
  - waitlisted cancel decrements waitlist and repacks positions
  - respects cancel cutoff

### Integration/API Tests
- tenant scoping enforced
- role enforcement enforced
- participant list accessible only to staff/admin
- counts and spots_left accurate

### Concurrency Tests (Critical)
Simulate N parallel bookings for capacity K:
- Exactly K bookings end in CONFIRMED
- Remaining are WAITLISTED (if enabled) or rejected
- No duplicate bookings per customer
- Counters match actual rows after completion
Implementation:
- Use parallel workers calling `POST /class-events/{id}/book` with different customers.
- Verify final state via participants endpoint.

### Frontend Tests (Smoke)
- Calendar renders appointments exactly as before
- Class events render separately
- Book/cancel updates UI state and counts

---

## Rollout Plan (Safe)
1. Add DB migrations.
2. Deploy backend with endpoints behind feature flag `class_events_enabled=false`.
3. Run migration in production.
4. Enable feature flag for internal tenant(s).
5. Validate concurrency test in staging; validate spot counts in production for internal.
6. Enable for more tenants.
7. Add monitoring alerts on counter inconsistencies.

---

## Phase 2 (Optional, After MVP)
- ClassSeries with recurrence templates and generation jobs.
- Multi-seat bookings (`seats > 1`) with per-booking seat count and adjusted counters.
- Private classes with customer groups.
- Payment integration (reserve spot pending payment with expiry).
- Manual staff overrides: force add, force remove, force promote.

---

## Acceptance Criteria (Definition of Done)
- Customers can book a class with limited capacity; system prevents overbooking under concurrency.
- Waitlist works and promotions occur correctly when cancellations happen.
- Staff can create/edit/cancel class events and see participant lists.
- Existing appointment features and behaviors remain unchanged.
- All tests pass, including concurrency tests.
- Metrics/logging present for booking outcomes.
