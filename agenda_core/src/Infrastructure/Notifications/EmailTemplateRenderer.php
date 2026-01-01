<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications;

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

    /**
     * Get default booking confirmation template.
     */
    public static function bookingConfirmed(): array
    {
        return [
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
                <h1 style="margin:0;color:#ffffff;font-size:24px;">✓ Prenotazione Confermata</h1>
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
                                <tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;">📍 Dove</span><br>
                                        <strong style="color:#333;">{{location_name}}</strong><br>
                                        <span style="color:#666;font-size:14px;">{{location_address}}</span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;">📅 Quando</span><br>
                                        <strong style="color:#333;">{{date}} alle {{time}}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:8px 0;border-bottom:1px solid #e0e0e0;">
                                        <span style="color:#666;">✂️ Servizi</span><br>
                                        <strong style="color:#333;">{{services}}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:8px 0;">
                                        <span style="color:#666;">💰 Totale</span><br>
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
                    {{business_name}}<br>
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
Prenotazione Confermata

Ciao {{client_name}},

La tua prenotazione presso {{business_name}} è stata confermata.

📍 Dove: {{location_name}}, {{location_address}}
📅 Quando: {{date}} alle {{time}}
✂️ Servizi: {{services}}
💰 Totale: €{{total_price}}

Puoi modificare o cancellare fino a {{cancel_deadline}}.

Gestisci prenotazione: {{manage_url}}

---
{{business_name}}
{{location_address}}, {{location_city}}
{{location_phone}}
TEXT,
        ];
    }

    /**
     * Get default booking cancelled template.
     */
    public static function bookingCancelled(): array
    {
        return [
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
            <td style="padding:40px 30px;text-align:center;background-color:#f44336;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;">✕ Prenotazione Cancellata</h1>
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
                            <p style="margin:0;color:#666;">
                                📅 <strong>{{date}} alle {{time}}</strong><br>
                                ✂️ {{services}}
                            </p>
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
                    {{business_name}}<br>
                    {{location_address}}, {{location_city}}
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
            'text' => <<<TEXT
Prenotazione Cancellata

Ciao {{client_name}},

La tua prenotazione presso {{business_name}} è stata cancellata.

📅 {{date}} alle {{time}}
✂️ {{services}}

Se desideri prenotare nuovamente: {{booking_url}}

---
{{business_name}}
{{location_address}}, {{location_city}}
TEXT,
        ];
    }

    /**
     * Get default reminder template (24h before).
     */
    public static function bookingReminder(): array
    {
        return [
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
            <td style="padding:40px 30px;text-align:center;background-color:#FF9800;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;">🔔 Promemoria Appuntamento</h1>
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
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#fff3e0;border-left:4px solid #FF9800;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <table width="100%" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td style="padding:5px 0;">
                                        <strong style="color:#333;">📅 {{date}} alle {{time}}</strong>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:5px 0;">
                                        <span style="color:#666;">📍 {{location_name}}</span><br>
                                        <span style="color:#666;font-size:14px;">{{location_address}}</span>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding:5px 0;">
                                        <span style="color:#666;">✂️ {{services}}</span>
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
                            <a href="{{manage_url}}" style="display:inline-block;padding:14px 30px;background-color:#FF9800;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
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
                    {{business_name}} | {{location_phone}}
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
            'text' => <<<TEXT
Promemoria Appuntamento

Ciao {{client_name}},

Ti ricordiamo che hai un appuntamento DOMANI presso {{business_name}}.

📅 {{date}} alle {{time}}
📍 {{location_name}}, {{location_address}}
✂️ {{services}}

Se non puoi presentarti, cancella la prenotazione: {{manage_url}}

---
{{business_name}} | {{location_phone}}
TEXT,
        ];
    }

    /**
     * Get default booking rescheduled template.
     */
    public static function bookingRescheduled(): array
    {
        return [
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
            <td style="padding:40px 30px;text-align:center;background-color:#4CAF50;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;">📅 Prenotazione Modificata</h1>
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
                            <span style="color:#c62828;font-weight:bold;">❌ Vecchia data</span><br>
                            <span style="color:#666;text-decoration:line-through;">{{old_date}} alle {{old_time}}</span>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:15px;background-color:#e8f5e9;border-radius:0 0 8px 8px;">
                            <span style="color:#2e7d32;font-weight:bold;">✓ Nuova data</span><br>
                            <strong style="color:#333;">{{date}} alle {{time}}</strong>
                        </td>
                    </tr>
                </table>
                
                <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8f9fa;border-radius:8px;margin-bottom:25px;">
                    <tr>
                        <td style="padding:20px;">
                            <p style="margin:0;color:#666;">
                                📍 {{location_name}}, {{location_address}}<br>
                                ✂️ {{services}}
                            </p>
                        </td>
                    </tr>
                </table>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{manage_url}}" style="display:inline-block;padding:14px 30px;background-color:#4CAF50;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
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
                    {{business_name}}
                </p>
            </td>
        </tr>
    </table>
</body>
</html>
HTML,
            'text' => <<<TEXT
Prenotazione Modificata

Ciao {{client_name}},

La tua prenotazione presso {{business_name}} è stata modificata.

❌ Vecchia data: {{old_date}} alle {{old_time}}
✓ Nuova data: {{date}} alle {{time}}

📍 {{location_name}}, {{location_address}}
✂️ {{services}}

Vedi dettagli: {{manage_url}}

---
{{business_name}}
TEXT,
        ];
    }

    /**
     * Get business admin welcome template.
     * Sent when a superadmin creates a new business and assigns an admin.
     */
    public static function businessAdminWelcome(): array
    {
        return [
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
            <td style="padding:40px 30px;text-align:center;background-color:#6366f1;">
                <h1 style="margin:0;color:#ffffff;font-size:24px;">🎉 Benvenuto sul tuo nuovo gestionale</h1>
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
                            <!-- TODO: Riattivare info business quando pronto
                            <p style="margin:0 0 10px;color:#333;"><strong>Il tuo business:</strong></p>
                            <p style="margin:0;color:#666;">
                                📌 Nome: {{business_name}}
                            </p>
                            <p style="margin:0;color:#666;">
                                🔗 URL prenotazioni: <a href="{{booking_url}}" style="color:#6366f1;">{{booking_url}}</a>
                            </p>
                            <p style="margin:15px 0 0;font-size:14px;color:#666;">
                                📅 Condividi questo link con i tuoi clienti per permettere loro di prenotare direttamente un appuntamento con la tua attività.
                            </p>
                            -->
                            <p style="margin:0;color:#666;">
                                Sei stato assegnato come amministratore del business <strong>{{business_name}}</strong>.
                            </p>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:0 0 25px;font-size:16px;color:#333;">
                    Per iniziare, clicca sul pulsante qui sotto per impostare la tua password:
                </p>
                
                <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                        <td style="text-align:center;">
                            <a href="{{reset_url}}" style="display:inline-block;padding:14px 30px;background-color:#6366f1;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">
                                Imposta Password
                            </a>
                        </td>
                    </tr>
                </table>
                
                <p style="margin:25px 0 0;font-size:14px;color:#666;">
                    ⏰ Questo link scade tra <strong>24 ore</strong>.
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
Benvenuto sul tuo nuovo gestionale

Ciao,

Sei stato assegnato come amministratore di {{business_name}} sulla piattaforma Agenda.

Per iniziare, visita il seguente link per impostare la tua password:
{{reset_url}}

⏰ Questo link scade tra 24 ore.

Se non hai richiesto questo account, ignora questa email.

---
Agenda Platform - Gestione prenotazioni semplice e veloce
TEXT,
        ];
    }
}
