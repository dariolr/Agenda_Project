<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\UseCases\CustomerAuth\LoginCustomer;
use Agenda\UseCases\CustomerAuth\RefreshCustomerToken;
use Agenda\UseCases\CustomerAuth\LogoutCustomer;
use Agenda\UseCases\CustomerAuth\GetCustomerMe;
use Agenda\UseCases\CustomerAuth\RegisterCustomer;
use Agenda\UseCases\CustomerAuth\RequestCustomerPasswordReset;
use Agenda\UseCases\CustomerAuth\ResetCustomerPassword;
use Agenda\UseCases\CustomerAuth\UpdateCustomerProfile;
use Agenda\UseCases\CustomerAuth\ChangeCustomerPassword;
use Agenda\Infrastructure\Repositories\BusinessRepository;
use Agenda\Domain\Exceptions\AuthException;
use Agenda\Domain\Exceptions\ValidationException;

/**
 * Customer authentication endpoints for self-service booking.
 * Separate from AuthController which handles operator/admin auth.
 * 
 * All endpoints are scoped to a business via /{business_id}/ prefix.
 */
final class CustomerAuthController
{
    public function __construct(
        private readonly LoginCustomer $loginCustomer,
        private readonly RefreshCustomerToken $refreshCustomerToken,
        private readonly LogoutCustomer $logoutCustomer,
        private readonly GetCustomerMe $getCustomerMe,
        private readonly RegisterCustomer $registerCustomer,
        private readonly RequestCustomerPasswordReset $requestPasswordReset,
        private readonly ResetCustomerPassword $resetPassword,
        private readonly UpdateCustomerProfile $updateCustomerProfile,
        private readonly ChangeCustomerPassword $changeCustomerPassword,
        private readonly BusinessRepository $businessRepository,
    ) {}

