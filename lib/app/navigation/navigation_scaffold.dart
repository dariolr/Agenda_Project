import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'navigation_controller.dart';
import 'navigation_destinations.dart';

class NavigationScaffold extends ConsumerWidget {
  final Widget child;
  const NavigationScaffold({super.key, required this.child});

  bool _isCompact(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 700; // soglia mobile
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSection = ref.watch(navigationControllerProvider);
    final destinations = AppSection.values;

    final router = GoRouter.of(context);

    void navigateTo(AppSection section) {
      if (section == selectedSection) return;
      ref.read(navigationControllerProvider.notifier).select(section);
      router.go(section.route);
    }

    if (_isCompact(context)) {
      // ✅ Bottom Navigation per mobile
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: destinations.indexOf(selectedSection),
          onDestinationSelected: (i) => navigateTo(destinations[i]),
          destinations: destinations
              .map(
                (s) =>
                    NavigationDestination(icon: Icon(s.icon), label: s.label),
              )
              .toList(),
        ),
      );
    } else {
      // ✅ NavigationRail per desktop/tablet
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.of(context).size.width > 1100,
              selectedIndex: destinations.indexOf(selectedSection),
              onDestinationSelected: (i) => navigateTo(destinations[i]),
              destinations: destinations
                  .map(
                    (s) => NavigationRailDestination(
                      icon: Icon(s.icon),
                      label: Text(s.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }
  }
}
