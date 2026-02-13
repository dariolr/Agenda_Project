<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\UseCases\Auth\LoginUser;
use Agenda\UseCases\Auth\RefreshToken;
use Agenda\UseCases\Auth\LogoutUser;
use Agenda\UseCases\Auth\GetMe;
use Agenda\UseCases\Auth\RegisterUser;
use Agenda\UseCases\Auth\RequestPasswordReset;
use Agenda\UseCases\Auth\ResetPassword;
use Agenda\UseCases\Auth\VerifyResetToken;
use Agenda\UseCases\Auth\ChangePassword;
use Agenda\UseCases\Auth\UpdateProfile;
use Agenda\Infrastructure\Repositories\BusinessUserRepository;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Domain\Exceptions\AuthException;
use Agenda\Domain\Exceptions\ValidationException;

final class AuthController
{
    public function __construct(
        private readonly LoginUser $loginUser,
        private readonly RefreshToken $refreshToken,
        private readonly LogoutUser $logoutUser,
        private readonly GetMe $getMe,
        private readonly RegisterUser $registerUser,
        private readonly RequestPasswordReset $requestPasswordReset,
        private readonly ResetPassword $resetPassword,
        private readonly VerifyResetToken $verifyResetToken,
        private readonly ChangePassword $changePassword,
        private readonly UpdateProfile $updateProfile,
        private readonly BusinessUserRepository $businessUserRepo,
        private readonly UserRepository $userRepo,
    ) {}

