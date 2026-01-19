import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/service.dart';
import '../../../../core/models/service_package.dart';
import 'service_item.dart';
import 'service_package_item.dart';

class ServicesList extends ConsumerWidget {
  final List<Service> services;
  final List<ServicePackage> packages;
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

  const ServicesList({
    super.key,
    required this.services,
    required this.packages,
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
                for (int i = 0; i < services.length; i++)
                  ServiceItem(
                    service: services[i],
                    isLast: i == services.length - 1,
                    isEvenRow: i.isEven,
                    isHovered: hoveredId == services[i].id,
                    isSelected: selectedId == services[i].id,
                    isWide: isWide,
                    colorScheme: colorScheme,
                    onTap: () {
                      selectedService.value = services[i].id;
                      onOpen(services[i]);
                    },
                    onEnter: () => hoveredService.value = services[i].id,
                    onExit: () => hoveredService.value = null,
                    onEdit: () => onEdit(services[i]),
                    onDuplicate: () => onDuplicate(services[i]),
                    onDelete: () => onDelete(services[i].id),
                  ),
                for (int i = 0; i < packages.length; i++)
                  ServicePackageListItem(
                    package: packages[i],
                    isLast: i == packages.length - 1,
                    isEvenRow: (services.length + i).isEven,
                    isWide: isWide,
                    colorScheme: colorScheme,
                    onTap: () => onPackageOpen(packages[i]),
                    onEdit: () => onPackageEdit(packages[i]),
                    onDelete: () => onPackageDelete(packages[i].id),
                  ),
                if (services.isNotEmpty || packages.isNotEmpty)
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
