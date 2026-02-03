import 'package:flutter/material.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/theme/extensions.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/popular_service.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/models/service_package.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_dividers.dart';

/// A form field for selecting a service, with services grouped by category.
/// Optionally shows packages in a dedicated section at the top.
///
/// On mobile: opens a bottom sheet with grouped services.
/// On desktop: opens a dialog with grouped services.
class ServicePickerField extends StatefulWidget {
  const ServicePickerField({
    super.key,
    required this.services,
    required this.categories,
    required this.formFactor,
    this.packages,
    this.popularServices,
    this.value,
    this.onChanged,
    this.onPackageSelected,
    this.onClear,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.autoOpenPicker = false,
    this.onAutoOpenPickerTriggered,
    this.onAutoOpenPickerCompleted,
    this.preselectedStaffServiceIds,
  });

  final List<Service> services;
  final List<ServiceCategory> categories;

  /// Optional list of packages to show in the picker.
  /// If provided, packages will appear in a dedicated section at the top.
  final List<ServicePackage>? packages;

  /// Servizi più prenotati per questa location.
  /// Se fornito e showPopularSection è true, mostra una sezione dedicata.
  final PopularServicesResult? popularServices;

  /// Lista di service IDs che lo staff preselezionato può eseguire.
  /// Se fornita, il picker mostrerà inizialmente solo questi servizi con
  /// un checkbox per visualizzare tutti i servizi.
  final List<int>? preselectedStaffServiceIds;

  final AppFormFactor formFactor;
  final int? value;
  final ValueChanged<int?>? onChanged;

  /// Callback called when a package is selected.
  /// The package is passed as parameter for expansion.
  final ValueChanged<ServicePackage>? onPackageSelected;

  /// Callback chiamato quando l'utente preme l'icona di rimozione.
  /// Se null, l'icona non viene mostrata.
  final VoidCallback? onClear;
  final FormFieldValidator<int>? validator;
  final bool autoOpenPicker;
  final VoidCallback? onAutoOpenPickerTriggered;
  final VoidCallback? onAutoOpenPickerCompleted;

  /// Modalità di autovalidazione. Default: disabled (valida solo su submit).
  final AutovalidateMode autovalidateMode;

  @override
  State<ServicePickerField> createState() => _ServicePickerFieldState();
}

class _ServicePickerFieldState extends State<ServicePickerField> {
  final _formFieldKey = GlobalKey<FormFieldState<int>>();
  bool _autoPickerInvoked = false;
  bool _autoOpenInProgress = false;

  Service? get _selectedService {
    if (widget.value == null) return null;
    return widget.services.where((s) => s.id == widget.value).firstOrNull;
  }

