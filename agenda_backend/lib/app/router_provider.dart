import 'dart:async';

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
import '../features/auth/presentation/meta_whatsapp_callback_screen.dart';
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
import '../features/clients/presentation/clients_screen.dart';
import '../features/more/presentation/locations_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/more/presentation/whatsapp_business_screen.dart';
import '../features/payments/presentation/payment_methods_screen.dart';
import '../features/billing/presentation/billing_screen.dart';
import '../features/billing/providers/billing_provider.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/services/presentation/services_screen.dart';
import '../features/staff/presentation/staff_week_overview_screen.dart';
import '../features/staff/presentation/team_screen.dart';
import '../core/services/preferences_service.dart';
import 'scaffold_with_navigation.dart';
import 'providers/router_debug_log_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => _rootNavigatorKey,
);
const Duration _lastVisitedRouteTtl = Duration(hours: 8);

String _toLocationString(Uri uri) {
  final path = uri.path;
  if (!uri.hasQuery || uri.query.isEmpty) {
    return path;
  }
  return '$path?${uri.query}';
}

bool _isRestorableLocation(String location) {
  final uri = Uri.tryParse(location);
  if (uri == null) return false;
  final path = uri.path;
  if (!path.startsWith('/')) return false;

  if (path == '/login') return false;
  if (path == '/change-password') return false;
  if (path == '/staff-availability') return false;
  if (path == '/auth/meta-whatsapp-callback') return false;
  if (path.startsWith('/invitation')) return false;
  if (path.startsWith('/reset-password')) return false;
  if (path.startsWith('/businesses')) return false;
  if (path.startsWith('/my-businesses')) return false;

  return true;
}

