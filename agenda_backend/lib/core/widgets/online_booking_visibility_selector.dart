import 'package:flutter/material.dart';

import '../l10n/l10_extension.dart';
import '../models/online_booking_visibility.dart';

class OnlineBookingVisibilitySelector extends StatelessWidget {
  const OnlineBookingVisibilitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final OnlineBookingVisibilityOption value;
  final ValueChanged<OnlineBookingVisibilityOption>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget buildOption(OnlineBookingVisibilityOption option, String label) {
      return RadioListTile<OnlineBookingVisibilityOption>.adaptive(
        value: option,
        groupValue: value,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
        title: Text(label),
        onChanged: onChanged == null ? null : (_) => onChanged!(option),
      );
    }

    return InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildOption(
            OnlineBookingVisibilityOption.publicVisible,
            context.l10n.onlineBookingVisibilityPublicOption,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          buildOption(
            OnlineBookingVisibilityOption.directLink,
            context.l10n.onlineBookingVisibilityDirectLinkOption,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          buildOption(
            OnlineBookingVisibilityOption.hidden,
            context.l10n.onlineBookingVisibilityHiddenOption,
          ),
        ],
      ),
    );
  }
}
