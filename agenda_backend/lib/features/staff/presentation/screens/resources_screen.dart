import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/location.dart';
import '../../../../core/models/resource.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dividers.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../agenda/providers/layout_config_provider.dart';
import '../../../agenda/providers/resource_providers.dart';
import '../../../auth/providers/current_business_user_provider.dart';
import '../../providers/staff_providers.dart';
import '../../providers/staff_sorted_providers.dart';
import '../dialogs/resource_dialog.dart';
import '../widgets/location_item.dart';

/// Provider che carica il conteggio servizi per ogni risorsa della location
final resourceServiceCountsProvider = FutureProvider.family<Map<int, int>, int>(
  (ref, locationId) async {
    final apiClient = ref.watch(apiClientProvider);
    final resources = ref.watch(locationResourcesProvider(locationId));

    final counts = <int, int>{};
    for (final resource in resources) {
      try {
        final response = await apiClient.getResourceServices(resource.id);
        final services = response['services'] as List? ?? [];
        counts[resource.id] = services.length;
      } catch (_) {
        counts[resource.id] = 0;
      }
    }
    return counts;
  },
);

class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({
    super.key,
    required this.location,
    this.showAppBar = true,
    this.enableLocationSelectionInForm = false,
  });

  final Location location;
  final bool showAppBar;
  final bool enableLocationSelectionInForm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectableLocations = enableLocationSelectionInForm
        ? ref.watch(sortedLocationsProvider)
        : const <Location>[];
    final resources = ref.watch(locationResourcesProvider(location.id));
    final serviceCountsAsync = ref.watch(
      resourceServiceCountsProvider(location.id),
    );
    final serviceCounts = serviceCountsAsync.value ?? {};

    final listBody = resources.isEmpty
        ? const _EmptyState()
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: resources.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final resource = resources[index];
              final serviceCount = serviceCounts[resource.id] ?? 0;
              return _ResourceCard(
                resource: resource,
                serviceCount: serviceCount,
                onEdit: () => showResourceDialog(
                  context,
                  ref,
                  locationId: location.id,
                  resource: resource,
                  selectableLocations: selectableLocations,
                ),
                onDelete: () => _confirmDelete(context, ref, resource),
              );
            },
          );

    final body = enableLocationSelectionInForm
        ? _ResourcesByLocationList(
            locations: selectableLocations,
            selectableLocations: selectableLocations,
          )
        : listBody;

    if (!showAppBar) return body;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: AppBackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(l10n.resourcesTitle),
        centerTitle: false,
        actions: [
          _StandaloneResourcesAddAction(
            locationId: location.id,
            selectableLocations: selectableLocations,
          ),
        ],
      ),
      body: body,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Resource resource,
  ) async {
    final l10n = context.l10n;

    await showAppConfirmDialog(
      context,
      title: Text(l10n.resourceDeleteConfirm),
      content: Text(l10n.resourceDeleteWarning),
      confirmLabel: l10n.actionDelete,
      cancelLabel: l10n.actionCancel,
      danger: true,
      onConfirm: () async {
        await ref.read(resourcesProvider.notifier).deleteResource(resource.id);
      },
    );
  }
}

class _ResourcesByLocationList extends ConsumerWidget {
  const _ResourcesByLocationList({
    required this.locations,
    required this.selectableLocations,
  });

  final List<Location> locations;
  final List<Location> selectableLocations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (locations.isEmpty) {
      return const _EmptyState();
    }

    final formFactor = ref.watch(formFactorProvider);
    final topPadding = formFactor == AppFormFactor.desktop ? 0.0 : 16.0;
    final canManageSettings = ref.watch(canManageBusinessSettingsProvider);
    final canViewStaff = ref.watch(currentUserCanViewStaffProvider);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        final resources = ref.watch(locationResourcesProvider(location.id));
        final serviceCountsAsync = ref.watch(
          resourceServiceCountsProvider(location.id),
        );
        final serviceCounts = serviceCountsAsync.value ?? {};

        return LocationItem(
          location: location,
          staff: const [],
          isWide: MediaQuery.sizeOf(context).width >= 720,
          showDefaultActions: false,
          readOnly: !canManageSettings,
          headerTrailing: _LocationResourcesActions(
            location: location,
            selectableLocations: selectableLocations,
            canViewStaff: canViewStaff,
            canManageSettings: canManageSettings,
          ),
          onAddStaff: () {},
          onEditLocation: () {},
          onDeleteLocation: () {},
          onEditStaff: (_) {},
          onDuplicateStaff: (_) {},
          onDeleteStaff: (_) {},
          staffListOverride: _LocationResourcesBody(
            locationId: location.id,
            resources: resources,
            serviceCounts: serviceCounts,
            selectableLocations: selectableLocations,
            readOnly: !canManageSettings,
          ),
        );
      },
    );
  }
}

