import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';
import '../../../providers/highlighted_staff_provider.dart';

class StaffHeaderRow extends ConsumerWidget {
  final List<Staff> staffList;
  final ScrollController scrollController;
  final double columnWidth;
  final double hourColumnWidth;

  const StaffHeaderRow({
    super.key,
    required this.staffList,
    required this.scrollController,
    required this.columnWidth,
    required this.hourColumnWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerHeight = LayoutConfig.headerHeight;
    final highlightedId = ref.watch(highlightedStaffIdProvider);

    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          // Colonna "Ora" — vuota e trasparente
          SizedBox(width: hourColumnWidth, height: headerHeight),

          // Scroll orizzontale sincronizzato con le colonne
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: staffList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final staff = entry.value;
                  final isLast = index == staffList.length - 1;
                  final isHighlighted = highlightedId == staff.id;

                  return Stack(
                    children: [
                      // 🔹 Base colorata per ogni colonna staff
                      Container(
                        width: columnWidth,
                        height: headerHeight,
                        decoration: BoxDecoration(
                          color: staff.color.withOpacity(0.18),
                          border: Border(
                            right: BorderSide(
                              color: isLast
                                  ? Colors.transparent
                                  : Colors.grey.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: Text(
                          staff.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // 🔸 Badge fisso in alto quando colonna è evidenziata
                      Positioned(
                        top: 6,
                        left: 6,
                        right: 6,
                        child: AnimatedOpacity(
                          opacity: isHighlighted ? 1 : 0,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeInOut,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: staff.color.withOpacity(0.28),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                staff.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
