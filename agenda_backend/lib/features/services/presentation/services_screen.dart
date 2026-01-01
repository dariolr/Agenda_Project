import 'dart:async';

import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/service_variant.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/reorder_toggle_button.dart';
import '../../../core/widgets/reorder_toggle_panel.dart';
import '../../staff/providers/staff_providers.dart';
import '../providers/service_categories_provider.dart';
import '../providers/services_provider.dart';
import '../providers/services_reorder_provider.dart';
import '../providers/services_sorted_providers.dart';
// utils e validators spostati nei dialog
import 'dialogs/category_dialog.dart';
import 'dialogs/service_dialog.dart';
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

  /// Modalità di riordino (mutuamente esclusive)
  bool isReorderCategories = false;
  bool isReorderServices = false;

  @override
  void initState() {
    super.initState();
    // Ricarica servizi e staff dal DB quando si entra nella schermata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(servicesProvider.notifier).refresh();
      ref.read(allStaffProvider.notifier).refresh();
    });
  }

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

  void _toggleCategoryReorder() {
    setState(() {
      isReorderCategories = !isReorderCategories;
      if (isReorderCategories) isReorderServices = false;
    });
    if (!isReorderCategories) {
      ref.read(servicesReorderPanelProvider.notifier).setVisible(false);
    }
  }

  void _toggleServiceReorder() {
    setState(() {
      isReorderServices = !isReorderServices;
      if (isReorderServices) isReorderCategories = false;
    });
    if (!isReorderServices) {
      ref.read(servicesReorderPanelProvider.notifier).setVisible(false);
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProvider);
    final allCategories = ref.watch(sortedCategoriesProvider);

    // Mostriamo sempre tutte le categorie; i provider di sort sposteranno le vuote in coda.
    final categories = allCategories;

    final colorScheme = Theme.of(context).colorScheme;
    final isWide = ref.watch(formFactorProvider) != AppFormFactor.mobile;
    final showReorderPanel = ref.watch(servicesReorderPanelProvider);

    ref.listen<bool>(servicesReorderPanelProvider, (previous, next) {
      if (!next && (isReorderCategories || isReorderServices)) {
        setState(() {
          isReorderCategories = false;
          isReorderServices = false;
        });
      }
    });

    // Mostra loading mentre carica servizi
    if (servicesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectedService.value = null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showReorderPanel) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      context.l10n.reorderTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                      child: Text(
                        context.l10n.reorderHelpDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ReorderTogglePanel(
                      isWide: isWide,
                      children: [
                        ReorderToggleButton(
                          isActive: isReorderCategories,
                          onPressed: _toggleCategoryReorder,
                          activeLabel: context.l10n.reorderCategoriesLabel,
                          inactiveLabel: context.l10n.reorderCategoriesLabel,
                          activeIcon: Icons.check,
                          inactiveIcon: Icons.drag_indicator,
                        ),
                        ReorderToggleButton(
                          isActive: isReorderServices,
                          onPressed: _toggleServiceReorder,
                          activeLabel: context.l10n.reorderServicesLabel,
                          inactiveLabel: context.l10n.reorderServicesLabel,
                          activeIcon: Icons.check,
                          inactiveIcon: Icons.drag_indicator,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

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

    // Partiziona categorie piene e vuote
    final services = ref.watch(servicesProvider).value ?? [];
    final isNonEmpty = <int, bool>{
      for (final c in cats) c.id: services.any((s) => s.categoryId == c.id),
    };
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

    // Flatten di tutti i servizi (solo delle categorie visualizzate)
    final allServices = <Service>[];
    final servicesByCategory = <int, List<Service>>{};
    for (final c in cats) {
      final list = ref.watch(sortedServicesByCategoryProvider(c.id));
      servicesByCategory[c.id] = list;
      allServices.addAll(list);
    }

    // Costruisce la lista visuale con header categoria "fissi" e righe servizio.
    // Gli header non hanno drag handle e non sono riordinabili; i servizi sì.
    final rows = <({bool isHeader, Service? s, ServiceCategory? c})>[];
    for (final c in cats) {
      final list = servicesByCategory[c.id] ?? const <Service>[];
      // Sempre mostrare header, anche se vuota
      rows.add((isHeader: true, s: null, c: c));
      for (final s in list) {
        rows.add((isHeader: false, s: s, c: null));
      }
    }

    int serviceFlatIndexFromRowsIndex(int rowsIndex) {
      int count = 0;
      for (int i = 0; i < rowsIndex; i++) {
        if (!rows[i].isHeader) count++;
      }
      return count;
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
        // Coerenza visiva: nessuna elevazione/ombra anche durante il drag servizi
        proxyDecorator: (child, index, animation) => child,
        itemCount: rows.length,
        onReorder: (oldIndex, newIndex) {
          // Normalizzazione Flutter Reorderable semantics
          final movingDown = newIndex > oldIndex;
          if (movingDown) newIndex -= 1;

          // Indice e servizio originale (riga servizio)
          final sOld = rows[oldIndex].s!;
          final oldCatId = sOld.categoryId;

          // Traduci newIndex della lista visuale in indice sulla lista servizi (saltando header)
          final targetServiceFlatIndex = serviceFlatIndexFromRowsIndex(
            newIndex,
          );

          // Calcola destinazione (categoria e indice relativo nella categoria) sulla base della lista servizi "reale"
          final (targetCatId, indexInTargetCat) = targetForFlatIndex(
            targetServiceFlatIndex,
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

          final s = row.s!;
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
  ) {
    final servicesNotifier = ref.read(servicesProvider.notifier);
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
      onServiceDelete: (id) =>
          _confirmDelete(context, onConfirm: () => servicesNotifier.delete(id)),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
  ) {
    showAppConfirmDialog(
      context,
      title: Text(context.l10n.deleteConfirmationTitle),
      confirmLabel: context.l10n.actionDelete,
      cancelLabel: context.l10n.actionCancel,
      danger: true,
      onConfirm: () {
        ref.read(serviceCategoriesProvider.notifier).deleteCategory(categoryId);
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
    return showServiceDialog(
      context,
      ref,
      service: service,
      preselectedCategoryId: preselectedCategoryId,
      preselectedColor: preselectedColor,
      duplicateFrom: duplicateFrom,
    ).then((_) => _selectedService.value = null);
  }

  void _confirmDelete(BuildContext context, {required VoidCallback onConfirm}) {
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
}

// Add menu locale rimosso: ora è gestito dallo ScaffoldWithNavigation
