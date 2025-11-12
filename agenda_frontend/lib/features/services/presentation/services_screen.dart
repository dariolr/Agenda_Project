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

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  static final ValueNotifier<int?> _hoveredService = ValueNotifier<int?>(null);
  static final ValueNotifier<int?> _selectedService = ValueNotifier<int?>(null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReordering = ref.watch(servicesReorderProvider);
    final categories = ref.watch(sortedCategoriesProvider);
    final servicesNotifier = ref.read(servicesProvider.notifier);
    final formFactor = ref.watch(formFactorProvider);
    final isWide = formFactor == AppFormFactor.tabletOrDesktop;
    final colorScheme = Theme.of(context).colorScheme;

    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCategoryDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Nuova categoria'), // TODO: l10n
        ),
        body: Column(
          children: [
            // Toolbar azioni
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      ref.read(servicesReorderProvider.notifier).toggle();
                      if (isReordering) {
                        // Quando esci dalla modalità, conferma salvataggio
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ordine salvato'),
                          ), // TODO: l10n
                        );
                      }
                    },
                    icon: Icon(
                      isReordering ? Icons.check : Icons.drag_indicator,
                    ),
                    label: Text(
                      isReordering ? 'Fine' : 'Modifica ordine',
                    ), // TODO: l10n
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: isReordering
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      buildDefaultDragHandles: false,
                      itemCount: categories.length,
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(servicesReorderProvider.notifier)
                            .reorderCategories(oldIndex, newIndex);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ordine salvato'),
                          ), // TODO: l10n
                        );
                      },
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final services = ref.watch(
                          sortedServicesByCategoryProvider(category.id),
                        );
                        return Container(
                          key: ValueKey('cat-${category.id}'),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.4,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header categoria con handle drag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withOpacity(0.6),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.drag_indicator),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        category.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Lista servizi riordinabile della categoria
                              if (services.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text('Nessun servizio'), // TODO: l10n
                                )
                              else
                                ReorderableListView.builder(
                                  key: ValueKey('svc-list-${category.id}'),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  buildDefaultDragHandles: false,
                                  itemCount: services.length,
                                  onReorder: (oldIndex, newIndex) {
                                    ref
                                        .read(servicesReorderProvider.notifier)
                                        .reorderServices(
                                          category.id,
                                          oldIndex,
                                          newIndex,
                                        );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ordine salvato'),
                                      ), // TODO: l10n
                                    );
                                  },
                                  itemBuilder: (ctx, i) {
                                    final s = services[i];
                                    return ListTile(
                                      key: ValueKey('svc-${s.id}'),
                                      leading: ReorderableDragStartListener(
                                        index: i,
                                        child: const Icon(Icons.drag_indicator),
                                      ),
                                      title: Text(s.name),
                                      subtitle: s.description != null
                                          ? Text(
                                              s.description!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : null,
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
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
                              // 🔹 Header categoria
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                        ),
                                        if (category.description != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              category.description!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onPrimaryContainer
                                                        .withOpacity(0.8),
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Aggiungi servizio',
                                          icon: Icon(
                                            Icons.add,
                                            color:
                                                colorScheme.onPrimaryContainer,
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
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                          onPressed: () => _showCategoryDialog(
                                            context,
                                            ref,
                                            category: category,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: context.l10n.actionDelete,
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          color: colorScheme.onPrimaryContainer,
                                          onPressed: () {
                                            final hasServices =
                                                services.isNotEmpty;
                                            if (hasServices) {
                                              _showCannotDeleteCategoryDialog(
                                                context,
                                              );
                                              return;
                                            }
                                            _confirmDeleteCategory(
                                              context,
                                              ref,
                                              category.id,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              if (services.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Nessun servizio in questa categoria',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                )
                              else
                                ValueListenableBuilder2<int?, int?>(
                                  first: _hoveredService,
                                  second: _selectedService,
                                  builder: (context, hoveredId, selectedId, _) {
                                    return Column(
                                      children: [
                                        for (
                                          int i = 0;
                                          i < services.length;
                                          i++
                                        )
                                          Builder(
                                            builder: (context) {
                                              final service = services[i];
                                              final isLast =
                                                  i == services.length - 1;

                                              return MouseRegion(
                                                onEnter: (_) =>
                                                    _hoveredService.value =
                                                        service.id,
                                                onExit: (_) =>
                                                    _hoveredService.value =
                                                        null,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    _selectedService.value =
                                                        service.id;
                                                    _showServiceDialog(
                                                      context,
                                                      ref,
                                                      service: service,
                                                    );
                                                  },
                                                  child: ValueListenableBuilder2<int?, int?>(
                                                    first: _hoveredService,
                                                    second: _selectedService,
                                                    builder:
                                                        (
                                                          context,
                                                          hoveredId,
                                                          selectedId,
                                                          _,
                                                        ) {
                                                          final isHovered =
                                                              hoveredId ==
                                                              service.id;
                                                          final isSelected =
                                                              selectedId ==
                                                              service.id;
                                                          final baseColor =
                                                              i.isOdd
                                                              ? colorScheme
                                                                    .onSurface
                                                                    .withOpacity(
                                                                      0.04,
                                                                    )
                                                              : Colors
                                                                    .transparent;

                                                          // Hover/Selezione hanno priorità
                                                          final bgColor =
                                                              (isHovered ||
                                                                  isSelected)
                                                              ? colorScheme
                                                                    .primaryContainer
                                                                    .withOpacity(
                                                                      0.1,
                                                                    )
                                                              : baseColor;

                                                          // Hover/Selezione hanno priorità
                                                          return Container(
                                                            decoration: BoxDecoration(
                                                              color: bgColor,
                                                              borderRadius: BorderRadius.only(
                                                                bottomLeft:
                                                                    isLast
                                                                    ? const Radius.circular(
                                                                        16,
                                                                      )
                                                                    : Radius
                                                                          .zero,
                                                                bottomRight:
                                                                    isLast
                                                                    ? const Radius.circular(
                                                                        16,
                                                                      )
                                                                    : Radius
                                                                          .zero,
                                                              ),
                                                            ),
                                                            child: ListTile(
                                                              contentPadding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical: 6,
                                                                  ),
                                                              title: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    service
                                                                        .name,
                                                                    style: Theme.of(context)
                                                                        .textTheme
                                                                        .titleMedium
                                                                        ?.copyWith(
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                  ),
                                                                  if (!service
                                                                      .isBookableOnline)
                                                                    Padding(
                                                                      padding:
                                                                          const EdgeInsets.only(
                                                                            top:
                                                                                2,
                                                                          ),
                                                                      child: Text(
                                                                        'Non prenotabile online',
                                                                        style:
                                                                            Theme.of(
                                                                              context,
                                                                            ).textTheme.bodySmall?.copyWith(
                                                                              color: Colors.red[600],
                                                                              fontStyle: FontStyle.italic,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                              subtitle:
                                                                  service.description !=
                                                                      null
                                                                  ? Text(
                                                                      service
                                                                          .description!,
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    )
                                                                  : null,
                                                              trailing: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  if (service
                                                                      .isFree)
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .green
                                                                            .withOpacity(
                                                                              0.1,
                                                                            ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                        border: Border.all(
                                                                          color: Colors.green.withOpacity(
                                                                            0.3,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      child: const Text(
                                                                        'Gratuito',
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.green,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              13,
                                                                        ),
                                                                      ),
                                                                    )
                                                                  else
                                                                    Text(
                                                                      PriceFormatter.formatService(
                                                                        context:
                                                                            context,
                                                                        ref:
                                                                            ref,
                                                                        service:
                                                                            service,
                                                                      ),
                                                                      style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                      ),
                                                                    ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  if (isWide)
                                                                    _buildActionIcons(
                                                                      context,
                                                                      ref,
                                                                      service,
                                                                      servicesNotifier,
                                                                    )
                                                                  else
                                                                    _buildPopupMenu(
                                                                      context,
                                                                      ref,
                                                                      service,
                                                                      servicesNotifier,
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                  ),
                                                ),
                                              );
                                            },
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
                    ),
            ),
          ],
        ),
      ),
    );
  }

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
        title: const Text('Impossibile eliminare'),
        content: const Text('La categoria contiene uno o più servizi.'),
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
            category == null ? 'Nuova categoria' : 'Modifica categoria',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nome *',
                  errorText: nameError
                      ? 'Il nome è obbligatorio'
                      : duplicateError
                      ? 'Esiste già una categoria con questo nome'
                      : null,
                ),
              ),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descrizione'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
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
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 Dialog di aggiunta/modifica servizio
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
              service == null ? 'Nuovo servizio' : 'Modifica servizio',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: [
                      for (final c in categories)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome *',
                      errorText: nameError
                          ? 'Il nome è obbligatorio'
                          : duplicateError
                          ? 'Esiste già un servizio con questo nome'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: selectedDuration,
                    decoration: InputDecoration(
                      labelText: 'Durata *',
                      errorText: durationError ? 'Seleziona una durata' : null,
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
                    decoration: const InputDecoration(labelText: 'Descrizione'),
                  ),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      // consente solo cifre, punto, virgola e segno -
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Prezzo',
                      prefixText: '$currencySymbol ',
                    ),
                    enabled: !isFree,
                    onChanged: (_) {
                      // se non c'è prezzo, "a partire da" non ha senso
                      if (priceController.text.trim().isEmpty &&
                          isPriceStartingFrom) {
                        setState(() => isPriceStartingFrom = false);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Prenotabile online'),
                    value: isBookableOnline,
                    onChanged: (v) => setState(() => isBookableOnline = v),
                  ),
                  SwitchListTile(
                    title: const Text('Servizio gratuito'),
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
                    title: const Text('Prezzo "a partire da"'),
                    subtitle: (isFree || priceController.text.trim().isEmpty)
                        ? const Text('Imposta un prezzo per abilitarlo')
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
                child: const Text('Annulla'),
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
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ),
    ).then((_) => _selectedService.value = null);
  }

  /// Opzioni durata
  List<(int, String)> _durationOptions(BuildContext context) {
    final List<(int, String)> options = [];
    for (int i = 5; i <= 240; i += 5) {
      options.add((i, context.localizedDurationLabel(i)));
    }
    return options;
  }

  Widget _buildActionIcons(
    BuildContext context,
    WidgetRef ref,
    Service service,
    dynamic servicesNotifier,
  ) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Modifica',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _showServiceDialog(context, ref, service: service),
        ),
        IconButton(
          tooltip: 'Duplica',
          icon: const Icon(Icons.copy_outlined),
          onPressed: () => servicesNotifier.duplicate(service),
        ),
        IconButton(
          tooltip: 'Elimina',
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
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Modifica')),
        PopupMenuItem(value: 'duplicate', child: Text('Duplica')),
        PopupMenuItem(value: 'delete', child: Text('Elimina')),
      ],
    );
  }

  void _confirmDelete(BuildContext context, {required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminare il servizio?'),
        content: const Text('Questa azione non può essere annullata.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.of(context, rootNavigator: true).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}

/// Helper per due ValueNotifier
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
