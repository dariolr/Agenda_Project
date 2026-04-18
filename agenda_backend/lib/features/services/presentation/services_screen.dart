import 'dart:async';

import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/class_type.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/service_package.dart';
import '../../../core/models/service_variant.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/price_utils.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/location_providers.dart';
import '../../agenda/providers/resource_providers.dart';
import '../../class_events/presentation/class_events_screen.dart';
import '../../class_events/providers/class_events_providers.dart';
import '../providers/service_categories_provider.dart';
import '../providers/service_packages_provider.dart';
import '../providers/services_provider.dart';
import '../providers/services_reorder_provider.dart';
import '../providers/services_sorted_providers.dart';
// utils e validators spostati nei dialog
import 'dialogs/category_dialog.dart';
import 'dialogs/service_dialog.dart';
import 'dialogs/service_package_dialog.dart';
import 'widgets/categories_list.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  static final ValueNotifier<int?> _hoveredService = ValueNotifier<int?>(null);
  static final ValueNotifier<int?> _selectedService = ValueNotifier<int?>(null);

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  AppointmentTypeFilterOption _appointmentTypeFilter =
      AppointmentTypeFilterOption.all;

  // NOTE: Non serve initState con refresh() perché:
  // 1. I provider AsyncNotifier caricano i dati automaticamente nel build()
  // 2. Il refresh al cambio tab avviene in _refreshProvidersForTab()

  // ---------- Auto-scroll mentre si trascina ----------
  void _startAutoScroll(Offset pointerInGlobal) {
    const threshold = 100.0; // distanza dal bordo
    const speed = 14.0; // px per tick ~60fps

    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scrollController.hasClients) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final local = renderBox.globalToLocal(pointerInGlobal);
      final dy = local.dy;

      final pos = _scrollController.offset;
      final max = _scrollController.position.maxScrollExtent;
      final viewH = _scrollController.position.viewportDimension;

      if (dy < threshold && pos > 0) {
        _scrollController.jumpTo((pos - speed).clamp(0, max));
      } else if (dy > viewH - threshold && pos < max) {
        _scrollController.jumpTo((pos + speed).clamp(0, max));
      }
    });
  }

  void _stopAutoScroll() => _autoScrollTimer?.cancel();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManageServices = ref.watch(currentUserCanManageServicesProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final allCategories = ref.watch(sortedCategoriesProvider);
    final packages =
        ref.watch(servicePackagesProvider).value ?? const <ServicePackage>[];
    final services = servicesAsync.value ?? const <Service>[];
    final classTypes =
        ref.watch(classTypesProvider).value ?? const <ClassType>[];
    final location = ref.watch(currentLocationProvider);
    final serviceById = {for (final s in services) s.id: s};
    final hasServiceOrPackageEntries =
        services.any((s) => s.categoryId > 0) ||
        packages.any((package) {
          var categoryId = package.categoryId;
          if (categoryId == 0 && package.items.isNotEmpty) {
            categoryId =
                serviceById[package.items.first.serviceId]?.categoryId ?? 0;
          }
          return categoryId > 0;
        });
    final hasServicesForLocation = services.any((s) => s.categoryId > 0);
    final hasPackagesForLocation = packages.any((package) {
      var categoryId = package.categoryId;
      if (categoryId == 0 && package.items.isNotEmpty) {
        categoryId =
            serviceById[package.items.first.serviceId]?.categoryId ?? 0;
      }
      return categoryId > 0;
    });
    final hasClassesForLocation = classTypes.any((classType) {
      final hasCategory = (classType.serviceCategoryId ?? 0) > 0;
      final isEnabledForLocation =
          classType.locationIds.isEmpty ||
          classType.locationIds.contains(location.id);
      return classType.isActive && hasCategory && isEnabledForLocation;
    });
    final availableFilterOptions = _resolveAvailableFilterOptions(
      hasServices: hasServicesForLocation,
      hasPackages: hasPackagesForLocation,
      hasClasses: hasClassesForLocation,
    );
    final shouldShowTypeFilter = _shouldShowTypeFilter(
      availableFilterOptions: availableFilterOptions,
    );
    final effectiveFilterOption =
        availableFilterOptions.contains(_appointmentTypeFilter)
        ? _appointmentTypeFilter
        : AppointmentTypeFilterOption.all;
    // Pre-carica le risorse solo per ruoli che possono modificare servizi.
    if (canManageServices) {
      ref.watch(resourcesProvider);
    }

    final localNonEmptyCategoryIds = <int>{
      for (final s in services)
        if (s.categoryId > 0) s.categoryId,
      for (final ct in classTypes)
        if ((ct.serviceCategoryId ?? 0) > 0) ct.serviceCategoryId!,
    };
    for (final package in packages) {
      var categoryId = package.categoryId;
      if (categoryId == 0 && package.items.isNotEmpty) {
        categoryId =
            serviceById[package.items.first.serviceId]?.categoryId ?? 0;
      }
      if (categoryId > 0) {
        localNonEmptyCategoryIds.add(categoryId);
      }
    }

    var categoriesWithServicesElsewhere = <int>{};
    final locations = ref.watch(locationsProvider);
    if (locations.length > 1) {
      final allLocationIds = locations.map((location) => location.id).toSet();
      final locationIdsKey = locationIdsToKey(allLocationIds);
      final allLocationsServicesAsync = ref.watch(
        servicesForLocationsProvider(locationIdsKey),
      );
      final allLocationsPackagesAsync = ref.watch(
        servicePackagesForLocationsProvider(locationIdsKey),
      );
      final allCategoriesWithServices = <int>{
        for (final s
            in allLocationsServicesAsync.value?.services ?? const <Service>[])
          if (s.categoryId > 0) s.categoryId,
      };
      final allServicesById = <int, Service>{
        for (final s
            in allLocationsServicesAsync.value?.services ?? const <Service>[])
          s.id: s,
      };
      final allCategoriesWithPackages = <int>{};
      for (final package
          in allLocationsPackagesAsync.value ?? const <ServicePackage>[]) {
        var categoryId = package.categoryId;
        if (categoryId == 0 && package.items.isNotEmpty) {
          categoryId =
              allServicesById[package.items.first.serviceId]?.categoryId ?? 0;
        }
        if (categoryId > 0) {
          allCategoriesWithPackages.add(categoryId);
        }
      }
      final allCategoriesWithEntries = <int>{
        ...allCategoriesWithServices,
        ...allCategoriesWithPackages,
      };
      categoriesWithServicesElsewhere = allCategoriesWithEntries.difference(
        localNonEmptyCategoryIds,
      );
    }

    final categories = allCategories.where((category) {
      if (localNonEmptyCategoryIds.contains(category.id)) {
        return true;
      }
      return !categoriesWithServicesElsewhere.contains(category.id);
    }).toList();
    final canReorderClassTypes =
        classTypes.isNotEmpty &&
        (classTypes.length > 1 || categories.length > 1);
    final hasOnlyClassTypesForReorder =
        canReorderClassTypes && !hasServiceOrPackageEntries;

    final colorScheme = Theme.of(context).colorScheme;
    final isWide = ref.watch(formFactorProvider) != AppFormFactor.mobile;
    var reorderMode = ref.watch(servicesReorderModeProvider);
    final canReorderCategories = categories.length >= 2;
    final canReorderServicesAndPackages = hasServiceOrPackageEntries;
    final canReorderClasses = canReorderClassTypes;
    if (reorderMode == ServicesReorderMode.categories &&
        !canReorderCategories) {
      reorderMode = ServicesReorderMode.none;
    } else if (reorderMode == ServicesReorderMode.servicesAndPackages &&
        !canReorderServicesAndPackages) {
      reorderMode = hasOnlyClassTypesForReorder
          ? ServicesReorderMode.classTypes
          : ServicesReorderMode.none;
    } else if (reorderMode == ServicesReorderMode.classTypes &&
        !canReorderClasses) {
      reorderMode = ServicesReorderMode.none;
    }

    return Column(
      children: [
        Expanded(
          child: _buildServicesTab(
            context,
            ref,
            servicesAsync: servicesAsync,
            categories: categories,
            reorderMode: reorderMode,
            isWide: isWide,
            colorScheme: colorScheme,
            shouldShowTypeFilter: shouldShowTypeFilter,
            availableFilterOptions: availableFilterOptions,
            filterOption: effectiveFilterOption,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesTab(
    BuildContext context,
    WidgetRef ref, {
    required AsyncValue<List<Service>> servicesAsync,
    required List<ServiceCategory> categories,
    required ServicesReorderMode reorderMode,
    required bool isWide,
    required ColorScheme colorScheme,
    required bool shouldShowTypeFilter,
    required List<AppointmentTypeFilterOption> availableFilterOptions,
    required AppointmentTypeFilterOption filterOption,
  }) {
    if (servicesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (servicesAsync.hasError) {
      return Center(
        child: Text(
          context.l10n.errorTitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noServicesFound,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectedService.value = null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reorderMode == ServicesReorderMode.none &&
              shouldShowTypeFilter) ...[
            _buildAppointmentTypeFilter(
              context,
              availableFilterOptions: availableFilterOptions,
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: reorderMode == ServicesReorderMode.categories
                ? _buildReorderCategories(context, ref, categories)
                : reorderMode == ServicesReorderMode.servicesAndPackages
                ? _buildReorderServices(context, ref, categories)
                : reorderMode == ServicesReorderMode.classTypes
                ? _buildReorderClassTypes(context, ref, categories)
                : _buildNormalList(
                    context,
                    ref,
                    categories,
                    isWide,
                    colorScheme,
                    filterOption,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentTypeFilter(
    BuildContext context, {
    required List<AppointmentTypeFilterOption> availableFilterOptions,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String labelForOption(AppointmentTypeFilterOption option) {
      switch (option) {
        case AppointmentTypeFilterOption.all:
          return context.l10n.filterAll;
        case AppointmentTypeFilterOption.services:
          return context.l10n.servicesTabLabel;
        case AppointmentTypeFilterOption.packages:
          return context.l10n.servicePackagesTabLabel;
        case AppointmentTypeFilterOption.servicesAndPackages:
          return context.l10n.servicesTypeFilterServicesAndPackages;
        case AppointmentTypeFilterOption.classes:
          return context.l10n.servicesTypeFilterClasses;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableFilterOptions
              .map(
                (option) => _buildFilterChip(
                  context: context,
                  label: labelForOption(option),
                  option: option,
                  colorScheme: colorScheme,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  List<AppointmentTypeFilterOption> _resolveAvailableFilterOptions({
    required bool hasServices,
    required bool hasPackages,
    required bool hasClasses,
  }) {
    final options = <AppointmentTypeFilterOption>[
      AppointmentTypeFilterOption.all,
    ];
    if (hasServices) options.add(AppointmentTypeFilterOption.services);
    if (hasPackages) options.add(AppointmentTypeFilterOption.packages);
    if (hasServices && hasPackages) {
      options.add(AppointmentTypeFilterOption.servicesAndPackages);
    }
    if (hasClasses) options.add(AppointmentTypeFilterOption.classes);
    return options;
  }

  bool _shouldShowTypeFilter({
    required List<AppointmentTypeFilterOption> availableFilterOptions,
  }) {
    final concreteTypesCount = availableFilterOptions
        .where((option) => option != AppointmentTypeFilterOption.all)
        .length;
    return concreteTypesCount > 1;
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required AppointmentTypeFilterOption option,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _appointmentTypeFilter == option;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colorScheme.primary.withOpacity(0.16),
      checkmarkColor: colorScheme.primary,
      side: BorderSide(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.4)
            : colorScheme.outlineVariant,
      ),
      onSelected: (_) {
        if (_appointmentTypeFilter == option) return;
        setState(() => _appointmentTypeFilter = option);
      },
    );
  }

  // ============================
  //  RIORDINO CLASSI (solo classi, cross-categoria)
  // ============================
  Widget _buildReorderClassTypes(
    BuildContext context,
    WidgetRef ref,
    List<ServiceCategory> cats,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final entriesByCategory = <int, List<ClassType>>{};
    final allClassTypes = <ClassType>[];
    for (final c in cats) {
      final list = ref.watch(classTypesByCategoryProvider(c.id));
      entriesByCategory[c.id] = list;
      allClassTypes.addAll(list);
    }

    if (allClassTypes.isEmpty) {
      return Center(
        child: Text(
          context.l10n.classTypesEmpty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final rows =
        <({bool isHeader, ClassType? classType, ServiceCategory? c})>[];
    for (final c in cats) {
      final list = entriesByCategory[c.id] ?? const <ClassType>[];
      if (list.isEmpty) continue;
      rows.add((isHeader: true, classType: null, c: c));
      for (final entry in list) {
        rows.add((isHeader: false, classType: entry, c: null));
      }
    }

    int entryFlatIndexFromRowsIndex(int rowsIndex, int oldIndex) {
      var count = 0;
      for (var i = 0; i < rowsIndex; i++) {
        if (i == oldIndex) continue;
        if (!rows[i].isHeader) count++;
      }
      return count;
    }

    (int catId, int indexInCat) targetForFlatIndex(
      int flatIndex, {
      required List<ClassType> entries,
      required int fallbackCategoryId,
    }) {
      if (entries.isEmpty) return (fallbackCategoryId, 0);
      final idx = flatIndex.clamp(0, entries.length);
      if (idx == entries.length) {
        final last = entries.last;
        final lastCatId = last.serviceCategoryId ?? fallbackCategoryId;
        final inCat = entriesByCategory[lastCatId] ?? const <ClassType>[];
        return (lastCatId, inCat.length);
      }

      final pivot = entries[idx];
      final pivotCatId = pivot.serviceCategoryId ?? fallbackCategoryId;
      var countBeforeInPivotCat = 0;
      for (var i = 0; i < idx; i++) {
        final entry = entries[i];
        if ((entry.serviceCategoryId ?? 0) == pivotCatId) {
          countBeforeInPivotCat++;
        }
      }

      return (pivotCatId, countBeforeInPivotCat);
    }

    return Listener(
      onPointerMove: (e) => _startAutoScroll(e.position),
      onPointerUp: (_) => _stopAutoScroll(),
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) => child,
        itemCount: rows.length,
        onReorder: (oldIndex, newIndex) {
          final entryOld = rows[oldIndex].classType;
          if (entryOld == null) return;
          final oldCatId = entryOld.serviceCategoryId ?? 0;
          if (oldCatId <= 0) return;

          final entriesWithoutMoving = [
            for (final entry in allClassTypes)
              if (entry.id != entryOld.id) entry,
          ];

          final dropOnHeader =
              newIndex < rows.length && rows[newIndex].isHeader;
          var fallbackCategoryId = oldCatId;
          final fallbackStartIndex = dropOnHeader
              ? newIndex - 1
              : (newIndex >= rows.length ? rows.length - 1 : newIndex);
          for (var i = fallbackStartIndex; i >= 0; i--) {
            final row = rows[i];
            if (row.isHeader && row.c != null) {
              fallbackCategoryId = row.c!.id;
              break;
            }
          }

          final targetFlatIndex = entryFlatIndexFromRowsIndex(
            newIndex,
            oldIndex,
          );
          final (targetCatId, indexInTargetCat) = dropOnHeader
              ? (
                  fallbackCategoryId,
                  (entriesByCategory[fallbackCategoryId] ?? const <ClassType>[])
                      .where((e) => e.id != entryOld.id)
                      .length,
                )
              : targetForFlatIndex(
                  targetFlatIndex,
                  entries: entriesWithoutMoving,
                  fallbackCategoryId: fallbackCategoryId,
                );

          final oldItems = [
            ...(entriesByCategory[oldCatId] ?? const <ClassType>[]),
          ];
          final newItems = targetCatId == oldCatId
              ? oldItems
              : [...(entriesByCategory[targetCatId] ?? const <ClassType>[])];

          final oldIndexInCat = oldItems.indexWhere((e) => e.id == entryOld.id);
          if (oldIndexInCat < 0) return;
          final movingItem = oldItems.removeAt(oldIndexInCat);
          final targetIndex = indexInTargetCat.clamp(0, newItems.length);
          if (targetCatId == oldCatId) {
            oldItems.insert(targetIndex, movingItem);
            unawaited(
              _persistClassTypesOrder(context, ref, {oldCatId: oldItems}),
            );
          } else {
            newItems.insert(targetIndex, movingItem);
            unawaited(
              _persistClassTypesOrder(context, ref, {
                oldCatId: oldItems,
                targetCatId: newItems,
              }),
            );
          }
        },
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row.isHeader) {
            final category = row.c!;
            return Container(
              key: ValueKey('class-header-${category.id}'),
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16, bottom: 6),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            );
          }

          final ct = row.classType!;
          return Container(
            key: ValueKey('class-reorder-${ct.id}'),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.7),
              ),
            ),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator),
              ),
              title: Text(ct.name),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _persistClassTypesOrder(
    BuildContext context,
    WidgetRef ref,
    Map<int, List<ClassType>> updatedByCategory,
  ) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId <= 0) return;

    final repo = ref.read(classEventsRepositoryProvider);
    try {
      for (final entry in updatedByCategory.entries) {
        final categoryId = entry.key;
        final items = entry.value;
        for (var i = 0; i < items.length; i++) {
          final classType = items[i];
          await repo.updateClassType(
            businessId: businessId,
            classTypeId: classType.id,
            payload: {'service_category_id': categoryId, 'sort_order': i},
          );
        }
      }
      ref.invalidate(classTypesProvider);
      ref.invalidate(classTypesWithInactiveProvider);
    } catch (_) {
      if (!context.mounted) return;
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: context.l10n.classTypesMutationErrorMessage,
      );
    }
  }

  // ============================
  //  RIORDINO CATEGORIE (solo categorie, servizi nascosti)
  // ============================
  Widget _buildReorderCategories(
    BuildContext context,
    WidgetRef ref,
    List<ServiceCategory> cats,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Partiziona categorie piene e vuote
    final services = ref.watch(servicesProvider).value ?? [];
    final packagesByCategory = <int, int>{
      for (final c in cats)
        c.id: ref.watch(servicePackagesByCategoryProvider(c.id)).length,
    };
    final isNonEmpty = <int, bool>{
      for (final c in cats) c.id: services.any((s) => s.categoryId == c.id),
    };
    for (final entry in packagesByCategory.entries) {
      if (entry.value > 0) {
        isNonEmpty[entry.key] = true;
      }
    }
    final fullCats = [
      for (final c in cats)
        if (isNonEmpty[c.id]!) c,
    ];
    final emptyCats = [
      for (final c in cats)
        if (!isNonEmpty[c.id]!) c,
    ];

    // Costruisci righe: piene, separatore, vuote (disabilitate)
    final rows = <({String type, ServiceCategory? cat})>[];
    for (final c in fullCats) {
      rows.add((type: 'full', cat: c));
    }
    if (emptyCats.isNotEmpty) {
      rows.add((type: 'separator', cat: null));
      for (final c in emptyCats) {
        rows.add((type: 'empty', cat: c));
      }
    }

    int fullIndexFromRow(int rowIndex) {
      int count = 0;
      for (int i = 0; i < rowIndex; i++) {
        if (rows[i].type == 'full') count++;
      }
      return count;
    }

    return Listener(
      onPointerMove: (e) => _startAutoScroll(e.position),
      onPointerUp: (_) => _stopAutoScroll(),
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        buildDefaultDragHandles: false,
        // Evita l'effetto elevazione/ombra sull'item in drag:
        proxyDecorator: (child, index, animation) => child,
        itemCount: rows.length,
        onReorder: (oldIndex, newIndex) {
          final movingDown = newIndex > oldIndex;
          if (movingDown) newIndex -= 1;

          // Calcola gli indici nella sola lista delle piene
          final oldFullIndex = fullIndexFromRow(oldIndex);
          final newFullIndex = fullIndexFromRow(newIndex);

          ref
              .read(servicesReorderProvider.notifier)
              .reorderNonEmptyCategories(oldFullIndex, newFullIndex);
        },
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row.type == 'separator') {
            return Container(
              key: const ValueKey('sep'),
              padding: const EdgeInsets.only(top: 64, bottom: 24),
              child: Text(
                context.l10n.emptyCategoriesNotReorderableNote,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final category = row.cat!;
          final isEmpty = row.type == 'empty';
          return Opacity(
            key: ValueKey('cat-${category.id}'),
            opacity: isEmpty ? 0.6 : 1.0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: ListTile(
                leading: isEmpty
                    ? Icon(
                        Icons.drag_indicator,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                      )
                    : ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_indicator),
                      ),
                title: Text(category.name),
                enabled: !isEmpty,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================
  //  RIORDINO SERVIZI (CROSS-CATEGORIA)
  // ============================
  Widget _buildReorderServices(
    BuildContext context,
    WidgetRef ref,
    List<ServiceCategory> cats,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final reorder = ref.read(servicesReorderProvider.notifier);

    // Flatten di servizi e pacchetti (solo delle categorie visualizzate)
    final allEntries = <ServiceCategoryEntry>[];
    final entriesByCategory = <int, List<ServiceCategoryEntry>>{};
    for (final c in cats) {
      final list = ref.watch(sortedCategoryEntriesProvider(c.id));
      entriesByCategory[c.id] = list;
      allEntries.addAll(list);
    }

    // Costruisce la lista visuale con header categoria "fissi" e righe elementi.
    // Gli header non hanno drag handle e non sono riordinabili; i servizi/pacchetti sì.
    final rows =
        <({bool isHeader, ServiceCategoryEntry? entry, ServiceCategory? c})>[];
    for (final c in cats) {
      final list = entriesByCategory[c.id] ?? const <ServiceCategoryEntry>[];
      // Sempre mostrare header, anche se vuota
      rows.add((isHeader: true, entry: null, c: c));
      for (final entry in list) {
        rows.add((isHeader: false, entry: entry, c: null));
      }
    }

    int entryFlatIndexFromRowsIndex(int rowsIndex, int oldIndex) {
      int count = 0;
      for (int i = 0; i < rowsIndex; i++) {
        if (i == oldIndex) continue;
        if (!rows[i].isHeader) count++;
      }
      return count;
    }

    // Funzione di supporto: data la posizione "globale" nella lista piatta,
    // ritorna la coppia (categoryId, indexNellaCategoria) dove verrebbe inserito
    (int catId, int indexInCat) targetForFlatIndex(
      int flatIndex, {
      required List<ServiceCategoryEntry> entries,
      required int fallbackCategoryId,
    }) {
      // Clamp e fallback
      if (entries.isEmpty) return (fallbackCategoryId, 0);
      final idx = flatIndex.clamp(0, entries.length);

      // Inserimento in coda assoluta
      if (idx == entries.length) {
        final last = entries.last;
        final inCat = entriesByCategory[last.categoryId] ?? [];
        return (last.categoryId, inCat.length);
      }

      // Pivot alla posizione globale idx
      final pivot = entries[idx];
      final pivotCatId = pivot.categoryId;

      // Quanti elementi di quella categoria compaiono prima dell'indice globale
      int countBeforeInPivotCat = 0;
      for (int i = 0; i < idx; i++) {
        final entry = entries[i];
        if (entry.categoryId == pivotCatId) {
          countBeforeInPivotCat++;
        }
      }

      return (pivotCatId, countBeforeInPivotCat);
    }

    return Listener(
      onPointerMove: (e) => _startAutoScroll(e.position),
      onPointerUp: (_) => _stopAutoScroll(),
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        buildDefaultDragHandles: false,
        // Coerenza visiva: nessuna elevazione/ombra anche durante il drag servizi
        proxyDecorator: (child, index, animation) => child,
        itemCount: rows.length,
        onReorder: (oldIndex, newIndex) {
          // Usa newIndex raw: il mapping a flat index esclude gia' l'elemento trascinato.

          final entryOld = rows[oldIndex].entry;
          if (entryOld == null) return;
          final oldCatId = entryOld.categoryId;
          final entriesWithoutMoving = [
            for (final entry in allEntries)
              if (entry.key != entryOld.key) entry,
          ];

          final bool dropOnHeader =
              newIndex < rows.length && rows[newIndex].isHeader;
          int fallbackCategoryId = oldCatId;
          final fallbackStartIndex = dropOnHeader
              ? newIndex - 1
              : (newIndex >= rows.length ? rows.length - 1 : newIndex);
          for (int i = fallbackStartIndex; i >= 0; i--) {
            final row = rows[i];
            if (row.isHeader) {
              fallbackCategoryId = row.c!.id;
              break;
            }
          }

          // Traduci newIndex della lista visuale in indice sulla lista elementi (saltando header)
          final targetFlatIndex = entryFlatIndexFromRowsIndex(
            newIndex,
            oldIndex,
          );

          // Se si rilascia su un header, inserisci in coda alla categoria precedente
          final (targetCatId, indexInTargetCat) = dropOnHeader
              ? (
                  fallbackCategoryId,
                  (entriesByCategory[fallbackCategoryId] ?? [])
                      .where((e) => e.key != entryOld.key)
                      .length,
                )
              : targetForFlatIndex(
                  targetFlatIndex,
                  entries: entriesWithoutMoving,
                  fallbackCategoryId: fallbackCategoryId,
                );

          if (targetCatId == oldCatId) {
            // stesso gruppo -> semplice riordino interno
            final updated = [
              ...(entriesByCategory[oldCatId] ??
                  const <ServiceCategoryEntry>[]),
            ];
            final oldIndexInCat = updated.indexWhere(
              (e) => e.key == entryOld.key,
            );
            if (oldIndexInCat < 0) return;
            final item = updated.removeAt(oldIndexInCat);
            final targetIndex = indexInTargetCat.clamp(0, updated.length);
            updated.insert(targetIndex, item);
            reorder.reorderCategoryItems(categoryId: oldCatId, items: updated);
          } else {
            // Cross-categoria -> sposta
            final oldItems = [
              ...(entriesByCategory[oldCatId] ??
                  const <ServiceCategoryEntry>[]),
            ];
            final newItems = [
              ...(entriesByCategory[targetCatId] ??
                  const <ServiceCategoryEntry>[]),
            ];
            final oldIndexInCat = oldItems.indexWhere(
              (e) => e.key == entryOld.key,
            );
            if (oldIndexInCat < 0) return;
            final movingItem = oldItems.removeAt(oldIndexInCat);
            final targetIndex = indexInTargetCat.clamp(0, newItems.length);
            newItems.insert(targetIndex, movingItem);
            reorder.moveCategoryItemBetweenCategories(
              oldCategoryId: oldCatId,
              newCategoryId: targetCatId,
              oldItems: oldItems,
              newItems: newItems,
            );
          }
        },
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row.isHeader) {
            final category = row.c!;
            return Container(
              key: ValueKey('header-${category.id}'),
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16, bottom: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            );
          }

          final entry = row.entry!;

          // ClassType: non riordinabile (nessun sortOrder API), mostrato senza drag handle.
          if (entry.isClassType) {
            final ct = entry.classType!;
            return Container(
              key: ValueKey('classtype-${ct.id}'),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.7),
                ),
              ),
              child: ListTile(
                leading: const SizedBox(width: 24),
                title: Text(ct.name),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            );
          }

          if (entry.isPackage) {
            final package = entry.package!;
            return Container(
              key: ValueKey('pkg-${package.id}'),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.7),
                ),
              ),
              child: ListTile(
                leading: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_indicator),
                ),
                title: Text(package.name),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            );
          }

          final s = entry.service!;
          return Container(
            key: ValueKey('svc-${s.id}'),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.7),
              ),
            ),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator),
              ),
              title: Text(s.name),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================
  //  VISTA NORMALE (pulsanti visibili, no drag)
  // ============================
  Widget _buildNormalList(
    BuildContext context,
    WidgetRef ref,
    List<ServiceCategory> cats,
    bool isWide,
    ColorScheme colorScheme,
    AppointmentTypeFilterOption filterOption,
  ) {
    final canManageServices = ref.watch(currentUserCanManageServicesProvider);
    final isSuperadmin = ref.watch(authProvider).user?.isSuperadmin ?? false;
    final servicesNotifier = ref.read(servicesProvider.notifier);
    if (cats.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noServicesFound,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    Color? mostUsedColorForCategory(ServiceCategory category) {
      final services = (ref.read(servicesProvider).value ?? [])
          .where((s) => s.categoryId == category.id)
          .toList();
      if (services.isEmpty) return null;
      final variants = ref.read(serviceVariantsProvider).value ?? [];
      final counts = <int, int>{};
      Color? topColor;
      int topCount = 0;
      for (final service in services) {
        ServiceVariant? variant;
        for (final v in variants) {
          if (v.serviceId == service.id) {
            variant = v;
            break;
          }
        }
        final colorHex = variant?.colorHex;
        if (colorHex == null) continue;
        final color = ColorUtils.fromHex(colorHex);
        final key = color.value;
        final nextCount = (counts[key] ?? 0) + 1;
        counts[key] = nextCount;
        if (nextCount > topCount) {
          topCount = nextCount;
          topColor = color;
        }
      }
      return topColor;
    }

    return CategoriesList(
      categories: cats,
      isWide: isWide,
      colorScheme: colorScheme,
      hoveredService: _hoveredService,
      selectedService: _selectedService,
      scrollController: _scrollController,
      onAddService: (category) => _openServiceDialog(
        context,
        ref,
        preselectedCategoryId: category.id,
        preselectedColor: mostUsedColorForCategory(category),
      ),
      onAddPackage: (category) =>
          _openPackageDialog(context, ref, preselectedCategoryId: category.id),
      onEditCategory: (category) =>
          showCategoryDialog(context, ref, category: category),
      onDeleteCategory: (categoryId) =>
          _confirmDeleteCategory(context, ref, categoryId),
      onDeleteCategoryBlocked: () => _showCannotDeleteCategoryDialog(context),
      onServiceOpen: (service) =>
          _openServiceDialog(context, ref, service: service),
      onServiceEdit: (service) =>
          _openServiceDialog(context, ref, service: service),
      onServiceDuplicate: (service) => _openServiceDialog(
        context,
        ref,
        service: service,
        duplicateFrom: true,
      ),
      onServiceDelete: (id) => _confirmDelete(
        context,
        ref,
        onConfirm: () async => servicesNotifier.deleteServiceApi(id),
      ),
      onPackageOpen: (package) =>
          _openPackageDialog(context, ref, package: package),
      onPackageEdit: (package) =>
          _openPackageDialog(context, ref, package: package),
      onPackageDelete: (id) => _confirmDeletePackage(context, ref, id),
      onAddClassType: (category) => _openClassTypeDialog(
        context,
        ref,
        preselectedCategoryId: category.id,
      ),
      onClassTypeOpen: (classType) =>
          _openClassTypeDialog(context, ref, classType: classType),
      onClassTypeEdit: (classType) =>
          _openClassTypeDialog(context, ref, classType: classType),
      onClassTypeDuplicate: (classType) =>
          _duplicateClassType(context, ref, classType),
      onClassTypeDelete: (id) => _confirmDeleteClassType(ref, id),
      onClassTypeSchedule: (classType) =>
          _openClassEventDialog(context, ref, classType: classType),
      readOnly: !canManageServices,
      showClassTypeAddOption: isSuperadmin,
      filterOption: filterOption,
      emptyFilterStateMessage: context.l10n.noServicesFound,
    );
  }

  Future<void> _openClassTypeDialog(
    BuildContext context,
    WidgetRef ref, {
    ClassType? classType,
    int? preselectedCategoryId,
  }) {
    final canManageServices = ref.read(currentUserCanManageServicesProvider);
    if (!canManageServices) return Future.value();
    return showCreateClassTypeDialog(
      context,
      ref,
      initial: classType,
      preselectedCategoryId: preselectedCategoryId,
    );
  }

  Future<void> _openClassEventDialog(
    BuildContext context,
    WidgetRef ref, {
    required ClassType classType,
  }) {
    return showCreateClassEventDialog(
      context,
      ref,
      initialClassTypeId: classType.id,
    );
  }

  Future<void> _duplicateClassType(
    BuildContext context,
    WidgetRef ref,
    ClassType source,
  ) async {
    final l10n = context.l10n;
    final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
    if (!isSuperadmin) {
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: l10n.classTypesCreateSuperadminOnlyMessage,
      );
      return;
    }
    try {
      final allTypes = await ref.read(classTypesProvider.future);
      final existingNames = allTypes
          .map((t) => t.name.trim().toLowerCase())
          .toSet();
      final baseName = '${source.name.trim()} ${l10n.classTypesCloneSuffix}';
      var candidateName = baseName;
      var counter = 2;
      while (existingNames.contains(candidateName.toLowerCase())) {
        candidateName = '$baseName $counter';
        counter++;
      }
      await ref
          .read(classTypeMutationControllerProvider.notifier)
          .create(
            name: candidateName,
            description: source.description,
            colorHex: source.colorHex,
            serviceCategoryId: source.serviceCategoryId,
            locationIds: source.locationIds,
          );
      if (!context.mounted) return;
      FeedbackDialog.showSuccess(
        context,
        title: l10n.classTypesCloneSuccessTitle,
        message: l10n.classTypesCloneSuccessMessage,
      );
    } catch (error) {
      if (!context.mounted) return;
      FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: l10n.classTypesMutationErrorMessage,
      );
    }
  }

  Future<void> _confirmDeleteClassType(WidgetRef ref, int classTypeId) async {
    if (!mounted) return;
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.classTypesDeleteConfirmTitle),
        content: Text(l10n.classTypesDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(classTypeMutationControllerProvider.notifier)
          .deleteType(classTypeId: classTypeId);
    } catch (error) {
      if (!mounted) return;
      await FeedbackDialog.showError(
        context,
        title: l10n.errorTitle,
        message: l10n.classTypesDeleteInUseErrorMessage,
      );
    }
  }

  void _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
  ) {
    final canManageServices = ref.read(currentUserCanManageServicesProvider);
    if (!canManageServices) return;

    showAppConfirmDialog(
      context,
      title: Text(context.l10n.deleteConfirmationTitle),
      confirmLabel: context.l10n.actionDelete,
      cancelLabel: context.l10n.actionCancel,
      danger: true,
      onConfirm: () async {
        final deleted = await ref
            .read(serviceCategoriesProvider.notifier)
            .deleteCategoryApi(categoryId);
        if (!context.mounted || deleted) return;
        FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: context.l10n.cannotDeleteCategoryContent,
        );
      },
    );
  }

  void _showCannotDeleteCategoryDialog(BuildContext context) {
    showAppInfoDialog(
      context,
      title: Text(context.l10n.cannotDeleteTitle),
      content: Text(context.l10n.cannotDeleteCategoryContent),
      closeLabel: context.l10n.actionClose,
    );
  }

  Future<void> _openServiceDialog(
    BuildContext context,
    WidgetRef ref, {
    Service? service,
    int? preselectedCategoryId,
    Color? preselectedColor,
    bool duplicateFrom = false,
  }) {
    final canManageServices = ref.read(currentUserCanManageServicesProvider);
    if (!canManageServices) {
      if (service == null) return Future.value();
      return showServiceDialog(
        context,
        ref,
        service: service,
        readOnly: true,
      ).then((_) => _selectedService.value = null);
    }

    return showServiceDialog(
      context,
      ref,
      service: service,
      preselectedCategoryId: preselectedCategoryId,
      preselectedColor: preselectedColor,
      duplicateFrom: duplicateFrom,
    ).then((_) => _selectedService.value = null);
  }

  Future<void> _openPackageDialog(
    BuildContext context,
    WidgetRef ref, {
    ServicePackage? package,
    int? preselectedCategoryId,
  }) {
    final canManageServices = ref.read(currentUserCanManageServicesProvider);
    if (!canManageServices) {
      if (package != null) {
        _openPackageDetailsDialog(context, ref, package);
      }
      return Future.value();
    }

    final services = ref.read(servicesProvider).value ?? [];
    final categories = ref.read(serviceCategoriesProvider);
    return showServicePackageDialog(
      context,
      ref,
      services: services,
      categories: categories,
      package: package,
      preselectedCategoryId: preselectedCategoryId,
    ).then((_) => _selectedService.value = null);
  }

  void _confirmDeletePackage(
    BuildContext context,
    WidgetRef ref,
    int packageId,
  ) {
    final canManageServices = ref.read(currentUserCanManageServicesProvider);
    if (!canManageServices) return;

    showAppConfirmDialog(
      context,
      title: Text(context.l10n.servicePackageDeleteTitle),
      content: Text(context.l10n.servicePackageDeleteMessage),
      confirmLabel: context.l10n.actionDelete,
      danger: true,
      onConfirm: () async {
        try {
          await ref
              .read(servicePackagesProvider.notifier)
              .deletePackage(packageId);
          if (!context.mounted) return;
          FeedbackDialog.showSuccess(
            context,
            title: context.l10n.servicePackageDeletedTitle,
            message: context.l10n.servicePackageDeletedMessage,
          );
        } catch (_) {
          if (!context.mounted) return;
          FeedbackDialog.showError(
            context,
            title: context.l10n.errorTitle,
            message: context.l10n.servicePackageDeleteError,
          );
        }
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback onConfirm,
  }) {
    final canManageServices = ref.read(currentUserCanManageServicesProvider);
    if (!canManageServices) return;

    showAppConfirmDialog(
      context,
      title: Text(context.l10n.deleteServiceQuestion),
      content: Text(context.l10n.cannotUndoWarning),
      confirmLabel: context.l10n.actionDelete,
      cancelLabel: context.l10n.actionCancel,
      danger: true,
      onConfirm: onConfirm,
    );
  }

  Future<void> _openPackageDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    ServicePackage package,
  ) async {
    final isIt = Localizations.localeOf(context).languageCode == 'it';
    final durationLabelText = isIt ? 'Durata' : 'Duration';
    final priceLabelText = isIt ? 'Prezzo' : 'Price';
    final currencyCode = ref.read(effectiveCurrencyProvider);
    await showAppInfoDialog(
      context,
      title: Text(package.name),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$durationLabelText: ${context.localizedDurationLabel(package.effectiveDurationMinutes)}',
          ),
          const SizedBox(height: 6),
          Text(
            '$priceLabelText: ${PriceFormatter.format(context: context, amount: package.effectivePrice, currencyCode: currencyCode)}',
          ),
          if ((package.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(package.description!.trim()),
          ],
        ],
      ),
      closeLabel: context.l10n.actionClose,
    );
  }
}

// Add menu locale rimosso: ora è gestito dallo ScaffoldWithNavigation
