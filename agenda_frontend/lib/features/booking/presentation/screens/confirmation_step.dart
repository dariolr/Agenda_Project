import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/route_slug_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/network/network_providers.dart';
import '../../providers/booking_direct_link_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/locations_provider.dart';

class ConfirmationStep extends ConsumerStatefulWidget {
  const ConfirmationStep({super.key});

  @override
  ConsumerState<ConfirmationStep> createState() => _ConfirmationStepState();
}

class _ConfirmationStepState extends ConsumerState<ConfirmationStep> {
  bool _showFirstFiveHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final shouldShow = await _shouldShowFirstFiveHint();
      if (!mounted) return;
      setState(() => _showFirstFiveHint = shouldShow);
    });
  }

  Future<bool> _shouldShowFirstFiveHint() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getCustomerBookings();
      final upcoming = response['upcoming'] as List<dynamic>? ?? const [];
      final past = response['past'] as List<dynamic>? ?? const [];
      final allBookings = [...upcoming, ...past];

      final totalBookings = allBookings.where((booking) {
        if (booking is! Map<String, dynamic>) return false;
        final status = booking['status']?.toString();
        return status != 'replaced';
      }).length;

      return totalBookings <= 5;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bookingState = ref.watch(bookingFlowProvider);
    final isWaitlisted =
        bookingState.confirmedClassBookingStatus == 'waitlisted';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Icona successo / lista d'attesa
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isWaitlisted
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
              ),
              child: Icon(
                isWaitlisted ? Icons.hourglass_top_rounded : Icons.check_circle,
                size: 64,
                color: isWaitlisted ? Colors.orange.shade700 : Colors.green,
              ),
            ),
            const SizedBox(height: 32),

            // Titolo
            Text(
              isWaitlisted ? l10n.confirmationWaitlistTitle : l10n.confirmationTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Sottotitolo
            Text(
              isWaitlisted
                  ? l10n.confirmationWaitlistSubtitle
                  : l10n.confirmationSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Codice prenotazione + hint "prime 5 prenotazioni" nello stesso box
            if (bookingState.confirmedBookingId != null || _showFirstFiveHint)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (bookingState.confirmedBookingId != null)
                      Text(
                        l10n.confirmationBookingId(bookingState.confirmedBookingId!),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    if (bookingState.confirmedBookingId != null &&
                        _showFirstFiveHint)
                      const SizedBox(height: 24),
                    if (_showFirstFiveHint)
                      Text(
                        l10n.confirmationPostRegistrationMyBookingsHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),

            const Spacer(),

            // Bottoni azioni
            ElevatedButton(
              onPressed: () {
                final slug = ref.read(routeSlugProvider);
                final directLinkSlug = ref.read(bookingDirectLinkSlugProvider);
                final urlLocationId = ref.read(urlLocationIdProvider);
                final location = ref.read(effectiveLocationProvider);
                final hasMultipleLocations = ref.read(
                  hasMultipleLocationsProvider,
                );
                ref.read(bookingFlowProvider.notifier).reset();

                // Se la prenotazione corrente e' stata creata da un direct link,
                // preserva i query param location e link nella navigazione.
                if (directLinkSlug != null && urlLocationId != null) {
                  context.go(
                    '/$slug/booking?location=$urlLocationId&link=$directLinkSlug',
                  );
                } else if (hasMultipleLocations) {
                  // Su business multi-location la nuova prenotazione deve
                  // ripartire dalla scelta sede.
                  ref.read(urlLocationIdProvider.notifier).state = null;
                  ref.read(selectedLocationProvider.notifier).clear();
                  context.go('/$slug/booking');
                } else if (location != null) {
                  // Re-applica subito la location nel nuovo flow per mantenere
                  // anche la regola "allow_customer_choose_staff".
                  ref.read(urlLocationIdProvider.notifier).state = location.id;
                  ref.read(selectedLocationProvider.notifier).select(location);
                  context.go('/$slug/booking?location=${location.id}');
                } else {
                  context.go('/$slug/booking');
                }
              },
              child: Text(l10n.confirmationNewBooking),
            ),
          ],
        ),
      ),
    );
  }
}
