<?php

declare(strict_types=1);

namespace Agenda\UseCases\Notifications;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Notifications\EmailTemplateRenderer;
use Agenda\Infrastructure\Notifications\CalendarICSGenerator;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Queue booking confirmation email.
 */
final class QueueBookingConfirmation
{
    public function __construct(
        private readonly Connection $db,
        private readonly NotificationRepository $notificationRepo,
    ) {}

    /**
     * Queue a booking confirmation email.
     * 
     * @param array $booking Booking data with all required fields
     *                       Supports both 'user_id' (operators) and 'client_id' (customers)
     */
    public function execute(array $booking): int
    {
        $locationTz = new DateTimeZone($booking['location_timezone'] ?? 'Europe/Rome');
        $now = new DateTimeImmutable('now', $locationTz);

        // For recurring bookings, keep only future occurrences.
        // If none are future, do not send confirmation.
        if ($this->isRecurringBooking($booking)) {
            $futureOccurrences = $this->filterFutureRecurringOccurrences(
                $booking['recurring_occurrences'] ?? null,
                $locationTz,
                $now
            );
            $futureCount = count($futureOccurrences);
            if ($futureCount === 0) {
                return 0;
            }

            $booking['recurring_occurrences'] = $futureOccurrences;
            $booking['start_time'] = (string) ($futureOccurrences[0]['start_time'] ?? $booking['start_time'] ?? '');
            if (!empty($futureOccurrences[0]['end_time'])) {
                $booking['end_time'] = (string) $futureOccurrences[0]['end_time'];
            }
            // Recurring template applies only when at least 2 future occurrences exist.
            if ($futureCount < 2) {
                $booking['is_recurring'] = false;
            }
        }

        // Don't send confirmation if appointment start time has already passed
        if (isset($booking['start_time']) && trim((string) $booking['start_time']) !== '') {
            $startTime = new DateTimeImmutable((string) $booking['start_time'], $locationTz);
            if ($startTime < $now) {
                return 0;
            }
        }

        // Check if already sent (deduplication)
        if ($this->notificationRepo->wasRecentlySent('booking_confirmed', (int) $booking['booking_id'])) {
            return 0;
        }

        // Check if notifications are enabled
        $settings = $this->notificationRepo->getSettings((int) $booking['business_id']);
        if (
            $settings
            && array_key_exists('email_booking_confirmed', $settings)
            && $settings['email_booking_confirmed'] !== null
            && (int) $settings['email_booking_confirmed'] === 0
        ) {
            return 0;
        }

        // Notifications go ONLY to clients, never to operators
        if (!isset($booking['client_id']) || empty($booking['client_id'])) {
            return 0; // No client = no notification
        }
        
        $recipientType = 'client';
        $recipientId = (int) $booking['client_id'];
        $recipientEmail = [
            'email' => $booking['client_email'] ?? null,
            'name' => $this->extractFirstName($booking['client_name'] ?? null),
        ];
        
        // Fallback: if email not provided, query clients table
        if (empty($recipientEmail['email'])) {
            $recipientEmail = $this->getClientEmail($recipientId);
        }
        
        if (!$recipientEmail || empty($recipientEmail['email'])) {
            return 0;
        }
        $recipientEmail['name'] = $this->extractFirstName($recipientEmail['name'] ?? null);

        $locale = $this->resolveLocale($booking);

        // Prepare template variables
        $calendar = $this->buildCalendarData($booking, $locale);
        $variables = $this->prepareVariables($booking, $locale);
        if (!isset($variables['client_name']) || trim((string) $variables['client_name']) === '') {
            $strings = EmailTemplateRenderer::strings($locale);
            $variables['client_name'] = $recipientEmail['name'] ?? $strings['client_fallback'];
        } else {
            $variables['client_name'] = $this->extractFirstName($variables['client_name']);
        }
        
        // Get template
        $template = $this->isRecurringBooking($booking)
            ? EmailTemplateRenderer::bookingConfirmedRecurring($locale)
            : EmailTemplateRenderer::bookingConfirmed($locale);
        
        $payload = [
            'template' => 'booking_confirmed',
            'variables' => $variables,
        ];
        if (!empty($calendar['attachments'])) {
            $payload['attachments'] = $calendar['attachments'];
        }

        // Queue notification
        return $this->notificationRepo->queue([
            'type' => 'email',
            'channel' => 'booking_confirmed',
            'recipient_type' => $recipientType,
            'recipient_id' => $recipientId,
            'recipient_email' => $recipientEmail['email'],
            'recipient_name' => $recipientEmail['name'],
            'subject' => EmailTemplateRenderer::render($template['subject'], $variables),
            'payload' => $payload,
            'priority' => 1, // High priority
            'business_id' => $booking['business_id'],
            'booking_id' => $booking['booking_id'],
        ]);
    }

