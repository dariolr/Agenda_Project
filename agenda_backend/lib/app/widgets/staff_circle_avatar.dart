import 'package:flutter/material.dart';

String initialsFromName(String name, {int maxChars = 3}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  var initials = '';
  if (parts.isNotEmpty) {
    initials += parts.first[0].toUpperCase();
  }
  for (int i = 1; i < parts.length && initials.length < maxChars; i++) {
    initials += parts[i][0].toUpperCase();
  }
  if (parts.length == 1 && initials.length < maxChars && trimmed.length > 1) {
    initials += trimmed[1].toUpperCase();
  }
  final end = initials.length.clamp(1, maxChars);
  return initials.substring(0, end);
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
