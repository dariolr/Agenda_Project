<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\CrmClientRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use PDOException;

final class CrmClientsController
{
    public function __construct(
        private readonly CrmClientRepository $crmRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    private function businessIdFromRoute(Request $request): int
    {
        return (int) $request->getRouteParam('business_id');
    }

    private function hasBusinessAccess(Request $request, int $businessId): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_clients', false);
    }

    private function assertBusinessAccess(Request $request): ?Response
    {
        $businessId = $this->businessIdFromRoute($request);
        if ($businessId <= 0) {
            return Response::error('business_id is required', 'validation_error', 400, $request->traceId);
        }

        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        return null;
    }

    private function assertClientInBusiness(Request $request): ?Response
    {
        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');

        if ($clientId <= 0) {
            return Response::error('client_id is required', 'validation_error', 400, $request->traceId);
        }

        if (!$this->crmRepo->clientExistsInBusiness($businessId, $clientId)) {
            return Response::notFound('Client not found', $request->traceId);
        }

        return null;
    }

    public function index(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }

        $businessId = $this->businessIdFromRoute($request);

        $filters = [
            'q' => $request->queryParam('q') ?? '',
            'status' => $request->queryParam('status') ?? '',
            'is_archived' => $request->queryParam('is_archived') ?? '',
            'tag_ids' => $request->queryParam('tag_ids') ?? '',
            'tag_names' => $request->queryParam('tag_names') ?? '',
            'last_visit_from' => $request->queryParam('last_visit_from') ?? '',
            'last_visit_to' => $request->queryParam('last_visit_to') ?? '',
            'spent_from' => $request->queryParam('spent_from') ?? '',
            'spent_to' => $request->queryParam('spent_to') ?? '',
            'visits_from' => $request->queryParam('visits_from') ?? '',
            'visits_to' => $request->queryParam('visits_to') ?? '',
            'birthday_month' => $request->queryParam('birthday_month') ?? '',
            'marketing_opt_in' => $request->queryParam('marketing_opt_in') ?? '',
            'profiling_opt_in' => $request->queryParam('profiling_opt_in') ?? '',
            'sort' => $request->queryParam('sort') ?? 'last_visit_desc',
            'page' => (int) ($request->queryParam('page') ?? '1'),
            'page_size' => (int) ($request->queryParam('page_size') ?? '20'),
        ];

