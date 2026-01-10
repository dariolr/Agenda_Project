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
use Agenda\Http\Controllers\CustomerAuthController;
use Agenda\Http\Controllers\HealthController;
use Agenda\Http\Controllers\LocationsController;
use Agenda\Http\Controllers\ServicesController;
use Agenda\Http\Controllers\StaffController;
use Agenda\Http\Controllers\StaffAvailabilityExceptionController;
use Agenda\Http\Controllers\StaffPlanningController;
use Agenda\Http\Controllers\ResourcesController;
use Agenda\Http\Controllers\TimeBlocksController;
use Agenda\Http\Controllers\AppointmentsController;
use Agenda\Http\Middleware\AuthMiddleware;
use Agenda\Http\Middleware\BusinessAccessMiddleware;
use Agenda\Http\Middleware\CustomerAuthMiddleware;
use Agenda\Http\Middleware\IdempotencyMiddleware;
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
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\ServiceRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\StaffScheduleRepository;
use Agenda\Infrastructure\Repositories\StaffAvailabilityExceptionRepository;
use Agenda\Infrastructure\Repositories\StaffPlanningRepository;
use Agenda\Infrastructure\Repositories\ResourceRepository;
use Agenda\Infrastructure\Repositories\TimeBlockRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Notifications\NotificationRepository;
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
use Agenda\UseCases\Booking\UpdateBooking;
use Agenda\UseCases\Booking\DeleteBooking;
use Agenda\UseCases\Booking\GetMyBookings;
use Agenda\UseCases\CustomerAuth\LoginCustomer;
use Agenda\UseCases\CustomerAuth\RegisterCustomer;
use Agenda\UseCases\CustomerAuth\RefreshCustomerToken;
use Agenda\UseCases\CustomerAuth\LogoutCustomer;
use Agenda\UseCases\CustomerAuth\GetCustomerMe;
use Agenda\UseCases\CustomerAuth\RequestCustomerPasswordReset;
use Agenda\UseCases\CustomerAuth\ResetCustomerPassword;
use Agenda\UseCases\CustomerAuth\UpdateCustomerProfile;
use Agenda\UseCases\CustomerAuth\ChangeCustomerPassword;
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
        $this->router->get('/v1/me/bookings', BookingsController::class, 'myBookings', ['auth']);
        $this->router->get('/v1/me/businesses', AdminBusinessesController::class, 'myBusinesses', ['auth']);

        // Admin/Superadmin endpoints
        $this->router->get('/v1/admin/businesses', AdminBusinessesController::class, 'index', ['auth']);
        $this->router->post('/v1/admin/businesses', AdminBusinessesController::class, 'store', ['auth']);
        $this->router->put('/v1/admin/businesses/{id}', AdminBusinessesController::class, 'update', ['auth']);
        $this->router->delete('/v1/admin/businesses/{id}', AdminBusinessesController::class, 'destroy', ['auth']);
        $this->router->post('/v1/admin/businesses/{id}/resend-invite', AdminBusinessesController::class, 'resendInvite', ['auth']);

        // Businesses - Public endpoint for subdomain resolution
        $this->router->get('/v1/businesses/by-slug/{slug}', BusinessController::class, 'showBySlug');
        // Public locations for a business (for booking flow)
        $this->router->get('/v1/businesses/{business_id}/locations/public', LocationsController::class, 'indexPublic');

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

        // Staff schedules (auth required)
        $this->router->get('/v1/businesses/{business_id}/staff/schedules', StaffController::class, 'indexSchedules', ['auth']);
        $this->router->get('/v1/staff/{id}/schedules', StaffController::class, 'showSchedule', ['auth']);
        $this->router->put('/v1/staff/{id}/schedules', StaffController::class, 'updateSchedule', ['auth']);

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
        $this->router->get('/v1/locations/{location_id}/resources', ResourcesController::class, 'indexByLocation', ['auth']);
        $this->router->post('/v1/locations/{location_id}/resources', ResourcesController::class, 'store', ['auth']);
        $this->router->put('/v1/resources/{id}', ResourcesController::class, 'update', ['auth']);
        $this->router->delete('/v1/resources/{id}', ResourcesController::class, 'destroy', ['auth']);

        // Business Users (operators management)
        $this->router->get('/v1/businesses/{business_id}/users', BusinessUsersController::class, 'index', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/users', BusinessUsersController::class, 'store', ['auth']);
        $this->router->patch('/v1/businesses/{business_id}/users/{target_user_id}', BusinessUsersController::class, 'update', ['auth']);
        $this->router->delete('/v1/businesses/{business_id}/users/{target_user_id}', BusinessUsersController::class, 'destroy', ['auth']);

        // Business Invitations
        $this->router->get('/v1/businesses/{business_id}/invitations', BusinessInvitationsController::class, 'index', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/invitations', BusinessInvitationsController::class, 'store', ['auth']);
        $this->router->delete('/v1/businesses/{business_id}/invitations/{invitation_id}', BusinessInvitationsController::class, 'destroy', ['auth']);
        $this->router->get('/v1/invitations/{token}', BusinessInvitationsController::class, 'show');
        $this->router->post('/v1/invitations/{token}/accept', BusinessInvitationsController::class, 'accept', ['auth']);

        // Public (business-scoped via query param)
        $this->router->get('/v1/services', ServicesController::class, 'index', ['location_query']);
        $this->router->get('/v1/staff', StaffController::class, 'index', ['location_query']);
        $this->router->get('/v1/availability', AvailabilityController::class, 'index', ['location_query']);

        // Services CRUD (auth required)
        $this->router->post('/v1/locations/{location_id}/services', ServicesController::class, 'store', ['auth', 'location_path']);
        $this->router->put('/v1/services/{id}', ServicesController::class, 'update', ['auth']);
        $this->router->delete('/v1/services/{id}', ServicesController::class, 'destroy', ['auth']);
        $this->router->post('/v1/services/reorder', ServicesController::class, 'reorderServices', ['auth']);

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

        // Bookings (protected, business-scoped via path)
        $this->router->get('/v1/locations/{location_id}/bookings', BookingsController::class, 'index', ['auth', 'location_path']);
        $this->router->get('/v1/locations/{location_id}/bookings/{booking_id}', BookingsController::class, 'show', ['auth', 'location_path']);
        $this->router->post('/v1/locations/{location_id}/bookings', BookingsController::class, 'store', ['auth', 'location_path', 'idempotency']);
        $this->router->put('/v1/locations/{location_id}/bookings/{booking_id}', BookingsController::class, 'update', ['auth', 'location_path']);
        $this->router->delete('/v1/locations/{location_id}/bookings/{booking_id}', BookingsController::class, 'destroy', ['auth', 'location_path']);

        // Time blocks (auth required)
        $this->router->get('/v1/locations/{location_id}/time-blocks', TimeBlocksController::class, 'index', ['auth']);
        $this->router->post('/v1/locations/{location_id}/time-blocks', TimeBlocksController::class, 'store', ['auth']);
        $this->router->put('/v1/time-blocks/{id}', TimeBlocksController::class, 'update', ['auth']);
        $this->router->delete('/v1/time-blocks/{id}', TimeBlocksController::class, 'destroy', ['auth']);

        // Appointments (protected, business-scoped via path)
        $this->router->get('/v1/locations/{location_id}/appointments', AppointmentsController::class, 'index', ['auth', 'location_path']);
        $this->router->get('/v1/locations/{location_id}/appointments/{id}', AppointmentsController::class, 'show', ['auth', 'location_path']);
        $this->router->patch('/v1/locations/{location_id}/appointments/{id}', AppointmentsController::class, 'update', ['auth', 'location_path']);
        $this->router->post('/v1/locations/{location_id}/appointments/{id}/cancel', AppointmentsController::class, 'cancel', ['auth', 'location_path']);
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
        $staffRepo = new StaffRepository($this->db);
        $staffScheduleRepo = new StaffScheduleRepository($this->db);
        $staffExceptionRepo = new StaffAvailabilityExceptionRepository($this->db);
        $staffPlanningRepo = new StaffPlanningRepository($this->db);
        $resourceRepo = new ResourceRepository($this->db);
        $timeBlockRepo = new TimeBlockRepository($this->db);
        $bookingRepo = new BookingRepository($this->db);
        $clientRepo = new ClientRepository($this->db);
        $clientAuthRepo = new ClientAuthRepository($this->db);
        $notificationRepo = new NotificationRepository($this->db);

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
        $computeAvailability = new ComputeAvailability($bookingRepo, $staffRepo, $locationRepo, $staffPlanningRepo);
        $createBooking = new CreateBooking($this->db, $bookingRepo, $serviceRepo, $staffRepo, $clientRepo, $locationRepo, $userRepo, $notificationRepo);
        $updateBooking = new UpdateBooking($bookingRepo, $this->db, $clientRepo, $notificationRepo);
        $deleteBooking = new DeleteBooking($bookingRepo, $this->db, $notificationRepo);
        $getMyBookings = new GetMyBookings($this->db);

        // Controllers
        $this->controllers = [
            HealthController::class => new HealthController(),
            AuthController::class => new AuthController($loginUser, $refreshToken, $logoutUser, $getMe, $registerUser, $requestPasswordReset, $resetPassword, $verifyResetToken, $changePassword, $updateProfile),
            CustomerAuthController::class => new CustomerAuthController($loginCustomer, $refreshCustomerToken, $logoutCustomer, $getCustomerMe, $registerCustomer, $requestCustomerPasswordReset, $resetCustomerPassword, $updateCustomerProfile, $changeCustomerPassword, $businessRepo),
            BusinessController::class => new BusinessController($businessRepo, $locationRepo, $businessUserRepo, $userRepo),
            LocationsController::class => new LocationsController($locationRepo, $businessUserRepo, $userRepo),
            ServicesController::class => new ServicesController($serviceRepo, $locationRepo, $businessUserRepo, $userRepo),
            StaffController::class => new StaffController($staffRepo, $staffScheduleRepo, $businessUserRepo, $locationRepo, $userRepo),
            AvailabilityController::class => new AvailabilityController($computeAvailability, $serviceRepo),
            BookingsController::class => new BookingsController($createBooking, $bookingRepo, $getMyBookings, $updateBooking, $deleteBooking, $locationRepo, $businessUserRepo, $userRepo),
            ClientsController::class => new ClientsController($clientRepo, $businessUserRepo, $userRepo, $bookingRepo),
            AppointmentsController::class => new AppointmentsController($bookingRepo, $createBooking, $updateBooking, $deleteBooking, $locationRepo, $businessUserRepo, $userRepo),
            AdminBusinessesController::class => new AdminBusinessesController($this->db, $businessRepo, $businessUserRepo, $userRepo),
            BusinessUsersController::class => new BusinessUsersController($businessRepo, $businessUserRepo, $userRepo),
            BusinessInvitationsController::class => new BusinessInvitationsController($businessRepo, $businessUserRepo, $businessInvitationRepo, $userRepo),
            StaffAvailabilityExceptionController::class => new StaffAvailabilityExceptionController($staffExceptionRepo, $staffRepo, $businessUserRepo, $userRepo),
            StaffPlanningController::class => new StaffPlanningController($staffPlanningRepo, $staffRepo, $businessUserRepo, $userRepo),
            ResourcesController::class => new ResourcesController($resourceRepo, $locationRepo, $businessUserRepo, $userRepo),
            TimeBlocksController::class => new TimeBlocksController($timeBlockRepo, $locationRepo, $businessUserRepo, $userRepo),
        ];
    }

    public function handle(Request $request): Response
    {
        try {
            $this->logger->info('Request', [
                'method' => $request->method,
                'path' => $request->path,
                'trace_id' => $request->traceId,
            ]);

            $route = $this->router->match($request->method, $request->path);
            
            if ($route === null) {
                return Response::notFound('Endpoint not found', $request->traceId);
            }

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
                    return $result;
                }
            }

            // Call controller
            $controller = $this->controllers[$route['controller']] ?? null;
            if ($controller === null) {
                return Response::serverError('Controller not found', $request->traceId);
            }

            $method = $route['method'];
            $response = $controller->$method($request);

            $this->logger->info('Response', [
                'status' => $response->status,
                'trace_id' => $request->traceId,
            ]);

            return $response;

        } catch (\PDOException $e) {
            $this->logger->error('Database error', [
                'message' => $e->getMessage(),
                'trace_id' => $request->traceId,
                'code' => $e->getCode(),
            ]);

            // Return user-friendly message for database errors
            return Response::error(
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
            
            return Response::serverError($message, $request->traceId);
        }
    }
}
