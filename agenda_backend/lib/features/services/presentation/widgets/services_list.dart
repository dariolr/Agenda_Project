import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/class_type.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/service_package.dart';
import '../../providers/services_sorted_providers.dart';
import 'class_type_list_item.dart';
import 'service_item.dart';
import 'service_package_item.dart';

class ServicesList extends ConsumerWidget {
  final List<ServiceCategoryEntry> entries;
  final bool isWide;
  final ColorScheme colorScheme;
  final ValueNotifier<int?> hoveredService;
  final ValueNotifier<int?> selectedService;
  final void Function(Service) onOpen;
  final void Function(Service) onEdit;
  final void Function(Service) onDuplicate;
  final void Function(int id) onDelete;
  final void Function(ServicePackage) onPackageOpen;
  final void Function(ServicePackage) onPackageEdit;
  final void Function(int id) onPackageDelete;
  final void Function(ClassType) onClassTypeOpen;
  final void Function(ClassType) onClassTypeEdit;
  final void Function(ClassType) onClassTypeDuplicate;
  final void Function(int id) onClassTypeDelete;
  final void Function(ClassType) onClassTypeSchedule;
  final bool readOnly;

  const ServicesList({
    super.key,
    required this.entries,
    required this.isWide,
    required this.colorScheme,
    required this.hoveredService,
    required this.selectedService,
    required this.onOpen,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onPackageOpen,
    required this.onPackageEdit,
    required this.onPackageDelete,
    required this.onClassTypeOpen,
    required this.onClassTypeEdit,
    required this.onClassTypeDuplicate,
    required this.onClassTypeDelete,
    required this.onClassTypeSchedule,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<int?>(
      valueListenable: hoveredService,
      builder: (context, hoveredId, _) {
        return ValueListenableBuilder<int?>(
          valueListenable: selectedService,
          builder: (context, selectedId, __) {
            return Column(
              children: [
                for (int i = 0; i < entries.length; i++)
                  if (entries[i].isService)
                    ServiceItem(
                      service: entries[i].service!,
                      isLast: i == entries.length - 1,
                      isEvenRow: i.isEven,
                      isHovered: hoveredId == entries[i].service!.id,
                      isSelected: selectedId == entries[i].service!.id,
                      isWide: isWide,
                      colorScheme: colorScheme,
                      onTap: () {
                        selectedService.value = entries[i].service!.id;
                        onOpen(entries[i].service!);
                      },
                      onEnter: () =>
                          hoveredService.value = entries[i].service!.id,
                      onExit: () => hoveredService.value = null,
                      onEdit: () => onEdit(entries[i].service!),
                      onDuplicate: () => onDuplicate(entries[i].service!),
                      onDelete: () => onDelete(entries[i].service!.id),
                      readOnly: readOnly,
                    )
                  else if (entries[i].isClassType)
                    ClassTypeListItem(
                      classType: entries[i].classType!,
                      isLast: i == entries.length - 1,
                      isEvenRow: i.isEven,
                      isWide: isWide,
                      colorScheme: colorScheme,
                      onTap: () => onClassTypeOpen(entries[i].classType!),
                      onEdit: () => onClassTypeEdit(entries[i].classType!),
                      onDuplicate: () =>
                          onClassTypeDuplicate(entries[i].classType!),
                      onDelete: () =>
                          onClassTypeDelete(entries[i].classType!.id),
                      onSchedule: () =>
                          onClassTypeSchedule(entries[i].classType!),
                      readOnly: readOnly,
                    )
                  else
                    ServicePackageListItem(
                      package: entries[i].package!,
                      isLast: i == entries.length - 1,
                      isEvenRow: i.isEven,
                      isWide: isWide,
                      colorScheme: colorScheme,
                      onTap: () {
                        onPackageOpen(entries[i].package!);
                      },
                      onEdit: () => onPackageEdit(entries[i].package!),
                      onDelete: () => onPackageDelete(entries[i].package!.id),
                      readOnly: readOnly,
                    ),
                if (entries.isNotEmpty)
                  Divider(
                    color: Colors.grey.withOpacity(0.2),
                    height: 1,
                    thickness: 1,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
