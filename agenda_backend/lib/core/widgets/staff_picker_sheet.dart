import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/core/l10n/l10_extension.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mostra un picker per la selezione dello staff.
/// Su mobile usa un bottom sheet, su desktop un dialog.
Future<int?> showStaffPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<Staff> staff,
  required int? selectedId,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final l10n = context.l10n;

  if (formFactor != AppFormFactor.desktop) {
    return AppBottomSheet.show<int>(
      context: context,
      padding: EdgeInsets.zero,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.selectStaffTitle,
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              StaffPickerContent(
                staff: staff,
                selectedId: selectedId,
                onSelected: (staffId) => Navigator.of(ctx).pop(staffId),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  } else {
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.selectStaffTitle),
        content: SizedBox(
          width: 300,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: StaffPickerContent(
                staff: staff,
                selectedId: selectedId,
                onSelected: (staffId) => Navigator.of(ctx).pop(staffId),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Content widget per la selezione dello staff (riutilizzabile)
class StaffPickerContent extends StatelessWidget {
  const StaffPickerContent({
    super.key,
    required this.staff,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Staff> staff;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (staff.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            l10n.noStaffAvailable,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final member in staff)
          ListTile(
            leading: StaffCircleAvatar(
              height: 36,
              color: member.color,
              isHighlighted: member.id == selectedId,
              initials: member.initials,
            ),
            title: Text('${member.name} ${member.surname}'.trim()),
            trailing: member.id == selectedId
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            selected: member.id == selectedId,
            onTap: () => onSelected(member.id),
          ),
      ],
    );
  }
}
