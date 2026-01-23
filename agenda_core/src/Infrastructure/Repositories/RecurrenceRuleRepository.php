<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Domain\Booking\RecurrenceRule;
use Agenda\Infrastructure\Database\Connection;

/**
 * Repository per la gestione delle regole di ricorrenza.
 */
final class RecurrenceRuleRepository
{
    public function __construct(
        private readonly Connection $db
    ) {}

    /**
     * Crea una nuova regola di ricorrenza.
     */
    public function create(RecurrenceRule $rule): int
    {
        $sql = <<<SQL
            INSERT INTO booking_recurrence_rules (
                business_id, frequency, interval_value, max_occurrences, 
                end_date, conflict_strategy, days_of_week, day_of_month
            ) VALUES (
                :business_id, :frequency, :interval_value, :max_occurrences,
                :end_date, :conflict_strategy, :days_of_week, :day_of_month
            )
        SQL;

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute([
            'business_id' => $rule->businessId,
            'frequency' => $rule->frequency,
            'interval_value' => $rule->intervalValue,
            'max_occurrences' => $rule->maxOccurrences,
            'end_date' => $rule->endDate?->format('Y-m-d'),
            'conflict_strategy' => $rule->conflictStrategy,
            'days_of_week' => $rule->daysOfWeek !== null ? json_encode($rule->daysOfWeek) : null,
            'day_of_month' => $rule->dayOfMonth,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Trova una regola di ricorrenza per ID.
     */
    public function findById(int $id): ?RecurrenceRule
    {
        $sql = 'SELECT * FROM booking_recurrence_rules WHERE id = :id';
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute(['id' => $id]);

        $row = $stmt->fetch();
        if ($row === false) {
            return null;
        }

        return RecurrenceRule::fromArray($row);
    }

    /**
     * Trova tutte le regole di ricorrenza per un business.
     */
    public function findByBusinessId(int $businessId): array
    {
        $sql = 'SELECT * FROM booking_recurrence_rules WHERE business_id = :business_id ORDER BY created_at DESC';
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute(['business_id' => $businessId]);

        $rules = [];
        while ($row = $stmt->fetch()) {
            $rules[] = RecurrenceRule::fromArray($row);
        }

        return $rules;
    }

    /**
     * Aggiorna una regola di ricorrenza.
     */
    public function update(RecurrenceRule $rule): bool
    {
        if ($rule->id === null) {
            return false;
        }

        $sql = <<<SQL
            UPDATE booking_recurrence_rules SET
                frequency = :frequency,
                interval_value = :interval_value,
                max_occurrences = :max_occurrences,
                end_date = :end_date,
                conflict_strategy = :conflict_strategy,
                days_of_week = :days_of_week,
                day_of_month = :day_of_month,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = :id
        SQL;

        $stmt = $this->db->getPdo()->prepare($sql);
        return $stmt->execute([
            'id' => $rule->id,
            'frequency' => $rule->frequency,
            'interval_value' => $rule->intervalValue,
            'max_occurrences' => $rule->maxOccurrences,
            'end_date' => $rule->endDate?->format('Y-m-d'),
            'conflict_strategy' => $rule->conflictStrategy,
            'days_of_week' => $rule->daysOfWeek !== null ? json_encode($rule->daysOfWeek) : null,
            'day_of_month' => $rule->dayOfMonth,
        ]);
    }

    /**
     * Elimina una regola di ricorrenza.
     * Le booking collegate perderanno il riferimento (FK SET NULL).
     */
    public function delete(int $id): bool
    {
        $sql = 'DELETE FROM booking_recurrence_rules WHERE id = :id';
        $stmt = $this->db->getPdo()->prepare($sql);
        return $stmt->execute(['id' => $id]);
    }

    /**
     * Conta quante booking usano questa regola.
     */
    public function countBookingsByRuleId(int $ruleId): int
    {
        $sql = 'SELECT COUNT(*) FROM bookings WHERE recurrence_rule_id = :rule_id';
        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute(['rule_id' => $ruleId]);
        return (int) $stmt->fetchColumn();
    }
}
