<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\StaffPlanningRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

/**
 * Controller per staff planning.
 * 
 * Endpoint:
 * - GET /v1/staff/{id}/plannings - tutti i planning di uno staff
 * - GET /v1/staff/{id}/planning - planning valido per una data (query: date)
 * - GET /v1/staff/{id}/availability - disponibilità per una data (query: date)
 */
final class StaffPlanningController
{
    public function __construct(
        private readonly StaffPlanningRepository $planningRepo,
        private readonly StaffRepository $staffRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * GET /v1/staff/{id}/plannings
     * 
     * Ritorna tutti i planning di uno staff.
     */
    public function indexForStaff(Request $request): Response
    {
        $staffId = (int) $request->getAttribute('id');

        if (!$this->hasStaffAccess($request, $staffId)) {
            return Response::notFound('Staff not found', $request->traceId);
        }

        $plannings = $this->planningRepo->findByStaffId($staffId);

        return Response::json(['success' => true, 'data' => $plannings], 200, $request->traceId);
    }

    /**
     * GET /v1/staff/{id}/planning?date=YYYY-MM-DD
     * 
     * Ritorna il planning valido per lo staff in una data specifica.
     * Include week_label calcolata per biweekly.
     */
    public function showForDate(Request $request): Response
    {
        $staffId = (int) $request->getAttribute('id');
        $date = $request->query['date'] ?? null;

        if ($date === null) {
            return Response::error(
                'Il parametro date è obbligatorio',
                'missing_date',
                400,
                $request->traceId
            );
        }

        if (!$this->isValidDate($date)) {
            return Response::error(
                'Formato data non valido. Usare YYYY-MM-DD',
                'invalid_date_format',
                400,
                $request->traceId
            );
        }

        if (!$this->hasStaffAccess($request, $staffId)) {
            return Response::notFound('Staff not found', $request->traceId);
        }

        try {
            $planning = $this->planningRepo->findValidForDate($staffId, $date);
        } catch (\RuntimeException $e) {
            // Errore di consistenza: più planning validi
            return Response::error(
                $e->getMessage(),
                'consistency_error',
                409,
                $request->traceId
            );
        }

        if ($planning === null) {
            return Response::json([
                'success' => true,
                'data' => null,
                'message' => 'Nessun planning valido per questa data',
            ], 200, $request->traceId);
        }

        // Aggiungi week_label calcolata per biweekly
        if ($planning['type'] === 'biweekly') {
            $planning['current_week_label'] = $this->planningRepo->computeWeekLabel(
                $planning['valid_from'],
                $date
            );
        } else {
            $planning['current_week_label'] = 'a';
        }

        return Response::json(['success' => true, 'data' => $planning], 200, $request->traceId);
    }

    /**
     * GET /v1/staff/{id}/availability?date=YYYY-MM-DD
     * 
     * Ritorna gli slot disponibili per lo staff in una data.
     */
    public function availabilityForDate(Request $request): Response
    {
        $staffId = (int) $request->getAttribute('id');
        $date = $request->query['date'] ?? null;

        if ($date === null) {
            return Response::error(
                'Il parametro date è obbligatorio',
                'missing_date',
                400,
                $request->traceId
            );
        }

        if (!$this->isValidDate($date)) {
            return Response::error(
                'Formato data non valido. Usare YYYY-MM-DD',
                'invalid_date_format',
                400,
                $request->traceId
            );
        }

        if (!$this->hasStaffAccess($request, $staffId)) {
            return Response::notFound('Staff not found', $request->traceId);
        }

        try {
            $slots = $this->planningRepo->getSlotsForDate($staffId, $date);
        } catch (\RuntimeException $e) {
            return Response::error(
                $e->getMessage(),
                'consistency_error',
                409,
                $request->traceId
            );
        }

        $dayOfWeek = (int) (new \DateTime($date))->format('N');

        return Response::json([
            'success' => true,
            'data' => [
                'staff_id' => $staffId,
                'date' => $date,
                'day_of_week' => $dayOfWeek,
                'slots' => $slots ?? [],
                'is_available' => $slots !== null && count($slots) > 0,
            ],
        ], 200, $request->traceId);
    }

    /**
     * GET /v1/staff/{id}/planning/{planning_id}
     * 
     * Ritorna un planning specifico.
     */
    public function show(Request $request): Response
    {
        $staffId = (int) $request->getAttribute('id');
        $planningId = (int) $request->getAttribute('planning_id');

        if (!$this->hasStaffAccess($request, $staffId)) {
            return Response::notFound('Staff not found', $request->traceId);
        }

        $planning = $this->planningRepo->findById($planningId);

        if ($planning === null || (int) $planning['staff_id'] !== $staffId) {
            return Response::notFound('Planning not found', $request->traceId);
        }

        return Response::json(['success' => true, 'data' => $planning], 200, $request->traceId);
    }

    /**
     * POST /v1/staff/{id}/plannings
     * 
     * Crea un nuovo planning per lo staff.
     */
    public function store(Request $request): Response
    {
        $staffId = (int) $request->getAttribute('id');

        if (!$this->hasStaffAccess($request, $staffId)) {
            return Response::notFound('Staff not found', $request->traceId);
        }

        $data = $request->body;

        // Validazione
        $errors = $this->validatePlanningData($data);
        if (!empty($errors)) {
            return Response::error(
                implode('. ', $errors),
                'validation_error',
                400,
                $request->traceId
            );
        }

        // Verifica sovrapposizione
        if ($this->planningRepo->hasOverlap(
            $staffId,
            $data['valid_from'],
            $data['valid_to'] ?? null
        )) {
            return Response::error(
                'Sovrapposizione con un planning esistente',
                'overlap_error',
                409,
                $request->traceId
            );
        }

        // Crea planning
        $planningId = $this->planningRepo->create([
            'staff_id' => $staffId,
            'type' => $data['type'],
            'valid_from' => $data['valid_from'],
            'valid_to' => $data['valid_to'] ?? null,
        ]);

        // Salva templates
        if (isset($data['templates'])) {
            $this->saveTemplates($planningId, $data['templates']);
        }

        $planning = $this->planningRepo->findById($planningId);

        return Response::json(['success' => true, 'data' => $planning], 201, $request->traceId);
    }

    /**
     * PUT /v1/staff/{id}/plannings/{planning_id}
     * 
     * Aggiorna un planning esistente.
     */
    public function update(Request $request): Response
    {
        $staffId = (int) $request->getAttribute('id');
        $planningId = (int) $request->getAttribute('planning_id');

        if (!$this->hasStaffAccess($request, $staffId)) {
            return Response::notFound('Staff not found', $request->traceId);
        }

        $existing = $this->planningRepo->findById($planningId);
        if ($existing === null || (int) $existing['staff_id'] !== $staffId) {
            return Response::notFound('Planning not found', $request->traceId);
        }

        $data = $request->body;

        // Validazione
        $errors = $this->validatePlanningData($data, true);
        if (!empty($errors)) {
            return Response::error(
                implode('. ', $errors),
                'validation_error',
                400,
                $request->traceId
            );
        }

        // Verifica sovrapposizione (escludendo il planning corrente)
        $validFrom = $data['valid_from'] ?? $existing['valid_from'];
        $validTo = array_key_exists('valid_to', $data) ? $data['valid_to'] : $existing['valid_to'];

        if ($this->planningRepo->hasOverlap($staffId, $validFrom, $validTo, $planningId)) {
            return Response::error(
                'Sovrapposizione con un planning esistente',
                'overlap_error',
                409,
                $request->traceId
            );
        }

        // Aggiorna planning
        $this->planningRepo->update($planningId, $data);

        // Aggiorna templates se forniti
        if (isset($data['templates'])) {
            $this->planningRepo->deleteTemplates($planningId);
            $this->saveTemplates($planningId, $data['templates']);
        }

        $planning = $this->planningRepo->findById($planningId);

        return Response::json(['success' => true, 'data' => $planning], 200, $request->traceId);
    }

    /**
     * DELETE /v1/staff/{id}/plannings/{planning_id}
     * 
     * Elimina un planning.
     */
    public function destroy(Request $request): Response
    {
        $staffId = (int) $request->getAttribute('id');
        $planningId = (int) $request->getAttribute('planning_id');

        if (!$this->hasStaffAccess($request, $staffId)) {
            return Response::notFound('Staff not found', $request->traceId);
        }

        $existing = $this->planningRepo->findById($planningId);
        if ($existing === null || (int) $existing['staff_id'] !== $staffId) {
            return Response::notFound('Planning not found', $request->traceId);
        }

        $this->planningRepo->delete($planningId);

        return Response::json(['success' => true, 'message' => 'Planning eliminato'], 200, $request->traceId);
    }

    /**
     * Verifica accesso allo staff.
     */
    private function hasStaffAccess(Request $request, int $staffId): bool
    {
        $staff = $this->staffRepo->findById($staffId);
        if ($staff === null) {
            return false;
        }

        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        // Superadmin ha accesso a tutto
        if ($this->userRepo->isSuperadmin((int) $userId)) {
            return true;
        }

        // Verifica accesso al business
        return $this->businessUserRepo->hasAccess(
            (int) $userId,
            (int) $staff['business_id'],
            false
        );
    }

    /**
     * Valida i dati del planning.
     */
    private function validatePlanningData(array $data, bool $isUpdate = false): array
    {
        $errors = [];

        if (!$isUpdate) {
            if (empty($data['type'])) {
                $errors[] = 'type è obbligatorio';
            } elseif (!in_array($data['type'], ['weekly', 'biweekly'])) {
                $errors[] = 'type deve essere weekly o biweekly';
            }

            if (empty($data['valid_from'])) {
                $errors[] = 'valid_from è obbligatorio';
            } elseif (!$this->isValidDate($data['valid_from'])) {
                $errors[] = 'valid_from deve essere in formato YYYY-MM-DD';
            }
        }

        if (isset($data['type']) && !in_array($data['type'], ['weekly', 'biweekly'])) {
            $errors[] = 'type deve essere weekly o biweekly';
        }

        if (isset($data['valid_from']) && !$this->isValidDate($data['valid_from'])) {
            $errors[] = 'valid_from deve essere in formato YYYY-MM-DD';
        }

        if (isset($data['valid_to']) && $data['valid_to'] !== null) {
            if (!$this->isValidDate($data['valid_to'])) {
                $errors[] = 'valid_to deve essere in formato YYYY-MM-DD';
            } elseif (isset($data['valid_from']) && $data['valid_to'] < $data['valid_from']) {
                $errors[] = 'valid_to deve essere >= valid_from';
            }
        }

        // Validazione templates
        if (isset($data['templates'])) {
            $type = $data['type'] ?? 'weekly';
            $hasA = false;
            $hasB = false;

            foreach ($data['templates'] as $template) {
                $label = strtolower($template['week_label'] ?? '');
                if ($label === 'a') $hasA = true;
                if ($label === 'b') $hasB = true;
            }

            if (!$hasA) {
                $errors[] = 'Template A è obbligatorio';
            }

            if ($type === 'biweekly' && !$hasB) {
                $errors[] = 'Template B è obbligatorio per pianificazione biweekly';
            }
        }

        return $errors;
    }

    /**
     * Salva i templates di un planning.
     */
    private function saveTemplates(int $planningId, array $templates): void
    {
        foreach ($templates as $template) {
            $weekLabel = $template['week_label'];
            $daySlots = $template['day_slots'] ?? [];

            // Supporta sia formato array di oggetti che formato mappa
            foreach ($daySlots as $key => $value) {
                // Formato array di oggetti: [{'day_of_week': 1, 'slots': [...]}]
                if (is_array($value) && isset($value['day_of_week'])) {
                    $dayOfWeek = (int) $value['day_of_week'];
                    $slots = $value['slots'] ?? [];
                } else {
                    // Formato mappa: {1: [...], 2: [...]}
                    $dayOfWeek = (int) $key;
                    $slots = $value;
                }
                
                if (is_array($slots) && !empty($slots)) {
                    $this->planningRepo->saveTemplate(
                        $planningId,
                        $weekLabel,
                        $dayOfWeek,
                        $slots
                    );
                }
            }
        }
    }

    /**
     * Verifica se una stringa è una data valida YYYY-MM-DD.
     */
    private function isValidDate(string $date): bool
    {
        $d = \DateTime::createFromFormat('Y-m-d', $date);
        return $d && $d->format('Y-m-d') === $date;
    }
}
