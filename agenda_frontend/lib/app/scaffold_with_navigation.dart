// Cleaned duplicate header
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10_extension.dart';
import '../features/agenda/presentation/widgets/agenda_top_controls.dart';
import '../features/agenda/presentation/widgets/appointment_dialog.dart';
import '../features/agenda/providers/date_range_provider.dart';
import '../features/agenda/providers/layout_config_provider.dart';
import '../features/clients/presentation/dialogs/client_edit_dialog.dart';
import '../features/services/presentation/dialogs/category_dialog.dart';
import '../features/services/presentation/dialogs/service_dialog.dart';
import 'providers/form_factor_provider.dart';

class ScaffoldWithNavigation extends ConsumerWidget {
  const ScaffoldWithNavigation({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = _ScaffoldWithNavigationHelpers.getDestinations(
      context,
    );
    final formFactor = ref.watch(formFactorProvider);

    if (formFactor != AppFormFactor.mobile) {
      final layoutConfig = ref.watch(layoutConfigProvider);
      final dividerColor = Theme.of(context).dividerColor;
      const dividerThickness = 1.0;
      final railDestinations =
          _ScaffoldWithNavigationHelpers.toRailDestinations(destinations);
      final isAgenda = navigationShell.currentIndex == 0;
      final isClients = navigationShell.currentIndex == 1;
      final isServices = navigationShell.currentIndex == 2;

      return Scaffold(
        appBar: AppBar(
          title: isAgenda
              ? const AgendaTopControls()
              : Text(
                  _ScaffoldWithNavigationHelpers.getLocalizedTitle(
                    context,
                    navigationShell.currentIndex,
                  ),
                ),
          centerTitle: false,
          toolbarHeight: 72,
          actions: isAgenda
              ? [const _AgendaAddAction()]
              : (isServices
                    ? [const _ServicesAddAction()]
                    : (isClients ? [const _ClientsAddAction()] : null)),
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _goBranch(index),
              labelType: NavigationRailLabelType.none,
              destinations: railDestinations,
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

    final isAgenda = navigationShell.currentIndex == 0;
    final isClients = navigationShell.currentIndex == 1;
    final isServices = navigationShell.currentIndex == 2;
    return Scaffold(
      appBar: AppBar(
        title: isAgenda
            ? const AgendaTopControls(compact: true)
            : Text(
                _ScaffoldWithNavigationHelpers.getLocalizedTitle(
                  context,
                  navigationShell.currentIndex,
                ),
              ),
        centerTitle: false,
        actions: isAgenda
            ? const [_AgendaAddAction(compact: true)]
            : (isServices
                  ? const [_ServicesAddAction(compact: true)]
                  : (isClients
                        ? const [_ClientsAddAction(compact: true)]
                        : null)),
      ),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _goBranch(index),
        type: BottomNavigationBarType.fixed,
        items: destinations
            .map(
              (d) => BottomNavigationBarItem(
                icon: d.icon,
                activeIcon: d.selectedIcon,
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _AgendaAddAction extends ConsumerWidget {
  const _AgendaAddAction({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final agendaDate = ref.watch(agendaDateProvider);
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 16),
        child: PopupMenuButton<String>(
          tooltip: l10n.agendaAdd,
          icon: const Icon(Icons.add_outlined, size: 22),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'appointment',
              child: Text(l10n.agendaAddAppointment),
            ),
            PopupMenuItem(value: 'block', child: Text(l10n.agendaAddBlock)),
          ],
          onSelected: (value) async {
            if (value == 'appointment') {
              await showAppointmentDialog(context, ref, date: agendaDate);
            } else if (value == 'block') {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.agendaAddBlock)));
            }
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: PopupMenuButton<String>(
        tooltip: l10n.agendaAdd,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'appointment',
            child: Text(l10n.agendaAddAppointment),
          ),
          PopupMenuItem(value: 'block', child: Text(l10n.agendaAddBlock)),
        ],
        onSelected: (value) {
          if (value == 'appointment') {
            showAppointmentDialog(context, ref, date: agendaDate);
          } else if (value == 'block') {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.agendaAddBlock)));
          }
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 28, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_outlined, size: 22, color: onContainer),
                    const SizedBox(width: 8),
                    Text(
                      l10n.agendaAdd,
                      style: TextStyle(
                        color: onContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ServicesAddAction extends ConsumerWidget {
  const _ServicesAddAction({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 16),
        child: PopupMenuButton<String>(
          tooltip: l10n.agendaAdd,
          icon: const Icon(Icons.add_outlined, size: 22),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'category',
              child: Text(l10n.createCategoryButtonLabel),
            ),
            PopupMenuItem(
              value: 'service',
              child: Text(l10n.servicesNewServiceMenu),
            ),
          ],
          onSelected: (value) async {
            if (value == 'category') {
              await showCategoryDialog(context, ref);
            } else if (value == 'service') {
              await showServiceDialog(
                context,
                ref,
                requireCategorySelection: true,
              );
            }
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 24),
      child: PopupMenuButton<String>(
        tooltip: l10n.agendaAdd,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'category',
            child: Text(l10n.createCategoryButtonLabel),
          ),
          PopupMenuItem(
            value: 'service',
            child: Text(l10n.servicesNewServiceMenu),
          ),
        ],
        onSelected: (value) async {
          if (value == 'category') {
            await showCategoryDialog(context, ref);
          } else if (value == 'service') {
            await showServiceDialog(
              context,
              ref,
              requireCategorySelection: true,
            );
          }
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 28, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_outlined, size: 22, color: onContainer),
                    const SizedBox(width: 8),
                    Text(
                      l10n.agendaAdd,
                      style: TextStyle(
                        color: onContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ClientsAddAction extends ConsumerWidget {
  const _ClientsAddAction({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, right: 16),
        child: IconButton(
          tooltip: l10n.clientsNew,
          icon: const Icon(Icons.add_outlined, size: 22),
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (_) => const ClientEditDialog(),
            );
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () async {
          await showDialog(
            context: context,
            builder: (_) => const ClientEditDialog(),
          );
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 28, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_outlined, size: 22, color: onContainer),
                    const SizedBox(width: 8),
                    Text(
                      l10n.agendaAdd,
                      style: TextStyle(
                        color: onContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScaffoldWithNavigationHelpers {
  static String getLocalizedTitle(BuildContext context, int index) {
    final l10n = context.l10n;
    switch (index) {
      case 0:
        return l10n.navAgenda;
      case 1:
        return l10n.navClients;
      case 2:
        return l10n.navServices;
      case 3:
        return l10n.navStaff;
      default:
        return l10n.appTitle;
    }
  }

  static List<NavigationDestination> getDestinations(BuildContext context) {
    final l10n = context.l10n;
    return [
      NavigationDestination(
        icon: const _NavIcon(icon: Icons.calendar_month_outlined),
        selectedIcon: const _NavIcon(
          icon: Icons.calendar_month,
          selected: true,
        ),
        label: l10n.navAgenda,
      ),
      NavigationDestination(
        icon: const _NavIcon(icon: Icons.people_outline),
        selectedIcon: const _NavIcon(icon: Icons.people, selected: true),
        label: l10n.navClients,
      ),
      NavigationDestination(
        icon: const _NavIcon(icon: Icons.cut_outlined),
        selectedIcon: const _NavIcon(icon: Icons.cut, selected: true),
        label: l10n.navServices,
      ),
      NavigationDestination(
        icon: const _NavIcon(icon: Icons.badge_outlined),
        selectedIcon: const _NavIcon(icon: Icons.badge, selected: true),
        label: l10n.navStaff,
      ),
    ];
  }

  static List<NavigationRailDestination> toRailDestinations(
    List<NavigationDestination> destinations,
  ) {
    return destinations
        .map(
          (d) => NavigationRailDestination(
            icon: Tooltip(message: d.label, child: d.icon),
            selectedIcon: Tooltip(message: d.label, child: d.selectedIcon),
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

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, this.selected = false});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.secondary;
    final iconColor = colorScheme.onSecondary.withOpacity(selected ? 0.9 : 0.7);
    final backgroundColor = selected
        ? accentColor
        : accentColor.withOpacity(0.35);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor),
    );
  }
}

class NavigationDestination {
  const NavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final Widget icon;
  final Widget selectedIcon;
  final String label;
}
