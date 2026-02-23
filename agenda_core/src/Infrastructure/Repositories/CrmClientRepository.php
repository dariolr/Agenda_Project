<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Repositories;

use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Support\Json;
use PDO;

final class CrmClientRepository
{
    public function __construct(
        private readonly Connection $db,
    ) {}

    public function db(): Connection
    {
        return $this->db;
    }

    public function clientExistsInBusiness(int $businessId, int $clientId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT 1 FROM clients WHERE business_id = ? AND id = ? LIMIT 1'
        );
        $stmt->execute([$businessId, $clientId]);

        return (bool) $stmt->fetchColumn();
    }

    public function listClients(int $businessId, array $filters): array
    {
        $limit = max(1, min(100, (int) ($filters['page_size'] ?? 20)));
        $page = max(1, (int) ($filters['page'] ?? 1));
        $offset = ($page - 1) * $limit;

        $where = ['c.business_id = ?'];
        $params = [$businessId];

        $q = trim((string) ($filters['q'] ?? ''));
        if ($q !== '') {
            $like = '%' . $q . '%';
            $where[] = '(c.first_name LIKE ? OR c.last_name LIKE ? OR c.email LIKE ? OR c.phone LIKE ? OR c.city LIKE ? OR c.notes LIKE ?)';
            array_push($params, $like, $like, $like, $like, $like, $like);
        }

        if (isset($filters['status']) && $filters['status'] !== '') {
            $where[] = 'c.status = ?';
            $params[] = $filters['status'];
        }

        if (isset($filters['is_archived']) && $filters['is_archived'] !== '') {
            $where[] = 'c.is_archived = ?';
            $params[] = (int) ((string) $filters['is_archived'] === '1' || (string) $filters['is_archived'] === 'true');
        }

        if (isset($filters['birthday_month']) && $filters['birthday_month'] !== '') {
            $where[] = 'MONTH(c.birth_date) = ?';
            $params[] = (int) $filters['birthday_month'];
        }

        if (isset($filters['marketing_opt_in']) && $filters['marketing_opt_in'] !== '') {
            $where[] = 'COALESCE(cc.marketing_opt_in, 0) = ?';
            $params[] = (int) ((string) $filters['marketing_opt_in'] === '1' || (string) $filters['marketing_opt_in'] === 'true');
        }

        if (isset($filters['profiling_opt_in']) && $filters['profiling_opt_in'] !== '') {
            $where[] = 'COALESCE(cc.profiling_opt_in, 0) = ?';
            $params[] = (int) ((string) $filters['profiling_opt_in'] === '1' || (string) $filters['profiling_opt_in'] === 'true');
        }

        if (isset($filters['last_visit_from']) && $filters['last_visit_from'] !== '') {
            $where[] = 'COALESCE(k.last_visit, c.last_visit) >= ?';
            $params[] = $filters['last_visit_from'] . ' 00:00:00';
        }

        if (isset($filters['last_visit_to']) && $filters['last_visit_to'] !== '') {
            $where[] = 'COALESCE(k.last_visit, c.last_visit) <= ?';
            $params[] = $filters['last_visit_to'] . ' 23:59:59';
        }

        if (isset($filters['spent_from']) && $filters['spent_from'] !== '') {
            $where[] = 'COALESCE(k.total_spent, 0) >= ?';
            $params[] = (float) $filters['spent_from'];
        }

        if (isset($filters['spent_to']) && $filters['spent_to'] !== '') {
            $where[] = 'COALESCE(k.total_spent, 0) <= ?';
            $params[] = (float) $filters['spent_to'];
        }

        if (isset($filters['visits_from']) && $filters['visits_from'] !== '') {
            $where[] = 'COALESCE(k.visits_count, 0) >= ?';
            $params[] = (int) $filters['visits_from'];
        }

        if (isset($filters['visits_to']) && $filters['visits_to'] !== '') {
            $where[] = 'COALESCE(k.visits_count, 0) <= ?';
            $params[] = (int) $filters['visits_to'];
        }

        $tagIds = $this->csvToIntList((string) ($filters['tag_ids'] ?? ''));
        if ($tagIds !== []) {
            $in = implode(',', array_fill(0, count($tagIds), '?'));
            $where[] = "EXISTS (
                SELECT 1
                FROM client_tag_links ctl
                WHERE ctl.business_id = c.business_id
                  AND ctl.client_id = c.id
                  AND ctl.tag_id IN ($in)
            )";
            array_push($params, ...$tagIds);
        }

        $tagNames = $this->csvToStringList((string) ($filters['tag_names'] ?? ''));
        if ($tagNames !== []) {
            $in = implode(',', array_fill(0, count($tagNames), '?'));
            $where[] = "EXISTS (
                SELECT 1
                FROM client_tag_links ctl
                JOIN client_tags ct ON ct.id = ctl.tag_id AND ct.business_id = ctl.business_id
                WHERE ctl.business_id = c.business_id
                  AND ctl.client_id = c.id
                  AND LOWER(ct.name) IN ($in)
            )";
            array_push($params, ...array_map('strtolower', $tagNames));
        }

        $whereSql = implode(' AND ', $where);
        $orderBy = $this->clientSortToSql((string) ($filters['sort'] ?? 'last_visit_desc'));

        $kpiJoin = "LEFT JOIN (
            SELECT
                b.business_id,
                b.client_id,
                COUNT(DISTINCT b.id) AS visits_count,
                COALESCE(SUM(CASE WHEN b.status = 'completed' THEN bi.price ELSE 0 END), 0) AS total_spent,
                MAX(CASE WHEN b.status = 'completed' THEN bi.end_time ELSE NULL END) AS last_visit,
                SUM(CASE WHEN b.status = 'no_show' THEN 1 ELSE 0 END) AS no_show_count
            FROM bookings b
            LEFT JOIN booking_items bi ON bi.booking_id = b.id
            WHERE b.business_id = ? AND b.client_id IS NOT NULL
            GROUP BY b.business_id, b.client_id
        ) k ON k.business_id = c.business_id AND k.client_id = c.id";

        $sql = "
            SELECT
                c.id,
                c.business_id,
                c.first_name,
                c.last_name,
                c.email,
                c.phone,
                c.gender,
                c.birth_date,
                c.city,
                c.address_city,
                c.notes,
                c.status,
                c.source,
                c.company_name,
                c.vat_number,
                c.loyalty_points,
                c.is_archived,
                c.tags,
                c.created_at,
                c.updated_at,
                c.deleted_at,
                COALESCE(k.total_spent, 0) AS total_spent,
                COALESCE(k.visits_count, 0) AS visits_count,
                CASE WHEN COALESCE(k.visits_count, 0) > 0 THEN COALESCE(k.total_spent, 0) / k.visits_count ELSE 0 END AS avg_ticket,
                COALESCE(k.last_visit, c.last_visit) AS last_visit,
                COALESCE(k.no_show_count, 0) AS no_show_count,
                COALESCE(cc.marketing_opt_in, 0) AS marketing_opt_in,
                COALESCE(cc.profiling_opt_in, 0) AS profiling_opt_in,
                COALESCE(cc.preferred_channel, 'none') AS preferred_channel
            FROM clients c
            $kpiJoin
            LEFT JOIN client_consents cc ON cc.business_id = c.business_id AND cc.client_id = c.id
            WHERE $whereSql
            ORDER BY $orderBy
            LIMIT ? OFFSET ?
        ";

        $stmt = $this->db->getPdo()->prepare($sql);
        $queryParams = [$businessId, ...$params, $limit, $offset];
        $stmt->execute($queryParams);
        $rows = $stmt->fetchAll();

        $countSql = "
            SELECT COUNT(*)
            FROM clients c
            $kpiJoin
            LEFT JOIN client_consents cc ON cc.business_id = c.business_id AND cc.client_id = c.id
            WHERE $whereSql
        ";
        $countStmt = $this->db->getPdo()->prepare($countSql);
        $countStmt->execute([$businessId, ...$params]);
        $total = (int) $countStmt->fetchColumn();

        $clientIds = array_map(static fn(array $row): int => (int) $row['id'], $rows);
        $tagsMap = $this->getTagNamesByClientIds($businessId, $clientIds);

        $clients = array_map(function (array $row) use ($tagsMap): array {
            $clientId = (int) $row['id'];
            return $this->hydrateClientRow($row, $tagsMap[$clientId] ?? []);
        }, $rows);

        return [
            'clients' => $clients,
            'page' => $page,
            'page_size' => $limit,
            'total' => $total,
            'has_more' => ($offset + count($clients)) < $total,
        ];
    }

    public function getClient(int $businessId, int $clientId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT
                c.*,
                COALESCE(k.total_spent, 0) AS total_spent,
                COALESCE(k.visits_count, 0) AS visits_count,
                CASE WHEN COALESCE(k.visits_count, 0) > 0 THEN COALESCE(k.total_spent, 0) / k.visits_count ELSE 0 END AS avg_ticket,
                COALESCE(k.last_visit, c.last_visit) AS last_visit,
                COALESCE(k.no_show_count, 0) AS no_show_count
             FROM clients c
             LEFT JOIN (
                SELECT
                    b.business_id,
                    b.client_id,
                    COUNT(DISTINCT b.id) AS visits_count,
                    COALESCE(SUM(CASE WHEN b.status = \'completed\' THEN bi.price ELSE 0 END), 0) AS total_spent,
                    MAX(CASE WHEN b.status = \'completed\' THEN bi.end_time ELSE NULL END) AS last_visit,
                    SUM(CASE WHEN b.status = \'no_show\' THEN 1 ELSE 0 END) AS no_show_count
                FROM bookings b
                LEFT JOIN booking_items bi ON bi.booking_id = b.id
                WHERE b.business_id = ? AND b.client_id IS NOT NULL
                GROUP BY b.business_id, b.client_id
             ) k ON k.business_id = c.business_id AND k.client_id = c.id
             WHERE c.business_id = ? AND c.id = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, $businessId, $clientId]);
        $row = $stmt->fetch();
        if (!$row) {
            return null;
        }

        $tags = $this->getTagNamesByClientIds($businessId, [$clientId])[$clientId] ?? [];

        return $this->loadClientDetail($businessId, $clientId, $this->hydrateClientRow($row, $tags));
    }

    public function createClient(int $businessId, array $data): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO clients (
                business_id, first_name, last_name, email, phone, gender, birth_date,
                city, address_city, notes, status, source, company_name, vat_number,
                is_archived
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );

        $stmt->execute([
            $businessId,
            $this->nullableString($data['first_name'] ?? null),
            $this->nullableString($data['last_name'] ?? null),
            $this->nullableString($data['email'] ?? null),
            $this->nullableString($data['phone'] ?? null),
            $this->nullableString($data['gender'] ?? null),
            $this->nullableDate($data['birth_date'] ?? null),
            $this->nullableString($data['city'] ?? null),
            $this->nullableString($data['address_city'] ?? null),
            $this->nullableString($data['notes'] ?? null),
            $this->nullableString($data['status'] ?? null) ?? 'active',
            $this->nullableString($data['source'] ?? null),
            $this->nullableString($data['company_name'] ?? null),
            $this->nullableString($data['vat_number'] ?? null),
            (int) (($data['is_archived'] ?? false) ? 1 : 0),
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function updateClientPartial(int $businessId, int $clientId, array $data): bool
    {
        $allowed = [
            'first_name',
            'last_name',
            'email',
            'phone',
            'gender',
            'birth_date',
            'city',
            'address_city',
            'notes',
            'status',
            'source',
            'company_name',
            'vat_number',
            'is_archived',
            'deleted_at',
        ];

        $fields = [];
        $values = [];

        foreach ($allowed as $field) {
            if (!array_key_exists($field, $data)) {
                continue;
            }

            $fields[] = "$field = ?";
            if ($field === 'is_archived') {
                $values[] = (int) ((bool) $data[$field]);
            } elseif ($field === 'birth_date') {
                $values[] = $this->nullableDate($data[$field]);
            } else {
                $values[] = $this->nullableString($data[$field]);
            }
        }

        if ($fields === []) {
            return false;
        }

        $values[] = $businessId;
        $values[] = $clientId;

        $stmt = $this->db->getPdo()->prepare(
            'UPDATE clients SET ' . implode(', ', $fields) . ', updated_at = NOW() WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute($values);
    }

    public function setArchived(int $businessId, int $clientId, bool $archived): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE clients SET is_archived = ?, updated_at = NOW() WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute([(int) $archived, $businessId, $clientId]);
    }

    public function getConsents(int $businessId, int $clientId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT marketing_opt_in, profiling_opt_in, preferred_channel, updated_by_user_id, updated_at, source
             FROM client_consents
             WHERE business_id = ? AND client_id = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, $clientId]);
        $row = $stmt->fetch();

        if (!$row) {
            return [
                'marketing_opt_in' => false,
                'profiling_opt_in' => false,
                'preferred_channel' => 'none',
                'updated_by_user_id' => null,
                'updated_at' => null,
                'source' => null,
            ];
        }

        return [
            'marketing_opt_in' => (bool) $row['marketing_opt_in'],
            'profiling_opt_in' => (bool) $row['profiling_opt_in'],
            'preferred_channel' => (string) $row['preferred_channel'],
            'updated_by_user_id' => $row['updated_by_user_id'] !== null ? (int) $row['updated_by_user_id'] : null,
            'updated_at' => $row['updated_at'],
            'source' => $row['source'],
        ];
    }

    public function upsertConsents(int $businessId, int $clientId, int $userId, array $data): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO client_consents (
                business_id, client_id, marketing_opt_in, profiling_opt_in, preferred_channel,
                updated_by_user_id, source
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                marketing_opt_in = VALUES(marketing_opt_in),
                profiling_opt_in = VALUES(profiling_opt_in),
                preferred_channel = VALUES(preferred_channel),
                updated_by_user_id = VALUES(updated_by_user_id),
                source = VALUES(source),
                updated_at = CURRENT_TIMESTAMP'
        );

        $stmt->execute([
            $businessId,
            $clientId,
            (int) ((bool) ($data['marketing_opt_in'] ?? false)),
            (int) ((bool) ($data['profiling_opt_in'] ?? false)),
            $this->sanitizePreferredChannel((string) ($data['preferred_channel'] ?? 'none')),
            $userId,
            $this->nullableString($data['source'] ?? 'backend-operator') ?? 'backend-operator',
        ]);
    }

    public function listTags(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, business_id, name, color, created_at
             FROM client_tags
             WHERE business_id = ?
             ORDER BY name ASC'
        );
        $stmt->execute([$businessId]);

        return array_map(static function (array $row): array {
            return [
                'id' => (int) $row['id'],
                'business_id' => (int) $row['business_id'],
                'name' => $row['name'],
                'color' => $row['color'],
                'created_at' => $row['created_at'],
            ];
        }, $stmt->fetchAll());
    }

    public function createTag(int $businessId, string $name, ?string $color = null): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO client_tags (business_id, name, color) VALUES (?, ?, ?)' 
        );
        $stmt->execute([$businessId, trim($name), $this->nullableString($color)]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function deleteTag(int $businessId, int $tagId, bool $force = false): bool
    {
        if (!$force) {
            $check = $this->db->getPdo()->prepare(
                'SELECT 1 FROM client_tag_links WHERE business_id = ? AND tag_id = ? LIMIT 1'
            );
            $check->execute([$businessId, $tagId]);
            if ($check->fetchColumn()) {
                return false;
            }
        } else {
            $unlink = $this->db->getPdo()->prepare(
                'DELETE FROM client_tag_links WHERE business_id = ? AND tag_id = ?'
            );
            $unlink->execute([$businessId, $tagId]);
        }

        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM client_tags WHERE business_id = ? AND id = ?'
        );

        return $stmt->execute([$businessId, $tagId]);
    }

    public function replaceClientTags(int $businessId, int $clientId, array $tagIds): void
    {
        $this->db->beginTransaction();
        try {
            $delete = $this->db->getPdo()->prepare(
                'DELETE FROM client_tag_links WHERE business_id = ? AND client_id = ?'
            );
            $delete->execute([$businessId, $clientId]);

            $insert = $this->db->getPdo()->prepare(
                'INSERT IGNORE INTO client_tag_links (business_id, client_id, tag_id) VALUES (?, ?, ?)'
            );
            foreach ($tagIds as $tagId) {
                $insert->execute([$businessId, $clientId, $tagId]);
            }

            $this->syncLegacyTagsJson($businessId, $clientId);
            $this->db->commit();
        } catch (\Throwable $e) {
            $this->db->rollback();
            throw $e;
        }
    }

    public function addClientTag(int $businessId, int $clientId, int $tagId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT IGNORE INTO client_tag_links (business_id, client_id, tag_id) VALUES (?, ?, ?)'
        );
        $stmt->execute([$businessId, $clientId, $tagId]);
        $this->syncLegacyTagsJson($businessId, $clientId);
    }

    public function removeClientTag(int $businessId, int $clientId, int $tagId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM client_tag_links WHERE business_id = ? AND client_id = ? AND tag_id = ?'
        );
        $stmt->execute([$businessId, $clientId, $tagId]);
        $this->syncLegacyTagsJson($businessId, $clientId);
    }

    public function listEvents(int $businessId, int $clientId, int $page, int $pageSize): array
    {
        $limit = max(1, min(100, $pageSize));
        $offset = max(0, ($page - 1) * $limit);

        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, event_type, payload, occurred_at, created_by_user_id, created_at
             FROM client_events
             WHERE business_id = ? AND client_id = ?
             ORDER BY occurred_at DESC, id DESC
             LIMIT ? OFFSET ?'
        );
        $stmt->execute([$businessId, $clientId, $limit, $offset]);

        $countStmt = $this->db->getPdo()->prepare(
            'SELECT COUNT(*) FROM client_events WHERE business_id = ? AND client_id = ?'
        );
        $countStmt->execute([$businessId, $clientId]);
        $total = (int) $countStmt->fetchColumn();

        $events = array_map(static function (array $row): array {
            return [
                'id' => (int) $row['id'],
                'event_type' => $row['event_type'],
                'payload' => Json::decodeAssoc((string) ($row['payload'] ?? 'null')),
                'occurred_at' => $row['occurred_at'],
                'created_by_user_id' => $row['created_by_user_id'] !== null ? (int) $row['created_by_user_id'] : null,
                'created_at' => $row['created_at'],
            ];
        }, $stmt->fetchAll());

        return [
            'events' => $events,
            'page' => $page,
            'page_size' => $limit,
            'total' => $total,
            'has_more' => ($offset + count($events)) < $total,
        ];
    }

    public function createManualEvent(int $businessId, int $clientId, int $userId, string $eventType, ?array $payload = null): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO client_events (business_id, client_id, event_type, payload, occurred_at, created_by_user_id)
             VALUES (?, ?, ?, ?, NOW(), ?)'
        );

        $stmt->execute([
            $businessId,
            $clientId,
            $eventType,
            $payload !== null ? Json::encode($payload) : null,
            $userId,
        ]);

        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function listTasks(int $businessId, int $clientId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, client_id, assigned_staff_id, title, description, due_at, status, priority,
                    created_by_user_id, created_at, updated_at, completed_at,
                    CASE WHEN status = "open" AND due_at IS NOT NULL AND due_at < NOW() THEN 1 ELSE 0 END AS is_overdue
             FROM client_tasks
             WHERE business_id = ? AND client_id = ?
             ORDER BY (status = "open") DESC, due_at ASC, id DESC'
        );
        $stmt->execute([$businessId, $clientId]);

        return array_map(static function (array $row): array {
            return [
                'id' => (int) $row['id'],
                'client_id' => (int) $row['client_id'],
                'assigned_staff_id' => $row['assigned_staff_id'] !== null ? (int) $row['assigned_staff_id'] : null,
                'title' => $row['title'],
                'description' => $row['description'],
                'due_at' => $row['due_at'],
                'status' => $row['status'],
                'priority' => $row['priority'],
                'created_by_user_id' => (int) $row['created_by_user_id'],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at'],
                'completed_at' => $row['completed_at'],
                'is_overdue' => (bool) $row['is_overdue'],
            ];
        }, $stmt->fetchAll());
    }

    public function createTask(int $businessId, int $clientId, int $userId, array $data): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO client_tasks (
                business_id, client_id, assigned_staff_id, title, description, due_at,
                status, priority, created_by_user_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );

        $stmt->execute([
            $businessId,
            $clientId,
            $data['assigned_staff_id'] ?? null,
            trim((string) ($data['title'] ?? '')),
            $this->nullableString($data['description'] ?? null),
            $this->nullableDateTime($data['due_at'] ?? null),
            $this->sanitizeTaskStatus((string) ($data['status'] ?? 'open')),
            $this->sanitizeTaskPriority((string) ($data['priority'] ?? 'medium')),
            $userId,
        ]);

        $taskId = (int) $this->db->getPdo()->lastInsertId();
        $this->createManualEvent($businessId, $clientId, $userId, 'task', [
            'action' => 'created',
            'task_id' => $taskId,
            'title' => trim((string) ($data['title'] ?? '')),
        ]);

        return $taskId;
    }

    public function updateTask(int $businessId, int $clientId, int $taskId, array $data): bool
    {
        $allowed = ['assigned_staff_id', 'title', 'description', 'due_at', 'status', 'priority'];
        $fields = [];
        $values = [];

        foreach ($allowed as $field) {
            if (!array_key_exists($field, $data)) {
                continue;
            }

            $fields[] = "$field = ?";
            if ($field === 'status') {
                $values[] = $this->sanitizeTaskStatus((string) $data[$field]);
            } elseif ($field === 'priority') {
                $values[] = $this->sanitizeTaskPriority((string) $data[$field]);
            } elseif ($field === 'due_at') {
                $values[] = $this->nullableDateTime($data[$field]);
            } elseif ($field === 'assigned_staff_id') {
                $values[] = $data[$field] !== null ? (int) $data[$field] : null;
            } elseif ($field === 'title') {
                $values[] = trim((string) $data[$field]);
            } else {
                $values[] = $this->nullableString($data[$field]);
            }
        }

        if ($fields === []) {
            return false;
        }

        if (array_key_exists('status', $data)) {
            $status = $this->sanitizeTaskStatus((string) $data['status']);
            if ($status === 'done') {
                $fields[] = 'completed_at = NOW()';
            }
            if ($status === 'open') {
                $fields[] = 'completed_at = NULL';
            }
        }

        $values[] = $businessId;
        $values[] = $clientId;
        $values[] = $taskId;

        $stmt = $this->db->getPdo()->prepare(
            'UPDATE client_tasks
             SET ' . implode(', ', $fields) . ', updated_at = NOW()
             WHERE business_id = ? AND client_id = ? AND id = ?'
        );

        return $stmt->execute($values);
    }

    public function markTaskStatus(int $businessId, int $clientId, int $taskId, string $status): bool
    {
        $status = $this->sanitizeTaskStatus($status);
        $completedAtSql = $status === 'done' ? 'NOW()' : 'NULL';

        $stmt = $this->db->getPdo()->prepare(
            "UPDATE client_tasks
             SET status = ?, completed_at = $completedAtSql, updated_at = NOW()
             WHERE business_id = ? AND client_id = ? AND id = ?"
        );

        return $stmt->execute([$status, $businessId, $clientId, $taskId]);
    }

    public function getLoyalty(int $businessId, int $clientId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT loyalty_points FROM clients WHERE business_id = ? AND id = ? LIMIT 1'
        );
        $stmt->execute([$businessId, $clientId]);
        $points = (int) ($stmt->fetchColumn() ?: 0);

        $ledgerStmt = $this->db->getPdo()->prepare(
            'SELECT id, delta_points, reason, ref_type, ref_id, created_by_user_id, created_at
             FROM client_loyalty_ledger
             WHERE business_id = ? AND client_id = ?
             ORDER BY id DESC
             LIMIT 200'
        );
        $ledgerStmt->execute([$businessId, $clientId]);

        $ledger = array_map(static function (array $row): array {
            return [
                'id' => (int) $row['id'],
                'delta_points' => (int) $row['delta_points'],
                'reason' => $row['reason'],
                'ref_type' => $row['ref_type'],
                'ref_id' => $row['ref_id'] !== null ? (int) $row['ref_id'] : null,
                'created_by_user_id' => $row['created_by_user_id'] !== null ? (int) $row['created_by_user_id'] : null,
                'created_at' => $row['created_at'],
            ];
        }, $ledgerStmt->fetchAll());

        return [
            'points' => $points,
            'ledger' => $ledger,
        ];
    }

    public function adjustLoyalty(int $businessId, int $clientId, int $userId, int $deltaPoints, string $reason): void
    {
        $this->db->beginTransaction();
        try {
            $insert = $this->db->getPdo()->prepare(
                'INSERT INTO client_loyalty_ledger (business_id, client_id, delta_points, reason, created_by_user_id)
                 VALUES (?, ?, ?, ?, ?)'
            );
            $insert->execute([$businessId, $clientId, $deltaPoints, $this->sanitizeLoyaltyReason($reason), $userId]);

            $update = $this->db->getPdo()->prepare(
                'UPDATE clients
                 SET loyalty_points = loyalty_points + ?, updated_at = NOW()
                 WHERE business_id = ? AND id = ?'
            );
            $update->execute([$deltaPoints, $businessId, $clientId]);

            $this->createManualEvent($businessId, $clientId, $userId, 'note', [
                'kind' => 'loyalty_adjustment',
                'delta_points' => $deltaPoints,
                'reason' => $reason,
            ]);

            $this->db->commit();
        } catch (\Throwable $e) {
            $this->db->rollback();
            throw $e;
        }
    }

    public function listContacts(int $businessId, int $clientId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, type, value, is_primary, is_verified, created_at, updated_at
             FROM client_contacts
             WHERE business_id = ? AND client_id = ?
             ORDER BY is_primary DESC, id ASC'
        );
        $stmt->execute([$businessId, $clientId]);

        return array_map(static function (array $row): array {
            return [
                'id' => (int) $row['id'],
                'type' => $row['type'],
                'value' => $row['value'],
                'is_primary' => (bool) $row['is_primary'],
                'is_verified' => (bool) $row['is_verified'],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at'],
            ];
        }, $stmt->fetchAll());
    }

    public function createContact(int $businessId, int $clientId, array $data): int
    {
        $type = $this->sanitizeContactType((string) ($data['type'] ?? 'other'));
        $value = trim((string) ($data['value'] ?? ''));
        if ($value === '') {
            throw new \InvalidArgumentException('Contact value is required');
        }

        $this->db->beginTransaction();
        try {
            if (($data['is_primary'] ?? false) === true) {
                $clearPrimary = $this->db->getPdo()->prepare(
                    'UPDATE client_contacts SET is_primary = 0 WHERE business_id = ? AND client_id = ?'
                );
                $clearPrimary->execute([$businessId, $clientId]);
            }

            $insert = $this->db->getPdo()->prepare(
                'INSERT INTO client_contacts (business_id, client_id, type, value, is_primary, is_verified)
                 VALUES (?, ?, ?, ?, ?, ?)'
            );
            $insert->execute([
                $businessId,
                $clientId,
                $type,
                $value,
                (int) (($data['is_primary'] ?? false) ? 1 : 0),
                (int) (($data['is_verified'] ?? false) ? 1 : 0),
            ]);
            $id = (int) $this->db->getPdo()->lastInsertId();

            $this->db->commit();
            return $id;
        } catch (\Throwable $e) {
            $this->db->rollback();
            throw $e;
        }
    }

    public function updateContact(int $businessId, int $clientId, int $contactId, array $data): bool
    {
        $this->db->beginTransaction();
        try {
            $fields = [];
            $values = [];
            if (array_key_exists('type', $data)) {
                $fields[] = 'type = ?';
                $values[] = $this->sanitizeContactType((string) $data['type']);
            }
            if (array_key_exists('value', $data)) {
                $fields[] = 'value = ?';
                $values[] = trim((string) $data['value']);
            }
            if (array_key_exists('is_verified', $data)) {
                $fields[] = 'is_verified = ?';
                $values[] = (int) ((bool) $data['is_verified']);
            }
            if (array_key_exists('is_primary', $data)) {
                if ((bool) $data['is_primary'] === true) {
                    $clearPrimary = $this->db->getPdo()->prepare(
                        'UPDATE client_contacts SET is_primary = 0 WHERE business_id = ? AND client_id = ?'
                    );
                    $clearPrimary->execute([$businessId, $clientId]);
                }
                $fields[] = 'is_primary = ?';
                $values[] = (int) ((bool) $data['is_primary']);
            }

            if ($fields === []) {
                $this->db->rollback();
                return false;
            }

            $values[] = $businessId;
            $values[] = $clientId;
            $values[] = $contactId;
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE client_contacts
                 SET ' . implode(', ', $fields) . ', updated_at = NOW()
                 WHERE business_id = ? AND client_id = ? AND id = ?'
            );
            $stmt->execute($values);
            $updated = $stmt->rowCount() > 0;
            $this->db->commit();
            return $updated;
        } catch (\Throwable $e) {
            $this->db->rollback();
            throw $e;
        }
    }

    public function deleteContact(int $businessId, int $clientId, int $contactId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM client_contacts WHERE business_id = ? AND client_id = ? AND id = ?'
        );
        $stmt->execute([$businessId, $clientId, $contactId]);
        return $stmt->rowCount() > 0;
    }

    public function makeContactPrimary(int $businessId, int $clientId, int $contactId): bool
    {
        $this->db->beginTransaction();
        try {
            $existsStmt = $this->db->getPdo()->prepare(
                'SELECT 1 FROM client_contacts WHERE business_id = ? AND client_id = ? AND id = ?'
            );
            $existsStmt->execute([$businessId, $clientId, $contactId]);
            if (!$existsStmt->fetchColumn()) {
                $this->db->rollback();
                return false;
            }

            $clearPrimary = $this->db->getPdo()->prepare(
                'UPDATE client_contacts SET is_primary = 0 WHERE business_id = ? AND client_id = ?'
            );
            $clearPrimary->execute([$businessId, $clientId]);

            $setPrimary = $this->db->getPdo()->prepare(
                'UPDATE client_contacts SET is_primary = 1, updated_at = NOW() WHERE business_id = ? AND client_id = ? AND id = ?'
            );
            $setPrimary->execute([$businessId, $clientId, $contactId]);

            $this->db->commit();
            return true;
        } catch (\Throwable $e) {
            $this->db->rollback();
            throw $e;
        }
    }

    public function dedupSuggestions(int $businessId, string $query, int $limit = 20): array
    {
        $query = trim($query);
        if ($query === '') {
            return [];
        }

        $normalizedEmail = strtolower($query);
        $normalizedPhone = $this->normalizePhone($query);
        $nameLike = '%' . $query . '%';

        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, first_name, last_name, email, phone, birth_date, city, last_visit
             FROM clients
             WHERE business_id = ? AND (
                 LOWER(email) = ?
                 OR REPLACE(REPLACE(REPLACE(REPLACE(phone, " ", ""), "-", ""), "(", ""), ")", "") = ?
                 OR CONCAT_WS(" ", first_name, last_name) LIKE ?
             )
             ORDER BY updated_at DESC
             LIMIT ?'
        );
        $stmt->execute([$businessId, $normalizedEmail, $normalizedPhone, $nameLike, max(1, min(100, $limit))]);
        $rows = $stmt->fetchAll();

        $suggestions = [];
        foreach ($rows as $row) {
            $reasons = [];
            $score = 0;

            if (!empty($row['email']) && strtolower((string) $row['email']) === $normalizedEmail) {
                $reasons[] = 'email_exact';
                $score += 70;
            }

            if (!empty($row['phone']) && $this->normalizePhone((string) $row['phone']) === $normalizedPhone && $normalizedPhone !== '') {
                $reasons[] = 'phone_exact';
                $score += 70;
            }

            $fullName = strtolower(trim(($row['first_name'] ?? '') . ' ' . ($row['last_name'] ?? '')));
            if ($fullName !== '' && str_contains($fullName, strtolower($query))) {
                $reasons[] = 'name_similarity';
                $score += 30;
            }

            if ($score > 100) {
                $score = 100;
            }

            if ($score <= 0) {
                continue;
            }

            $suggestions[] = [
                'candidate_client_id' => (int) $row['id'],
                'match_reasons' => $reasons,
                'score' => $score,
                'preview' => [
                    'first_name' => $row['first_name'],
                    'last_name' => $row['last_name'],
                    'email' => $row['email'],
                    'phone' => $row['phone'],
                    'last_visit' => $row['last_visit'],
                ],
            ];
        }

        usort($suggestions, static fn(array $a, array $b): int => $b['score'] <=> $a['score']);
        return $suggestions;
    }

    public function mergeClients(int $businessId, int $sourceClientId, int $targetClientId, int $userId): void
    {
        if ($sourceClientId === $targetClientId) {
            throw new \InvalidArgumentException('source and target must be different');
        }

        $this->db->beginTransaction();
        try {
            $checkStmt = $this->db->getPdo()->prepare(
                'SELECT id FROM clients WHERE business_id = ? AND id IN (?, ?)'
            );
            $checkStmt->execute([$businessId, $sourceClientId, $targetClientId]);
            $ids = array_map(static fn(array $r): int => (int) $r['id'], $checkStmt->fetchAll());
            if (!in_array($sourceClientId, $ids, true) || !in_array($targetClientId, $ids, true)) {
                throw new \InvalidArgumentException('One or both clients not found in business');
            }

            $insertMerge = $this->db->getPdo()->prepare(
                'INSERT INTO client_merge_map (business_id, source_client_id, target_client_id, merged_by_user_id)
                 VALUES (?, ?, ?, ?)'
            );
            $insertMerge->execute([$businessId, $sourceClientId, $targetClientId, $userId]);

            $this->repointClientRows($businessId, 'client_contacts', $sourceClientId, $targetClientId);
            $this->repointClientRows($businessId, 'client_addresses', $sourceClientId, $targetClientId);
            $this->repointClientRows($businessId, 'client_events', $sourceClientId, $targetClientId);
            $this->repointClientRows($businessId, 'client_tasks', $sourceClientId, $targetClientId);
            $this->repointClientRows($businessId, 'client_loyalty_ledger', $sourceClientId, $targetClientId);
            $this->repointClientRows($businessId, 'bookings', $sourceClientId, $targetClientId);

            try {
                $this->repointClientRowsWithCustomColumn($businessId, 'class_bookings', 'customer_id', $sourceClientId, $targetClientId);
            } catch (\PDOException) {
                // Optional table on some installs.
            }

            $mergeTags = $this->db->getPdo()->prepare(
                'INSERT IGNORE INTO client_tag_links (business_id, client_id, tag_id, created_at)
                 SELECT business_id, ?, tag_id, created_at
                 FROM client_tag_links
                 WHERE business_id = ? AND client_id = ?'
            );
            $mergeTags->execute([$targetClientId, $businessId, $sourceClientId]);

            $deleteSourceTags = $this->db->getPdo()->prepare(
                'DELETE FROM client_tag_links WHERE business_id = ? AND client_id = ?'
            );
            $deleteSourceTags->execute([$businessId, $sourceClientId]);

            $markSource = $this->db->getPdo()->prepare(
                'UPDATE clients
                 SET is_archived = 1, status = "lost", updated_at = NOW()
                 WHERE business_id = ? AND id = ?'
            );
            $markSource->execute([$businessId, $sourceClientId]);

            $this->createManualEvent($businessId, $targetClientId, $userId, 'merge', [
                'source_client_id' => $sourceClientId,
                'target_client_id' => $targetClientId,
            ]);

            $this->syncLegacyTagsJson($businessId, $targetClientId);
            $this->syncLegacyTagsJson($businessId, $sourceClientId);

            $this->db->commit();
        } catch (\Throwable $e) {
            $this->db->rollback();
            throw $e;
        }
    }

    public function gdprExport(int $businessId, int $clientId): array
    {
        $client = $this->getClient($businessId, $clientId);
        if ($client === null) {
            throw new \InvalidArgumentException('Client not found');
        }

        return [
            'client' => $client,
            'events' => $this->listEvents($businessId, $clientId, 1, 1000)['events'],
            'tasks' => $this->listTasks($businessId, $clientId),
            'contacts' => $this->listContacts($businessId, $clientId),
            'loyalty' => $this->getLoyalty($businessId, $clientId),
            'exported_at' => gmdate('c'),
            'format' => 'json',
        ];
    }

    public function gdprDelete(int $businessId, int $clientId, int $userId): void
    {
        $this->db->beginTransaction();
        try {
            $mask = 'deleted_' . $clientId . '@anonymized.local';
            $stmt = $this->db->getPdo()->prepare(
                'UPDATE clients
                 SET first_name = "Deleted",
                     last_name = "User",
                     email = ?,
                     phone = NULL,
                     birth_date = NULL,
                     city = NULL,
                     address_city = NULL,
                     notes = NULL,
                     company_name = NULL,
                     vat_number = NULL,
                     source = "gdpr_deleted",
                     status = "lost",
                     is_archived = 1,
                     deleted_at = NOW(),
                     updated_at = NOW()
                 WHERE business_id = ? AND id = ?'
            );
            $stmt->execute([$mask, $businessId, $clientId]);

            $wipeContacts = $this->db->getPdo()->prepare(
                'DELETE FROM client_contacts WHERE business_id = ? AND client_id = ?'
            );
            $wipeContacts->execute([$businessId, $clientId]);

            $wipeAddresses = $this->db->getPdo()->prepare(
                'DELETE FROM client_addresses WHERE business_id = ? AND client_id = ?'
            );
            $wipeAddresses->execute([$businessId, $clientId]);

            $wipeConsents = $this->db->getPdo()->prepare(
                'DELETE FROM client_consents WHERE business_id = ? AND client_id = ?'
            );
            $wipeConsents->execute([$businessId, $clientId]);

            $this->createManualEvent($businessId, $clientId, $userId, 'gdpr_delete', [
                'deleted_at' => gmdate('c'),
            ]);

            $this->db->commit();
        } catch (\Throwable $e) {
            $this->db->rollback();
            throw $e;
        }
    }

    public function listSegments(int $businessId): array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, name, filters_json, created_at, updated_at
             FROM client_segments
             WHERE business_id = ?
             ORDER BY updated_at DESC, id DESC'
        );
        $stmt->execute([$businessId]);

        return array_map(static function (array $row): array {
            return [
                'id' => (int) $row['id'],
                'name' => $row['name'],
                'filters' => Json::decodeAssoc((string) $row['filters_json']) ?? [],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at'],
            ];
        }, $stmt->fetchAll());
    }

    public function createSegment(int $businessId, string $name, array $filters): int
    {
        $stmt = $this->db->getPdo()->prepare(
            'INSERT INTO client_segments (business_id, name, filters_json)
             VALUES (?, ?, ?)'
        );
        $stmt->execute([$businessId, trim($name), Json::encode($filters)]);
        return (int) $this->db->getPdo()->lastInsertId();
    }

    public function updateSegment(int $businessId, int $segmentId, string $name, array $filters): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE client_segments
             SET name = ?, filters_json = ?, updated_at = NOW()
             WHERE business_id = ? AND id = ?'
        );
        $stmt->execute([trim($name), Json::encode($filters), $businessId, $segmentId]);
        return $stmt->rowCount() > 0;
    }

    public function deleteSegment(int $businessId, int $segmentId): bool
    {
        $stmt = $this->db->getPdo()->prepare(
            'DELETE FROM client_segments WHERE business_id = ? AND id = ?'
        );
        $stmt->execute([$businessId, $segmentId]);
        return $stmt->rowCount() > 0;
    }

    public function getSegment(int $businessId, int $segmentId): ?array
    {
        $stmt = $this->db->getPdo()->prepare(
            'SELECT id, name, filters_json, created_at, updated_at
             FROM client_segments
             WHERE business_id = ? AND id = ?
             LIMIT 1'
        );
        $stmt->execute([$businessId, $segmentId]);
        $row = $stmt->fetch();
        if (!$row) {
            return null;
        }

        return [
            'id' => (int) $row['id'],
            'name' => $row['name'],
            'filters' => Json::decodeAssoc((string) $row['filters_json']) ?? [],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'],
        ];
    }

    public function importClientsFromCsv(
        int $businessId,
        string $csvContent,
        array $mapping,
        bool $dryRun = true
    ): array {
        $lines = preg_split('/\r\n|\r|\n/', trim($csvContent)) ?: [];
        if ($lines === []) {
            return [
                'preview_rows' => [],
                'total_rows' => 0,
                'valid_rows' => 0,
                'error_rows' => 0,
                'errors' => [],
                'created_ids' => [],
            ];
        }

        $header = str_getcsv((string) array_shift($lines));
        $map = [];
        foreach ($mapping as $field => $columnName) {
            $idx = array_search($columnName, $header, true);
            if ($idx !== false) {
                $map[$field] = (int) $idx;
            }
        }

        $preview = [];
        $errors = [];
        $createdIds = [];
        $validRows = 0;
        $errorRows = 0;

        if (!$dryRun) {
            $this->db->beginTransaction();
        }

        try {
            foreach ($lines as $lineNo => $line) {
                if (trim($line) === '') {
                    continue;
                }
                $cols = str_getcsv($line);
                $row = [
                    'first_name' => $this->csvValue($cols, $map, 'first_name'),
                    'last_name' => $this->csvValue($cols, $map, 'last_name'),
                    'email' => $this->csvValue($cols, $map, 'email'),
                    'phone' => $this->csvValue($cols, $map, 'phone'),
                    'city' => $this->csvValue($cols, $map, 'city'),
                    'notes' => $this->csvValue($cols, $map, 'notes'),
                    'source' => $this->csvValue($cols, $map, 'source') ?? 'csv-import',
                ];

                if (($row['first_name'] ?? null) === null
                    && ($row['last_name'] ?? null) === null
                    && ($row['email'] ?? null) === null
                    && ($row['phone'] ?? null) === null) {
                    $errorRows++;
                    $errors[] = [
                        'line' => $lineNo + 2,
                        'error' => 'At least one among first_name,last_name,email,phone is required',
                    ];
                    continue;
                }

                $validRows++;
                $preview[] = $row;

                if (!$dryRun) {
                    $createdIds[] = $this->createClient($businessId, $row);
                }
            }

            if (!$dryRun) {
                $this->db->commit();
            }
        } catch (\Throwable $e) {
            if (!$dryRun) {
                $this->db->rollback();
            }
            throw $e;
        }

        return [
            'preview_rows' => array_slice($preview, 0, 20),
            'total_rows' => count($preview) + $errorRows,
            'valid_rows' => $validRows,
            'error_rows' => $errorRows,
            'errors' => $errors,
            'created_ids' => $createdIds,
        ];
    }

    public function exportClientsCsv(int $businessId, array $filters = []): string
    {
        $list = $this->listClients($businessId, [
            ...$filters,
            'page' => 1,
            'page_size' => 1000,
            'sort' => $filters['sort'] ?? 'name_asc',
        ]);

        $fp = fopen('php://temp', 'r+');
        fputcsv($fp, [
            'id',
            'first_name',
            'last_name',
            'email',
            'phone',
            'city',
            'status',
            'is_archived',
            'tags',
            'visits_count',
            'total_spent',
            'last_visit',
        ]);

        foreach ($list['clients'] as $client) {
            fputcsv($fp, [
                $client['id'],
                $client['first_name'],
                $client['last_name'],
                $client['email'],
                $client['phone'],
                $client['city'],
                $client['status'],
                $client['is_archived'] ? 1 : 0,
                implode('|', (array) ($client['tags'] ?? [])),
                $client['kpi']['visits_count'] ?? 0,
                $client['kpi']['total_spent'] ?? 0,
                $client['kpi']['last_visit'] ?? '',
            ]);
        }

        rewind($fp);
        $csv = stream_get_contents($fp) ?: '';
        fclose($fp);
        return $csv;
    }

    private function loadClientDetail(int $businessId, int $clientId, array $base): array
    {
        $base['consents'] = $this->getConsents($businessId, $clientId);

        $contactsStmt = $this->db->getPdo()->prepare(
            'SELECT id, type, value, is_primary, is_verified, created_at, updated_at
             FROM client_contacts
             WHERE business_id = ? AND client_id = ?
             ORDER BY is_primary DESC, id ASC'
        );
        $contactsStmt->execute([$businessId, $clientId]);
        $base['contacts'] = array_map(static function (array $row): array {
            return [
                'id' => (int) $row['id'],
                'type' => $row['type'],
                'value' => $row['value'],
                'is_primary' => (bool) $row['is_primary'],
                'is_verified' => (bool) $row['is_verified'],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at'],
            ];
        }, $contactsStmt->fetchAll());

        $addressesStmt = $this->db->getPdo()->prepare(
            'SELECT id, label, line1, line2, city, province, postal_code, country, created_at, updated_at
             FROM client_addresses
             WHERE business_id = ? AND client_id = ?
             ORDER BY id ASC'
        );
        $addressesStmt->execute([$businessId, $clientId]);
        $base['addresses'] = array_map(static function (array $row): array {
            return [
                'id' => (int) $row['id'],
                'label' => $row['label'],
                'line1' => $row['line1'],
                'line2' => $row['line2'],
                'city' => $row['city'],
                'province' => $row['province'],
                'postal_code' => $row['postal_code'],
                'country' => $row['country'],
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at'],
            ];
        }, $addressesStmt->fetchAll());

        $base['loyalty'] = $this->getLoyalty($businessId, $clientId);

        return $base;
    }

    private function hydrateClientRow(array $row, array $linkedTags): array
    {
        $legacyTags = [];
        if (isset($row['tags']) && $row['tags'] !== null && $row['tags'] !== '') {
            $decoded = Json::decodeAssoc((string) $row['tags']);
            if ($decoded !== null) {
                $legacyTags = array_values(array_filter(array_map(static fn($v): string => (string) $v, $decoded)));
            }
        }

        $tags = $linkedTags !== [] ? $linkedTags : $legacyTags;

        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'first_name' => $row['first_name'] ?? null,
            'last_name' => $row['last_name'] ?? null,
            'email' => $row['email'] ?? null,
            'phone' => $row['phone'] ?? null,
            'gender' => $row['gender'] ?? null,
            'birth_date' => $row['birth_date'] ?? null,
            'city' => $row['city'] ?? null,
            'address_city' => $row['address_city'] ?? null,
            'notes' => $row['notes'] ?? null,
            'status' => $row['status'] ?? 'active',
            'source' => $row['source'] ?? null,
            'company_name' => $row['company_name'] ?? null,
            'vat_number' => $row['vat_number'] ?? null,
            'loyalty_points' => (int) ($row['loyalty_points'] ?? 0),
            'is_archived' => (bool) ($row['is_archived'] ?? false),
            'tags' => $tags,
            'kpi' => [
                'visits_count' => (int) ($row['visits_count'] ?? 0),
                'total_spent' => (float) ($row['total_spent'] ?? 0),
                'avg_ticket' => (float) ($row['avg_ticket'] ?? 0),
                'last_visit' => $row['last_visit'] ?? null,
                'no_show_count' => (int) ($row['no_show_count'] ?? 0),
            ],
            'created_at' => $row['created_at'] ?? null,
            'updated_at' => $row['updated_at'] ?? null,
            'deleted_at' => $row['deleted_at'] ?? null,
        ];
    }

    private function getTagNamesByClientIds(int $businessId, array $clientIds): array
    {
        if ($clientIds === []) {
            return [];
        }

        $in = implode(',', array_fill(0, count($clientIds), '?'));
        $stmt = $this->db->getPdo()->prepare(
            "SELECT ctl.client_id, ct.name
             FROM client_tag_links ctl
             JOIN client_tags ct ON ct.id = ctl.tag_id AND ct.business_id = ctl.business_id
             WHERE ctl.business_id = ?
               AND ctl.client_id IN ($in)
             ORDER BY ct.name ASC"
        );
        $stmt->execute([$businessId, ...$clientIds]);

        $map = [];
        foreach ($stmt->fetchAll() as $row) {
            $clientId = (int) $row['client_id'];
            if (!isset($map[$clientId])) {
                $map[$clientId] = [];
            }
            $map[$clientId][] = $row['name'];
        }

        return $map;
    }

    private function syncLegacyTagsJson(int $businessId, int $clientId): void
    {
        $tags = $this->getTagNamesByClientIds($businessId, [$clientId])[$clientId] ?? [];
        $stmt = $this->db->getPdo()->prepare(
            'UPDATE clients SET tags = ?, updated_at = NOW() WHERE business_id = ? AND id = ?'
        );
        $stmt->execute([Json::encode($tags), $businessId, $clientId]);
    }

    private function repointClientRows(int $businessId, string $table, int $sourceClientId, int $targetClientId): void
    {
        $stmt = $this->db->getPdo()->prepare(
            "UPDATE $table SET client_id = ? WHERE business_id = ? AND client_id = ?"
        );
        $stmt->execute([$targetClientId, $businessId, $sourceClientId]);
    }

    private function repointClientRowsWithCustomColumn(
        int $businessId,
        string $table,
        string $clientColumn,
        int $sourceClientId,
        int $targetClientId
    ): void {
        $stmt = $this->db->getPdo()->prepare(
            "UPDATE $table SET $clientColumn = ? WHERE business_id = ? AND $clientColumn = ?"
        );
        $stmt->execute([$targetClientId, $businessId, $sourceClientId]);
    }

    private function csvToIntList(string $value): array
    {
        if ($value === '') {
            return [];
        }

        return array_values(array_filter(array_map(
            static fn(string $part): int => (int) trim($part),
            explode(',', $value)
        ), static fn(int $v): bool => $v > 0));
    }

    private function csvToStringList(string $value): array
    {
        if ($value === '') {
            return [];
        }

        return array_values(array_filter(array_map(
            static fn(string $part): string => trim($part),
            explode(',', $value)
        ), static fn(string $v): bool => $v !== ''));
    }

    private function clientSortToSql(string $sort): string
    {
        return match ($sort) {
            'name_asc' => 'c.first_name ASC, c.last_name ASC, c.id ASC',
            'name_desc' => 'c.first_name DESC, c.last_name DESC, c.id DESC',
            'spent_desc' => 'COALESCE(k.total_spent, 0) DESC, c.id DESC',
            'spent_asc' => 'COALESCE(k.total_spent, 0) ASC, c.id ASC',
            'created_asc' => 'c.created_at ASC, c.id ASC',
            'created_desc' => 'c.created_at DESC, c.id DESC',
            default => 'COALESCE(k.last_visit, c.last_visit) DESC, c.id DESC',
        };
    }

    private function sanitizePreferredChannel(string $value): string
    {
        $allowed = ['whatsapp', 'sms', 'email', 'phone', 'none'];
        $value = strtolower(trim($value));
        return in_array($value, $allowed, true) ? $value : 'none';
    }

    private function sanitizeTaskStatus(string $value): string
    {
        $allowed = ['open', 'done', 'cancelled'];
        $value = strtolower(trim($value));
        return in_array($value, $allowed, true) ? $value : 'open';
    }

    private function sanitizeTaskPriority(string $value): string
    {
        $allowed = ['low', 'medium', 'high'];
        $value = strtolower(trim($value));
        return in_array($value, $allowed, true) ? $value : 'medium';
    }

    private function sanitizeLoyaltyReason(string $value): string
    {
        $allowed = ['manual', 'booking', 'promotion', 'refund', 'adjustment'];
        $value = strtolower(trim($value));
        return in_array($value, $allowed, true) ? $value : 'manual';
    }

    private function sanitizeContactType(string $value): string
    {
        $allowed = ['email', 'phone', 'whatsapp', 'instagram', 'facebook', 'other'];
        $value = strtolower(trim($value));
        return in_array($value, $allowed, true) ? $value : 'other';
    }

    private function normalizePhone(string $value): string
    {
        $value = trim($value);
        $value = preg_replace('/[^\d+]/', '', $value) ?? '';
        return str_starts_with($value, '+') ? $value : preg_replace('/\D/', '', $value) ?? '';
    }

    private function csvValue(array $cols, array $map, string $field): ?string
    {
        if (!isset($map[$field])) {
            return null;
        }
        $idx = $map[$field];
        if (!array_key_exists($idx, $cols)) {
            return null;
        }
        $value = trim((string) $cols[$idx]);
        return $value === '' ? null : $value;
    }

    private function nullableString(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }
        $trimmed = trim((string) $value);
        return $trimmed === '' ? null : $trimmed;
    }

    private function nullableDate(mixed $value): ?string
    {
        $date = $this->nullableString($value);
        if ($date === null) {
            return null;
        }

        return preg_match('/^\d{4}-\d{2}-\d{2}$/', $date) === 1 ? $date : null;
    }

    private function nullableDateTime(mixed $value): ?string
    {
        $dateTime = $this->nullableString($value);
        if ($dateTime === null) {
            return null;
        }

        return preg_match('/^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(:\d{2})?$/', $dateTime) === 1
            ? str_replace('T', ' ', $dateTime)
            : null;
    }
}
