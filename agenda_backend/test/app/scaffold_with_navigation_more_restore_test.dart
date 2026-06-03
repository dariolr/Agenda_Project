import 'package:agenda_backend/app/scaffold_with_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('More compact branch restore', () {
    test('keeps last non-agenda/client branch when clients nav is visible', () {
      expect(
        resolveMoreCompactBranchTarget(
          lastMoreBranchIndex: 4, // report
          includeClients: true,
        ),
        4,
      );
    });

    test('falls back to /altro root when last branch is agenda', () {
      expect(
        resolveMoreCompactBranchTarget(
          lastMoreBranchIndex: 0,
          includeClients: true,
        ),
        6,
      );
    });

    test(
      'falls back to /altro root when last branch is clienti and clients are visible',
      () {
        expect(
          resolveMoreCompactBranchTarget(
            lastMoreBranchIndex: 1,
            includeClients: true,
          ),
          6,
        );
      },
    );

    test('keeps branch index 1 when clients nav is hidden', () {
      expect(
        resolveMoreCompactBranchTarget(
          lastMoreBranchIndex: 1,
          includeClients: false,
        ),
        1,
      );
    });

    test('accepts future branch indexes without hardcoded upper bound', () {
      expect(
        resolveMoreCompactBranchTarget(
          lastMoreBranchIndex: 13,
          includeClients: true,
        ),
        13,
      );
    });

    test('remembers only routes that really live under /altro', () {
      expect(shouldRememberMoreCompactBranchLocation('/altro'), isTrue);
      expect(shouldRememberMoreCompactBranchLocation('/altro/risorse'), isTrue);
      expect(shouldRememberMoreCompactBranchLocation('/staff'), isFalse);
      expect(shouldRememberMoreCompactBranchLocation('/servizi'), isFalse);
      expect(shouldRememberMoreCompactBranchLocation('/report'), isFalse);
    });
  });
}
