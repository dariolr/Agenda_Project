<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Support\Json;

/**
 * Repository per staff planning settimanale/bisettimanale.
 * 
 * Gestisce:
 * - staff_planning: pianificazioni con intervalli [valid_from, valid_to]
 * - staff_planning_week_template: template settimanali (A/B per biweekly)
 */
final class StaffPlanningRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    /**
     * Trova tutti i planning per uno staff.
     */
    public function findByStaffId(int $staffId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, staff_id, type, valid_from, valid_to, created_at, updated_at
             FROM staff_planning
             WHERE staff_id = ?
             ORDER BY valid_from ASC'
        );
        $stmt->execute([$staffId]);
        $plannings = $stmt->fetchAll();

        foreach ($plannings as &$planning) {
            $planning['templates'] = $this->getTemplates((int) $planning['id']);
        }

        return $plannings;
    }

    /**
     * Trova un planning per ID.
     */
    public function findById(int $planningId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, staff_id, type, valid_from, valid_to, created_at, updated_at
             FROM staff_planning
             WHERE id = ?'
        );
        $stmt->execute([$planningId]);
        $planning = $stmt->fetch();

        if (!$planning) {
            return null;
        }

        $planning['templates'] = $this->getTemplates((int) $planning['id']);

        return $planning;
    }

    /**
     * Trova il planning valido per uno staff in una data specifica.
     * 
     * Intervallo chiuso-chiuso: [valid_from, valid_to].
     * valid_to = NULL significa "senza scadenza".
     * 
     * @return array|null Il planning trovato, o null se nessuno valido.
     * @throws \RuntimeException Se più planning sono validi (errore di consistenza).
     */
    public function findValidForDate(int $staffId, string $date): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, staff_id, type, valid_from, valid_to, created_at, updated_at
             FROM staff_planning
             WHERE staff_id = ?
               AND valid_from <= ?
               AND (valid_to IS NULL OR valid_to >= ?)
             ORDER BY valid_from ASC'
        );
        $stmt->execute([$staffId, $date, $date]);
        $plannings = $stmt->fetchAll();

        if (count($plannings) === 0) {
            return null;
        }

        if (count($plannings) > 1) {
            throw new \RuntimeException(
                "Errore di consistenza: trovati " . count($plannings) . 
                " planning validi per staff $staffId in data $date"
            );
        }

        $planning = $plannings[0];
        $planning['templates'] = $this->getTemplates((int) $planning['id']);

        return $planning;
    }

    /**
     * Trova tutti i planning validi per uno staff in un range di date.
     */
    public function findValidForRange(int $staffId, string $startDate, string $endDate): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, staff_id, type, valid_from, valid_to, created_at, updated_at
             FROM staff_planning
             WHERE staff_id = ?
               AND valid_from <= ?
               AND (valid_to IS NULL OR valid_to >= ?)
             ORDER BY valid_from ASC'
        );
        $stmt->execute([$staffId, $endDate, $startDate]);
        $plannings = $stmt->fetchAll();

        foreach ($plannings as &$planning) {
            $planning['templates'] = $this->getTemplates((int) $planning['id']);
        }

        return $plannings;
    }

    /**
     * Ottiene i template settimanali per un planning.
     */
    private function getTemplates(int $planningId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, staff_planning_id, week_label, day_of_week, slots
             FROM staff_planning_week_template
             WHERE staff_planning_id = ?
             ORDER BY week_label ASC, day_of_week ASC'
        );
        $stmt->execute([$planningId]);
        $rows = $stmt->fetchAll();

        $templates = [];
        foreach ($rows as $row) {
            $weekLabel = strtolower($row['week_label']);
            
            if (!isset($templates[$weekLabel])) {
                $templates[$weekLabel] = [
                    'id' => (int) $row['id'],
                    'staff_planning_id' => (int) $row['staff_planning_id'],
                    'week_label' => $weekLabel,
                    'day_slots' => [],
                ];
            }

            $dayOfWeek = (int) $row['day_of_week'];
            $slots = Json::decodeAssoc((string) $row['slots']) ?? [];
            $templates[$weekLabel]['day_slots'][$dayOfWeek] = $slots;
        }

        return array_values($templates);
    }

    /**
     * Calcola la week label (A/B) per una data in un planning biweekly.
     * 
     * week_index = floor(delta_days / 7)
     * pari → A, dispari → B
     */
    public function computeWeekLabel(string $validFrom, string $date): string
    {
        $from = new \DateTime($validFrom);
        $target = new \DateTime($date);
        
        $deltaDays = (int) $from->diff($target)->days;
        $weekIndex = intdiv($deltaDays, 7);

        return ($weekIndex % 2 === 0) ? 'a' : 'b';
    }

    /**
     * Ottiene gli slot disponibili per uno staff in una data.
     * 
     * @return array|null Array di slot index, o null se nessun planning valido.
     * @throws \RuntimeException Se più planning sono validi.
     */
    public function getSlotsForDate(int $staffId, string $date): ?array
    {
        $planning = $this->findValidForDate($staffId, $date);
        
        if ($planning === null) {
            return null;
        }

        $dayOfWeek = (int) (new \DateTime($date))->format('N'); // 1-7 (Mon-Sun)

        // Determina quale template usare
        $weekLabel = 'a';
        if ($planning['type'] === 'biweekly') {
            $weekLabel = $this->computeWeekLabel($planning['valid_from'], $date);
        }

        // Trova il template corretto
        foreach ($planning['templates'] as $template) {
            if ($template['week_label'] === $weekLabel) {
                return $template['day_slots'][$dayOfWeek] ?? [];
            }
        }

        return [];
    }

    /**
     * Verifica se uno staff è disponibile (ha slot) in una data.
     */
    public function isStaffAvailable(int $staffId, string $date): bool
    {
        $slots = $this->getSlotsForDate($staffId, $date);
        return $slots !== null && count($slots) > 0;
    }

    /**
     * Crea un nuovo planning.
     * 
     * @return int L'ID del planning creato.
     */
    public function create(array $data): int
    {
        $pdo = $this->db->getPdo();
        
        $stmt = $pdo->prepare(
            'INSERT INTO staff_planning (staff_id, type, valid_from, valid_to, created_at)
             VALUES (?, ?, ?, ?, NOW())'
        );
        $stmt->execute([
            $data['staff_id'],
            $data['type'],
            $data['valid_from'],
            $data['valid_to'] ?? null,
        ]);

        return (int) $pdo->lastInsertId();
    }

    /**
     * Aggiorna un planning esistente.
     */
    public function update(int $planningId, array $data): bool
    {
        $fields = [];
        $values = [];

        if (isset($data['type'])) {
            $fields[] = 'type = ?';
            $values[] = $data['type'];
        }
        if (isset($data['valid_from'])) {
            $fields[] = 'valid_from = ?';
            $values[] = $data['valid_from'];
        }
        if (array_key_exists('valid_to', $data)) {
            $fields[] = 'valid_to = ?';
            $values[] = $data['valid_to'];
        }
        if (empty($fields)) {
            return false;
        }

        $fields[] = 'updated_at = NOW()';
        $values[] = $planningId;

        $stmt = $this->db->getPdo()->prepare(
            'UPDATE staff_planning SET ' . implode(', ', $fields) . ' WHERE id = ?'
        );
        
        return $stmt->execute($values);
    }

    /**
     * Elimina un planning.
     */
    public function delete(int $planningId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM staff_planning WHERE id = ?'
        );
        return $stmt->execute([$planningId]);
    }

    /**
     * Salva un template settimanale (inserisce o aggiorna).
     */
    public function saveTemplate(int $planningId, string $weekLabel, int $dayOfWeek, array $slots): void
    {
        $pdo = $this->db->getPdo();
        
        // Prova UPDATE prima
        $stmt = $pdo->prepare(
            'UPDATE staff_planning_week_template
             SET slots = ?
             WHERE staff_planning_id = ? AND week_label = ? AND day_of_week = ?'
        );
        $stmt->execute([
            Json::encode($slots),
            $planningId,
            strtoupper($weekLabel),
            $dayOfWeek
        ]);

        if ($stmt->rowCount() === 0) {
            // Nessuna riga aggiornata, fai INSERT
            $stmt = $pdo->prepare(
                'INSERT INTO staff_planning_week_template (staff_planning_id, week_label, day_of_week, slots)
                 VALUES (?, ?, ?, ?)'
            );
            $stmt->execute([
                $planningId,
                strtoupper($weekLabel),
                $dayOfWeek,
                Json::encode($slots)
            ]);
        }
    }

    /**
     * Elimina tutti i template di un planning.
     */
    public function deleteTemplates(int $planningId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM staff_planning_week_template WHERE staff_planning_id = ?'
        );
        return $stmt->execute([$planningId]);
    }

    /**
     * Verifica sovrapposizione con altri planning dello stesso staff.
     * 
     * Intervalli chiusi-chiusi: [valid_from, valid_to] si sovrappongono se
     * hanno almeno un giorno in comune.
     * 
     * @param int|null $excludePlanningId ID del planning da escludere (per update).
     */
    public function hasOverlap(
        int $staffId,
        string $validFrom,
        ?string $validTo,
        ?int $excludePlanningId = null
    ): bool {
        $overlapping = $this->findOverlapping($staffId, $validFrom, $validTo, $excludePlanningId);
        return count($overlapping) > 0;
    }

    /**
     * Trova tutti i planning sovrapposti per uno staff in un intervallo.
     * 
     * @return array Array di planning sovrapposti con i loro templates.
     */
    public function findOverlapping(
        int $staffId,
        string $validFrom,
        ?string $validTo,
        ?int $excludePlanningId = null
    ): array {
        $sql = 'SELECT id, staff_id, type, valid_from, valid_to, created_at, updated_at
                FROM staff_planning WHERE staff_id = ?';
        $params = [$staffId];

        if ($excludePlanningId !== null) {
            $sql .= ' AND id != ?';
            $params[] = $excludePlanningId;
        }

        // Condizione di sovrapposizione per intervalli chiusi-chiusi:
        // [A_from, A_to] e [B_from, B_to] si sovrappongono se:
        // A_from <= B_to AND A_to >= B_from
        
        if ($validTo === null) {
            // Nuovo planning senza scadenza
            $sql .= ' AND (valid_to IS NULL OR valid_to >= ?)';
            $params[] = $validFrom;
        } else {
            // Nuovo planning con scadenza
            $sql .= ' AND valid_from <= ? AND (valid_to IS NULL OR valid_to >= ?)';
            $params[] = $validTo;
            $params[] = $validFrom;
        }

        $sql .= ' ORDER BY valid_from ASC';

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute($params);
        $plannings = $stmt->fetchAll();

        foreach ($plannings as &$planning) {
            $planning['templates'] = $this->getTemplates((int) $planning['id']);
        }

        return $plannings;
    }

    /**
     * Duplica un planning con nuove date di validità.
     * Copia tutti i templates.
     * 
     * @return int ID del nuovo planning creato.
     */
    public function duplicate(int $planningId, string $newValidFrom, ?string $newValidTo): int
    {
        $original = $this->findById($planningId);
        if ($original === null) {
            throw new \InvalidArgumentException("Planning $planningId not found");
        }

        // Crea nuovo planning
        $newId = $this->create([
            'staff_id' => $original['staff_id'],
            'type' => $original['type'],
            'valid_from' => $newValidFrom,
            'valid_to' => $newValidTo,
        ]);

        // Copia templates
        foreach ($original['templates'] as $template) {
            $weekLabel = $template['week_label'];
            $daySlots = $template['day_slots'] ?? [];
            
            foreach ($daySlots as $dayOfWeek => $slots) {
                if (!empty($slots)) {
                    $this->saveTemplate($newId, $weekLabel, (int) $dayOfWeek, $slots);
                }
            }
        }

        return $newId;
    }
}
