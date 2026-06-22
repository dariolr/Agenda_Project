<?php

declare(strict_types=1);

namespace Agenda\UseCases\Whatsapp;

use Agenda\Infrastructure\Repositories\BusinessWhatsappSettingsRepository;
use Agenda\Infrastructure\Repositories\WhatsappRepository;
use Agenda\Infrastructure\Whatsapp\MetaWhatsAppTemplateClient;

final class SubmitDefaultWhatsAppTemplateAfterEmbeddedSignup
{
    private const MESSAGE_TYPE = 'booking_reminder';
    private const ACTIVE_META_STATUSES = ['submitted', 'pending', 'approved', 'paused'];

    public function __construct(
        private readonly WhatsappRepository $whatsappRepo,
        private readonly BusinessWhatsappSettingsRepository $settingsRepo,
        private readonly MetaWhatsAppTemplateClient $templateClient,
    ) {}

    /**
     * @return array<string,mixed>
     */
    public function execute(int $businessId, int $whatsappConfigId, string $wabaId): array
    {
        $languageCode = $this->normalizeLanguage($this->env('META_TEMPLATE_DEFAULT_LANGUAGE', 'it'));
        $category = strtolower($this->env('META_TEMPLATE_DEFAULT_CATEGORY', 'utility'));
        $templateName = $this->buildTemplateName($businessId, $languageCode);

        $existing = $this->whatsappRepo->findTemplateForAutoSubmit(
            $businessId,
            self::MESSAGE_TYPE,
            $languageCode,
            $templateName
        );
        if ($existing !== null && in_array((string) ($existing['status'] ?? ''), self::ACTIVE_META_STATUSES, true)) {
            return [
                'status' => 'skipped',
                'reason' => 'template_already_submitted',
                'template' => $existing,
            ];
        }

        $blueprint = $this->resolveBlueprint($businessId, $languageCode);
        $templateId = $this->whatsappRepo->upsertAutoTemplateDraft($businessId, [
            'id' => isset($existing['id']) ? (int) $existing['id'] : null,
            'template_name' => $templateName,
            'language_code' => $languageCode,
            'category' => $category,
            'message_type' => self::MESSAGE_TYPE,
            'body_preview' => $blueprint['body'],
            'variables_schema_json' => $blueprint['variables_schema'],
        ]);

        if (!$this->autoSubmitEnabled()) {
            return [
                'status' => 'skipped',
                'reason' => 'auto_submit_disabled',
                'template' => $this->whatsappRepo->findTemplateById($businessId, $templateId),
            ];
        }
        if ($wabaId === '') {
            return [
                'status' => 'skipped',
                'reason' => 'waba_id_missing',
                'template' => $this->whatsappRepo->findTemplateById($businessId, $templateId),
            ];
        }

        $settings = $this->settingsRepo->findByBusinessId($businessId);
        if (((int) ($settings['whatsapp_enabled'] ?? 0)) !== 1) {
            return [
                'status' => 'skipped',
                'reason' => 'whatsapp_not_enabled',
                'template' => $this->whatsappRepo->findTemplateById($businessId, $templateId),
            ];
        }

        $result = $this->templateClient->submitTemplate(
            $wabaId,
            $templateName,
            $languageCode,
            $category,
            $blueprint['body'],
            $blueprint['examples']
        );

        if ($result['success']) {
            $status = in_array((string) ($result['status'] ?? ''), self::ACTIVE_META_STATUSES, true)
                ? (string) $result['status']
                : 'submitted';
            $this->whatsappRepo->markTemplateMetaSubmitted(
                $templateId,
                $businessId,
                $status,
                $result['provider_template_id']
            );

            return [
                'status' => $status,
                'template' => $this->whatsappRepo->findTemplateById($businessId, $templateId),
            ];
        }

        if ($this->looksLikeDuplicateName($result['error_message'] ?? '', $result['error_code'] ?? '')) {
            $this->whatsappRepo->markTemplateMetaSubmitted($templateId, $businessId, 'pending', null);
            return [
                'status' => 'pending',
                'reason' => 'template_name_already_exists',
                'template' => $this->whatsappRepo->findTemplateById($businessId, $templateId),
            ];
        }

        $this->whatsappRepo->markTemplateMetaSubmissionFailed(
            $templateId,
            $businessId,
            $result['error_code'],
            $result['error_message']
        );

        return [
            'status' => 'error',
            'reason' => $result['error_code'] ?? 'meta_template_submission_failed',
            'error_message' => $result['error_message'] ?? null,
            'template' => $this->whatsappRepo->findTemplateById($businessId, $templateId),
        ];
    }

    /**
     * @return array{body:string,variables_schema:array<string,mixed>,examples:array<int,string>}
     */
    private function resolveBlueprint(int $businessId, string $languageCode): array
    {
        $template = $this->whatsappRepo->findTemplateBlueprint($businessId, self::MESSAGE_TYPE, $languageCode);
        $body = trim((string) ($template['body_preview'] ?? ''));
        if ($body === '') {
            $body = 'Ciao {{1}}, ti ricordiamo il tuo appuntamento presso {{2}} il {{3}} alle {{4}}.';
        }

        $variablesSchema = [
            'body' => [
                ['key' => 'client_name', 'example' => 'Mario Rossi'],
                ['key' => 'business_name', 'example' => 'Romeo Lab'],
                ['key' => 'date', 'example' => '24/06/2026'],
                ['key' => 'time', 'example' => '10:30'],
            ],
        ];

        return [
            'body' => $body,
            'variables_schema' => $variablesSchema,
            'examples' => $this->examplesForBody($body, $variablesSchema),
        ];
    }

    /**
     * @param array<string,mixed> $schema
     * @return array<int,string>
     */
    private function examplesForBody(string $body, array $schema): array
    {
        if (!preg_match_all('/\{\{(\d+)\}\}/', $body, $matches)) {
            return [];
        }
        $examples = [];
        $bodySchema = is_array($schema['body'] ?? null) ? $schema['body'] : [];
        foreach ($matches[1] as $rawIndex) {
            $index = (int) $rawIndex - 1;
            $row = is_array($bodySchema[$index] ?? null) ? $bodySchema[$index] : [];
            $examples[] = (string) ($row['example'] ?? ('Valore ' . $rawIndex));
        }

        return $examples;
    }

    private function buildTemplateName(int $businessId, string $languageCode): string
    {
        $language = preg_replace('/[^a-z0-9_]+/', '_', strtolower($languageCode)) ?: 'it';
        return 'agenda_booking_reminder_b' . $businessId . '_' . trim($language, '_');
    }

    private function normalizeLanguage(string $languageCode): string
    {
        $value = strtolower(trim($languageCode));
        if ($value === '') {
            return 'it';
        }
        return str_starts_with($value, 'en') ? 'en' : $value;
    }

    private function autoSubmitEnabled(): bool
    {
        return in_array(strtolower($this->env('META_TEMPLATE_AUTO_SUBMIT_ENABLED', 'false')), ['1', 'true', 'yes', 'on'], true);
    }

    private function looksLikeDuplicateName(?string $message, ?string $code): bool
    {
        $haystack = strtolower(trim((string) $code . ' ' . (string) $message));
        return str_contains($haystack, 'already exists') || str_contains($haystack, 'duplicate');
    }

    private function env(string $key, string $default): string
    {
        $value = $_ENV[$key] ?? getenv($key);
        return trim((string) ($value === false || $value === null || $value === '' ? $default : $value));
    }
}
