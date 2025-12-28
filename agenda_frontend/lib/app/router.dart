import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/booking/presentation/screens/booking_screen.dart';
import '../features/booking/presentation/screens/my_bookings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Usa select per evitare rebuild su ogni cambio di stato auth
  final isAuthenticated = ref.watch(
    authProvider.select((state) => state.isAuthenticated),
  );

  return GoRouter(
    initialLocation: '/booking',
    debugLogDiagnostics: false, // Disabilita log in produzione
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isResettingPassword = state.matchedLocation.startsWith(
        '/reset-password',
      );

      // Se non è autenticato e non sta cercando di loggarsi o registrarsi
      if (!isAuthenticated &&
          !isLoggingIn &&
          !isRegistering &&
          !isResettingPassword) {
        return '/booking';
      }

      // Se è autenticato e sta cercando di accedere a login/register
      if (isAuthenticated && (isLoggingIn || isRegistering)) {
        return '/booking';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/booking'),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/reset-password/:token',
        name: 'reset-password',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) => const BookingScreen(),
      ),
      GoRoute(
        path: '/my-bookings',
        name: 'my-bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Pagina non trovata: ${state.uri.path}')),
    ),
  );
});