/// Provider per il router con supporto autenticazione.
/// Il GoRouter è una singola istanza stabile: non rebuilda mai al cambio auth.
/// L'auth state viene letto fresco dentro il redirect ad ogni valutazione.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: kDebugMode,

    // Refresh router quando cambia lo stato auth
    refreshListenable: _AuthNotifier(ref),

    redirect: (context, state) {
      // Auth state fresco ad ogni valutazione — non catturato alla creazione del GoRouter.
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isSuperadmin = authState.user?.isSuperadmin ?? false;
      final isInitialOrLoading =
          authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading;

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

      final isLoggingIn = state.uri.path == '/login';
      final isOnBusinessList = state.uri.path == '/businesses';
      final isOnSuperadminBookingNotifications =
          state.uri.path.startsWith('/businesses/notifiche-prenotazioni');
      final isOnUserBusinessSwitch = state.uri.path == '/my-businesses';
      final isOnChangePassword = state.uri.path == '/change-password';
      final isMetaWhatsappCallbackPage =
          state.uri.path == '/auth/meta-whatsapp-callback';
      final invitationPath = state.uri.path;
      final isInvitationPage =
          invitationPath == '/invitation' ||
          invitationPath.startsWith('/invitation/');
      final canViewServices = ref.read(currentUserCanViewServicesProvider);
      final canViewStaff = ref.read(currentUserCanViewStaffProvider);
      final canManageOperators = ref.read(canManageOperatorsProvider);
      final canManageBusinessSettings = ref.read(
        canManageBusinessSettingsProvider,
      );
      final canViewReports = ref.read(currentUserCanViewReportsProvider);
      final canAccessClassEvents = ref.read(currentUserCanViewServicesProvider);
      final currentBusinessId = ref.read(currentBusinessIdProvider);
      final superadminSelectedBusiness = ref.read(
        superadminSelectedBusinessProvider,
      );
      final authenticatedUserId = authState.user?.id;
      final currentLocation = _toLocationString(state.uri);
      final prefs = ref.read(preferencesServiceProvider);

      // [DEBUG] Helper locale per loggare i redirect del router.
      void rlog(String reason, [String? to]) {
        final now = DateTime.now();
        final hms =
            '${now.hour.toString().padLeft(2, '0')}'
            ':${now.minute.toString().padLeft(2, '0')}'
            ':${now.second.toString().padLeft(2, '0')}'
            '.${now.millisecond.toString().padLeft(3, '0')}';
        final toStr = to != null ? ' →$to' : '';
        final saBiz = superadminSelectedBusiness?.toString() ?? 'null';
        final line =
            '[$hms] ${state.uri.path}$toStr | $reason'
            ' | auth=$isAuthenticated sa=$isSuperadmin'
            ' | saBiz=$saBiz bizId=$currentBusinessId'
            ' | match=${state.matchedLocation}';
        ref.read(routerDebugLogProvider.notifier).addLine(line);
      }

      // Durante il caricamento iniziale, non fare redirect
      if (isInitialOrLoading) {
        return null;
      }

      // Pagine pubbliche che non richiedono autenticazione
      final isPublicPage =
          isLoggingIn ||
          state.uri.path.startsWith('/reset-password') ||
          isMetaWhatsappCallbackPage ||
          isInvitationPage;

      // Persisti l'ultima route privata visitata per ripristino post-riavvio.
      if (isAuthenticated &&
          !isPublicPage &&
          authenticatedUserId != null &&
          _isRestorableLocation(currentLocation)) {
        unawaited(
          prefs.setLastVisitedRouteForUser(
            authenticatedUserId,
            currentLocation,
          ),
        );
      }

      // Se non loggato e non su pagina pubblica, vai al login preservando la destinazione.
      if (!isAuthenticated && !isPublicPage) {
        final encodedRedirect = Uri.encodeComponent(currentLocation);
        final loginWithRedirect = '/login?redirect=$encodedRedirect';
        rlog('not_authenticated_private_route', loginWithRedirect);
        return loginWithRedirect;
      }

      // Se loggato e sulla pagina login
      if (isAuthenticated && isLoggingIn) {
        final redirect = state.uri.queryParameters['redirect'];
        if (redirect != null && redirect.startsWith('/')) {
          rlog('login_authenticated_redirect_param', redirect);
          return redirect;
        }
        if (authenticatedUserId != null) {
          final savedLocation = prefs.getLastVisitedRouteForUser(
            authenticatedUserId,
            maxAge: _lastVisitedRouteTtl,
          );
          if (savedLocation != null && _isRestorableLocation(savedLocation)) {
            if (isSuperadmin && superadminSelectedBusiness == null) {
              rlog('login_authenticated_superadmin_no_business', '/businesses');
              return '/businesses';
            }
            if (!isSuperadmin && currentBusinessId <= 0) {
              rlog('login_authenticated_no_current_business', '/my-businesses');
              return '/my-businesses';
            }
            rlog('login_authenticated_restore_saved_location', savedLocation);
            return savedLocation;
          }
        }
        // Dopo login:
        // - superadmin: se ha un ultimo business selezionato, entra direttamente in agenda
        // - altrimenti va alla lista business admin
        // - utenti normali: selettore personale
        if (isSuperadmin) {
          if (superadminSelectedBusiness != null) {
            rlog('login_authenticated_superadmin_has_business', '/agenda');
            return '/agenda';
          }
          rlog('login_authenticated_superadmin_no_business_default', '/businesses');
          return '/businesses';
        }
        rlog('login_non_superadmin_default', '/my-businesses');
        return '/my-businesses';
      }

      // Business list admin solo per superadmin.
      if (isAuthenticated && !isSuperadmin && isOnBusinessList) {
        rlog('non_superadmin_on_businesses', '/my-businesses');
        return '/my-businesses';
      }
      if (isAuthenticated &&
          !isSuperadmin &&
          isOnSuperadminBookingNotifications) {
        rlog('non_superadmin_on_superadmin_booking_notifications', '/agenda');
        return '/agenda';
      }

      // Se superadmin va alla schermata switch user, riporta alla lista admin.
      if (isAuthenticated && isSuperadmin && isOnUserBusinessSwitch) {
        rlog('superadmin_on_my_businesses', '/businesses');
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
          rlog('non_superadmin_user_business_switch_without_switch_param', '/agenda');
          return '/agenda';
        }
      }

      // Se superadmin tenta di accedere all'agenda senza aver selezionato un business
      if (isAuthenticated &&
          isSuperadmin &&
          superadminSelectedBusiness == null &&
          !isInvitationPage &&
          !isOnBusinessList &&
          !isOnSuperadminBookingNotifications &&
          !isOnUserBusinessSwitch &&
          !isOnChangePassword &&
          !isLoggingIn) {
        rlog('superadmin_no_selected_business_guard', '/businesses');
        return '/businesses';
      }

      // Blocco accesso per billing scaduto (access_blocked server-side).
      if (isAuthenticated && !isSuperadmin) {
        final billing = ref.read(billingSubscriptionProvider).asData?.value;
        final isOnBillingScreen = state.uri.path == '/altro/abbonamento';
        final isOnMyBusinesses = state.uri.path == '/my-businesses';
        if (billing != null &&
            billing.accessBlocked &&
            !isOnBillingScreen &&
            !isOnMyBusinesses) {
          rlog('billing_access_blocked', '/altro/abbonamento');
          return '/altro/abbonamento';
        }
      }

      // Route guard by explicit permissions.
      if (isAuthenticated && !isSuperadmin) {
        final path = state.uri.path;

        if (path == '/servizi' && !canViewServices) {
          rlog('permission_guard_services', '/agenda');
          return '/agenda';
        }
        if (path == '/staff' && !canViewStaff) {
          rlog('permission_guard_staff', '/agenda');
          return '/agenda';
        }
        if (path == '/staff-availability' && !canViewStaff) {
          rlog('permission_guard_staff_availability', '/agenda');
          return '/agenda';
        }
        if (path == '/report' && !canViewReports) {
          rlog('permission_guard_reports', '/agenda');
          return '/agenda';
        }
        if (path == '/chiusure' && !canManageBusinessSettings) {
          rlog('permission_guard_closures', '/agenda');
          return '/agenda';
        }
        if (path == '/altro/classi' && !canAccessClassEvents) {
          rlog('permission_guard_class_events', '/agenda');
          return '/agenda';
        }
        if (path == '/altro/metodi-pagamento' && !canManageBusinessSettings) {
          rlog('permission_guard_payment_methods', '/agenda');
          return '/agenda';
        }
        if (path == '/altro/whatsapp-business' && !canManageBusinessSettings) {
          rlog('permission_guard_whatsapp_business', '/agenda');
          return '/agenda';
        }
        if (path == '/permessi' && !canManageOperators) {
          rlog('permission_guard_permissions', '/agenda');
          return '/agenda';
        }
        if (path.startsWith('/operatori/') && !canManageOperators) {
          rlog('permission_guard_operators', '/agenda');
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
      GoRoute(
        path: '/auth/meta-whatsapp-callback',
        name: 'meta-whatsapp-callback',
        builder: (context, state) => const MetaWhatsappCallbackScreen(),
      ),

      // Route lista business per superadmin (fuori dalla shell)
      GoRoute(
        path: '/businesses',
        name: 'businesses',
        builder: (context, state) => const BusinessListScreen(),
      ),
      GoRoute(
        path: '/businesses/notifiche-prenotazioni',
        name: 'superadmin-booking-notifications',
        builder: (context, state) => BookingNotificationsScreen(
          enableBusinessSelectorForSuperadmin: true,
          showStandaloneAppBar: true,
          initialTabIndex: state.uri.queryParameters['tab'] == 'whatsapp'
              ? 1
              : 0,
        ),
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
                pageBuilder: (BuildContext context, GoRouterState state) =>
                    const NoTransitionPage(child: TeamScreen()),
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
                    path: 'risorse',
                    name: 'more-resources',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        const NoTransitionPage(child: MoreResourcesScreen()),
                  ),
                  GoRoute(
                    path: 'sedi',
                    name: 'more-locations',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        const NoTransitionPage(child: MoreLocationsScreen()),
                  ),

                  GoRoute(
                    path: 'metodi-pagamento',
                    name: 'payment-methods',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        const NoTransitionPage(child: PaymentMethodsScreen()),
                  ),
                  GoRoute(
                    path: 'abbonamento',
                    name: 'billing',
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      final checkoutCanceled =
                          state.uri.queryParameters['billing'] == 'cancel';
                      return NoTransitionPage(
                        child: BillingScreen(
                          checkoutCanceled: checkoutCanceled,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'whatsapp-business',
                    name: 'more-whatsapp-business',
                    pageBuilder: (BuildContext context, GoRouterState state) =>
                        const NoTransitionPage(child: WhatsappBusinessScreen()),
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
                builder: (BuildContext context, GoRouterState state) {
                  final initialTab =
                      state.uri.queryParameters['tab'] == 'whatsapp' ? 1 : 0;
                  return BookingNotificationsScreen(
                    initialTabIndex: initialTab,
                  );
                },
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
            ChangePasswordScreen(targetUserId: state.extra as int?),
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
  router.routerDelegate.addListener(() {
    final loc = router.routerDelegate.currentConfiguration.uri.path;
    debugPrint('[routerDelegate.listener] location=$loc');
    ref.read(routerDebugLogProvider.notifier).addLine('delegate→ $loc');
  });
  return router;
});

/// Notifier per aggiornare il router quando cambia l'auth state.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      // Se l'utente si disconnette, resetta la selezione business del superadmin
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        _ref.read(routerDebugLogProvider.notifier).addLine(
          'AUTH DISCONNECT prev=${previous?.status} next=${next.status} → clear saBiz',
        );
        _ref.read(superadminSelectedBusinessProvider.notifier).clear();
        invalidateBusinessScopedProviders(_ref);
      } else {
        _ref.read(routerDebugLogProvider.notifier).addLine(
          'auth change prev=${previous?.status} next=${next.status}',
        );
      }
      notifyListeners();
    });

    // Importante per superadmin: se cambia la selezione business
    // deve rieseguire subito le redirect guard (es. /agenda -> /businesses).
    _ref.listen<int?>(superadminSelectedBusinessProvider, (previous, next) {
      if (previous == next) return;
      _ref.read(routerDebugLogProvider.notifier).addLine('saBiz: $previous→$next');
      notifyListeners();
    });

    // Riesegue i redirect anche quando cambia il business corrente effettivo.
    _ref.listen<int>(currentBusinessIdProvider, (previous, next) {
      if (previous == next) return;
      notifyListeners();
    });

    // Riesegue i redirect quando billing carica o cambia (access_blocked).
    _ref.listen(billingSubscriptionProvider, (previous, next) {
      final prevBlocked = previous?.when(
        data: (v) => v.accessBlocked,
        loading: () => null,
        error: (_, __) => null,
      );
      final nextBlocked = next.when(
        data: (v) => v.accessBlocked,
        loading: () => null,
        error: (_, __) => null,
      );
      if (prevBlocked != nextBlocked) notifyListeners();
    });

  }

  final Ref _ref;
}
