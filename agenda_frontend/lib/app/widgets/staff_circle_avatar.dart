import 'package:flutter/material.dart';

class StaffCircleAvatar extends StatelessWidget {
  final double height;
  final Color color;
  final bool isHighlighted;
  final String initials;

  const StaffCircleAvatar({
    super.key,
    required this.height,
    required this.color,
    required this.isHighlighted,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final hasThreeLetterInitials = initials.length == 3;
    final initialsFontSize = height * (hasThreeLetterInitials ? 0.30 : 0.35);
    return Container(
      width: height,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isHighlighted ? color : color.withOpacity(0.35),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.18),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.all(height * 0.06),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              initials,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: initialsFontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
