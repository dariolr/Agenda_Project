# Agenda Backend - Staff Planning Integration Instructions

## Scope

Align agenda availability with the new staff planning model.
Use only agenda_core API data. Do not re-implement planning logic locally.

## Source of Truth

- STAFF_PLANNING_MODEL.md
- agenda_core API responses

## Mandatory API Endpoints

- GET `/v1/staff/{id}/planning?date=YYYY-MM-DD`
- GET `/v1/staff/{id}/planning-availability?date=YYYY-MM-DD`
- GET `/v1/staff/{id}/plannings` (for management UI only)

## Non-Negotiable Rules

- `valid_to = null` means no end date.
- If no planning exists for a date, the staff is unavailable.
- Do not assume a single weekly schedule or static weekly availability.
- Do not calculate week A/B or planning validity on the client.
- No local fallbacks or inferred availability.

## Integration Points (Expected Changes)

1) Agenda availability:
   - `lib/features/agenda/providers/staff_slot_availability_provider.dart`
   - Replace the legacy weekly schedule base with planning availability
     from the API.

2) Legacy schedules:
   - `lib/features/staff/presentation/staff_availability_screen.dart`
   - The agenda must not depend on `/v1/staff/{id}/schedules`.
   - Keep planning management in `staff_planning_provider.dart`.

3) Provider usage:
   - Prefer a provider that reads planning availability for the current date
     and staff list shown in agenda.

## Notes

- Do not merge or override planning data with local rules.
- Any unavailable date or missing planning means no slots in agenda.
