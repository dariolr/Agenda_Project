import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10_extension.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/booking/presentation/screens/booking_screen.dart';
import '../features/booking/presentation/screens/my_bookings_screen.dart';
import '../features/booking/providers/business_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Usa select per evitare rebuild su ogni cambio di stato auth
  final isAuthenticated = ref.watch(
    authProvider.select((state) => state.isAuthenticated),
  );

  // Ottiene lo slug del business corrente dall'URL
  final businessSlug = ref.watch(businessSlugProvider);

  return GoRouter(
    // Se c'è uno slug, vai al booking; altrimenti mostra landing
    initialLocation: businessSlug != null ? '/booking' : '/',
    debugLogDiagnostics: false, // Disabilita log in produzione
    redirect: (context, state) {
      final path = state.matchedLocation;

      // Se non c'è slug e non siamo sulla landing, mostra landing
      if (businessSlug == null && path != '/') {
        return '/';
      }

      // Auth redirect logic
      final isLoggingIn = path == '/login';
      final isRegistering = path == '/register';
      final isResettingPassword = path.startsWith('/reset-password');

      // Se non è autenticato e non sta cercando di loggarsi o registrarsi
      if (!isAuthenticated &&
          !isLoggingIn &&
          !isRegistering &&
          !isResettingPassword &&
          path != '/' &&
          path != '/booking') {
        return '/booking';
      }

      // Se è autenticato e sta cercando di accedere a login/register
      if (isAuthenticated && (isLoggingIn || isRegistering)) {
        return '/booking';
      }

      return null;
    },
    routes: [
      // Landing page - business non specificato
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const _BusinessNotFoundScreen(),
      ),
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

/// Schermata per business non trovato o URL senza slug
class _BusinessNotFoundScreen extends ConsumerWidget {
  const _BusinessNotFoundScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final businessAsync = ref.watch(currentBusinessProvider);

    return Scaffold(
      body: Center(
        child: businessAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n.errorGeneric,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          data: (business) {
            // Se il business è null, mostra il messaggio
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_outlined, size: 64),
                const SizedBox(height: 16),
                Text(
                  l10n.businessNotFound,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    l10n.businessNotFoundHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha((0.6 * 255).round()),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
