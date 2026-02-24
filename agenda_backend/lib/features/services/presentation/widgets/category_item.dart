import 'package:flutter/material.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_package.dart';
import '../../providers/services_sorted_providers.dart';
import 'empty_state.dart';
import 'services_list.dart';

/// Item che rappresenta la card di una singola categoria (header + servizi).
class CategoryItem extends StatefulWidget {
  final ServiceCategory category;
  final List<ServiceCategoryEntry> entries;
  final bool isWide;
  final ColorScheme colorScheme;
  final ValueNotifier<int?> hoveredService;
  final ValueNotifier<int?> selectedService;
  final VoidCallback onAddService;
  final VoidCallback onAddPackage;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final VoidCallback onDeleteBlocked;
  final ValueChanged<Service> onServiceOpen;
  final ValueChanged<Service> onServiceEdit;
  final ValueChanged<Service> onServiceDuplicate;
  final ValueChanged<int> onServiceDelete;
  final ValueChanged<ServicePackage> onPackageOpen;
  final ValueChanged<ServicePackage> onPackageEdit;
  final ValueChanged<int> onPackageDelete;
  final bool addTopSpacing;
  final bool readOnly;
  final bool isCollapsible;

  const CategoryItem({
    super.key,
    required this.category,
    required this.entries,
    required this.isWide,
    required this.colorScheme,
    required this.hoveredService,
    required this.selectedService,
    required this.onAddService,
    required this.onAddPackage,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onDeleteBlocked,
    required this.onServiceOpen,
    required this.onServiceEdit,
    required this.onServiceDuplicate,
    required this.onServiceDelete,
    required this.onPackageOpen,
    required this.onPackageEdit,
    required this.onPackageDelete,
    required this.addTopSpacing,
    this.readOnly = false,
    this.isCollapsible = false,
  });

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.isCollapsible;
  }

  @override
  void didUpdateWidget(CategoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCollapsible != widget.isCollapsible) {
      _isExpanded = !widget.isCollapsible;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmptyCategory = widget.entries.isEmpty;
    final categoryBorderColor =
        widget.colorScheme.outlineVariant.withOpacity(0.16);

    return Container(
      margin: EdgeInsets.only(top: widget.addTopSpacing ? 32 : 0, bottom: 24),
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        border: Border.all(color: categoryBorderColor),
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.isCollapsible
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.colorScheme.surface,
                border: _isExpanded
                    ? Border(bottom: BorderSide(color: categoryBorderColor))
                    : null,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom:
                      _isExpanded ? Radius.zero : const Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  // Titolo + descrizione
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (widget.isCollapsible &&
                                widget.entries.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _CountChip(count: widget.entries.length),
                            ],
                          ],
                        ),
                        if (widget.category.description != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.category.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Pulsanti azione + chevron
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.readOnly) ...[
                        IconButton(
                          tooltip: context.l10n.addServiceTooltip,
                          icon: const Icon(Icons.add),
                          onPressed: widget.onAddService,
                        ),
                        IconButton(
                          tooltip: context.l10n.servicePackageNewMenu,
                          icon: const Icon(Icons.widgets_outlined),
                          onPressed: widget.onAddPackage,
                        ),
                        IconButton(
                          tooltip: context.l10n.actionEdit,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: widget.onEditCategory,
                        ),
                        if (isEmptyCategory)
                          IconButton(
                            tooltip: context.l10n.actionDelete,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: widget.onDeleteCategory,
                          ),
                      ],
                      if (widget.isCollapsible)
                        AnimatedRotation(
                          turns: _isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(Icons.chevron_right),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Body: lista servizi o stato vuoto (animato)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: isEmptyCategory
                        ? ServicesEmptyState(
                            message: context.l10n.noServicesInCategory,
                          )
                        : ServicesList(
                            entries: widget.entries,
                            isWide: widget.isWide,
                            colorScheme: widget.colorScheme,
                            hoveredService: widget.hoveredService,
                            selectedService: widget.selectedService,
                            onOpen: widget.onServiceOpen,
                            onEdit: widget.onServiceEdit,
                            onDuplicate: widget.onServiceDuplicate,
                            onDelete: widget.onServiceDelete,
                            onPackageOpen: widget.onPackageOpen,
                            onPackageEdit: widget.onPackageEdit,
                            onPackageDelete: widget.onPackageDelete,
                            readOnly: widget.readOnly,
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
