import 'package:agenda_backend/core/models/service.dart';
import 'package:agenda_backend/features/services/utils/service_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceValidators.isDuplicateServiceName', () {
    test('matches active services case-insensitively', () {
      final services = [
        const Service(id: 1, businessId: 1, categoryId: 1, name: 'Taglio'),
      ];

      expect(
        ServiceValidators.isDuplicateServiceName(services, 'taglio'),
        isTrue,
      );
    });

    test('ignores inactive services', () {
      final services = [
        const Service(
          id: 1,
          businessId: 1,
          categoryId: 1,
          name: 'Taglio',
          isActive: false,
        ),
      ];

      expect(
        ServiceValidators.isDuplicateServiceName(services, 'Taglio'),
        isFalse,
      );
    });

    test('ignores the excluded service id while editing', () {
      final services = [
        const Service(id: 1, businessId: 1, categoryId: 1, name: 'Taglio'),
      ];

      expect(
        ServiceValidators.isDuplicateServiceName(
          services,
          'Taglio',
          excludeId: 1,
        ),
        isFalse,
      );
    });
  });
}
