<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Infrastructure\Environment\EnvironmentPolicy;
use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;

final class LocationsController
{
    private const NEVER_CANCELLATION_HOURS = 100000;
    private const ALLOWED_STAFF_ICON_KEYS = [
        'person',
        'door',
        'team',
        'tennis',
        'soccer',
        'resource',
        'room',
        'court',
        'equipment',
        'wellness',
        'medical',
        'beauty',
        'education',
        'pet',
        'generic',
    ];
    private const COUNTRY_PATTERN = '/^[A-Z]{2}$/';
    private const ALLOWED_BOOKING_DEFAULT_LOCALES = ['it', 'en'];

    public function __construct(
        private readonly LocationRepository $locationRepo,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * Check if authenticated user has access to the given business.
     */
    private function hasBusinessAccess(Request $request, int $businessId): bool
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return false;
        }

        // Superadmin has access to all businesses
        if ($this->userRepo->isSuperadmin($userId)) {
            return true;
        }

        // Normal user: check business_users table
        return $this->businessUserRepo->hasAccess($userId, $businessId, false);
    }

    /**
     * GET /v1/businesses/{business_id}/locations
     * List all locations for a business (authenticated - includes inactive)
     */
    public function index(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');

        // Authorization check
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::forbidden('You do not have access to this business', $request->traceId);
        }

        // For authenticated users (gestionale), show ALL locations including inactive
        $locations = $this->locationRepo->findByBusinessId($businessId, includeInactive: true);

        return Response::success([
            'data' => array_map(fn($l) => $this->formatLocation($l), $locations),
        ]);
    }

    /**
     * GET /v1/businesses/{business_id}/locations/public
     * List all locations for a business (public - for booking flow, only active)
     */
    public function indexPublic(Request $request): Response
    {
        $businessId = (int) $request->getAttribute('business_id');

        if ($businessId <= 0) {
            return Response::error('Invalid business_id', 'validation_error', 400, $request->traceId);
        }

        // For public (booking), show only active locations
        $locations = $this->locationRepo->findByBusinessId($businessId, includeInactive: false);

        return Response::success([
            'data' => array_map(fn($l) => $this->formatLocationPublic($l), $locations),
        ]);
    }

    /**
     * GET /v1/locations/{id}
     * Get a single location by ID
     */
    public function show(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('id');

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        // Authorization check
        $businessId = (int) $location['business_id'];
        if (!$this->hasBusinessAccess($request, $businessId)) {
            return Response::notFound('Location not found', $request->traceId);
        }

        return Response::success($this->formatLocation($location));;
    }

    private function formatLocation(array $row): array
    {
        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'name' => $row['name'],
            'address' => $row['address'],
            'city' => $row['city'],
            'region' => $row['region'],
            'country' => $row['country'],
            'phone' => $row['phone'],
            'email' => $row['email'],
            'latitude' => $row['latitude'] ? (float) $row['latitude'] : null,
            'longitude' => $row['longitude'] ? (float) $row['longitude'] : null,
            'currency' => $row['currency'],
            'timezone' => $row['timezone'] ?? 'Europe/Rome',
            'booking_default_locale' => $row['booking_default_locale'],
            'min_booking_notice_hours' => (int) ($row['min_booking_notice_hours'] ?? 1),
            'max_booking_advance_days' => (int) ($row['max_booking_advance_days'] ?? 90),
            'allow_customer_choose_staff' => (bool) ($row['allow_customer_choose_staff'] ?? false),
            'staff_icon_key' => $this->normalizeStaffIconKey($row['staff_icon_key'] ?? null),
            'booking_text_overrides' => $this->decodeBookingTextOverrides($row['booking_text_overrides_json'] ?? null),
            'cancellation_hours' => isset($row['cancellation_hours']) ? (int) $row['cancellation_hours'] : null,
            'online_booking_slot_interval_minutes' => (int) ($row['online_booking_slot_interval_minutes'] ?? 15),
            'slot_display_mode' => $row['slot_display_mode'] ?? 'all',
            'min_gap_minutes' => (int) ($row['min_gap_minutes'] ?? 30),
            'is_default' => (bool) $row['is_default'],
            'sort_order' => (int) ($row['sort_order'] ?? 0),
            'is_active' => (bool) $row['is_active'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'],
        ];
    }

    /**
     * Format location for public display (limited fields for booking)
     */
    private function formatLocationPublic(array $row): array
    {
        return [
            'id' => (int) $row['id'],
            'business_id' => (int) $row['business_id'],
            'name' => $row['name'],
            'address' => $row['address'],
            'city' => $row['city'],
            'phone' => $row['phone'],
            'timezone' => $row['timezone'] ?? 'Europe/Rome',
            'country' => $row['country'],
            'booking_default_locale' => $row['booking_default_locale'],
            'min_booking_notice_hours' => (int) ($row['min_booking_notice_hours'] ?? 1),
            'max_booking_advance_days' => (int) ($row['max_booking_advance_days'] ?? 90),
            'allow_customer_choose_staff' => (bool) ($row['allow_customer_choose_staff'] ?? false),
            'staff_icon_key' => $this->normalizeStaffIconKey($row['staff_icon_key'] ?? null),
            'booking_text_overrides' => $this->decodeBookingTextOverrides($row['booking_text_overrides_json'] ?? null),
            'cancellation_hours' => isset($row['cancellation_hours']) ? (int) $row['cancellation_hours'] : null,
            'is_default' => (bool) $row['is_default'],
        ];
    }

    /**
     * POST /v1/businesses/{business_id}/locations
     * Create a new location for a business
     */
    public function store(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        // Check user has access to business
        if (!$this->businessUserRepo->hasAccess($userId, $businessId, $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();
        
        // Validate required fields
        if (empty($body['name'])) {
            return Response::error('Name is required', 'validation_error', 400, $request->traceId);
        }

        $countryError = null;
        $country = $this->normalizeCountry($body['country'] ?? null, true, $countryError);
        if ($countryError !== null) {
            return Response::error($countryError, 'validation_error', 400, $request->traceId);
        }

        $timezoneError = null;
        $timezone = $this->normalizeTimezone($body['timezone'] ?? 'Europe/Rome', true, $timezoneError);
        if ($timezoneError !== null) {
            return Response::error($timezoneError, 'validation_error', 400, $request->traceId);
        }
        $bookingDefaultLocaleError = null;
        $bookingDefaultLocale = $this->normalizeBookingDefaultLocale(
            $body['booking_default_locale'] ?? null,
            $bookingDefaultLocaleError,
        );
        if ($bookingDefaultLocaleError !== null) {
            return Response::error($bookingDefaultLocaleError, 'validation_error', 400, $request->traceId);
        }

        $cancellationHours = null;
        if (array_key_exists('cancellation_hours', $body)) {
            if ($body['cancellation_hours'] === null) {
                $cancellationHours = null;
            } else {
                $hours = (int) $body['cancellation_hours'];
                if (($hours >= 0 && $hours <= 720) || $hours === self::NEVER_CANCELLATION_HOURS) {
                    $cancellationHours = $hours;
                }
            }
        }

        $bookingTextOverridesError = null;
        $bookingTextOverridesJson = null;
        if (array_key_exists('booking_text_overrides', $body)) {
            $bookingTextOverridesJson = $this->normalizeBookingTextOverrides(
                $body['booking_text_overrides'],
                $bookingTextOverridesError,
            );
            if ($bookingTextOverridesError !== null) {
                return Response::error($bookingTextOverridesError, 'validation_error', 400, $request->traceId);
            }
        }

        $staffIconKey = $this->normalizeStaffIconKey($body['staff_icon_key'] ?? null, strict: true);
        if (array_key_exists('staff_icon_key', $body) && $staffIconKey === null) {
            return Response::error('staff_icon_key is invalid', 'validation_error', 400, $request->traceId);
        }

        $locationId = $this->locationRepo->create($businessId, $body['name'], [
            'address' => $body['address'] ?? null,
            'country' => $country,
            'phone' => $body['phone'] ?? null,
            'email' => $body['email'] ?? null,
            'timezone' => $timezone,
            'booking_default_locale' => $bookingDefaultLocale,
            'min_booking_notice_hours' => $body['min_booking_notice_hours'] ?? 1,
            'max_booking_advance_days' => $body['max_booking_advance_days'] ?? 90,
            'allow_customer_choose_staff' => $body['allow_customer_choose_staff'] ?? false,
            'cancellation_hours' => $cancellationHours,
            'booking_text_overrides_json' => $bookingTextOverridesJson,
            'staff_icon_key' => $staffIconKey ?? 'person',
            'is_active' => $body['is_active'] ?? true,
        ]);

        $location = $this->locationRepo->findById($locationId);

        return Response::created([
            'location' => $this->formatLocation($location),
        ]);
    }

    /**
     * PUT /v1/locations/{id}
     * Update a location
     */
    public function update(Request $request): Response
    {
        $locationId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        // Check user has access to business
        if (!$this->businessUserRepo->hasAccess($userId, (int) $location['business_id'], $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        $body = $request->getBody();
        
        $updateData = [
            'name' => $body['name'] ?? $location['name'],
            'address' => array_key_exists('address', $body) ? $body['address'] : $location['address'],
            'phone' => array_key_exists('phone', $body) ? $body['phone'] : $location['phone'],
            'email' => array_key_exists('email', $body) ? $body['email'] : $location['email'],
            'is_active' => array_key_exists('is_active', $body) ? $body['is_active'] : $location['is_active'],
        ];

        if (array_key_exists('country', $body)) {
            $countryError = null;
            $country = $this->normalizeCountry($body['country'], true, $countryError);
            if ($countryError !== null) {
                return Response::error($countryError, 'validation_error', 400, $request->traceId);
            }
            $updateData['country'] = $country;
        }

        if (array_key_exists('timezone', $body)) {
            $timezoneError = null;
            $timezone = $this->normalizeTimezone($body['timezone'], true, $timezoneError);
            if ($timezoneError !== null) {
                return Response::error($timezoneError, 'validation_error', 400, $request->traceId);
            }
            $updateData['timezone'] = $timezone;
        }
        if (array_key_exists('booking_default_locale', $body)) {
            $bookingDefaultLocaleError = null;
            $bookingDefaultLocale = $this->normalizeBookingDefaultLocale(
                $body['booking_default_locale'],
                $bookingDefaultLocaleError,
            );
            if ($bookingDefaultLocaleError !== null) {
                return Response::error($bookingDefaultLocaleError, 'validation_error', 400, $request->traceId);
            }
            $updateData['booking_default_locale'] = $bookingDefaultLocale;
        }

        if (array_key_exists('allow_customer_choose_staff', $body)) {
            $updateData['allow_customer_choose_staff'] = (bool) $body['allow_customer_choose_staff'];
        }
        if (array_key_exists('booking_text_overrides', $body)) {
            $bookingTextOverridesError = null;
            $bookingTextOverridesJson = $this->normalizeBookingTextOverrides(
                $body['booking_text_overrides'],
                $bookingTextOverridesError,
            );
            if ($bookingTextOverridesError !== null) {
                return Response::error($bookingTextOverridesError, 'validation_error', 400, $request->traceId);
            }
            $updateData['booking_text_overrides_json'] = $bookingTextOverridesJson;
        }
        if (array_key_exists('staff_icon_key', $body)) {
            $staffIconKey = $this->normalizeStaffIconKey($body['staff_icon_key'], strict: true);
            if ($staffIconKey === null) {
                return Response::error('staff_icon_key is invalid', 'validation_error', 400, $request->traceId);
            }
            $updateData['staff_icon_key'] = $staffIconKey;
        }

        // Handle booking limits fields
        if (array_key_exists('min_booking_notice_hours', $body)) {
            $updateData['min_booking_notice_hours'] = (int) $body['min_booking_notice_hours'];
        }
        if (array_key_exists('max_booking_advance_days', $body)) {
            $updateData['max_booking_advance_days'] = (int) $body['max_booking_advance_days'];
        }
        if (array_key_exists('cancellation_hours', $body)) {
            if ($body['cancellation_hours'] === null) {
                $updateData['cancellation_hours'] = null;
            } else {
                $hours = (int) $body['cancellation_hours'];
                if (($hours >= 0 && $hours <= 720) || $hours === self::NEVER_CANCELLATION_HOURS) {
                    $updateData['cancellation_hours'] = $hours;
                }
            }
        }

        // Handle smart slot display settings
        if (array_key_exists('online_booking_slot_interval_minutes', $body)) {
            $interval = (int) $body['online_booking_slot_interval_minutes'];
            // Validate interval is reasonable (5-120 minutes)
            if ($interval >= 5 && $interval <= 120) {
                $updateData['online_booking_slot_interval_minutes'] = $interval;
            }
        }
        if (array_key_exists('slot_display_mode', $body)) {
            $mode = $body['slot_display_mode'];
            if (in_array($mode, ['all', 'min_gap'], true)) {
                $updateData['slot_display_mode'] = $mode;
            }
        }
        if (array_key_exists('min_gap_minutes', $body)) {
            $gap = (int) $body['min_gap_minutes'];
            // Validate gap is reasonable (0-120 minutes)
            if ($gap >= 0 && $gap <= 120) {
                $updateData['min_gap_minutes'] = $gap;
            }
        }

        $this->locationRepo->update($locationId, $updateData);

        $updated = $this->locationRepo->findById($locationId);

        return Response::success([
            'location' => $this->formatLocation($updated),
        ]);
    }

    /**
     * DELETE /v1/locations/{id}
     * Soft delete a location
     */
    public function destroy(Request $request): Response
    {
        $policy = EnvironmentPolicy::current();
        if (!$policy->canDeleteLocation()) {
            return Response::demoBlocked('Eliminazione location non consentita in ambiente demo', $request->traceId);
        }

        $locationId = (int) $request->getRouteParam('id');
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $location = $this->locationRepo->findById($locationId);
        if (!$location) {
            return Response::notFound('Location not found', $request->traceId);
        }

        $businessId = (int) $location['business_id'];

        // Check user has access to business
        if (!$this->businessUserRepo->hasAccess($userId, $businessId, $isSuperadmin)) {
            return Response::error('Access denied', 'forbidden', 403, $request->traceId);
        }

        // Cannot delete the only location
        if ($this->locationRepo->isOnlyActiveLocation($locationId, $businessId)) {
            return Response::error('Cannot delete the only location', 'validation_error', 400, $request->traceId);
        }

        $this->locationRepo->delete($locationId);

        return Response::success(['deleted' => true]);
    }

    /**
     * POST /v1/locations/reorder
     * Batch update sort_order for multiple locations.
     * Body: { "locations": [{ "id": 1, "sort_order": 0 }, { "id": 2, "sort_order": 1 }] }
     */
    public function reorder(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        $isSuperadmin = $this->userRepo->isSuperadmin($userId);

        $body = $request->getBody();
        $locationList = $body['locations'] ?? [];

        if (empty($locationList) || !is_array($locationList)) {
            return Response::error('locations array is required', 'validation_error', 400, $request->traceId);
        }

        // Validate structure
        foreach ($locationList as $item) {
            if (!isset($item['id']) || !isset($item['sort_order'])) {
                return Response::error('Each item must have id and sort_order', 'validation_error', 400, $request->traceId);
            }
        }

        // Check all locations belong to same business
        $locationIds = array_map(fn($l) => (int) $l['id'], $locationList);
        $businessId = $this->locationRepo->allBelongToSameBusiness($locationIds);

        if ($businessId === null) {
            return Response::error('Locations must belong to the same business', 'validation_error', 400, $request->traceId);
        }

        // Check user has access to this business
        if (!$this->businessUserRepo->hasAccess($userId, $businessId, $isSuperadmin)) {
            return Response::forbidden('Access denied', $request->traceId);
        }

        // Perform batch update
        $this->locationRepo->batchUpdateSortOrder($locationList);

        return Response::success(['updated' => count($locationList)]);
    }

    private function decodeBookingTextOverrides(?string $raw): ?array
    {
        if ($raw === null || trim($raw) === '') {
            return null;
        }

        $decoded = json_decode($raw, true);
        if (!is_array($decoded) || empty($decoded)) {
            return null;
        }

        return $decoded;
    }

    private function normalizeBookingTextOverrides(mixed $value, ?string &$error = null): ?string
    {
        $error = null;

        if ($value === null) {
            return null;
        }
        if (!is_array($value)) {
            $error = 'booking_text_overrides must be an object with a single "default" block';
            return null;
        }
        if (empty($value)) {
            return null;
        }

        $keys = array_keys($value);
        if (count($keys) !== 1) {
            $error = 'booking_text_overrides must contain exactly one block: "default"';
            return null;
        }
        $key = strtolower(trim((string) $keys[0]));
        if ($key !== 'default') {
            $error = 'booking_text_overrides block key must be "default"';
            return null;
        }

        $phrases = $value[$keys[0]];
        if (!is_array($phrases)) {
            $error = 'booking_text_overrides.default must be an object of phrase overrides';
            return null;
        }

        $normalizedPhrases = [];
        foreach ($phrases as $phraseKey => $phraseValue) {
            $phraseKeyNorm = trim((string) $phraseKey);
            if ($phraseKeyNorm === '') {
                continue;
            }
            if (strlen($phraseKeyNorm) > 80) {
                $error = 'Invalid phrase key length in booking_text_overrides.default';
                return null;
            }
            if (!is_scalar($phraseValue)) {
                $error = "Phrase value for key {$phraseKeyNorm} in booking_text_overrides.default must be a string";
                return null;
            }
            $text = trim((string) $phraseValue);
            if ($text === '') {
                continue;
            }
            if (mb_strlen($text) > 500) {
                $error = "Phrase value too long for key {$phraseKeyNorm} in booking_text_overrides.default";
                return null;
            }
            $normalizedPhrases[$phraseKeyNorm] = $text;
        }

        if (empty($normalizedPhrases)) {
            return null;
        }

        $normalized = [
            'default' => $normalizedPhrases,
        ];

        $encoded = json_encode($normalized, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if ($encoded === false) {
            $error = 'Unable to encode booking_text_overrides';
            return null;
        }

        return $encoded;
    }

    private function normalizeCountry(mixed $raw, bool $required, ?string &$error): ?string
    {
        $error = null;
        $country = strtoupper(trim((string) ($raw ?? '')));

        if ($country === '') {
            if ($required) {
                $error = 'country is required';
            }
            return null;
        }

        if (!preg_match(self::COUNTRY_PATTERN, $country)) {
            $error = 'country must be an ISO 3166-1 alpha-2 code';
            return null;
        }

        return $country;
    }

    private function normalizeTimezone(mixed $raw, bool $required, ?string &$error): ?string
    {
        $error = null;
        $timezone = trim((string) ($raw ?? ''));

        if ($timezone === '') {
            if ($required) {
                $error = 'timezone is required';
            }
            return null;
        }

        try {
            new \DateTimeZone($timezone);
        } catch (\Throwable) {
            $error = 'timezone must be a valid IANA timezone';
            return null;
        }

        return $timezone;
    }

    private function normalizeBookingDefaultLocale(mixed $raw, ?string &$error): ?string
    {
        $error = null;
        $locale = strtolower(trim((string) ($raw ?? '')));
        if ($locale === '') {
            return null;
        }

        if (!in_array($locale, self::ALLOWED_BOOKING_DEFAULT_LOCALES, true)) {
            $error = 'booking_default_locale must be one of: it, en';
            return null;
        }

        return $locale;
    }

    private function normalizeStaffIconKey(mixed $value, bool $strict = false): ?string
    {
        if ($value === null) {
            return 'person';
        }
        $key = strtolower(trim((string) $value));
        if ($key === '') {
            return 'person';
        }
        if (!in_array($key, self::ALLOWED_STAFF_ICON_KEYS, true)) {
            return $strict ? null : 'person';
        }
        return $key;
    }
}
