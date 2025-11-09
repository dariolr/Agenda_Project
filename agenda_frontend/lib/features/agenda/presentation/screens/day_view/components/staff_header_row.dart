import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/models/staff.dart';
import '../../../../providers/highlighted_staff_provider.dart';
import '../../../../providers/layout_config_provider.dart';

class StaffHeaderRow extends ConsumerWidget {
  final List<Staff> staffList;
  final ScrollController
  scrollController; // non usato per scrollare qui, ma utile per offset/read
  final double columnWidth;
  final double hourColumnWidth; // NON usato per lasciare spazio iniziale

  const StaffHeaderRow({
    super.key,
    required this.staffList,
    required this.scrollController,
    required this.columnWidth,
    required this.hourColumnWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerHeight = ref.watch(layoutConfigProvider).headerHeight;
    final highlightedId = ref.watch(highlightedStaffIdProvider);

    // ⚠️ Nessuna SizedBox iniziale qui! Lo spazio per l'ora è già messo nel parent.
    final initialsMap = {
      for (final staff in staffList) staff.id: _buildInitials(staff),
    };
    final hasThreeLetterInitials = initialsMap.values.any(
      (value) => value.length == 3,
    );
    final initialsFontSize =
        headerHeight * (hasThreeLetterInitials ? 0.30 : 0.35);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: staffList.asMap().entries.map((entry) {
        final index = entry.key;
        final staff = entry.value;
        final isLast = index == staffList.length - 1;
        final isHighlighted = highlightedId == staff.id;

        final initials = initialsMap[staff.id] ?? '';
        final displayName = _buildDisplayName(staff);

        return Container(
          width: columnWidth,
          height: headerHeight,
          decoration: BoxDecoration(
            color: staff.color.withOpacity(isHighlighted ? 0.24 : 0.12),
            border: Border(
              right: BorderSide(
                color: isLast
                    ? Colors.transparent
                    : Colors.grey.withOpacity(0.25),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: headerHeight * 0.18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: headerHeight * 0.78,
                height: headerHeight * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isHighlighted
                        ? staff.color
                        : staff.color.withOpacity(0.35),
                    width: isHighlighted ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: staff.color.withOpacity(0.18),
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.all(headerHeight * 0.06),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: staff.color,
                          fontWeight: FontWeight.w600,
                          fontSize: initialsFontSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _buildInitials(Staff staff) {
    final nameInitial = staff.name.isNotEmpty
        ? staff.name.trim().split(RegExp(r'\s+')).first[0].toUpperCase()
        : '';

    final surnameParts = staff.surname.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);

    if (nameInitial.isEmpty && surnameParts.isEmpty) {
      return '';
    }

    var initials = nameInitial;

    if (surnameParts.isNotEmpty) {
      for (final part in surnameParts) {
        initials += part[0].toUpperCase();
        if (initials.length >= 3) break;
      }
    }

    if (initials.length < 3 && surnameParts.isEmpty) {
      final nameParts = staff.name.trim().split(RegExp(r'\s+'))
        ..removeWhere((p) => p.isEmpty);
      if (nameParts.length > 1) {
        for (int i = 1; i < nameParts.length; i++) {
          initials += nameParts[i][0].toUpperCase();
          if (initials.length >= 3) break;
        }
      } else if (staff.name.length > 1) {
        initials += staff.name[1].toUpperCase();
      }
    }

    final endIndex = initials.length.clamp(1, 3).toInt();
    return initials.substring(0, endIndex);
  }

  String _buildDisplayName(Staff staff) {
    if (staff.surname.isEmpty) return staff.name;
    return '${staff.name} ${staff.surname}';
  }
}
