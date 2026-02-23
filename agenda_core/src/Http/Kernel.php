<?php

declare(strict_types=1);

namespace Agenda\Http;

use Agenda\Http\Controllers\AuthController;
use Agenda\Http\Controllers\AvailabilityController;
use Agenda\Http\Controllers\BookingsController;
use Agenda\Http\Controllers\BusinessController;
use Agenda\Http\Controllers\AdminBusinessesController;
use Agenda\Http\Controllers\BusinessUsersController;
use Agenda\Http\Controllers\BusinessInvitationsController;
use Agenda\Http\Controllers\ClientsController;
use Agenda\Http\Controllers\CrmClientsController;
use Agenda\Http\Controllers\CustomerAuthController;
use Agenda\Http\Controllers\HealthController;
use Agenda\Http\Controllers\LocationsController;
use Agenda\Http\Controllers\ServicesController;
use Agenda\Http\Controllers\StaffController;
use Agenda\Http\Controllers\StaffAvailabilityExceptionController;
use Agenda\Http\Controllers\StaffPlanningController;
use Agenda\Http\Controllers\ResourcesController;
use Agenda\Http\Controllers\ServicePackagesController;
use Agenda\Http\Controllers\ServiceVariantResourceController;
use Agenda\Http\Controllers\TimeBlocksController;
use Agenda\Http\Controllers\AppointmentsController;
use Agenda\Http\Controllers\BookingNotificationsController;
use Agenda\Http\Controllers\BusinessSyncController;
use Agenda\Http\Controllers\LocationClosuresController;
use Agenda\Http\Controllers\ClassEventsController;
use Agenda\Http\Controllers\ReportsController;
use Agenda\Http\Middleware\AuthMiddleware;
use Agenda\Http\Middleware\BusinessAccessMiddleware;
use Agenda\Http\Middleware\CustomerAuthMiddleware;
use Agenda\Http\Middleware\IdempotencyMiddleware;
use Agenda\Http\Middleware\LocationAccessMiddleware;
use Agenda\Http\Middleware\LocationContextMiddleware;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Logger\Logger;
use Agenda\Infrastructure\Repositories\AuthSessionRepository;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\BusinessInvitationRepository;
use Agenda\Infrastructure\Repositories\ClientAuthRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Repositories\CrmClientRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\ServiceRepository;
use Agenda\Infrastructure\Repositories\ServicePackageRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\StaffAvailabilityExceptionRepository;
use Agenda\Infrastructure\Repositories\StaffPlanningRepository;
use Agenda\Infrastructure\Repositories\ResourceRepository;
use Agenda\Infrastructure\Repositories\ServiceVariantResourceRepository;
use Agenda\Infrastructure\Repositories\TimeBlockRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Notifications\NotificationRepository;
use Agenda\Infrastructure\Repositories\PopularServiceRepository;
use Agenda\Infrastructure\Repositories\LocationClosureRepository;
use Agenda\Infrastructure\Repositories\ClassEventRepository;
use Agenda\Infrastructure\Security\JwtService;
use Agenda\Infrastructure\Security\PasswordHasher;
use Agenda\UseCases\Auth\GetMe;
use Agenda\UseCases\Auth\LoginUser;
use Agenda\UseCases\Auth\LogoutUser;
use Agenda\UseCases\Auth\RefreshToken;
use Agenda\UseCases\Auth\RegisterUser;
use Agenda\UseCases\Auth\RequestPasswordReset;
use Agenda\UseCases\Auth\ResetPassword;
use Agenda\UseCases\Auth\VerifyResetToken;
use Agenda\UseCases\Auth\ChangePassword;
use Agenda\UseCases\Auth\UpdateProfile;
use Agenda\UseCases\Booking\ComputeAvailability;
use Agenda\UseCases\Booking\CreateBooking;
use Agenda\UseCases\Booking\CreateRecurringBooking;
use Agenda\UseCases\Booking\PreviewRecurringBooking;
use Agenda\UseCases\Booking\ModifyRecurringSeries;
use Agenda\UseCases\Booking\UpdateBooking;
use Agenda\UseCases\Booking\DeleteBooking;
use Agenda\UseCases\Booking\GetMyBookings;
use Agenda\UseCases\Booking\ReplaceBooking;
use Agenda\UseCases\CustomerAuth\LoginCustomer;
use Agenda\UseCases\CustomerAuth\RegisterCustomer;
use Agenda\UseCases\CustomerAuth\RefreshCustomerToken;
use Agenda\UseCases\CustomerAuth\LogoutCustomer;
use Agenda\UseCases\CustomerAuth\GetCustomerMe;
use Agenda\UseCases\CustomerAuth\RequestCustomerPasswordReset;
use Agenda\UseCases\CustomerAuth\ResetCustomerPassword;
use Agenda\UseCases\CustomerAuth\UpdateCustomerProfile;
use Agenda\UseCases\CustomerAuth\ChangeCustomerPassword;
use Agenda\UseCases\Admin\ExportBusiness;
use Agenda\UseCases\Admin\ImportBusiness;
use Agenda\Infrastructure\Repositories\BookingAuditRepository;
use Agenda\Infrastructure\Repositories\RecurrenceRuleRepository;
use Throwable;

final class Kernel
{
    private Router $router;
    private Connection $db;
    private Logger $logger;
    private array $middleware = [];
    private array $controllers = [];

    public function __construct()
    {
        $this->db = new Connection();
        $this->logger = new Logger();
        $this->router = new Router();
        
        $this->registerRoutes();
        $this->registerMiddleware();
        $this->registerControllers();
    }

