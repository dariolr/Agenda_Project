
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/class_type.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/models/service_package.dart';
import '../../domain/appointment_type_filter_option.dart';
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
  final ValueChanged<ServiceCategory> onAddPackage;
  final ValueChanged<ServiceCategory> onAddClassType;
  final ValueChanged<ServiceCategory> onEditCategory;
  final ValueChanged<ServiceCategory> onCopyCategoryDirectLink;
  final ValueChanged<int> onDeleteCategory;
  final VoidCallback onDeleteCategoryBlocked;
  final ValueChanged<Service> onServiceOpen;
  final ValueChanged<Service> onServiceEdit;
  final ValueChanged<Service> onServiceDuplicate;
  final ValueChanged<Service> onServiceCopyDirectLink;
  final ValueChanged<int> onServiceDelete;
  final ValueChanged<ServicePackage> onPackageOpen;
  final ValueChanged<ServicePackage> onPackageEdit;
  final ValueChanged<ServicePackage> onPackageCopyDirectLink;
  final ValueChanged<int> onPackageDelete;
  final ValueChanged<ClassType> onClassTypeOpen;
  final ValueChanged<ClassType> onClassTypeEdit;
  final ValueChanged<ClassType> onClassTypeDuplicate;
  final ValueChanged<int> onClassTypeDelete;
  final ValueChanged<ClassType> onClassTypeSchedule;
  final ScrollController scrollController;
  final bool readOnly;
  final bool showClassTypeAddOption;
  final AppointmentTypeFilterOption filterOption;
  final String emptyFilterStateMessage;

  const CategoriesList({
    super.key,
    required this.categories,
    required this.isWide,
    required this.colorScheme,
    required this.hoveredService,
    required this.selectedService,
    required this.onAddService,
    required this.onAddPackage,
    required this.onAddClassType,
    required this.onEditCategory,
    required this.onCopyCategoryDirectLink,
    required this.onDeleteCategory,
    required this.onDeleteCategoryBlocked,
    required this.onServiceOpen,
    required this.onServiceEdit,
    required this.onServiceDuplicate,
    required this.onServiceCopyDirectLink,
    required this.onServiceDelete,
    required this.onPackageOpen,
    required this.onPackageEdit,
    required this.onPackageCopyDirectLink,
    required this.onPackageDelete,
    required this.onClassTypeOpen,
    required this.onClassTypeEdit,
    required this.onClassTypeDuplicate,
    required this.onClassTypeDelete,
    required this.onClassTypeSchedule,
    required this.scrollController,
    required this.emptyFilterStateMessage,
    this.readOnly = false,
    this.showClassTypeAddOption = true,
    this.filterOption = AppointmentTypeFilterOption.all,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool includeEntry(ServiceCategoryEntry entry) {
      switch (filterOption) {
        case AppointmentTypeFilterOption.all:
          return true;
        case AppointmentTypeFilterOption.services:
          return entry.isService;
        case AppointmentTypeFilterOption.packages:
          return entry.isPackage;
        case AppointmentTypeFilterOption.servicesAndPackages:
          return entry.isService || entry.isPackage;
        case AppointmentTypeFilterOption.classes:
          return entry.isClassType;
      }
    }

    // Pre-fetch all entries to compute the collapsible threshold.
    final entriesPerCategory = {
      for (final cat in categories)
        cat.id: ref
            .watch(sortedCategoryEntriesProvider(cat.id))
            .where(includeEntry)
            .toList(),
    };
    final visibleCategories = filterOption == AppointmentTypeFilterOption.all
        ? categories
        : categories
              .where((category) => entriesPerCategory[category.id]!.isNotEmpty)
              .toList();
    if (visibleCategories.isEmpty) {
      return Center(
        child: Text(
          emptyFilterStateMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final totalEntries = entriesPerCategory.values.fold<int>(
      0,
      (sum, e) => sum + e.length,
    );
    final isCollapsible = totalEntries > 30 && categories.length >= 3;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: visibleCategories.length,
      itemBuilder: (context, index) {
        final category = visibleCategories[index];
        final entries = entriesPerCategory[category.id]!;
        final hasPrev = index > 0;
        final prevIsNonEmpty = hasPrev
            ? entriesPerCategory[visibleCategories[index - 1].id]!.isNotEmpty
            : false;
        final isFirstEmptyAfterNonEmpty =
            entries.isEmpty && (!hasPrev || prevIsNonEmpty);

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
              'cat-${category.id}-${entries.isEmpty ? 'empty' : 'full'}',
            ),
            child: CategoryItem(
              category: category,
              entries: entries,
              isWide: isWide,
              colorScheme: colorScheme,
              hoveredService: hoveredService,
              selectedService: selectedService,
              onAddService: () => onAddService(category),
              onAddPackage: () => onAddPackage(category),
              onAddClassType: () => onAddClassType(category),
              onEditCategory: () => onEditCategory(category),
              onCopyDirectLink: () => onCopyCategoryDirectLink(category),
              onDeleteCategory: () => onDeleteCategory(category.id),
              onDeleteBlocked: onDeleteCategoryBlocked,
              onServiceOpen: onServiceOpen,
              onServiceEdit: onServiceEdit,
              onServiceDuplicate: onServiceDuplicate,
              onServiceCopyDirectLink: onServiceCopyDirectLink,
              onServiceDelete: onServiceDelete,
              onPackageOpen: onPackageOpen,
              onPackageEdit: onPackageEdit,
              onPackageCopyDirectLink: onPackageCopyDirectLink,
              onPackageDelete: onPackageDelete,
              onClassTypeOpen: onClassTypeOpen,
              onClassTypeEdit: onClassTypeEdit,
              onClassTypeDuplicate: onClassTypeDuplicate,
              onClassTypeDelete: onClassTypeDelete,
              onClassTypeSchedule: onClassTypeSchedule,
              addTopSpacing: isFirstEmptyAfterNonEmpty,
              readOnly: readOnly,
              isCollapsible: isCollapsible,
              showClassTypeAddOption: showClassTypeAddOption,
            ),
          ),
        );
      },
    );
  }
}

