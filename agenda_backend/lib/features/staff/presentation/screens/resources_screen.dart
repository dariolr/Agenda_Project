import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/location.dart';
import '../../../../core/models/resource.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../agenda/providers/resource_providers.dart';
import '../dialogs/resource_dialog.dart';

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
  const ResourcesScreen({super.key, required this.location});

  final Location location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final resources = ref.watch(locationResourcesProvider(location.id));
    final serviceCountsAsync = ref.watch(
      resourceServiceCountsProvider(location.id),
    );
    final serviceCounts = serviceCountsAsync.value ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resourcesTitle),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () =>
                  showResourceDialog(context, ref, locationId: location.id),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.agendaAdd),
            ),
          ),
        ],
      ),
      body: resources.isEmpty
          ? _EmptyState(locationId: location.id)
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
                  ),
                  onDelete: () => _confirmDelete(context, ref, resource),
                );
              },
            ),
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

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.locationId});

  final int locationId;

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
            const SizedBox(height: 24),
            AppFilledButton(
              onPressed: () =>
                  showResourceDialog(context, ref, locationId: locationId),
              child: Text(l10n.agendaAdd),
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
