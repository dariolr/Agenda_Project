<?php

declare(strict_types=1);

namespace Agenda\UseCases\Whatsapp;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Repositories\BusinessWhatsappSettingsRepository;
use Agenda\Infrastructure\Repositories\WhatsappRepository;
use Agenda\Infrastructure\Support\Json;
use DateTimeImmutable;
use DateTimeZone;

final class QueueWhatsappNotification
{
    private const ENABLED_MESSAGE_TYPES = ['booking_reminder'];

    public function __construct(
        private readonly Connection $db,
        private readonly WhatsappRepository $whatsappRepo,
        private readonly BusinessWhatsappSettingsRepository $settingsRepo,
    ) {}

    public function execute(array $data, string $channel, ?string $scheduledAt = null): int
    {
        $businessId = (int) ($data['business_id'] ?? 0);
        $clientId = (int) ($data['client_id'] ?? $data['recipient_id'] ?? 0);
        if ($businessId <= 0 || $clientId <= 0) {
            return 0;
        }

        $settings = $this->settingsRepo->findByBusinessId($businessId);
        if (
            (int) ($settings['whatsapp_enabled'] ?? 0) !== 1
            || (int) ($settings['messages_enabled'] ?? 0) !== 1
            || (int) ($settings['business_messages_enabled'] ?? 1) !== 1
        ) {
            return 0;
        }

        $messageType = $this->messageTypeForChannel($channel);
        if ($messageType === null) {
            return 0;
        }
        if (!$this->isMessageTypeEnabled($messageType)) {
            return 0;
        }

        $client = $this->loadClient($businessId, $clientId);
        if ($client === null) {
            return 0;
        }

        $phone = $this->resolvePhone($businessId, $clientId, $client, $settings);
        if ($phone === null) {
            return 0;
        }

        $locationId = isset($data['location_id']) ? (int) $data['location_id'] : $this->resolveLocationId($data);
        $config = $locationId > 0
            ? $this->whatsappRepo->findConfigForLocation($businessId, $locationId)
            : $this->findDefaultConfig($businessId);
        if (
            $config === null
            || ($config['status'] ?? '') !== 'active'
            || trim((string) ($config['phone_number_id'] ?? '')) === ''
        ) {
            return 0;
        }

        $template = $this->findApprovedTemplate($businessId, $messageType, (string) ($data['locale'] ?? 'it'));
        if ($template === null) {
            return 0;
        }

        $bookingId = isset($data['booking_id']) ? (int) $data['booking_id'] : null;
        $classBookingId = isset($data['class_booking_id']) ? (int) $data['class_booking_id'] : null;
        $dedupeKey = $this->dedupeKey($businessId, $messageType, $bookingId, $classBookingId, $scheduledAt);

        return $this->whatsappRepo->createOutbox([
            'business_id' => $businessId,
            'booking_id' => $bookingId,
            'class_booking_id' => $classBookingId,
            'client_id' => $clientId,
            'location_id' => $locationId > 0 ? $locationId : null,
            'whatsapp_config_id' => (int) $config['id'],
            'recipient_phone' => $phone,
            'recipient_phone_e164' => $phone,
            'template_name' => (string) $template['template_name'],
            'template_language' => (string) ($template['language_code'] ?? $data['locale'] ?? 'it'),
            'template_payload' => $this->buildVariables($data, $client),
            'message_type' => $messageType,
            'scheduled_at' => $scheduledAt,
            'dedupe_key' => $dedupeKey,
            'max_attempts' => 3,
        ]);
    }

    public function queueFromNotificationRow(array $notification): int
    {
        $payload = [];
        if (isset($notification['payload']) && is_string($notification['payload'])) {
            $payload = Json::decodeAssoc($notification['payload']) ?? [];
        } elseif (isset($notification['payload']) && is_array($notification['payload'])) {
            $payload = $notification['payload'];
        }
        $variables = is_array($payload['variables'] ?? null) ? $payload['variables'] : [];

        return $this->execute([
            ...$variables,
            'business_id' => $notification['business_id'] ?? null,
            'booking_id' => $notification['booking_id'] ?? null,
            'class_booking_id' => $notification['class_booking_id'] ?? null,
            'client_id' => $notification['recipient_id'] ?? null,
            'location_id' => $variables['location_id'] ?? null,
            'locale' => $variables['locale'] ?? null,
        ], (string) ($notification['channel'] ?? ''), $notification['scheduled_at'] ?? null);
    }

