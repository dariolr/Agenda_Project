import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/network/api_client.dart';
import '../../providers/booking_provider.dart';

class ServicesStep extends ConsumerWidget {
  const ServicesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('BUILD ServicesStep');
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final servicesDataAsync = ref.watch(servicesDataProvider);
    final bookingState = ref.watch(bookingFlowProvider);
    final selectedServices = bookingState.request.services;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.servicesTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildErrorWidget(context, ref, e),
            data: (data) {
              if (data.isEmpty) {
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
                selectedServices,
              );
            },
          ),
        ),

        // Footer con selezione e bottone
        _buildFooter(context, ref, selectedServices),
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
      onRetry: showRetry ? () => ref.invalidate(servicesDataProvider) : null,
    );
  }

  Widget _buildServicesList(
    BuildContext context,
    WidgetRef ref,
    List<ServiceCategory> categories,
    List<Service> services,
    List<Service> selectedServices,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryServices =
            services
                .where((s) => s.categoryId == category.id && s.isBookableOnline)
                .toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        if (categoryServices.isEmpty) return const SizedBox.shrink();

        return _CategorySection(
          category: category,
          services: categoryServices,
          selectedServices: selectedServices,
          onServiceTap: (service) {
            ref.read(bookingFlowProvider.notifier).toggleService(service);
          },
        );
      },
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
                  l10n.servicesSelected(selectedServices.length),
                  style: theme.textTheme.bodyMedium,
                ),
                if (selectedServices.isNotEmpty)
                  Text(
                    bookingState.request.formattedTotalPrice,
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
                  ? () => ref.read(bookingFlowProvider.notifier).nextStep()
                  : null,
              child: Text(l10n.actionNext),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final ServiceCategory category;
  final List<Service> services;
  final List<Service> selectedServices;
  final void Function(Service) onServiceTap;

  const _CategorySection({
    required this.category,
    required this.services,
    required this.selectedServices,
    required this.onServiceTap,
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
        ...services.map((service) {
          final isSelected = selectedServices.any((s) => s.id == service.id);
          return _ServiceTile(
            service: service,
            isSelected: isSelected,
            onTap: () => onServiceTap(service),
          );
        }),
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
    final l10n = context.l10n;

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
                      l10n.servicesDuration(service.durationMinutes),
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
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.actionRetry),
              ),
            ],
          ],
        ),
      ),
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
