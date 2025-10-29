import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Importa Riverpod
import 'package:go_router/go_router.dart';

import '../core/l10n/l10_extension.dart';
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
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
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
        icon: const Icon(Icons.calendar_month_outlined),
        selectedIcon: const Icon(Icons.calendar_month),
        label: l10n.navAgenda,
      ),
      NavigationDestination(
        icon: const Icon(Icons.people_outline),
        selectedIcon: const Icon(Icons.people),
        label: l10n.navClients,
      ),
      NavigationDestination(
        icon: const Icon(Icons.cut_outlined),
        selectedIcon: const Icon(Icons.cut),
        label: l10n.navServices,
      ),
      NavigationDestination(
        icon: const Icon(Icons.badge_outlined),
        selectedIcon: const Icon(Icons.badge),
        label: l10n.navStaff,
      ),
    ];
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
