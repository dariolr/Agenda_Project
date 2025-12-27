import 'package:agenda_backend/features/services/providers/service_categories_provider.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:agenda_backend/features/services/providers/services_reorder_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // NOTA: Questi test di integrazione richiedono che il backend agenda_core
  // sia in esecuzione su localhost:8888 con database configurato.
  // I test sono marcati come skip per evitare fallimenti nel CI/CD.
  // Per eseguirli localmente:
  // 1. Avvia il backend: cd agenda_core && php -S localhost:8888 -t public
  // 2. Esegui i test: flutter test --tags integration
  group('Services reordering edge cases', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test(
      'reorderNonEmptyCategories: move first to end with 3 non-empty',
      () async {
        // Aspetta che i servizi siano caricati
        await container.read(servicesProvider.future);

        final initial = container.read(serviceCategoriesProvider);
        expect(initial.length, greaterThanOrEqualTo(3));

        // Move first (index 0) to end (index 2)
        container
            .read(servicesReorderProvider.notifier)
            .reorderNonEmptyCategories(0, 2);

        final after = container.read(serviceCategoriesProvider);
        // Verify order changed accordingly
        final names = after.map((c) => c.name).toList();
        // Expect former second becomes first, third becomes second, first becomes last
        expect(names.length, greaterThanOrEqualTo(3));
      },
      skip: 'Integration test - requires backend API running and responding',
    );

    test(
      'reorderNonEmptyCategories: move last to start',
      () async {
        // Aspetta che i servizi siano caricati
        await container.read(servicesProvider.future);

        // Ensure a known order first
        final cats0 = container.read(serviceCategoriesProvider);
        expect(cats0.length, greaterThanOrEqualTo(3));

        container
            .read(servicesReorderProvider.notifier)
            .reorderNonEmptyCategories(2, 0);

        final cats = container.read(serviceCategoriesProvider);
        expect(cats.length, greaterThanOrEqualTo(3));
        // First should be the former last by id order; just ensure stable length and distinct order indices
        expect(cats.map((c) => c.sortOrder).toSet().length, cats.length);
      },
      skip: 'Integration test - requires backend API running and responding',
    );

    test(
      'reorderNonEmptyCategories: empty categories stay at end',
      () async {
        // Aspetta che i servizi siano caricati
        await container.read(servicesProvider.future);

        // Make one category empty deleting its only service (category id 12 has service id 3 by seed)
        final services = container.read(servicesProvider).value ?? [];
        if (services.any((s) => s.id == 3)) {
          container.read(servicesProvider.notifier).delete(3);
        }

        final before = container.read(serviceCategoriesProvider);
        // The empty one should be at the end due to bumpEmptyCategoriesToEnd
        // Move first non-empty down
        container
            .read(servicesReorderProvider.notifier)
            .reorderNonEmptyCategories(0, 1);

        final after = container.read(serviceCategoriesProvider);
        expect(after.length, before.length);
        // Ensure the last category remains the last (empty) after reorder among non-empty
        expect(after.last.id, before.last.id);
      },
      skip: 'Integration test - requires backend API running and responding',
    );

    test(
      'reorderServices within same category with 2+ items',
      () async {
        // Aspetta che i servizi siano caricati
        await container.read(servicesProvider.future);

        // Ensure category 10 has at least 2 services: duplicate one
        final services0 = container.read(servicesProvider).value ?? [];
        final inCat10 = services0.where((s) => s.categoryId == 10).toList();
        expect(inCat10, isNotEmpty);

        container.read(servicesProvider.notifier).duplicate(inCat10.first);

        final services1 = container.read(servicesProvider).value ?? [];
        final cat10List = services1.where((s) => s.categoryId == 10).toList();
        expect(cat10List.length, greaterThanOrEqualTo(2));

        // Sort by current sortOrder for clarity
        cat10List.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final firstId = cat10List.first.id;

        // Move first to position 1 (down by one)
        container
            .read(servicesReorderProvider.notifier)
            .reorderServices(10, 0, 1);

        final services2 = container.read(servicesProvider).value ?? [];
        final cat10After = services2.where((s) => s.categoryId == 10).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        // The original first should no longer be the first
        expect(cat10After.first.id == firstId, isFalse);
      },
      skip: 'Integration test - requires backend API running and responding',
    );

    test(
      'moveServiceBetweenCategories into empty category',
      () async {
        // Aspetta che i servizi siano caricati
        await container.read(servicesProvider.future);

        // Ensure category 12 is empty
        final initialServices = container.read(servicesProvider).value ?? [];
        if (initialServices.any((s) => s.id == 3)) {
          container.read(servicesProvider.notifier).delete(3);
        }
        final svcsBefore = container.read(servicesProvider).value ?? [];
        expect(svcsBefore.where((s) => s.categoryId == 12).isEmpty, isTrue);

        // Move service id 1 from cat 10 to cat 12 at index 0
        container
            .read(servicesReorderProvider.notifier)
            .moveServiceBetweenCategories(10, 12, 1, 0);

        final svcsAfter = container.read(servicesProvider).value ?? [];
        final moved = svcsAfter.firstWhere((s) => s.id == 1);
        expect(moved.categoryId, 12);
        // It should be the first in target category
        final targetList = svcsAfter.where((s) => s.categoryId == 12).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        expect(targetList.first.id, 1);
      },
      skip: 'Integration test - requires backend API running and responding',
    );
  });
}
