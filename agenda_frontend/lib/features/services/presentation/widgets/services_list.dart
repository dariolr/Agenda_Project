import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/service.dart';
import 'service_item.dart';

class ServicesList extends ConsumerWidget {
  final List<Service> services;
  final bool isWide;
  final ColorScheme colorScheme;
  final ValueNotifier<int?> hoveredService;
  final ValueNotifier<int?> selectedService;
  final void Function(Service) onOpen;
  final void Function(Service) onEdit;
  final void Function(Service) onDuplicate;
  final void Function(int id) onDelete;

  const ServicesList({
    super.key,
    required this.services,
    required this.isWide,
    required this.colorScheme,
    required this.hoveredService,
    required this.selectedService,
    required this.onOpen,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
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
                    isOddRow: i.isOdd,
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
                if (services.isNotEmpty)
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
