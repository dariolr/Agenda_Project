# Agenda Frontend - Staff Planning Integration Instructions

## Scope

Align availability, slots, and date selection with the new staff planning model.
Use only agenda_core API data. Do not re-implement planning logic locally.

## Source of Truth

- STAFF_PLANNING_MODEL.md
- agenda_core API responses

## Mandatory API Endpoints

- GET `/v1/staff/{id}/planning?date=YYYY-MM-DD`
- GET `/v1/staff/{id}/planning-availability?date=YYYY-MM-DD`
- GET `/v1/availability?location_id=X&date=YYYY-MM-DD&service_ids=1,2&staff_id=N`

## Non-Negotiable Rules

- `valid_to = null` means no end date.
- If no planning exists for a date, the staff is unavailable.
- Do not assume a single weekly schedule or static weekly availability.
- Do not calculate week A/B or planning validity on the client.
- No local fallbacks or inferred availability.

## Integration Points (Expected Changes)

1) Date availability:
   - `lib/features/booking/providers/booking_provider.dart`
   - `availableDatesProvider` must only mark dates that have valid planning
     and actual available slots.

2) Slot availability:
   - `lib/features/booking/providers/booking_provider.dart`
   - `availableSlotsProvider` must use planning availability for the date
     before returning slots.

3) Staff availability logic:
   - `lib/features/booking/data/booking_repository.dart`
   - Use `getStaffPlanningForDate` and `getStaffPlanningAvailability` where
     a planning check is required.

4) Reschedule flow:
   - `lib/features/booking/presentation/dialogs/reschedule_booking_dialog.dart`
   - Do not show slots for dates without valid planning.

## Notes

- The staff step occurs before date selection. Do not add assumptions for staff
  without a selected date. Apply planning checks when a date is known.
- Keep all UI texts localized with `context.l10n`.
