import 'package:agenda_backend/app/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('appRouter exposes four main navigation branches', () {
    final routes = appRouter.configuration.routes;
    expect(routes.length, 2);

    final shellRoute = routes.first;
    expect(shellRoute, isA<StatefulShellRoute>());

    final branches = (shellRoute as StatefulShellRoute).branches
        .map((b) => b.routes)
        .toList();
    expect(branches.length, 4);

    final branchPaths = branches
        .map((routes) => (routes.first as GoRoute).path)
        .toSet();
    expect(
      branchPaths,
      containsAll(['/agenda', '/clienti', '/servizi', '/staff']),
    );
  });
}