    private function getClientEmail(int $clientId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT email, first_name as name 
             FROM clients WHERE id = :id'
        );
        $stmt->execute(['id' => $clientId]);
        return $stmt->fetch(\PDO::FETCH_ASSOC) ?: null;
    }

    private function prepareVariables(array $booking, string $locale): array
    {
        $locationTz = new DateTimeZone($booking['location_timezone'] ?? 'Europe/Rome');
        $startTime = new DateTimeImmutable($booking['start_time'], $locationTz);
        $cancelDeadline = isset($booking['cancellation_hours']) 
            ? $startTime->modify("-{$booking['cancellation_hours']} hours")
            : $startTime->modify('-24 hours');
        $locationName = $booking['location_name'] ?? '';
        $locationAddress = $booking['location_address'] ?? '';
        $strings = EmailTemplateRenderer::strings($locale);
        $hasMultipleLocations = $this->hasMultipleLocations((int) ($booking['business_id'] ?? 0));
        $locationBlockHtml = $hasMultipleLocations ? sprintf(
            '<tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;">📍 %s</span><br>
                                        <strong style="color:#333;">%s</strong><br>
                                        <span style="color:#666;font-size:14px;">%s</span>
                                    </td>
                                </tr>',
            $strings['where_label'],
            $locationName,
            $locationAddress
        ) : '';
        $locationBlockText = $hasMultipleLocations
            ? sprintf("📍 %s: %s, %s\n", $strings['where_label'], $locationName, $locationAddress)
            : '';
        [$recurringScheduleHtml, $recurringScheduleText] = $this->buildRecurringScheduleBlocks(
            $booking,
            $locale,
            $locationTz
        );
        [$recurringCancellationPolicyHtml, $recurringCancellationPolicyText] = $this->buildRecurringCancellationPolicy(
            $booking,
            $locale
        );

        return [
            'client_name' => $this->extractFirstName($booking['client_name'] ?? $strings['client_fallback']),
            'business_name' => $booking['business_name'] ?? '',
            'business_email' => $booking['business_email'] ?? '',
            'location_name' => $locationName,
            'location_email' => $booking['location_email'] ?? '',
            'sender_email' => $booking['sender_email'] ?? '',
            'sender_name' => $booking['sender_name'] ?? '',
            'location_address' => $locationAddress,
            'location_city' => $booking['location_city'] ?? '',
            'location_phone' => $booking['location_phone'] ?? '',
            'date' => EmailTemplateRenderer::formatLongDate($startTime, $locale),
            'time' => $startTime->format('H:i'),
            'services' => $booking['services'] ?? '',
            'total_price' => number_format((float) ($booking['total_price'] ?? 0), 2, ',', '.'),
            'cancel_deadline' => EmailTemplateRenderer::formatLongDateTime($cancelDeadline, $locale),
            'manage_url' => $booking['manage_url'] ?? '#',
            'booking_url' => $booking['booking_url'] ?? '#',
            'location_block_html' => $locationBlockHtml,
            'location_block_text' => $locationBlockText,
            'recurring_schedule_html' => $recurringScheduleHtml,
            'recurring_schedule_text' => $recurringScheduleText,
            'recurring_cancellation_policy_html' => $recurringCancellationPolicyHtml,
            'recurring_cancellation_policy_text' => $recurringCancellationPolicyText,
            'is_recurring_confirmation' => $this->isRecurringBooking($booking) ? '1' : '0',
        ];
    }

    /**
     * @return array{0:string,1:string}
     */
    private function buildRecurringScheduleBlocks(
        array $booking,
        string $locale,
        DateTimeZone $locationTz
    ): array {
        if (!$this->isRecurringBooking($booking)) {
            return ['', ''];
        }

        $occurrences = $booking['recurring_occurrences'] ?? null;
        if (!is_array($occurrences) || $occurrences === []) {
            return ['', ''];
        }

        $isEnglish = EmailTemplateRenderer::normalizeLocale($locale) === 'en';
        $title = $isEnglish ? 'Booked dates/times' : 'Date e orari prenotati';
        $occurrencesCount = count($occurrences);
        $recurrenceTypeLabel = $this->buildRecurrenceTypeLabel($booking, $locale);
        $recurrenceSummaryHtml = '';
        $recurrenceSummaryText = '';
        $sectionLabelHtml = $title;
        $sectionLabelText = $title;
        if ($occurrencesCount >= 2) {
            if ($isEnglish) {
                $recurrenceSummaryHtml = sprintf(
                    '<div style="margin:0;color:#333;"><strong>Recurrence:</strong> %s<br><strong>Appointments:</strong> %d<br><br><br><strong>%s:</strong></div>',
                    htmlspecialchars($recurrenceTypeLabel, ENT_QUOTES, 'UTF-8'),
                    $occurrencesCount,
                    $title
                );
                $recurrenceSummaryText = sprintf(
                    "Recurrence: %s\nAppointments: %d\n\n\n%s:\n",
                    $recurrenceTypeLabel,
                    $occurrencesCount,
                    $title
                );
            } else {
                $recurrenceSummaryHtml = sprintf(
                    '<div style="margin:0;color:#333;"><strong>Tipo di ricorrenza:</strong> %s<br><strong>Numero appuntamenti:</strong> %d<br><br><br><strong>%s:</strong></div>',
                    htmlspecialchars($recurrenceTypeLabel, ENT_QUOTES, 'UTF-8'),
                    $occurrencesCount,
                    $title
                );
                $recurrenceSummaryText = sprintf(
                    "Tipo di ricorrenza: %s\nNumero appuntamenti: %d\n\n\n%s:\n",
                    $recurrenceTypeLabel,
                    $occurrencesCount,
                    $title
                );
            }
            $sectionLabelHtml = '';
            $sectionLabelText = '';
        }

        $itemsHtml = [];
        $itemsText = [];

        foreach ($occurrences as $occurrence) {
            if (!is_array($occurrence) || empty($occurrence['start_time'])) {
                continue;
            }

            try {
                $start = new DateTimeImmutable((string) $occurrence['start_time'], $locationTz);
            } catch (\Throwable) {
                continue;
            }

            $dateLabel = EmailTemplateRenderer::formatLongDate($start, $locale);
            $timeLabel = $isEnglish
                ? sprintf('at %s', $start->format('H:i'))
                : sprintf('alle %s', $start->format('H:i'));
            $lineLabel = sprintf('%s - %s', $dateLabel, $timeLabel);
            $itemsHtml[] = sprintf(
                '<div style="margin:0;">
                    <div><strong>%s</strong></div>
                </div>',
                $lineLabel
            );
            $itemsText[] = sprintf("• %s", $lineLabel);
        }

        if ($itemsHtml === []) {
            return ['', ''];
        }

        $html = sprintf(
            '<tr>
                <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                    <span style="color:#666;font-size:13px;">%s</span><br>
                    <div style="margin:8px 0 0 0;color:#333;">
                        %s%s
                    </div>
                </td>
            </tr>',
            $sectionLabelHtml,
            $recurrenceSummaryHtml,
            implode('', $itemsHtml)
        );

        $text = ($sectionLabelText !== '' ? $sectionLabelText . ":\n" : '') . $recurrenceSummaryText . implode("\n", $itemsText) . "\n";

        return [$html, $text];
    }

    /**
     * @return array{0:string,1:string}
     */
    private function buildRecurringCancellationPolicy(array $booking, string $locale): array
    {
        if (!$this->isRecurringBooking($booking)) {
            return ['', ''];
        }

        $isEnglish = EmailTemplateRenderer::normalizeLocale($locale) === 'en';
        $hours = isset($booking['cancellation_hours'])
            ? max(0, (int) $booking['cancellation_hours'])
            : 24;

        $leadTimeLabel = $this->formatLeadTime($hours, $locale);
        $sentence = $isEnglish
            ? sprintf(
                'You can change or cancel each booking with at least %s before the appointment.',
                $leadTimeLabel
            )
            : sprintf(
                "Potrai modificare o cancellare ogni appuntamento con un anticipo di almeno %s prima dell'appuntamento",
                $leadTimeLabel
            );

        $html = sprintf(
            '<div style="margin:0 0 18px 0;color:#666;font-size:13px;">%s</div>',
            htmlspecialchars($sentence, ENT_QUOTES, 'UTF-8')
        );

        return [$html, $sentence];
    }

    private function formatLeadTime(int $hours, string $locale): string
    {
        $isEnglish = EmailTemplateRenderer::normalizeLocale($locale) === 'en';
        if ($hours > 0 && $hours % 24 === 0) {
            $days = (int) ($hours / 24);
            if ($isEnglish) {
                return $days === 1 ? '1 day' : "{$days} days";
            }

            return $days === 1 ? '1 giorno' : "{$days} giorni";
        }

        if ($isEnglish) {
            return $hours === 1 ? '1 hour' : "{$hours} hours";
        }

        return $hours === 1 ? '1 ora' : "{$hours} ore";
    }

    private function isRecurringBooking(array $booking): bool
    {
        $value = $booking['is_recurring'] ?? false;
        if (is_bool($value)) {
            return $value;
        }
        if (is_int($value)) {
            return $value === 1;
        }
        if (is_string($value)) {
            $normalized = strtolower(trim($value));
            return in_array($normalized, ['1', 'true', 'yes'], true);
        }

        return false;
    }

    /**
     * @param mixed $rawOccurrences
     * @return array<int, array<string, mixed>>
     */
    private function filterFutureRecurringOccurrences(
        mixed $rawOccurrences,
        DateTimeZone $locationTz,
        DateTimeImmutable $now
    ): array {
        $occurrences = $rawOccurrences;
        if (!is_array($occurrences) || $occurrences === []) {
            return [];
        }

        $future = [];
        foreach ($occurrences as $occurrence) {
            if (!is_array($occurrence) || empty($occurrence['start_time'])) {
                continue;
            }

            try {
                $start = new DateTimeImmutable((string) $occurrence['start_time'], $locationTz);
            } catch (\Throwable) {
                continue;
            }

            if ($start >= $now) {
                $future[] = $occurrence;
            }
        }

        return $future;
    }

    private function buildRecurrenceTypeLabel(array $booking, string $locale): string
    {
        $isEnglish = EmailTemplateRenderer::normalizeLocale($locale) === 'en';
        $frequency = strtolower(trim((string) ($booking['recurrence_frequency'] ?? 'weekly')));
        $interval = (int) ($booking['recurrence_interval_value'] ?? 1);
        if ($interval < 1) {
            $interval = 1;
        }

        return match ($frequency) {
            'daily' => $isEnglish
                ? ($interval === 1 ? 'Every day' : "Every {$interval} days")
                : ($interval === 1 ? 'Ogni giorno' : "Ogni {$interval} giorni"),
            'monthly' => $isEnglish
                ? ($interval === 1 ? 'Every month' : "Every {$interval} months")
                : ($interval === 1 ? 'Ogni mese' : "Ogni {$interval} mesi"),
            default => $isEnglish
                ? ($interval === 1 ? 'Every week' : "Every {$interval} weeks")
                : ($interval === 1 ? 'Ogni settimana' : "Ogni {$interval} settimane"),
        };
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

    private function resolveLocale(array $booking): string
    {
        return EmailTemplateRenderer::normalizeLocale(
            $booking['locale'] ?? $booking['business_locale'] ?? null
        );
    }

    /**
     * Build calendar HTML/text and ICS attachment (if end_time is available).
     *
     * @return array{html: string, text: string, attachments: array<int, array>|null}
     */
    private function buildCalendarData(array $booking, string $locale): array
    {
        if (empty($booking['end_time'])) {
            return ['attachments' => null];
        }

        $eventData = CalendarICSGenerator::prepareEventFromBooking(
            $booking,
            $booking['business_name'] ?? '',
            $locale
        );
        $icsContent = CalendarICSGenerator::generateIcsContent($eventData);
        return [
            'attachments' => [CalendarICSGenerator::createIcsAttachment($icsContent)],
        ];
    }
}
