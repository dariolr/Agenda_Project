import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/models/service_package.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/centered_error_view.dart';
import '../../providers/booking_provider.dart';

class ServicesStep extends ConsumerStatefulWidget {
  const ServicesStep({super.key});

  @override
  ConsumerState<ServicesStep> createState() => _ServicesStepState();
}

class _ServicesStepState extends ConsumerState<ServicesStep> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final servicesDataAsync = ref.watch(servicesDataProvider);
    final packagesAsync = ref.watch(servicePackagesProvider);
    final bookingState = ref.watch(bookingFlowProvider);
    final selectedServices = bookingState.request.services;
    final isLoading = servicesDataAsync.isLoading;

    if (servicesDataAsync.hasError) {
      return _buildErrorWidget(context, ref, servicesDataAsync.error!);
    }

    return Stack(
      children: [
        Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.servicesTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.servicesSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Lista servizi per categoria (singola chiamata API)
            Expanded(
              child: servicesDataAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
                data: (data) {
                  final packages =
                      packagesAsync.value ?? const <ServicePackage>[];
                  if (data.bookableServices.isEmpty && packages.isEmpty) {
                    return _EmptyView(
                      title: l10n.servicesEmpty,
                      subtitle: l10n.servicesEmptySubtitle,
                    );
                  }

                  return _buildServicesList(
                    context,
                    ref,
                    data.categories,
                    data.bookableServices,
                    data.serviceIdsWithEligibleStaff,
                    data.services,
                    bookingState.request.selectedServiceIds,
                    bookingState.request.selectedPackageIds,
                    selectedServices,
                    packagesAsync,
                  );
                },
              ),
            ),

            // Footer con selezione e bottone
            _buildFooter(context, ref, selectedServices),
          ],
        ),
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: theme.colorScheme.surface.withOpacity(0.6),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  /// Costruisce il widget di errore appropriato in base al tipo di errore
  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object error) {
    final l10n = context.l10n;

    // Determina titolo e sottotitolo in base al tipo di errore
    String title;
    String subtitle;
    IconData icon;
    bool showRetry;

    if (error is ApiException) {
      if (error.isLocationNotFound) {
        title = l10n.errorLocationNotFound;
        subtitle = l10n.errorLocationNotFoundSubtitle;
        icon = Icons.location_off_outlined;
        showRetry = false;
      } else if (error.isBusinessNotFound) {
        title = l10n.errorBusinessNotFound;
        subtitle = l10n.errorBusinessNotFoundSubtitle;
        icon = Icons.store_outlined;
        showRetry = false;
      } else if (error.isServiceUnavailable) {
        title = l10n.errorServiceUnavailable;
        subtitle = l10n.errorServiceUnavailableSubtitle;
        icon = Icons.cloud_off_outlined;
        showRetry = true;
      } else {
        title = l10n.errorLoadingServices;
        subtitle = error.message;
        icon = Icons.error_outline;
        showRetry = true;
      }
    } else {
      title = l10n.errorLoadingServices;
      subtitle = '';
      icon = Icons.cloud_off_outlined;
      showRetry = true;
    }

    return _ErrorView(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onRetry: showRetry
          ? () => ref.read(servicesDataProvider.notifier).refresh()
          : null,
    );
  }

  Widget _buildServicesList(
    BuildContext context,
    WidgetRef ref,
    List<ServiceCategory> categories,
    List<Service> services,
    Set<int> serviceIdsWithEligibleStaff,
    List<Service> allServices,
    Set<int> selectedServiceIds,
    Set<int> selectedPackageIds,
    List<Service> selectedServices,
    AsyncValue<List<ServicePackage>> packagesAsync,
  ) {
    final widgets = <Widget>[];
    final packages = packagesAsync.value ?? [];
    final visibleServiceIds = services.map((s) => s.id).toSet();
    final visiblePackages = packages.where((package) {
      if (!package.isActive || package.isBroken) return false;
      final packageServiceIds = package.orderedServiceIds;
      if (packageServiceIds.isEmpty) return false;
      return packageServiceIds.every(
        (serviceId) =>
            visibleServiceIds.contains(serviceId) &&
            serviceIdsWithEligibleStaff.contains(serviceId),
      );
    }).toList();
    final serviceById = {for (final s in allServices) s.id: s};
    final l10n = context.l10n;

    if (packagesAsync.hasError) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            context.l10n.servicePackagesLoadError,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    final categoryIds = categories.map((c) => c.id).toSet();
    final maxSortOrder = categories.fold<int>(
      -1,
      (max, c) => c.sortOrder > max ? c.sortOrder : max,
    );
    var extraIndex = 0;
    final extraCategories = <ServiceCategory>[];
    for (final package in visiblePackages) {
      final packageCategoryId = package.categoryId;
      if (packageCategoryId <= 0 || categoryIds.contains(packageCategoryId)) {
        continue;
      }
      final name =
          (package.categoryName != null &&
              package.categoryName!.trim().isNotEmpty)
          ? package.categoryName!
          : l10n.servicesCategoryFallbackName(packageCategoryId);
      extraCategories.add(
        ServiceCategory(
          id: packageCategoryId,
          businessId: 0,
          name: name,
          sortOrder: maxSortOrder + 1 + extraIndex++,
        ),
      );
      categoryIds.add(packageCategoryId);
    }

    final allCategories = [...categories, ...extraCategories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final category in allCategories) {
      final categoryServices =
          services
              .where((s) => s.categoryId == category.id && s.isBookableOnline)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final categoryPackages =
          visiblePackages.where((p) {
            final effectiveCategoryId = p.categoryId != 0
                ? p.categoryId
                : (p.items.isNotEmpty
                      ? serviceById[p.items.first.serviceId]?.categoryId
                      : null);
            return effectiveCategoryId == category.id;
          }).toList()..sort((a, b) {
            final so = a.sortOrder.compareTo(b.sortOrder);
            return so != 0
                ? so
                : a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

      final categoryEntries =
          <_CategoryEntry>[
            for (final service in categoryServices)
              _CategoryEntry.service(service),
            for (final package in categoryPackages)
              _CategoryEntry.package(package),
          ]..sort((a, b) {
            final so = a.sortOrder.compareTo(b.sortOrder);
            return so != 0
                ? so
                : a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

      if (categoryEntries.isEmpty) continue;

      widgets.add(
        _CategorySection(
          category: category,
          entries: categoryEntries,
          selectedServiceIds: selectedServiceIds,
          selectedPackageIds: selectedPackageIds,
          selectedServices: selectedServices,
          onServiceTap: (service) {
            ref.read(bookingFlowProvider.notifier).toggleService(service);
          },
          onPackageTap: (package) {
            ref
                .read(bookingFlowProvider.notifier)
                .togglePackageSelection(package, services);
          },
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: widgets,
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    List<Service> selectedServices,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bookingState = ref.watch(bookingFlowProvider);
    final totals = ref.watch(bookingTotalsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info selezione
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.servicesSelected(totals.selectedItemCount),
                  style: theme.textTheme.bodyMedium,
                ),
                if (selectedServices.isNotEmpty)
                  Text(
                    _formatTotalPrice(context, totals.totalPrice),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottone avanti
            ElevatedButton(
              onPressed: bookingState.canGoNext
                  ? () => ref
                        .read(bookingFlowProvider.notifier)
                        .nextFromServicesWithAutoStaff()
                  : null,
              child: Text(l10n.actionNext),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTotalPrice(BuildContext context, double totalPrice) {
    final l10n = context.l10n;
    if (totalPrice == 0) return l10n.servicesFree;
    return '€${totalPrice.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _CategorySection extends StatelessWidget {
  final ServiceCategory category;
  final List<_CategoryEntry> entries;
  final Set<int> selectedServiceIds;
  final Set<int> selectedPackageIds;
  final List<Service> selectedServices;
  final void Function(Service) onServiceTap;
  final void Function(ServicePackage) onPackageTap;

  const _CategorySection({
    required this.category,
    required this.entries,
    required this.selectedServiceIds,
    required this.selectedPackageIds,
    required this.selectedServices,
    required this.onServiceTap,
    required this.onPackageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            category.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final entry in entries)
          if (entry.isPackage)
            _PackageTile(
              package: entry.package!,
              isSelected: selectedPackageIds.contains(entry.package!.id),
              isDisabled: !entry.package!.isActive || entry.package!.isBroken,
              onTap: (!entry.package!.isActive || entry.package!.isBroken)
                  ? null
                  : () => onPackageTap(entry.package!),
            )
          else
            _ServiceTile(
              service: entry.service!,
              isSelected: selectedServiceIds.contains(entry.service!.id),
              onTap: () => onServiceTap(entry.service!),
            ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Service service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              // Info servizio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.localizedDurationLabel(service.totalDurationMinutes),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Prezzo
              Text(
                service.formattedPrice,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryEntry {
  final Service? service;
  final ServicePackage? package;

  const _CategoryEntry._({this.service, this.package});

  const _CategoryEntry.service(Service service) : this._(service: service);

  const _CategoryEntry.package(ServicePackage package)
    : this._(package: package);

  bool get isPackage => package != null;

  int get sortOrder => service?.sortOrder ?? package!.sortOrder;

  String get name => service?.name ?? package!.name;
}

class _PackageTile extends StatelessWidget {
  final ServicePackage package;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _PackageTile({
    required this.package,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final price = package.effectivePrice;
    final priceLabel = price == 0
        ? l10n.servicesFree
        : '€${price.toStringAsFixed(2).replaceAll('.', ',')}';

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              package.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.localizedDurationLabel(
                          package.effectiveDurationMinutes,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  priceLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget per mostrare errori con bottone retry
class _ErrorView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onRetry;

  const _ErrorView({
    required this.title,
    this.subtitle = '',
    this.icon = Icons.cloud_off_outlined,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return CenteredErrorView(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onRetry: onRetry,
      retryLabel: context.l10n.actionRetry,
    );
  }
}

/// Widget per mostrare stato vuoto
class _EmptyView extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyView({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
