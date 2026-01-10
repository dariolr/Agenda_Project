import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10_extension.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/booking/presentation/screens/booking_screen.dart';
import '../features/booking/presentation/screens/my_bookings_screen.dart';
import '../features/booking/providers/locations_provider.dart';
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
  // NOTA: usa ref.read per evitare rebuild del router quando auth cambia
  // Il redirect legge sempre lo stato auth corrente senza causare loop

  // Listenable che triggera refresh del router quando auth cambia
  final authRefreshListenable = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authRefreshListenable,
    redirect: (context, state) {
      // Legge auth con ref.read (non ref.watch) per evitare loop
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;

      // Se auth è ancora in loading/initial, non fare redirect auth
      // Il refreshListenable trigghererà un nuovo check quando l'auth è pronto
      final authReady =
          authState.status != AuthStatus.initial &&
          authState.status != AuthStatus.loading;

      // Filtra segmenti vuoti (trailing slash produce ['slug', ''])
      final pathSegments = state.uri.pathSegments
          .where((s) => s.isNotEmpty)
          .toList();

      // Estrae lo slug dal path (primo segmento se non è una route riservata)
      String? slug;
      if (pathSegments.isNotEmpty) {
        final firstSegment = pathSegments.first;
        if (!_reservedPaths.contains(firstSegment)) {
          slug = firstSegment;
        }
      }

      debugPrint('🔀 ROUTER: extracted slug=$slug');

      // Estrae location ID dal query param (?location=4)
      final locationParam = state.uri.queryParameters['location'];
      final urlLocationId = locationParam != null
          ? int.tryParse(locationParam)
          : null;

      // Aggiorna i provider con slug e location correnti
      // Usiamo Future.microtask per evitare modifiche durante il build
      Future.microtask(() {
        ref.read(routeSlugProvider.notifier).state = slug;
        ref.read(urlLocationIdProvider.notifier).state = urlLocationId;
        debugPrint(
          '🔀 ROUTER: routeSlugProvider updated to $slug, urlLocationId=$urlLocationId',
        );
      });

      // Se siamo su /:slug senza sotto-path, redirect a /:slug/booking (mantieni query params)
      if (slug != null && pathSegments.length == 1) {
        final query = state.uri.query.isNotEmpty ? '?${state.uri.query}' : '';
        debugPrint('🔀 ROUTER: redirecting to /$slug/booking$query');
        return '/$slug/booking$query';
      }

      // Auth redirect logic per route con slug (solo se auth è ready)
      if (slug != null && authReady) {
        final subPath = pathSegments.length > 1 ? pathSegments[1] : '';

        // Route protette che richiedono autenticazione
        // booking incluso: l'utente deve essere loggato per prenotare
        const protectedRoutes = {
          'booking',
          'my-bookings',
          'profile',
          'change-password',
        };

        // Se non autenticato e cerca di accedere a route protetta, redirect a login
        if (!isAuthenticated && protectedRoutes.contains(subPath)) {
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
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return RegisterScreen(initialEmail: email);
        },
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

      /// Profilo utente (richiede auth)
      GoRoute(
        path: '/:slug/profile',
        name: 'business-profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      /// Reset password con business context (link da email)
      GoRoute(
        path: '/:slug/reset-password/:token',
        name: 'business-reset-password',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
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
  'profile',
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

/// Listenable che notifica il router quando lo stato auth cambia
/// Permette di ri-valutare i redirect dopo il restore della sessione
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    // Ascolta i cambiamenti dello stato auth
    _ref.listen(authProvider, (previous, next) {
      // Notifica solo quando lo status cambia (non per ogni cambio di state)
      if (previous?.status != next.status) {
        debugPrint(
          '🔀 ROUTER: auth status changed ${previous?.status} → ${next.status}',
        );
        notifyListeners();
      }
    });
  }

  final Ref _ref;
}
