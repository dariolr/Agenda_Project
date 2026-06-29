<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Domain\Exceptions\BookingException;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Support\Json;
use InvalidArgumentException;

final class BookingFormRepository
{
    public const FIELD_SHORT_TEXT = 'short_text';
    public const FIELD_LONG_TEXT = 'long_text';
    public const FIELD_SINGLE_CHOICE = 'single_choice';
    public const FIELD_SEGMENTED_CHOICE = 'segmented_choice';
    public const FIELD_MULTIPLE_CHOICE = 'multiple_choice';
    public const FIELD_CHECKBOX = 'checkbox';
    public const FIELD_CONSENT = 'consent';
    public const FIELD_INFO_TEXT = 'info_text';
    public const FIELD_NUMBER = 'number';
    public const FIELD_EMAIL = 'email';
    public const FIELD_PHONE = 'phone';
    public const FIELD_DATE = 'date';
    public const FIELD_DROPDOWN = 'dropdown';

    private const NON_REQUIRED_TYPES = [self::FIELD_INFO_TEXT];
    private const CHOICE_TYPES = [
        self::FIELD_SINGLE_CHOICE,
        self::FIELD_SEGMENTED_CHOICE,
        self::FIELD_MULTIPLE_CHOICE,
        self::FIELD_DROPDOWN,
    ];
    private const INPUT_TYPES = [
        self::FIELD_SHORT_TEXT,
        self::FIELD_LONG_TEXT,
        self::FIELD_SINGLE_CHOICE,
        self::FIELD_SEGMENTED_CHOICE,
        self::FIELD_MULTIPLE_CHOICE,
        self::FIELD_CHECKBOX,
        self::FIELD_CONSENT,
        self::FIELD_NUMBER,
        self::FIELD_EMAIL,
        self::FIELD_PHONE,
        self::FIELD_DATE,
        self::FIELD_DROPDOWN,
    ];

    private const FIELD_TYPES = [
        self::FIELD_SHORT_TEXT,
        self::FIELD_LONG_TEXT,
        self::FIELD_SINGLE_CHOICE,
        self::FIELD_SEGMENTED_CHOICE,
        self::FIELD_MULTIPLE_CHOICE,
        self::FIELD_CHECKBOX,
        self::FIELD_CONSENT,
        self::FIELD_INFO_TEXT,
        self::FIELD_NUMBER,
        self::FIELD_EMAIL,
        self::FIELD_PHONE,
        self::FIELD_DATE,
        self::FIELD_DROPDOWN,
    ];

    private const SCOPE_TYPES = [
        'business',
        'location',
        'service_variant',
        'service_package',
        'class_event',
        'class_type',
        'service_category',
    ];

    public function __construct(private readonly Connection $db) {}

    public function listForms(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            "SELECT bf.*,
                    (SELECT COUNT(*) FROM booking_form_fields bff WHERE bff.form_id = bf.id AND bff.is_active = 1) AS fields_count,
                    (SELECT COUNT(*) FROM booking_form_rules bfr WHERE bfr.form_id = bf.id AND bfr.is_active = 1) AS rules_count
             FROM booking_forms bf
             WHERE bf.business_id = ?
               AND bf.deleted_at IS NULL
             ORDER BY bf.sort_order ASC, bf.id ASC"
        );
        $stmt->execute([$businessId]);

