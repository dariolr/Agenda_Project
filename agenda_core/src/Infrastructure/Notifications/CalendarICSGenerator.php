<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

use DateTimeImmutable;
use DateTimeZone;

/**
 * Generate ICS content for email notifications.
 */
final class CalendarICSGenerator
{
    /**
     * Generate ICS content only (no external links).
     *
     * @param array{
     *   title: string,
     *   description: string,
     *   start_time: string,
     *   end_time: string,
     *   location: string,
     *   timezone?: string,
     *   booking_id?: int
     * } $event Event data
     */
    public static function generateIcsContent(array $event): string
    {
        $timezone = $event['timezone'] ?? 'Europe/Rome';
        $tz = new DateTimeZone($timezone);

        $startTime = new DateTimeImmutable($event['start_time'], $tz);
        $endTime = new DateTimeImmutable($event['end_time'], $tz);

        $title = $event['title'];
        $description = $event['description'];
        $location = $event['location'];
        $bookingId = $event['booking_id'] ?? 0;

        return self::generateIcs($title, $description, $location, $startTime, $endTime, $timezone, $bookingId);
    }

    /**
     * Generate ICS file content.
     */
    private static function generateIcs(
        string $title,
        string $description,
        string $location,
        DateTimeImmutable $startTime,
        DateTimeImmutable $endTime,
        string $timezone,
        int $bookingId
    ): string {
        $utcTz = new DateTimeZone('UTC');
        $now = (new DateTimeImmutable('now', $utcTz));

        $locationTz = new DateTimeZone($timezone);
        $startLocal = $startTime->setTimezone($locationTz);
        $endLocal = $endTime->setTimezone($locationTz);
        
        // Escape special characters for ICS format
        $title = self::escapeIcsText($title);
        $description = self::escapeIcsText($description);
        $location = self::escapeIcsText($location);
        
        // Generate unique ID
        $uid = sprintf('booking-%d-%s@romeolab.it', $bookingId, $startTime->format('Ymd'));
        
        $ics = [
            'BEGIN:VCALENDAR',
            'VERSION:2.0',
            'PRODID:-//RomeoLab Agenda//IT',
            'CALSCALE:GREGORIAN',
            'METHOD:PUBLISH',
            'BEGIN:VEVENT',
            'UID:' . $uid,
            'DTSTAMP:' . $now->format('Ymd\THis\Z'),
            'DTSTART:' . $startLocal->format('Ymd\THis'),
            'DTEND:' . $endLocal->format('Ymd\THis'),
            'SUMMARY:' . $title,
            'DESCRIPTION:' . $description,
            'LOCATION:' . $location,
            'STATUS:CONFIRMED',
            'SEQUENCE:0',
            'END:VEVENT',
            'END:VCALENDAR',
        ];
        
        return implode("\r\n", $ics);
    }

    /**
     * Escape text for ICS format.
     * ICS requires escaping backslashes, semicolons, commas, and newlines.
     */
    private static function escapeIcsText(string $text): string
    {
        // Replace newlines with \n literal
        $text = str_replace(["\r\n", "\r", "\n"], '\n', $text);
        // Escape backslashes, semicolons, and commas
        $text = str_replace(['\\', ';', ','], ['\\\\', '\;', '\,'], $text);
        
        return $text;
    }


    /**
     * Prepare event data from booking for calendar link generation.
     *
     * @param array $booking Booking data
     * @param string $businessName Business name
     * @param string $locale Language locale
     * @return array Event data ready for ICS generation
     */
    public static function prepareEventFromBooking(array $booking, string $businessName, string $locale = 'it'): array
    {
        $labels = [
            'it' => [
                'appointment_at' => 'Appuntamento presso',
                'services' => 'Servizi',
            ],
            'en' => [
                'appointment_at' => 'Appointment at',
                'services' => 'Services',
            ],
        ];
        $l = $labels[$locale] ?? $labels['it'];
        
        $title = "{$l['appointment_at']} {$businessName}";
        
        $description = "{$l['services']}: " . ($booking['services'] ?? '');
        
        $location = trim(($booking['location_name'] ?? '') . ', ' . ($booking['location_address'] ?? '') . ', ' . ($booking['location_city'] ?? ''), ', ');
        
        return [
            'title' => $title,
            'description' => $description,
            'start_time' => $booking['start_time'],
            'end_time' => $booking['end_time'],
            'location' => $location,
            'timezone' => $booking['location_timezone'] ?? 'Europe/Rome',
            'booking_id' => $booking['booking_id'] ?? 0,
        ];
    }

    /**
     * Create an email attachment array for an ICS file.
     *
     * @return array{filename: string, content: string, content_type: string, encoding: string}
     */
    public static function createIcsAttachment(string $icsContent, string $filename = 'appuntamento.ics'): array
    {
        return [
            'filename' => $filename,
            'content' => base64_encode($icsContent),
            'content_type' => 'text/calendar; charset=utf-8',
            'encoding' => 'base64',
        ];
    }
}
