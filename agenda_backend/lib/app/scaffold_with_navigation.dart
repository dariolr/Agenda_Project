// Cleaned duplicate header
import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/app/widgets/agenda_control_components.dart';
import 'package:agenda_backend/app/widgets/agenda_staff_filter_selector.dart';
import 'package:agenda_backend/app/widgets/top_controls.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/agenda_dividers.dart';
import 'package:agenda_backend/features/auth/providers/current_business_user_provider.dart';
import 'package:agenda_backend/features/bookings_list/providers/bookings_list_provider.dart';
import 'package:agenda_backend/features/reports/providers/reports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/l10n/l10_extension.dart';
import '../core/models/location.dart';
import '../core/widgets/adaptive_dropdown.dart';
import '../core/widgets/app_bottom_sheet.dart';
import '../core/widgets/app_buttons.dart';
import '../core/widgets/global_loading_overlay.dart';
import '../features/agenda/presentation/dialogs/add_block_dialog.dart';
import '../features/agenda/presentation/widgets/agenda_top_controls.dart';
import '../features/agenda/presentation/widgets/booking_dialog.dart';
import '../features/agenda/providers/business_providers.dart';
import '../features/agenda/providers/date_range_provider.dart';
import '../features/agenda/providers/layout_config_provider.dart';
import '../features/agenda/providers/location_providers.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/business/presentation/dialogs/invite_operator_dialog.dart';
import '../features/business/presentation/dialogs/location_closure_dialog.dart';
import '../features/business/providers/location_closures_provider.dart';
import '../features/business/providers/superadmin_selected_business_provider.dart';
import '../features/clients/presentation/dialogs/client_edit_dialog.dart';
import '../features/clients/providers/clients_providers.dart';
import '../features/services/presentation/dialogs/category_dialog.dart';
import '../features/services/presentation/dialogs/service_dialog.dart';
import '../features/services/presentation/dialogs/service_package_dialog.dart';
import '../features/services/providers/service_categories_provider.dart';
import '../features/services/providers/services_provider.dart';
import '../features/services/providers/services_reorder_provider.dart';
import '../features/staff/presentation/dialogs/location_dialog.dart';
import '../features/staff/presentation/dialogs/staff_dialog.dart';
import '../features/staff/providers/staff_providers.dart';
import '../features/staff/providers/staff_reorder_provider.dart';

