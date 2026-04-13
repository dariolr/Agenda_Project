import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:agenda_backend/core/utils/color_utils.dart';
import 'package:flutter/material.dart';

class ClientCircleAvatar extends StatelessWidget {
  const ClientCircleAvatar({
    super.key,
    required this.height,
    required this.initials,
    this.clientColorHex,
    this.isHighlighted = false,
    this.fallbackColor,
    this.child,
  });

  final double height;
  final String initials;
  final String? clientColorHex;
  final bool isHighlighted;
  final Color? fallbackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = resolveClientAvatarColor(
      clientColorHex: clientColorHex,
      fallback: fallbackColor ?? Theme.of(context).colorScheme.primary,
    );

    return StaffCircleAvatar(
      height: height,
      color: resolvedColor,
      isHighlighted: isHighlighted,
      initials: initials,
      child: child,
    );
  }
}

Color resolveClientAvatarColor({
  required String? clientColorHex,
  required Color fallback,
}) {
  final hex = clientColorHex?.trim();
  if (hex == null || hex.isEmpty) return fallback;
  try {
    return ColorUtils.fromHex(hex);
  } catch (_) {
    return fallback;
  }
}
