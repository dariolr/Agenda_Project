# Demo Policy Matrix (agenda_core)

| Endpoint / Area | Policy | Stato |
|---|---|---|
| `POST /v1/businesses/{id}/invitations` | `canSendRealEmails()` | Bloccato in demo |
| `POST /v1/admin/businesses` | `canExecuteDestructiveBusinessActions()` | Bloccato in demo |
| `PUT /v1/admin/businesses/{id}` | `canExecuteDestructiveBusinessActions()` | Bloccato in demo |
| `DELETE /v1/admin/businesses/{id}` | `canDeleteBusiness()` | Bloccato in demo |
| `POST /v1/admin/businesses/{id}/resend-invite` | `canSendRealEmails()` | Bloccato in demo |
| `GET /v1/admin/businesses/{id}/export` | `canRunRealExports()` | Bloccato in demo |
| `GET /v1/admin/businesses/by-slug/{slug}/export` | `canRunRealExports()` | Bloccato in demo |
| `POST /v1/admin/businesses/import` | `canExecuteDestructiveBusinessActions()` | Bloccato in demo |
| `POST /v1/admin/businesses/sync-from-production` | `canCallExternalWebhooks()` | Bloccato in demo |
| `DELETE /v1/locations/{id}` | `canDeleteLocation()` | Bloccato in demo |
| `DELETE /v1/businesses/{business_id}/users/{target_user_id}` | `canDeleteCriticalData()` | Bloccato in demo |
| `PUT /v1/bookings/{booking_id}/payment` (via controller pagamenti) | `canUseRealPayments()` | Bloccato in demo |
| Invio email applicativo (`EmailService`) | `canSendRealEmails()` | Bloccato in demo |

Risposta standard in caso di blocco: `Response::demoBlocked(...)` (HTTP 403, `code=demo_blocked`, `demo_blocked=true`).
