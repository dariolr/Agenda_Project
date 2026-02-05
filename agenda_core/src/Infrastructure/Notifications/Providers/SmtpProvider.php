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
        ?array $attachments = null,
        ?string $fromEmail = null,
        ?string $fromName = null,
        ?string $replyTo = null,
    ): bool {
        $from = $fromEmail ?? $this->defaultFromEmail;
        $name = $fromName ?? $this->defaultFromName;
        $replyTo = $replyTo ?? $from;

        // Use PHP's mail() for simple SMTP or PHPMailer if available
        if (class_exists('PHPMailer\\PHPMailer\\PHPMailer')) {
            return $this->sendWithPhpMailer($to, $subject, $htmlBody, $textBody, $attachments, $from, $name, $replyTo);
        }

        // Build email headers
        $hasAttachments = !empty($attachments);
        $boundaryMixed = md5(uniqid('mixed', true));
        $boundaryAlt = md5(uniqid('alt', true));

        $headers = [
            'MIME-Version: 1.0',
            "From: {$name} <{$from}>",
            "Reply-To: {$replyTo}",
            'X-Mailer: AgendaCore/1.0',
        ];

        if ($hasAttachments) {
            $headers[] = 'Content-Type: multipart/mixed; boundary="' . $boundaryMixed . '"';
        } else {
            $headers[] = 'Content-Type: multipart/alternative; boundary="' . $boundaryAlt . '"';
        }

        // Build multipart body
        if ($hasAttachments) {
            $body = "--{$boundaryMixed}\r\n";
            $body .= "Content-Type: multipart/alternative; boundary=\"{$boundaryAlt}\"\r\n\r\n";
        } else {
            $body = '';
        }

        $body .= "--{$boundaryAlt}\r\n";
        $body .= "Content-Type: text/plain; charset=UTF-8\r\n";
        $body .= "Content-Transfer-Encoding: 8bit\r\n\r\n";
        $body .= ($textBody ?? strip_tags($htmlBody)) . "\r\n\r\n";

        $body .= "--{$boundaryAlt}\r\n";
        $body .= "Content-Type: text/html; charset=UTF-8\r\n";
        $body .= "Content-Transfer-Encoding: 8bit\r\n\r\n";
        $body .= $htmlBody . "\r\n\r\n";
        $body .= "--{$boundaryAlt}--\r\n";

        if ($hasAttachments) {
            foreach ($attachments as $attachment) {
                $filename = $attachment['filename'] ?? 'attachment';
                $contentType = $attachment['content_type'] ?? 'application/octet-stream';
                $encoding = $attachment['encoding'] ?? 'base64';
                $content = $attachment['content'] ?? '';

                if ($encoding !== 'base64') {
                    $content = base64_encode((string) $content);
                    $encoding = 'base64';
                }

                $body .= "--{$boundaryMixed}\r\n";
                $body .= "Content-Type: {$contentType}; name=\"{$filename}\"\r\n";
                $body .= "Content-Transfer-Encoding: {$encoding}\r\n";
                $body .= "Content-Disposition: attachment; filename=\"{$filename}\"\r\n\r\n";
                $body .= chunk_split((string) $content) . "\r\n";
            }
            $body .= "--{$boundaryMixed}--";
        }

        // Fallback to native mail() - requires proper server config
        return @mail($to, $subject, $body, implode("\r\n", $headers));
    }

    private function sendWithPhpMailer(
        string $to,
        string $subject,
        string $htmlBody,
        ?string $textBody,
        ?array $attachments,
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

            if (!empty($attachments)) {
                foreach ($attachments as $attachment) {
                    $filename = $attachment['filename'] ?? 'attachment';
                    $contentType = $attachment['content_type'] ?? 'application/octet-stream';
                    $encoding = $attachment['encoding'] ?? 'base64';
                    $content = $attachment['content'] ?? '';

                    if ($encoding === 'base64') {
                        $content = base64_decode((string) $content);
                        $phpMailerEncoding = 'base64';
                    } else {
                        $phpMailerEncoding = '8bit';
                    }

                    $mail->addStringAttachment((string) $content, $filename, $phpMailerEncoding, $contentType);
                }
            }

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
                $message['attachments'] ?? null,
            );
        }
        return $results;
    }

    public function getName(): string
    {
        return 'smtp';
    }
}
