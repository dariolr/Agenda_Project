<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

use DateTimeImmutable;

/**
 * Email template renderer.
 * Supports placeholders like {{client_name}}, {{date}}, etc.
 */
final class EmailTemplateRenderer
{
    /**
     * Render a template with variables.
     *
     * @param string $template Template string with {{placeholders}}
     * @param array<string, string|int|float> $variables Variables to replace
     * @return string Rendered template
     */
    public static function render(string $template, array $variables): string
    {
        foreach ($variables as $key => $value) {
            $template = str_replace('{{' . $key . '}}', (string) $value, $template);
        }
        return $template;
    }

    public static function normalizeLocale(?string $locale): string
    {
        $normalized = strtolower(trim((string) $locale));
        if ($normalized === '') {
            return 'it';
        }

        $normalized = str_replace('_', '-', $normalized);
        $primary = explode('-', $normalized)[0] ?? 'it';

        return in_array($primary, ['it', 'en'], true) ? $primary : 'it';
    }

    /**
     * @return array<string, string>
     */
    public static function strings(string $locale): array
    {
        $locale = self::normalizeLocale($locale);
        $strings = [
            'it' => [
                'where_label' => 'Dove',
                'at_label' => 'alle',
                'client_fallback' => 'Cliente',
            ],
            'en' => [
                'where_label' => 'Where',
                'at_label' => 'at',
                'client_fallback' => 'Customer',
            ],
        ];

        return $strings[$locale];
    }

    public static function formatLongDate(DateTimeImmutable $date, ?string $locale): string
    {
        $locale = self::normalizeLocale($locale);
        $weekdays = [
            'it' => ['lunedì', 'martedì', 'mercoledì', 'giovedì', 'venerdì', 'sabato', 'domenica'],
            'en' => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        ];
        $months = [
            'it' => [
                'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
                'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
            ],
            'en' => [
                'January', 'February', 'March', 'April', 'May', 'June',
                'July', 'August', 'September', 'October', 'November', 'December',
            ],
        ];

        $weekdayIndex = (int) $date->format('N') - 1;
        $monthIndex = (int) $date->format('n') - 1;

        $weekday = $weekdays[$locale][$weekdayIndex] ?? $date->format('l');
        $month = $months[$locale][$monthIndex] ?? $date->format('F');
        $day = (int) $date->format('j');
        $year = (int) $date->format('Y');

        return sprintf('%s %d %s %d', $weekday, $day, $month, $year);
    }

    public static function formatLongDateTime(DateTimeImmutable $dateTime, ?string $locale): string
    {
        $strings = self::strings(self::normalizeLocale($locale));
        $date = self::formatLongDate($dateTime, $locale);
        $time = $dateTime->format('H:i');

        return sprintf('%s %s %s', $date, $strings['at_label'], $time);
    }

