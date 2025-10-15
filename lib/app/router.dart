import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/agenda/presentation/agenda_screen.dart';

/// 🔹 Router globale dell’app (GoRouter v16+ compatibile)
final GoRouter appRouter = GoRouter(
  initialLocation: '/agenda',
  routes: [
    GoRoute(
      path: '/agenda',
      name: 'agenda',
      builder: (BuildContext context, GoRouterState state) => AgendaScreen(),
    ),
  ],

  // 🔸 Gestione errori: se la route non esiste
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Errore')),
    body: Center(
      child: Text(
        'Pagina non trovata: ${state.uri.path}',
        style: const TextStyle(color: Colors.redAccent),
      ),
    ),
  ),

  // 🔸 Debug logging (facoltativo)
  debugLogDiagnostics: true,
);
