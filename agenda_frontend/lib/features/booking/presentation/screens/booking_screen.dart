import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/providers/route_slug_provider.dart';
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
    final slug = ref.watch(routeSlugProvider);
    final isMobile =
        _formFactorForWidth(MediaQuery.of(context).size.width) ==
        AppFormFactor.mobile;

    // Determina se mostrare il back button
    // Se c'è una sola location e siamo su services, non mostrare back
    final showBackButton =
        bookingState.canGoBack &&
        !(bookingState.currentStep == BookingStep.services &&
            !hasMultipleLocations);

    return PopScope(
      canPop: !(isMobile && showBackButton),
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (isMobile && showBackButton) {
          ref.read(bookingFlowProvider.notifier).previousStep();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.bookingTitle),
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      ref.read(bookingFlowProvider.notifier).previousStep(),
                )
              : null,
          actions: [
            if (isAuthenticated && slug != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle_outlined),
                tooltip: l10n.profileTitle,
                onSelected: (value) async {
                  switch (value) {
                    case 'bookings':
                      context.go('/$slug/my-bookings');
                    case 'profile':
                      context.push('/$slug/profile');
                    case 'logout':
                      final businessId = ref.read(currentBusinessIdProvider);
                      if (businessId != null) {
                        await ref
                            .read(authProvider.notifier)
                            .logout(businessId: businessId);
                      }
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
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(l10n.actionLogout),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(formFactorProvider.notifier)
                  .update(constraints.maxWidth);
            });
            final formFactor = _formFactorForWidth(constraints.maxWidth);
            final maxWidth = switch (formFactor) {
              AppFormFactor.desktop => 980.0,
              AppFormFactor.tablet => 760.0,
              AppFormFactor.mobile => double.infinity,
            };
            final horizontalPadding = switch (formFactor) {
              AppFormFactor.desktop => 32.0,
              AppFormFactor.tablet => 24.0,
              AppFormFactor.mobile => 0.0,
            };

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      // Step indicator
                      if (bookingState.currentStep != BookingStep.confirmation)
                        BookingStepIndicator(
                          currentStep: bookingState.currentStep,
                          allowStaffSelection: config.allowStaffSelection,
                          showLocationStep: hasMultipleLocations,
                          onStepTap: (step) {
                            ref
                                .read(bookingFlowProvider.notifier)
                                .goToStep(step);
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  AppFormFactor _formFactorForWidth(double width) {
    if (width >= 1024) return AppFormFactor.desktop;
    if (width >= 600) return AppFormFactor.tablet;
    return AppFormFactor.mobile;
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