    /**
     * Get default booking confirmation template.
     */
    public static function bookingConfirmed(string $locale = 'it'): array
    {
        $locale = self::normalizeLocale($locale);

        $templates = [
            'it' => [
                'subject' => 'Prenotazione confermata - {{business_name}}',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Prenotazione Confermata</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">
                    ✓ Prenotazione Confermata
                </h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Ciao <strong>{{client_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    La tua prenotazione presso <strong>{{business_name}}</strong> è stata confermata.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f9fa;border-radius:8px;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                {{location_block_html}}
                                <tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;font-size:13px;">Quando</span><br>
                                        <strong style="color:#333;">{{date}} alle {{time}}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;font-size:13px;">Cosa</span><br>
                                        <strong style="color:#333;">{{services}}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:8px 0;">
                                        <span style="color:#666;font-size:13px;">Totale</span><br>
                                        <strong style="color:#333;">€{{total_price}}</strong>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:0 0 20px;font-size:14px;color:#666;">
                    Puoi modificare o cancellare la prenotazione fino a <strong>{{cancel_deadline}}</strong>.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{manage_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Gestisci Prenotazione
                            </a>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    Il team di {{business_name}}<br>
                    {{location_address}}, {{location_city}}<br>
                    {{location_phone}}
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
PRENOTAZIONE CONFERMATA

Ciao {{client_name}},

La tua prenotazione presso {{business_name}} è stata confermata.

{{location_block_text}}
• Quando: {{date}} alle {{time}}
• Cosa: {{services}}
• Totale: €{{total_price}}

Puoi modificare o cancellare fino a {{cancel_deadline}}.

Gestisci prenotazione: {{manage_url}}

---
Il team di {{business_name}}
{{location_address}}, {{location_city}}
{{location_phone}}
TEXT,
            ],
            'en' => [
                'subject' => 'Booking confirmed - {{business_name}}',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Confirmed</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">
                    ✓ Booking Confirmed
                </h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Hi <strong>{{client_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Your booking at <strong>{{business_name}}</strong> has been confirmed.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f9fa;border-radius:8px;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                {{location_block_html}}
                                <tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;font-size:13px;">When</span><br>
                                        <strong style="color:#333;">{{date}} at {{time}}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;font-size:13px;">What</span><br>
                                        <strong style="color:#333;">{{services}}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:8px 0;">
                                        <span style="color:#666;font-size:13px;">Total</span><br>
                                        <strong style="color:#333;">€{{total_price}}</strong>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:0 0 20px;font-size:14px;color:#666;">
                    You can change or cancel your booking until <strong>{{cancel_deadline}}</strong>.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{manage_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Manage Booking
                            </a>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    The {{business_name}} Team<br>
                    {{location_address}}, {{location_city}}<br>
                    {{location_phone}}
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
BOOKING CONFIRMED

Hi {{client_name}},

Your booking at {{business_name}} has been confirmed.

{{location_block_text}}
• When: {{date}} at {{time}}
• What: {{services}}
• Total: €{{total_price}}

You can change or cancel your booking until {{cancel_deadline}}.

Manage booking: {{manage_url}}

---
The {{business_name}} Team
{{location_address}}, {{location_city}}
{{location_phone}}
TEXT,
            ],
        ];

        return $templates[$locale];
    }

    /**
     * Get default booking cancelled template.
     */
    public static function bookingCancelled(string $locale = 'it'): array
    {
        $locale = self::normalizeLocale($locale);

        $templates = [
            'it' => [
                'subject' => 'Prenotazione cancellata - {{business_name}}',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Prenotazione Cancellata</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">
                    ✗ Prenotazione Cancellata
                </h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Ciao <strong>{{client_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    La tua prenotazione presso <strong>{{business_name}}</strong> è stata cancellata.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f9fa;border-radius:8px;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                {{location_block_html}}
                                <tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;font-size:13px;">Quando</span><br>
                                        <strong style="color:#333;">{{date}} alle {{time}}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:8px 0;">
                                        <span style="color:#666;font-size:13px;">Cosa</span><br>
                                        <strong style="color:#333;">{{services}}</strong>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Se desideri prenotare nuovamente, visita il nostro sito.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{booking_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Prenota di Nuovo
                            </a>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    Il team di {{business_name}}<br>
                    {{location_address}}, {{location_city}}
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
PRENOTAZIONE CANCELLATA

Ciao {{client_name}},

La tua prenotazione presso {{business_name}} è stata cancellata.

{{location_block_text}}• Quando: {{date}} alle {{time}}
• Cosa: {{services}}

Se desideri prenotare nuovamente: {{booking_url}}

---
Il team di {{business_name}}
{{location_address}}, {{location_city}}
TEXT,
            ],
            'en' => [
                'subject' => 'Booking cancelled - {{business_name}}',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Cancelled</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">
                    ✗ Booking Cancelled
                </h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Hi <strong>{{client_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Your booking at <strong>{{business_name}}</strong> has been cancelled.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f9fa;border-radius:8px;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                {{location_block_html}}
                                <tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;font-size:13px;">When</span><br>
                                        <strong style="color:#333;">{{date}} at {{time}}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:8px 0;">
                                        <span style="color:#666;font-size:13px;">What</span><br>
                                        <strong style="color:#333;">{{services}}</strong>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    If you would like to book again, visit our website.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{booking_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Book Again
                            </a>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    The {{business_name}} Team<br>
                    {{location_address}}, {{location_city}}
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
BOOKING CANCELLED

Hi {{client_name}},

Your booking at {{business_name}} has been cancelled.

{{location_block_text}}• When: {{date}} at {{time}}
• What: {{services}}

If you would like to book again: {{booking_url}}

---
The {{business_name}} Team
{{location_address}}, {{location_city}}
TEXT,
            ],
        ];

        return $templates[$locale];
    }

    /**
     * Get default reminder template (24h before).
     */
    public static function bookingReminder(string $locale = 'it'): array
    {
        $locale = self::normalizeLocale($locale);

        $templates = [
            'it' => [
                'subject' => 'Promemoria: domani hai un appuntamento - {{business_name}}',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Promemoria Appuntamento</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">
                    Promemoria Appuntamento
                </h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Ciao <strong>{{client_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Ti ricordiamo che hai un appuntamento <strong>domani</strong> presso <strong>{{business_name}}</strong>.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f9fa;border-radius:8px;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                {{location_block_html}}
                                <tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;font-size:13px;">Quando</span><br>
                                        <strong style="color:#333;">{{date}} alle {{time}}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:8px 0;">
                                        <span style="color:#666;font-size:13px;">Cosa</span><br>
                                        <strong style="color:#333;">{{services}}</strong>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:0 0 20px;font-size:14px;color:#666;">
                    Se non puoi presentarti, ti preghiamo di cancellare la prenotazione.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{manage_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Gestisci Prenotazione
                            </a>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    Il team di {{business_name}} | {{location_phone}}
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
PROMEMORIA APPUNTAMENTO

Ciao {{client_name}},

Ti ricordiamo che hai un appuntamento DOMANI presso {{business_name}}.

{{location_block_text}}• Quando: {{date}} alle {{time}}
• Cosa: {{services}}

Se non puoi presentarti, cancella la prenotazione: {{manage_url}}

---
Il team di {{business_name}} | {{location_phone}}
TEXT,
            ],
            'en' => [
                'subject' => 'Reminder: you have an appointment tomorrow - {{business_name}}',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Appointment Reminder</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">
                    Appointment Reminder
                </h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Hi <strong>{{client_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    This is a reminder that you have an appointment <strong>tomorrow</strong> at <strong>{{business_name}}</strong>.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f9fa;border-radius:8px;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                {{location_block_html}}
                                <tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;font-size:13px;">When</span><br>
                                        <strong style="color:#333;">{{date}} at {{time}}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:8px 0;">
                                        <span style="color:#666;font-size:13px;">What</span><br>
                                        <strong style="color:#333;">{{services}}</strong>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:0 0 20px;font-size:14px;color:#666;">
                    If you cannot make it, please cancel your booking.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{manage_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Manage Booking
                            </a>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    The {{business_name}} Team | {{location_phone}}
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
APPOINTMENT REMINDER

Hi {{client_name}},

This is a reminder that you have an appointment TOMORROW at {{business_name}}.

{{location_block_text}}• When: {{date}} at {{time}}
• What: {{services}}

If you cannot make it, cancel your booking: {{manage_url}}

---
The {{business_name}} Team | {{location_phone}}
TEXT,
            ],
        ];

        return $templates[$locale];
    }

    /**
     * Get default booking rescheduled template.
     */
    public static function bookingRescheduled(string $locale = 'it'): array
    {
        $locale = self::normalizeLocale($locale);

        $templates = [
            'it' => [
                'subject' => 'Prenotazione modificata - {{business_name}}',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Prenotazione Modificata</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">
                    Prenotazione Modificata
                </h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Ciao <strong>{{client_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    La tua prenotazione presso <strong>{{business_name}}</strong> è stata modificata.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:25px;">
                    <tr>
                        <td style="padding:15px;background-color:#ffebee;border-radius:8px 8px 0 0;">
                            <span style="color:#c62828;font-weight:bold;">Vecchia data</span><br>
                            <span style="color:#666;text-decoration:line-through;">{{old_date}} alle {{old_time}}</span>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:15px;background-color:#e8f5e9;border-radius:0 0 8px 8px;">
                            <span style="color:#2e7d32;font-weight:bold;">Nuova data</span><br>
                            <strong style="color:#333;">{{date}} alle {{time}}</strong>
                        </td>
                    </tr>
                </table>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f9fa;border-radius:8px;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <p style="margin:0;color:#666;">
                                {{location_block_html}}
                                <span style="color:#666;font-size:13px;">Cosa</span><br>
                                <strong style="color:#333;">{{services}}</strong>
                            </p>
                        </td>
                    </tr>
                </table>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{manage_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Vedi Dettagli
                            </a>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    Il team di {{business_name}}
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
PRENOTAZIONE MODIFICATA

Ciao {{client_name}},

La tua prenotazione presso {{business_name}} è stata modificata.

• Vecchia data: {{old_date}} alle {{old_time}}
• Nuova data: {{date}} alle {{time}}

{{location_block_text}}• Cosa: {{services}}

Vedi dettagli: {{manage_url}}

---
Il team di {{business_name}}
TEXT,
            ],
            'en' => [
                'subject' => 'Booking rescheduled - {{business_name}}',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Rescheduled</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">
                    Booking Rescheduled
                </h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Hi <strong>{{client_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Your booking at <strong>{{business_name}}</strong> has been rescheduled.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:25px;">
                    <tr>
                        <td style="padding:15px;background-color:#ffebee;border-radius:8px 8px 0 0;">
                            <span style="color:#c62828;font-weight:bold;">Previous date</span><br>
                            <span style="color:#666;text-decoration:line-through;">{{old_date}} at {{old_time}}</span>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:15px;background-color:#e8f5e9;border-radius:0 0 8px 8px;">
                            <span style="color:#2e7d32;font-weight:bold;">New date</span><br>
                            <strong style="color:#333;">{{date}} at {{time}}</strong>
                        </td>
                    </tr>
                </table>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f9fa;border-radius:8px;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <p style="margin:0;color:#666;">
                                {{location_block_html}}
                                <span style="color:#666;font-size:13px;">What</span><br>
                                <strong style="color:#333;">{{services}}</strong>
                            </p>
                        </td>
                    </tr>
                </table>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{manage_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                View Details
                            </a>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    The {{business_name}} Team
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
BOOKING RESCHEDULED

Hi {{client_name}},

Your booking at {{business_name}} has been rescheduled.

• Previous date: {{old_date}} at {{old_time}}
• New date: {{date}} at {{time}}

{{location_block_text}}• What: {{services}}

View details: {{manage_url}}

---
The {{business_name}} Team
TEXT,
            ],
        ];

        return $templates[$locale];
    }

    /**
     * Get business admin welcome template.
     * Sent when a superadmin creates a new business and assigns an admin.
     */
    public static function businessAdminWelcome(string $locale = 'it'): array
    {
        $locale = self::normalizeLocale($locale);

        $templates = [
            'it' => [
                'subject' => 'Benvenuto sul tuo nuovo gestionale - Configura il tuo account',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Benvenuto sul tuo nuovo gestionale</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">Benvenuto sul tuo nuovo gestionale</h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Ciao,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Sei stato assegnato come amministratore di <strong>{{business_name}}</strong> sulla piattaforma Agenda.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f9fa;border-radius:8px;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <p style="margin:0 0 15px;color:#333;"><strong>Il tuo business:</strong></p>
                            <p style="margin:0 0 8px;color:#666;">
                                <span style="color:#666;font-size:13px;">Nome</span><br>
                                <strong style="color:#333;">{{business_name}}</strong>
                            </p>
                            <!--
                            <p style="margin:0 0 8px;color:#666;">
                                <span style="color:#666;font-size:13px;">URL di prenotazione online per i propri clienti</span><br>
                                <a href="{{booking_url}}" style="color:#6366f1;font-weight:500;">{{booking_url}}</a>
                            </p>
                            <p style="margin:15px 0 0;font-size:14px;color:#666;">
                                Condividi questo link con i tuoi clienti per permettere loro di prenotare direttamente un appuntamento.
                            </p>
                            -->
                        </td>
                    </tr>
                </table>
                
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Per iniziare, clicca sul pulsante qui sotto per impostare la tua password:
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{reset_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Imposta Password
                            </a>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:25px 0 0;font-size:14px;color:#666;">
                    Questo link scade tra <strong>24 ore</strong>.
                </p>
                <p style="margin:10px 0 0;font-size:14px;color:#666;">
                    Se non hai richiesto questo account, ignora questa email.
                </p>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    Agenda Platform - Gestione prenotazioni semplice e veloce
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
BENVENUTO SUL TUO NUOVO GESTIONALE

Ciao,

Sei stato assegnato come amministratore di {{business_name}} sulla piattaforma Agenda.

Per iniziare, visita il seguente link per impostare la tua password:
{{reset_url}}

Questo link scade tra 24 ore.

Se non hai richiesto questo account, ignora questa email.

---
Agenda Platform - Gestione prenotazioni semplice e veloce
TEXT,
            ],
            'en' => [
                'subject' => 'Welcome to your new dashboard - Set up your account',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to your new dashboard</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">Welcome to your new dashboard</h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Hi,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    You have been assigned as administrator of <strong>{{business_name}}</strong> on the Agenda platform.
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f9fa;border-radius:8px;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <p style="margin:0 0 15px;color:#333;"><strong>Your business:</strong></p>
                            <p style="margin:0 0 8px;color:#666;">
                                <span style="color:#666;font-size:13px;">Name</span><br>
                                <strong style="color:#333;">{{business_name}}</strong>
                            </p>
                            <!--
                            <p style="margin:0 0 8px;color:#666;">
                                <span style="color:#666;font-size:13px;">Booking URL</span><br>
                                <a href="{{booking_url}}" style="color:#6366f1;font-weight:500;">{{booking_url}}</a>
                            </p>
                            <p style="margin:15px 0 0;font-size:14px;color:#666;">
                                Share this link with your clients so they can book directly.
                            </p>
                            -->
                        </td>
                    </tr>
                </table>
                
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    To get started, click the button below to set your password:
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{reset_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Set Password
                            </a>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:25px 0 0;font-size:14px;color:#666;">
                    This link expires in <strong>24 hours</strong>.
                </p>
                <p style="margin:10px 0 0;font-size:14px;color:#666;">
                    If you didn't request this account, ignore this email.
                </p>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    Agenda Platform - Simple and fast booking management
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
WELCOME TO YOUR NEW DASHBOARD

Hi,

You have been assigned as administrator of {{business_name}} on the Agenda platform.

To get started, use the link below to set your password:
{{reset_url}}

This link expires in 24 hours.

If you didn't request this account, ignore this email.

---
Agenda Platform - Simple and fast booking management
TEXT,
            ],
        ];

        return $templates[$locale];
    }

    /**
     * Get customer password reset template.
     * Sent when a customer requests a password reset from the booking frontend.
     */
    public static function customerPasswordReset(string $locale = 'it'): array
    {
        $locale = self::normalizeLocale($locale);

        $templates = [
            'it' => [
                'subject' => 'Reimposta la tua password - {{business_name}}',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reimposta Password</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">Reimposta Password</h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Ciao <strong>{{client_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Abbiamo ricevuto una richiesta di reimpostazione password per il tuo account su <strong>{{business_name}}</strong>.
                </p>
                
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Clicca sul pulsante qui sotto per reimpostare la tua password:
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{reset_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Reimposta Password
                            </a>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:25px 0 0;font-size:14px;color:#666;">
                    Questo link scade tra <strong>24 ore</strong>.
                </p>
                <p style="margin:10px 0 0;font-size:14px;color:#666;">
                    Se non hai richiesto la reimpostazione della password, puoi ignorare questa email. La tua password rimarrà invariata.
                </p>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    Il team di {{business_name}}
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
REIMPOSTA PASSWORD

Ciao {{client_name}},

Abbiamo ricevuto una richiesta di reimpostazione password per il tuo account su {{business_name}}.

Per reimpostare la tua password, visita il seguente link:
{{reset_url}}

Questo link scade tra 24 ore.

Se non hai richiesto la reimpostazione della password, puoi ignorare questa email.

---
Il team di {{business_name}}
TEXT,
            ],
            'en' => [
                'subject' => 'Reset your password - {{business_name}}',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">Reset Password</h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Hi <strong>{{client_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    We received a password reset request for your account at <strong>{{business_name}}</strong>.
                </p>
                
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Click the button below to reset your password:
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{reset_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Reset Password
                            </a>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:25px 0 0;font-size:14px;color:#666;">
                    This link expires in <strong>24 hours</strong>.
                </p>
                <p style="margin:10px 0 0;font-size:14px;color:#666;">
                    If you did not request a password reset, you can ignore this email. Your password will remain unchanged.
                </p>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    The {{business_name}} Team
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
RESET PASSWORD

Hi {{client_name}},

We received a password reset request for your account at {{business_name}}.

To reset your password, visit the link below:
{{reset_url}}

This link expires in 24 hours.

If you did not request a password reset, you can ignore this email.

---
The {{business_name}} Team
TEXT,
            ],
        ];

        return $templates[$locale];
    }

    /**
     * Get operator password reset template.
     * Sent when an operator requests a password reset from the gestionale.
     */
    public static function operatorPasswordReset(string $locale = 'it'): array
    {
        $locale = self::normalizeLocale($locale);

        $templates = [
            'it' => [
                'subject' => 'Reimposta la tua password - Gestionale Agenda',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reimposta Password</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">Reimposta Password</h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Ciao <strong>{{user_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Abbiamo ricevuto una richiesta di reimpostazione password per il tuo account sul <strong>Gestionale Agenda</strong>.
                </p>
                
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Clicca sul pulsante qui sotto per reimpostare la tua password:
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{reset_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Reimposta Password
                            </a>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:25px 0 0;font-size:14px;color:#666;">
                    Questo link scade tra <strong>1 ora</strong>.
                </p>
                <p style="margin:10px 0 0;font-size:14px;color:#666;">
                    Se non hai richiesto la reimpostazione della password, puoi ignorare questa email. La tua password rimarrà invariata.
                </p>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    Gestionale Agenda - RomeoLab
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
REIMPOSTA PASSWORD

Ciao {{user_name}},

Abbiamo ricevuto una richiesta di reimpostazione password per il tuo account sul Gestionale Agenda.

Per reimpostare la tua password, visita il seguente link:
{{reset_url}}

Questo link scade tra 1 ora.

Se non hai richiesto la reimpostazione della password, puoi ignorare questa email.

---
Gestionale Agenda - RomeoLab
TEXT,
            ],
            'en' => [
                'subject' => 'Reset your password - Agenda Management',
                'html' => <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password</title>
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background-color:#f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;">
        <tr>
            <td style="padding:40px 30px;text-align:center;background-color:#2196F3;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:600;">Reset Password</h1>
            </td>
        </tr>
        <tr>
            <td style="padding:30px;">
                <p style="margin:0 0 20px;font-size:16px;color:#333;">
                    Hi <strong>{{user_name}}</strong>,
                </p>
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    We received a password reset request for your account on <strong>Agenda Management</strong>.
                </p>
                
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Click the button below to reset your password:
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{reset_url}}" style="display:inline-block;padding:14px 30px;background-color:#2196F3;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Reset Password
                            </a>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:25px 0 0;font-size:14px;color:#666;">
                    This link expires in <strong>1 hour</strong>.
                </p>
                <p style="margin:10px 0 0;font-size:14px;color:#666;">
                    If you did not request a password reset, you can ignore this email. Your password will remain unchanged.
                </p>
            </td>
        </tr>
        <tr>
            <td style="padding:20px 30px;background-color:#f5f5f5;text-align:center;">
                <p style="margin:0;font-size:12px;color:#999;">
                    Agenda Management - RomeoLab
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
                'text' => <<<TEXT
RESET PASSWORD

Hi {{user_name}},

We received a password reset request for your account on Agenda Management.

To reset your password, visit the following link:
{{reset_url}}

This link expires in 1 hour.

If you did not request a password reset, you can ignore this email.

---
Agenda Management - RomeoLab
TEXT,
            ],
        ];

        return $templates[$locale];
    }
}
