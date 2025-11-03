import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Importa Riverpod
import 'package:go_router/go_router.dart';

import '../core/l10n/l10_extension.dart';
import '../features/agenda/providers/layout_config_provider.dart';
import '../features/agenda/presentation/widgets/agenda_top_controls.dart';
// 2. Importa il nuovo provider globale
import 'providers/form_factor_provider.dart';

// 3. Trasforma in ConsumerWidget
class ScaffoldWithNavigation extends ConsumerWidget {
  const ScaffoldWithNavigation({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // ... (le funzioni helper _getLocalizedTitle e _getDestinations non cambiano) ...
  // [CODICE HELPER OMESSO PER BREVITÀ]

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 4. Aggiungi WidgetRef
    final destinations =
        _ScaffoldWithNavigationHelpers.getDestinations(context);

    // 5. LEGGI IL PROVIDER GLOBALE!
    final formFactor = ref.watch(formFactorProvider);

    // 6. Usa il formFactor per decidere il layout
    if (formFactor == AppFormFactor.tabletOrDesktop) {
      final layoutConfig = ref.watch(layoutConfigProvider);
      final dividerColor = Theme.of(context).dividerColor;
      const dividerThickness = 1.0;
      final railDestinations =
          _ScaffoldWithNavigationHelpers.toRailDestinations(destinations);
      final isAgenda = navigationShell.currentIndex == 0;

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

    // 🎯 TARGET MOBILE: BottomNavigationBar
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _ScaffoldWithNavigationHelpers.getLocalizedTitle(
            context,
            navigationShell.currentIndex,
          ),
        ),
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

  // ... (la funzione _goBranch non cambia) ...
  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  // ... (le funzioni helper omesse prima) ...
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
        selectedIcon: const _NavIcon(icon: Icons.calendar_month, selected: true),
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
              Expanded(
                child: Container(color: color),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    this.selected = false,
  });

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.secondary;
    final iconColor = colorScheme.onSecondary.withOpacity(selected ? 0.9 : 0.7);
    final backgroundColor =
        selected ? accentColor : accentColor.withOpacity(0.35);

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

// Classe helper (invariata)
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
