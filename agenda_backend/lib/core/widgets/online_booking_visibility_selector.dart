import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10_extension.dart';
import '../models/online_booking_visibility.dart';
import '../utils/booking_direct_link_utils.dart';
import 'app_buttons.dart';
import 'app_dividers.dart';

class OnlineBookingVisibilitySelector extends ConsumerWidget {
  const OnlineBookingVisibilitySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.isEditing = false,
    this.targetType,
    this.targetId,
    this.enabled = true,
  });

  final OnlineBookingVisibilityOption value;
  final ValueChanged<OnlineBookingVisibilityOption>? onChanged;

  /// Se true e [targetType]/[targetId] sono valorizzati, mostra il pulsante copia link.
  final bool isEditing;
  final String? targetType;
  final int? targetId;

  /// Permette al form padre di disabilitare il pulsante per motivi propri
  /// (es. salvataggio in corso, permessi insufficienti).
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final showButton =
        isEditing && targetType != null && targetId != null;
    final buttonEnabled =
        enabled && value != OnlineBookingVisibilityOption.hidden;

    Widget buildOption(OnlineBookingVisibilityOption option, String label) {
      return RadioListTile<OnlineBookingVisibilityOption>.adaptive(
        value: option,
        groupValue: value,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
        activeColor: primaryColor,
        title: Text(label),
        onChanged: onChanged == null ? null : (_) => onChanged!(option),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InputDecorator(
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
              const AppDivider(),
              buildOption(
                OnlineBookingVisibilityOption.directLink,
                context.l10n.onlineBookingVisibilityDirectLinkOption,
              ),
              const AppDivider(),
              buildOption(
                OnlineBookingVisibilityOption.hidden,
                context.l10n.onlineBookingVisibilityHiddenOption,
              ),
            ],
          ),
        ),
        if (showButton) ...[
          const SizedBox(height: 12),
          AppOutlinedActionButton(
            onPressed: buttonEnabled
                ? () => copyBookingDirectLink(
                      context,
                      ref,
                      targetType: targetType!,
                      targetId: targetId!,
                    )
                : null,
            child: Text(context.l10n.closuresImportHolidaysCopyLinkAction),
          ),
        ],
      ],
    );
  }
}
