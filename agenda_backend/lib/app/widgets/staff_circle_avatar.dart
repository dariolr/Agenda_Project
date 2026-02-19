import 'package:flutter/material.dart';

import '../../core/utils/initials_utils.dart';

String initialsFromName(String name, {int maxChars = 3}) {
  return InitialsUtils.fromName(name, maxChars: maxChars);
}

class StaffCircleAvatar extends StatelessWidget {
  final double height;
  final Color color;
  final bool isHighlighted;
  final String initials;
  final Widget? child;

  const StaffCircleAvatar({
    super.key,
    required this.height,
    required this.color,
    required this.isHighlighted,
    required this.initials,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hasThreeLetterInitials = InitialsUtils.length(initials) == 3;
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
            child: child ??
                Text(
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