  @override
  void didUpdateWidget(ServicePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Aggiorna lo stato del FormField quando il valore cambia
    if (oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = _formFieldKey.currentState;
        if (state != null) {
          state.didChange(widget.value);
        }
      });
    }
    if (oldWidget.autoOpenPicker != widget.autoOpenPicker) {
      _autoPickerInvoked = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      key: _formFieldKey,
      initialValue: widget.value,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (field) {
        final theme = Theme.of(context);
        final hasError = field.hasError;
        final borderColor = hasError
            ? theme.colorScheme.error
            : theme.colorScheme.outline;

        if (widget.autoOpenPicker && !_autoPickerInvoked) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _autoPickerInvoked) return;
            _autoPickerInvoked = true;
            _autoOpenInProgress = true;
            _openPicker(field);
            widget.onAutoOpenPickerTriggered?.call();
          });
        }

        return InkWell(
          onTap: () => _openPicker(field),
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: _selectedService != null
                  ? context.l10n.formService
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: borderColor),
              ),
              errorText: field.errorText,
              suffixIcon: _selectedService != null && widget.onClear != null
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      onPressed: widget.onClear,
                      tooltip: context.l10n.actionDelete,
                    )
                  : const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              _selectedService?.name ?? context.l10n.selectService,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: _selectedService == null
                    ? theme.colorScheme.onSurfaceVariant.withOpacity(0.7)
                    : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPicker(FormFieldState<int> field) async {
    if (widget.formFactor == AppFormFactor.desktop) {
      await _openDesktopDialogWithField(field);
    } else {
      await _openBottomSheetWithField(field);
    }
  }

  Future<void> _openBottomSheetWithField(FormFieldState<int> field) async {
    await AppBottomSheet.show<int>(
      context: context,
      heightFactor: AppBottomSheet.defaultHeightFactor,
      padding: EdgeInsets.zero,
      builder: (ctx) => _ServicePickerContent(
        services: widget.services,
        categories: widget.categories,
        packages: widget.packages,
        popularServices: widget.popularServices,
        preselectedStaffServiceIds: widget.preselectedStaffServiceIds,
        selectedId: widget.value,
        onSelected: (id) {
          final wasAutoOpen = _autoOpenInProgress;
          Navigator.of(ctx).pop();
          field.didChange(id);
          field.validate(); // Ri-valida per rimuovere l'errore
          widget.onChanged?.call(id);
          if (wasAutoOpen) {
            _autoOpenInProgress = false;
            widget.onAutoOpenPickerCompleted?.call();
          }
        },
        onPackageSelected: widget.onPackageSelected != null
            ? (package) {
                final wasAutoOpen = _autoOpenInProgress;
                Navigator.of(ctx).pop();
                widget.onPackageSelected!(package);
                if (wasAutoOpen) {
                  _autoOpenInProgress = false;
                  widget.onAutoOpenPickerCompleted?.call();
                }
              }
            : null,
      ),
    );
    _autoOpenInProgress = false;
  }

  Future<void> _openDesktopDialogWithField(FormFieldState<int> field) async {
    await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 600,
            maxWidth: 720,
            maxHeight: 500,
          ),
          child: _ServicePickerContent(
            services: widget.services,
            categories: widget.categories,
            packages: widget.packages,
            popularServices: widget.popularServices,
            preselectedStaffServiceIds: widget.preselectedStaffServiceIds,
            selectedId: widget.value,
            onSelected: (id) {
              final wasAutoOpen = _autoOpenInProgress;
              Navigator.of(ctx).pop();
              field.didChange(id);
              field.validate(); // Ri-valida per rimuovere l'errore
              widget.onChanged?.call(id);
              if (wasAutoOpen) {
                _autoOpenInProgress = false;
                widget.onAutoOpenPickerCompleted?.call();
              }
            },
            onPackageSelected: widget.onPackageSelected != null
                ? (package) {
                    final wasAutoOpen = _autoOpenInProgress;
                    Navigator.of(ctx).pop();
                    widget.onPackageSelected!(package);
                    if (wasAutoOpen) {
                      _autoOpenInProgress = false;
                      widget.onAutoOpenPickerCompleted?.call();
                    }
                  }
                : null,
          ),
        ),
      ),
    );
    _autoOpenInProgress = false;
  }
}

/// Content widget for the service picker (used in both bottom sheet and popup).
class _ServicePickerContent extends StatefulWidget {
  const _ServicePickerContent({
    required this.services,
    required this.categories,
    this.packages,
    this.popularServices,
    this.preselectedStaffServiceIds,
    required this.selectedId,
    required this.onSelected,
    this.onPackageSelected,
  });

  final List<Service> services;
  final List<ServiceCategory> categories;
  final List<ServicePackage>? packages;
  final PopularServicesResult? popularServices;
  final List<int>? preselectedStaffServiceIds;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  final ValueChanged<ServicePackage>? onPackageSelected;

  @override
  State<_ServicePickerContent> createState() => _ServicePickerContentState();
}

