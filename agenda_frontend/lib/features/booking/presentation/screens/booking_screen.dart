import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/app_loading_screen.dart';
import '../../../../core/widgets/booking_app_bar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../booking/providers/business_provider.dart';
import '../../providers/booking_direct_link_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/class_events_provider.dart';
import '../../providers/locations_provider.dart';
import '../widgets/booking_step_indicator.dart';
import 'confirmation_step.dart';
import 'date_time_step.dart';
import 'location_step.dart';
import 'services_step.dart';
import 'staff_step.dart';
import 'summary_step.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  bool _redirectingWrongBusiness = false;
  String? _appliedDirectLinkLocationSlug;

  Future<void> _redirectToRegisterForBusiness({
    required int authenticatedBusinessId,
    required String? slug,
  }) async {
    if (_redirectingWrongBusiness) return;
    _redirectingWrongBusiness = true;

    await ref
        .read(authProvider.notifier)
        .logout(businessId: authenticatedBusinessId);
    if (!mounted || !context.mounted) return;
    final businessSlug = slug ?? '';
    if (businessSlug.isEmpty) return;
    final params = <String, String>{'from': 'booking', 'force': '1'};
    final linkSlug = ref.read(bookingDirectLinkSlugProvider);
    if (linkSlug != null && linkSlug.isNotEmpty) {
      params['link'] = linkSlug;
    }
    final query = Uri(queryParameters: params).query;
    context.go('/$businessSlug/register?$query');
  }

  @override
  Widget build(BuildContext context) {
    // Always-needed watches — must come before any conditional return
    final businessAsync = ref.watch(currentBusinessProvider);
    final config = ref.watch(bookingConfigProvider);
    final authState = ref.watch(authProvider);
    final businessSlug = ref.watch(businessSlugProvider);
    final authenticatedBusinessIdAsync = ref.watch(
      authenticatedBusinessIdProvider,
    );
    final l10n = context.l10n;
    final linkSlug = ref.watch(bookingDirectLinkSlugProvider);
    final urlLocationId = ref.watch(urlLocationIdProvider);

    // Guard: il router aggiorna bookingDirectLinkSlugProvider via Future.microtask,
    // quindi per UN FRAME il provider può essere null anche se l'URL ha già ?link=.
    // GoRouterState.of(context).uri è sempre sincrono con l'URL corrente.
    // Se il link è nell'URL ma il provider non è ancora aggiornato, mostriamo
    // loading per evitare il flash dello step sede.
    final currentUri = GoRouterState.of(context).uri;
    final rawLinkSlug = currentUri.queryParameters['link'];
    if (rawLinkSlug != null && rawLinkSlug.isNotEmpty && linkSlug == null) {
      return const AppLoadingScreen();
    }

    // Auth redirect
    final currentBusinessId = businessAsync.value?.id;
    final authenticatedBusinessId = authenticatedBusinessIdAsync.value;
    final isWrongBusinessAuthenticated =
        authState.isAuthenticated &&
        currentBusinessId != null &&
        authenticatedBusinessId != null &&
        currentBusinessId != authenticatedBusinessId;

    if (isWrongBusinessAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectToRegisterForBusiness(
          authenticatedBusinessId: authenticatedBusinessId,
          slug: businessSlug,
        );
      });
      return const AppLoadingScreen();
    }

    if (businessAsync.isLoading) {
      return const AppLoadingScreen();
    }

    if (businessAsync.hasError) {
      return Scaffold(
        appBar: const BookingAppBar(showUserMenu: false),
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

    if (!config.isValid) {
      final isNotActive = config.businessExistsButNotActive;
      final title = isNotActive
          ? l10n.errorBusinessNotActive
          : l10n.errorBusinessNotFound;
      final subtitle = isNotActive
          ? l10n.errorBusinessNotActiveSubtitle
          : l10n.errorBusinessNotFoundSubtitle;
      final icon = isNotActive ? Icons.schedule : Icons.storefront_outlined;

      return Scaffold(
        appBar: const BookingAppBar(showUserMenu: false),
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

    // Direct link error screen (shared by missing-location and mismatch cases)
    Widget buildDirectLinkErrorScreen() => Scaffold(
      appBar: const BookingAppBar(showUserMenu: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link_off,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((0.4 * 255).round()),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.errorDirectLinkInvalidTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.errorDirectLinkInvalidMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final slug = businessSlug ?? '';
                  if (slug.isEmpty) return;
                  context.go('/$slug/booking');
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.actionBackToBooking),
              ),
            ],
          ),
        ),
      ),
    );

    // link presente ma location assente → errore immediato, zero chiamate a /resolve
    if (linkSlug != null && (urlLocationId == null || urlLocationId <= 0)) {
      return buildDirectLinkErrorScreen();
    }

    // link presente con location → controlla stato resolve PRIMA di watchare
    // bookingDirectLinkProvider direttamente, così in caso di errore/mismatch
    // BookingScreen non è un watcher diretto del provider
    if (linkSlug != null) {
      final isDirectLinkBlockingError = ref.watch(
        bookingDirectLinkBlockingErrorProvider,
      );
      if (isDirectLinkBlockingError) {
        return buildDirectLinkErrorScreen();
      }

      final isDirectLinkResolving = ref.watch(
        bookingDirectLinkIsResolvingProvider,
      );
      if (isDirectLinkResolving) {
        return const Scaffold(
          appBar: BookingAppBar(showUserMenu: false),
          body: Center(child: CircularProgressIndicator()),
        );
      }
    }

    // Qui il direct link è assente o risolto correttamente.
    // È sicuro watchare bookingDirectLinkProvider (una sola volta, solo in questo path).
    final directLinkAsync = ref.watch(bookingDirectLinkProvider);
    final locationsAsync = ref.watch(locationsProvider);

    final directLink = directLinkAsync.value;
    final targetLocationId = _intFromJson(directLink?.target['location_id']);
    if (directLink != null &&
        targetLocationId != null &&
        _appliedDirectLinkLocationSlug != directLink.linkSlug) {
      final locations = locationsAsync.value;
      if (locations != null) {
        for (final location in locations) {
          if (location.id == targetLocationId) {
            _appliedDirectLinkLocationSlug = directLink.linkSlug;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ref.read(selectedLocationProvider.notifier).select(location);
            });
            break;
          }
        }
      }
    }

    // Normal booking flow
    final bookingState = ref.watch(bookingFlowProvider);
    final hasMultipleLocations = ref.watch(hasMultipleLocationsProvider);
    final hideStaffAndDateTime =
        ref.watch(isEventOnlyModeProvider) ||
        bookingState.request.isClassEventBooking;
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
        appBar: BookingAppBar(
          showBackButton: showBackButton,
          onBackPressed: () =>
              ref.read(bookingFlowProvider.notifier).previousStep(),
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
                          hideStaffAndDateTime: hideStaffAndDateTime,
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

  int? _intFromJson(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