    /**
     * POST /v1/auth/login
     */
    public function login(Request $request): Response
    {
        $body = $request->getBody();

        $email = isset($body['email']) ? trim((string) $body['email']) : null;
        $password = isset($body['password']) ? trim((string) $body['password']) : null;

        if ($email === null || $password === null) {
            return Response::error('Email and password are required', 'validation_error', 400);
        }

        try {
            $result = $this->loginUser->execute(
                $email,
                $password,
                $request->getHeader('User-Agent'),
                $request->getClientIp()
            );

            $response = Response::success($result, 200);
            
            // Set refresh token as httpOnly cookie for web clients
            $response->setCookie(
                'refresh_token',
                $result['refresh_token'],
                [
                    'httpOnly' => true,
                    'secure' => true,
                    'sameSite' => 'Strict',
                    'maxAge' => 90 * 24 * 60 * 60, // 90 days
                    'path' => '/v1/auth',
                ]
            );

            return $response;

        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }

    /**
     * POST /v1/auth/refresh
     */
    public function refresh(Request $request): Response
    {
        // Try to get refresh token from cookie first, then from body
        $refreshToken = $request->getCookie('refresh_token') 
            ?? $request->getBody()['refresh_token'] 
            ?? null;

        if ($refreshToken === null) {
            return Response::error('Refresh token is required', 'validation_error', 400);
        }

        try {
            $result = $this->refreshToken->execute(
                $refreshToken,
                $request->getHeader('User-Agent'),
                $request->getClientIp()
            );

            $response = Response::success($result, 200);

            // Update refresh token cookie
            $response->setCookie(
                'refresh_token',
                $result['refresh_token'],
                [
                    'httpOnly' => true,
                    'secure' => true,
                    'sameSite' => 'Strict',
                    'maxAge' => 90 * 24 * 60 * 60,
                    'path' => '/v1/auth',
                ]
            );

            return $response;

        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }

    /**
     * POST /v1/auth/logout
     */
    public function logout(Request $request): Response
    {
        $refreshToken = $request->getCookie('refresh_token') 
            ?? $request->getBody()['refresh_token'] 
            ?? null;

        if ($refreshToken !== null) {
            $this->logoutUser->execute($refreshToken);
        }

        $response = Response::success(['message' => 'Logged out successfully'], 200);

        // Clear refresh token cookie
        $response->setCookie(
            'refresh_token',
            '',
            [
                'httpOnly' => true,
                'secure' => true,
                'sameSite' => 'Strict',
                'maxAge' => 0,
                'path' => '/v1/auth',
            ]
        );

        return $response;
    }

    /**
     * GET /v1/me
     */
    public function me(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');

        if ($userId === null) {
            return Response::error('Unauthorized', 'unauthorized', 401);
        }

        try {
            $user = $this->getMe->execute($userId);
            return Response::success($user, 200);
        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }

    /**
     * POST /v1/auth/register
     */
    public function register(Request $request): Response
    {
        $body = $request->getBody();

        $email = $body['email'] ?? null;
        $password = $body['password'] ?? null;

        if ($email === null || $password === null) {
            return Response::error('Email and password are required', 'validation_error', 400);
        }

        // Accept either first_name/last_name or a single 'name' field
        $firstName = $body['first_name'] ?? null;
        $lastName = $body['last_name'] ?? null;
        
        // If first_name is not provided, try to split 'name'
        if ($firstName === null && isset($body['name'])) {
            $nameParts = explode(' ', trim($body['name']), 2);
            $firstName = $nameParts[0];
            $lastName = $nameParts[1] ?? '';
        }
        
        // Provide defaults if still null
        $firstName = $firstName ?? 'User';
        $lastName = $lastName ?? '';

        try {
            $result = $this->registerUser->execute(
                $email,
                $password,
                $firstName,
                $lastName,
                $body['phone'] ?? null,
                $request->getHeader('User-Agent'),
                $request->getClientIp()
            );

            $response = Response::success($result, 201);

            // Set refresh token as httpOnly cookie for web clients
            $response->setCookie(
                'refresh_token',
                $result['refresh_token'],
                [
                    'httpOnly' => true,
                    'secure' => true,
                    'sameSite' => 'Strict',
                    'maxAge' => 90 * 24 * 60 * 60,
                    'path' => '/v1/auth',
                ]
            );

            return $response;

        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }

    /**
     * POST /v1/auth/forgot-password
     */
    public function forgotPassword(Request $request): Response
    {
        $body = $request->getBody();
        $email = $body['email'] ?? null;

        if ($email === null) {
            return Response::error('Email is required', 'validation_error', 400);
        }

        // Always return success to prevent email enumeration
        $this->requestPasswordReset->execute($email);

        return Response::success([
            'message' => 'If the email exists, a password reset link has been sent',
        ], 200);
    }

    /**
     * GET /v1/auth/verify-reset-token/{token}
     * Verifies if a reset token is valid before showing the reset form.
     */
    public function verifyResetTokenAction(Request $request): Response
    {
        $token = $request->getRouteParam('token');

        if ($token === null) {
            return Response::error('Token is required', 'validation_error', 400);
        }

        try {
            $this->verifyResetToken->execute($token);
            return Response::success([
                'valid' => true,
                'message' => 'Token is valid',
            ], 200);
        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }

    /**
     * POST /v1/auth/reset-password
     */
    public function resetPasswordAction(Request $request): Response
    {
        $body = $request->getBody();
        $token = $body['token'] ?? null;
        $password = $body['password'] ?? null;

        if ($token === null || $password === null) {
            return Response::error('Token and password are required', 'validation_error', 400);
        }

        try {
            $this->resetPassword->execute($token, $password);
            return Response::success([
                'message' => 'Password has been reset successfully',
            ], 200);
        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }

    /**
     * POST /v1/me/change-password
     */
    public function changePassword(Request $request): Response
    {
        // Require authentication
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return Response::error('Unauthorized', 'unauthorized', 401);
        }

        $body = $request->getBody();
        $currentPassword = $body['current_password'] ?? null;
        $newPassword = $body['new_password'] ?? null;

        if ($currentPassword === null || $newPassword === null) {
            return Response::error(
                'Current password and new password are required',
                'validation_error',
                400
            );
        }

        try {
            $this->changePassword->execute((int) $userId, $currentPassword, $newPassword);
            return Response::success([
                'message' => 'Password changed successfully',
            ], 200);
        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }

    /**
     * PUT /v1/me
     */
    public function updateMe(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');

        if ($userId === null) {
            return Response::error('Unauthorized', 'unauthorized', 401);
        }

        $body = $request->getBody();

        try {
            $user = $this->updateProfile->execute((int) $userId, $body);
            return Response::success($user, 200);
        } catch (ValidationException $e) {
            return Response::error($e->getMessage(), 'validation_error', 422, $e->getErrors());
        }
    }

    /**
     * GET /v1/me/business/{business_id}
     * Returns the current user's context (role, scope_type, location_ids) for a specific business.
     */
    public function myBusinessContext(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        if ($userId === null) {
            return Response::error('Unauthorized', 'unauthorized', 401);
        }

        $businessId = (int) $request->getRouteParam('business_id');
        if ($businessId <= 0) {
            return Response::error('Invalid business ID', 'validation_error', 400);
        }

        // Check if user is superadmin
        $user = $this->userRepo->findById((int) $userId);
        if ($user && ($user['is_superadmin'] ?? false)) {
            return Response::success([
                'data' => [
                    'user_id' => (int) $userId,
                    'business_id' => $businessId,
                    'role' => 'superadmin',
                    'scope_type' => 'business',
                    'location_ids' => [],
                    'permissions' => [
                        'can_manage_bookings' => true,
                        'can_manage_clients' => true,
                        'can_manage_services' => true,
                        'can_manage_staff' => true,
                        'can_view_reports' => true,
                    ],
                    'is_superadmin' => true,
                ],
            ], 200);
        }

        // Get business_user record
        $businessUser = $this->businessUserRepo->findByUserAndBusiness((int) $userId, $businessId);
        if ($businessUser === null) {
            return Response::error('Access denied', 'forbidden', 403);
        }

        return Response::success([
            'data' => [
                'user_id' => (int) $userId,
                'business_id' => $businessId,
                'role' => $businessUser['role'],
                'scope_type' => $businessUser['scope_type'] ?? 'business',
                'location_ids' => $businessUser['location_ids'] ?? [],
                'staff_id' => $businessUser['staff_id'] ?? null,
                'permissions' => [
                    'can_manage_bookings' => (bool) ($businessUser['can_manage_bookings'] ?? false),
                    'can_manage_clients' => (bool) ($businessUser['can_manage_clients'] ?? false),
                    'can_manage_services' => (bool) ($businessUser['can_manage_services'] ?? false),
                    'can_manage_staff' => (bool) ($businessUser['can_manage_staff'] ?? false),
                    'can_view_reports' => (bool) ($businessUser['can_view_reports'] ?? false),
                ],
                'is_superadmin' => false,
            ],
        ], 200);
    }
}
