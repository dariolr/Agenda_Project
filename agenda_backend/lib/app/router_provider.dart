import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10_extension.dart';
import '../features/agenda/presentation/agenda_screen.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/business/presentation/business_list_screen.dart';
import '../features/clients/presentation/clients_screen.dart';
import '../features/services/presentation/services_screen.dart';
import '../features/staff/presentation/staff_week_overview_screen.dart';
import '../features/staff/presentation/team_screen.dart';
import 'scaffold_with_navigation.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider derivato che cambia SOLO quando cambia l'autenticazione effettiva
/// NON quando cambia solo l'errorMessage (evita rebuild inutili del router)
final _routerAuthStateProvider =
    Provider<
      ({bool isAuthenticated, bool isSuperadmin, bool isInitialOrLoading})
    >((ref) {
      final authState = ref.watch(authProvider);
      return (
        isAuthenticated: authState.isAuthenticated,
        isSuperadmin: authState.user?.isSuperadmin ?? false,
        isInitialOrLoading:
            authState.status == AuthStatus.initial ||
            authState.status == AuthStatus.loading,
      );
    });

/// Provider per il router con supporto autenticazione.
final routerProvider = Provider<GoRouter>((ref) {
  // Usa il provider derivato per evitare rebuild quando cambia solo errorMessage
  final authInfo = ref.watch(_routerAuthStateProvider);
  final isAuthenticated = authInfo.isAuthenticated;
  final isSuperadmin = authInfo.isSuperadmin;
  final isInitialOrLoading = authInfo.isInitialOrLoading;

  final superadminSelectedBusiness = ref.watch(
    superadminSelectedBusinessProvider,
  );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: kDebugMode,

    // Refresh router quando cambia lo stato auth
    refreshListenable: _AuthNotifier(ref),

    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnBusinessList = state.matchedLocation == '/businesses';

      debugPrint(
        '🔀 Router redirect: path=${state.matchedLocation}, '
        'isLoggedIn=$isAuthenticated, isSuperadmin=$isSuperadmin, '
        'selectedBusiness=$superadminSelectedBusiness',
      );

      // Durante il caricamento iniziale, non fare redirect
      if (isInitialOrLoading) {
        return null;
      }

      // Pagine pubbliche che non richiedono autenticazione
      final isPublicPage =
          isLoggingIn || state.matchedLocation.startsWith('/reset-password');

      // Se non loggato e non su pagina pubblica, vai al login
      if (!isAuthenticated && !isPublicPage) {
        return '/login';
      }

      // Se loggato e sulla pagina login
      if (isAuthenticated && isLoggingIn) {
        // Se superadmin senza business selezionato, vai alla lista business
        if (isSuperadmin && superadminSelectedBusiness == null) {
          debugPrint('🔀 Superadmin → /businesses');
          return '/businesses';
        }
        return '/agenda';
      }

      // Se superadmin tenta di accedere all'agenda senza aver selezionato un business
      if (isAuthenticated &&
          isSuperadmin &&
          superadminSelectedBusiness == null &&
          !isOnBusinessList &&
          !isLoggingIn) {
        debugPrint('🔀 Superadmin senza business → /businesses');
        return '/businesses';
      }

      return null;
    },

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: Text(context.l10n.errorTitle)),
      body: Center(
        child: Text(
          context.l10n.errorNotFound(state.uri.path),
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    ),

    routes: [
      // Route login (fuori dalla shell)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Route reset password (fuori dalla shell, pubblica)
      GoRoute(
        path: '/reset-password/:token',
        name: 'reset-password',
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return ResetPasswordScreen(token: token);
        },
      ),

      // Route lista business per superadmin (fuori dalla shell)
      GoRoute(
        path: '/businesses',
        name: 'businesses',
        builder: (context, state) => const BusinessListScreen(),
      ),

      // Shell con navigazione principale
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavigation(navigationShell: navigationShell);
        },
        branches: [
          // --- Ramo 0: Agenda ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/agenda',
                name: 'agenda',
                builder: (BuildContext context, GoRouterState state) {
                  final q = state.uri.queryParameters['clientId'];
                  final initialClientId = q == null ? null : int.tryParse(q);
                  return AgendaScreen(initialClientId: initialClientId);
                },
              ),
            ],
          ),

          // --- Ramo 1: Clienti ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clienti',
                name: 'clienti',
                builder: (BuildContext context, GoRouterState state) =>
                    const ClientsScreen(),
              ),
            ],
          ),

          // --- Ramo 2: Servizi ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/servizi',
                name: 'servizi',
                builder: (BuildContext context, GoRouterState state) =>
                    const ServicesScreen(),
              ),
            ],
          ),

          // --- Ramo 3: Staff ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/staff',
                name: 'staff',
                builder: (BuildContext context, GoRouterState state) =>
                    const TeamScreen(),
              ),
            ],
          ),
        ],
      ),

      // Route esterne alla shell
      GoRoute(
        path: '/staff-availability',
        name: 'staff-availability',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            const StaffWeekOverviewScreen(),
      ),

      // Route cambio password
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            const ChangePasswordScreen(),
      ),
    ],
  );
});

/// Notifier per aggiornare il router quando cambia l'auth state.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      // Se l'utente si disconnette, resetta la selezione business del superadmin
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        _ref.read(superadminSelectedBusinessProvider.notifier).clear();
      }
      notifyListeners();
    });
  }

  final Ref _ref;
}
