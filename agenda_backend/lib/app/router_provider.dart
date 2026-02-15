import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10_extension.dart';
import '../features/agenda/presentation/agenda_screen.dart';
import '../features/agenda/providers/business_providers.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/providers/current_business_user_provider.dart';
import '../features/booking_notifications/presentation/booking_notifications_screen.dart';
import '../features/bookings_list/presentation/bookings_list_screen.dart';
import '../features/business/presentation/business_list_screen.dart';
import '../features/business/presentation/invitation_accept_screen.dart';
import '../features/business/presentation/location_closures_screen.dart';
import '../features/business/presentation/operators_screen.dart';
import '../features/business/presentation/user_business_switch_screen.dart';
import '../features/business/providers/superadmin_selected_business_provider.dart';
import '../features/class_events/presentation/class_events_screen.dart';
import '../features/clients/presentation/clients_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/services/presentation/services_screen.dart';
import '../features/staff/presentation/staff_week_overview_screen.dart';
import '../features/staff/presentation/team_screen.dart';
import 'scaffold_with_navigation.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => _rootNavigatorKey,
);

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

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: kDebugMode,

    // Refresh router quando cambia lo stato auth
    refreshListenable: _AuthNotifier(ref),

    redirect: (context, state) {
      final browserPath = Uri.base.path;
      final isInvitationBrowserUrl =
          browserPath == '/invitation' ||
          browserPath.startsWith('/invitation/');
      final browserLocation = Uri.base.hasQuery
          ? '${Uri.base.path}?${Uri.base.query}'
          : Uri.base.path;

      // Single source of truth for invitation deep-links:
      // if browser URL is /invitation/{token}, keep router locked there.
      if (isInvitationBrowserUrl) {
        final allowLeaveInvitation =
            state.uri.queryParameters['leave_invitation'] == '1';
        if (allowLeaveInvitation) {
          return null;
        }
        final stateLocation = state.uri.hasQuery
            ? '${state.uri.path}?${state.uri.query}'
            : state.uri.path;
        if (stateLocation != browserLocation) {
          return browserLocation;
        }
        return null;
      }

      final isLoggingIn = state.matchedLocation == '/login';
      final isOnBusinessList = state.matchedLocation == '/businesses';
      final isOnUserBusinessSwitch = state.matchedLocation == '/my-businesses';
      final invitationPath = state.uri.path;
      final isInvitationPage =
          invitationPath == '/invitation' ||
          invitationPath.startsWith('/invitation/');
      final canManageClients = ref.read(currentUserCanManageClientsProvider);
      final canViewServices = ref.read(currentUserCanViewServicesProvider);
      final canViewStaff = ref.read(currentUserCanViewStaffProvider);
      final canManageOperators = ref.read(canManageOperatorsProvider);
      final canManageBusinessSettings = ref.read(
        canManageBusinessSettingsProvider,
      );
      final canViewReports = ref.read(currentUserCanViewReportsProvider);
      final canAccessClassEvents = ref.read(
        currentUserCanAccessClassEventsProvider,
      );
      final currentBusinessId = ref.read(currentBusinessIdProvider);
      final superadminSelectedBusiness = ref.read(
        superadminSelectedBusinessProvider,
      );

      // Durante il caricamento iniziale, non fare redirect
      if (isInitialOrLoading) {
        return null;
      }

      // Pagine pubbliche che non richiedono autenticazione
      final isPublicPage =
          isLoggingIn ||
          state.matchedLocation.startsWith('/reset-password') ||
          isInvitationPage;

      // Se non loggato e non su pagina pubblica, vai al login
      if (!isAuthenticated && !isPublicPage) {
        return '/login';
      }

      // Se loggato e sulla pagina login
      if (isAuthenticated && isLoggingIn) {
        final redirect = state.uri.queryParameters['redirect'];
        if (redirect != null && redirect.startsWith('/')) {
          return redirect;
        }
        // Dopo login: superadmin su lista business admin, utenti normali su selettore personale.
        return isSuperadmin ? '/businesses' : '/my-businesses';
      }

      // Business list admin solo per superadmin.
      if (isAuthenticated && !isSuperadmin && isOnBusinessList) {
        return '/my-businesses';
      }

      // Se superadmin va alla schermata switch user, riporta alla lista admin.
      if (isAuthenticated && isSuperadmin && isOnUserBusinessSwitch) {
        return '/businesses';
      }

      // Per utenti non superadmin:
      // - /my-businesses è usata in due casi:
      //   1) selezione iniziale (business non ancora selezionato)
      //   2) switch esplicito dal menu (?switch=1)
      // - se esiste già un business corrente e non è uno switch esplicito,
      //   evita rimbalzi tornando in agenda.
      if (isAuthenticated && !isSuperadmin && isOnUserBusinessSwitch) {
        final isExplicitSwitch = state.uri.queryParameters['switch'] == '1';
        if (!isExplicitSwitch && currentBusinessId > 0) {
          return '/agenda';
        }
      }

      // Se superadmin tenta di accedere all'agenda senza aver selezionato un business
      if (isAuthenticated &&
          isSuperadmin &&
          superadminSelectedBusiness == null &&
          !isInvitationPage &&
          !isOnBusinessList &&
          !isOnUserBusinessSwitch &&
          !isLoggingIn) {
        return '/businesses';
      }

      // Route guard by explicit permissions.
      if (isAuthenticated && !isSuperadmin) {
        final path = state.uri.path;
        if (path == '/clienti' && !canManageClients) return '/agenda';
        if (path == '/servizi' && !canViewServices) return '/agenda';
        if (path == '/staff' && !canViewStaff) return '/agenda';
        if (path == '/staff-availability' && !canViewStaff) return '/agenda';
        if (path == '/report' && !canViewReports) return '/agenda';
        if (path == '/chiusure' && !canManageBusinessSettings) return '/agenda';
        if (path == '/altro/classi' && !canAccessClassEvents) return '/agenda';
        if (path == '/permessi' && !canManageOperators) return '/agenda';
        if (path.startsWith('/operatori/') && !canManageOperators) {
          return '/agenda';
        }
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
        builder: (context, state) =>
            LoginScreen(redirectTo: state.uri.queryParameters['redirect']),
      ),

      GoRoute(
        path: '/invitation/:token',
        name: 'invitation',
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return InvitationAcceptScreen(token: token);
        },
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

      // Route selezione business per utenti non superadmin
      GoRoute(
        path: '/my-businesses',
        name: 'my-businesses',
        builder: (context, state) => const UserBusinessSwitchScreen(),
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

          // --- Ramo 4: Report ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/report',
                name: 'report',
                builder: (BuildContext context, GoRouterState state) =>
                    const ReportsScreen(),
              ),
            ],
          ),

          // --- Ramo 5: Elenco Prenotazioni ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/prenotazioni',
                name: 'prenotazioni',
                builder: (BuildContext context, GoRouterState state) =>
                    const BookingsListScreen(),
              ),
            ],
          ),

          // --- Ramo 6: Altro (schermata con cards) ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/altro',
                name: 'altro',
                builder: (BuildContext context, GoRouterState state) =>
                    const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'classi',
                    name: 'class-events',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ClassEventsScreen(),
                  ),
                ],
              ),
            ],
          ),

          // --- Ramo 7: Chiusure ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chiusure',
                name: 'chiusure',
                builder: (BuildContext context, GoRouterState state) =>
                    const LocationClosuresScreen(),
              ),
            ],
          ),

          // --- Ramo 8: Profilo ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profilo',
                name: 'profilo',
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(),
              ),
            ],
          ),

          // --- Ramo 9: Permessi ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/permessi',
                name: 'permessi',
                builder: (BuildContext context, GoRouterState state) =>
                    const OperatorsScreen(),
              ),
            ],
          ),

          // --- Ramo 10: Notifiche Prenotazioni ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifiche-prenotazioni',
                name: 'notifiche-prenotazioni',
                builder: (BuildContext context, GoRouterState state) =>
                    const BookingNotificationsScreen(),
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

      // Route operatori business
      GoRoute(
        path: '/operatori/:businessId',
        name: 'operatori',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          final businessId = int.parse(state.pathParameters['businessId']!);
          return OperatorsScreen(businessId: businessId);
        },
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
        invalidateBusinessScopedProviders(_ref);
      }
      notifyListeners();
    });
  }

  final Ref _ref;
}
