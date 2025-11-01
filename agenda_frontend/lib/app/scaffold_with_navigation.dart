import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Importa Riverpod
import 'package:go_router/go_router.dart';

import '../core/l10n/l10_extension.dart';
import '../features/agenda/providers/layout_config_provider.dart';
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
    final destinations = _getDestinations(context);

    // 5. LEGGI IL PROVIDER GLOBALE!
    final formFactor = ref.watch(formFactorProvider);

    // 6. Usa il formFactor per decidere il layout
    if (formFactor == AppFormFactor.tabletOrDesktop) {
      final layoutConfig = ref.watch(layoutConfigProvider);
      final dividerColor = Theme.of(context).dividerColor;
      const dividerThickness = 1.0;

      // 🎯 TARGET WEB/DESKTOP/TABLET: NavigationRail
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _getLocalizedTitle(context, navigationShell.currentIndex),
          ),
          centerTitle: false,
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _goBranch(index),
              labelType: NavigationRailLabelType.none,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Tooltip(message: d.label, child: d.icon),
                      selectedIcon:
                          Tooltip(message: d.label, child: d.selectedIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
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
        title: Text(_getLocalizedTitle(context, navigationShell.currentIndex)),
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
  String _getLocalizedTitle(BuildContext context, int index) {
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

  List<NavigationDestination> _getDestinations(BuildContext context) {
    final l10n = context.l10n;
    return [
      NavigationDestination(
        icon: _NavIcon(icon: Icons.calendar_month_outlined),
        selectedIcon: _NavIcon(icon: Icons.calendar_month, selected: true),
        label: l10n.navAgenda,
      ),
      NavigationDestination(
        icon: _NavIcon(icon: Icons.people_outline),
        selectedIcon: _NavIcon(icon: Icons.people, selected: true),
        label: l10n.navClients,
      ),
      NavigationDestination(
        icon: _NavIcon(icon: Icons.cut_outlined),
        selectedIcon: _NavIcon(icon: Icons.cut, selected: true),
        label: l10n.navServices,
      ),
      NavigationDestination(
        icon: _NavIcon(icon: Icons.badge_outlined),
        selectedIcon: _NavIcon(icon: Icons.badge, selected: true),
        label: l10n.navStaff,
      ),
    ];
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
    final cardColor = theme.cardTheme.color ?? colorScheme.surface;
    final iconColor = selected ? colorScheme.primary : colorScheme.onPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: selected ? cardColor : Colors.transparent,
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
