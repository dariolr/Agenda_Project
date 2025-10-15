import 'package:flutter/material.dart';

import '../../../../../core/models/staff.dart';
import '../../../domain/config/layout_config.dart';

class StaffHeaderRow extends StatefulWidget {
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
  State<StaffHeaderRow> createState() => _StaffHeaderRowState();
}

class _StaffHeaderRowState extends State<StaffHeaderRow> {
  late final ScrollController _localController;

  @override
  void initState() {
    super.initState();

    // ✅ collega il controller locale a quello principale
    _localController = ScrollController();

    widget.scrollController.addListener(() {
      if (!_localController.hasClients) return;
      _localController.jumpTo(widget.scrollController.offset);
    });
  }

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = LayoutConfig.headerHeight;

    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          // Colonna “Ora” → vuota e trasparente
          SizedBox(width: widget.hourColumnWidth, height: headerHeight),

          // Colonne staff scrollabili in sync
          Expanded(
            child: SingleChildScrollView(
              controller: _localController,
              scrollDirection: Axis.horizontal,
              physics:
                  const NeverScrollableScrollPhysics(), // non scrolla da sola
              child: Row(
                children: widget.staffList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final staff = entry.value;
                  final isLast = index == widget.staffList.length - 1;

                  return Container(
                    width: widget.columnWidth,
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
