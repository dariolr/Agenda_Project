import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import '../../providers/services_sorted_providers.dart';
import 'category_item.dart';

/// Lista dei pannelli categoria aggiornata per la vista normale.
class CategoriesList extends ConsumerWidget {
  final List<ServiceCategory> categories;
  final bool isWide;
  final ColorScheme colorScheme;
  final ValueNotifier<int?> hoveredService;
  final ValueNotifier<int?> selectedService;
  final ValueChanged<ServiceCategory> onAddService;
  final ValueChanged<ServiceCategory> onEditCategory;
  final ValueChanged<int> onDeleteCategory;
  final VoidCallback onDeleteCategoryBlocked;
  final ValueChanged<Service> onServiceOpen;
  final ValueChanged<Service> onServiceEdit;
  final ValueChanged<Service> onServiceDuplicate;
  final ValueChanged<int> onServiceDelete;
  final ScrollController scrollController;

  const CategoriesList({
    super.key,
    required this.categories,
    required this.isWide,
    required this.colorScheme,
    required this.hoveredService,
    required this.selectedService,
    required this.onAddService,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onDeleteCategoryBlocked,
    required this.onServiceOpen,
    required this.onServiceEdit,
    required this.onServiceDuplicate,
    required this.onServiceDelete,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final services = ref.watch(
          sortedServicesByCategoryProvider(category.id),
        );
        final hasPrev = index > 0;
        final prevIsNonEmpty = hasPrev
            ? ref
                  .watch(
                    sortedServicesByCategoryProvider(categories[index - 1].id),
                  )
                  .isNotEmpty
            : false;
        final isFirstEmptyAfterNonEmpty =
            services.isEmpty && (!hasPrev || prevIsNonEmpty);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(
              'cat-${category.id}-${services.isEmpty ? 'empty' : 'full'}',
            ),
            child: CategoryItem(
              category: category,
              services: services,
              isWide: isWide,
              colorScheme: colorScheme,
              hoveredService: hoveredService,
              selectedService: selectedService,
              onAddService: () => onAddService(category),
              onEditCategory: () => onEditCategory(category),
              onDeleteCategory: () => onDeleteCategory(category.id),
              onDeleteBlocked: onDeleteCategoryBlocked,
              onServiceOpen: onServiceOpen,
              onServiceEdit: onServiceEdit,
              onServiceDuplicate: onServiceDuplicate,
              onServiceDelete: onServiceDelete,
              addTopSpacing: isFirstEmptyAfterNonEmpty,
            ),
          ),
        );
      },
    );
  }
}
