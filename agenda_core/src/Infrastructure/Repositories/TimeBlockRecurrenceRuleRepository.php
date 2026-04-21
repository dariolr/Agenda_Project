<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Domain\Booking\RecurrenceRule;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Support\Json;

/**
 * Repository per le regole di ricorrenza dei blocchi di non disponibilità.
 */
final class TimeBlockRecurrenceRuleRepository
{
    public function __construct(
        private readonly Connection $db
    ) {}

    /**
     * Crea una nuova regola di ricorrenza per blocchi.
     * Restituisce l'ID della regola creata.
     */
    public function create(RecurrenceRule $rule): int
    {
        $sql = <<<SQL
            INSERT INTO time_block_recurrence_rules (
                business_id, frequency, interval_value,
                max_occurrences, end_date, days_of_week, day_of_month
            ) VALUES (
                :business_id, :frequency, :interval_value,
                :max_occurrences, :end_date, :days_of_week, :day_of_month
            )
        SQL;

        $stmt = $this->db->getPdo()->prepare($sql);
        $stmt->execute([
            'business_id'     => $rule->businessId,
            'frequency'       => $rule->frequency,
            'interval_value'  => $rule->intervalValue,
            'max_occurrences' => $rule->maxOccurrences,
            'end_date'        => $rule->endDate?->format('Y-m-d'),
            'days_of_week'    => $rule->daysOfWeek !== null
                ? Json::encode($rule->daysOfWeek)
                : null,
            'day_of_month'    => $rule->dayOfMonth,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    /**
     * Trova una regola per ID.
     */
    public function findById(int $id): ?RecurrenceRule
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT * FROM time_block_recurrence_rules WHERE id = :id'
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch(\PDO::FETCH_ASSOC);

        return $row ? RecurrenceRule::fromArray($row) : null;
    }

    /**
     * Elimina una regola (i time_blocks collegati avranno recurrence_rule_id = NULL
     * solo se si aggiunge FK con SET NULL; altrimenti eliminare i blocchi prima).
     */
    public function delete(int $id): void
    {
        $this->db->getPdo()
            ->prepare('DELETE FROM time_block_recurrence_rules WHERE id = :id')
            ->execute(['id' => $id]);
    }
}