class _LocationResourcesActions extends ConsumerWidget {
  const _LocationResourcesActions({
    required this.location,
    required this.selectableLocations,
    required this.canViewStaff,
    required this.canManageSettings,
  });

  final Location location;
  final List<Location> selectableLocations;
  final bool canViewStaff;
  final bool canManageSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canViewStaff)
          IconButton(
            tooltip: context.l10n.navStaff,
            icon: const Icon(Icons.badge_outlined),
            onPressed: () {
              ref.read(staffSectionLocationIdProvider.notifier).set(location.id);
              context.go('/staff?from_altro=1');
            },
          ),
        if (canManageSettings)
          IconButton(
            tooltip: context.l10n.agendaAdd,
            icon: const Icon(Icons.add_outlined),
            onPressed: () => showResourceDialog(
              context,
              ref,
              locationId: location.id,
              selectableLocations: selectableLocations,
            ),
          ),
      ],
    );
  }
}

class _LocationResourcesBody extends ConsumerWidget {
  const _LocationResourcesBody({
    required this.locationId,
    required this.resources,
    required this.serviceCounts,
    required this.selectableLocations,
    required this.readOnly,
  });

  final int locationId;
  final List<Resource> resources;
  final Map<int, int> serviceCounts;
  final List<Location> selectableLocations;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (resources.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          context.l10n.resourcesEmpty,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < resources.length; i++) ...[
          Material(
            color: i.isEven
                ? colorScheme.surface
                : colorScheme.surfaceContainerLowest,
            child: InkWell(
              onTap: () => showResourceDialog(
                context,
                ref,
                locationId: locationId,
                resource: resources[i],
                selectableLocations: selectableLocations,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resources[i].name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${context.l10n.resourceQuantityLabel}: ${resources[i].quantity}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if ((resources[i].type ?? '').isNotEmpty)
                            Text(
                              resources[i].type!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if ((resources[i].note ?? '').isNotEmpty)
                            Text(
                              resources[i].note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${serviceCounts[resources[i].id] ?? 0}',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!readOnly) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: context.l10n.actionDelete,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final l10n = context.l10n;
                          await showAppConfirmDialog(
                            context,
                            title: Text(l10n.resourceDeleteConfirm),
                            content: Text(l10n.resourceDeleteWarning),
                            confirmLabel: l10n.actionDelete,
                            cancelLabel: l10n.actionCancel,
                            danger: true,
                            onConfirm: () async {
                              await ref
                                  .read(resourcesProvider.notifier)
                                  .deleteResource(resources[i].id);
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (i < resources.length - 1) const AppDivider(),
        ],
      ],
    );
  }
}

class _StandaloneResourcesAddAction extends ConsumerWidget {
  const _StandaloneResourcesAddAction({
    required this.locationId,
    required this.selectableLocations,
  });

  final int locationId;
  final List<Location> selectableLocations;
  static const double _actionButtonHeight = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final layoutConfig = ref.watch(layoutConfigProvider);
    final formFactor = ref.watch(formFactorProvider);
    final compact = formFactor != AppFormFactor.desktop;
    final showLabel = layoutConfig.showTopbarAddLabel;
    final showLabelEffective = showLabel || formFactor != AppFormFactor.mobile;
    const iconOnlyWidth = 46.0;
    final bool isIconOnly = !showLabelEffective;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => showResourceDialog(
          context,
          ref,
          locationId: locationId,
          selectableLocations: selectableLocations,
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
                  child: compact
                      ? showLabelEffective
                            ? Text(
                                l10n.agendaAdd,
                                style: TextStyle(
                                  color: onContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : Icon(
                                Icons.add_outlined,
                                size: 22,
                                color: onContainer,
                              )
                      : !showLabelEffective
                      ? Icon(
                          Icons.add_outlined,
                          size: 22,
                          color: onContainer,
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_outlined,
                              size: 22,
                              color: onContainer,
                            ),
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.resourcesEmpty,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.resourcesEmptyHint,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.resource,
    required this.serviceCount,
    required this.onEdit,
    required this.onDelete,
  });

  final Resource resource;
  final int serviceCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${resource.quantity}',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (resource.type != null && resource.type!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          resource.type!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                    if (resource.note != null && resource.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          resource.note!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Conteggio servizi associati
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 14,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            serviceCount == 1
                                ? context.l10n.resourceServiceCountSingular
                                : context.l10n.resourceServiceCountPlural(
                                    serviceCount,
                                  ),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(context.l10n.actionEdit),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.l10n.actionDelete,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
