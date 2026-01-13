import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/location.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dividers.dart';
import '../../../../core/widgets/form_loading_overlay.dart';
import '../../../../core/widgets/labeled_form_field.dart';
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
      padding: EdgeInsets.zero,
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
  final _emailController = TextEditingController();
  bool _isActive = true;
  int _minBookingNoticeHours = 1;
  int _maxBookingAdvanceDays = 90;
  bool _allowCustomerChooseStaff = false;

  // Opzioni disponibili per i dropdown
  static const _noticeHoursOptions = [1, 2, 4, 6, 12, 24, 48];
  static const _advanceDaysOptions = [7, 14, 30, 60, 90, 180, 365];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameController.text = widget.initial!.name;
      _addressController.text = widget.initial!.address ?? '';
      _emailController.text = widget.initial!.email ?? '';
      _isActive = widget.initial!.isActive;
      _minBookingNoticeHours = widget.initial!.minBookingNoticeHours;
      _maxBookingAdvanceDays = widget.initial!.maxBookingAdvanceDays;
      _allowCustomerChooseStaff = widget.initial!.allowCustomerChooseStaff;
    } else {
      // Pre-popola con il nome del business per nuove sedi
      final businessName = ref.read(currentBusinessProvider).name;
      _nameController.text = businessName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
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
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionCancel),
      ),
      AppFilledButton(
        onPressed: _isLoading ? null : _onSave,
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionSave),
      ),
    ];

    final bottomActions = actions
        .map(
          (a) => SizedBox(width: AppButtonStyles.dialogButtonWidth, child: a),
        )
        .toList();

    final nameField = LabeledFormField(
      label: l10n.teamLocationNameLabel,
      child: TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? l10n.validationRequired : null,
      ),
    );

    final addressField = LabeledFormField(
      label: l10n.teamLocationAddressLabel,
      child: TextFormField(
        controller: _addressController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );

    final emailField = LabeledFormField(
      label: l10n.teamLocationEmailLabel,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          hintText: l10n.teamLocationEmailHint,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null; // Optional
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(v.trim())) {
            return l10n.validationInvalidEmail;
          }
          return null;
        },
      ),
    );

    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          nameField,
          const SizedBox(height: AppSpacing.formRowSpacing),
          addressField,
          const SizedBox(height: AppSpacing.formRowSpacing),
          emailField,
          const SizedBox(height: AppSpacing.formRowSpacing),
          SwitchListTile(
            title: Text(l10n.teamLocationIsActiveLabel),
            subtitle: Text(
              l10n.teamLocationIsActiveHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          // Sezione Limiti Prenotazione Online
          Text(
            l10n.teamLocationBookingLimitsSection,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(l10n.teamLocationAllowCustomerChooseStaffLabel),
            subtitle: Text(
              l10n.teamLocationAllowCustomerChooseStaffHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: _allowCustomerChooseStaff,
            onChanged: (v) => setState(() => _allowCustomerChooseStaff = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          // Preavviso minimo
          LabeledFormField(
            label: l10n.teamLocationMinBookingNoticeLabel,
            child: DropdownButtonFormField<int>(
              value: _minBookingNoticeHours,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                helperText: l10n.teamLocationMinBookingNoticeHint,
              ),
              items: _noticeHoursOptions.map((hours) {
                return DropdownMenuItem(
                  value: hours,
                  child: Text(l10n.teamLocationHours(hours)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _minBookingNoticeHours = v);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),
          // Anticipo massimo
          LabeledFormField(
            label: l10n.teamLocationMaxBookingAdvanceLabel,
            child: DropdownButtonFormField<int>(
              value: _maxBookingAdvanceDays,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                helperText: l10n.teamLocationMaxBookingAdvanceHint,
              ),
              items: _advanceDaysOptions.map((days) {
                return DropdownMenuItem(
                  value: days,
                  child: Text(l10n.teamLocationDays(days)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _maxBookingAdvanceDays = v);
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.formRowSpacing),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );

    if (ref.read(formFactorProvider) == AppFormFactor.desktop) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
          child: FormLoadingOverlay(
            isLoading: _isLoading,
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
        ),
      );
    }

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
          return FormLoadingOverlay(
            isLoading: _isLoading,
            child: SizedBox(
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: 0,
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Align(
                        alignment: bottomActions.length == 3
                            ? Alignment.center
                            : Alignment.centerRight,
                        child: Wrap(
                          alignment: bottomActions.length == 3
                              ? WrapAlignment.center
                              : WrapAlignment.end,
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
            ),
          );
        },
      ),
    );
  }

  bool _isLoading = false;
  String? _error;

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final notifier = ref.read(locationsProvider.notifier);
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();

    try {
      if (widget.initial != null) {
        // Aggiorna location esistente
        await notifier.updateLocation(
          locationId: widget.initial!.id,
          name: name,
          address: address.isEmpty ? null : address,
          email: email.isEmpty ? null : email,
          isActive: _isActive,
          minBookingNoticeHours: _minBookingNoticeHours,
          maxBookingAdvanceDays: _maxBookingAdvanceDays,
          allowCustomerChooseStaff: _allowCustomerChooseStaff,
        );
      } else {
        // Crea nuova location
        await notifier.create(
          name: name,
          address: address.isEmpty ? null : address,
          email: email.isEmpty ? null : email,
          isActive: _isActive,
          minBookingNoticeHours: _minBookingNoticeHours,
          maxBookingAdvanceDays: _maxBookingAdvanceDays,
          allowCustomerChooseStaff: _allowCustomerChooseStaff,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
}
