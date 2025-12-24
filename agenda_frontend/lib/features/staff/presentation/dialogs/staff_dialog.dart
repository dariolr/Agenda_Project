import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/staff.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../agenda/providers/business_providers.dart';
import '../../../agenda/providers/location_providers.dart';
import '../../providers/staff_providers.dart';

Future<void> showStaffDialog(
  BuildContext context,
  WidgetRef ref, {
  Staff? initial,
  int? initialLocationId,
}) async {
  final formFactor = ref.read(formFactorProvider);
  final isDesktop = formFactor == AppFormFactor.desktop;

  final dialog = _StaffDialog(
    initial: initial,
    initialLocationId: initialLocationId,
  );

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

class _StaffDialog extends ConsumerStatefulWidget {
  const _StaffDialog({this.initial, this.initialLocationId});

  final Staff? initial;
  final int? initialLocationId;

  bool get isEditing => initial != null;

  @override
  ConsumerState<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends ConsumerState<_StaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();

  late Color _selectedColor;
  final Set<int> _selectedLocationIds = {};
  String? _locationsError;

  static const List<Color> _palette = [
    Colors.green,
    Colors.cyan,
    Colors.orange,
    Colors.pinkAccent,
    Colors.blue,
    Colors.teal,
    Colors.indigo,
    Colors.red,
    Colors.purple,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.amber,
    Colors.lime,
    Colors.lightGreen,
    Colors.blueGrey,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _selectedColor = initial?.color ?? _palette.first;
    if (initial != null) {
      _nameController.text = initial.name;
      _surnameController.text = initial.surname;
      _selectedLocationIds.addAll(initial.locationIds);
    } else if (widget.initialLocationId != null) {
      _selectedLocationIds.add(widget.initialLocationId!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title =
        widget.isEditing ? l10n.teamEditStaffTitle : l10n.teamNewStaffTitle;
    final locations = ref.watch(locationsProvider);

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
            decoration: InputDecoration(labelText: l10n.teamStaffNameLabel),
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.validationRequired : null,
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          TextFormField(
            controller: _surnameController,
            decoration: InputDecoration(labelText: l10n.teamStaffSurnameLabel),
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          Text(
            l10n.teamStaffColorLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in _palette)
                GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.black.withOpacity(0.08),
                        width: _selectedColor == color ? 2 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          Text(
            l10n.teamStaffLocationsLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              for (final loc in locations)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selectedLocationIds.contains(loc.id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedLocationIds.add(loc.id);
                      } else {
                        _selectedLocationIds.remove(loc.id);
                      }
                      _locationsError = null;
                    });
                  },
                  title: Text(loc.name),
                ),
            ],
          ),
          if (_locationsError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _locationsError!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          Text(
            l10n.teamStaffMultiLocationWarning,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
                          const SizedBox(height: AppSpacing.formRowSpacing),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Color(0x1F000000),
                ),
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
    if (_selectedLocationIds.isEmpty) {
      setState(() => _locationsError = context.l10n.validationRequired);
      return;
    }
    final notifier = ref.read(allStaffProvider.notifier);
    final business = ref.read(currentBusinessProvider);
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();

    if (widget.initial != null) {
      notifier.update(
        widget.initial!.copyWith(
          name: name,
          surname: surname,
          color: _selectedColor,
          locationIds: _selectedLocationIds.toList(),
        ),
      );
    } else {
      notifier.add(
        Staff(
          id: notifier.nextId(),
          businessId: business.id,
          name: name,
          surname: surname,
          color: _selectedColor,
          locationIds: _selectedLocationIds.toList(),
          sortOrder: notifier.nextSortOrderForLocations(_selectedLocationIds),
        ),
      );
    }
    Navigator.of(context).pop();
  }
}
