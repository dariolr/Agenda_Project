<?php

declare(strict_types=1);

namespace Agenda\UseCases\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\CalendarICSGenerator;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Queue an email notification for a class booking event.
 *
 * Supported channels:
 *   class_booking_confirmed  — spot confirmed at booking time
 *   class_booking_waitlisted — added to waitlist
 *   class_booking_promoted   — moved from waitlist to confirmed
 *   class_booking_cancelled  — booking cancelled by customer or staff
 *   class_booking_updated    — class event date/time/price changed
 *   class_booking_reminder   — 24h reminder before class start
 */
final class QueueClassBookingNotification
{
    public function __construct(
        private readonly Connection $db,
        private readonly NotificationRepository $notificationRepo,
    ) {}

    /**
     * Queue a notification for the given class booking.
     *
     * @param int    $classBookingId
     * @param int    $businessId
     * @param string $channel  One of the supported channels above
     * @param string|null $scheduledAt  ISO-8601 UTC timestamp for reminders (null = send immediately)
     * @return int Notification queue ID, or 0 if not queued
     */
    public function execute(int $classBookingId, int $businessId, string $channel, ?string $scheduledAt = null): int
    {
        // Load all data needed for the email in one query
        $data = $this->loadClassBookingData($classBookingId, $businessId);
        if ($data === null) {
            return 0;
        }

        $locationTz = new DateTimeZone($data['location_timezone'] ?? 'Europe/Rome');
        $now = new DateTimeImmutable('now', $locationTz);

        // Don't send notification if the class has already started
        if (isset($data['starts_at']) && trim((string) $data['starts_at']) !== '') {
            $startsAt = new DateTimeImmutable((string) $data['starts_at'], new DateTimeZone('UTC'));
            if ($startsAt < $now) {
                return 0;
            }
        }

        // Deduplication
        if ($this->notificationRepo->wasRecentlySentForClassBooking($channel, $classBookingId)) {
            return 0;
        }

        // Check notification settings
        $settingKey = $this->settingKeyForChannel($channel);
        if ($settingKey !== null) {
            $settings = $this->notificationRepo->getSettings($businessId);
            if (
                $settings
                && array_key_exists($settingKey, $settings)
                && $settings[$settingKey] !== null
                && (int) $settings[$settingKey] === 0
            ) {
                return 0;
            }
        }

        $clientId  = (int) ($data['customer_id'] ?? 0);
        if ($clientId <= 0) {
            return 0;
        }

        // Get client email
        $clientEmail = $this->getClientEmail($clientId);
        if ($clientEmail === null || empty($clientEmail['email'])) {
            return 0;
        }

        $locale = $this->resolveLocale($data);

        $variables = $this->buildVariables($data, $locale);
        $template  = $this->resolveTemplate($channel, $locale);

        $priority = match ($channel) {
            'class_booking_promoted'  => 1,
            'class_booking_confirmed' => 1,
            'class_booking_waitlisted'=> 2,
            'class_booking_cancelled' => 2,
            'class_booking_updated'   => 2,
            default                   => 5,
        };

        $attachments = [];
        if (in_array($channel, ['class_booking_confirmed', 'class_booking_promoted'], true)) {
            try {
                $eventData   = CalendarICSGenerator::prepareEventFromClassBooking($data, $locale);
                $icsContent  = CalendarICSGenerator::generateIcsContent($eventData);
                $attachments = [CalendarICSGenerator::createIcsAttachment($icsContent, 'lezione.ics')];
            } catch (\Throwable) {
                // ICS failure must not block the notification
            }
        } elseif ($channel === 'class_booking_updated') {
            try {
                $icsContent  = CalendarICSGenerator::generateUpdateIcsFromClassBooking($data);
                $attachments = [CalendarICSGenerator::createIcsAttachment($icsContent, 'aggiornamento.ics')];
            } catch (\Throwable) {
            }
        } elseif ($channel === 'class_booking_cancelled') {
            try {
                $icsContent  = CalendarICSGenerator::generateCancelIcsFromClassBooking($data);
                $attachments = [CalendarICSGenerator::createIcsAttachment($icsContent, 'cancellazione.ics')];
            } catch (\Throwable) {
            }
        }

        $payload = ['template' => $channel, 'variables' => $variables];
        if (!empty($attachments)) {
            $payload['attachments'] = $attachments;
        }

        return $this->notificationRepo->queue([
            'type'              => 'email',
            'channel'           => $channel,
            'recipient_type'    => 'client',
            'recipient_id'      => $clientId,
            'recipient_email'   => $clientEmail['email'],
            'recipient_name'    => $this->extractFirstName($clientEmail['name'] ?? null),
            'subject'           => EmailTemplateRenderer::render($template['subject'], $variables),
            'payload'           => $payload,
            'priority'          => $priority,
            'scheduled_at'      => $scheduledAt,
            'business_id'       => $businessId,
            'class_booking_id'  => $classBookingId,
        ]);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function loadClassBookingData(int $classBookingId, int $businessId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT
                 cb.id                  AS class_booking_id,
                 cb.business_id,
                 cb.customer_id,
                 cb.status,
                 cb.waitlist_position,
                 ce.id                  AS class_event_id,
                 ce.starts_at,
                 ce.ends_at,
                 ce.cancel_cutoff_minutes,
                 ce.price_cents,
                 ce.currency,
                 ct.name                AS class_type_name,
                 l.id                   AS location_id,
                 l.name                 AS location_name,
                 l.address              AS location_address,
                 l.city                 AS location_city,
                 l.phone                AS location_phone,
                 l.timezone             AS location_timezone,
                 l.booking_default_locale AS location_locale,
                 bus.name               AS business_name,
                 bus.email              AS business_email
             FROM class_bookings cb
             INNER JOIN class_events ce
                 ON ce.id = cb.class_event_id AND ce.business_id = cb.business_id
             INNER JOIN class_types ct
                 ON ct.id = ce.class_type_id
             INNER JOIN locations l
                 ON l.id = ce.location_id
             INNER JOIN businesses bus
                 ON bus.id = cb.business_id
             WHERE cb.id = :id AND cb.business_id = :business_id
             LIMIT 1'
        );
        $stmt->execute(['id' => $classBookingId, 'business_id' => $businessId]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);
        return $row ?: null;
    }

