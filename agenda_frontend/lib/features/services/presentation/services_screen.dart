import 'dart:async';

import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/core/utils/price_utils.dart';
import 'package:agenda_frontend/features/agenda/providers/business_providers.dart';
import 'package:agenda_frontend/features/agenda/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../providers/service_categories_provider.dart';
import '../providers/services_provider.dart';
import '../providers/services_reorder_provider.dart';
import '../providers/services_sorted_providers.dart';

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

  /// Modalità di riordino (mutuamente esclusive)
  bool isReorderCategories = false;
  bool isReorderServices = false;

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
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(sortedCategoriesProvider);

    // In modalità riordino escludiamo le categorie senza servizi
    final categories = (isReorderCategories || isReorderServices)
        ? allCategories
              .where(
                (c) => ref
                    .watch(sortedServicesByCategoryProvider(c.id))
                    .isNotEmpty,
              )
              .toList()
        : allCategories;

    final colorScheme = Theme.of(context).colorScheme;
    final isWide =
        ref.watch(formFactorProvider) == AppFormFactor.tabletOrDesktop;

    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.servicesTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectedService.value = null,
      child: Scaffold(
        floatingActionButton: (isReorderCategories || isReorderServices)
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showCategoryDialog(context, ref),
                icon: const Icon(Icons.add),
                // Per eventuale chiave i18n: createCategoryButtonLabel
                label: Text(context.l10n.createCategoryButtonLabel),
              ),
        body: Column(
          children: [
            // ---------- Toolbar ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        isReorderCategories = !isReorderCategories;
                        if (isReorderCategories) isReorderServices = false;
                      });
                      if (!isReorderCategories) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.orderSavedMessage),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isReorderCategories ? Icons.check : Icons.drag_indicator,
                    ),
                    label: Text(
                      isReorderCategories
                          ? context.l10n.doneCategoriesButton
                          : context.l10n.editCategoriesOrderButton,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        isReorderServices = !isReorderServices;
                        if (isReorderServices) isReorderCategories = false;
                      });
                      if (!isReorderServices) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.orderSavedMessage),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isReorderServices ? Icons.check : Icons.drag_indicator,
                    ),
                    label: Text(
                      isReorderServices
                          ? context.l10n.doneServicesButton
                          : context.l10n.editServicesOrderButton,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // ---------- Corpo ----------
            Expanded(
              child: isReorderCategories
                  ? _buildReorderCategories(context, ref, categories)
                  : isReorderServices
                  ? _buildReorderServices(context, ref, categories)
                  : _buildNormalList(
                      context,
                      ref,
                      categories,
                      isWide,
                      colorScheme,
                    ),
            ),
          ],
        ),
      ),
    );
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

    return Listener(
      onPointerMove: (e) => _startAutoScroll(e.position),
      onPointerUp: (_) => _stopAutoScroll(),
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        buildDefaultDragHandles: false,
        itemCount: cats.length,
        onReorder: (oldIndex, newIndex) {
          ref
              .read(servicesReorderProvider.notifier)
              .reorderCategories(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final category = cats[index];
          return Container(
            key: ValueKey('cat-${category.id}'),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator),
              ),
              title: Text(category.name),
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

    // Flatten di tutti i servizi (solo delle categorie visualizzate)
    final allServices = <Service>[];
    final servicesByCategory = <int, List<Service>>{};
    for (final c in cats) {
      final list = ref.watch(sortedServicesByCategoryProvider(c.id));
      servicesByCategory[c.id] = list;
      allServices.addAll(list);
    }

    // Funzione di supporto: data la posizione "globale" nella lista piatta,
    // ritorna la coppia (categoryId, indexNellaCategoria) dove verrebbe inserito
    (int catId, int indexInCat) targetForFlatIndex(
      int flatIndex, {
      required bool movingDown,
      int? movingServiceId,
    }) {
      // Clamp e fallback
      if (allServices.isEmpty) return (cats.first.id, 0);
      final idx = flatIndex.clamp(0, allServices.length);

      // Inserimento in coda assoluta
      if (idx == allServices.length) {
        final last = allServices.last;
        final inCat = servicesByCategory[last.categoryId] ?? [];
        return (last.categoryId, inCat.length);
      }

      // Pivot alla posizione globale idx
      final pivot = allServices[idx];
      final pivotCatId = pivot.categoryId;

      // Quanti elementi di quella categoria compaiono prima dell'indice globale,
      // escludendo il servizio in movimento (per evitare off-by-one)
      int countBeforeInPivotCat = 0;
      for (int i = 0; i < idx; i++) {
        final s = allServices[i];
        if (s.categoryId == pivotCatId && s.id != movingServiceId) {
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
        itemCount: allServices.length,
        onReorder: (oldIndex, newIndex) {
          // Normalizzazione Flutter Reorderable semantics
          final movingDown = newIndex > oldIndex;
          if (movingDown) newIndex -= 1;

          final sOld = allServices[oldIndex];
          final oldCatId = sOld.categoryId;

          // Calcola destinazione (categoria e indice relativo nella categoria)
          final (targetCatId, indexInTargetCat) = targetForFlatIndex(
            newIndex,
            movingDown: movingDown,
            movingServiceId: sOld.id,
          );

          if (targetCatId == oldCatId) {
            // stesso gruppo -> semplice riordino interno
            reorder.reorderServices(
              oldCatId,
              // index relativo nella categoria di origine
              (servicesByCategory[oldCatId] ?? []).indexWhere(
                (e) => e.id == sOld.id,
              ),
              indexInTargetCat,
            );
          } else {
            // Cross-categoria -> sposta
            reorder.moveServiceBetweenCategories(
              oldCatId,
              targetCatId,
              sOld.id,
              indexInTargetCat,
            );
          }
        },
        itemBuilder: (context, index) {
          final s = allServices[index];
          final catName = cats.firstWhere((c) => c.id == s.categoryId).name;
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
              subtitle: Text(
                catName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
  ) {
    final servicesNotifier = ref.read(servicesProvider.notifier);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      itemCount: cats.length,
      itemBuilder: (context, index) {
        final category = cats[index];
        final services = ref.watch(
          sortedServicesByCategoryProvider(category.id),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header categoria
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Titolo + descrizione
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                              ),
                        ),
                        if (category.description != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              category.description!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onPrimaryContainer
                                        .withOpacity(0.8),
                                  ),
                            ),
                          ),
                      ],
                    ),

                    // Pulsanti azione (solo in vista normale)
                    Row(
                      children: [
                        IconButton(
                          tooltip: context.l10n.addServiceTooltip,
                          icon: Icon(
                            Icons.add,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          onPressed: () => _showServiceDialog(
                            context,
                            ref,
                            preselectedCategoryId: category.id,
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.actionEdit,
                          icon: Icon(
                            Icons.edit_outlined,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          onPressed: () => _showCategoryDialog(
                            context,
                            ref,
                            category: category,
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.actionDelete,
                          icon: const Icon(Icons.delete_outline),
                          color: colorScheme.onPrimaryContainer,
                          onPressed: () {
                            if (services.isNotEmpty) {
                              _showCannotDeleteCategoryDialog(context);
                              return;
                            }
                            _confirmDeleteCategory(context, ref, category.id);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Body: lista servizi
              if (services.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    context.l10n.noServicesInCategory,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                )
              else
                ValueListenableBuilder2<int?, int?>(
                  first: _hoveredService,
                  second: _selectedService,
                  builder: (context, hoveredId, selectedId, _) {
                    return Column(
                      children: [
                        for (int i = 0; i < services.length; i++)
                          _buildServiceTile(
                            context: context,
                            ref: ref,
                            service: services[i],
                            isLast: i == services.length - 1,
                            isHovered: hoveredId == services[i].id,
                            isSelected: selectedId == services[i].id,
                            isWide: isWide,
                            colorScheme: colorScheme,
                            servicesNotifier: servicesNotifier,
                          ),
                        if (services.isNotEmpty)
                          Divider(
                            color: Colors.grey.withOpacity(0.2),
                            height: 1,
                            thickness: 1,
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceTile({
    required BuildContext context,
    required WidgetRef ref,
    required Service service,
    required bool isLast,
    required bool isHovered,
    required bool isSelected,
    required bool isWide,
    required ColorScheme colorScheme,
    required dynamic servicesNotifier,
  }) {
    final baseColor = (service.id % 2 == 1)
        ? colorScheme.onSurface.withOpacity(0.04)
        : Colors.transparent;

    final bgColor = (isHovered || isSelected)
        ? colorScheme.primaryContainer.withOpacity(0.1)
        : baseColor;

    return MouseRegion(
      onEnter: (_) => _hoveredService.value = service.id,
      onExit: (_) => _hoveredService.value = null,
      child: GestureDetector(
        onTap: () {
          _selectedService.value = service.id;
          _showServiceDialog(context, ref, service: service);
        },
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
              bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!service.isBookableOnline)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      context.l10n.notBookableOnline,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: service.description != null
                ? Text(
                    service.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (service.isFree)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      context.l10n.freeLabel,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  Text(
                    PriceFormatter.formatService(
                      context: context,
                      ref: ref,
                      service: service,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                const SizedBox(width: 8),
                if (isWide)
                  _buildActionIcons(context, ref, service, servicesNotifier)
                else
                  _buildPopupMenu(context, ref, service, servicesNotifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================
  //  DIALOGS & HELPERS
  // ============================

  void _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.deleteConfirmationTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(serviceCategoriesProvider.notifier)
                  .deleteCategory(categoryId);
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
  }

  void _showCannotDeleteCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.cannotDeleteTitle),
        content: Text(context.l10n.cannotDeleteCategoryContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(context.l10n.actionClose),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    ServiceCategory? category,
  }) {
    final notifier = ref.read(serviceCategoriesProvider.notifier);
    final allCategories = ref.read(serviceCategoriesProvider);

    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(
      text: category?.description ?? '',
    );

    bool nameError = false;
    bool duplicateError = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            category == null
                ? context.l10n.newCategoryTitle
                : context.l10n.editCategoryTitle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: context.l10n.fieldNameRequiredLabel,
                    errorText: nameError
                        ? context.l10n.fieldNameRequiredError
                        : (duplicateError
                              ? context.l10n.categoryDuplicateError
                              : null),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.l10n.fieldDescriptionLabel,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.actionCancel),
            ),
            ElevatedButton(
              onPressed: () {
                final rawName = nameController.text.trim();
                if (rawName.isEmpty) {
                  setState(() => nameError = true);
                  return;
                }

                final formattedName = rawName
                    .split(' ')
                    .map(
                      (w) => w.isEmpty
                          ? ''
                          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
                    )
                    .join(' ');

                if (allCategories.any(
                  (c) =>
                      c.id != category?.id &&
                      c.name.toLowerCase() == formattedName.toLowerCase(),
                )) {
                  setState(() => duplicateError = true);
                  return;
                }

                final newCategory = ServiceCategory(
                  id: category?.id ?? DateTime.now().millisecondsSinceEpoch,
                  businessId: ref.read(currentBusinessProvider).id,
                  name: formattedName,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  sortOrder: category?.sortOrder ?? allCategories.length,
                );

                if (category == null) {
                  notifier.addCategory(newCategory);
                } else {
                  notifier.updateCategory(newCategory);
                }

                Navigator.pop(context);
              },
              child: Text(context.l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceDialog(
    BuildContext context,
    WidgetRef ref, {
    Service? service,
    int? preselectedCategoryId,
  }) {
    final notifier = ref.read(servicesProvider.notifier);
    final allServices = ref.read(servicesProvider);
    final categories = ref.read(serviceCategoriesProvider);
    final currencyCode = ref.read(effectiveCurrencyProvider);
    final currencySymbol = NumberFormat.currency(
      name: currencyCode,
    ).currencySymbol;

    final nameController = TextEditingController(text: service?.name ?? '');
    final priceController = TextEditingController(
      text: service?.price != null
          ? PriceFormatter.format(
              context: context,
              amount: service!.price!,
              currencyCode: currencyCode,
            )
          : '',
    );
    final descController = TextEditingController(
      text: service?.description ?? '',
    );

    int selectedCategory =
        service?.categoryId ?? preselectedCategoryId ?? categories.first.id;
    int? selectedDuration = service?.duration;

    bool isBookableOnline = service?.isBookableOnline ?? true;
    bool isFree = service?.isFree ?? false;
    bool isPriceStartingFrom = service?.isPriceStartingFrom ?? false;

    bool nameError = false;
    bool duplicateError = false;
    bool durationError = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              service == null
                  ? context.l10n.newServiceTitle
                  : context.l10n.editServiceTitle,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: context.l10n.fieldCategoryLabel,
                    ),
                    items: [
                      for (final c in categories)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.fieldNameRequiredLabel,
                      errorText: nameError
                          ? context.l10n.fieldNameRequiredError
                          : (duplicateError
                                ? context.l10n.serviceDuplicateError
                                : null),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: selectedDuration,
                    decoration: InputDecoration(
                      labelText: context.l10n.fieldDurationRequiredLabel,
                      errorText: durationError
                          ? context.l10n.fieldDurationRequiredError
                          : null,
                    ),
                    items: [
                      for (final (minutes, label) in _durationOptions(context))
                        DropdownMenuItem(value: minutes, child: Text(label)),
                    ],
                    onChanged: (v) => setState(() {
                      selectedDuration = v;
                      durationError = false;
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.l10n.fieldDescriptionLabel,
                    ),
                  ),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
                    ],
                    decoration: InputDecoration(
                      labelText: context.l10n.fieldPriceLabel,
                      prefixText: '$currencySymbol ',
                    ),
                    enabled: !isFree,
                    onChanged: (_) {
                      if (priceController.text.trim().isEmpty &&
                          isPriceStartingFrom) {
                        setState(() => isPriceStartingFrom = false);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: Text(context.l10n.bookableOnlineSwitch),
                    value: isBookableOnline,
                    onChanged: (v) => setState(() => isBookableOnline = v),
                  ),
                  SwitchListTile(
                    title: Text(context.l10n.freeServiceSwitch),
                    value: isFree,
                    onChanged: (v) {
                      setState(() {
                        isFree = v;
                        if (isFree) {
                          priceController.clear();
                          isPriceStartingFrom = false;
                        }
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(context.l10n.priceStartingFromSwitch),
                    subtitle: (isFree || priceController.text.trim().isEmpty)
                        ? Text(context.l10n.setPriceToEnable)
                        : null,
                    value: isPriceStartingFrom,
                    onChanged:
                        (!isFree && priceController.text.trim().isNotEmpty)
                        ? (v) => setState(() => isPriceStartingFrom = v)
                        : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: Text(context.l10n.actionCancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    setState(() => nameError = true);
                    return;
                  }
                  final normalizedName = name
                      .split(' ')
                      .map(
                        (w) => w.isEmpty
                            ? ''
                            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
                      )
                      .join(' ');
                  if (allServices.any(
                    (s) =>
                        s.id != service?.id &&
                        s.name.toLowerCase() == normalizedName.toLowerCase(),
                  )) {
                    setState(() => duplicateError = true);
                    return;
                  }
                  if (selectedDuration == null) {
                    setState(() => durationError = true);
                    return;
                  }

                  final parsedPrice = PriceFormatter.parse(
                    priceController.text,
                  );
                  final effectiveIsFree = isFree;
                  final double? finalPrice = effectiveIsFree
                      ? null
                      : parsedPrice;
                  final bool finalIsPriceStartingFrom =
                      (effectiveIsFree || finalPrice == null)
                      ? false
                      : isPriceStartingFrom;

                  final newService = Service(
                    id: service?.id ?? DateTime.now().millisecondsSinceEpoch,
                    businessId: ref.read(currentBusinessProvider).id,
                    categoryId: selectedCategory,
                    name: normalizedName,
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    duration: selectedDuration,
                    price: finalPrice,
                    color: service?.color,
                    isBookableOnline: isBookableOnline,
                    isFree: effectiveIsFree,
                    isPriceStartingFrom: finalIsPriceStartingFrom,
                    currency: service?.currency ?? currencyCode,
                  );

                  if (service == null) {
                    notifier.add(newService);
                  } else {
                    notifier.update(newService);
                  }

                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: Text(context.l10n.actionSave),
              ),
            ],
          );
        },
      ),
    ).then((_) => _selectedService.value = null);
  }

  // ---------- Opzioni durata ----------
  List<(int, String)> _durationOptions(BuildContext context) {
    final List<(int, String)> options = [];
    for (int i = 5; i <= 240; i += 5) {
      options.add((i, context.localizedDurationLabel(i)));
    }
    return options;
  }

  // ---------- Azioni servizio ----------
  Widget _buildActionIcons(
    BuildContext context,
    WidgetRef ref,
    Service service,
    dynamic servicesNotifier,
  ) {
    return Row(
      children: [
        IconButton(
          tooltip: context.l10n.actionEdit,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _showServiceDialog(context, ref, service: service),
        ),
        IconButton(
          tooltip: context.l10n.duplicateAction,
          icon: const Icon(Icons.copy_outlined),
          onPressed: () => servicesNotifier.duplicate(service),
        ),
        IconButton(
          tooltip: context.l10n.actionDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(
            context,
            onConfirm: () => servicesNotifier.delete(service.id),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
    WidgetRef ref,
    Service service,
    dynamic servicesNotifier,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showServiceDialog(context, ref, service: service);
            break;
          case 'duplicate':
            servicesNotifier.duplicate(service);
            break;
          case 'delete':
            _confirmDelete(
              context,
              onConfirm: () => servicesNotifier.delete(service.id),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(context.l10n.actionEdit)),
        PopupMenuItem(
          value: 'duplicate',
          child: Text(context.l10n.duplicateAction),
        ),
        PopupMenuItem(value: 'delete', child: Text(context.l10n.actionDelete)),
      ],
    );
  }

  void _confirmDelete(BuildContext context, {required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.deleteServiceQuestion),
        content: Text(context.l10n.cannotUndoWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(context.l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.of(context, rootNavigator: true).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
  }
}

// ============================
//  Helper per due ValueNotifier
// ============================
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;
  final Widget? child;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, valueA, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, valueB, __) {
            return builder(context, valueA, valueB, child);
          },
        );
      },
    );
  }
}
