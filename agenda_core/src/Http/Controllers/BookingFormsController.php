<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\BookingFormRepository;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use InvalidArgumentException;

final class BookingFormsController
{
    public function __construct(
        private readonly BookingFormRepository $bookingFormRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
        private readonly BookingRepository $bookingRepo,
    ) {}

    public function index(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->hasReadAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        return Response::success([
            'forms' => $this->bookingFormRepo->listForms($businessId),
        ]);
    }

    public function show(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $formId = (int) $request->getRouteParam('form_id');
        if (!$this->hasReadAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $form = $this->bookingFormRepo->findForm($businessId, $formId);
        if ($form === null) {
            return Response::notFound('Booking form not found', $request->traceId);
        }

        return Response::success(['form' => $form]);
    }

    public function store(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        try {
            $formId = $this->bookingFormRepo->createForm(
                $businessId,
                $this->body($request),
                $this->userId($request)
            );
            return Response::success(['form' => $this->bookingFormRepo->findForm($businessId, $formId)], 201);
        } catch (InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 422, $request->traceId);
        }
    }

    public function update(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $formId = (int) $request->getRouteParam('form_id');
        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        try {
            if (!$this->bookingFormRepo->updateForm($businessId, $formId, $this->body($request), $this->userId($request))) {
                return Response::notFound('Booking form not found', $request->traceId);
            }
            return Response::success(['form' => $this->bookingFormRepo->findForm($businessId, $formId)]);
        } catch (InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 422, $request->traceId);
        }
    }

    public function destroy(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $formId = (int) $request->getRouteParam('form_id');
        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        if (!$this->bookingFormRepo->deleteForm($businessId, $formId, $this->userId($request))) {
            return Response::notFound('Booking form not found', $request->traceId);
        }
        return Response::success(['deleted' => true]);
    }

    public function storeField(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $formId = (int) $request->getRouteParam('form_id');
        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        try {
            $this->bookingFormRepo->addField($businessId, $formId, $this->body($request));
            return Response::success(['form' => $this->bookingFormRepo->findForm($businessId, $formId)], 201);
        } catch (InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 422, $request->traceId);
        }
    }

    public function updateField(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $formId = (int) $request->getRouteParam('form_id');
        $fieldId = (int) $request->getRouteParam('field_id');
        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        try {
            if (!$this->bookingFormRepo->updateField($businessId, $formId, $fieldId, $this->body($request))) {
                return Response::notFound('Booking form field not found', $request->traceId);
            }
            return Response::success(['form' => $this->bookingFormRepo->findForm($businessId, $formId)]);
        } catch (InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 422, $request->traceId);
        }
    }

    public function destroyField(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $formId = (int) $request->getRouteParam('form_id');
        $fieldId = (int) $request->getRouteParam('field_id');
        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $this->bookingFormRepo->deactivateField($businessId, $formId, $fieldId);
        return Response::success(['form' => $this->bookingFormRepo->findForm($businessId, $formId)]);
    }

    public function reorderForms(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $formIds = $this->body($request)['form_ids'] ?? [];
        if (!is_array($formIds)) {
            return Response::error('form_ids is required', 'validation_error', 422, $request->traceId);
        }

        $this->bookingFormRepo->reorderForms($businessId, array_map('intval', $formIds));
        return Response::success(['forms' => $this->bookingFormRepo->listForms($businessId)]);
    }

    public function reorderFields(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $formId = (int) $request->getRouteParam('form_id');
        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $fieldIds = $this->body($request)['field_ids'] ?? [];
        if (!is_array($fieldIds)) {
            return Response::error('field_ids is required', 'validation_error', 422, $request->traceId);
        }

        $this->bookingFormRepo->reorderFields($businessId, $formId, array_map('intval', $fieldIds));
        return Response::success(['form' => $this->bookingFormRepo->findForm($businessId, $formId)]);
    }

    public function replaceRules(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $formId = (int) $request->getRouteParam('form_id');
        if (!$this->hasManageAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $rules = $this->body($request)['rules'] ?? [];
        if (!is_array($rules)) {
            return Response::error('rules is required', 'validation_error', 422, $request->traceId);
        }

        try {
            $this->bookingFormRepo->replaceRules($businessId, $formId, $rules);
            return Response::success(['form' => $this->bookingFormRepo->findForm($businessId, $formId)]);
        } catch (InvalidArgumentException $e) {
            return Response::error($e->getMessage(), 'validation_error', 422, $request->traceId);
        }
    }

    public function resolvePublic(Request $request): Response
    {
        $body = $this->body($request);
        $businessId = (int) ($body['business_id'] ?? 0);
        $locationId = (int) ($body['location_id'] ?? 0);
        if ($businessId <= 0 || $locationId <= 0) {
            return Response::error('business_id and location_id are required', 'validation_error', 400, $request->traceId);
        }

        return Response::success([
            'forms' => $this->bookingFormRepo->resolvePublicForms(
                $businessId,
                $locationId,
                $this->ids($body['service_variant_ids'] ?? []),
                $this->ids($body['service_ids'] ?? []),
                $this->ids($body['service_package_ids'] ?? $body['package_ids'] ?? []),
                $this->ids($body['class_event_ids'] ?? []),
            ),
        ]);
    }

    public function submissionsForBooking(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $bookingId = (int) $request->getRouteParam('booking_id');
        if (!$this->hasReadAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        return Response::success([
            'form_submissions' => $this->bookingFormRepo->getSubmissionsForBooking($businessId, $bookingId),
        ]);
    }

    /**
     * Moduli applicabili a una prenotazione (definizione + valori correnti),
     * per la visualizzazione/modifica nel gestionale.
     */
    public function formsForBooking(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $bookingId = (int) $request->getRouteParam('booking_id');
        if (!$this->hasReadAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $booking = $this->bookingRepo->findById($bookingId);
        if ($booking === null || (int) $booking['business_id'] !== $businessId) {
            return Response::notFound('Booking not found', $request->traceId);
        }

        return Response::success([
            'forms' => $this->bookingFormRepo->getActiveFormsWithValues($businessId, $bookingId),
        ]);
    }

    public function saveBookingSubmissions(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $bookingId = (int) $request->getRouteParam('booking_id');
        if (!$this->hasBookingManageAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        $booking = $this->bookingRepo->findById($bookingId);
        if ($booking === null || (int) $booking['business_id'] !== $businessId) {
            return Response::notFound('Booking not found', $request->traceId);
        }

        $submissions = $this->body($request)['submissions'] ?? [];
        if (!is_array($submissions)) {
            return Response::error('submissions is required', 'validation_error', 422, $request->traceId);
        }

        $clientId = $booking['client_id'] !== null ? (int) $booking['client_id'] : null;
        try {
            $this->bookingFormRepo->saveManagedSubmissions($businessId, $bookingId, $clientId, $submissions);
        } catch (\Throwable $e) {
            return Response::error($e->getMessage(), 'validation_error', 422, $request->traceId);
        }

        return Response::success([
            'form_submissions' => $this->bookingFormRepo->getSubmissionsForBooking($businessId, $bookingId),
        ]);
    }

    /**
     * Moduli per-cliente da mostrare al signup (endpoint pubblico, non
     * autenticato come login/register).
     */
    public function resolveRegistrationForms(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        if ($businessId <= 0) {
            return Response::error('business_id is required', 'validation_error', 400, $request->traceId);
        }

        return Response::success([
            'forms' => $this->bookingFormRepo->resolveRegistrationForms($businessId),
        ]);
    }

    /**
     * Moduli per-cliente ancora in sospeso per il cliente autenticato
     * (business + eventuale sede). Usato all'avvio prenotazione.
     */
    public function pendingCustomerForms(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $clientId = $this->clientId($request);
        if ($clientId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }
        $locationId = (int) ($request->queryParam('location_id') ?? 0);

        return Response::success([
            'forms' => $this->bookingFormRepo->resolvePendingCustomerForms(
                $businessId,
                $clientId,
                $locationId > 0 ? $locationId : null,
            ),
        ]);
    }

    /**
     * Salva le risposte ai moduli per-cliente per il cliente autenticato.
     */
    public function submitCustomerForms(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $clientId = $this->clientId($request);
        if ($clientId === null) {
            return Response::unauthorized('Authentication required', $request->traceId);
        }

        $body = $this->body($request);
        $submissions = $body['submissions'] ?? [];
        if (!is_array($submissions)) {
            return Response::error('submissions is required', 'validation_error', 422, $request->traceId);
        }
        $locationId = (int) ($body['location_id'] ?? 0);

        try {
            $this->bookingFormRepo->validateAndSaveCustomerSubmissions(
                $businessId,
                $clientId,
                $locationId > 0 ? $locationId : null,
                $submissions,
            );
        } catch (\Throwable $e) {
            return Response::error($e->getMessage(), 'validation_error', 422, $request->traceId);
        }

        return Response::success([
            'forms' => $this->bookingFormRepo->resolvePendingCustomerForms(
                $businessId,
                $clientId,
                $locationId > 0 ? $locationId : null,
            ),
        ]);
    }

    /**
     * Risposte ai moduli per-cliente di un cliente, per la scheda cliente del
     * gestionale (sola lettura).
     */
    public function clientFormSubmissions(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $clientId = (int) $request->getRouteParam('client_id');
        if (!$this->hasReadAccess($request, $businessId)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        return Response::success([
            'form_submissions' => $this->bookingFormRepo->getCustomerSubmissions($businessId, $clientId),
        ]);
    }

    private function clientId(Request $request): ?int
    {
        $clientId = $request->getAttribute('client_id');
        return $clientId !== null ? (int) $clientId : null;
    }

    private function hasManageAccess(Request $request, int $businessId): bool
    {
        $userId = $this->userId($request);
        if ($userId === null) {
            return false;
        }
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }
        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_services', false);
    }

    private function hasBookingManageAccess(Request $request, int $businessId): bool
    {
        $userId = $this->userId($request);
        if ($userId === null) {
            return false;
        }
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }
        return $this->businessUserRepo->hasPermission($userId, $businessId, 'can_manage_bookings', false);
    }

    private function hasReadAccess(Request $request, int $businessId): bool
    {
        $userId = $this->userId($request);
        if ($userId === null) {
            return false;
        }
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }
        return $this->businessUserRepo->hasAccess($userId, $businessId, false);
    }

    private function userId(Request $request): ?int
    {
        $userId = $request->getAttribute('user_id');
        return $userId !== null ? (int) $userId : null;
    }

    private function body(Request $request): array
    {
        $body = $request->getBody();
        return is_array($body) ? $body : [];
    }

    private function ids(mixed $value): array
    {
        if (!is_array($value)) {
            return [];
        }
        return array_values(array_unique(array_filter(array_map('intval', $value), static fn(int $id): bool => $id > 0)));
    }
}
