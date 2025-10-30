import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Importa le nuove schermate
import '../features/agenda/presentation/agenda_screen.dart';
import '../features/clients/presentation/clients_screen.dart';
import '../features/services/presentation/services_screen.dart';
import '../features/staff/presentation/staff_screen.dart';
// Importa la nostra "Shell"
import 'scaffold_with_navigation.dart';
import '../core/l10n/l10_extension.dart';

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
              builder: (BuildContext context, GoRouterState state) =>
                  const AgendaScreen(),
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
                  const StaffScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
