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
              useIndicator: false, // disattiva highlight di sistema su tap
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
                icon: Icon(d.iconData),
                activeIcon: Icon(d.selectedIconData),
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
        iconData: Icons.cut_outlined,
        selectedIconData: Icons.cut,
        label: l10n.navServices,
      ),
      NavigationDestination(
        iconData: Icons.badge_outlined,
        selectedIconData: Icons.badge,
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
  static const double _iconSize = 28;
  static const double _tooltipHeight = 34;

  bool _hovering = false;
  OverlayEntry? _tooltipEntry;

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _handleHover(bool hovering) {
    if (_hovering == hovering) return;
    setState(() => _hovering = hovering);
    if (hovering) {
      _showTooltip();
    } else {
      _removeTooltip();
    }
  }

  void _showTooltip() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final iconGlobal = renderBox.localToGlobal(Offset.zero);
    final overlayGlobal = overlayBox.localToGlobal(Offset.zero);

    // distanza orizzontale dal NavigationRail: leggermente più vicina
    final dx = iconGlobal.dx - overlayGlobal.dx + renderBox.size.width + 18;
    final dy =
        iconGlobal.dy -
        overlayGlobal.dy +
        (renderBox.size.height - _tooltipHeight) / 2;

    _removeTooltip();
    _tooltipEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: dx,
          top: dy,
          child: _NavTooltipBubble(label: widget.label),
        );
      },
    );
    overlay.insert(_tooltipEntry!);
  }

  void _removeTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.secondary;

    final iconColor = scheme.onSecondary.withOpacity(
      widget.selected ? 0.95 : 0.7,
    );

    Color backgroundColor = Colors.transparent;

    if (widget.selected) {
      // effetto "selected": fill pieno
      backgroundColor = accent;
    } else if (_hovering) {
      // effetto "hover": fill leggero
      backgroundColor = scheme.onSecondary.withOpacity(0.08);
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
          height: _size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(widget.icon, color: iconColor, size: _iconSize),
        ),
      ),
    );
  }
}

class _NavTooltipBubble extends StatelessWidget {
  const _NavTooltipBubble({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const double arrowWidth = 8.0;
    final double arrowHeight = _NavIconState._tooltipHeight * 0.6;

    return CustomPaint(
      painter: _NavBubblePainter(
        color: Colors.black87,
        arrowWidth: arrowWidth,
        arrowHeight: arrowHeight,
        radius: 18,
      ),
      child: Container(
        height: _NavIconState._tooltipHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(left: 16 + arrowWidth),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _NavBubblePainter extends CustomPainter {
  const _NavBubblePainter({
    required this.color,
    required this.arrowWidth,
    required this.arrowHeight,
    required this.radius,
  });

  final Color color;
  final double arrowWidth;
  final double arrowHeight;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    // Ovale principale
    final bubbleRect = Rect.fromLTWH(
      arrowWidth,
      0,
      size.width - arrowWidth,
      size.height,
    );
    path.addRRect(RRect.fromRectAndRadius(bubbleRect, Radius.circular(radius)));

    // Freccia laterale integrata
    //final arrowTop = (size.height - arrowHeight) / 2;
    //path.moveTo(arrowWidth + 4, arrowTop);
    //path.lineTo(0, size.height / 2);
    //path.lineTo(arrowWidth + 4, arrowTop + arrowHeight);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NavBubblePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.arrowWidth != arrowWidth ||
        oldDelegate.arrowHeight != arrowHeight ||
        oldDelegate.radius != radius;
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