    private function registerRoutes(): void
    {
        // Health check (no auth, no business context)
        $this->router->get('/health', HealthController::class, 'check');

        // Auth (no business context)
        $this->router->post('/v1/auth/login', AuthController::class, 'login');
        $this->router->post('/v1/auth/register', AuthController::class, 'register');
        $this->router->post('/v1/auth/refresh', AuthController::class, 'refresh');
        $this->router->post('/v1/auth/logout', AuthController::class, 'logout', ['auth']);
        $this->router->post('/v1/auth/forgot-password', AuthController::class, 'forgotPassword');
        $this->router->get('/v1/auth/verify-reset-token/{token}', AuthController::class, 'verifyResetTokenAction');
        $this->router->post('/v1/auth/reset-password', AuthController::class, 'resetPasswordAction');
        $this->router->get('/v1/me', AuthController::class, 'me', ['auth']);
        $this->router->put('/v1/me', AuthController::class, 'updateMe', ['auth']);
        $this->router->post('/v1/me/change-password', AuthController::class, 'changePassword', ['auth']);
        $this->router->get('/v1/me/business/{business_id}', AuthController::class, 'myBusinessContext', ['auth']);
        $this->router->get('/v1/me/bookings', BookingsController::class, 'myBookings', ['auth']);
        $this->router->get('/v1/me/businesses', AdminBusinessesController::class, 'myBusinesses', ['auth']);

        // Admin/Superadmin endpoints
        $this->router->get('/v1/admin/businesses', AdminBusinessesController::class, 'index', ['auth']);
        $this->router->post('/v1/admin/businesses', AdminBusinessesController::class, 'store', ['auth']);
        $this->router->put('/v1/admin/businesses/{id}', AdminBusinessesController::class, 'update', ['auth']);
        $this->router->delete('/v1/admin/businesses/{id}', AdminBusinessesController::class, 'destroy', ['auth']);
        $this->router->post('/v1/admin/businesses/{id}/resend-invite', AdminBusinessesController::class, 'resendInvite', ['auth']);
        
        // Business Sync (sincronizzazione tra ambienti)
        $this->router->get('/v1/admin/businesses/{id}/export', BusinessSyncController::class, 'export', ['auth']);
        $this->router->get('/v1/admin/businesses/by-slug/{slug}/export', BusinessSyncController::class, 'exportBySlug', ['auth']);
        $this->router->post('/v1/admin/businesses/import', BusinessSyncController::class, 'import', ['auth']);
        $this->router->post('/v1/admin/businesses/sync-from-production', BusinessSyncController::class, 'syncFromProduction', ['auth']);

        // Businesses - Public endpoint for subdomain resolution
        $this->router->get('/v1/businesses/by-slug/{slug}', BusinessController::class, 'showBySlug');
        // Public locations for a business (for booking flow)
        $this->router->get('/v1/businesses/{business_id}/locations/public', LocationsController::class, 'indexPublic');
        
        // Calendar ICS download (public, token-protected)

        // Businesses and Locations (auth required)
        $this->router->get('/v1/businesses', BusinessController::class, 'index', ['auth']);
        $this->router->get('/v1/businesses/{id}', BusinessController::class, 'show', ['auth']);
        $this->router->get('/v1/businesses/{business_id}/locations', LocationsController::class, 'index', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/locations', LocationsController::class, 'store', ['auth']);
        $this->router->get('/v1/locations/{id}', LocationsController::class, 'show', ['auth']);
        $this->router->put('/v1/locations/{id}', LocationsController::class, 'update', ['auth']);
        $this->router->delete('/v1/locations/{id}', LocationsController::class, 'destroy', ['auth']);
        $this->router->post('/v1/locations/reorder', LocationsController::class, 'reorder', ['auth']);

        // Staff management (auth required)
        $this->router->get('/v1/businesses/{business_id}/staff', StaffController::class, 'indexByBusiness', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/staff', StaffController::class, 'store', ['auth']);
        $this->router->put('/v1/staff/{id}', StaffController::class, 'update', ['auth']);
        $this->router->delete('/v1/staff/{id}', StaffController::class, 'destroy', ['auth']);
        $this->router->post('/v1/staff/reorder', StaffController::class, 'reorder', ['auth']);

        // Staff availability exceptions (auth required)
        $this->router->get('/v1/businesses/{business_id}/staff/availability-exceptions', StaffAvailabilityExceptionController::class, 'indexForBusiness', ['auth']);
        $this->router->get('/v1/staff/{id}/availability-exceptions', StaffAvailabilityExceptionController::class, 'indexForStaff', ['auth']);
        $this->router->post('/v1/staff/{id}/availability-exceptions', StaffAvailabilityExceptionController::class, 'store', ['auth']);
        $this->router->put('/v1/staff/availability-exceptions/{id}', StaffAvailabilityExceptionController::class, 'update', ['auth']);
        $this->router->delete('/v1/staff/availability-exceptions/{id}', StaffAvailabilityExceptionController::class, 'destroy', ['auth']);

        // Staff planning (auth required)
        $this->router->get('/v1/staff/{id}/plannings', StaffPlanningController::class, 'indexForStaff', ['auth']);
        $this->router->get('/v1/staff/{id}/planning', StaffPlanningController::class, 'showForDate', ['auth']);
        $this->router->get('/v1/staff/{id}/planning/{planning_id}', StaffPlanningController::class, 'show', ['auth']);
        $this->router->get('/v1/staff/{id}/planning-availability', StaffPlanningController::class, 'availabilityForDate', ['auth']);
        $this->router->post('/v1/staff/{id}/plannings', StaffPlanningController::class, 'store', ['auth']);
        $this->router->put('/v1/staff/{id}/plannings/{planning_id}', StaffPlanningController::class, 'update', ['auth']);
        $this->router->delete('/v1/staff/{id}/plannings/{planning_id}', StaffPlanningController::class, 'destroy', ['auth']);

        // Resources (auth required)
        $this->router->get('/v1/businesses/{business_id}/resources', ResourcesController::class, 'indexByBusiness', ['auth']);
        $this->router->get('/v1/locations/{location_id}/resources', ResourcesController::class, 'indexByLocation', ['auth', 'location_path', 'location_access']);
        $this->router->post('/v1/locations/{location_id}/resources', ResourcesController::class, 'store', ['auth', 'location_path', 'location_access']);
        $this->router->put('/v1/resources/{id}', ResourcesController::class, 'update', ['auth']);
        $this->router->delete('/v1/resources/{id}', ResourcesController::class, 'destroy', ['auth']);

        // Service Variant Resources (auth required)
        $this->router->get('/v1/service-variants/{id}/resources', ServiceVariantResourceController::class, 'index', ['auth']);
        $this->router->put('/v1/service-variants/{id}/resources', ServiceVariantResourceController::class, 'update', ['auth']);
        $this->router->post('/v1/service-variants/{id}/resources', ServiceVariantResourceController::class, 'store', ['auth']);
        $this->router->delete('/v1/service-variants/{id}/resources/{resource_id}', ServiceVariantResourceController::class, 'destroy', ['auth']);

        // Resource Services (auth required) - manage from resource perspective
        $this->router->get('/v1/resources/{id}/services', ServiceVariantResourceController::class, 'servicesByResource', ['auth']);
        $this->router->put('/v1/resources/{id}/services', ServiceVariantResourceController::class, 'updateServicesByResource', ['auth']);

        // Business Users (operators management)
        $this->router->get('/v1/businesses/{business_id}/users', BusinessUsersController::class, 'index', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/users', BusinessUsersController::class, 'store', ['auth']);
        $this->router->patch('/v1/businesses/{business_id}/users/{target_user_id}', BusinessUsersController::class, 'update', ['auth']);
        $this->router->delete('/v1/businesses/{business_id}/users/{target_user_id}', BusinessUsersController::class, 'destroy', ['auth']);

        // Current user's business context (for permissions)
        $this->router->get('/v1/me/business/{business_id}', BusinessUsersController::class, 'meContext', ['auth']);

        // Business Invitations
        $this->router->get('/v1/businesses/{business_id}/invitations', BusinessInvitationsController::class, 'index', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/invitations', BusinessInvitationsController::class, 'store', ['auth']);
        $this->router->delete('/v1/businesses/{business_id}/invitations/{invitation_id}', BusinessInvitationsController::class, 'destroy', ['auth']);
        $this->router->get('/v1/invitations/{token}', BusinessInvitationsController::class, 'show');
        $this->router->post('/v1/invitations/{token}/accept', BusinessInvitationsController::class, 'accept', ['auth']);
        $this->router->post('/v1/invitations/{token}/accept-public', BusinessInvitationsController::class, 'acceptPublic');
        $this->router->post('/v1/invitations/{token}/decline', BusinessInvitationsController::class, 'decline');
        $this->router->post('/v1/invitations/{token}/register', BusinessInvitationsController::class, 'register');

        // Public (business-scoped via query param)
        $this->router->get('/v1/services', ServicesController::class, 'index', ['location_query']);
        $this->router->get('/v1/staff/{staff_id}/services/popular', ServicesController::class, 'popular', ['auth']);
        $this->router->get('/v1/staff', StaffController::class, 'index', ['location_query']);
        $this->router->get('/v1/availability', AvailabilityController::class, 'index', ['location_query']);

        // Services CRUD (auth required)
        $this->router->post('/v1/businesses/{business_id}/services', ServicesController::class, 'storeMultiLocation', ['auth', 'business_access_route']);
        $this->router->post('/v1/locations/{location_id}/services', ServicesController::class, 'store', ['auth', 'location_path', 'location_access']);
        $this->router->put('/v1/services/{id}', ServicesController::class, 'update', ['auth']);
        $this->router->delete('/v1/services/{id}', ServicesController::class, 'destroy', ['auth']);
        $this->router->post('/v1/services/reorder', ServicesController::class, 'reorderServices', ['auth']);
        $this->router->get('/v1/services/{id}/locations', ServicesController::class, 'getLocations', ['auth']);
        $this->router->put('/v1/services/{id}/locations', ServicesController::class, 'updateLocations', ['auth']);

        // Class Events (auth required)
        $this->router->get('/v1/businesses/{business_id}/class-types', ClassEventsController::class, 'indexTypes', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/class-types', ClassEventsController::class, 'storeType', ['auth']);
        $this->router->put('/v1/businesses/{business_id}/class-types/{id}', ClassEventsController::class, 'updateType', ['auth']);
        $this->router->delete('/v1/businesses/{business_id}/class-types/{id}', ClassEventsController::class, 'destroyType', ['auth']);
        $this->router->get('/v1/businesses/{business_id}/class-events', ClassEventsController::class, 'index', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/class-events', ClassEventsController::class, 'store', ['auth']);
        $this->router->get('/v1/businesses/{business_id}/class-events/{id}', ClassEventsController::class, 'show', ['auth']);
        $this->router->put('/v1/businesses/{business_id}/class-events/{id}', ClassEventsController::class, 'update', ['auth']);
        $this->router->delete('/v1/businesses/{business_id}/class-events/{id}', ClassEventsController::class, 'destroy', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/class-events/{id}/cancel', ClassEventsController::class, 'cancel', ['auth']);
        $this->router->get('/v1/businesses/{business_id}/class-events/{id}/participants', ClassEventsController::class, 'participants', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/class-events/{id}/book', ClassEventsController::class, 'book', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/class-events/{id}/cancel-booking', ClassEventsController::class, 'cancelBooking', ['auth']);

        // Service Packages (public)
        $this->router->get('/v1/locations/{location_id}/service-packages', ServicePackagesController::class, 'index', ['location_path']);
        $this->router->get('/v1/locations/{location_id}/service-packages/{id}/expand', ServicePackagesController::class, 'expand', ['location_path']);

        // Service Packages CRUD (auth required)
        $this->router->post('/v1/locations/{location_id}/service-packages', ServicePackagesController::class, 'store', ['auth', 'location_path', 'location_access']);
        $this->router->put('/v1/locations/{location_id}/service-packages/{id}', ServicePackagesController::class, 'update', ['auth', 'location_path', 'location_access']);
        $this->router->delete('/v1/locations/{location_id}/service-packages/{id}', ServicePackagesController::class, 'destroy', ['auth', 'location_path', 'location_access']);
        $this->router->post('/v1/service-packages/reorder', ServicePackagesController::class, 'reorder', ['auth']);

        // Service Categories CRUD (auth required)
        $this->router->get('/v1/businesses/{business_id}/categories', ServicesController::class, 'indexCategories', ['auth', 'business_access_route']);
        $this->router->post('/v1/businesses/{business_id}/categories', ServicesController::class, 'storeCategory', ['auth', 'business_access_route']);
        $this->router->put('/v1/categories/{id}', ServicesController::class, 'updateCategory', ['auth']);
        $this->router->delete('/v1/categories/{id}', ServicesController::class, 'destroyCategory', ['auth']);
        $this->router->post('/v1/categories/reorder', ServicesController::class, 'reorderCategories', ['auth']);

        // Clients (auth required)
        $this->router->get('/v1/clients', ClientsController::class, 'index', ['auth']);
        $this->router->get('/v1/clients/{id}', ClientsController::class, 'show', ['auth']);
        $this->router->get('/v1/clients/{id}/appointments', ClientsController::class, 'appointments', ['auth']);
        $this->router->post('/v1/clients', ClientsController::class, 'store', ['auth']);
        $this->router->put('/v1/clients/{id}', ClientsController::class, 'update', ['auth']);
        $this->router->delete('/v1/clients/{id}', ClientsController::class, 'destroy', ['auth']);

        // CRM clients (business scoped, non-breaking)
        $this->router->get('/v1/businesses/{business_id}/clients', CrmClientsController::class, 'index', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients', CrmClientsController::class, 'store', ['auth']);
        $this->router->get('/v1/businesses/{business_id}/clients/{client_id}', CrmClientsController::class, 'show', ['auth']);
        $this->router->patch('/v1/businesses/{business_id}/clients/{client_id}', CrmClientsController::class, 'patch', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/archive', CrmClientsController::class, 'archive', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/unarchive', CrmClientsController::class, 'unarchive', ['auth']);

        $this->router->get('/v1/businesses/{business_id}/client-tags', CrmClientsController::class, 'listTags', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/client-tags', CrmClientsController::class, 'createTag', ['auth']);
        $this->router->delete('/v1/businesses/{business_id}/client-tags/{tag_id}', CrmClientsController::class, 'deleteTag', ['auth']);
        $this->router->put('/v1/businesses/{business_id}/clients/{client_id}/tags', CrmClientsController::class, 'replaceTags', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/tags/{tag_id}', CrmClientsController::class, 'addTag', ['auth']);
        $this->router->delete('/v1/businesses/{business_id}/clients/{client_id}/tags/{tag_id}', CrmClientsController::class, 'removeTag', ['auth']);

        $this->router->get('/v1/businesses/{business_id}/clients/{client_id}/consents', CrmClientsController::class, 'getConsents', ['auth']);
        $this->router->put('/v1/businesses/{business_id}/clients/{client_id}/consents', CrmClientsController::class, 'putConsents', ['auth']);

        $this->router->get('/v1/businesses/{business_id}/clients/{client_id}/contacts', CrmClientsController::class, 'listContacts', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/contacts', CrmClientsController::class, 'createContact', ['auth']);
        $this->router->patch('/v1/businesses/{business_id}/clients/{client_id}/contacts/{contact_id}', CrmClientsController::class, 'patchContact', ['auth']);
        $this->router->delete('/v1/businesses/{business_id}/clients/{client_id}/contacts/{contact_id}', CrmClientsController::class, 'deleteContact', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/contacts/{contact_id}/make-primary', CrmClientsController::class, 'makePrimaryContact', ['auth']);

        $this->router->get('/v1/businesses/{business_id}/clients/{client_id}/events', CrmClientsController::class, 'listEvents', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/events', CrmClientsController::class, 'createEvent', ['auth']);

        $this->router->get('/v1/businesses/{business_id}/clients/{client_id}/tasks', CrmClientsController::class, 'listTasks', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/tasks', CrmClientsController::class, 'createTask', ['auth']);
        $this->router->patch('/v1/businesses/{business_id}/clients/{client_id}/tasks/{task_id}', CrmClientsController::class, 'patchTask', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/tasks/{task_id}/complete', CrmClientsController::class, 'completeTask', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/tasks/{task_id}/reopen', CrmClientsController::class, 'reopenTask', ['auth']);

        $this->router->get('/v1/businesses/{business_id}/clients/{client_id}/loyalty', CrmClientsController::class, 'getLoyalty', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/loyalty/adjust', CrmClientsController::class, 'adjustLoyalty', ['auth']);

        $this->router->get('/v1/businesses/{business_id}/clients/dedup/suggestions', CrmClientsController::class, 'dedupSuggestions', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{source_client_id}/merge-into/{target_client_id}', CrmClientsController::class, 'mergeInto', ['auth']);

        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/gdpr/export', CrmClientsController::class, 'gdprExport', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/{client_id}/gdpr/delete', CrmClientsController::class, 'gdprDelete', ['auth']);

        $this->router->get('/v1/businesses/{business_id}/client-segments', CrmClientsController::class, 'listSegments', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/client-segments', CrmClientsController::class, 'createSegment', ['auth']);
        $this->router->patch('/v1/businesses/{business_id}/client-segments/{segment_id}', CrmClientsController::class, 'updateSegment', ['auth']);
        $this->router->delete('/v1/businesses/{business_id}/client-segments/{segment_id}', CrmClientsController::class, 'deleteSegment', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/clients/import/csv', CrmClientsController::class, 'importCsv', ['auth']);
        $this->router->get('/v1/businesses/{business_id}/clients/export/csv', CrmClientsController::class, 'exportCsv', ['auth']);

        // Bookings (protected, business-scoped via path)
        $this->router->get('/v1/locations/{location_id}/bookings', BookingsController::class, 'index', ['auth', 'location_path', 'location_access']);
        $this->router->get('/v1/locations/{location_id}/bookings/{booking_id}', BookingsController::class, 'show', ['auth', 'location_path', 'location_access']);
        $this->router->post('/v1/locations/{location_id}/bookings', BookingsController::class, 'store', ['auth', 'location_path', 'location_access', 'idempotency']);
        $this->router->put('/v1/locations/{location_id}/bookings/{booking_id}', BookingsController::class, 'update', ['auth', 'location_path', 'location_access']);
        $this->router->delete('/v1/locations/{location_id}/bookings/{booking_id}', BookingsController::class, 'destroy', ['auth', 'location_path', 'location_access']);
        
        // Booking replace (atomic replace pattern)
        $this->router->post('/v1/bookings/{booking_id}/replace', BookingsController::class, 'replace', ['auth']);
        
        // Recurring bookings (gestionale only)
        $this->router->post('/v1/locations/{location_id}/bookings/recurring/preview', BookingsController::class, 'previewRecurring', ['auth', 'location_path', 'location_access']);
        $this->router->post('/v1/locations/{location_id}/bookings/recurring', BookingsController::class, 'storeRecurring', ['auth', 'location_path', 'location_access']);
        $this->router->get('/v1/bookings/recurring/{recurrence_rule_id}', BookingsController::class, 'showRecurringSeries', ['auth']);
        $this->router->patch('/v1/bookings/recurring/{recurrence_rule_id}', BookingsController::class, 'patchRecurringSeries', ['auth']);
        $this->router->delete('/v1/bookings/recurring/{recurrence_rule_id}', BookingsController::class, 'cancelRecurringSeries', ['auth']);
        
        // Booking history (audit trail)
        $this->router->get('/v1/bookings/{booking_id}/history', BookingsController::class, 'history', ['auth']);
        
        // Bookings list (paginated with filters)
        $this->router->get('/v1/businesses/{business_id}/bookings/list', BookingsController::class, 'listAll', ['auth']);
        $this->router->get('/v1/businesses/{business_id}/booking-notifications', BookingNotificationsController::class, 'index', ['auth']);

        // Reports (admin/owner only)
        $this->router->get('/v1/reports/appointments', ReportsController::class, 'appointments', ['auth']);
        $this->router->get('/v1/reports/work-hours', ReportsController::class, 'workHours', ['auth']);

        // Closures (holidays, vacation periods - per business, can apply to multiple locations)
        $this->router->get('/v1/businesses/{business_id}/closures', LocationClosuresController::class, 'index', ['auth']);
        $this->router->get('/v1/businesses/{business_id}/closures/in-range', LocationClosuresController::class, 'inRange', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/closures', LocationClosuresController::class, 'store', ['auth']);
        $this->router->get('/v1/closures/{id}', LocationClosuresController::class, 'show', ['auth']);
        $this->router->put('/v1/closures/{id}', LocationClosuresController::class, 'update', ['auth']);
        $this->router->delete('/v1/closures/{id}', LocationClosuresController::class, 'destroy', ['auth']);

        // Time blocks (auth required)
        $this->router->get('/v1/locations/{location_id}/time-blocks', TimeBlocksController::class, 'index', ['auth', 'location_path', 'location_access']);
        $this->router->post('/v1/locations/{location_id}/time-blocks', TimeBlocksController::class, 'store', ['auth', 'location_path', 'location_access']);
        $this->router->put('/v1/time-blocks/{id}', TimeBlocksController::class, 'update', ['auth']);
        $this->router->delete('/v1/time-blocks/{id}', TimeBlocksController::class, 'destroy', ['auth']);

        // Appointments (protected, business-scoped via path)
        $this->router->get('/v1/locations/{location_id}/appointments', AppointmentsController::class, 'index', ['auth', 'location_path', 'location_access']);
        $this->router->get('/v1/locations/{location_id}/appointments/{id}', AppointmentsController::class, 'show', ['auth', 'location_path', 'location_access']);
        $this->router->patch('/v1/locations/{location_id}/appointments/{id}', AppointmentsController::class, 'update', ['auth', 'location_path', 'location_access']);
        $this->router->post('/v1/locations/{location_id}/appointments/{id}/cancel', AppointmentsController::class, 'cancel', ['auth', 'location_path', 'location_access']);
        $this->router->post('/v1/bookings/{booking_id}/items', AppointmentsController::class, 'store', ['auth']);
        $this->router->delete('/v1/bookings/{booking_id}/items/{item_id}', AppointmentsController::class, 'destroyItem', ['auth']);

        // =========================================================================
        // CUSTOMER AUTH (self-service booking)
        // Separate from operator auth - uses clients table, not users table
        // =========================================================================
        $this->router->post('/v1/customer/{business_id}/auth/login', CustomerAuthController::class, 'login');
        $this->router->post('/v1/customer/{business_id}/auth/register', CustomerAuthController::class, 'register');
        $this->router->post('/v1/customer/{business_id}/auth/refresh', CustomerAuthController::class, 'refresh');
        $this->router->post('/v1/customer/{business_id}/auth/logout', CustomerAuthController::class, 'logout');
        $this->router->post('/v1/customer/{business_id}/auth/forgot-password', CustomerAuthController::class, 'forgotPassword');
        $this->router->post('/v1/customer/auth/reset-password', CustomerAuthController::class, 'resetPasswordWithToken');
        $this->router->get('/v1/customer/me', CustomerAuthController::class, 'me', ['customer_auth']);
        $this->router->put('/v1/customer/me', CustomerAuthController::class, 'updateProfile', ['customer_auth']);
        $this->router->post('/v1/customer/me/change-password', CustomerAuthController::class, 'changePassword', ['customer_auth']);
        
        // Customer bookings (protected, uses client_id from customer JWT)
        $this->router->post('/v1/customer/{business_id}/bookings', BookingsController::class, 'storeCustomer', ['customer_auth', 'idempotency']);
        $this->router->get('/v1/customer/bookings', BookingsController::class, 'myCustomerBookings', ['customer_auth']);
        $this->router->put('/v1/customer/bookings/{booking_id}', BookingsController::class, 'updateCustomer', ['customer_auth']);
        $this->router->delete('/v1/customer/bookings/{booking_id}', BookingsController::class, 'destroyCustomer', ['customer_auth']);
        
        // Customer booking replace (atomic replace pattern)
        $this->router->post('/v1/customer/bookings/{booking_id}/replace', BookingsController::class, 'replaceCustomer', ['customer_auth']);
        
        // Customer booking history (audit trail)
        $this->router->get('/v1/customer/bookings/{booking_id}/history', BookingsController::class, 'historyCustomer', ['customer_auth']);
    }

    private function registerMiddleware(): void
    {
        $jwtService = new JwtService();
        $locationRepo = new LocationRepository($this->db);
        $businessUserRepo = new BusinessUserRepository($this->db);
        $userRepo = new UserRepository($this->db);

        $this->middleware = [
            'auth' => new AuthMiddleware($jwtService),
            'customer_auth' => new CustomerAuthMiddleware($jwtService),
            'location_path' => new LocationContextMiddleware($locationRepo, 'path'),
            'location_query' => new LocationContextMiddleware($locationRepo, 'query'),
            'location_access' => new LocationAccessMiddleware($businessUserRepo, $userRepo),
            'idempotency' => new IdempotencyMiddleware(),
            'business_access' => new BusinessAccessMiddleware($businessUserRepo, $userRepo, 'attribute'),
            'business_access_route' => new BusinessAccessMiddleware($businessUserRepo, $userRepo, 'route'),
        ];
    }

    private function registerControllers(): void
    {
        // Repositories
        $userRepo = new UserRepository($this->db);
        $sessionRepo = new AuthSessionRepository($this->db);
        $businessRepo = new BusinessRepository($this->db);
        $businessUserRepo = new BusinessUserRepository($this->db);
        $businessInvitationRepo = new BusinessInvitationRepository($this->db);
        $locationRepo = new LocationRepository($this->db);
        $serviceRepo = new ServiceRepository($this->db);
        $servicePackageRepo = new ServicePackageRepository($this->db);
        $staffRepo = new StaffRepository($this->db);
        $staffExceptionRepo = new StaffAvailabilityExceptionRepository($this->db);
        $staffPlanningRepo = new StaffPlanningRepository($this->db);
        $resourceRepo = new ResourceRepository($this->db);
        $variantResourceRepo = new ServiceVariantResourceRepository($this->db);
        $timeBlockRepo = new TimeBlockRepository($this->db);
        $bookingRepo = new BookingRepository($this->db);
        $clientRepo = new ClientRepository($this->db);
        $crmClientRepo = new CrmClientRepository($this->db);
        $clientAuthRepo = new ClientAuthRepository($this->db);
        $notificationRepo = new NotificationRepository($this->db);
        $popularServiceRepo = new PopularServiceRepository($this->db);
        $locationClosureRepo = new LocationClosureRepository($this->db);
        $classEventRepo = new ClassEventRepository($this->db);

        // Services
        $jwtService = new JwtService();
        $passwordHasher = new PasswordHasher();

        // Operator Auth Use Cases
        $loginUser = new LoginUser($userRepo, $sessionRepo, $jwtService, $passwordHasher);
        $refreshToken = new RefreshToken($userRepo, $sessionRepo, $jwtService);
        $logoutUser = new LogoutUser($sessionRepo);
        $getMe = new GetMe($userRepo, $clientRepo);
        $registerUser = new RegisterUser($userRepo, $sessionRepo, $jwtService, $passwordHasher);
        $requestPasswordReset = new RequestPasswordReset($this->db, $userRepo);
        $resetPassword = new ResetPassword($this->db, $userRepo, $passwordHasher);
        $verifyResetToken = new VerifyResetToken($this->db);
        $changePassword = new ChangePassword($userRepo, $passwordHasher);
        $updateProfile = new UpdateProfile($this->db, $userRepo);

        // Customer Auth Use Cases
        $loginCustomer = new LoginCustomer($clientAuthRepo, $jwtService, $passwordHasher);
        $registerCustomer = new RegisterCustomer($clientAuthRepo, $clientRepo, $jwtService, $passwordHasher);
        $refreshCustomerToken = new RefreshCustomerToken($clientAuthRepo, $jwtService);
        $logoutCustomer = new LogoutCustomer($clientAuthRepo);
        $getCustomerMe = new GetCustomerMe($clientAuthRepo);
        $requestCustomerPasswordReset = new RequestCustomerPasswordReset($clientAuthRepo, $businessRepo);
        $resetCustomerPassword = new ResetCustomerPassword($clientAuthRepo, $passwordHasher);
        $updateCustomerProfile = new UpdateCustomerProfile($clientAuthRepo);
        $changeCustomerPassword = new ChangeCustomerPassword($clientAuthRepo, $passwordHasher);

        // Booking Use Cases
        $bookingAuditRepo = new BookingAuditRepository($this->db, $userRepo, $clientRepo);
        $recurrenceRuleRepo = new RecurrenceRuleRepository($this->db);
        $computeAvailability = new ComputeAvailability($bookingRepo, $staffRepo, $locationRepo, $staffPlanningRepo, $timeBlockRepo, $staffExceptionRepo, $variantResourceRepo, $serviceRepo, $locationClosureRepo);
        $createBooking = new CreateBooking($this->db, $bookingRepo, $serviceRepo, $staffRepo, $clientRepo, $locationRepo, $userRepo, $notificationRepo, $computeAvailability, $bookingAuditRepo, $locationClosureRepo);
        $createRecurringBooking = new CreateRecurringBooking($this->db, $bookingRepo, $recurrenceRuleRepo, $serviceRepo, $staffRepo, $clientRepo, $locationRepo, $userRepo, $computeAvailability, $notificationRepo, $bookingAuditRepo);
        $previewRecurringBooking = new PreviewRecurringBooking($this->db, $bookingRepo, $serviceRepo, $staffRepo, $clientRepo, $locationRepo);
        $modifyRecurringSeries = new ModifyRecurringSeries($this->db, $bookingRepo, $recurrenceRuleRepo, $staffRepo, $bookingAuditRepo);
        $updateBooking = new UpdateBooking($bookingRepo, $this->db, $clientRepo, $notificationRepo, $bookingAuditRepo);
        $deleteBooking = new DeleteBooking($bookingRepo, $this->db, $notificationRepo, $bookingAuditRepo);
        $getMyBookings = new GetMyBookings($this->db);
        $replaceBooking = new ReplaceBooking($this->db, $bookingRepo, $bookingAuditRepo, $serviceRepo, $staffRepo, $clientRepo, $locationRepo, $notificationRepo, $computeAvailability);

        // Controllers
        $this->controllers = [
            HealthController::class => new HealthController(),
            AuthController::class => new AuthController($loginUser, $refreshToken, $logoutUser, $getMe, $registerUser, $requestPasswordReset, $resetPassword, $verifyResetToken, $changePassword, $updateProfile, $businessUserRepo, $userRepo),
            CustomerAuthController::class => new CustomerAuthController($loginCustomer, $refreshCustomerToken, $logoutCustomer, $getCustomerMe, $registerCustomer, $requestCustomerPasswordReset, $resetCustomerPassword, $updateCustomerProfile, $changeCustomerPassword, $businessRepo),
            BusinessController::class => new BusinessController($businessRepo, $locationRepo, $businessUserRepo, $userRepo),
            LocationsController::class => new LocationsController($locationRepo, $businessUserRepo, $userRepo),
            ServicesController::class => new ServicesController($serviceRepo, $variantResourceRepo, $locationRepo, $businessUserRepo, $userRepo, $servicePackageRepo, $popularServiceRepo, $staffRepo),
            ServicePackagesController::class => new ServicePackagesController($servicePackageRepo, $businessUserRepo, $userRepo),
            StaffController::class => new StaffController($staffRepo, $businessUserRepo, $locationRepo, $userRepo),
            AvailabilityController::class => new AvailabilityController($computeAvailability, $serviceRepo),
            BookingsController::class => new BookingsController($createBooking, $bookingRepo, $getMyBookings, $updateBooking, $deleteBooking, $locationRepo, $businessUserRepo, $userRepo, $replaceBooking, $bookingAuditRepo, $clientRepo, $createRecurringBooking, $previewRecurringBooking, $recurrenceRuleRepo, $modifyRecurringSeries, $notificationRepo),
            BookingNotificationsController::class => new BookingNotificationsController($notificationRepo, $businessUserRepo, $userRepo),
            ClientsController::class => new ClientsController($clientRepo, $businessUserRepo, $userRepo, $bookingRepo),
            CrmClientsController::class => new CrmClientsController($crmClientRepo, $businessUserRepo, $userRepo),
            AppointmentsController::class => new AppointmentsController($bookingRepo, $createBooking, $updateBooking, $deleteBooking, $locationRepo, $businessUserRepo, $userRepo, $bookingAuditRepo, $notificationRepo, $this->db),
            AdminBusinessesController::class => new AdminBusinessesController($this->db, $businessRepo, $businessUserRepo, $userRepo),
            BusinessSyncController::class => new BusinessSyncController(
                new ExportBusiness($this->db),
                new ImportBusiness($this->db),
                $userRepo
            ),
            BusinessUsersController::class => new BusinessUsersController($businessRepo, $businessUserRepo, $businessInvitationRepo, $sessionRepo, $userRepo),
            BusinessInvitationsController::class => new BusinessInvitationsController($businessRepo, $businessUserRepo, $businessInvitationRepo, $locationRepo, $staffRepo, $userRepo, $registerUser),
            StaffAvailabilityExceptionController::class => new StaffAvailabilityExceptionController($staffExceptionRepo, $staffRepo, $businessUserRepo, $userRepo),
            StaffPlanningController::class => new StaffPlanningController($staffPlanningRepo, $staffRepo, $businessUserRepo, $userRepo),
            ResourcesController::class => new ResourcesController($resourceRepo, $locationRepo, $businessUserRepo, $userRepo, $variantResourceRepo),
            ServiceVariantResourceController::class => new ServiceVariantResourceController($variantResourceRepo, $businessUserRepo, $userRepo),
            TimeBlocksController::class => new TimeBlocksController($timeBlockRepo, $locationRepo, $businessUserRepo, $userRepo),
            ReportsController::class => new ReportsController($this->db, $businessUserRepo, $userRepo, $locationClosureRepo),
            LocationClosuresController::class => new LocationClosuresController($locationClosureRepo, $locationRepo, $businessUserRepo, $userRepo),
            ClassEventsController::class => new ClassEventsController($classEventRepo, $businessUserRepo, $locationRepo, $userRepo),
        ];
    }

    public function handle(Request $request): Response
    {
        $this->logger->info('Request', [
            'method' => $request->method,
            'path' => $request->path,
            'trace_id' => $request->traceId,
        ]);

        $customerAuthAudit = $this->buildCustomerAuthAuditContext($request);
        $response = null;

        try {
            $route = $this->router->match($request->method, $request->path);

            if ($route === null) {
                $response = Response::notFound('Endpoint not found', $request->traceId);
            } else {
                // Set path params as attributes
                foreach ($route['params'] as $key => $value) {
                    $request->setAttribute($key, $value);
                }

                // Apply middleware
                foreach ($route['middleware'] as $middlewareName) {
                    if (!isset($this->middleware[$middlewareName])) {
                        continue;
                    }

                    $middleware = $this->middleware[$middlewareName];
                    $result = $middleware->handle($request);

                    if ($result instanceof Response) {
                        $response = $result;
                        break;
                    }
                }

                if ($response === null) {
                    // Call controller
                    $controller = $this->controllers[$route['controller']] ?? null;
                    if ($controller === null) {
                        $response = Response::serverError('Controller not found', $request->traceId);
                    } else {
                        $method = $route['method'];
                        $response = $controller->$method($request);
                    }
                }
            }
        } catch (\PDOException $e) {
            $this->logger->error('Database error', [
                'message' => $e->getMessage(),
                'trace_id' => $request->traceId,
                'code' => $e->getCode(),
            ]);

            // Return user-friendly message for database errors
            $response = Response::error(
                'Service temporarily unavailable. Please try again later.',
                'database_error',
                503,
                $request->traceId
            );
        } catch (Throwable $e) {
            $this->logger->error('Exception', [
                'message' => $e->getMessage(),
                'trace_id' => $request->traceId,
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            $debug = ($_ENV['APP_DEBUG'] ?? false) === 'true';
            $message = $debug ? $e->getMessage() : 'Internal server error';

            $response = Response::serverError($message, $request->traceId);
        }

        // Log response (include structured error code for quick filtering)
        $errorCode = null;
        if ($response->status >= 400) {
            $errorCode = $response->data['error']['code'] ?? null;
        }
        $this->logger->info('Response', [
            'status' => $response->status,
            'error_code' => $errorCode,
            'trace_id' => $request->traceId,
        ]);

        // Safe customer auth audit logging (hashed email; no PII in cleartext)
        if ($customerAuthAudit !== null) {
            $this->logger->info('CustomerAuth', [
                ...$customerAuthAudit,
                'status' => $response->status,
                'error_code' => $errorCode,
                'trace_id' => $request->traceId,
            ]);
        }

        return $response;
    }

    /**
     * Builds a safe audit context for customer auth endpoints.
     *
     * - Never logs cleartext email/password.
     * - Logs only sha256(email) to allow correlation between attempts.
     *
     * @return array{action:string,business_id:int,email_hash:?string}|null
     */
    private function buildCustomerAuthAuditContext(Request $request): ?array
    {
        // Match only customer auth login/register.
        if (!preg_match('#^/v1/customer/([0-9]+)/auth/(login|register)$#', $request->path, $m)) {
            return null;
        }

        $businessId = (int) $m[1];
        $action = $m[2];
        $body = $request->getBody() ?? [];
        $email = $body['email'] ?? null;
        $emailHash = null;
        if (is_string($email)) {
            $normalized = strtolower(trim($email));
            if ($normalized !== '') {
                $emailHash = hash('sha256', $normalized);
            }
        }

        return [
            'action' => $action,
            'business_id' => $businessId,
            'email_hash' => $emailHash,
        ];
    }
}
