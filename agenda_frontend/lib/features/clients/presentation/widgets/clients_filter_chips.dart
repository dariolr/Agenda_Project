import 'package:flutter/material.dart';

class ClientsFilterChips extends StatelessWidget {
  final int selectedIndex; // 0=all,1=VIP,2=Inactive,3=New
  final ValueChanged<int> onSelectedIndex;
  final String labelAll;
  final String labelVIP;
  final String labelInactive;
  final String labelNew;

  const ClientsFilterChips({
    super.key,
    required this.selectedIndex,
    required this.onSelectedIndex,
    required this.labelAll,
    required this.labelVIP,
    required this.labelInactive,
    required this.labelNew,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: Text(labelAll),
            selected: selectedIndex == 0,
            onSelected: (_) => onSelectedIndex(0),
          ),
          ChoiceChip(
            label: Text(labelVIP),
            selected: selectedIndex == 1,
            onSelected: (_) => onSelectedIndex(1),
          ),
          ChoiceChip(
            label: Text(labelInactive),
            selected: selectedIndex == 2,
            onSelected: (_) => onSelectedIndex(2),
          ),
          ChoiceChip(
            label: Text(labelNew),
            selected: selectedIndex == 3,
            onSelected: (_) => onSelectedIndex(3),
          ),
        ],
      ),
    );
  }
}