    /**
     * POST /v1/customer/{business_id}/auth/login
     */
    public function login(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        
        // Verify business exists
        $business = $this->businessRepository->findById($businessId);
        if ($business === null) {
            return Response::error('Business not found', 'not_found', 404);
        }

        $body = $request->getBody();
        $email = $body['email'] ?? null;
        $password = $body['password'] ?? null;

        if ($email === null || $password === null) {
            return Response::error('Email and password are required', 'validation_error', 400);
        }

        try {
            $result = $this->loginCustomer->execute(
                $email,
                $password,
                $businessId,
                $request->getHeader('User-Agent'),
                $request->getClientIp()
            );

            $response = Response::success($result, 200);
            
            // Set refresh token as httpOnly cookie for web clients
            $response->setCookie(
                'customer_refresh_token',
                $result['refresh_token'],
                [
                    'httpOnly' => true,
                    'secure' => true,
                    'sameSite' => 'Strict',
                    'maxAge' => 90 * 24 * 60 * 60, // 90 days
                    'path' => "/v1/customer/{$businessId}/auth",
                ]
            );

            return $response;

        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }

    /**
     * POST /v1/customer/{business_id}/auth/register
     */
    public function register(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        
        // Verify business exists
        $business = $this->businessRepository->findById($businessId);
        if ($business === null) {
            return Response::error('Business not found', 'not_found', 404);
        }

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
        $firstName = $firstName ?? 'Cliente';
        $lastName = $lastName ?? '';

        try {
            $result = $this->registerCustomer->execute(
                $email,
                $password,
                $firstName,
                $lastName,
                $businessId,
                $body['phone'] ?? null,
                $request->getHeader('User-Agent'),
                $request->getClientIp()
            );

            $response = Response::success($result, 201);

            // Set refresh token as httpOnly cookie for web clients
            $response->setCookie(
                'customer_refresh_token',
                $result['refresh_token'],
                [
                    'httpOnly' => true,
                    'secure' => true,
                    'sameSite' => 'Strict',
                    'maxAge' => 90 * 24 * 60 * 60,
                    'path' => "/v1/customer/{$businessId}/auth",
                ]
            );

            return $response;

        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        } catch (ValidationException $e) {
            return Response::error($e->getMessage(), 'validation_error', 400);
        } catch (\Exception $e) {
            // Log the real error for debugging
            error_log('Customer registration error: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
            return Response::error('Registration failed: ' . $e->getMessage(), 'internal_error', 500);
        }
    }

    /**
     * POST /v1/customer/{business_id}/auth/refresh
     */
    public function refresh(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');

        // Try to get refresh token from cookie first, then from body
        $refreshToken = $request->getCookie('customer_refresh_token') 
            ?? $request->getBody()['refresh_token'] 
            ?? null;

        if ($refreshToken === null) {
            return Response::error('Refresh token is required', 'validation_error', 400);
        }

        try {
            $result = $this->refreshCustomerToken->execute(
                $refreshToken,
                $request->getHeader('User-Agent'),
                $request->getClientIp()
            );

            // Verify business matches
            if ($result['client']['business_id'] !== $businessId) {
                return Response::error('Invalid refresh token for this business', 'invalid_token', 401);
            }

            $response = Response::success($result, 200);

            // Update refresh token cookie
            $response->setCookie(
                'customer_refresh_token',
                $result['refresh_token'],
                [
                    'httpOnly' => true,
                    'secure' => true,
                    'sameSite' => 'Strict',
                    'maxAge' => 90 * 24 * 60 * 60,
                    'path' => "/v1/customer/{$businessId}/auth",
                ]
            );

            return $response;

        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }

    /**
     * POST /v1/customer/{business_id}/auth/logout
     */
    public function logout(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');

        $refreshToken = $request->getCookie('customer_refresh_token') 
            ?? $request->getBody()['refresh_token'] 
            ?? null;

        if ($refreshToken !== null) {
            $this->logoutCustomer->execute($refreshToken);
        }

        $response = Response::success(['message' => 'Logged out successfully'], 200);

        // Clear refresh token cookie
        $response->setCookie(
            'customer_refresh_token',
            '',
            [
                'httpOnly' => true,
                'secure' => true,
                'sameSite' => 'Strict',
                'maxAge' => 0,
                'path' => "/v1/customer/{$businessId}/auth",
            ]
        );

        return $response;
    }

    /**
     * GET /v1/customer/me
     * Protected by CustomerAuthMiddleware - requires customer JWT.
     */
    public function me(Request $request): Response
    {
        $clientId = $request->getAttribute('client_id');

        if ($clientId === null) {
            return Response::error('Unauthorized', 'unauthorized', 401);
        }

        try {
            $client = $this->getCustomerMe->execute((int) $clientId);
            return Response::success($client, 200);
        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }

    /**
     * POST /v1/customer/{business_id}/auth/forgot-password
     * Request password reset email for customer.
     */
    public function forgotPassword(Request $request): Response
    {
        $businessId = (int) $request->getRouteParam('business_id');
        
        // Verify business exists
        $business = $this->businessRepository->findById($businessId);
        if ($business === null) {
            return Response::error('Business not found', 'not_found', 404);
        }

        $body = $request->getBody();
        $email = $body['email'] ?? null;

        if ($email === null || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return Response::error('Valid email is required', 'validation_error', 400);
        }

        // Execute reset request - returns false if email not found
        $emailFound = $this->requestPasswordReset->execute($email, $businessId);

        if (!$emailFound) {
            return Response::error(
                'Email not found in our system',
                'email_not_found',
                404
            );
        }

        return Response::success([
            'message' => 'Password reset email sent successfully.',
        ], 200);
    }

    /**
     * POST /v1/customer/auth/reset-password
     * Reset password using token from email.
     */
    public function resetPasswordWithToken(Request $request): Response
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
                'message' => 'Password has been reset successfully. You can now login with your new password.',
            ], 200);
        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }

    /**
     * PUT /v1/customer/me
     * Update customer profile.
     * Protected by CustomerAuthMiddleware.
     */
    public function updateProfile(Request $request): Response
    {
        $clientId = $request->getAttribute('client_id');

        if ($clientId === null) {
            return Response::error('Unauthorized', 'unauthorized', 401);
        }

        $body = $request->getBody();

        try {
            $client = $this->updateCustomerProfile->execute(
                (int) $clientId,
                $body['first_name'] ?? null,
                $body['last_name'] ?? null,
                $body['email'] ?? null,
                $body['phone'] ?? null
            );
            return Response::success($client, 200);
        } catch (ValidationException $e) {
            return Response::error($e->getMessage(), 'validation_error', 400);
        }
    }

    /**
     * POST /v1/customer/me/change-password
     * Change password for authenticated customer.
     * Protected by CustomerAuthMiddleware.
     */
    public function changePassword(Request $request): Response
    {
        $clientId = $request->getAttribute('client_id');

        if ($clientId === null) {
            return Response::error('Unauthorized', 'unauthorized', 401);
        }

        $body = $request->getBody();
        $currentPassword = $body['current_password'] ?? null;
        $newPassword = $body['new_password'] ?? null;

        if ($currentPassword === null || $newPassword === null) {
            return Response::error('Current password and new password are required', 'validation_error', 400);
        }

        try {
            $this->changeCustomerPassword->execute(
                (int) $clientId,
                $currentPassword,
                $newPassword
            );
            return Response::success([
                'message' => 'Password changed successfully.',
            ], 200);
        } catch (AuthException $e) {
            return Response::error($e->getMessage(), $e->getErrorCode(), $e->getHttpStatus());
        }
    }
}