    private function getClientEmail(int $clientId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT email, CONCAT(first_name, " ", last_name) AS name FROM clients WHERE id = :id'
        );
        $stmt->execute(['id' => $clientId]);
        return $stmt->fetch(\PDO::FETCH_ASSOC) ?: null;
    }

    private function resolveLocale(array $data): string
    {
        $defaultLocale = getenv('DEFAULT_LOCALE') ?: 'it';
        return EmailTemplateRenderer::normalizeLocale(
            $data['location_locale'] ?? $data['business_locale'] ?? $defaultLocale
        );
    }

    private function buildVariables(array $data, string $locale): array
    {
        $locationTz  = new DateTimeZone($data['location_timezone'] ?? 'Europe/Rome');
        $startsAt    = new DateTimeImmutable((string) $data['starts_at'], new DateTimeZone('UTC'));
        $startsLocal = $startsAt->setTimezone($locationTz);

        $endTime = '';
        if (!empty($data['ends_at'])) {
            $endsAt    = new DateTimeImmutable((string) $data['ends_at'], new DateTimeZone('UTC'));
            $endsLocal = $endsAt->setTimezone($locationTz);
            $endTime   = $endsLocal->format('H:i');
        }

        $isEnglish = EmailTemplateRenderer::normalizeLocale($locale) === 'en';

        // Price row
        $priceCents = (int) ($data['price_cents'] ?? 0);
        $priceRowHtml = '';
        $priceRowText = '';
        if ($priceCents > 0) {
            $formatted = number_format($priceCents / 100, 2, ',', '.');
            $label = $isEnglish ? 'Price' : 'Prezzo';
            $priceRowHtml = sprintf(
                '<tr><td style="padding:8px 0;"><strong style="color:#666;font-size:13px;">%s</strong><br><span style="color:#333;font-size:13px;">€%s</span></td></tr>',
                $label,
                $formatted
            );
            $priceRowText = $isEnglish
                ? sprintf("• Price: €%s\n", $formatted)
                : sprintf("• Prezzo: €%s\n", $formatted);
        }

        // Location block (only when business has multiple locations)
        $locationBlockHtml = '';
        $locationBlockText = '';
        if ($this->hasMultipleLocations((int) ($data['business_id'] ?? 0))) {
            $strings = EmailTemplateRenderer::strings($locale);
            $locationBlockHtml = sprintf(
                '<tr><td style="padding:8px 0;border-bottom:1px solid #e0e0e0;"><strong style="color:#666;font-size:13px;">%s</strong><br><span style="color:#333;font-size:13px;">%s</span><br><span style="color:#333;font-size:13px;">%s</span></td></tr>',
                $strings['where_label'],
                htmlspecialchars((string) ($data['location_name'] ?? ''), ENT_QUOTES, 'UTF-8'),
                htmlspecialchars((string) ($data['location_address'] ?? ''), ENT_QUOTES, 'UTF-8')
            );
            $locationBlockText = sprintf(
                "%s: %s, %s\n",
                $strings['where_label'],
                $data['location_name'] ?? '',
                $data['location_address'] ?? ''
            );
        }

        // Cancellation policy
        $cancelPolicyHtml = '';
        $cancelPolicyText = '';
        $cutoffMinutes = (int) ($data['cancel_cutoff_minutes'] ?? 0);
        if ($cutoffMinutes > 0) {
            $hours = $cutoffMinutes / 60;
            if ($isEnglish) {
                $policyText = $hours >= 24
                    ? sprintf('You can cancel up to %d day(s) before the class.', (int) ($hours / 24))
                    : sprintf('You can cancel up to %d hour(s) before the class.', (int) $hours);
            } else {
                $policyText = $hours >= 24
                    ? sprintf('Puoi annullare fino a %d giorno/i prima della lezione.', (int) ($hours / 24))
                    : sprintf('Puoi annullare fino a %d ora/e prima della lezione.', (int) $hours);
            }
            $cancelPolicyHtml = sprintf('<p style="margin:0 0 20px;font-size:14px;color:#666;">%s</p>', htmlspecialchars($policyText, ENT_QUOTES, 'UTF-8'));
            $cancelPolicyText = $policyText . "\n";
        }

        $locationAddress = trim((string) ($data['location_address'] ?? ''));
        $locationCity    = trim((string) ($data['location_city'] ?? ''));
        $locationAddressLine = implode(', ', array_filter([$locationAddress, $locationCity]));

        return [
            'client_name'        => '',  // filled in by job worker from recipient_name
            'business_name'      => (string) ($data['business_name'] ?? ''),
            'business_email'     => (string) ($data['business_email'] ?? ''),
            'location_name'      => (string) ($data['location_name'] ?? ''),
            'location_address'   => $locationAddress,
            'location_city'      => $locationCity,
            'location_address_line' => $locationAddressLine,
            'location_phone'     => (string) ($data['location_phone'] ?? ''),
            'class_type_name'    => (string) ($data['class_type_name'] ?? ''),
            'date'               => EmailTemplateRenderer::formatLongDate($startsLocal, $locale),
            'time'               => $startsLocal->format('H:i'),
            'end_time'           => $endTime,
            'waitlist_position'  => isset($data['waitlist_position']) ? (string) (int) $data['waitlist_position'] : '',
            'price_row_html'     => $priceRowHtml,
            'price_row_text'     => $priceRowText,
            'location_block_html'=> $locationBlockHtml,
            'location_block_text'=> $locationBlockText,
            'cancel_policy_html' => $cancelPolicyHtml,
            'cancel_policy_text' => $cancelPolicyText,
            'locale'             => $locale,
            'sender_name'        => (string) ($data['business_name'] ?? ''),
            'sender_email'       => (string) ($data['business_email'] ?? ''),
        ];
    }

    private function resolveTemplate(string $channel, string $locale): array
    {
        return match ($channel) {
            'class_booking_confirmed'  => EmailTemplateRenderer::classBookingConfirmed($locale),
            'class_booking_waitlisted' => EmailTemplateRenderer::classBookingWaitlisted($locale),
            'class_booking_promoted'   => EmailTemplateRenderer::classBookingPromoted($locale),
            'class_booking_cancelled'  => EmailTemplateRenderer::classBookingCancelled($locale),
            'class_booking_updated'    => EmailTemplateRenderer::classBookingUpdated($locale),
            'class_booking_reminder'   => EmailTemplateRenderer::classBookingReminder($locale),
            default => throw new \InvalidArgumentException("Unknown class booking channel: {$channel}"),
        };
    }

    private function settingKeyForChannel(string $channel): ?string
    {
        return match ($channel) {
            'class_booking_confirmed'  => 'email_class_booking_confirmed',
            'class_booking_waitlisted' => 'email_class_booking_waitlisted',
            'class_booking_promoted'   => 'email_class_booking_promoted',
            'class_booking_cancelled'  => 'email_class_booking_cancelled',
            'class_booking_updated'    => 'email_class_booking_confirmed',
            'class_booking_reminder'   => 'email_class_booking_reminder',
            default => null,
        };
    }

    private function hasMultipleLocations(int $businessId): bool
    {
        if ($businessId <= 0) {
            return false;
        }
        $stmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM locations WHERE business_id = ? AND is_active = 1'
        );
        $stmt->execute([$businessId]);
        return (int) $stmt->fetchColumn() > 1;
    }

    private function extractFirstName(?string $fullName): string
    {
        $name = trim((string) $fullName);
        if ($name === '') {
            return '';
        }
        $parts = preg_split('/\s+/', $name);
        return $parts[0] ?? $name;
    }
}
