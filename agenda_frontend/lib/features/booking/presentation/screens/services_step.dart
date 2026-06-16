import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/class_event.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/models/service_package.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/centered_error_view.dart';
import '../../domain/booking_direct_link.dart';
import '../../providers/booking_direct_link_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/locations_provider.dart';
import '../../providers/booking_nomenclature_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/class_events_provider.dart';
import '../../providers/my_bookings_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class ServicesStep extends ConsumerStatefulWidget {
  const ServicesStep({super.key});

  @override
  ConsumerState<ServicesStep> createState() => _ServicesStepState();
}

class _ServicesStepState extends ConsumerState<ServicesStep>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _hasRequestedBookingsLoad = false;
  String? _appliedDirectLinkSlug;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Quando l'utente cambia tab manualmente, aggiorna lo stato per il footer
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customServiceLabel = ref.watch(bookingServiceDisplayLabelProvider);
    final phraseOverrides = ref.watch(
      bookingTextOverridesForLocaleProvider(Localizations.localeOf(context)),
    );
    final servicesDataAsync = ref.watch(servicesDataProvider);
    final packagesAsync = ref.watch(servicePackagesProvider);
    final classEventsAsync = ref.watch(filteredClassEventsProvider);
    final directLink = ref.watch(bookingDirectLinkProvider).value;
    final bookingConstraint = _BookingLinkConstraint.fromDirectLink(directLink);
    final bookingState = ref.watch(bookingFlowProvider);
    final selectedServices = bookingState.request.services;
    final isLoading = servicesDataAsync.isLoading || classEventsAsync.isLoading;

    // Carica le prenotazioni esistenti dell'utente (se autenticato) per
    // impedire di prenotare due volte lo stesso evento.
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    if (isAuthenticated && !_hasRequestedBookingsLoad) {
      _hasRequestedBookingsLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(myBookingsProvider.notifier).loadBookings();
      });
    }
    final bookedEventStatus = ref.watch(bookedClassEventStatusProvider);
    final location = ref.watch(effectiveLocationProvider);
    final allowMultiServiceBooking = ref.watch(
      allowMultiServiceBookingProvider,
    );
    final showPriceToCustomer = location?.showPriceToCustomer ?? true;
    final showDurationToCustomer = location?.showDurationToCustomer ?? true;

    if (servicesDataAsync.hasError) {
      return _buildErrorWidget(
        context,
        ref,
        servicesDataAsync.error!,
        customServiceLabel,
        phraseOverrides,
      );
    }

    final packages = packagesAsync.value ?? const <ServicePackage>[];
    final servicesData = servicesDataAsync.value;
    final visibleServicesData = servicesData == null
        ? null
        : ServicesData(
            categories: servicesData.categories,
            services: servicesData.services
                .where(bookingConstraint.allowsService)
                .toList(),
          );
    final visiblePackages = packages
        .where(bookingConstraint.allowsPackage)
        .toList();
    final visibleClassEvents = (classEventsAsync.value ?? const <ClassEvent>[])
        .where(bookingConstraint.allowsEvent)
        .toList();
    final hasServices =
        (visibleServicesData?.bookableServices.isNotEmpty ?? false) ||
        visiblePackages.isNotEmpty;
    final hasClassEvents = visibleClassEvents.isNotEmpty;
    final showBothTabs = hasServices && hasClassEvents;
    final isClassTab = showBothTabs && _tabController.index == 1;

    _applyDirectLinkSelectionIfReady(
      directLink: directLink,
      servicesData: visibleServicesData,
      packages: visiblePackages,
      classEvents: visibleClassEvents,
      showBothTabs: showBothTabs,
    );

    // Se non ci sono entrambi i tipi, torna al tab 0
    if (!showBothTabs && _tabController.index != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.animateTo(0);
      });
    }

    final headerSubtitle = showBothTabs
        ? bookingServicesAndEventsSubtitle(
            context,
            phraseOverrides: phraseOverrides,
          )
        : hasClassEvents
        ? bookingEventsSubtitle(context, phraseOverrides: phraseOverrides)
        : allowMultiServiceBooking
        ? bookingServicesSubtitle(
            context,
            customServiceLabel,
            phraseOverrides: phraseOverrides,
          )
        : null;

    Widget buildServicesContent() {
      if (bookingState.request.isClassEventBooking) {
        return _ConflictView(
          title: bookingTabConflictServicesTitle(
            context,
            phraseOverrides: phraseOverrides,
          ),
          subtitle: bookingTabConflictServicesSubtitle(
            context,
            bookingState.request.selectedClassEvent!.classTypeName,
            phraseOverrides: phraseOverrides,
          ),
        );
      }
      if (visibleServicesData == null) return const SizedBox.shrink();
      if (visibleServicesData.bookableServices.isEmpty &&
          visiblePackages.isEmpty) {
        return _EmptyView(
          title: bookingServicesEmptyTitle(
            context,
            customServiceLabel,
            phraseOverrides: phraseOverrides,
          ),
          subtitle: bookingServicesEmptySubtitle(
            context,
            customServiceLabel,
            phraseOverrides: phraseOverrides,
          ),
        );
      }
      return _buildServicesList(
        context,
        ref,
        visibleServicesData.categories,
        visibleServicesData.bookableServices,
        visibleServicesData.serviceIdsWithEligibleStaff,
        servicesData!.services,
        bookingState.request.selectedServiceIds,
        bookingState.request.selectedPackageIds,
        selectedServices,
        AsyncValue.data(visiblePackages),
        phraseOverrides,
        bookingConstraint: bookingConstraint,
        showPriceToCustomer: showPriceToCustomer,
        showDurationToCustomer: showDurationToCustomer,
      );
    }

    late final Widget content;
    if (showBothTabs) {
      content = TabBarView(
        controller: _tabController,
        children: [
          buildServicesContent(),
          _buildClassEventsTab(
            context,
            ref,
            AsyncValue.data(visibleClassEvents),
            bookingState.request.selectedClassEvent,
            bookingConstraint: bookingConstraint,
            hasSelectedServices: selectedServices.isNotEmpty,
            bookedEventStatus: bookedEventStatus,
          ),
        ],
      );
    } else if (hasClassEvents) {
      content = _buildClassEventsTab(
        context,
        ref,
        AsyncValue.data(visibleClassEvents),
        bookingState.request.selectedClassEvent,
        bookingConstraint: bookingConstraint,
        hasSelectedServices: selectedServices.isNotEmpty,
        bookedEventStatus: bookedEventStatus,
      );
    } else {
      content = buildServicesContent();
    }

    return Stack(
      children: [
        Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showBothTabs
                        ? bookingServicesAndEventsTitle(
                            context,
                            phraseOverrides: phraseOverrides,
                          )
                        : hasClassEvents
                        ? bookingEventsTitle(
                            context,
                            phraseOverrides: phraseOverrides,
                          )
                        : bookingServicesTitle(
                            context,
                            customServiceLabel,
                            phraseOverrides: phraseOverrides,
                          ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (headerSubtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      headerSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // TabBar solo quando ci sono sia servizi che classi
            if (showBothTabs)
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    text: bookingTabServicesLabel(
                      context,
                      phraseOverrides: phraseOverrides,
                    ),
                  ),
                  Tab(
                    text: bookingTabEventsLabel(
                      context,
                      phraseOverrides: phraseOverrides,
                    ),
                  ),
                ],
              ),

            Expanded(child: content),

            // Footer con selezione e bottone
            _buildFooter(
              context,
              ref,
              selectedServices,
              isClassTab: isClassTab,
            ),
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

  void _applyDirectLinkSelectionIfReady({
    required BookingDirectLink? directLink,
    required ServicesData? servicesData,
    required List<ServicePackage>? packages,
    required List<ClassEvent>? classEvents,
    required bool showBothTabs,
  }) {
    if (directLink == null || _appliedDirectLinkSlug == directLink.linkSlug) {
      return;
    }

    switch (directLink.targetType) {
      case 'service_variant':
        if (servicesData == null) return;
        _appliedDirectLinkSlug = directLink.linkSlug;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final service = _findDirectService(directLink, servicesData.services);
          if (service == null) return;
          final current = ref.read(bookingFlowProvider).request;
          if (current.selectedServiceIds.length != 1 ||
              !current.selectedServiceIds.contains(service.id) ||
              current.selectedPackageIds.isNotEmpty ||
              current.selectedClassEvent != null) {
            ref
                .read(bookingFlowProvider.notifier)
                .applyLockedServiceSelection(service);
          }
        });
        return;
      case 'service_package':
        if (servicesData == null || packages == null) return;
        _appliedDirectLinkSlug = directLink.linkSlug;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final package = _findDirectPackage(directLink.targetId, packages);
          if (package == null) return;
          final current = ref.read(bookingFlowProvider).request;
          if (current.selectedPackageIds.length != 1 ||
              !current.selectedPackageIds.contains(package.id) ||
              current.selectedClassEvent != null) {
            ref
                .read(bookingFlowProvider.notifier)
                .applyLockedPackageSelection(package, servicesData.services);
          }
        });
        return;
      case 'class_event':
        if (classEvents == null) return;
        _appliedDirectLinkSlug = directLink.linkSlug;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final event = _findDirectClassEvent(directLink.targetId, classEvents);
          if (event == null) return;
          final current = ref.read(bookingFlowProvider).request;
          if (current.selectedClassEvent?.id != event.id) {
            ref
                .read(bookingFlowProvider.notifier)
                .applyLockedClassEventSelection(event);
          }
          if (showBothTabs && _tabController.index != 1) {
            _tabController.animateTo(1);
          }
        });
        return;
      case 'service_category':
        _appliedDirectLinkSlug = directLink.linkSlug;
        return;
      default:
        _appliedDirectLinkSlug = directLink.linkSlug;
        return;
    }
  }

  Service? _findDirectService(
    BookingDirectLink directLink,
    List<Service> services,
  ) {
    final serviceId = _intFromJson(directLink.target['service_id']);
    for (final service in services) {
      if (service.serviceVariantId == directLink.targetId) return service;
      if (serviceId != null && service.id == serviceId) return service;
    }
    return null;
  }

  ServicePackage? _findDirectPackage(
    int packageId,
    List<ServicePackage> packages,
  ) {
    for (final package in packages) {
      if (package.id == packageId) return package;
    }
    return null;
  }

  ClassEvent? _findDirectClassEvent(int eventId, List<ClassEvent> classEvents) {
    for (final event in classEvents) {
      if (event.id == eventId) return event;
    }
    return null;
  }

  int? _intFromJson(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Costruisce il widget di errore appropriato in base al tipo di errore
  Widget _buildErrorWidget(
    BuildContext context,
    WidgetRef ref,
    Object error,
    String? customServiceLabel,
    Map<String, String>? phraseOverrides,
  ) {
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
        title = bookingErrorServiceUnavailableMessage(
          context,
          customServiceLabel,
          phraseOverrides: phraseOverrides,
        );
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
    Map<String, String>? phraseOverrides, {
    required _BookingLinkConstraint bookingConstraint,
    bool showPriceToCustomer = true,
    bool showDurationToCustomer = true,
  }) {
    final widgets = <Widget>[];
    final packages = packagesAsync.value ?? [];
    final visiblePackages = packages.where((package) {
      if (!package.isActive || !package.isBookableOnline || package.isBroken) {
        return false;
      }
      if (package.onlineVisibility == 'hidden') return false;
      final packageServiceIds = package.orderedServiceIds;
      if (packageServiceIds.isEmpty) return false;
      if (!bookingConstraint.hasDirectLinkConstraint) {
        return package.onlineVisibility == 'public';
      }
      return bookingConstraint.allowsPackage(package);
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

    // Prima passata: costruisci le entries per categoria.
    final categoryDataList =
        <({ServiceCategory category, List<_CategoryEntry> entries})>[];

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

      // Non mostrare categorie senza servizi prenotabili né pacchetti visibili.
      if (categoryServices.isEmpty && categoryPackages.isEmpty) continue;

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
      categoryDataList.add((category: category, entries: categoryEntries));
    }

    // Seconda passata: determina se mostrare categorie collassabili.
    final totalEntries = categoryDataList.fold<int>(
      0,
      (sum, d) => sum + d.entries.length,
    );
    final isCollapsible = totalEntries > 30 && categoryDataList.length >= 3;

    for (final data in categoryDataList) {
      widgets.add(
        _CategorySection(
          key: ValueKey<int>(data.category.id),
          category: data.category,
          entries: data.entries,
          selectedServiceIds: selectedServiceIds,
          selectedPackageIds: selectedPackageIds,
          selectedServices: selectedServices,
          serviceById: serviceById,
          isCollapsible: isCollapsible,
          showPriceToCustomer: showPriceToCustomer,
          showDurationToCustomer: showDurationToCustomer,
          onServiceTap: (service) {
            if (bookingConstraint.locksSingleServiceSelection &&
                selectedServiceIds.contains(service.id)) {
              return;
            }
            ref.read(bookingFlowProvider.notifier).toggleService(service);
          },
          onPackageTap: (package) {
            if (bookingConstraint.locksSinglePackageSelection &&
                selectedPackageIds.contains(package.id)) {
              return;
            }
            ref
                .read(bookingFlowProvider.notifier)
                .togglePackageSelection(package, services);
          },
          disableServiceTap: bookingConstraint.locksSingleServiceSelection,
          disablePackageTap: bookingConstraint.locksSinglePackageSelection,
        ),
      );
    }

    // Il footer fisso è alto ~88px (info selezione + bottone); aggiunge
    // viewPadding.bottom per la gesture bar Android.
    final bottomInset = MediaQuery.of(context).viewPadding.bottom + 88 + 24;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
      children: widgets,
    );
  }

  Widget _buildClassEventsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ClassEvent>> eventsAsync,
    ClassEvent? selectedEvent, {
    required _BookingLinkConstraint bookingConstraint,
    required bool hasSelectedServices,
    required Map<int, String> bookedEventStatus,
  }) {
    if (hasSelectedServices) {
      final phraseOverrides = ref.watch(
        bookingTextOverridesForLocaleProvider(Localizations.localeOf(context)),
      );
      return _ConflictView(
        title: bookingTabConflictEventsTitle(
          context,
          phraseOverrides: phraseOverrides,
        ),
        subtitle: bookingTabConflictEventsSubtitle(
          context,
          phraseOverrides: phraseOverrides,
        ),
      );
    }

    final phraseOverrides = ref.watch(
      bookingTextOverridesForLocaleProvider(Localizations.localeOf(context)),
    );

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        title: bookingEventsEmptyTitle(
          context,
          phraseOverrides: phraseOverrides,
        ),
        onRetry: () => ref.read(classEventsProvider.notifier).refresh(),
      ),
      data: (events) {
        if (events.isEmpty) {
          return _EmptyView(
            title: bookingEventsEmptyTitle(
              context,
              phraseOverrides: phraseOverrides,
            ),
            subtitle: bookingEventsEmptySubtitle(
              context,
              phraseOverrides: phraseOverrides,
            ),
          );
        }

        // Raggruppa per categoria
        final servicesData = ref.watch(servicesDataProvider).value;
        final categoryById = <int, ServiceCategory>{
          if (servicesData != null)
            for (final c in servicesData.categories) c.id: c,
        };

        final byCategory = <int?, List<ClassEvent>>{};
        for (final e in events) {
          byCategory.putIfAbsent(e.classTypeServiceCategoryId, () => []).add(e);
        }

        final sortedCategoryIds = byCategory.keys.toList()
          ..sort((a, b) {
            if (a == null && b == null) return 0;
            if (a == null) return 1;
            if (b == null) return -1;
            final catA = categoryById[a];
            final catB = categoryById[b];
            if (catA == null && catB == null) return a.compareTo(b);
            if (catA == null) return 1;
            if (catB == null) return -1;
            return catA.sortOrder.compareTo(catB.sortOrder);
          });

        final showCategories =
            sortedCategoryIds.length > 1 ||
            (sortedCategoryIds.length == 1 &&
                sortedCategoryIds.first != null &&
                categoryById.containsKey(sortedCategoryIds.first));

        final isCollapsible =
            showCategories &&
            events.length > 30 &&
            sortedCategoryIds.length >= 3;

        void onEventTap(ClassEvent event) {
          if (bookingConstraint.locksSingleEventSelection &&
              selectedEvent?.id == event.id) {
            return;
          }
          final notifier = ref.read(bookingFlowProvider.notifier);
          if (selectedEvent?.id == event.id) {
            notifier.selectClassEvent(null);
          } else {
            notifier.selectClassEvent(event);
          }
        }

        if (!showCategories) {
          // Singola categoria o nessuna: mostra eventi raggruppati per data
          final bottomInset =
              MediaQuery.of(context).viewPadding.bottom + 88 + 24;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
            children: _buildEventsByDate(
              context,
              byCategory.values.expand((e) => e).toList(),
              selectedEvent,
              bookedEventStatus,
              phraseOverrides,
              onEventTap,
            ),
          );
        }

        final items = <Widget>[];
        for (final catId in sortedCategoryIds) {
          final catEvents = byCategory[catId]!;
          String? eventCategoryName;
          for (final event in catEvents) {
            final name = event.classTypeServiceCategoryName?.trim();
            if (name != null && name.isNotEmpty) {
              eventCategoryName = name;
              break;
            }
          }
          final catName = catId != null && categoryById.containsKey(catId)
              ? categoryById[catId]!.name
              : (eventCategoryName ?? context.l10n.tabEvents);
          items.add(
            _EventCategorySection(
              key: ValueKey(catId),
              categoryName: catName,
              events: catEvents,
              selectedEvent: selectedEvent,
              bookedEventStatus: bookedEventStatus,
              phraseOverrides: phraseOverrides,
              isCollapsible: isCollapsible,
              hasSelectedEvent: catEvents.any((e) => e.id == selectedEvent?.id),
              onEventTap: onEventTap,
            ),
          );
        }

        final bottomInset = MediaQuery.of(context).viewPadding.bottom + 88 + 24;
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
          children: items,
        );
      },
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    List<Service> selectedServices, {
    bool isClassTab = false,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final customServiceLabel = ref.watch(bookingServiceDisplayLabelProvider);
    final phraseOverrides = ref.watch(
      bookingTextOverridesForLocaleProvider(Localizations.localeOf(context)),
    );
    final bookingState = ref.watch(bookingFlowProvider);
    final totals = ref.watch(bookingTotalsProvider);
    final selectedClassEvent = bookingState.request.selectedClassEvent;
    final footerLocation = ref.watch(effectiveLocationProvider);
    final showPriceToCustomer = footerLocation?.showPriceToCustomer ?? true;

    // Testo info selezione
    Widget selectionInfo;
    if (isClassTab) {
      if (selectedClassEvent != null) {
        selectionInfo = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedClassEvent.classTypeName,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (showPriceToCustomer)
              Text(
                selectedClassEvent.formattedPrice,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        );
      } else {
        selectionInfo = Text(
          bookingEventsSelectedNoneLabel(
            context,
            phraseOverrides: phraseOverrides,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        );
      }
    } else {
      selectionInfo = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            bookingServicesSelectedLabel(
              context,
              customServiceLabel,
              totals.selectedItemCount,
              phraseOverrides: phraseOverrides,
            ),
            style: theme.textTheme.bodyMedium,
          ),
          if (selectedServices.isNotEmpty && showPriceToCustomer)
            Text(
              _formatTotalPrice(context, totals.totalPrice),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      );
    }

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
            selectionInfo,
            const SizedBox(height: 12),
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

  static List<Widget> _buildEventsByDate(
    BuildContext context,
    List<ClassEvent> events,
    ClassEvent? selectedEvent,
    Map<int, String> bookedEventStatus,
    Map<String, String>? phraseOverrides,
    void Function(ClassEvent) onEventTap,
  ) {
    final byDate = <String, List<ClassEvent>>{};
    for (final e in events) {
      final dateKey = e.displayStartsAt.substring(0, 10);
      byDate.putIfAbsent(dateKey, () => []).add(e);
    }
    final locale = Localizations.localeOf(context).languageCode;
    final widgets = <Widget>[];
    for (final entry in byDate.entries) {
      final date = DateTime.parse(entry.key);
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
          child: Text(
            DateFormat('EEEE d MMMM', locale).format(date),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
      for (final event in entry.value) {
        final existingStatus = bookedEventStatus[event.id];
        widgets.add(
          _ClassEventTile(
            event: event,
            isSelected: selectedEvent?.id == event.id,
            existingStatus: existingStatus,
            phraseOverrides: phraseOverrides,
            onTap: existingStatus != null ? () {} : () => onEventTap(event),
          ),
        );
      }
    }
    return widgets;
  }
}

class _ClassEventTile extends ConsumerWidget {
  final ClassEvent event;
  final bool isSelected;

  /// 'confirmed' | 'waitlisted' | null
  final String? existingStatus;
  final Map<String, String>? phraseOverrides;
  final VoidCallback onTap;

  const _ClassEventTile({
    required this.event,
    required this.isSelected,
    required this.onTap,
    this.existingStatus,
    this.phraseOverrides,
  });

  Future<void> _confirmWaitlist(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          bookingClassEventWaitlistDialogTitle(
            context,
            phraseOverrides: phraseOverrides,
          ),
        ),
        content: Text(
          bookingClassEventWaitlistDialogMessage(
            context,
            phraseOverrides: phraseOverrides,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              bookingClassEventWaitlistDialogConfirm(
                context,
                phraseOverrides: phraseOverrides,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) onTap();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final slug = ref.watch(businessSlugProvider);
    final startTime = DateTime.tryParse(event.displayStartsAt);
    final endTime = DateTime.tryParse(event.displayEndsAt);
    final timeLabel = (startTime != null && endTime != null)
        ? '${DateFormat('HH:mm').format(startTime)} – ${DateFormat('HH:mm').format(endTime)}'
        : event.displayStartsAt;

    Color? dotColor;
    if (event.classTypeColorHex != null) {
      final hex = event.classTypeColorHex!.replaceFirst('#', '');
      if (hex.length == 6) {
        dotColor = Color(int.parse('FF$hex', radix: 16));
      }
    }

    final isAlreadyBooked = existingStatus == 'confirmed';
    final isAlreadyWaitlisted = existingStatus == 'waitlisted';
    final hasExistingBooking = existingStatus != null;
    final showPriceToCustomer =
        ref.watch(effectiveLocationProvider)?.showPriceToCustomer ?? true;

    final effectiveOnTap = hasExistingBooking
        ? null
        : (event.isFull && !event.waitlistEnabled)
        ? null
        : (event.isFull && event.waitlistEnabled)
        ? () => _confirmWaitlist(context)
        : onTap;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAlreadyBooked
              ? theme.colorScheme.primary.withOpacity(0.4)
              : isAlreadyWaitlisted
              ? Colors.orange.withOpacity(0.4)
              : isSelected
              ? theme.colorScheme.primary
              : theme.dividerColor,
          width: (isSelected || hasExistingBooking) ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: effectiveOnTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: hasExistingBooking ? 0.65 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Indicatore selezione / stato prenotazione
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAlreadyBooked
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : isAlreadyWaitlisted
                        ? Colors.orange.withOpacity(0.15)
                        : isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isAlreadyBooked
                          ? theme.colorScheme.primary.withOpacity(0.5)
                          : isAlreadyWaitlisted
                          ? Colors.orange.withOpacity(0.5)
                          : isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: hasExistingBooking
                      ? Icon(
                          isAlreadyBooked
                              ? Icons.check_circle_outline
                              : Icons.hourglass_top_rounded,
                          size: 14,
                          color: isAlreadyBooked
                              ? theme.colorScheme.primary
                              : Colors.orange.shade700,
                        )
                      : isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                // Pallino colore tipo classe
                if (dotColor != null) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                // Info evento
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.classTypeName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (hasExistingBooking && showPriceToCustomer) ...[
                        const SizedBox(height: 2),
                        Text(
                          event.formattedPrice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Posti / prezzo / stato prenotazione
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!hasExistingBooking && showPriceToCustomer)
                      Text(
                        event.formattedPrice,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    const SizedBox(height: 2),
                    if (isAlreadyBooked) ...[
                      Text(
                        bookingClassEventAlreadyBookedLabel(
                          context,
                          phraseOverrides: phraseOverrides,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (slug != null) ...[
                        const SizedBox(height: 6),
                        _ManageBookingLink(
                          slug: slug,
                          color: theme.colorScheme.primary,
                          label: bookingClassEventManageBookingLabel(
                            context,
                            phraseOverrides: phraseOverrides,
                          ),
                          textTheme: theme.textTheme,
                        ),
                      ],
                    ] else if (isAlreadyWaitlisted) ...[
                      Text(
                        bookingClassEventAlreadyWaitlistedLabel(
                          context,
                          phraseOverrides: phraseOverrides,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (slug != null) ...[
                        const SizedBox(height: 6),
                        _ManageBookingLink(
                          slug: slug,
                          color: Colors.orange.shade700,
                          label: bookingClassEventManageBookingLabel(
                            context,
                            phraseOverrides: phraseOverrides,
                          ),
                          textTheme: theme.textTheme,
                        ),
                      ],
                    ] else if (event.isFull && event.waitlistEnabled)
                      Text(
                        bookingClassEventJoinWaitlistLabel(
                          context,
                          phraseOverrides: phraseOverrides,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (event.isFull)
                      Text(
                        bookingClassEventFullLabel(
                          context,
                          phraseOverrides: phraseOverrides,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        bookingClassEventSpotsLeftLabel(
                          context,
                          event.spotsLeft,
                          phraseOverrides: phraseOverrides,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final ServiceCategory category;
  final List<_CategoryEntry> entries;
  final Set<int> selectedServiceIds;
  final Set<int> selectedPackageIds;
  final List<Service> selectedServices;
  final Map<int, Service> serviceById;
  final void Function(Service) onServiceTap;
  final void Function(ServicePackage) onPackageTap;
  final bool disableServiceTap;
  final bool disablePackageTap;
  final bool isCollapsible;
  final bool showPriceToCustomer;
  final bool showDurationToCustomer;

  const _CategorySection({
    super.key,
    required this.category,
    required this.entries,
    required this.selectedServiceIds,
    required this.selectedPackageIds,
    required this.selectedServices,
    required this.serviceById,
    required this.onServiceTap,
    required this.onPackageTap,
    this.disableServiceTap = false,
    this.disablePackageTap = false,
    this.isCollapsible = false,
    this.showPriceToCustomer = true,
    this.showDurationToCustomer = true,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.isCollapsible;
  }

  @override
  void didUpdateWidget(_CategorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCollapsible != widget.isCollapsible) {
      _isExpanded = !widget.isCollapsible;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withOpacity(0.18);

    final selectedCount = widget.entries.where((e) {
      if (e.isPackage) return widget.selectedPackageIds.contains(e.package!.id);
      return widget.selectedServiceIds.contains(e.service!.id);
    }).length;

    final header = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isCollapsible
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.isCollapsible ? 14 : 0,
          12,
          widget.isCollapsible ? 8 : 0,
          12,
        ),
        child: Row(
          children: [
            // Sinistra: nome + chip totale
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isCollapsible) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.entries.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Destra: chip selezionati + freccia
            if (selectedCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$selectedCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (widget.isCollapsible) ...[
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.chevron_right),
              ),
            ],
          ],
        ),
      ),
    );

    final body = _isExpanded
        ? Padding(
            padding: widget.isCollapsible
                ? const EdgeInsets.fromLTRB(10, 0, 10, 10)
                : EdgeInsets.zero,
            child: Column(
              children: [
                for (final entry in widget.entries)
                  if (entry.isPackage)
                    _PackageTile(
                      package: entry.package!,
                      serviceById: widget.serviceById,
                      isSelected: widget.selectedPackageIds.contains(
                        entry.package!.id,
                      ),
                      isDisabled:
                          !entry.package!.isActive || entry.package!.isBroken,
                      onTap:
                          (!entry.package!.isActive || entry.package!.isBroken)
                          ? null
                          : widget.disablePackageTap
                          ? null
                          : () => widget.onPackageTap(entry.package!),
                      showPriceToCustomer: widget.showPriceToCustomer,
                    )
                  else
                    _ServiceTile(
                      service: entry.service!,
                      isSelected: widget.selectedServiceIds.contains(
                        entry.service!.id,
                      ),
                      onTap: widget.disableServiceTap
                          ? () {}
                          : () => widget.onServiceTap(entry.service!),
                      showPriceToCustomer: widget.showPriceToCustomer,
                      showDurationToCustomer: widget.showDurationToCustomer,
                    ),
                if (!widget.isCollapsible) const SizedBox(height: 8),
              ],
            ),
          )
        : const SizedBox.shrink();

    if (!widget.isCollapsible) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, body],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, body],
      ),
    );
  }
}

class _EventCategorySection extends StatefulWidget {
  final String categoryName;
  final List<ClassEvent> events;
  final ClassEvent? selectedEvent;
  final Map<int, String> bookedEventStatus;
  final Map<String, String>? phraseOverrides;
  final bool isCollapsible;
  final bool hasSelectedEvent;
  final void Function(ClassEvent) onEventTap;

  const _EventCategorySection({
    super.key,
    required this.categoryName,
    required this.events,
    required this.selectedEvent,
    required this.bookedEventStatus,
    required this.phraseOverrides,
    required this.hasSelectedEvent,
    required this.onEventTap,
    this.isCollapsible = false,
  });

  @override
  State<_EventCategorySection> createState() => _EventCategorySectionState();
}

class _EventCategorySectionState extends State<_EventCategorySection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.isCollapsible;
  }

  @override
  void didUpdateWidget(_EventCategorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCollapsible != widget.isCollapsible) {
      _isExpanded = !widget.isCollapsible;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withOpacity(0.18);

    final header = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isCollapsible
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.isCollapsible ? 14 : 0,
          12,
          widget.isCollapsible ? 8 : 0,
          12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.categoryName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isCollapsible) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.events.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.hasSelectedEvent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '1',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (widget.isCollapsible) ...[
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.chevron_right),
              ),
            ],
          ],
        ),
      ),
    );

    final body = _isExpanded
        ? Padding(
            padding: widget.isCollapsible
                ? const EdgeInsets.fromLTRB(10, 0, 10, 10)
                : EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _ServicesStepState._buildEventsByDate(
                context,
                widget.events,
                widget.selectedEvent,
                widget.bookedEventStatus,
                widget.phraseOverrides,
                widget.onEventTap,
              ),
            ),
          )
        : const SizedBox.shrink();

    if (!widget.isCollapsible) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, body],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, body],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Service service;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showPriceToCustomer;
  final bool showDurationToCustomer;

  const _ServiceTile({
    required this.service,
    required this.isSelected,
    required this.onTap,
    this.showPriceToCustomer = true,
    this.showDurationToCustomer = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = service.description?.trim();

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
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                    if (showDurationToCustomer) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.localizedDurationLabel(
                          service.customerVisibleDurationMinutes,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Prezzo
              if (showPriceToCustomer)
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
  final Map<int, Service> serviceById;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;
  final bool showPriceToCustomer;

  const _PackageTile({
    required this.package,
    required this.serviceById,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
    this.showPriceToCustomer = true,
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
                          package.customerVisibleDurationMinutes(serviceById),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showPriceToCustomer)
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

class _BookingLinkConstraint {
  final String? targetType;
  final int? targetId;
  final String? childVisibilityScope;

  const _BookingLinkConstraint({
    this.targetType,
    this.targetId,
    this.childVisibilityScope,
  });

  factory _BookingLinkConstraint.fromDirectLink(BookingDirectLink? directLink) {
    if (directLink == null) {
      return const _BookingLinkConstraint();
    }
    return _BookingLinkConstraint(
      targetType: directLink.targetType,
      targetId: directLink.targetId,
      childVisibilityScope: directLink.childVisibilityScope,
    );
  }

  bool get locksSingleServiceSelection => targetType == 'service_variant';
  bool get locksSinglePackageSelection => targetType == 'service_package';
  bool get locksSingleEventSelection => targetType == 'class_event';

  bool get hasDirectLinkConstraint => targetType != null;

  bool get isScopedToServicesOnly =>
      targetType == 'service_variant' || targetType == 'service_package';

  bool get isScopedToEventsOnly => targetType == 'class_event';

  bool _matchesCategoryVisibility(String onlineVisibility) {
    if (targetType != 'service_category') {
      return true;
    }

    return switch (childVisibilityScope) {
      'public_only' => onlineVisibility == 'public',
      'direct_link_only' => onlineVisibility == 'direct_link',
      'empty' => false,
      _ => onlineVisibility != 'hidden',
    };
  }

  bool allowsService(Service service) {
    switch (targetType) {
      case 'service_variant':
        return service.serviceVariantId == targetId;
      case 'service_package':
      case 'class_event':
        return false;
      case 'service_category':
        return service.categoryId == targetId &&
            _matchesCategoryVisibility(service.onlineVisibility);
      default:
        return true;
    }
  }

  bool allowsPackage(ServicePackage package) {
    switch (targetType) {
      case 'service_variant':
      case 'class_event':
        return false;
      case 'service_package':
        return package.id == targetId;
      case 'service_category':
        return package.categoryId == targetId &&
            _matchesCategoryVisibility(package.onlineVisibility);
      default:
        return true;
    }
  }

  bool allowsEvent(ClassEvent event) {
    switch (targetType) {
      case 'service_variant':
      case 'service_package':
        return false;
      case 'class_event':
        return event.id == targetId;
      case 'service_category':
        return event.classTypeServiceCategoryId == targetId &&
            _matchesCategoryVisibility(event.onlineVisibility);
      default:
        return true;
    }
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
class _ConflictView extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ConflictView({required this.title, required this.subtitle});

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
              Icons.info_outline,
              size: 56,
              color: theme.colorScheme.primary.withOpacity(0.5),
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

class _ManageBookingLink extends StatelessWidget {
  final String slug;
  final Color color;
  final String label;
  final TextTheme textTheme;

  const _ManageBookingLink({
    required this.slug,
    required this.color,
    required this.label,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: OutlinedButton(
        onPressed: () => context.go('/$slug/my-bookings'),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
    );
  }
}
