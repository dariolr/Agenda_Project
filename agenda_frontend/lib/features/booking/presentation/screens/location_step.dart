import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/location.dart';
import '../../../../core/widgets/centered_error_view.dart';
import '../../providers/booking_nomenclature_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/locations_provider.dart';
import '../booking_step_layout.dart';

class LocationStep extends ConsumerWidget {
  const LocationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final customLocationLabel = ref.watch(bookingLocationDisplayLabelProvider);
    final phraseOverrides = ref.watch(
      bookingTextOverridesForLocaleProvider(Localizations.localeOf(context)),
    );
    final locationsAsync = ref.watch(locationsProvider);
    final flowLocations = ref.watch(bookableLocationsForCurrentFlowProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);
    final isLoading = locationsAsync.isLoading;

    if (locationsAsync.hasError) {
      return CenteredErrorView(
        title: l10n.errorGeneric,
        onRetry: () => ref.read(locationsProvider.notifier).refresh(),
        retryLabel: l10n.actionRetry,
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kBookingStepHorizontalMargin,
                12,
                kBookingStepHorizontalMargin,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookingLocationTitle(
                      context,
                      customLocationLabel,
                      phraseOverrides: phraseOverrides,
                    ),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bookingLocationSubtitle(
                      context,
                      customLocationLabel,
                      phraseOverrides: phraseOverrides,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Lista locations
            Expanded(
              child: locationsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
                data: (_) {
                  final locations = flowLocations;
                  if (locations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            bookingLocationEmptyLabel(
                              context,
                              customLocationLabel,
                              phraseOverrides: phraseOverrides,
                            ),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  // Il footer fisso è alto ~72px; aggiunge viewPadding.bottom
                  // per la gesture bar Android così l'ultimo item è sempre visibile.
                  final bottomInset =
                      MediaQuery.of(context).viewPadding.bottom + 72 + 24;
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      kBookingStepHorizontalMargin,
                      0,
                      kBookingStepHorizontalMargin,
                      bottomInset,
                    ),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      final isSelected = selectedLocation?.id == location.id;

                      return _LocationCard(
                        location: location,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(selectedLocationProvider.notifier)
                              .select(location);
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Footer con bottone
            _buildFooter(context, ref, selectedLocation),
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

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    Location? selectedLocation,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

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
        child: ElevatedButton(
          onPressed: selectedLocation != null
              ? () => ref.read(bookingFlowProvider.notifier).nextStep()
              : null,
          child: Text(l10n.actionNext),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Location location;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationCard({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icona location
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.35)
                        : theme.dividerColor.withOpacity(0.8),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),

              // Info location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            location.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (location.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Principale',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (location.formattedAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        location.formattedAddress,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                    if (location.phone != null &&
                        location.phone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location.phone!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Checkmark se selezionato
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
