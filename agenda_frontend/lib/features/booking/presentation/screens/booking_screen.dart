import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/locations_provider.dart';
import '../widgets/booking_step_indicator.dart';
import 'confirmation_step.dart';
import 'date_time_step.dart';
import 'location_step.dart';
import 'services_step.dart';
import 'staff_step.dart';
import 'summary_step.dart';

class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(currentBusinessProvider);
    final config = ref.watch(bookingConfigProvider);
    final l10n = context.l10n;

    // Se il business è in caricamento, mostra loading
    if (businessAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.bookingTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Se c'è un errore nel caricamento del business
    if (businessAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.bookingTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n.errorGeneric,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(currentBusinessProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.actionRetry),
              ),
            ],
          ),
        ),
      );
    }

    // Se la config non è valida (business o location mancanti)
    if (!config.isValid) {
      // Distingui tra "business non trovato" e "business non attivo"
      final isNotActive = config.businessExistsButNotActive;
      final title = isNotActive
          ? l10n.errorBusinessNotActive
          : l10n.errorBusinessNotFound;
      final subtitle = isNotActive
          ? l10n.errorBusinessNotActiveSubtitle
          : l10n.errorBusinessNotFoundSubtitle;
      final icon = isNotActive ? Icons.schedule : Icons.storefront_outlined;

      return Scaffold(
        appBar: AppBar(title: Text(l10n.bookingTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal booking flow
    final bookingState = ref.watch(bookingFlowProvider);
    final hasMultipleLocations = ref.watch(hasMultipleLocationsProvider);
    final isAuthenticated = ref.watch(
      authProvider.select((state) => state.isAuthenticated),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookingTitle),
        leading: bookingState.canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    ref.read(bookingFlowProvider.notifier).previousStep(),
              )
            : null,
        actions: [
          if (isAuthenticated)
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle_outlined),
              tooltip: l10n.profileTitle,
              onSelected: (value) {
                switch (value) {
                  case 'bookings':
                    context.go('/my-bookings');
                  case 'profile':
                    context.push('/profile');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'bookings',
                  child: ListTile(
                    leading: const Icon(Icons.event_note),
                    title: Text(l10n.myBookings),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'profile',
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(l10n.profileTitle),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Step indicator
          if (bookingState.currentStep != BookingStep.confirmation)
            BookingStepIndicator(
              currentStep: bookingState.currentStep,
              allowStaffSelection: config.allowStaffSelection,
              showLocationStep: hasMultipleLocations,
              onStepTap: (step) {
                ref.read(bookingFlowProvider.notifier).goToStep(step);
              },
            ),

          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStepContent(bookingState.currentStep),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BookingStep step) {
    switch (step) {
      case BookingStep.location:
        return const LocationStep();
      case BookingStep.services:
        return const ServicesStep();
      case BookingStep.staff:
        return const StaffStep();
      case BookingStep.dateTime:
        return const DateTimeStep();
      case BookingStep.summary:
        return const SummaryStep();
      case BookingStep.confirmation:
        return const ConfirmationStep();
    }
  }
}