class _ServicePickerContentState extends State<_ServicePickerContent> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  bool _showAllServices = false;

  @override
  void initState() {
    super.initState();
    // Se non c'è uno staff preselezionato, mostra tutti i servizi
    _showAllServices =
        widget.preselectedStaffServiceIds == null ||
        widget.preselectedStaffServiceIds!.isEmpty;

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

    // Filtra per staff preselezionato (se presente e checkbox non attivo)
    if (!_showAllServices &&
        widget.preselectedStaffServiceIds != null &&
        widget.preselectedStaffServiceIds!.isNotEmpty) {
      services = services
          .where((s) => widget.preselectedStaffServiceIds!.contains(s.id))
          .toList();
    }

    // Filtra per query di ricerca
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      services = services
          .where((s) => s.name.toLowerCase().contains(query))
          .toList();
    }

    return services;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final filteredServices = _filteredServices;

    final servicesByCategory = <int, List<Service>>{};
    for (final service in filteredServices) {
      (servicesByCategory[service.categoryId] ??= []).add(service);
    }

    final hasServicesMap = <int, bool>{
      for (final category in widget.categories)
        category.id: (servicesByCategory[category.id]?.isNotEmpty ?? false),
    };

    // Sort categories like services section:
    // 1) non-empty before empty, 2) sortOrder, 3) name
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

    // Filter active packages and sort by sortOrder
    var activePackages =
        (widget.packages ?? []).where((p) => p.isActive && !p.isBroken).toList()
          ..sort((a, b) {
            final so = a.sortOrder.compareTo(b.sortOrder);
            return so != 0
                ? so
                : a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

    // Filtra packages per staff preselezionato (se presente e checkbox non attivo)
    // Lo staff deve poter eseguire TUTTI i servizi inclusi nel pacchetto
    if (!_showAllServices &&
        widget.preselectedStaffServiceIds != null &&
        widget.preselectedStaffServiceIds!.isNotEmpty) {
      activePackages = activePackages.where((p) {
        final packageServiceIds = p.orderedServiceIds;
        return packageServiceIds.every(
          (serviceId) => widget.preselectedStaffServiceIds!.contains(serviceId),
        );
      }).toList();
    }

    // Filtra packages per ricerca
    final filteredPackages = _searchQuery.isEmpty
        ? activePackages
        : activePackages
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    final showPackages =
        filteredPackages.isNotEmpty && widget.onPackageSelected != null;

    final hasStaffFilter =
        widget.preselectedStaffServiceIds != null &&
        widget.preselectedStaffServiceIds!.isNotEmpty;

    // Mostra checkbox solo se lo staff non ha già tutti i servizi
    final staffHasAllServices =
        hasStaffFilter &&
        widget.preselectedStaffServiceIds!.length >= widget.services.length;
    final showAllServicesCheckbox = hasStaffFilter && !staffHasAllServices;

    // Mostra il campo di ricerca solo se ci sono più di 10 servizi
    // (conta i servizi dopo il filtro staff ma prima della ricerca)
    final servicesBeforeSearch =
        _showAllServices ||
            widget.preselectedStaffServiceIds == null ||
            widget.preselectedStaffServiceIds!.isEmpty
        ? widget.services.length
        : widget.services
              .where((s) => widget.preselectedStaffServiceIds!.contains(s.id))
              .length;
    final showSearchField =
        servicesBeforeSearch > 10 || _searchQuery.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            l10n.formService,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
        // Checkbox "Mostra tutti i servizi" (solo se c'è filtro staff e non ha già tutti)
        if (showAllServicesCheckbox) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _showAllServices,
                  onChanged: (value) {
                    setState(() {
                      _showAllServices = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAllServices = !_showAllServices;
                      });
                    },
                    child: Text(
                      l10n.showAllServices,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        const AppDivider(),
        // Service and packages list
        Expanded(
          child: filteredServices.isEmpty && filteredPackages.isEmpty
              ? Center(
                  child: Text(
                    l10n.noServicesFound,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  controller: _scrollController,
                  children: [
                    // Packages section (if available)
                    if (showPackages)
                      _PackagesSection(
                        packages: filteredPackages,
                        onSelected: widget.onPackageSelected!,
                      ),
                    // Popular services section (if available and search empty)
                    if (_searchQuery.isEmpty &&
                        widget.popularServices != null &&
                        widget.popularServices!.showPopularSection)
                      Builder(
                        builder: (context) {
                          // Filtra servizi popolari per staff preselezionato
                          var filteredPopular =
                              widget.popularServices!.popularServices;
                          if (!_showAllServices &&
                              widget.preselectedStaffServiceIds != null &&
                              widget.preselectedStaffServiceIds!.isNotEmpty) {
                            filteredPopular = filteredPopular
                                .where(
                                  (ps) => widget.preselectedStaffServiceIds!
                                      .contains(ps.serviceId),
                                )
                                .toList();
                          }
                          // Mostra sezione solo se ci sono servizi popolari dopo il filtro
                          if (filteredPopular.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return _PopularServicesSection(
                            popularServices: filteredPopular,
                            selectedId: widget.selectedId,
                            onSelected: widget.onSelected,
                          );
                        },
                      ),
                    // Categories and services
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
                            selectedId: widget.selectedId,
                            onSelected: widget.onSelected,
                          );
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// A section showing packages in a dedicated section.
class _PackagesSection extends StatelessWidget {
  const _PackagesSection({required this.packages, required this.onSelected});

  final List<ServicePackage> packages;
  final ValueChanged<ServicePackage> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final interactionColors = theme.extension<AppInteractionColors>();
    final evenBackgroundColor =
        interactionColors?.alternatingRowFill ??
        theme.colorScheme.onSurface.withOpacity(0.04);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Packages header with accent color
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          color: theme.colorScheme.secondary,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.widgets_outlined,
                  color: theme.colorScheme.onSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.servicePackagesTitle.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Package items with alternating background
        for (int i = 0; i < packages.length; i++)
          _buildPackageTile(
            context,
            packages[i],
            isEven: i.isEven,
            evenBackgroundColor: evenBackgroundColor,
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildPackageTile(
    BuildContext context,
    ServicePackage package, {
    required bool isEven,
    required Color evenBackgroundColor,
    required ThemeData theme,
  }) {
    final priceStr = package.effectivePrice > 0
        ? '€${package.effectivePrice.toStringAsFixed(2)}'
        : null;

    return Material(
      color: isEven ? evenBackgroundColor : Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(package),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.widgets_outlined,
                color: theme.colorScheme.secondary,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${package.serviceCount} ${package.serviceCount == 1 ? context.l10n.formService.toLowerCase() : context.l10n.bookingItems.toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (priceStr != null)
                Text(
                  priceStr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section showing the most popular (most booked) services.
class _PopularServicesSection extends StatelessWidget {
  const _PopularServicesSection({
    required this.popularServices,
    required this.selectedId,
    required this.onSelected,
  });

  final List<PopularService> popularServices;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final interactionColors = theme.extension<AppInteractionColors>();
    final evenBackgroundColor =
        interactionColors?.alternatingRowFill ??
        theme.colorScheme.onSurface.withOpacity(0.04);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with tertiary color (to distinguish from packages and categories)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          color: theme.colorScheme.tertiary,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  color: theme.colorScheme.onTertiary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.popularServicesTitle.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onTertiary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Popular service items with alternating background
        for (int i = 0; i < popularServices.length; i++)
          _buildPopularServiceTile(
            context,
            popularServices[i],
            isEven: i.isEven,
            evenBackgroundColor: evenBackgroundColor,
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildPopularServiceTile(
    BuildContext context,
    PopularService popularService, {
    required bool isEven,
    required Color evenBackgroundColor,
    required ThemeData theme,
  }) {
    final isSelected = popularService.serviceId == selectedId;

    return Material(
      color: isEven ? evenBackgroundColor : Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(popularService.serviceId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      popularService.serviceName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    // Mostra categoria solo se presente (significa che i servizi
                    // popolari appartengono a categorie diverse)
                    if (popularService.categoryName != null)
                      Text(
                        popularService.categoryName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section showing a category header and its services.
class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.services,
    required this.selectedId,
    required this.onSelected,
  });

  final ServiceCategory category;
  final List<Service> services;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Colore di sfondo leggero per i servizi con indice pari (even)
    final interactionColors = theme.extension<AppInteractionColors>();
    final evenBackgroundColor =
        interactionColors?.alternatingRowFill ??
        theme.colorScheme.onSurface.withOpacity(0.04);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category header with full-width background
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          color: theme.colorScheme.primary,
          child: Center(
            child: Text(
              category.name.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        // Services con sfondo alternato (even)
        for (int i = 0; i < services.length; i++)
          _buildServiceTile(
            context,
            services[i],
            isEven: i.isEven,
            evenBackgroundColor: evenBackgroundColor,
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildServiceTile(
    BuildContext context,
    Service service, {
    required bool isEven,
    required Color evenBackgroundColor,
    required ThemeData theme,
  }) {
    final isSelected = service.id == selectedId;
    return Material(
      color: isEven ? evenBackgroundColor : Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(service.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(service.name)),
              if (isSelected)
                Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
