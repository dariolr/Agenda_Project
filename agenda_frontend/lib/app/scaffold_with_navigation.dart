// Cleaned duplicate header
import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:agenda_frontend/app/widgets/agenda_control_components.dart';
import 'package:agenda_frontend/features/agenda/presentation/screens/widgets/agenda_dividers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/l10n/l10_extension.dart';
import '../core/widgets/adaptive_dropdown.dart';
import '../core/widgets/app_buttons.dart';
import '../features/agenda/presentation/dialogs/add_block_dialog.dart';
import '../features/agenda/presentation/widgets/agenda_top_controls.dart';
import '../features/agenda/presentation/widgets/booking_dialog.dart';
import '../features/agenda/providers/date_range_provider.dart';
import '../features/agenda/providers/layout_config_provider.dart';
import '../features/clients/presentation/dialogs/client_edit_dialog.dart';
import '../features/services/presentation/dialogs/category_dialog.dart';
import '../features/services/presentation/dialogs/service_dialog.dart';
import '../features/services/providers/services_reorder_provider.dart';

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
    final destinations = _ScaffoldWithNavigationHelpers.getDestinations(
      context,
    );
    final formFactor = ref.watch(formFactorProvider);

    if (formFactor == AppFormFactor.desktop) {
      final layoutConfig = ref.watch(layoutConfigProvider);
      final dividerColor = Theme.of(context).dividerColor;
      const dividerThickness = 1.0;
      final railDestinations =
          _ScaffoldWithNavigationHelpers.toRailDestinations(destinations);
      final isAgenda = navigationShell.currentIndex == 0;
      final isClients = navigationShell.currentIndex == 1;
      final isServices = navigationShell.currentIndex == 2;

      final isTablet = formFactor == AppFormFactor.tablet;

      return Scaffold(
        appBar: AppBar(
          titleSpacing: isTablet && isAgenda
              ? 4
              : NavigationToolbar.kMiddleSpacing,
          title: isAgenda ? const AgendaTopControls() : const SizedBox.shrink(),
          centerTitle: false,
          toolbarHeight: 76,
          actions: isAgenda
              ? [const _AgendaAddAction()]
              : (isServices
                    ? [const _ServicesAddAction()]
                    : (isClients ? [const _ClientsAddAction()] : null)),
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
                onDestinationSelected: (index) => _goBranch(index, ref),
                labelType: NavigationRailLabelType.none,
                useIndicator: false, // disattiva highlight di sistema su tap
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

    final isAgenda = navigationShell.currentIndex == 0;
    final isClients = navigationShell.currentIndex == 1;
    final isServices = navigationShell.currentIndex == 2;
    final isTablet = formFactor == AppFormFactor.tablet;
    final showBottomDateSwitcher =
        isAgenda && formFactor == AppFormFactor.mobile;
    final bottomNavColor =
        Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.surface;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isTablet ? 76 : 64,
        titleSpacing: isAgenda ? 4 : NavigationToolbar.kMiddleSpacing,
        title: isAgenda
            ? const AgendaTopControls(compact: true)
            : const SizedBox.shrink(),
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
                onTap: (index) => _goBranch(index, ref),
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
}

class _AgendaAddAction extends ConsumerWidget {
  const _AgendaAddAction({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final agendaDate = ref.watch(agendaDateProvider);
    final scheme = Theme.of(context).colorScheme;
    final onContainer = scheme.onSecondaryContainer;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final showLabel = layoutConfig.showTopbarAddLabel;
    final showLabelEffective = showLabel || formFactor != AppFormFactor.mobile;

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
    );
  }
}

class _ServicesAddAction extends ConsumerWidget {
  const _ServicesAddAction({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final onContainer = scheme.onSecondaryContainer;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final showLabel = layoutConfig.showTopbarAddLabel;
    final showLabelEffective = showLabel || formFactor != AppFormFactor.mobile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: l10n.reorderTitle,
            child: SizedBox(
              height: 36,
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
                child: const Icon(Icons.sort, size: 20),
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
        ],
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
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final showLabel = layoutConfig.showTopbarAddLabel;
    final showLabelEffective = showLabel || formFactor != AppFormFactor.mobile;
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 28, 8),
                child: _buildAddButtonContent(
                  showLabelEffective: showLabelEffective,
                  compact: compact,
                  label: l10n.agendaAdd,
                  onContainer: onContainer,
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
