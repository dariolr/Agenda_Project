<?php

declare(strict_types=1);

namespace Agenda\Domain\Booking;

use DateTimeImmutable;
use JsonSerializable;

/**
 * Regola di ricorrenza per prenotazioni ripetute.
 */
final class RecurrenceRule implements JsonSerializable
{
    public const FREQUENCY_DAILY = 'daily';
    public const FREQUENCY_WEEKLY = 'weekly';
    public const FREQUENCY_MONTHLY = 'monthly';
    public const FREQUENCY_CUSTOM = 'custom';

    public const CONFLICT_SKIP = 'skip';
    public const CONFLICT_FORCE = 'force';

    public function __construct(
        public readonly ?int $id,
        public readonly int $businessId,
        public readonly string $frequency,
        public readonly int $intervalValue,
        public readonly ?int $maxOccurrences,
        public readonly ?DateTimeImmutable $endDate,
        public readonly string $conflictStrategy,
        public readonly ?array $daysOfWeek = null,
        public readonly ?int $dayOfMonth = null,
        public readonly ?DateTimeImmutable $createdAt = null,
        public readonly ?DateTimeImmutable $updatedAt = null,
    ) {}

    /**
     * Crea da array (es. da database row).
     */
    public static function fromArray(array $data): self
    {
        return new self(
            id: isset($data['id']) ? (int) $data['id'] : null,
            businessId: (int) $data['business_id'],
            frequency: $data['frequency'],
            intervalValue: (int) ($data['interval_value'] ?? 1),
            maxOccurrences: isset($data['max_occurrences']) ? (int) $data['max_occurrences'] : null,
            endDate: isset($data['end_date']) ? new DateTimeImmutable($data['end_date']) : null,
            conflictStrategy: $data['conflict_strategy'] ?? self::CONFLICT_SKIP,
            daysOfWeek: isset($data['days_of_week'])
                ? json_decode($data['days_of_week'], true, 512, JSON_INVALID_UTF8_SUBSTITUTE)
                : null,
            dayOfMonth: isset($data['day_of_month']) ? (int) $data['day_of_month'] : null,
            createdAt: isset($data['created_at']) ? new DateTimeImmutable($data['created_at']) : null,
            updatedAt: isset($data['updated_at']) ? new DateTimeImmutable($data['updated_at']) : null,
        );
    }

    /**
     * Calcola tutte le date della serie a partire dalla data iniziale.
     *
     * @return DateTimeImmutable[]
     */
    public function calculateDates(DateTimeImmutable $startDate, int $maxLimit = 52): array
    {
        $dates = [$startDate];
        $current = $startDate;
        $count = 1;

        // Determina limite
        // Se maxOccurrences è specificato, usa quello (con cap a maxLimit per sicurezza)
        // Se non specificato (Mai), usa endDate o calcola fino a 1 anno dalla data iniziale
        if ($this->maxOccurrences !== null) {
            $limit = min($this->maxOccurrences, $maxLimit);
        } else {
            // "Mai" - calcola fino a 1 anno (o endDate se specificata)
            $limit = 365; // Limite massimo di sicurezza per evitare loop infiniti
        }
        
        // Calcola la data massima (1 anno dalla data iniziale se endDate non specificata)
        $maxEndDate = $this->endDate ?? $startDate->modify('+1 year');

        while ($count < $limit) {
            $next = $this->getNextDate($current);

            // Verifica end_date (o limite 1 anno)
            if ($next > $maxEndDate) {
                break;
            }

            $dates[] = $next;
            $current = $next;
            $count++;
        }

        return $dates;
    }

    /**
     * Calcola la prossima data in base alla frequenza.
     */
    private function getNextDate(DateTimeImmutable $current): DateTimeImmutable
    {
        return match ($this->frequency) {
            self::FREQUENCY_DAILY, self::FREQUENCY_CUSTOM => $current->modify("+{$this->intervalValue} days"),
            self::FREQUENCY_WEEKLY => $current->modify("+{$this->intervalValue} weeks"),
            self::FREQUENCY_MONTHLY => $this->getNextMonthlyDate($current),
            default => $current->modify("+{$this->intervalValue} days"),
        };
    }

    /**
     * Calcola la prossima data per ricorrenza mensile.
     * Gestisce il caso in cui il giorno del mese non esiste (es. 31 febbraio).
     */
    private function getNextMonthlyDate(DateTimeImmutable $current): DateTimeImmutable
    {
        $targetDay = $this->dayOfMonth ?? (int) $current->format('j');
        $next = $current->modify("+{$this->intervalValue} months");

        // Se il giorno target è maggiore dei giorni nel mese, usa l'ultimo giorno
        $daysInMonth = (int) $next->format('t');
        $actualDay = min($targetDay, $daysInMonth);

        return $next->setDate(
            (int) $next->format('Y'),
            (int) $next->format('n'),
            $actualDay
        );
    }

    /**
     * Verifica se la strategia è "salta conflitti".
     */
    public function shouldSkipConflicts(): bool
    {
        return $this->conflictStrategy === self::CONFLICT_SKIP;
    }

    /**
     * Verifica se la strategia è "forza creazione".
     */
    public function shouldForceCreation(): bool
    {
        return $this->conflictStrategy === self::CONFLICT_FORCE;
    }

    public function jsonSerialize(): array
    {
        return [
            'id' => $this->id,
            'business_id' => $this->businessId,
            'frequency' => $this->frequency,
            'interval_value' => $this->intervalValue,
            'max_occurrences' => $this->maxOccurrences,
            'end_date' => $this->endDate?->format('Y-m-d'),
            'conflict_strategy' => $this->conflictStrategy,
            'days_of_week' => $this->daysOfWeek,
            'day_of_month' => $this->dayOfMonth,
            'created_at' => $this->createdAt?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updatedAt?->format('Y-m-d H:i:s'),
        ];
    }
}
