import 'package:flutter/material.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_category.dart';
import 'empty_state.dart';
import 'services_list.dart';

/// Item che rappresenta la card di una singola categoria (header + servizi).
class CategoryItem extends StatelessWidget {
  final ServiceCategory category;
  final List<Service> services;
  final bool isWide;
  final ColorScheme colorScheme;
  final ValueNotifier<int?> hoveredService;
  final ValueNotifier<int?> selectedService;
  final VoidCallback onAddService;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final VoidCallback onDeleteBlocked;
  final ValueChanged<Service> onServiceOpen;
  final ValueChanged<Service> onServiceEdit;
  final ValueChanged<Service> onServiceDuplicate;
  final ValueChanged<int> onServiceDelete;
  final bool addTopSpacing;

  const CategoryItem({
    super.key,
    required this.category,
    required this.services,
    required this.isWide,
    required this.colorScheme,
    required this.hoveredService,
    required this.selectedService,
    required this.onAddService,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onDeleteBlocked,
    required this.onServiceOpen,
    required this.onServiceEdit,
    required this.onServiceDuplicate,
    required this.onServiceDelete,
    required this.addTopSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final isEmptyCategory = services.isEmpty;
    return Container(
      margin: EdgeInsets.only(
        top: addTopSpacing ? 32 : 0,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header categoria
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            child: Row(
              children: [
                // Titolo + descrizione
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimaryContainer,
                            ),
                      ),
                      if (category.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            category.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withOpacity(0.8),
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Pulsanti azione (solo in vista normale)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: context.l10n.addServiceTooltip,
                      icon: Icon(
                        Icons.add,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      onPressed: onAddService,
                    ),
                    IconButton(
                      tooltip: context.l10n.actionEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      onPressed: onEditCategory,
                    ),
                    if (isEmptyCategory)
                      IconButton(
                        tooltip: context.l10n.actionDelete,
                        icon: const Icon(Icons.delete_outline),
                        color: colorScheme.onPrimaryContainer,
                        onPressed: onDeleteCategory,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Body: lista servizi o stato vuoto
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: isEmptyCategory
                ? ServicesEmptyState(message: context.l10n.noServicesInCategory)
                : ServicesList(
                    services: services,
                    isWide: isWide,
                    colorScheme: colorScheme,
                    hoveredService: hoveredService,
                    selectedService: selectedService,
                    onOpen: onServiceOpen,
                    onEdit: onServiceEdit,
                    onDuplicate: onServiceDuplicate,
                    onDelete: onServiceDelete,
                  ),
          ),
        ],
      ),
    );
  }
}
