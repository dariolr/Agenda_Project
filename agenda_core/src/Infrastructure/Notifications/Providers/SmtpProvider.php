<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Notifications\Providers;

use Agenda\Infrastructure\Notifications\EmailProviderInterface;

/**
 * Generic SMTP email provider.
 * Works with SiteGround, Gmail, or any standard SMTP server.
 */
final class SmtpProvider implements EmailProviderInterface
{
    private string $host;
    private int $port;
    private string $username;
    private string $password;
    private string $encryption;
    private string $defaultFromEmail;
    private string $defaultFromName;

    public function __construct(
        string $host,
        int $port,
        string $username,
        string $password,
        string $encryption = 'tls',
        string $defaultFromEmail = '',
        string $defaultFromName = 'Agenda',
    ) {
        $this->host = $host;
        $this->port = $port;
        $this->username = $username;
        $this->password = $password;
        $this->encryption = $encryption;
        $this->defaultFromEmail = $defaultFromEmail ?: $username;
        $this->defaultFromName = $defaultFromName;
    }

    public function send(
        string $to,
        string $subject,
        string $htmlBody,
        ?string $textBody = null,
        ?string $fromEmail = null,
        ?string $fromName = null,
        ?string $replyTo = null,
    ): bool {
        $from = $fromEmail ?? $this->defaultFromEmail;
        $name = $fromName ?? $this->defaultFromName;
        $replyTo = $replyTo ?? $from;

        // Build email headers
        $boundary = md5(uniqid((string) time()));
        
        $headers = [
            'MIME-Version: 1.0',
            "From: {$name} <{$from}>",
            "Reply-To: {$replyTo}",
            'Content-Type: multipart/alternative; boundary="' . $boundary . '"',
            'X-Mailer: AgendaCore/1.0',
        ];

        // Build multipart body
        $body = "--{$boundary}\r\n";
        $body .= "Content-Type: text/plain; charset=UTF-8\r\n";
        $body .= "Content-Transfer-Encoding: 8bit\r\n\r\n";
        $body .= ($textBody ?? strip_tags($htmlBody)) . "\r\n\r\n";
        
        $body .= "--{$boundary}\r\n";
        $body .= "Content-Type: text/html; charset=UTF-8\r\n";
        $body .= "Content-Transfer-Encoding: 8bit\r\n\r\n";
        $body .= $htmlBody . "\r\n\r\n";
        
        $body .= "--{$boundary}--";

        // Use PHP's mail() for simple SMTP or PHPMailer if available
        if (class_exists('PHPMailer\\PHPMailer\\PHPMailer')) {
            return $this->sendWithPhpMailer($to, $subject, $htmlBody, $textBody, $from, $name, $replyTo);
        }

        // Fallback to native mail() - requires proper server config
        return @mail($to, $subject, $body, implode("\r\n", $headers));
    }

    private function sendWithPhpMailer(
        string $to,
        string $subject,
        string $htmlBody,
        ?string $textBody,
        string $from,
        string $name,
        string $replyTo,
    ): bool {
        $mail = new \PHPMailer\PHPMailer\PHPMailer(true);

        try {
            // SMTP configuration
            $mail->isSMTP();
            $mail->Host = $this->host;
            $mail->SMTPAuth = true;
            $mail->Username = $this->username;
            $mail->Password = $this->password;
            $mail->SMTPSecure = $this->encryption === 'ssl' 
                ? \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS 
                : \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Port = $this->port;
            $mail->CharSet = 'UTF-8';

            // Recipients
            $mail->setFrom($from, $name);
            $mail->addAddress($to);
            $mail->addReplyTo($replyTo);

            // Content
            $mail->isHTML(true);
            $mail->Subject = $subject;
            $mail->Body = $htmlBody;
            $mail->AltBody = $textBody ?? strip_tags($htmlBody);

            $mail->send();
            return true;
        } catch (\Exception $e) {
            error_log("SMTP Error: " . $e->getMessage());
            return false;
        }
    }

    public function sendBatch(array $messages): array
    {
        $results = [];
        foreach ($messages as $message) {
            $results[$message['to']] = $this->send(
                $message['to'],
                $message['subject'],
                $message['htmlBody'],
                $message['textBody'] ?? null,
            );
        }
        return $results;
    }

    public function getName(): string
    {
        return 'smtp';
    }
}