Widget _buildAddButtonContent({
  required bool showLabelEffective,
  required bool compact,
  required String label,
  required Color onContainer,
}) {
  if (compact) {
    return showLabelEffective
        ? Text(
            label,
            style: TextStyle(color: onContainer, fontWeight: FontWeight.w600),
          )
        : Icon(Icons.add_outlined, size: 22, color: onContainer);
  }
  if (!showLabelEffective) {
    return Icon(Icons.add_outlined, size: 22, color: onContainer);
  }
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.add_outlined, size: 22, color: onContainer),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(color: onContainer, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class ScaffoldWithNavigation extends ConsumerWidget {
  const ScaffoldWithNavigation({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formFactor = ref.watch(formFactorProvider);
    final isAgenda = navigationShell.currentIndex == 0;
    final isClients = navigationShell.currentIndex == 1;
    final isServices = navigationShell.currentIndex == 2;
    final isStaff = navigationShell.currentIndex == 3;
    final isReport = navigationShell.currentIndex == 4;
    final isBookingsList = navigationShell.currentIndex == 5;
    final isClosures = navigationShell.currentIndex == 7;
    final isPermessi = navigationShell.currentIndex == 9;
    final agendaDate = ref.watch(agendaDateProvider);
    final today = DateUtils.dateOnly(DateTime.now());
    final isToday = DateUtils.isSameDay(agendaDate, today);
    final isPast = agendaDate.isBefore(today);
    final user = ref.watch(authProvider).user;
    final isSuperadmin = user?.isSuperadmin ?? false;
    final showClientsNav = ref.watch(currentUserCanManageClientsProvider);
    final canCreateAgendaItems = ref.watch(
      currentUserCanManageBookingsProvider,
    );
    final canManageServices = ref.watch(currentUserCanManageServicesProvider);
    final canViewStaff = ref.watch(currentUserCanViewStaffProvider);
    final canViewReports = ref.watch(currentUserCanViewReportsProvider);
    final canManageOperators = ref.watch(canManageOperatorsProvider);
    final canManageClosures = ref.watch(canManageBusinessSettingsProvider);
    final businessesAsync = ref.watch(businessesProvider);
    final hasMultipleBusinesses = businessesAsync.maybeWhen(
      data: (businesses) => businesses.length > 1,
      orElse: () => false,
    );
    final showSwitchBusiness = isSuperadmin || hasMultipleBusinesses;

    // Per mobile e desktop usiamo destinazioni compatte con "Altro"
    final mobileDestinations =
        _ScaffoldWithNavigationHelpers.getMobileDestinations(
          context,
          showSwitchBusiness: showSwitchBusiness,
          includeClients: showClientsNav,
        );

    // Quando non siamo su oggi, mostra freccia per tornare a oggi
    // Freccia destra se nel passato (vai avanti), sinistra se nel futuro (torna indietro)
    // Destinazioni mobile risolte (con freccia per oggi se necessario)
    final resolvedMobileDestinations = isAgenda && !isToday
        ? [
            NavigationDestination(
              iconData: isPast ? Icons.arrow_forward : Icons.arrow_back,
              selectedIconData: isPast ? Icons.arrow_forward : Icons.arrow_back,
              label: context.l10n.agendaToday,
            ),
            ...mobileDestinations.skip(1),
          ]
        : mobileDestinations;

    if (formFactor == AppFormFactor.desktop) {
      final layoutConfig = ref.watch(layoutConfigProvider);
      final dividerColor = Theme.of(context).dividerColor;
      const dividerThickness = 1.0;
      // Desktop usa le stesse destinazioni del mobile (con "Altro")
      final railDestinations =
          _ScaffoldWithNavigationHelpers.toRailDestinations(
            resolvedMobileDestinations,
          );

      final isTablet = formFactor == AppFormFactor.tablet;

      // Azioni specifiche per tab (menu utente è nella rail)
      List<Widget> buildActions() {
        final List<Widget> actions = [];
        if (isAgenda) {
          if (canCreateAgendaItems) {
            actions.add(const _AgendaAddAction());
          }
        } else if (isServices && canManageServices) {
          actions.add(const _ServicesAddAction());
        } else if (isClients && showClientsNav) {
          actions.add(const _ClientsAddAction());
        } else if (isStaff && canViewStaff) {
          actions.add(const _TeamAddAction());
        } else if (isReport && canViewReports) {
          actions.add(_ReportRefreshAction(ref: ref));
        } else if (isBookingsList) {
          actions.add(_BookingsListRefreshAction(ref: ref));
        } else if (isClosures && canManageClosures) {
          actions.add(const _ClosuresAddAction());
        } else if (isPermessi && canManageOperators) {
          actions.add(const _PermessiAddAction());
        }
        return actions;
      }

      // Mappa indice corrente a indice compatto per desktop.
      int desktopCurrentIndex;
      if (!showClientsNav) {
        desktopCurrentIndex = navigationShell.currentIndex == 0 ? 0 : 1;
      } else if (navigationShell.currentIndex <= 1) {
        // Agenda o Clienti
        desktopCurrentIndex = navigationShell.currentIndex;
      } else {
        // Tutto il resto (Servizi, Staff, Report, Prenotazioni, Altro, Chiusure, Profilo) → evidenzia "Altro"
        desktopCurrentIndex = 2;
      }

      return GlobalLoadingOverlay(
        child: Scaffold(
          appBar: AppBar(
            titleSpacing: isTablet && isAgenda
                ? 4
                : NavigationToolbar.kMiddleSpacing,
            title: isAgenda
                ? const AgendaTopControls()
                : isReport
                ? Text(context.l10n.reportsTitle)
                : isBookingsList
                ? Text(context.l10n.bookingsListTitle)
                : isClosures
                ? Text(context.l10n.closuresTitle)
                : isPermessi
                ? Text(context.l10n.permissionsTitle)
                : const SizedBox.shrink(),
            centerTitle: false,
            toolbarHeight: 76,
            actionsPadding: const EdgeInsets.only(right: 6),
            actions: buildActions(),
          ),
          body: Row(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
                child: NavigationRail(
                  selectedIndex: desktopCurrentIndex,
                  onDestinationSelected: (index) => _handleDesktopNavTap(
                    context,
                    index,
                    ref,
                    includeClients: showClientsNav,
                  ),
                  labelType: NavigationRailLabelType.none,
                  useIndicator: false, // disattiva highlight di sistema su tap
                  // BusinessSelector rimosso - superadmin usa /businesses
                  destinations: railDestinations,
                ),
              ),
              _RailDivider(
                topInset: layoutConfig.headerHeight,
                color: dividerColor,
                thickness: dividerThickness,
              ),
              Expanded(child: navigationShell),
            ],
          ),
        ),
      );
    }

    final isTablet = formFactor == AppFormFactor.tablet;
    final isMobile = formFactor == AppFormFactor.mobile;
    // Su mobile e tablet il date switcher è in basso, non nell'AppBar
    final showBottomDateSwitcher = isAgenda && (isTablet || isMobile);
    final bottomNavColor =
        Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.surface;

    // Azioni specifiche per tab (menu utente è nella BNB)
    List<Widget> buildMobileActions() {
      final List<Widget> actions = [];
      if (isAgenda) {
        if (formFactor == AppFormFactor.mobile) {
          actions.add(
            const _AgendaFilterActions(padding: EdgeInsets.only(left: 8)),
          );
        }
        if (canCreateAgendaItems) {
          actions.add(const _AgendaAddAction(compact: true));
        }
      } else if (isServices && canManageServices) {
        actions.add(const _ServicesAddAction(compact: true));
      } else if (isClients && showClientsNav) {
        actions.add(const _ClientsAddAction(compact: true));
      } else if (isStaff && canViewStaff) {
        actions.add(const _TeamAddAction(compact: true));
      } else if (isReport && canViewReports) {
        actions.add(_ReportRefreshAction(ref: ref));
      } else if (isBookingsList) {
        actions.add(_BookingsListRefreshAction(ref: ref));
      } else if (isClosures && canManageClosures) {
        actions.add(const _ClosuresAddAction(compact: true));
      } else if (isPermessi && canManageOperators) {
        actions.add(const _PermessiAddAction(compact: true));
      }
      return actions;
    }

    // Su mobile, mappa l'indice corrente a quello compatto
    // Desktop: 0=Agenda, 1=Clienti, 2=Servizi, 3=Staff, 4=Report, 5=Prenotazioni, 6=Altro, 7=Chiusure, 8=Profilo
    // Mobile:  0=Agenda, 1=Clienti, 2=Altro
    int mobileCurrentIndex;
    if (!showClientsNav) {
      mobileCurrentIndex = navigationShell.currentIndex == 0 ? 0 : 1;
    } else if (navigationShell.currentIndex <= 1) {
      // Agenda o Clienti
      mobileCurrentIndex = navigationShell.currentIndex;
    } else {
      // Tutto il resto (Servizi, Staff, Report, Prenotazioni, Altro, Chiusure, Profilo) → evidenzia "Altro"
      mobileCurrentIndex = 2;
    }

    return GlobalLoadingOverlay(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: isTablet ? 76 : 64,
          titleSpacing: isAgenda ? 4 : NavigationToolbar.kMiddleSpacing,
          title: isAgenda
              ? const AgendaTopControls(compact: true)
              : isReport
              ? Text(context.l10n.reportsTitle)
              : isBookingsList
              ? Text(context.l10n.bookingsListTitle)
              : isClosures
              ? Text(context.l10n.closuresTitle)
              : isPermessi
              ? Text(context.l10n.permissionsTitle)
              : const SizedBox.shrink(),
          centerTitle: false,
          actionsPadding: const EdgeInsets.only(right: 6),
          actions: buildMobileActions(),
        ),
        body: navigationShell,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBottomDateSwitcher) ...[
              const AgendaHorizontalDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: const _MobileAgendaDateSwitcher(),
              ),
            ],
            ColoredBox(
              color: bottomNavColor,
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                minimum: const EdgeInsets.only(bottom: 15),
                child: BottomNavigationBar(
                  currentIndex: mobileCurrentIndex,
                  onTap: (index) => _handleMobileNavTap(
                    context,
                    index,
                    ref,
                    includeClients: showClientsNav,
                  ),
                  type: BottomNavigationBarType.fixed,
                  items: resolvedMobileDestinations
                      .map(
                        (d) => BottomNavigationBarItem(
                          icon: Icon(d.iconData),
                          activeIcon: Icon(d.selectedIconData),
                          label: d.label,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBranch(int index, WidgetRef ref) {
    // Protezione: i branch validi sono 0-6
    if (index < 0 || index > 6) {
      debugPrint('_goBranch: invalid index $index, ignoring');
      return;
    }

    if (index == 0 && navigationShell.currentIndex == 0) {
      final selectedDate = ref.read(agendaDateProvider);
      final today = DateUtils.dateOnly(DateTime.now());
      if (!DateUtils.isSameDay(selectedDate, today)) {
        ref.read(agendaDateProvider.notifier).setToday();
      }
    }

    // Ricarica i provider quando si cambia tab per forzare il refresh dei dati
    if (index != navigationShell.currentIndex) {
      _refreshProvidersForTab(index, ref);
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// Ricarica i provider relativi alla tab selezionata
  void _refreshProvidersForTab(int index, WidgetRef ref) {
    final canManageSettings = ref.read(canManageBusinessSettingsProvider);
    final canManageClients = ref.read(currentUserCanManageClientsProvider);
    final canViewServices = ref.read(currentUserCanViewServicesProvider);
    final canViewStaff = ref.read(currentUserCanViewStaffProvider);
    switch (index) {
      case 0: // Agenda
        if (canManageSettings) {
          ref.read(locationClosuresProvider.notifier).refresh();
        }
        break;
      case 1: // Clienti
        if (canManageClients) {
          ref.read(clientsProvider.notifier).setSearchQuery('');
          ref.read(clientsProvider.notifier).refresh();
          ref.read(clientAppointmentsRefreshProvider.notifier).bump();
        }
        break;
      case 2: // Servizi
        if (canViewServices) {
          ref.read(servicesProvider.notifier).refresh();
        }
        break;
      case 3: // Staff
        if (canViewStaff) {
          ref.read(allStaffProvider.notifier).refresh();
          ref.read(locationsProvider.notifier).refresh();
        }
        break;
    }
  }

  /// Gestisce tap su navigation desktop (compatta come mobile):
  /// - Index 0, 1: navigazione normale (Agenda, Clienti)
  /// - Index 2: naviga a "Altro" (schermata con cards)
  /// - Index 3: Cambia Business (se presente) o Logout
  /// - Index 4: Logout (se Cambia Business presente)
  void _handleDesktopNavTap(
    BuildContext context,
    int desktopIndex,
    WidgetRef ref, {
    required bool includeClients,
  }) {
    final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
    final businessesAsync = ref.read(businessesProvider);
    final hasMultipleBusinesses = businessesAsync.maybeWhen(
      data: (businesses) => businesses.length > 1,
      orElse: () => false,
    );
    final showSwitchBusiness = isSuperadmin || hasMultipleBusinesses;
    final baseCount = includeClients ? 3 : 2;
    final logoutIndex = showSwitchBusiness ? baseCount + 1 : baseCount;
    final switchBusinessIndex = showSwitchBusiness ? baseCount : -1;

    if (desktopIndex == logoutIndex) {
      _handleLogout(context, ref);
      return;
    }
    if (desktopIndex == switchBusinessIndex) {
      _goToBusinessSwitcher(context, ref);
      return;
    }
    if (desktopIndex == 0) {
      _goBranch(0, ref);
      return;
    }
    if (includeClients && desktopIndex == 1) {
      _goBranch(1, ref);
      return;
    }
    final moreIndex = includeClients ? 2 : 1;
    if (desktopIndex == moreIndex) {
      _goBranch(6, ref);
    }
  }

  /// Gestisce tap su navigation mobile:
  /// - Index 0, 1: navigazione normale (Agenda, Clienti)
  /// - Index 2: naviga a "Altro" (schermata con cards)
  /// - Index 3: Cambia Business (se presente) o Logout
  /// - Index 4: Logout (se Cambia Business presente)
  void _handleMobileNavTap(
    BuildContext context,
    int mobileIndex,
    WidgetRef ref, {
    required bool includeClients,
  }) {
    final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
    final businessesAsync = ref.read(businessesProvider);
    final hasMultipleBusinesses = businessesAsync.maybeWhen(
      data: (businesses) => businesses.length > 1,
      orElse: () => false,
    );
    final showSwitchBusiness = isSuperadmin || hasMultipleBusinesses;
    final baseCount = includeClients ? 3 : 2;
    final logoutIndex = showSwitchBusiness ? baseCount + 1 : baseCount;
    final switchBusinessIndex = showSwitchBusiness ? baseCount : -1;

    if (mobileIndex == logoutIndex) {
      _handleLogout(context, ref);
      return;
    }
    if (mobileIndex == switchBusinessIndex) {
      _goToBusinessSwitcher(context, ref);
      return;
    }
    if (mobileIndex == 0) {
      _goBranch(0, ref);
      return;
    }
    if (includeClients && mobileIndex == 1) {
      _goBranch(1, ref);
      return;
    }
    final moreIndex = includeClients ? 2 : 1;
    if (mobileIndex == moreIndex) {
      _goBranch(6, ref);
    }
  }

  void _goToBusinessSwitcher(BuildContext context, WidgetRef ref) {
    final isSuperadmin = ref.read(authProvider).user?.isSuperadmin ?? false;
    invalidateBusinessScopedProviders(ref);
    if (isSuperadmin) {
      ref.read(superadminSelectedBusinessProvider.notifier).clear();
      context.go('/businesses');
      return;
    }
    context.go('/my-businesses?switch=1');
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.authLogout),
        content: const Text('Vuoi uscire dal gestionale?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: Text(l10n.authLogout),
          ),
        ],
      ),
    );
  }
}

class _AgendaAddAction extends ConsumerWidget {
  const _AgendaAddAction({this.compact = false});
  final bool compact;
  static const double _actionButtonHeight = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final agendaDate = ref.watch(agendaDateProvider);
    final scheme = Theme.of(context).colorScheme;
    final onContainer = scheme.onSecondaryContainer;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final showLabel = layoutConfig.showTopbarAddLabel;
    final showLabelEffective =
        showLabel ||
        formFactor == AppFormFactor.tablet ||
        formFactor == AppFormFactor.desktop;
    const iconOnlyWidth = 46.0;
    final bool isIconOnly = !showLabelEffective;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AdaptiveDropdown<String>(
        modalTitle: l10n.agendaAddTitle,
        alignment: AdaptiveDropdownAlignment.right,
        verticalPosition: AdaptiveDropdownVerticalPosition.above,
        forcePopup: true,
        hideTriggerWhenOpen: true,
        popupWidth: 200,
        items: [
          AdaptiveDropdownItem(
            value: 'appointment',
            child: Text(l10n.agendaAddAppointment),
          ),
          AdaptiveDropdownItem(
            value: 'block',
            child: Text(l10n.agendaAddBlock),
          ),
        ],
        onSelected: (value) {
          if (value == 'appointment') {
            showBookingDialog(
              context,
              ref,
              date: agendaDate,
              autoOpenDatePicker: true,
            );
          } else if (value == 'block') {
            showAddBlockDialog(context, ref, date: agendaDate);
          }
        },
        child: Material(
          elevation: 0,
          color: scheme.secondaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: _actionButtonHeight,
            width: isIconOnly ? iconOnlyWidth : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _buildAddButtonContent(
                showLabelEffective: showLabelEffective,
                compact: compact,
                label: l10n.agendaAdd,
                onContainer: onContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaFilterActions extends ConsumerWidget {
  const _AgendaFilterActions({
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  static const double _actionButtonHeight = 40;
  static const double _iconOnlyWidth = 46;
  static const double _spacing = 8;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final showLabel = layoutConfig.showTopbarAddLabel;
    final showLabelEffective =
        showLabel ||
        formFactor == AppFormFactor.tablet ||
        formFactor == AppFormFactor.desktop;
    final staffCount = ref.watch(staffForCurrentLocationProvider).length;
    final locations = ref.watch(locationsProvider);
    final currentLocationId = ref.watch(currentLocationIdProvider);
    // Mostra selettore staff solo se può vedere tutti gli appuntamenti
    final canViewAll = ref.watch(canViewAllAppointmentsProvider);
    final showStaffSelector = canViewAll && staffCount > 1;
    final showLocationSelector = locations.length > 1;

    if (!showStaffSelector && !showLocationSelector) {
      return const SizedBox.shrink();
    }

    Widget buildActionLabel(IconData icon, String label) {
      return showLabelEffective
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 8),
                Text(label),
              ],
            )
          : Icon(icon, size: 22);
    }

    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStaffSelector)
            AgendaStaffFilterSelector(
              compactBuilder: (context, onPressed, tooltip) {
                return Tooltip(
                  message: tooltip,
                  child: SizedBox(
                    height: _actionButtonHeight,
                    width: showLabelEffective ? null : _iconOnlyWidth,
                    child: AppOutlinedActionButton(
                      onPressed: onPressed,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      borderColor: scheme.primary,
                      foregroundColor: scheme.primary,
                      child: buildActionLabel(
                        Icons.badge_outlined,
                        l10n.staffFilterTitle,
                      ),
                    ),
                  ),
                );
              },
            ),
          if (showStaffSelector && showLocationSelector)
            const SizedBox(width: _spacing),
          if (showLocationSelector)
            Tooltip(
              message: l10n.agendaSelectLocation,
              child: SizedBox(
                height: _actionButtonHeight,
                width: showLabelEffective ? null : _iconOnlyWidth,
                child: AppOutlinedActionButton(
                  onPressed: () => _showLocationSheet(
                    context,
                    ref,
                    locations,
                    currentLocationId,
                    l10n.agendaSelectLocation,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  borderColor: scheme.primary,
                  foregroundColor: scheme.primary,
                  child: buildActionLabel(
                    Icons.place_outlined,
                    l10n.agendaSelectLocation,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showLocationSheet(
    BuildContext context,
    WidgetRef ref,
    List<Location> locations,
    int currentLocationId,
    String title,
  ) async {
    final result = await AppBottomSheet.show<int?>(
      context: context,
      builder: (ctx) => LocationSheetContent(
        locations: locations,
        currentLocationId: currentLocationId,
        title: title,
        onSelected: (id) => Navigator.of(ctx).pop(id),
      ),
      useRootNavigator: true,
      padding: EdgeInsets.zero,
    );

    if (result != null) {
      ref.read(currentLocationIdProvider.notifier).set(result);
    }
  }
}

class _ServicesAddAction extends ConsumerWidget {
  const _ServicesAddAction({this.compact = false});
  final bool compact;
  static const double _actionButtonHeight = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final onContainer = scheme.onSecondaryContainer;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final showLabel = layoutConfig.showTopbarAddLabel;
    final showLabelEffective =
        showLabel ||
        formFactor == AppFormFactor.tablet ||
        formFactor == AppFormFactor.desktop;
    final services = ref.watch(servicesProvider).value ?? [];
    final categories = ref.watch(serviceCategoriesProvider);
    const iconOnlyWidth = 46.0;
    final bool isIconOnly = !showLabelEffective;
    Widget buildActionLabel(IconData icon, String label) {
      return showLabelEffective
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 8),
                Text(label),
              ],
            )
          : Icon(icon, size: 22);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...[
            Tooltip(
              message: l10n.reorderTitle,
              child: SizedBox(
                height: _actionButtonHeight,
                width: isIconOnly ? iconOnlyWidth : null,
                child: AppOutlinedActionButton(
                  onPressed: () {
                    ref.read(servicesReorderPanelProvider.notifier).toggle();
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  borderColor: scheme.primary,
                  foregroundColor: scheme.primary,
                  child: buildActionLabel(Icons.sort, l10n.reorderTitle),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          AdaptiveDropdown<String>(
            modalTitle: l10n.agendaAdd,
            alignment: AdaptiveDropdownAlignment.right,
            verticalPosition: AdaptiveDropdownVerticalPosition.above,
            forcePopup: true,
            hideTriggerWhenOpen: true,
            popupWidth: 200,
            items: [
              AdaptiveDropdownItem(
                value: 'category',
                child: Text(l10n.createCategoryButtonLabel),
              ),
              AdaptiveDropdownItem(
                value: 'service',
                child: Text(l10n.servicesNewServiceMenu),
              ),
              AdaptiveDropdownItem(
                value: 'package',
                child: Text(l10n.servicePackageNewMenu),
              ),
            ],
            onSelected: (value) {
              if (value == 'category') {
                showCategoryDialog(context, ref);
              } else if (value == 'service') {
                showServiceDialog(context, ref, requireCategorySelection: true);
              } else if (value == 'package') {
                showServicePackageDialog(
                  context,
                  ref,
                  services: services,
                  categories: categories,
                );
              }
            },
            child: Material(
              elevation: 0,
              color: scheme.secondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: _actionButtonHeight,
                width: isIconOnly ? iconOnlyWidth : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: _buildAddButtonContent(
                    showLabelEffective: showLabelEffective,
                    compact: compact,
                    label: l10n.agendaAdd,
                    onContainer: onContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamAddAction extends ConsumerWidget {
  const _TeamAddAction({this.compact = false});
  final bool compact;
  static const double _actionButtonHeight = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final onContainer = scheme.onSecondaryContainer;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final showLabel = layoutConfig.showTopbarAddLabel;
    final showLabelEffective = showLabel || formFactor != AppFormFactor.mobile;
    const iconOnlyWidth = 46.0;
    final bool isIconOnly = !showLabelEffective;

    // Controlla se ci sono staff e locations per determinare visibilità pulsanti
    final staffAsync = ref.watch(allStaffProvider);
    final staffCount = staffAsync.value?.length ?? 0;
    final locations = ref.watch(locationsProvider);
    final locationCount = locations.length;
    final canManageStaff = ref.watch(currentUserCanManageStaffProvider);

    Widget buildActionLabel(IconData icon, String label) {
      return showLabelEffective
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 8),
                Text(label),
              ],
            )
          : Icon(icon, size: 22);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsante Disponibilità: visibile solo se almeno 1 staff
          if (staffCount >= 1) ...[
            Tooltip(
              message: l10n.staffHubAvailabilityTitle,
              child: SizedBox(
                height: _actionButtonHeight,
                width: isIconOnly ? iconOnlyWidth : null,
                child: AppOutlinedActionButton(
                  onPressed: () => context.pushNamed('staff-availability'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  borderColor: scheme.primary,
                  foregroundColor: scheme.primary,
                  child: buildActionLabel(
                    Icons.schedule_outlined,
                    l10n.staffHubAvailabilityTitle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Pulsante Modifica ordinamento: solo per ruoli con permesso di modifica
          if (canManageStaff && (staffCount >= 2 || locationCount >= 2)) ...[
            Tooltip(
              message: l10n.reorderTitle,
              child: SizedBox(
                height: _actionButtonHeight,
                width: isIconOnly ? iconOnlyWidth : null,
                child: AppOutlinedActionButton(
                  onPressed: () {
                    ref.read(teamReorderPanelProvider.notifier).toggle();
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  borderColor: scheme.primary,
                  foregroundColor: scheme.primary,
                  child: buildActionLabel(Icons.sort, l10n.reorderTitle),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (canManageStaff)
            AdaptiveDropdown<String>(
              modalTitle: l10n.agendaAdd,
              alignment: AdaptiveDropdownAlignment.right,
              verticalPosition: AdaptiveDropdownVerticalPosition.above,
              forcePopup: true,
              hideTriggerWhenOpen: true,
              popupWidth: 220,
              items: [
                AdaptiveDropdownItem(
                  value: 'location',
                  child: Text(l10n.teamNewLocationTitle),
                ),
                AdaptiveDropdownItem(
                  value: 'staff',
                  child: Text(l10n.teamNewStaffTitle),
                ),
              ],
              onSelected: (value) {
                if (value == 'location') {
                  showLocationDialog(context, ref);
                } else if (value == 'staff') {
                  showStaffDialog(context, ref);
                }
              },
              child: Material(
                elevation: 0,
                color: scheme.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: _actionButtonHeight,
                  width: isIconOnly ? iconOnlyWidth : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: _buildAddButtonContent(
                      showLabelEffective: showLabelEffective,
                      compact: compact,
                      label: l10n.agendaAdd,
                      onContainer: onContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClientsAddAction extends ConsumerWidget {
  const _ClientsAddAction({this.compact = false});
  final bool compact;
  static const double _actionButtonHeight = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final showLabel = layoutConfig.showTopbarAddLabel;
    final showLabelEffective = showLabel || formFactor != AppFormFactor.mobile;
    const iconOnlyWidth = 46.0;
    final bool isIconOnly = !showLabelEffective;
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          onTap: () async {
            await showClientEditDialog(context, ref);
          },
          child: Builder(
            builder: (buttonContext) {
              final scheme = Theme.of(buttonContext).colorScheme;
              final onContainer = scheme.onSecondaryContainer;
              return Material(
                elevation: 0,
                color: scheme.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: _actionButtonHeight,
                  width: isIconOnly ? iconOnlyWidth : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: _buildAddButtonContent(
                      showLabelEffective: showLabelEffective,
                      compact: compact,
                      label: l10n.agendaAdd,
                      onContainer: onContainer,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () async {
          await showClientEditDialog(context, ref);
        },
        child: Builder(
          builder: (buttonContext) {
            final scheme = Theme.of(buttonContext).colorScheme;
            final onContainer = scheme.onSecondaryContainer;
            return Material(
              elevation: 0,
              color: scheme.secondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: _actionButtonHeight,
                width: isIconOnly ? iconOnlyWidth : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 28, 8),
                  child: _buildAddButtonContent(
                    showLabelEffective: showLabelEffective,
                    compact: compact,
                    label: l10n.agendaAdd,
                    onContainer: onContainer,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MobileAgendaDateSwitcher extends ConsumerWidget {
  const _MobileAgendaDateSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaDate = ref.watch(agendaDateProvider);
    final dateController = ref.read(agendaDateProvider.notifier);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat('EEE d MMM', localeTag).format(agendaDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AgendaDateSwitcher(
        label: label,
        selectedDate: agendaDate,
        onPrevious: dateController.previousDay,
        onNext: dateController.nextDay,
        onPreviousWeek: dateController.previousWeek,
        onNextWeek: dateController.nextWeek,
        onPreviousMonth: dateController.previousMonth,
        onNextMonth: dateController.nextMonth,
        onSelectDate: (date) {
          dateController.set(DateUtils.dateOnly(date));
        },
        isCompact: true,
      ),
    );
  }
}

class _ScaffoldWithNavigationHelpers {
  /// Destinazioni compatte per mobile e desktop (con "Altro")
  static List<NavigationDestination> getMobileDestinations(
    BuildContext context, {
    bool showSwitchBusiness = false,
    bool includeClients = true,
  }) {
    final l10n = context.l10n;
    return [
      NavigationDestination(
        iconData: Icons.calendar_month_outlined,
        selectedIconData: Icons.calendar_month,
        label: l10n.navAgenda,
      ),
      if (includeClients)
        NavigationDestination(
          iconData: Icons.people_outline,
          selectedIconData: Icons.people,
          label: l10n.navClients,
        ),
      NavigationDestination(
        iconData: Icons.more_horiz_outlined,
        selectedIconData: Icons.more_horiz,
        label: l10n.navMore,
      ),
      // Cambia Business
      if (showSwitchBusiness)
        NavigationDestination(
          iconData: Icons.business_outlined,
          selectedIconData: Icons.business,
          label: l10n.switchBusiness,
        ),
      // Esci / Logout
      NavigationDestination(
        iconData: Icons.logout_outlined,
        selectedIconData: Icons.logout,
        label: l10n.authLogout,
      ),
    ];
  }

  static List<NavigationRailDestination> toRailDestinations(
    List<NavigationDestination> destinations,
  ) {
    return destinations
        .map(
          (d) => NavigationRailDestination(
            icon: _NavIcon(icon: d.iconData, label: d.label),
            selectedIcon: _NavIcon(
              icon: d.selectedIconData,
              label: d.label,
              selected: true,
            ),
            label: Text(d.label),
          ),
        )
        .toList();
  }
}

class _RailDivider extends StatelessWidget {
  const _RailDivider({
    required this.topInset,
    required this.color,
    required this.thickness,
  });

  final double topInset;
  final Color color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: thickness,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final inset = topInset.clamp(0.0, availableHeight);

          return Column(
            children: [
              SizedBox(height: inset),
              Expanded(child: Container(color: color)),
            ],
          );
        },
      ),
    );
  }
}

class _NavIcon extends StatefulWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon> {
  static const double _size = 52;
  static const double _iconSize = 24;

  bool _hovering = false;

  void _handleHover(bool hovering) {
    if (_hovering == hovering) return;
    setState(() => _hovering = hovering);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final iconColor = scheme.onSecondary.withOpacity(
      widget.selected ? 0.95 : 0.7,
    );

    final labelColor = scheme.onSecondary.withOpacity(
      widget.selected ? 0.95 : 0.65,
    );

    Color backgroundColor = Colors.transparent;

    if (widget.selected || _hovering) {
      // effetto "selected" o "hover": fill leggero
      backgroundColor = scheme.onSecondary.withOpacity(
        widget.selected ? 0.11 : 0.08,
      );
    }

    final baseTheme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: Theme(
        // disattiva splash / highlight di sistema su tap/long-press
        data: baseTheme.copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: _size,
          height: _size + 16, // Altezza extra per la label
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: iconColor, size: _iconSize),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 10,
                  fontWeight: widget.selected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationDestination {
  const NavigationDestination({
    required this.iconData,
    required this.selectedIconData,
    required this.label,
  });
  final IconData iconData;
  final IconData selectedIconData;
  final String label;
}

/// Refresh button for Report screen
class _ReportRefreshAction extends StatelessWidget {
  const _ReportRefreshAction({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => ref.read(reportsProvider.notifier).refresh(),
      icon: const Icon(Icons.refresh),
      tooltip: context.l10n.actionRefresh,
    );
  }
}

/// Refresh button for BookingsList screen
class _BookingsListRefreshAction extends StatelessWidget {
  const _BookingsListRefreshAction({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final businessId = ref.read(currentLocationProvider).businessId;
    return IconButton(
      onPressed: () =>
          ref.read(bookingsListProvider.notifier).loadBookings(businessId),
      icon: const Icon(Icons.refresh),
      tooltip: context.l10n.actionRefresh,
    );
  }
}

/// Add button for Closures screen
class _ClosuresAddAction extends ConsumerWidget {
  const _ClosuresAddAction({this.compact = false});
  final bool compact;
  static const double _actionButtonHeight = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final showLabel = layoutConfig.showTopbarAddLabel;
    final showLabelEffective = showLabel || formFactor != AppFormFactor.mobile;
    const iconOnlyWidth = 46.0;
    final bool isIconOnly = !showLabelEffective;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => LocationClosureDialog.show(context),
        child: Builder(
          builder: (buttonContext) {
            final scheme = Theme.of(buttonContext).colorScheme;
            final onContainer = scheme.onSecondaryContainer;
            return Material(
              elevation: 0,
              color: scheme.secondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: _actionButtonHeight,
                width: isIconOnly ? iconOnlyWidth : null,
                child: Padding(
                  padding: compact
                      ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                      : const EdgeInsets.fromLTRB(12, 8, 28, 8),
                  child: _buildAddButtonContent(
                    showLabelEffective: showLabelEffective,
                    compact: compact,
                    label: l10n.agendaAdd,
                    onContainer: onContainer,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Add button for Permessi screen
class _PermessiAddAction extends ConsumerWidget {
  const _PermessiAddAction({this.compact = false});
  final bool compact;
  static const double _actionButtonHeight = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final showLabel = layoutConfig.showTopbarAddLabel;
    final showLabelEffective = showLabel || formFactor != AppFormFactor.mobile;
    const iconOnlyWidth = 46.0;
    final bool isIconOnly = !showLabelEffective;
    final businessId = ref.watch(currentBusinessIdProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (ctx) => InviteOperatorDialog(businessId: businessId),
        ),
        child: Builder(
          builder: (buttonContext) {
            final scheme = Theme.of(buttonContext).colorScheme;
            final onContainer = scheme.onSecondaryContainer;
            return Material(
              elevation: 0,
              color: scheme.secondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: _actionButtonHeight,
                width: isIconOnly ? iconOnlyWidth : null,
                child: Padding(
                  padding: compact
                      ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                      : const EdgeInsets.fromLTRB(12, 8, 28, 8),
                  child: _buildAddButtonContent(
                    showLabelEffective: showLabelEffective,
                    compact: compact,
                    label: l10n.agendaAdd,
                    onContainer: onContainer,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
