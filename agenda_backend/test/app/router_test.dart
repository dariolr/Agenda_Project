import 'package:agenda_backend/app/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('appRouter exposes six main navigation branches', () {
    final routes = appRouter.configuration.routes;
    // StatefulShellRoute + 4 route extra (staff-availability, profilo, change-password, reset-password)
    expect(routes.length, 5);

    final shellRoute = routes.first;
    expect(shellRoute, isA<StatefulShellRoute>());

    final branches = (shellRoute as StatefulShellRoute).branches
        .map((b) => b.routes)
        .toList();
    expect(branches.length, 6);

    final branchPaths = branches
        .map((routes) => (routes.first as GoRoute).path)
        .toSet();
    expect(
      branchPaths,
      containsAll([
        '/agenda',
        '/clienti',
        '/servizi',
        '/staff',
        '/report',
        '/prenotazioni',
      ]),
    );
  });
}