        return array_map([$this, 'formatAdminFormSummary'], $stmt->fetchAll());
    }

    public function findForm(int $businessId, int $formId): ?array
    {
        $stmt = $this->db->getPdo()->prepare('SELECT * FROM booking_forms WHERE id = ? AND business_id = ? AND deleted_at IS NULL');
        $stmt->execute([$formId, $businessId]);
        $form = $stmt->fetch();
        if (!$form) {
            return null;
        }

        return $this->formatAdminForm($form);
    }

    public function createForm(int $businessId, array $data, ?int $userId): int
    {
        $title = trim((string) ($data['title'] ?? ''));
        if ($title === '') {
            throw new InvalidArgumentException('title_required');
        }

        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO booking_forms
                (business_id, title, description, internal_name, is_active, sort_order, created_by_user_id, updated_by_user_id)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $businessId,
            $title,
            $this->nullableTrim($data['description'] ?? null),
            $this->nullableTrim($data['internal_name'] ?? null),
            isset($data['is_active']) ? ((int) (bool) $data['is_active']) : 1,
            (int) ($data['sort_order'] ?? 0),
            $userId,
            $userId,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function updateForm(int $businessId, int $formId, array $data, ?int $userId): bool
    {
        $allowed = ['title', 'description', 'internal_name', 'is_active', 'sort_order'];
        $fields = [];
        $params = [];
        foreach ($allowed as $key) {
            if (!array_key_exists($key, $data)) {
                continue;
            }
            if ($key === 'title') {
                $value = trim((string) $data[$key]);
                if ($value === '') {
                    throw new InvalidArgumentException('title_required');
                }
            } elseif (in_array($key, ['description', 'internal_name'], true)) {
                $value = $this->nullableTrim($data[$key]);
            } elseif ($key === 'is_active') {
                $value = (int) (bool) $data[$key];
            } else {
                $value = (int) $data[$key];
            }
            $fields[] = "{$key} = ?";
            $params[] = $value;
        }

        if ($userId !== null) {
            $fields[] = 'updated_by_user_id = ?';
            $params[] = $userId;
        }

        if (empty($fields)) {
            return $this->findForm($businessId, $formId) !== null;
        }

        $params[] = $formId;
        $params[] = $businessId;
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE booking_forms SET ' . implode(', ', $fields) . ', updated_at = NOW() WHERE id = ? AND business_id = ? AND deleted_at IS NULL'
        );
        $stmt->execute($params);

        return $stmt->rowCount() > 0;
    }

    public function deleteForm(int $businessId, int $formId, ?int $userId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE booking_forms
             SET is_active = 0, deleted_at = NOW(), updated_by_user_id = ?, updated_at = NOW()
             WHERE id = ? AND business_id = ? AND deleted_at IS NULL'
        );
        $stmt->execute([$userId, $formId, $businessId]);

        return $stmt->rowCount() > 0;
    }

    public function addField(int $businessId, int $formId, array $data): int
    {
        $this->assertFormBelongsToBusiness($businessId, $formId);
        $normalized = $this->normalizeFieldData($data);
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO booking_form_fields
                (form_id, business_id, field_type, label, description, placeholder, help_text, is_required, sort_order, options_json, validation_json, is_active)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $formId,
            $businessId,
            $normalized['field_type'],
            $normalized['label'],
            $normalized['description'],
            $normalized['placeholder'],
            $normalized['help_text'],
            $normalized['is_required'],
            $normalized['sort_order'],
            $normalized['options_json'],
            $normalized['validation_json'],
            $normalized['is_active'],
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function updateField(int $businessId, int $formId, int $fieldId, array $data): bool
    {
        $this->assertFormBelongsToBusiness($businessId, $formId);
        $existing = $this->findField($businessId, $formId, $fieldId);
        if ($existing === null) {
            return false;
        }

        $normalized = $this->normalizeFieldData(array_merge($existing, $data), false);
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE booking_form_fields
             SET field_type = ?, label = ?, description = ?, placeholder = ?, help_text = ?,
                 is_required = ?, sort_order = ?, options_json = ?, validation_json = ?, is_active = ?, updated_at = NOW()
             WHERE id = ? AND form_id = ? AND business_id = ?'
        );
        $stmt->execute([
            $normalized['field_type'],
            $normalized['label'],
            $normalized['description'],
            $normalized['placeholder'],
            $normalized['help_text'],
            $normalized['is_required'],
            $normalized['sort_order'],
            $normalized['options_json'],
            $normalized['validation_json'],
            $normalized['is_active'],
            $fieldId,
            $formId,
            $businessId,
        ]);

        return true;
    }

    public function deactivateField(int $businessId, int $formId, int $fieldId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE booking_form_fields SET is_active = 0, updated_at = NOW() WHERE id = ? AND form_id = ? AND business_id = ?'
        );
        $stmt->execute([$fieldId, $formId, $businessId]);
        return $stmt->rowCount() > 0;
    }

    public function reorderForms(int $businessId, array $formIds): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE booking_forms SET sort_order = ?, updated_at = NOW() WHERE id = ? AND business_id = ? AND deleted_at IS NULL'
        );
        foreach (array_values($formIds) as $index => $formId) {
            $stmt->execute([$index, (int) $formId, $businessId]);
        }
    }

    public function reorderFields(int $businessId, int $formId, array $fieldIds): void
    {
        $this->assertFormBelongsToBusiness($businessId, $formId);
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE booking_form_fields SET sort_order = ?, updated_at = NOW() WHERE id = ? AND form_id = ? AND business_id = ?'
        );
        foreach (array_values($fieldIds) as $index => $fieldId) {
            $stmt->execute([$index, (int) $fieldId, $formId, $businessId]);
        }
    }

    /**
     * Sostituisce tutte le regole di visualizzazione di un modulo.
     * Ogni regola è un insieme di condizioni in AND; tra regole diverse vale OR.
     *
     * @param array<int,array{conditions?:array}> $rules
     */
    public function replaceRules(int $businessId, int $formId, array $rules): void
    {
        $this->assertFormBelongsToBusiness($businessId, $formId);

        // Valida e normalizza tutte le regole prima di toccare il DB.
        $normalizedRules = [];
        foreach ($rules as $rule) {
            if (!is_array($rule)) {
                throw new InvalidArgumentException('invalid_rule');
            }
            $conditions = $rule['conditions'] ?? [];
            if (!is_array($conditions)) {
                throw new InvalidArgumentException('invalid_rule');
            }
            $normalizedRules[] = $this->normalizeRuleConditions($businessId, $conditions);
        }

        $pdo = $this->db->getPdo();
        $pdo->beginTransaction();
        try {
            $deleteConditions = $pdo->prepare('DELETE FROM booking_form_rule_conditions WHERE form_id = ? AND business_id = ?');
            $deleteConditions->execute([$formId, $businessId]);
            $deleteRules = $pdo->prepare('DELETE FROM booking_form_rules WHERE form_id = ? AND business_id = ?');
            $deleteRules->execute([$formId, $businessId]);

            $insertRule = $pdo->prepare(
                'INSERT INTO booking_form_rules (form_id, business_id, is_active, sort_order) VALUES (?, ?, 1, ?)'
            );
            $insertCondition = $pdo->prepare(
                'INSERT INTO booking_form_rule_conditions (rule_id, form_id, business_id, scope_type, scope_id)
                 VALUES (?, ?, ?, ?, ?)'
            );
            foreach ($normalizedRules as $index => $conditions) {
                $insertRule->execute([$formId, $businessId, $index]);
                $ruleId = (int) $pdo->lastInsertId();
                foreach ($conditions as $condition) {
                    $insertCondition->execute([
                        $ruleId,
                        $formId,
                        $businessId,
                        $condition['scope_type'],
                        $condition['scope_id'],
                    ]);
                }
            }
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
    }

    /**
     * Valida e normalizza le condizioni di una singola regola.
     *
     * Combinazioni ammesse (AND dentro la regola):
     *   - solo business
     *   - solo location
     *   - solo service_category
     *   - solo tipo appuntamento (service_variant | service_package | class_event)
     *   - location + service_category
     *   - location + tipo appuntamento
     *
     * @return array<int,array{scope_type:string,scope_id:?int}>
     */
    private function normalizeRuleConditions(int $businessId, array $conditions): array
    {
        $counts = ['business' => 0, 'location' => 0, 'service_category' => 0, 'appointment' => 0];
        $normalized = [];
        $seen = [];
        foreach ($conditions as $condition) {
            if (!is_array($condition)) {
                throw new InvalidArgumentException('invalid_rule');
            }
            $scopeType = (string) ($condition['scope_type'] ?? '');
            $scopeId = array_key_exists('scope_id', $condition) && $condition['scope_id'] !== null
                ? (int) $condition['scope_id']
                : null;
            if (!$this->isValidCondition($businessId, $scopeType, $scopeId)) {
                throw new InvalidArgumentException('invalid_rule');
            }
            $key = $scopeType . ':' . ($scopeId ?? 'business');
            if (isset($seen[$key])) {
                continue; // condizioni identiche deduplicate
            }
            $seen[$key] = true;
            $counts[$this->conditionCategory($scopeType)]++;
            $normalized[] = ['scope_type' => $scopeType, 'scope_id' => $scopeId];
        }

        if (empty($normalized)) {
            throw new InvalidArgumentException('empty_rule');
        }
        // Una sola condizione per ciascuna categoria.
        if ($counts['location'] > 1 || $counts['service_category'] > 1 || $counts['appointment'] > 1) {
            throw new InvalidArgumentException('invalid_rule_combination');
        }
        // business non si combina con altre condizioni.
        if ($counts['business'] > 0 && count($normalized) > 1) {
            throw new InvalidArgumentException('invalid_rule_combination');
        }
        // categoria + tipo appuntamento (con o senza sede) non è ammesso.
        if ($counts['service_category'] > 0 && $counts['appointment'] > 0) {
            throw new InvalidArgumentException('invalid_rule_combination');
        }

        return $normalized;
    }

    private function conditionCategory(string $scopeType): string
    {
        return match ($scopeType) {
            'business' => 'business',
            'location' => 'location',
            'service_category' => 'service_category',
            'service_variant', 'service_package', 'class_event', 'class_type' => 'appointment',
            default => 'unknown',
        };
    }

    public function resolvePublicForms(
        int $businessId,
        int $locationId,
        array $serviceVariantIds = [],
        array $serviceIds = [],
        array $servicePackageIds = [],
        array $classEventIds = []
    ): array {
        $context = $this->buildContextIds($businessId, $locationId, $serviceVariantIds, $serviceIds, $servicePackageIds, $classEventIds);
        $forms = $this->findActiveFormsForContext($businessId, $context);
        return array_map([$this, 'formatPublicForm'], $forms);
    }

    public function validateAndSaveSubmissions(
        int $businessId,
        int $locationId,
        int $bookingId,
        ?int $clientId,
        array $serviceVariantIds,
        array $serviceIds,
        array $servicePackageIds,
        array $classEventIds,
        array $submissions,
        bool $replaceExisting = false,
        bool $enforceRequired = true
    ): void {
        $context = $this->buildContextIds($businessId, $locationId, $serviceVariantIds, $serviceIds, $servicePackageIds, $classEventIds);
        $forms = $this->findActiveFormsForContext($businessId, $context);
        $formsById = [];
        foreach ($forms as $form) {
            $formsById[(int) $form['id']] = $form;
        }

        // Modifica dal gestionale: sostituisce le submission esistenti.
        if ($replaceExisting) {
            $this->deleteSubmissionsForBooking($businessId, $bookingId);
        }

        $submittedByForm = [];
        foreach ($submissions as $submission) {
            if (!is_array($submission) || !isset($submission['form_id'])) {
                throw BookingException::bookingFormError('booking_form_invalid_submission', 'Invalid booking form submission');
            }
            $formId = (int) $submission['form_id'];
            if (!isset($formsById[$formId])) {
                throw BookingException::bookingFormError('booking_form_not_applicable', 'Booking form is not applicable to this booking', ['form_id' => $formId]);
            }
            $submittedByForm[$formId] = $submission;
        }

        $missing = [];
        foreach ($formsById as $formId => $form) {
            $answersByField = $this->answersByField($submittedByForm[$formId]['answers'] ?? []);
            foreach ($form['fields'] as $field) {
                if ((int) $field['is_required'] !== 1 || !$this->isInputField((string) $field['field_type'])) {
                    continue;
                }
                $value = $answersByField[(int) $field['id']]['value'] ?? null;
                if (!$this->isValidAnswerValue($field, $value)) {
                    $missing[] = ['form_id' => $formId, 'field_id' => (int) $field['id']];
                }
            }
        }
        if ($enforceRequired && !empty($missing)) {
            throw BookingException::bookingFormError(
                'booking_form_required_fields_missing',
                'One or more required booking form fields are missing',
                ['fields' => $missing]
            );
        }

        foreach ($submittedByForm as $formId => $submission) {
            $form = $formsById[$formId];
            $answersByField = $this->answersByField($submission['answers'] ?? []);
            $answersToSave = [];
            foreach ($form['fields'] as $field) {
                $fieldId = (int) $field['id'];
                $fieldType = (string) $field['field_type'];
                if (!$this->isInputField($fieldType) || !array_key_exists($fieldId, $answersByField)) {
                    continue;
                }
                $value = $answersByField[$fieldId]['value'] ?? null;
                if (!$this->isValidAnswerValue($field, $value)) {
                    if ((int) $field['is_required'] === 1) {
                        throw BookingException::bookingFormError('booking_form_invalid_field', 'Invalid booking form field value', ['field_id' => $fieldId]);
                    }
                    continue;
                }
                $answersToSave[] = $this->formatAnswerForStorage($field, $value);
            }

            if (empty($answersToSave)) {
                continue;
            }

            $stmt = $this->db->getPdo()->prepare(
                'INSERT INTO booking_form_submissions
                    (business_id, booking_id, form_id, form_title_snapshot, submitted_by_client_id)
                 VALUES (?, ?, ?, ?, ?)'
            );
            $stmt->execute([$businessId, $bookingId, $formId, $form['title'], $clientId]);
            $submissionId = (int) $this->db->getPdo()->lastInsertId();

            $answerStmt = $this->db->getPdo()->prepare(
                'INSERT INTO booking_form_submission_answers
                    (submission_id, business_id, booking_id, form_id, field_id, field_type_snapshot, field_label_snapshot, answer_text, answer_json)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            foreach ($answersToSave as $answer) {
                $answerStmt->execute([
                    $submissionId,
                    $businessId,
                    $bookingId,
                    $formId,
                    $answer['field_id'],
                    $answer['field_type'],
                    $answer['field_label'],
                    $answer['answer_text'],
                    $answer['answer_json'],
                ]);
            }
        }
    }

    public function getSubmissionsForBooking(int $businessId, int $bookingId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM booking_form_submissions WHERE business_id = ? AND booking_id = ? ORDER BY id ASC'
        );
        $stmt->execute([$businessId, $bookingId]);
        $submissions = $stmt->fetchAll();
        if (empty($submissions)) {
            return [];
        }

        $ids = array_map(static fn(array $row): int => (int) $row['id'], $submissions);
        $placeholders = implode(',', array_fill(0, count($ids), '?'));
        $answerStmt = $this->db->getPdo()->prepare(
            "SELECT * FROM booking_form_submission_answers
             WHERE submission_id IN ({$placeholders})
             ORDER BY id ASC"
        );
        $answerStmt->execute($ids);
        $answersBySubmission = [];
        foreach ($answerStmt->fetchAll() as $answer) {
            $answersBySubmission[(int) $answer['submission_id']][] = [
                'id' => (int) $answer['id'],
                'field_id' => (int) $answer['field_id'],
                'field_type' => $answer['field_type_snapshot'],
                'field_label' => $answer['field_label_snapshot'],
                'answer_text' => $answer['answer_text'],
                'answer_json' => $this->decodeJson($answer['answer_json'] ?? null),
            ];
        }

        return array_map(static function (array $submission) use ($answersBySubmission): array {
            $id = (int) $submission['id'];
            return [
                'id' => $id,
                'booking_id' => (int) $submission['booking_id'],
                'form_id' => (int) $submission['form_id'],
                'form_title' => $submission['form_title_snapshot'],
                'submitted_by_client_id' => $submission['submitted_by_client_id'] !== null ? (int) $submission['submitted_by_client_id'] : null,
                'submitted_at' => $submission['submitted_at'],
                'answers' => $answersBySubmission[$id] ?? [],
            ];
        }, $submissions);
    }

    /**
     * Tutti i moduli attivi del business (con campi) e il valore corrente di
     * ogni campo dalle submission salvate. Per il gestionale, dove l'operatore
     * può compilare/modificare qualunque modulo su una prenotazione,
     * indipendentemente dalle assegnazioni (che valgono per la prenotazione
     * pubblica).
     */
    public function getActiveFormsWithValues(int $businessId, int $bookingId): array
    {
        $forms = array_map(
            [$this, 'formatPublicForm'],
            $this->allActiveFormsWithFields($businessId)
        );
        return $this->attachAnswerValues($forms, $businessId, $bookingId);
    }

    /**
     * Salva (sostituendo) le risposte ai moduli di una prenotazione dal
     * gestionale. Valida i valori rispetto ai campi del modulo; permissivo sui
     * campi obbligatori (consente salvataggi parziali).
     */
    public function saveManagedSubmissions(
        int $businessId,
        int $bookingId,
        ?int $clientId,
        array $submissions
    ): void {
        $formsById = [];
        foreach ($this->allActiveFormsWithFields($businessId) as $form) {
            $formsById[(int) $form['id']] = $form;
        }

        $this->deleteSubmissionsForBooking($businessId, $bookingId);

        $pdo = $this->db->getPdo();
        $submissionStmt = $pdo->prepare(
            'INSERT INTO booking_form_submissions
                (business_id, booking_id, form_id, form_title_snapshot, submitted_by_client_id)
             VALUES (?, ?, ?, ?, ?)'
        );
        $answerStmt = $pdo->prepare(
            'INSERT INTO booking_form_submission_answers
                (submission_id, business_id, booking_id, form_id, field_id, field_type_snapshot, field_label_snapshot, answer_text, answer_json)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );

        foreach ($submissions as $submission) {
            if (!is_array($submission) || !isset($submission['form_id'])) {
                continue;
            }
            $formId = (int) $submission['form_id'];
            if (!isset($formsById[$formId])) {
                continue; // modulo sconosciuto/non attivo: ignorato
            }
            $form = $formsById[$formId];
            $answersByField = $this->answersByField($submission['answers'] ?? []);
            $answersToSave = [];
            foreach ($form['fields'] as $field) {
                $fieldId = (int) $field['id'];
                $fieldType = (string) $field['field_type'];
                if (!$this->isInputField($fieldType) || !array_key_exists($fieldId, $answersByField)) {
                    continue;
                }
                $value = $answersByField[$fieldId]['value'] ?? null;
                if (!$this->isValidAnswerValue($field, $value)) {
                    continue;
                }
                $answersToSave[] = $this->formatAnswerForStorage($field, $value);
            }
            if (empty($answersToSave)) {
                continue;
            }

            $submissionStmt->execute([$businessId, $bookingId, $formId, $form['title'], $clientId]);
            $submissionId = (int) $pdo->lastInsertId();
            foreach ($answersToSave as $answer) {
                $answerStmt->execute([
                    $submissionId,
                    $businessId,
                    $bookingId,
                    $formId,
                    $answer['field_id'],
                    $answer['field_type'],
                    $answer['field_label'],
                    $answer['answer_text'],
                    $answer['answer_json'],
                ]);
            }
        }
    }

    /** @param array<int,array<string,mixed>> $forms */
    private function attachAnswerValues(array $forms, int $businessId, int $bookingId): array
    {
        $valueByFormField = [];
        foreach ($this->getSubmissionsForBooking($businessId, $bookingId) as $submission) {
            $formId = (int) $submission['form_id'];
            foreach ($submission['answers'] as $answer) {
                $valueByFormField[$formId][(int) $answer['field_id']] = $answer;
            }
        }

        foreach ($forms as &$form) {
            $formId = (int) $form['id'];
            foreach ($form['fields'] as &$field) {
                $stored = $valueByFormField[$formId][(int) $field['id']] ?? null;
                $field['value'] = $stored === null
                    ? null
                    : $this->storedAnswerValue((string) $field['field_type'], $stored);
            }
            unset($field);
        }
        unset($form);

        return $forms;
    }

    private function allActiveFormsWithFields(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM booking_forms
             WHERE business_id = ? AND is_active = 1 AND deleted_at IS NULL
             ORDER BY sort_order ASC, id ASC'
        );
        $stmt->execute([$businessId]);
        $forms = $stmt->fetchAll();
        if (empty($forms)) {
            return [];
        }

        $formIds = array_map(static fn(array $row): int => (int) $row['id'], $forms);
        $fieldsByForm = $this->fieldsByFormIds($businessId, $formIds);
        $result = [];
        foreach ($forms as $form) {
            $id = (int) $form['id'];
            if (empty($fieldsByForm[$id])) {
                continue;
            }
            $form['fields'] = $fieldsByForm[$id];
            $result[] = $form;
        }
        return $result;
    }

    private function storedAnswerValue(string $fieldType, array $answer): mixed
    {
        if ($fieldType === self::FIELD_MULTIPLE_CHOICE) {
            $json = $answer['answer_json'] ?? null;
            return is_array($json) ? array_values($json) : [];
        }
        if (in_array($fieldType, [self::FIELD_CHECKBOX, self::FIELD_CONSENT], true)) {
            return ($answer['answer_text'] ?? null) === '1';
        }
        return $answer['answer_text'];
    }

    private function deleteSubmissionsForBooking(int $businessId, int $bookingId): void
    {
        $pdo = $this->db->getPdo();
        $answers = $pdo->prepare(
            'DELETE FROM booking_form_submission_answers WHERE business_id = ? AND booking_id = ?'
        );
        $answers->execute([$businessId, $bookingId]);
        $submissions = $pdo->prepare(
            'DELETE FROM booking_form_submissions WHERE business_id = ? AND booking_id = ?'
        );
        $submissions->execute([$businessId, $bookingId]);
    }

    private function findActiveFormsForContext(int $businessId, array $context): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT bf.*
             FROM booking_forms bf
             WHERE bf.business_id = ?
               AND bf.is_active = 1
               AND bf.deleted_at IS NULL
             ORDER BY bf.sort_order ASC, bf.id ASC'
        );
        $stmt->execute([$businessId]);
        $forms = $stmt->fetchAll();
        if (empty($forms)) {
            return [];
        }

        $formIds = array_map(static fn(array $row): int => (int) $row['id'], $forms);
        $fieldsByForm = $this->fieldsByFormIds($businessId, $formIds);
        $rulesByForm = $this->rulesByFormIds($businessId, $formIds);
        $formsWithFields = [];
        foreach ($forms as $form) {
            $id = (int) $form['id'];
            if (empty($fieldsByForm[$id])) {
                continue;
            }
            // Il modulo appare se almeno una regola è soddisfatta (OR tra regole).
            if (!$this->formMatchesContext($rulesByForm[$id] ?? [], $context)) {
                continue;
            }
            $form['fields'] = $fieldsByForm[$id];
            $form['rules'] = $rulesByForm[$id] ?? [];
            $formsWithFields[] = $form;
        }

        return $formsWithFields;
    }

    /**
     * Una regola è soddisfatta solo se tutte le sue condizioni sono compatibili
     * con il contesto della prenotazione (AND); tra regole diverse vale OR.
     *
     * @param array<int,array{conditions:array}> $rules
     */
    private function formMatchesContext(array $rules, array $context): bool
    {
        foreach ($rules as $rule) {
            $conditions = $rule['conditions'] ?? [];
            if (empty($conditions)) {
                continue;
            }
            $allMatch = true;
            foreach ($conditions as $condition) {
                if (!$this->conditionMatchesContext($condition, $context)) {
                    $allMatch = false;
                    break;
                }
            }
            if ($allMatch) {
                return true;
            }
        }
        return false;
    }

    private function conditionMatchesContext(array $condition, array $context): bool
    {
        $scopeType = (string) ($condition['scope_type'] ?? '');
        if ($scopeType === 'business') {
            return true;
        }
        $scopeId = $condition['scope_id'] ?? null;
        if ($scopeId === null) {
            return false;
        }
        $ids = $context[$scopeType] ?? [];
        return in_array((int) $scopeId, $ids, true);
    }

    private function buildContextIds(int $businessId, int $locationId, array $serviceVariantIds, array $serviceIds, array $servicePackageIds, array $classEventIds): array
    {
        $serviceVariantIds = $this->positiveIds($serviceVariantIds);
        $serviceIds = $this->positiveIds($serviceIds);
        $servicePackageIds = $this->positiveIds($servicePackageIds);
        $classEventIds = $this->positiveIds($classEventIds);
        $categoryIds = [];
        $classTypeIds = [];

        if (!empty($serviceVariantIds) || !empty($serviceIds)) {
            $variantSql = !empty($serviceVariantIds)
                ? 'sv.id IN (' . implode(',', array_fill(0, count($serviceVariantIds), '?')) . ')'
                : '0 = 1';
            $serviceSql = !empty($serviceIds)
                ? 's.id IN (' . implode(',', array_fill(0, count($serviceIds), '?')) . ')'
                : '0 = 1';
            $stmt = $this->db->getPdo()->prepare(
                "SELECT DISTINCT s.category_id
                 FROM service_variants sv
                 INNER JOIN services s ON s.id = sv.service_id
                 WHERE ({$variantSql} OR {$serviceSql}) AND s.business_id = ? AND sv.location_id = ?"
            );
            $stmt->execute([...$serviceVariantIds, ...$serviceIds, $businessId, $locationId]);
            foreach ($stmt->fetchAll() as $row) {
                if ($row['category_id'] !== null) {
                    $categoryIds[] = (int) $row['category_id'];
                }
            }

            if (!empty($serviceIds)) {
                $placeholders = implode(',', array_fill(0, count($serviceIds), '?'));
                $variantStmt = $this->db->getPdo()->prepare(
                    "SELECT sv.id
                     FROM service_variants sv
                     INNER JOIN services s ON s.id = sv.service_id
                     WHERE s.id IN ({$placeholders}) AND s.business_id = ? AND sv.location_id = ?"
                );
                $variantStmt->execute([...$serviceIds, $businessId, $locationId]);
                foreach ($variantStmt->fetchAll() as $row) {
                    $serviceVariantIds[] = (int) $row['id'];
                }
                $serviceVariantIds = $this->positiveIds($serviceVariantIds);
            }
        }

        if (!empty($servicePackageIds)) {
            $placeholders = implode(',', array_fill(0, count($servicePackageIds), '?'));
            $stmt = $this->db->getPdo()->prepare(
                "SELECT DISTINCT category_id
                 FROM service_packages
                 WHERE id IN ({$placeholders}) AND business_id = ? AND location_id = ?"
            );
            $stmt->execute([...$servicePackageIds, $businessId, $locationId]);
            foreach ($stmt->fetchAll() as $row) {
                if ($row['category_id'] !== null) {
                    $categoryIds[] = (int) $row['category_id'];
                }
            }
        }

        if (!empty($classEventIds)) {
            $placeholders = implode(',', array_fill(0, count($classEventIds), '?'));
            $stmt = $this->db->getPdo()->prepare(
                "SELECT DISTINCT ct.id AS class_type_id, ct.service_category_id
                 FROM class_events ce
                 INNER JOIN class_types ct ON ct.id = ce.class_type_id AND ct.business_id = ce.business_id
                 WHERE ce.id IN ({$placeholders}) AND ce.business_id = ? AND ce.location_id = ?"
            );
            $stmt->execute([...$classEventIds, $businessId, $locationId]);
            foreach ($stmt->fetchAll() as $row) {
                if ($row['class_type_id'] !== null) {
                    $classTypeIds[] = (int) $row['class_type_id'];
                }
                if ($row['service_category_id'] !== null) {
                    $categoryIds[] = (int) $row['service_category_id'];
                }
            }
        }

        return [
            'location' => [$locationId],
            'service_variant' => $serviceVariantIds,
            'service_package' => $servicePackageIds,
            'class_event' => $classEventIds,
            'class_type' => $this->positiveIds($classTypeIds),
            'service_category' => $this->positiveIds($categoryIds),
        ];
    }

    private function fieldsByFormIds(int $businessId, array $formIds): array
    {
        if (empty($formIds)) {
            return [];
        }
        $placeholders = implode(',', array_fill(0, count($formIds), '?'));
        $stmt = $this->db->getPdo()->prepare(
            "SELECT *
             FROM booking_form_fields
             WHERE business_id = ?
               AND form_id IN ({$placeholders})
               AND is_active = 1
             ORDER BY sort_order ASC, id ASC"
        );
        $stmt->execute([$businessId, ...$formIds]);
        $fields = [];
        foreach ($stmt->fetchAll() as $field) {
            $fields[(int) $field['form_id']][] = $this->formatField($field);
        }
        return $fields;
    }

    /**
     * Restituisce le regole (con condizioni) per i moduli indicati,
     * raggruppate per form_id.
     */
    private function rulesByFormIds(int $businessId, array $formIds): array
    {
        if (empty($formIds)) {
            return [];
        }
        $placeholders = implode(',', array_fill(0, count($formIds), '?'));
        $stmt = $this->db->getPdo()->prepare(
            "SELECT *
             FROM booking_form_rules
             WHERE business_id = ?
               AND form_id IN ({$placeholders})
               AND is_active = 1
             ORDER BY sort_order ASC, id ASC"
        );
        $stmt->execute([$businessId, ...$formIds]);
        $rules = $stmt->fetchAll();
        if (empty($rules)) {
            return [];
        }

        $ruleIds = array_map(static fn(array $row): int => (int) $row['id'], $rules);
        $rulePlaceholders = implode(',', array_fill(0, count($ruleIds), '?'));
        $condStmt = $this->db->getPdo()->prepare(
            "SELECT *
             FROM booking_form_rule_conditions
             WHERE rule_id IN ({$rulePlaceholders})
             ORDER BY id ASC"
        );
        $condStmt->execute($ruleIds);
        $conditionsByRule = [];
        foreach ($condStmt->fetchAll() as $cond) {
            $conditionsByRule[(int) $cond['rule_id']][] = [
                'scope_type' => $cond['scope_type'],
                'scope_id' => $cond['scope_id'] !== null ? (int) $cond['scope_id'] : null,
            ];
        }

        $byForm = [];
        foreach ($rules as $rule) {
            $id = (int) $rule['id'];
            $byForm[(int) $rule['form_id']][] = [
                'id' => $id,
                'form_id' => (int) $rule['form_id'],
                'sort_order' => (int) $rule['sort_order'],
                'conditions' => $conditionsByRule[$id] ?? [],
            ];
        }
        return $byForm;
    }

    private function formatAdminForm(array $form): array
    {
        $id = (int) $form['id'];
        return $this->formatAdminFormSummary($form) + [
            'fields' => $this->fieldsByFormIds((int) $form['business_id'], [$id])[$id] ?? [],
            'rules' => $this->rulesByFormIds((int) $form['business_id'], [$id])[$id] ?? [],
        ];
    }

    private function formatAdminFormSummary(array $form): array
    {
        return [
            'id' => (int) $form['id'],
            'business_id' => (int) $form['business_id'],
            'title' => $form['title'],
            'description' => $form['description'],
            'internal_name' => $form['internal_name'],
            'is_active' => (int) $form['is_active'] === 1,
            'sort_order' => (int) $form['sort_order'],
            'fields_count' => isset($form['fields_count']) ? (int) $form['fields_count'] : null,
            'rules_count' => isset($form['rules_count']) ? (int) $form['rules_count'] : null,
            'created_at' => $form['created_at'],
            'updated_at' => $form['updated_at'],
        ];
    }

    private function formatPublicForm(array $form): array
    {
        return [
            'id' => (int) $form['id'],
            'title' => $form['title'],
            'description' => $form['description'],
            'sort_order' => (int) $form['sort_order'],
            'fields' => $form['fields'] ?? [],
        ];
    }

    private function formatField(array $field): array
    {
        return [
            'id' => (int) $field['id'],
            'form_id' => (int) $field['form_id'],
            'field_type' => $field['field_type'],
            'label' => $field['label'],
            'description' => $field['description'],
            'placeholder' => $field['placeholder'],
            'help_text' => $field['help_text'],
            'is_required' => (int) $field['is_required'] === 1,
            'sort_order' => (int) $field['sort_order'],
            'options' => $this->decodeJson($field['options_json'] ?? null) ?? [],
            'validation' => $this->decodeJson($field['validation_json'] ?? null) ?? [],
            'is_active' => (int) $field['is_active'] === 1,
        ];
    }

    private function normalizeFieldData(array $data, bool $requireLabel = true): array
    {
        $fieldType = (string) ($data['field_type'] ?? '');
        if (!in_array($fieldType, self::FIELD_TYPES, true)) {
            throw new InvalidArgumentException('invalid_field_type');
        }
        $label = trim((string) ($data['label'] ?? ''));
        if ($label === '' && $fieldType !== self::FIELD_CONSENT) {
            throw new InvalidArgumentException('label_required');
        }

        $isRequired = isset($data['is_required'])
            ? (int) (bool) $data['is_required']
            : 0;
        if (in_array($fieldType, self::NON_REQUIRED_TYPES, true)) {
            $isRequired = 0;
        }

        $options = $this->normalizeOptions($data['options'] ?? $data['options_json'] ?? null);
        if (in_array($fieldType, self::CHOICE_TYPES, true) && count($options) < 2) {
            throw new InvalidArgumentException('options_required');
        }

        $validation = $this->decodeJson($data['validation_json'] ?? null);
        if (isset($data['validation']) && is_array($data['validation'])) {
            $validation = $data['validation'];
        }
        if ($fieldType === self::FIELD_CONSENT && is_array($validation) && isset($validation['url'])) {
            $url = trim((string) $validation['url']);
            if ($url === '') {
                unset($validation['url']);
            } elseif (!filter_var($url, FILTER_VALIDATE_URL)) {
                throw new InvalidArgumentException('invalid_consent_url');
            } else {
                $validation['url'] = $url;
            }
        }

        return [
            'field_type' => $fieldType,
            'label' => $label,
            'description' => $this->nullableTrim($data['description'] ?? null),
            'placeholder' => $this->nullableTrim($data['placeholder'] ?? null),
            'help_text' => $this->nullableTrim($data['help_text'] ?? null),
            'is_required' => $isRequired,
            'sort_order' => (int) ($data['sort_order'] ?? 0),
            'options_json' => !empty($options) ? Json::encode($options) : null,
            'validation_json' => is_array($validation) && !empty($validation) ? Json::encode($validation) : null,
            'is_active' => isset($data['is_active']) ? (int) (bool) $data['is_active'] : 1,
        ];
    }

    private function normalizeOptions(mixed $value): array
    {
        $decoded = is_string($value) ? $this->decodeJson($value) : $value;
        if (!is_array($decoded)) {
            return [];
        }
        $options = [];
        foreach ($decoded as $option) {
            if (is_array($option)) {
                $optionValue = trim((string) ($option['value'] ?? $option['label'] ?? ''));
                $label = trim((string) ($option['label'] ?? $optionValue));
            } else {
                $optionValue = trim((string) $option);
                $label = $optionValue;
            }
            if ($optionValue === '') {
                continue;
            }
            $options[] = ['value' => $optionValue, 'label' => $label];
        }
        return $options;
    }

    private function answersByField(array $answers): array
    {
        $result = [];
        foreach ($answers as $answer) {
            if (!is_array($answer) || !isset($answer['field_id'])) {
                continue;
            }
            $result[(int) $answer['field_id']] = $answer;
        }
        return $result;
    }

    private function isValidAnswerValue(array $field, mixed $value): bool
    {
        $type = (string) $field['field_type'];
        $required = (int) $field['is_required'] === 1 || ($field['is_required'] ?? false) === true;
        if ($value === null || $value === '') {
            return !$required;
        }

        if (in_array($type, [self::FIELD_CHECKBOX, self::FIELD_CONSENT], true)) {
            return !$required || $value === true || $value === 1 || $value === '1';
        }

        if ($type === self::FIELD_MULTIPLE_CHOICE) {
            if (!is_array($value)) {
                return false;
            }
            if ($required && empty($value)) {
                return false;
            }
            return $this->valuesBelongToOptions($field, $value);
        }

        if (in_array(
            $type,
            [self::FIELD_SINGLE_CHOICE, self::FIELD_SEGMENTED_CHOICE, self::FIELD_DROPDOWN],
            true
        )) {
            return $this->valuesBelongToOptions($field, [(string) $value]);
        }

        $text = trim((string) $value);
        if ($required && $text === '') {
            return false;
        }
        $max = $type === self::FIELD_SHORT_TEXT ? 1000 : 4000;
        $validation = is_array($field['validation'] ?? null) ? $field['validation'] : [];
        if (isset($validation['max_length'])) {
            $max = max(1, min(10000, (int) $validation['max_length']));
        }
        return mb_strlen($text) <= $max;
    }

    private function valuesBelongToOptions(array $field, array $values): bool
    {
        $allowed = [];
        foreach (($field['options'] ?? []) as $option) {
            if (is_array($option) && isset($option['value'])) {
                $allowed[(string) $option['value']] = true;
            }
        }
        foreach ($values as $value) {
            if (!isset($allowed[(string) $value])) {
                return false;
            }
        }
        return true;
    }

    private function formatAnswerForStorage(array $field, mixed $value): array
    {
        $type = (string) $field['field_type'];
        $answerText = null;
        $answerJson = null;
        if ($type === self::FIELD_MULTIPLE_CHOICE || is_array($value)) {
            $answerJson = Json::encode(array_values((array) $value));
        } elseif (in_array($type, [self::FIELD_CHECKBOX, self::FIELD_CONSENT], true)) {
            $answerText = ($value === true || $value === 1 || $value === '1') ? '1' : '0';
        } else {
            $answerText = trim((string) $value);
        }

        return [
            'field_id' => (int) $field['id'],
            'field_type' => $type,
            'field_label' => (string) $field['label'],
            'answer_text' => $answerText,
            'answer_json' => $answerJson,
        ];
    }

    private function isValidCondition(int $businessId, string $scopeType, ?int $scopeId): bool
    {
        if (!in_array($scopeType, self::SCOPE_TYPES, true)) {
            return false;
        }
        if ($scopeType === 'business') {
            return $scopeId === null;
        }
        if ($scopeId === null || $scopeId <= 0) {
            return false;
        }
        $map = [
            'location' => ['locations', 'id'],
            'service_variant' => ['service_variants sv INNER JOIN services s ON s.id = sv.service_id', 'sv.id'],
            'service_package' => ['service_packages', 'id'],
            'class_event' => ['class_events', 'id'],
            'class_type' => ['class_types', 'id'],
            'service_category' => ['service_categories', 'id'],
        ];
        [$table, $column] = $map[$scopeType];
        $businessColumn = $scopeType === 'service_variant' ? 's.business_id' : 'business_id';
        $stmt = $this->db->getPdo()->prepare("SELECT 1 FROM {$table} WHERE {$column} = ? AND {$businessColumn} = ? LIMIT 1");
        $stmt->execute([$scopeId, $businessId]);
        return (bool) $stmt->fetchColumn();
    }

    private function assertFormBelongsToBusiness(int $businessId, int $formId): void
    {
        if ($this->findForm($businessId, $formId) === null) {
            throw new InvalidArgumentException('form_not_found');
        }
    }

    private function findField(int $businessId, int $formId, int $fieldId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM booking_form_fields WHERE id = ? AND form_id = ? AND business_id = ?'
        );
        $stmt->execute([$fieldId, $formId, $businessId]);
        return $stmt->fetch() ?: null;
    }

    private function nullableTrim(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }
        $trimmed = trim((string) $value);
        return $trimmed === '' ? null : $trimmed;
    }

    private function decodeJson(mixed $value): mixed
    {
        if ($value === null || $value === '') {
            return null;
        }
        if (is_array($value)) {
            return $value;
        }
        return Json::decodeAssoc((string) $value);
    }

    private function positiveIds(array $ids): array
    {
        $normalized = array_values(array_unique(array_filter(
            array_map(static fn(mixed $id): int => (int) $id, $ids),
            static fn(int $id): bool => $id > 0
        )));
        sort($normalized);
        return $normalized;
    }

    private function isInputField(string $type): bool
    {
        return in_array($type, self::INPUT_TYPES, true);
    }
}
