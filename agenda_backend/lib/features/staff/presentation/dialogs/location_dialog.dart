import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/location.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dividers.dart';
import '../../../agenda/providers/business_providers.dart';
import '../../../agenda/providers/location_providers.dart';

Future<void> showLocationDialog(
  BuildContext context,
  WidgetRef ref, {
  Location? initial,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;

  final dialog = _LocationDialog(initial: initial);

  if (isDesktop) {
    await showDialog(context: context, builder: (_) => dialog);
  } else {
    await AppBottomSheet.show(
      context: context,
      builder: (_) => dialog,
      useRootNavigator: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      heightFactor: AppBottomSheet.defaultHeightFactor,
    );
  }
}

class _LocationDialog extends ConsumerStatefulWidget {
  const _LocationDialog({this.initial});

  final Location? initial;

  bool get isEditing => initial != null;

  @override
  ConsumerState<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends ConsumerState<_LocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameController.text = widget.initial!.name;
      _addressController.text = widget.initial!.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.isEditing
        ? l10n.teamEditLocationTitle
        : l10n.teamNewLocationTitle;

    final actions = [
      AppOutlinedActionButton(
        onPressed: () => Navigator.of(context).pop(),
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionCancel),
      ),
      AppFilledButton(
        onPressed: _onSave,
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionSave),
      ),
    ];

    final bottomActions = actions
        .map(
          (a) => SizedBox(width: AppButtonStyles.dialogButtonWidth, child: a),
        )
        .toList();

    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.teamLocationNameLabel),
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.validationRequired : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration:
                InputDecoration(labelText: l10n.teamLocationAddressLabel),
          ),
        ],
      ),
    );

    if (ref.read(formFactorProvider) == AppFormFactor.desktop) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Flexible(child: SingleChildScrollView(child: content)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < bottomActions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      bottomActions[i],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isKeyboardOpen =
              MediaQuery.of(context).viewInsets.bottom > 0;
          return SizedBox(
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          content,
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isKeyboardOpen) ...[
                  const AppBottomSheetDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: bottomActions,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(locationsProvider.notifier);
    final business = ref.read(currentBusinessProvider);
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (widget.initial != null) {
      notifier.update(
        widget.initial!.copyWith(
          name: name,
          address: address.isEmpty ? null : address,
        ),
      );
    } else {
      notifier.add(
        Location(
          id: notifier.nextId(),
          businessId: business.id,
          name: name,
          address: address.isEmpty ? null : address,
        ),
      );
    }
    Navigator.of(context).pop();
  }
}
