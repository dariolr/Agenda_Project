// Cleaned duplicate header
import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/app/widgets/agenda_control_components.dart';
import 'package:agenda_backend/app/widgets/agenda_staff_filter_selector.dart';
import 'package:agenda_backend/app/widgets/top_controls.dart';
import 'package:agenda_backend/app/widgets/user_menu_button.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/agenda_dividers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/l10n/l10_extension.dart';
import '../core/models/location.dart';
import '../core/widgets/adaptive_dropdown.dart';
import '../core/widgets/app_bottom_sheet.dart';
import '../core/widgets/app_buttons.dart';
import '../features/agenda/presentation/dialogs/add_block_dialog.dart';
import '../features/agenda/presentation/widgets/agenda_top_controls.dart';
import '../features/agenda/presentation/widgets/booking_dialog.dart';
import '../features/agenda/providers/date_range_provider.dart';
import '../features/agenda/providers/layout_config_provider.dart';
import '../features/agenda/providers/location_providers.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/business/presentation/business_list_screen.dart';
import '../features/clients/presentation/dialogs/client_edit_dialog.dart';
import '../features/services/presentation/dialogs/category_dialog.dart';
import '../features/services/presentation/dialogs/service_dialog.dart';
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
    final agendaDate = ref.watch(agendaDateProvider);
    final isToday = DateUtils.isSameDay(
      agendaDate,
      DateUtils.dateOnly(DateTime.now()),
    );
    final user = ref.watch(authProvider).user;
    final isSuperadmin = user?.isSuperadmin ?? false;

    final destinations = _ScaffoldWithNavigationHelpers.getDestinations(
      context,
      isSuperadmin: isSuperadmin,
    );
    final resolvedDestinations = isAgenda && !isToday
        ? [
            NavigationDestination(
              iconData: Icons.today_outlined,
              selectedIconData: Icons.today,
              label: context.l10n.agendaToday,
            ),
            ...destinations.skip(1),
          ]
        : destinations;

    if (formFactor == AppFormFactor.desktop) {
      final layoutConfig = ref.watch(layoutConfigProvider);
      final dividerColor = Theme.of(context).dividerColor;
      const dividerThickness = 1.0;
      final railDestinations =
          _ScaffoldWithNavigationHelpers.toRailDestinations(
            resolvedDestinations,
          );

      final isTablet = formFactor == AppFormFactor.tablet;

      // Azioni specifiche per tab (menu utente è nella rail)
      List<Widget> buildActions() {
        final List<Widget> actions = [];
        if (isAgenda) {
          actions.add(const _AgendaAddAction());
        } else if (isServices) {
          actions.add(const _ServicesAddAction());
        } else if (isClients) {
          actions.add(const _ClientsAddAction());
        } else if (isStaff) {
          actions.add(const _TeamAddAction());
        }
        return actions;
      }

      return Scaffold(
        appBar: AppBar(
          titleSpacing: isTablet && isAgenda
              ? 4
              : NavigationToolbar.kMiddleSpacing,
          title: isAgenda ? const AgendaTopControls() : const SizedBox.shrink(),
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
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) =>
                    _handleNavTap(context, index, ref),
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
      );
    }

    final isTablet = formFactor == AppFormFactor.tablet;
    final showBottomDateSwitcher =
        isAgenda && formFactor != AppFormFactor.desktop;
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
        actions.add(const _AgendaAddAction(compact: true));
      } else if (isServices) {
        actions.add(const _ServicesAddAction(compact: true));
      } else if (isClients) {
        actions.add(const _ClientsAddAction(compact: true));
      } else if (isStaff) {
        actions.add(const _TeamAddAction(compact: true));
      }
      return actions;
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isTablet ? 76 : 64,
        titleSpacing: isAgenda ? 4 : NavigationToolbar.kMiddleSpacing,
        title: isAgenda
            ? const AgendaTopControls(compact: true)
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
                currentIndex: navigationShell.currentIndex,
                onTap: (index) => _handleNavTap(context, index, ref),
                type: BottomNavigationBarType.fixed,
                items: resolvedDestinations
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
    );
  }

  void _goBranch(int index, WidgetRef ref) {
    if (index == 0 && navigationShell.currentIndex == 0) {
      final selectedDate = ref.read(agendaDateProvider);
      final today = DateUtils.dateOnly(DateTime.now());
      if (!DateUtils.isSameDay(selectedDate, today)) {
        ref.read(agendaDateProvider.notifier).setToday();
      }
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// Gestisce tap su navigation: se è index 4, mostra menu utente
  void _handleNavTap(BuildContext context, int index, WidgetRef ref) {
    if (index == 4) {
      _showUserMenu(context, ref);
    } else {
      _goBranch(index, ref);
    }
  }

  /// Mostra il menu utente (profilo, cambia password, logout)
  void _showUserMenu(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final menuItems = UserMenuButton.buildMenuItems(
      context,
      theme,
      colorScheme,
      user,
    );

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200,
        MediaQuery.of(context).size.height - 250,
        16,
        16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: menuItems,
    ).then((value) {
      if (value == null || !context.mounted) return;
      if (value == 'logout') {
        UserMenuButton.handleLogout(context, ref);
      } else if (value == 'profile') {
        context.push('/profilo');
      } else if (value == 'change_password') {
        context.push('/change-password');
      } else if (value == 'switch_business') {
        ref.read(superadminSelectedBusinessProvider.notifier).clear();
        context.go('/businesses');
      }
    });
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
    final showStaffSelector = staffCount > 1;
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
            ],
            onSelected: (value) {
              if (value == 'category') {
                showCategoryDialog(context, ref);
              } else if (value == 'service') {
                showServiceDialog(context, ref, requireCategorySelection: true);
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
          // Pulsante Modifica ordinamento: visibile solo se almeno 2 staff o 2 locations
          if (staffCount >= 2 || locationCount >= 2) ...[
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
  static List<NavigationDestination> getDestinations(
    BuildContext context, {
    bool isSuperadmin = false,
  }) {
    final l10n = context.l10n;
    return [
      NavigationDestination(
        iconData: Icons.calendar_month_outlined,
        selectedIconData: Icons.calendar_month,
        label: l10n.navAgenda,
      ),
      NavigationDestination(
        iconData: Icons.people_outline,
        selectedIconData: Icons.people,
        label: l10n.navClients,
      ),
      NavigationDestination(
        iconData: Icons.category_outlined,
        selectedIconData: Icons.cut,
        label: l10n.navServices,
      ),
      NavigationDestination(
        iconData: Icons.badge_outlined,
        selectedIconData: Icons.badge,
        label: l10n.navStaff,
      ),
      NavigationDestination(
        iconData: Icons.account_circle_outlined,
        selectedIconData: Icons.account_circle,
        label: l10n.navProfile,
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
