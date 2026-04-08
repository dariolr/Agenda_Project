import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/route_slug_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/network/network_providers.dart';
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Icona successo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 32),

            // Titolo
            Text(
              l10n.confirmationTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Sottotitolo
            Text(
              l10n.confirmationSubtitle,
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
                final locationId = ref.read(effectiveLocationProvider)?.id;
                ref.read(bookingFlowProvider.notifier).reset();
                if (locationId != null) {
                  context.go('/$slug/booking?location=$locationId');
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
