import 'package:flutter/material.dart';

import '../../../../app/theme/extensions.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';

class ServiceEligibilitySelector extends StatelessWidget {
  const ServiceEligibilitySelector({
    super.key,
    required this.services,
    required this.categories,
    required this.selectedServiceIds,
    required this.onChanged,
    this.showSelectAll = true,
    this.readOnly = false,
    this.onServiceTap,
  });

  final List<Service> services;
  final List<ServiceCategory> categories;
  final Set<int> selectedServiceIds;
  final ValueChanged<Set<int>> onChanged;
  final bool showSelectAll;
  final bool readOnly;
  final ValueChanged<Service>? onServiceTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final servicesByCategory = <int, List<Service>>{};
    for (final service in services) {
      (servicesByCategory[service.categoryId] ??= []).add(service);
    }

    final hasServicesMap = <int, bool>{
      for (final category in categories)
        category.id: (servicesByCategory[category.id]?.isNotEmpty ?? false),
    };

    final sortedCategories = [...categories]
      ..sort((a, b) {
        final aEmpty = !(hasServicesMap[a.id] ?? false);
        final bEmpty = !(hasServicesMap[b.id] ?? false);
        if (aEmpty != bEmpty) return aEmpty ? 1 : -1;
        final so = a.sortOrder.compareTo(b.sortOrder);
        return so != 0
            ? so
            : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final allServiceIds = [
      for (final service in services) service.id,
    ];
    final isAllSelected =
        allServiceIds.isNotEmpty &&
        allServiceIds.every(selectedServiceIds.contains);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSelectAll)
          _SelectableRow(
            label: l10n.teamSelectAllServices,
            selected: isAllSelected,
            onTap: readOnly
                ? null
                : () {
              if (isAllSelected) {
                onChanged(<int>{});
              } else {
                onChanged(allServiceIds.toSet());
              }
            },
          ),
        if (showSelectAll) const Divider(height: 1),
        for (final category in sortedCategories)
          if ((servicesByCategory[category.id] ?? const <Service>[]).isNotEmpty)
            ...[
                _CategoryHeader(
                  category: category,
                  selectedIds: selectedServiceIds,
                  services: servicesByCategory[category.id]!,
                  onChanged: onChanged,
                  readOnly: readOnly,
                ),
              for (int i = 0; i < servicesByCategory[category.id]!.length; i++)
                _ServiceRow(
                  service: servicesByCategory[category.id]![i],
                  isEven: i.isEven,
                  selectedIds: selectedServiceIds,
                  onChanged: onChanged,
                  evenBackgroundColor: theme
                          .extension<AppInteractionColors>()
                          ?.alternatingRowFill ??
                      theme.colorScheme.onSurface.withOpacity(0.04),
                  readOnly: readOnly,
                  onServiceTap: onServiceTap,
                ),
            ],
      ],
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              if (selected)
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.category,
    required this.services,
    required this.selectedIds,
    required this.onChanged,
    required this.readOnly,
  });

  final ServiceCategory category;
  final List<Service> services;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceIds = services.map((s) => s.id).toList();
    final isSelected =
        serviceIds.isNotEmpty && serviceIds.every(selectedIds.contains);

    return Material(
      color: theme.colorScheme.primary,
      child: InkWell(
        onTap: readOnly
            ? null
            : () {
          if (serviceIds.isEmpty) return;
          final updated = {...selectedIds};
          if (isSelected) {
            updated.removeWhere(serviceIds.contains);
          } else {
            updated.addAll(serviceIds);
          }
          onChanged(updated);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category.name.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (serviceIds.isNotEmpty)
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: theme.colorScheme.onPrimary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.isEven,
    required this.selectedIds,
    required this.onChanged,
    required this.evenBackgroundColor,
    required this.readOnly,
    this.onServiceTap,
  });

  final Service service;
  final bool isEven;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;
  final Color evenBackgroundColor;
  final bool readOnly;
  final ValueChanged<Service>? onServiceTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIds.contains(service.id);
    return Material(
      color: isEven ? evenBackgroundColor : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (readOnly) {
            onServiceTap?.call(service);
            return;
          }
          final updated = {...selectedIds};
          if (isSelected) {
            updated.remove(service.id);
          } else {
            updated.add(service.id);
          }
          onChanged(updated);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(service.name)),
              if (isSelected)
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