        $result = $this->crmRepo->listClients($businessId, $filters);
        return Response::success($result);
    }

    public function store(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }

        $body = $request->getBody() ?? [];
        if (!isset($body['first_name']) && !isset($body['last_name']) && !isset($body['email']) && !isset($body['phone'])) {
            return Response::error(
                'At least one field between first_name, last_name, email, phone is required',
                'validation_error',
                400,
                $request->traceId
            );
        }

        $businessId = $this->businessIdFromRoute($request);

        try {
            $clientId = $this->crmRepo->createClient($businessId, $body);
            $client = $this->crmRepo->getClient($businessId, $clientId);
            return Response::created($client ?? ['id' => $clientId]);
        } catch (PDOException $e) {
            if ((int) $e->getCode() === 23000) {
                return Response::conflict('client_conflict', 'Duplicate value violates unique constraints', $request->traceId);
            }
            throw $e;
        }
    }

    public function show(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');

        $client = $this->crmRepo->getClient($businessId, $clientId);
        if ($client === null) {
            return Response::notFound('Client not found', $request->traceId);
        }

        return Response::success($client);
    }

    public function patch(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $body = $request->getBody() ?? [];
        if ($body === []) {
            return Response::error('Empty body', 'validation_error', 400, $request->traceId);
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');

        try {
            $this->crmRepo->updateClientPartial($businessId, $clientId, $body);
            $client = $this->crmRepo->getClient($businessId, $clientId);
            return Response::success($client ?? ['id' => $clientId]);
        } catch (PDOException $e) {
            if ((int) $e->getCode() === 23000) {
                return Response::conflict('client_conflict', 'Duplicate value violates unique constraints', $request->traceId);
            }
            throw $e;
        }
    }

    public function archive(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');

        $this->crmRepo->setArchived($businessId, $clientId, true);
        return Response::success(['archived' => true]);
    }

    public function unarchive(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');

        $this->crmRepo->setArchived($businessId, $clientId, false);
        return Response::success(['archived' => false]);
    }

    public function listTags(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }

        $tags = $this->crmRepo->listTags($this->businessIdFromRoute($request));
        return Response::success(['tags' => $tags]);
    }

    public function createTag(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }

        $body = $request->getBody() ?? [];
        $name = trim((string) ($body['name'] ?? ''));
        if ($name === '') {
            return Response::error('name is required', 'validation_error', 400, $request->traceId);
        }

        try {
            $tagId = $this->crmRepo->createTag($this->businessIdFromRoute($request), $name, $body['color'] ?? null);
            return Response::created(['id' => $tagId]);
        } catch (PDOException $e) {
            if ((int) $e->getCode() === 23000) {
                return Response::conflict('tag_conflict', 'Tag name already exists', $request->traceId);
            }
            throw $e;
        }
    }

    public function deleteTag(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }

        $businessId = $this->businessIdFromRoute($request);
        $tagId = (int) $request->getRouteParam('tag_id');
        $force = ($request->queryParam('force') ?? 'false') === 'true';

        $deleted = $this->crmRepo->deleteTag($businessId, $tagId, $force);
        if (!$deleted && !$force) {
            return Response::error(
                'Tag is linked to clients. Use force=true to delete and unlink.',
                'business_rule_violation',
                422,
                $request->traceId
            );
        }

        return Response::success(['deleted' => true]);
    }

    public function replaceTags(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $body = $request->getBody() ?? [];
        $tagIds = array_values(array_filter(array_map(
            static fn(mixed $v): int => (int) $v,
            (array) ($body['tag_ids'] ?? [])
        ), static fn(int $v): bool => $v > 0));

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');

        $this->crmRepo->replaceClientTags($businessId, $clientId, $tagIds);
        return Response::success(['tag_ids' => $tagIds]);
    }

    public function addTag(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $tagId = (int) $request->getRouteParam('tag_id');

        $this->crmRepo->addClientTag($businessId, $clientId, $tagId);
        return Response::success(['added' => true]);
    }

    public function removeTag(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $tagId = (int) $request->getRouteParam('tag_id');

        $this->crmRepo->removeClientTag($businessId, $clientId, $tagId);
        return Response::success(['removed' => true]);
    }

    public function getConsents(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');

        return Response::success($this->crmRepo->getConsents($businessId, $clientId));
    }

    public function putConsents(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $body = $request->getBody() ?? [];
        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $userId = (int) ($request->getAttribute('user_id') ?? 0);

        $this->crmRepo->upsertConsents($businessId, $clientId, $userId, $body);
        return Response::success($this->crmRepo->getConsents($businessId, $clientId));
    }

    public function listEvents(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $page = max(1, (int) ($request->queryParam('page') ?? '1'));
        $pageSize = max(1, min(100, (int) ($request->queryParam('page_size') ?? '20')));

        return Response::success($this->crmRepo->listEvents($businessId, $clientId, $page, $pageSize));
    }

    public function createEvent(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $body = $request->getBody() ?? [];
        $eventType = strtolower(trim((string) ($body['event_type'] ?? '')));
        if (!in_array($eventType, ['note', 'message'], true)) {
            return Response::error('Only note and message are allowed for manual event creation', 'validation_error', 400, $request->traceId);
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $userId = (int) ($request->getAttribute('user_id') ?? 0);

        $eventId = $this->crmRepo->createManualEvent($businessId, $clientId, $userId, $eventType, (array) ($body['payload'] ?? []));
        return Response::created(['id' => $eventId]);
    }

    public function listTasks(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $tasks = $this->crmRepo->listTasks($businessId, $clientId);

        return Response::success(['tasks' => $tasks]);
    }

    public function createTask(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $body = $request->getBody() ?? [];
        $title = trim((string) ($body['title'] ?? ''));
        if ($title === '') {
            return Response::error('title is required', 'validation_error', 400, $request->traceId);
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $userId = (int) ($request->getAttribute('user_id') ?? 0);

        $taskId = $this->crmRepo->createTask($businessId, $clientId, $userId, $body);
        return Response::created(['id' => $taskId]);
    }

    public function patchTask(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $body = $request->getBody() ?? [];
        if ($body === []) {
            return Response::error('Empty body', 'validation_error', 400, $request->traceId);
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $taskId = (int) $request->getRouteParam('task_id');

        $updated = $this->crmRepo->updateTask($businessId, $clientId, $taskId, $body);
        if (!$updated) {
            return Response::notFound('Task not found', $request->traceId);
        }

        return Response::success(['updated' => true]);
    }

    public function completeTask(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $taskId = (int) $request->getRouteParam('task_id');

        $updated = $this->crmRepo->markTaskStatus($businessId, $clientId, $taskId, 'done');
        if (!$updated) {
            return Response::notFound('Task not found', $request->traceId);
        }

        return Response::success(['completed' => true]);
    }

    public function reopenTask(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $taskId = (int) $request->getRouteParam('task_id');

        $updated = $this->crmRepo->markTaskStatus($businessId, $clientId, $taskId, 'open');
        if (!$updated) {
            return Response::notFound('Task not found', $request->traceId);
        }

        return Response::success(['reopened' => true]);
    }

    public function getLoyalty(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');

        return Response::success($this->crmRepo->getLoyalty($businessId, $clientId));
    }

    public function adjustLoyalty(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $body = $request->getBody() ?? [];
        $delta = (int) ($body['delta'] ?? 0);
        if ($delta === 0) {
            return Response::error('delta must be non-zero', 'validation_error', 400, $request->traceId);
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $userId = (int) ($request->getAttribute('user_id') ?? 0);
        $reason = (string) ($body['reason'] ?? 'manual');

        $this->crmRepo->adjustLoyalty($businessId, $clientId, $userId, $delta, $reason);

        return Response::success($this->crmRepo->getLoyalty($businessId, $clientId));
    }

    public function listContacts(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        return Response::success(['contacts' => $this->crmRepo->listContacts($businessId, $clientId)]);
    }

    public function createContact(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $body = $request->getBody() ?? [];

        try {
            $contactId = $this->crmRepo->createContact($businessId, $clientId, $body);
            return Response::created(['id' => $contactId]);
        } catch (\InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 400, $request->traceId);
        } catch (PDOException $e) {
            if ((int) $e->getCode() === 23000) {
                return Response::conflict('contact_conflict', 'Contact already exists in this business', $request->traceId);
            }
            throw $e;
        }
    }

    public function patchContact(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $contactId = (int) $request->getRouteParam('contact_id');
        $body = $request->getBody() ?? [];

        if ($body === []) {
            return Response::error('Empty body', 'validation_error', 400, $request->traceId);
        }

        try {
            $updated = $this->crmRepo->updateContact($businessId, $clientId, $contactId, $body);
            if (!$updated) {
                return Response::notFound('Contact not found', $request->traceId);
            }
            return Response::success(['updated' => true]);
        } catch (PDOException $e) {
            if ((int) $e->getCode() === 23000) {
                return Response::conflict('contact_conflict', 'Contact already exists in this business', $request->traceId);
            }
            throw $e;
        }
    }

    public function deleteContact(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $contactId = (int) $request->getRouteParam('contact_id');
        $deleted = $this->crmRepo->deleteContact($businessId, $clientId, $contactId);
        if (!$deleted) {
            return Response::notFound('Contact not found', $request->traceId);
        }
        return Response::success(['deleted' => true]);
    }

    public function makePrimaryContact(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $contactId = (int) $request->getRouteParam('contact_id');
        $updated = $this->crmRepo->makeContactPrimary($businessId, $clientId, $contactId);
        if (!$updated) {
            return Response::notFound('Contact not found', $request->traceId);
        }
        return Response::success(['updated' => true]);
    }

    public function dedupSuggestions(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        $businessId = $this->businessIdFromRoute($request);
        $query = (string) ($request->queryParam('q') ?? '');
        if (trim($query) === '') {
            return Response::error('q is required', 'validation_error', 400, $request->traceId);
        }

        $suggestions = $this->crmRepo->dedupSuggestions($businessId, $query, 20);
        return Response::success(['suggestions' => $suggestions]);
    }

    public function mergeInto(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }

        $businessId = $this->businessIdFromRoute($request);
        $sourceClientId = (int) $request->getRouteParam('source_client_id');
        $targetClientId = (int) $request->getRouteParam('target_client_id');
        $userId = (int) ($request->getAttribute('user_id') ?? 0);

        try {
            $this->crmRepo->mergeClients($businessId, $sourceClientId, $targetClientId, $userId);
            return Response::success([
                'merged' => true,
                'source_client_id' => $sourceClientId,
                'target_client_id' => $targetClientId,
            ]);
        } catch (\InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 400, $request->traceId);
        } catch (PDOException $e) {
            if ((int) $e->getCode() === 23000) {
                return Response::conflict('merge_conflict', 'Merge failed due to unique constraint conflict', $request->traceId);
            }
            throw $e;
        }
    }

    public function gdprExport(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $payload = $this->crmRepo->gdprExport($businessId, $clientId);
        $this->crmRepo->createManualEvent($businessId, $clientId, (int) ($request->getAttribute('user_id') ?? 0), 'gdpr_export', [
            'exported_at' => gmdate('c'),
        ]);

        return Response::success(['job_id' => null, 'format' => 'json', 'payload' => $payload]);
    }

    public function gdprDelete(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        if (($clientCheck = $this->assertClientInBusiness($request)) !== null) {
            return $clientCheck;
        }

        $businessId = $this->businessIdFromRoute($request);
        $clientId = (int) $request->getRouteParam('client_id');
        $userId = (int) ($request->getAttribute('user_id') ?? 0);
        $this->crmRepo->gdprDelete($businessId, $clientId, $userId);
        return Response::success(['deleted' => true, 'mode' => 'soft_delete_anonymize']);
    }

    public function listSegments(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        $segments = $this->crmRepo->listSegments($this->businessIdFromRoute($request));
        return Response::success(['segments' => $segments]);
    }

    public function createSegment(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }

        $body = $request->getBody() ?? [];
        $name = trim((string) ($body['name'] ?? ''));
        if ($name === '') {
            return Response::error('name is required', 'validation_error', 400, $request->traceId);
        }
        $filters = (array) ($body['filters'] ?? []);

        try {
            $id = $this->crmRepo->createSegment($this->businessIdFromRoute($request), $name, $filters);
            return Response::created(['id' => $id]);
        } catch (PDOException $e) {
            if ((int) $e->getCode() === 23000) {
                return Response::conflict('segment_conflict', 'Segment name already exists', $request->traceId);
            }
            throw $e;
        }
    }

    public function updateSegment(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        $segmentId = (int) $request->getRouteParam('segment_id');
        $body = $request->getBody() ?? [];
        $name = trim((string) ($body['name'] ?? ''));
        if ($name === '') {
            return Response::error('name is required', 'validation_error', 400, $request->traceId);
        }
        $filters = (array) ($body['filters'] ?? []);

        $updated = $this->crmRepo->updateSegment($this->businessIdFromRoute($request), $segmentId, $name, $filters);
        if (!$updated) {
            return Response::notFound('Segment not found', $request->traceId);
        }
        return Response::success(['updated' => true]);
    }

    public function deleteSegment(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }
        $segmentId = (int) $request->getRouteParam('segment_id');
        $deleted = $this->crmRepo->deleteSegment($this->businessIdFromRoute($request), $segmentId);
        if (!$deleted) {
            return Response::notFound('Segment not found', $request->traceId);
        }
        return Response::success(['deleted' => true]);
    }

    public function importCsv(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }

        $body = $request->getBody() ?? [];
        $csv = (string) ($body['csv'] ?? '');
        $mapping = (array) ($body['mapping'] ?? []);
        $dryRun = (bool) ($body['dry_run'] ?? true);

        if (trim($csv) === '') {
            return Response::error('csv is required', 'validation_error', 400, $request->traceId);
        }

        $result = $this->crmRepo->importClientsFromCsv(
            $this->businessIdFromRoute($request),
            $csv,
            $mapping,
            $dryRun
        );
        return Response::success($result);
    }

    public function exportCsv(Request $request): Response
    {
        if (($access = $this->assertBusinessAccess($request)) !== null) {
            return $access;
        }

        $businessId = $this->businessIdFromRoute($request);
        $segmentId = (int) ($request->queryParam('segment_id') ?? '0');
        $filters = [];
        if ($segmentId > 0) {
            $segment = $this->crmRepo->getSegment($businessId, $segmentId);
            if ($segment === null) {
                return Response::notFound('Segment not found', $request->traceId);
            }
            $filters = (array) ($segment['filters'] ?? []);
        }

        $csv = $this->crmRepo->exportClientsCsv($businessId, $filters);
        return Response::success([
            'segment_id' => $segmentId > 0 ? $segmentId : null,
            'csv' => $csv,
        ]);
    }
}
