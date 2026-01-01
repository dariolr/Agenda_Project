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
use Agenda\Http\Controllers\HealthController;
use Agenda\Http\Controllers\LocationsController;
use Agenda\Http\Controllers\ServicesController;
use Agenda\Http\Controllers\StaffController;
use Agenda\Http\Controllers\AppointmentsController;
use Agenda\Http\Middleware\AuthMiddleware;
use Agenda\Http\Middleware\BusinessAccessMiddleware;
use Agenda\Http\Middleware\IdempotencyMiddleware;
use Agenda\Http\Middleware\LocationContextMiddleware;
use Agenda\Infrastructure\Database\Connection;
use Agenda\Infrastructure\Logger\Logger;
use Agenda\Infrastructure\Repositories\AuthSessionRepository;
use Agenda\Infrastructure\Repositories\BookingRepository;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\BusinessInvitationRepository;
use Agenda\Infrastructure\Repositories\ClientRepository;
use Agenda\Infrastructure\Repositories\LocationRepository;
use Agenda\Infrastructure\Repositories\ServiceRepository;
use Agenda\Infrastructure\Repositories\StaffRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Security\JwtService;
use Agenda\Infrastructure\Security\PasswordHasher;
use Agenda\UseCases\Auth\GetMe;
use Agenda\UseCases\Auth\LoginUser;
use Agenda\UseCases\Auth\LogoutUser;
use Agenda\UseCases\Auth\RefreshToken;
use Agenda\UseCases\Auth\RegisterUser;
use Agenda\UseCases\Auth\RequestPasswordReset;
use Agenda\UseCases\Auth\ResetPassword;
use Agenda\UseCases\Auth\ChangePassword;
use Agenda\UseCases\Auth\UpdateProfile;
use Agenda\UseCases\Booking\ComputeAvailability;
use Agenda\UseCases\Booking\CreateBooking;
use Agenda\UseCases\Booking\UpdateBooking;
use Agenda\UseCases\Booking\DeleteBooking;
use Agenda\UseCases\Booking\GetMyBookings;
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

        // Staff management (auth required)
        $this->router->get('/v1/businesses/{business_id}/staff', StaffController::class, 'indexByBusiness', ['auth']);
        $this->router->post('/v1/businesses/{business_id}/staff', StaffController::class, 'store', ['auth']);
        $this->router->put('/v1/staff/{id}', StaffController::class, 'update', ['auth']);
        $this->router->delete('/v1/staff/{id}', StaffController::class, 'destroy', ['auth']);

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

        // Clients (auth required)
        $this->router->get('/v1/clients', ClientsController::class, 'index', ['auth']);
        $this->router->get('/v1/clients/{id}', ClientsController::class, 'show', ['auth']);
        $this->router->post('/v1/clients', ClientsController::class, 'store', ['auth']);
        $this->router->put('/v1/clients/{id}', ClientsController::class, 'update', ['auth']);
        $this->router->delete('/v1/clients/{id}', ClientsController::class, 'destroy', ['auth']);

        // Bookings (protected, business-scoped via path)
        $this->router->get('/v1/locations/{location_id}/bookings', BookingsController::class, 'index', ['auth', 'location_path']);
        $this->router->get('/v1/locations/{location_id}/bookings/{booking_id}', BookingsController::class, 'show', ['auth', 'location_path']);
        $this->router->post('/v1/locations/{location_id}/bookings', BookingsController::class, 'store', ['auth', 'location_path', 'idempotency']);
        $this->router->put('/v1/locations/{location_id}/bookings/{booking_id}', BookingsController::class, 'update', ['auth', 'location_path']);
        $this->router->delete('/v1/locations/{location_id}/bookings/{booking_id}', BookingsController::class, 'destroy', ['auth', 'location_path']);

        // Appointments (protected, business-scoped via path)
        $this->router->get('/v1/locations/{location_id}/appointments', AppointmentsController::class, 'index', ['auth', 'location_path']);
        $this->router->get('/v1/locations/{location_id}/appointments/{id}', AppointmentsController::class, 'show', ['auth', 'location_path']);
        $this->router->patch('/v1/locations/{location_id}/appointments/{id}', AppointmentsController::class, 'update', ['auth', 'location_path']);
        $this->router->post('/v1/locations/{location_id}/appointments/{id}/cancel', AppointmentsController::class, 'cancel', ['auth', 'location_path']);
    }

    private function registerMiddleware(): void
    {
        $jwtService = new JwtService();
        $locationRepo = new LocationRepository($this->db);
        $businessUserRepo = new BusinessUserRepository($this->db);
        $userRepo = new UserRepository($this->db);

        $this->middleware = [
            'auth' => new AuthMiddleware($jwtService),
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
        $bookingRepo = new BookingRepository($this->db);
        $clientRepo = new ClientRepository($this->db);

        // Services
        $jwtService = new JwtService();
        $passwordHasher = new PasswordHasher();

        // Use Cases
        $loginUser = new LoginUser($userRepo, $sessionRepo, $jwtService, $passwordHasher);
        $refreshToken = new RefreshToken($userRepo, $sessionRepo, $jwtService);
        $logoutUser = new LogoutUser($sessionRepo);
        $getMe = new GetMe($userRepo, $clientRepo);
        $registerUser = new RegisterUser($userRepo, $sessionRepo, $jwtService, $passwordHasher);
        $requestPasswordReset = new RequestPasswordReset($this->db, $userRepo);
        $resetPassword = new ResetPassword($this->db, $userRepo, $passwordHasher);
        $changePassword = new ChangePassword($userRepo, $passwordHasher);
        $updateProfile = new UpdateProfile($this->db, $userRepo);
        $computeAvailability = new ComputeAvailability($bookingRepo, $staffRepo, $locationRepo);
        $createBooking = new CreateBooking($this->db, $bookingRepo, $serviceRepo, $staffRepo, $clientRepo, $locationRepo, $userRepo);
        $updateBooking = new UpdateBooking($bookingRepo, $this->db);
        $deleteBooking = new DeleteBooking($bookingRepo, $this->db);
        $getMyBookings = new GetMyBookings($this->db);

        // Controllers
        $this->controllers = [
            HealthController::class => new HealthController(),
            AuthController::class => new AuthController($loginUser, $refreshToken, $logoutUser, $getMe, $registerUser, $requestPasswordReset, $resetPassword, $changePassword, $updateProfile),
            BusinessController::class => new BusinessController($businessRepo, $locationRepo),
            LocationsController::class => new LocationsController($locationRepo, $businessUserRepo, $userRepo),
            ServicesController::class => new ServicesController($serviceRepo),
            StaffController::class => new StaffController($staffRepo, $businessUserRepo, $locationRepo, $userRepo),
            AvailabilityController::class => new AvailabilityController($computeAvailability, $serviceRepo),
            BookingsController::class => new BookingsController($createBooking, $bookingRepo, $getMyBookings, $updateBooking, $deleteBooking),
            ClientsController::class => new ClientsController($clientRepo),
            AppointmentsController::class => new AppointmentsController($bookingRepo, $createBooking, $updateBooking, $deleteBooking),
            AdminBusinessesController::class => new AdminBusinessesController($this->db, $businessRepo, $businessUserRepo, $userRepo),
            BusinessUsersController::class => new BusinessUsersController($businessRepo, $businessUserRepo, $userRepo),
            BusinessInvitationsController::class => new BusinessInvitationsController($businessRepo, $businessUserRepo, $businessInvitationRepo, $userRepo),
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
