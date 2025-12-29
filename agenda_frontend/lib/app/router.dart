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
import 'providers/route_slug_provider.dart';

/// Router provider con supporto path-based multi-business
///
/// Struttura URL:
/// - /                      → Landing page (business non specificato)
/// - /:slug                 → Redirect a /:slug/booking
/// - /:slug/booking         → Schermata prenotazione
/// - /:slug/login           → Login
/// - /:slug/register        → Registrazione
/// - /:slug/my-bookings     → Le mie prenotazioni
/// - /reset-password/:token → Reset password (globale, no slug)
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(
    authProvider.select((state) => state.isAuthenticated),
  );

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,

    // Aggiorna routeSlugProvider quando la route cambia
    redirect: (context, state) {
      final pathSegments = state.uri.pathSegments;

      // Estrae lo slug dal path (primo segmento se non è una route riservata)
      String? slug;
      if (pathSegments.isNotEmpty) {
        final firstSegment = pathSegments.first;
        if (!_reservedPaths.contains(firstSegment)) {
          slug = firstSegment;
        }
      }

      // Aggiorna il provider con lo slug corrente
      // Usiamo Future.microtask per evitare modifiche durante il build
      Future.microtask(() {
        ref.read(routeSlugProvider.notifier).state = slug;
      });

      // Se siamo su /:slug senza sotto-path, redirect a /:slug/booking
      if (slug != null && pathSegments.length == 1) {
        return '/$slug/booking';
      }

      // Auth redirect logic per route con slug
      if (slug != null) {
        final subPath = pathSegments.length > 1 ? pathSegments[1] : '';

        // Se non autenticato e cerca di accedere a my-bookings, redirect a login
        if (!isAuthenticated && subPath == 'my-bookings') {
          return '/$slug/login';
        }

        // Se autenticato e cerca di accedere a login/register, redirect a booking
        if (isAuthenticated && (subPath == 'login' || subPath == 'register')) {
          return '/$slug/booking';
        }
      }

      return null;
    },

    routes: [
      // ============================================
      // ROUTE GLOBALI (senza business context)
      // ============================================

      /// Landing page - nessun business specificato
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const _LandingScreen(),
      ),

      /// Reset password (globale, il link viene da email)
      GoRoute(
        path: '/reset-password/:token',
        name: 'reset-password',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),

      // ============================================
      // ROUTE CON BUSINESS CONTEXT (/:slug/*)
      // ============================================

      /// Prenotazione - route principale del business
      GoRoute(
        path: '/:slug/booking',
        name: 'business-booking',
        builder: (context, state) => const BookingScreen(),
      ),

      /// Login con context business
      GoRoute(
        path: '/:slug/login',
        name: 'business-login',
        builder: (context, state) => const LoginScreen(),
      ),

      /// Registrazione con context business
      GoRoute(
        path: '/:slug/register',
        name: 'business-register',
        builder: (context, state) => const RegisterScreen(),
      ),

      /// Le mie prenotazioni (richiede auth)
      GoRoute(
        path: '/:slug/my-bookings',
        name: 'business-my-bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),

      /// Cambio password (richiede auth)
      GoRoute(
        path: '/:slug/change-password',
        name: 'business-change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      /// Catch-all per /:slug → redirect a /:slug/booking
      /// Gestito nel redirect, ma serve come fallback
      GoRoute(
        path: '/:slug',
        redirect: (context, state) {
          final slug = state.pathParameters['slug'];
          return '/$slug/booking';
        },
      ),
    ],

    errorBuilder: (context, state) => _ErrorScreen(path: state.uri.path),
  );
});

/// Path riservati che NON sono slug di business
const _reservedPaths = {
  'reset-password',
  'login',
  'register',
  'booking',
  'my-bookings',
  'change-password',
  'privacy',
  'terms',
};

/// Schermata landing - nessun business specificato
class _LandingScreen extends ConsumerWidget {
  const _LandingScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      body: Center(
        child: Column(
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Schermata errore 404
class _ErrorScreen extends StatelessWidget {
  final String path;

  const _ErrorScreen({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Pagina non trovata',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              path,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
