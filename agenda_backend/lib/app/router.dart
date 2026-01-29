import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10_extension.dart';
// Importa le nuove schermate
import '../features/agenda/presentation/agenda_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/bookings_list/presentation/bookings_list_screen.dart';
import '../features/clients/presentation/clients_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/services/presentation/services_screen.dart';
import '../features/staff/presentation/staff_week_overview_screen.dart';
import '../features/staff/presentation/team_screen.dart';
// Importa la nostra "Shell"
import 'scaffold_with_navigation.dart';

// 1. Definiamo una chiave globale per la nostra Shell (necessaria)
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// 🔹 Router globale dell’app
final GoRouter appRouter = GoRouter(
  initialLocation: '/agenda',
  navigatorKey: _rootNavigatorKey,

  debugLogDiagnostics: kDebugMode,

  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.errorTitle)),
    body: Center(
      child: Text(
        context.l10n.errorNotFound(state.uri.path),
        style: const TextStyle(color: Colors.redAccent),
      ),
    ),
  ),

  // 2. Definiamo la nostra navigazione con `StatefulShellRoute`
  routes: [
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
    GoRoute(
      path: '/staff-availability',
      name: 'staff-availability',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const StaffWeekOverviewScreen(),
    ),
    // Route per profilo utente
    GoRoute(
      path: '/profilo',
      name: 'profilo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const ProfileScreen(),
    ),
    // Route per reset password (da email invito)
    GoRoute(
      path: '/reset-password/:token',
      name: 'reset-password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final token = state.pathParameters['token']!;
        return ResetPasswordScreen(token: token);
      },
    ),
    // Route per report
    GoRoute(
      path: '/report',
      name: 'report',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const ReportsScreen(),
    ),
    // Route per lista prenotazioni
    GoRoute(
      path: '/prenotazioni',
      name: 'prenotazioni',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const BookingsListScreen(),
    ),
  ],
);