    private function loadClient(int $businessId, int $clientId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, first_name, last_name, phone, created_at
             FROM clients
             WHERE id = ? AND business_id = ? AND is_archived = 0
             LIMIT 1'
        );
        $stmt->execute([$clientId, $businessId]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ?: null;
    }

    private function resolvePhone(int $businessId, int $clientId, array $client, array $settings): ?string
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT phone_e164, opt_in, opted_in, revoked_at
             FROM whatsapp_client_optins
             WHERE business_id = ?
               AND client_id = ?
             ORDER BY updated_at DESC, id DESC
             LIMIT 1'
        );
        $stmt->execute([$businessId, $clientId]);
        $optIn = $stmt->fetch(\PDO::FETCH_ASSOC) ?: null;

        if ($optIn !== null && $optIn['revoked_at'] !== null) {
            return null;
        }

        $hasExplicitOptIn = $optIn !== null
            && (((int) ($optIn['opted_in'] ?? 0)) === 1 || ((int) ($optIn['opt_in'] ?? 0)) === 1);
        $hasExplicitOptOut = $optIn !== null
            && !$hasExplicitOptIn
            && (((int) ($optIn['opted_in'] ?? 0)) === 0 || ((int) ($optIn['opt_in'] ?? 0)) === 0);

        if (!$hasExplicitOptIn) {
            if ($hasExplicitOptOut || !$this->allowsAssumedExistingClientOptIn($settings, $client)) {
                return null;
            }
        }

        $optInPhone = is_array($optIn) ? ($optIn['phone_e164'] ?? null) : null;
        $phone = is_string($optInPhone) && trim($optInPhone) !== ''
            ? trim($optInPhone)
            : $this->normalizePhone((string) ($client['phone'] ?? ''));

        return $this->isE164($phone) ? $phone : null;
    }

    private function allowsAssumedExistingClientOptIn(array $settings, array $client): bool
    {
        if (($settings['existing_clients_opt_in_policy'] ?? 'explicit_only') !== 'assume_existing_consented') {
            return false;
        }

        $assumedAt = trim((string) ($settings['existing_clients_opt_in_assumed_at'] ?? ''));
        $clientCreatedAt = trim((string) ($client['created_at'] ?? ''));
        if ($assumedAt === '' || $clientCreatedAt === '') {
            return false;
        }

        return strtotime($clientCreatedAt) <= strtotime($assumedAt);
    }

    private function normalizePhone(string $raw): string
    {
        $value = preg_replace('/[^\d+]/', '', trim($raw)) ?? '';
        if ($value === '') {
            return '';
        }
        if (str_starts_with($value, '+')) {
            return $value;
        }
        if (str_starts_with($value, '00')) {
            return '+' . substr($value, 2);
        }
        if (preg_match('/^3\d{8,10}$/', $value) === 1) {
            return '+39' . $value;
        }

        return $value;
    }

    private function isE164(string $phone): bool
    {
        return preg_match('/^\+[1-9]\d{7,14}$/', $phone) === 1;
    }

    private function findDefaultConfig(int $businessId): ?array
    {
        foreach ($this->whatsappRepo->getConfigsByBusinessId($businessId) as $config) {
            if ((int) ($config['is_default'] ?? 0) === 1) {
                return $config;
            }
        }

        return null;
    }

    private function findApprovedTemplate(int $businessId, string $messageType, string $locale): ?array
    {
        $language = str_starts_with(strtolower($locale), 'en') ? 'en' : 'it';
        $stmt = $this->db->getPdo()->prepare(
            'SELECT business_id, template_name, language_code
             FROM whatsapp_templates
             WHERE (business_id = ? OR business_id IS NULL)
               AND (message_type = ? OR template_name = ?)
               AND language_code IN (?, "it")
               AND status = "approved"
             ORDER BY business_id IS NULL ASC, language_code = ? DESC
             LIMIT 1'
        );
        $stmt->execute([$businessId, $messageType, $messageType, $language, $language]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        if ($row !== false) {
            return $row;
        }

        if ($messageType === 'booking_reminder') {
            return [
                'business_id' => null,
                'template_name' => $this->defaultReminderTemplateName(),
                'language_code' => $language,
            ];
        }

        return null;
    }

    private function defaultReminderTemplateName(): string
    {
        $name = trim((string) ($_ENV['WHATSAPP_REMINDER_TEMPLATE_NAME'] ?? getenv('WHATSAPP_REMINDER_TEMPLATE_NAME') ?? ''));

        return $name !== '' ? $name : 'promemoria_appuntamento_ita_24h';
    }

    private function messageTypeForChannel(string $channel): ?string
    {
        return match ($channel) {
            'booking_confirmed' => 'booking_confirmation',
            'booking_reminder' => 'booking_reminder',
            'booking_cancelled' => 'booking_cancellation',
            'booking_rescheduled' => 'booking_reschedule',
            'class_booking_confirmed', 'class_booking_promoted' => 'class_booking_confirmation',
            'class_booking_reminder' => 'class_booking_reminder',
            'class_booking_cancelled' => 'class_booking_cancellation',
            default => null,
        };
    }

    private function isMessageTypeEnabled(string $messageType): bool
    {
        return in_array($messageType, self::ENABLED_MESSAGE_TYPES, true);
    }

    private function resolveLocationId(array $data): int
    {
        if (isset($data['location_id']) && (int) $data['location_id'] > 0) {
            return (int) $data['location_id'];
        }
        $bookingId = (int) ($data['booking_id'] ?? 0);
        if ($bookingId > 0) {
            $stmt = $this->db->getPdo()->prepare('SELECT location_id FROM bookings WHERE id = ? LIMIT 1');
            $stmt->execute([$bookingId]);
            return (int) ($stmt->fetchColumn() ?: 0);
        }
        $classBookingId = (int) ($data['class_booking_id'] ?? 0);
        if ($classBookingId > 0) {
            $stmt = $this->db->getPdo()->prepare(
                'SELECT ce.location_id
                 FROM class_bookings cb
                 JOIN class_events ce ON ce.id = cb.class_event_id
                 WHERE cb.id = ?
                 LIMIT 1'
            );
            $stmt->execute([$classBookingId]);
            return (int) ($stmt->fetchColumn() ?: 0);
        }

        return 0;
    }

    private function buildVariables(array $data, array $client): array
    {
        $name = trim((string) ($data['client_name'] ?? ($client['first_name'] ?? '')));
        if ($name === '') {
            $name = trim((string) ($client['first_name'] ?? ''));
        }
        $date = (string) ($data['date'] ?? $data['new_date'] ?? '');
        $time = (string) ($data['time'] ?? $data['new_time'] ?? '');
        $startRaw = (string) ($data['new_start_time'] ?? $data['start_time'] ?? $data['starts_at'] ?? '');
        if (($date === '' || $time === '') && $startRaw !== '') {
            try {
                $timezone = new DateTimeZone((string) ($data['location_timezone'] ?? 'Europe/Rome'));
                $start = new DateTimeImmutable($startRaw, $timezone);
                $date = $date !== '' ? $date : $start->format('d/m/Y');
                $time = $time !== '' ? $time : $start->format('H:i');
            } catch (\Throwable) {
            }
        }

        return [
            'client_name' => $name,
            'business_name' => (string) ($data['business_name'] ?? ''),
            'location_name' => (string) ($data['location_name'] ?? ''),
            'location_address' => (string) ($data['location_address_line'] ?? $data['location_address'] ?? ''),
            'date' => $date,
            'time' => $time,
            'service' => (string) ($data['services'] ?? $data['class_type_name'] ?? ''),
            'staff' => (string) ($data['staff_name'] ?? ''),
            'link' => (string) ($data['manage_url'] ?? $data['booking_url'] ?? ''),
        ];
    }

    private function dedupeKey(int $businessId, string $messageType, ?int $bookingId, ?int $classBookingId, ?string $scheduledAt): string
    {
        $target = $bookingId !== null && $bookingId > 0
            ? 'booking:' . $bookingId
            : 'class_booking:' . (int) $classBookingId;
        $schedule = $scheduledAt !== null && $scheduledAt !== ''
            ? (new DateTimeImmutable($scheduledAt, new DateTimeZone('UTC')))->format('YmdHis')
            : 'now';

        return 'wa:' . $businessId . ':' . $target . ':' . $messageType . ':' . $schedule;
    }
}
