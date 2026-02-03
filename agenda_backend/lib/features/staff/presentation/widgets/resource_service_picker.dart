import 'package:flutter/material.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_dividers.dart';

/// Picker per selezionare servizi multipli da associare a una risorsa.
/// Simile al ServicePickerField ma:
/// - Permette selezione multipla
/// - Non ha il checkbox "visualizza tutti"
/// - Non ha la sezione pacchetti
/// - Non ha la sezione servizi popolari
class ResourceServicePicker extends StatelessWidget {
  const ResourceServicePicker({
    super.key,
    required this.services,
    required this.categories,
    required this.selectedServiceVariantIds,
    required this.onSelectionChanged,
    required this.formFactor,
  });

  final List<Service> services;
  final List<ServiceCategory> categories;
  final Set<int> selectedServiceVariantIds;
  final ValueChanged<Set<int>> onSelectionChanged;
  final AppFormFactor formFactor;

  Future<void> _openPicker(BuildContext context) async {
    final result = await _showPickerSheet(context);
    if (result != null) {
      onSelectionChanged(result);
    }
  }

  Future<Set<int>?> _showPickerSheet(BuildContext context) async {
    final isDesktop = formFactor == AppFormFactor.desktop;

    if (!isDesktop) {
      return AppBottomSheet.show<Set<int>>(
        context: context,
        heightFactor: 0.85,
        builder: (ctx) => _ResourceServicePickerContent(
          services: services,
          categories: categories,
          selectedIds: selectedServiceVariantIds,
        ),
      );
    }

    // Desktop: dialog
    return showDialog<Set<int>>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: _ResourceServicePickerContent(
            services: services,
            categories: categories,
            selectedIds: selectedServiceVariantIds,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Ottieni i nomi dei servizi selezionati
    final selectedServices = <Service>[];
    for (final service in services) {
      final variantId = service.serviceVariantId;
      if (variantId != null && selectedServiceVariantIds.contains(variantId)) {
        selectedServices.add(service);
      }
    }

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Row(
          children: [
            Expanded(
              child: selectedServices.isEmpty
                  ? Text(
                      l10n.resourceNoServicesSelected,
                      style: TextStyle(color: colorScheme.outline),
                    )
                  : Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final service in selectedServices)
                          Chip(
                            label: Text(
                              service.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                          ),
                      ],
                    ),
            ),
            Text(
              '${selectedServiceVariantIds.length}/${services.length}',
              style: TextStyle(color: colorScheme.outline, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_drop_down, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

/// Contenuto del picker per servizi multipli.
class _ResourceServicePickerContent extends StatefulWidget {
  const _ResourceServicePickerContent({
    required this.services,
    required this.categories,
    required this.selectedIds,
  });

  final List<Service> services;
  final List<ServiceCategory> categories;
  final Set<int> selectedIds;

  @override
  State<_ResourceServicePickerContent> createState() =>
      _ResourceServicePickerContentState();
}

class _ResourceServicePickerContentState
    extends State<_ResourceServicePickerContent> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.selectedIds};

    // Auto-focus sul campo di ricerca dopo il primo build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Service> get _filteredServices {
    var services = widget.services;

    // Filtra per query di ricerca
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      services = services
          .where((s) => s.name.toLowerCase().contains(query))
          .toList();
    }

    return services;
  }

  void _toggleService(int variantId) {
    setState(() {
      if (_selectedIds.contains(variantId)) {
        _selectedIds.remove(variantId);
      } else {
        _selectedIds.add(variantId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final service in _filteredServices) {
        final variantId = service.serviceVariantId;
        if (variantId != null) {
          _selectedIds.add(variantId);
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      for (final service in _filteredServices) {
        final variantId = service.serviceVariantId;
        if (variantId != null) {
          _selectedIds.remove(variantId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;

    final filteredServices = _filteredServices;

    final servicesByCategory = <int, List<Service>>{};
    for (final service in filteredServices) {
      (servicesByCategory[service.categoryId] ??= []).add(service);
    }

    final hasServicesMap = <int, bool>{
      for (final category in widget.categories)
        category.id: (servicesByCategory[category.id]?.isNotEmpty ?? false),
    };

    // Sort categories: non-empty before empty, then sortOrder, then name
    final sortedCategories = [...widget.categories]
      ..sort((a, b) {
        final aEmpty = !(hasServicesMap[a.id] ?? false);
        final bEmpty = !(hasServicesMap[b.id] ?? false);
        if (aEmpty != bEmpty) return aEmpty ? 1 : -1;
        final so = a.sortOrder.compareTo(b.sortOrder);
        return so != 0
            ? so
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final showSearchField =
        widget.services.length > 10 || _searchQuery.isNotEmpty;

    // Calcola se tutti i servizi filtrati sono selezionati
    final allFilteredSelected = filteredServices.every((s) {
      final variantId = s.serviceVariantId;
      return variantId != null && _selectedIds.contains(variantId);
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header con pulsanti azioni
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.resourceSelectServices,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Pulsante seleziona/deseleziona tutti
              TextButton(
                onPressed: allFilteredSelected ? _deselectAll : _selectAll,
                child: Text(
                  allFilteredSelected
                      ? l10n.actionDeselectAll
                      : l10n.actionSelectAll,
                ),
              ),
            ],
          ),
        ),
        // Campo di ricerca (solo se > 10 servizi)
        if (showSearchField)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: l10n.searchServices,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        const SizedBox(height: 8),
        const AppDivider(),
        // Lista servizi
        Expanded(
          child: filteredServices.isEmpty
              ? Center(
                  child: Text(
                    l10n.noServicesFound,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  controller: _scrollController,
                  children: [
                    for (final category in sortedCategories)
                      Builder(
                        builder: (ctx) {
                          final categoryServices =
                              (servicesByCategory[category.id] ?? []).toList()
                                ..sort((a, b) {
                                  final so = a.sortOrder.compareTo(b.sortOrder);
                                  return so != 0
                                      ? so
                                      : a.name.toLowerCase().compareTo(
                                          b.name.toLowerCase(),
                                        );
                                });

                          if (categoryServices.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return _CategorySection(
                            category: category,
                            services: categoryServices,
                            selectedIds: _selectedIds,
                            onToggle: _toggleService,
                          );
                        },
                      ),
                  ],
                ),
        ),
        const AppDivider(),
        // Footer con pulsanti conferma/annulla
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.actionCancel),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_selectedIds),
                child: Text(l10n.actionConfirm),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sezione categoria con checkbox per selezione multipla.
class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.services,
    required this.selectedIds,
    required this.onToggle,
  });

  final ServiceCategory category;
  final List<Service> services;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            category.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ),
        // Services
        for (final service in services)
          Builder(
            builder: (context) {
              final variantId = service.serviceVariantId;
              if (variantId == null) return const SizedBox.shrink();

              final isSelected = selectedIds.contains(variantId);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => onToggle(variantId),
                title: Text(service.name, style: theme.textTheme.bodyMedium),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              );
            },
          ),
      ],
    );
  }
}
