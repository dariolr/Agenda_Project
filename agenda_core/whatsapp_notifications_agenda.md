# WhatsApp Notifications Integration -- Agenda Platform

Version: 1.0 Status: Production-Ready Specification Scope: Multi-tenant
SaaS booking platform Compliance: Meta WhatsApp Business Platform, GDPR,
Security Best Practices

------------------------------------------------------------------------

# 1. OBJECTIVE

Implement a fully robust, scalable, secure, and compliant WhatsApp
notification system for a multi-tenant booking platform where each
business connects its own WhatsApp Business account.

The system MUST: - Support multi-tenant isolation - Use WhatsApp Cloud
API (official Meta) - Handle transactional templates - Respect opt-in
requirements - Be production-grade and scalable - Be audit-safe (GDPR
compliant) - Be resilient to failure and abuse

------------------------------------------------------------------------

# 2. ARCHITECTURE OVERVIEW

Components:

1.  Frontend (Admin Panel)
    -   WhatsApp integration settings
    -   Template management
    -   Notification rules
    -   Consent management
2.  Backend API Layer
    -   OAuth Meta onboarding
    -   Token storage (encrypted)
    -   Notification orchestration
    -   Webhook handling
3.  Notification Service (Microservice Recommended)
    -   Outbox pattern
    -   Worker sender
    -   Retry logic
    -   Rate limiting
4.  Database
    -   Business configuration
    -   Consent tracking
    -   Message logging
    -   Delivery status
5.  Scheduler (Cron / Queue-driven)
    -   Reminder generation
    -   Delayed notifications

------------------------------------------------------------------------

# 3. DATABASE STRUCTURE

## 3.1 business_whatsapp_config

-   id (UUID)
-   business_id (FK)
-   waba_id
-   phone_number_id
-   access_token_encrypted
-   token_expires_at
-   connected_at
-   status (active, disabled, error)
-   quality_rating
-   created_at
-   updated_at

## 3.2 whatsapp_templates

-   id (UUID)
-   business_id
-   template_name
-   category (utility, authentication, marketing)
-   language_code
-   status (approved, pending, rejected)
-   created_at

## 3.3 customer_consents

-   id (UUID)
-   customer_id
-   business_id
-   channel (whatsapp)
-   opt_in (boolean)
-   opt_in_at
-   source (web, app, whatsapp, paper)
-   proof_reference
-   revoked_at
-   created_at

## 3.4 notification_outbox

-   id (UUID)
-   business_id
-   customer_id
-   channel (whatsapp)
-   event_type
-   template_name
-   payload_json
-   status (queued, sent, delivered, read, failed)
-   provider_message_id
-   error_code
-   retry_count
-   next_retry_at
-   created_at
-   updated_at

## 3.5 whatsapp_message_log

-   id (UUID)
-   business_id
-   customer_id
-   direction (outbound, inbound)
-   message_type
-   content_snapshot
-   provider_message_id
-   delivery_status
-   timestamp

------------------------------------------------------------------------

# 4. BUSINESS ONBOARDING FLOW (META OAUTH)

1.  Business clicks "Connect WhatsApp".
2.  Redirect to Meta OAuth login.
3.  Retrieve:
    -   access_token
    -   waba_id
    -   phone_number_id
4.  Encrypt token before storing.
5.  Register webhook endpoint.
6.  Set status = active.

Token encryption MUST use strong symmetric encryption (AES-256).

------------------------------------------------------------------------

# 5. WEBHOOK HANDLING

Endpoint MUST:

-   Validate signature from Meta
-   Support verification challenge
-   Process events:
    -   message status updates
    -   inbound messages

On inbound: - Log message - Optionally forward to business UI

------------------------------------------------------------------------

# 6. TEMPLATE MANAGEMENT

Minimum required templates:

1.  booking_confirmed
2.  reminder_24h
3.  reminder_2h
4.  booking_canceled
5.  booking_rescheduled

Rules: - Only approved templates can be used - No marketing content
unless explicit marketing opt-in exists

------------------------------------------------------------------------

# 7. CONSENT MANAGEMENT

Consent MUST be:

-   Explicit
-   Channel-specific
-   Logged with timestamp
-   Revocable

Opt-in example text:

"I agree to receive appointment notifications via WhatsApp from
\[Business Name\]."

Before sending:

IF consent.whatsapp != true DO NOT SEND

------------------------------------------------------------------------

# 8. NOTIFICATION FLOW

Event-driven architecture required.

Example flow:

1.  Booking confirmed
2.  Emit NotificationEvent
3.  Notification Service checks:
    -   WhatsApp enabled?
    -   Business connected?
    -   Template approved?
    -   Customer consent valid?
4.  Insert into notification_outbox
5.  Worker sends message

------------------------------------------------------------------------

# 9. RETRY LOGIC

Retry policy:

-   Exponential backoff
-   Max 5 retries
-   Stop on permanent errors

Permanent errors include: - Invalid phone - Template rejected - Policy
violation

------------------------------------------------------------------------

# 10. RATE LIMITING

Per business limits required.

Implement:

-   Max sends per minute
-   Daily send cap configurable
-   Automatic suspension on excessive failures

------------------------------------------------------------------------

# 11. SECURITY REQUIREMENTS

-   Encrypt access tokens
-   Do not expose tokens to frontend
-   Secure webhook endpoint
-   Validate all incoming payloads
-   Implement RBAC in admin panel

------------------------------------------------------------------------

# 12. MONITORING & LOGGING

Track:

-   Sent
-   Delivered
-   Read
-   Failed
-   Spam reports

If quality drops below threshold: - Disable sending - Notify business

------------------------------------------------------------------------

# 13. SCALABILITY

Use:

-   Queue system (Redis / RabbitMQ / SQS)
-   Stateless workers
-   Horizontal scaling support

Outbox pattern mandatory.

------------------------------------------------------------------------

# 14. GDPR COMPLIANCE

-   Right to revoke consent
-   Data minimization
-   Retention policy
-   Audit trail
-   Export logs per customer

------------------------------------------------------------------------

# 15. BUSINESS MODEL OPTIONS

Option A: Self-billing via Meta Option B: Reseller model (advanced)

Recommended: Self-billing.

------------------------------------------------------------------------

# 16. MVP CHECKLIST

-   OAuth integration
-   2 templates
-   Outbox
-   Worker
-   Webhook
-   Consent tracking

------------------------------------------------------------------------

# 17. PRODUCTION READINESS CHECKLIST

-   Load testing
-   Failure simulation
-   Rate limiting validation
-   Token rotation handling
-   Monitoring dashboard
-   Abuse detection

------------------------------------------------------------------------

END OF SPECIFICATION
