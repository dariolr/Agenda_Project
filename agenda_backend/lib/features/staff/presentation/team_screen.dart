import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/location.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/widgets/app_dialogs.dart';
import 'package:agenda_backend/core/widgets/reorder_toggle_button.dart';
import 'package:agenda_backend/core/widgets/reorder_toggle_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../agenda/providers/location_providers.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../providers/staff_providers.dart';
import '../providers/staff_reorder_provider.dart';
import '../providers/staff_sorted_providers.dart';
import 'dialogs/location_dialog.dart';
import 'dialogs/staff_dialog.dart';
import 'screens/resources_screen.dart';
import 'widgets/location_item.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isReorderLocations = false;
  bool isReorderStaff = false;

  // NOTE: Non serve initState con refresh() perché:
  // 1. I provider AsyncNotifier caricano i dati automaticamente nel build()
  // 2. Il refresh al cambio tab avviene in _refreshProvidersForTab()

  void _toggleLocationReorder() {
    setState(() {
      isReorderLocations = !isReorderLocations;
      if (isReorderLocations) isReorderStaff = false;
    });
    if (!isReorderLocations) {
      ref.read(teamReorderPanelProvider.notifier).setVisible(false);
    }
  }

  void _toggleStaffReorder() {
    setState(() {
      isReorderStaff = !isReorderStaff;
      if (isReorderStaff) isReorderLocations = false;
    });
    if (!isReorderStaff) {
      ref.read(teamReorderPanelProvider.notifier).setVisible(false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(sortedLocationsProvider);
    final staffAsync = ref.watch(allStaffProvider);
    final isWide = ref.watch(formFactorProvider) != AppFormFactor.mobile;
    final showReorderPanel = ref.watch(teamReorderPanelProvider);

    ref.listen<bool>(teamReorderPanelProvider, (previous, next) {
      if (!next && (isReorderLocations || isReorderStaff)) {
        setState(() {
          isReorderLocations = false;
          isReorderStaff = false;
        });
      }
      // Se apro il pannello e c'è solo 1 location, attiva subito riordino staff
      if (next && previous == false && locations.length < 2) {
        setState(() {
          isReorderStaff = true;
          isReorderLocations = false;
        });
      }
    });

    // Mostra loading mentre carica staff
    if (staffAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (locations.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showReorderPanel) ...[
            Builder(
              builder: (context) {
                // Conta lo staff totale
                final totalStaffCount = staffAsync.value?.length ?? 0;
                final showLocationReorder = locations.length >= 2;
                final showStaffReorder = totalStaffCount >= 2;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          context.l10n.reorderTitle,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                          child: Text(
                            context.l10n.teamReorderHelpDescription,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        ReorderTogglePanel(
                          isWide: isWide,
                          children: [
                            if (showLocationReorder)
                              ReorderToggleButton(
                                isActive: isReorderLocations,
                                onPressed: _toggleLocationReorder,
                                activeLabel: context.l10n.teamLocationsLabel,
                                inactiveLabel: context.l10n.teamLocationsLabel,
                                activeIcon: Icons.check,
                                inactiveIcon: Icons.drag_indicator,
                              ),
                            if (showStaffReorder)
                              ReorderToggleButton(
                                isActive: isReorderStaff,
                                onPressed: _toggleStaffReorder,
                                activeLabel: context.l10n.teamStaffLabel,
                                inactiveLabel: context.l10n.teamStaffLabel,
                                activeIcon: Icons.check,
                                inactiveIcon: Icons.drag_indicator,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          Expanded(
            child: isReorderLocations
                ? _buildReorderLocations(context, ref, locations)
                : isReorderStaff
                ? _buildReorderStaff(context, ref, locations)
                : _buildNormalList(context, ref, locations, isWide),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderLocations(
    BuildContext context,
    WidgetRef ref,
    List<Location> locations,
  ) {
    final notifier = ref.read(teamReorderProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => child,
      itemCount: locations.length,
      onReorder: (oldIndex, newIndex) =>
          notifier.reorderLocations(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final loc = locations[index];
        return Container(
          key: ValueKey('loc-${loc.id}'),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_indicator),
            ),
            title: Text(loc.name),
          ),
        );
      },
    );
  }

  Widget _buildReorderStaff(
    BuildContext context,
    WidgetRef ref,
    List<Location> locations,
  ) {
    final notifier = ref.read(teamReorderProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final staffByLocation = <int, List<Staff>>{
      for (final loc in locations)
        loc.id: ref.watch(staffByLocationProvider(loc.id)),
    };

    final rows = <({bool isHeader, int locationId, Staff? staff})>[];
    for (final loc in locations) {
      rows.add((isHeader: true, locationId: loc.id, staff: null));
      for (final member in staffByLocation[loc.id] ?? const <Staff>[]) {
        rows.add((isHeader: false, locationId: loc.id, staff: member));
      }
    }

    int indexInLocation(int rowIndex) {
      final locationId = rows[rowIndex].locationId;
      int count = 0;
      for (int i = 0; i < rowIndex; i++) {
        final row = rows[i];
        if (!row.isHeader && row.locationId == locationId) count++;
      }
      return count;
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => child,
      itemCount: rows.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        if (newIndex >= rows.length) newIndex = rows.length - 1;
        final moving = rows[oldIndex];
        if (moving.isHeader) return;
        if (rows[newIndex].isHeader) {
          if (rows[newIndex].locationId == moving.locationId) {
            newIndex = (newIndex + 1).clamp(0, rows.length - 1);
          } else {
            return;
          }
        }
        final target = rows[newIndex];
        if (target.locationId != moving.locationId) return;
        notifier.reorderStaffForLocation(
          moving.locationId,
          indexInLocation(oldIndex),
          indexInLocation(newIndex),
        );
      },
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row.isHeader) {
          final loc = locations.firstWhere((l) => l.id == row.locationId);
          return Container(
            key: ValueKey('header-${loc.id}'),
            width: double.infinity,
            margin: const EdgeInsets.only(top: 16, bottom: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Text(
              loc.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          );
        }

        final member = row.staff!;
        return Container(
          key: ValueKey('staff-${row.locationId}-${member.id}'),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.7),
            ),
          ),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_indicator),
            ),
            title: Text(member.displayName),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNormalList(
    BuildContext context,
    WidgetRef ref,
    List<Location> locations,
    bool isWide,
  ) {
    final canManageStaff = ref.watch(currentUserCanManageStaffProvider);
    final canManageSettings = ref.watch(canManageBusinessSettingsProvider);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final loc = locations[index];
        final staff = ref.watch(staffByLocationProvider(loc.id));
        return LocationItem(
          location: loc,
          staff: staff,
          isWide: isWide,
          onAddStaff: canManageStaff
              ? () => showStaffDialog(context, ref, initialLocationId: loc.id)
              : () {},
          onManageResources: canManageSettings
              ? () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ResourcesScreen(location: loc),
                  ),
                )
              : null,
          onEditLocation: canManageSettings
              ? () => showLocationDialog(context, ref, initial: loc)
              : () {},
          onDeleteLocation: () async {
            if (!canManageSettings) return;
            if (staff.isNotEmpty) {
              await showAppInfoDialog(
                context,
                title: Text(context.l10n.teamDeleteLocationBlockedTitle),
                content: Text(context.l10n.teamDeleteLocationBlockedMessage),
              );
              return;
            }
            final confirmed = await showConfirmDialog(
              context,
              title: Text(context.l10n.teamDeleteLocationTitle),
              content: Text(context.l10n.teamDeleteLocationMessage),
              confirmLabel: context.l10n.actionConfirm,
              cancelLabel: context.l10n.actionCancel,
            );
            if (confirmed == true) {
              final currentId = ref.read(currentLocationIdProvider);
              await ref
                  .read(locationsProvider.notifier)
                  .deleteLocation(loc.id, currentLocationId: currentId);
            }
          },
          onEditStaff: canManageStaff
              ? (staff) => showStaffDialog(context, ref, initial: staff)
              : (_) {},
          onDuplicateStaff: canManageStaff
              ? (staff) => showStaffDialog(
                  context,
                  ref,
                  initial: staff,
                  duplicateFrom: true,
                )
              : (_) {},
          onDeleteStaff: (staff) async {
            if (!canManageStaff) return;
            final confirmed = await showConfirmDialog(
              context,
              title: Text(context.l10n.teamDeleteStaffTitle),
              content: Text(context.l10n.teamDeleteStaffMessage),
              confirmLabel: context.l10n.actionConfirm,
              cancelLabel: context.l10n.actionCancel,
            );
            if (confirmed == true) {
              await ref
                  .read(allStaffProvider.notifier)
                  .deleteStaffApi(staff.id);
            }
          },
        );
      },
    );
  }
}
