import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../agenda/providers/business_providers.dart';
import '../providers/billing_provider.dart';

Future<bool?> showAdminBusinessBillingConfigDialog(
  BuildContext context, {
  required int businessId,
  required String businessName,
}) {
  return AppForm.show<bool>(
    context: context,
    builder: (_) => AdminBusinessBillingConfigDialog(
      businessId: businessId,
      businessName: businessName,
    ),
  );
}

class AdminBusinessBillingConfigDialog extends ConsumerStatefulWidget {
  const AdminBusinessBillingConfigDialog({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final int businessId;
  final String businessName;

  @override
  ConsumerState<AdminBusinessBillingConfigDialog> createState() =>
      _AdminBusinessBillingConfigDialogState();
}

class _AdminBusinessBillingConfigDialogState
    extends ConsumerState<AdminBusinessBillingConfigDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _enabled = false;
  String _currency = 'EUR';
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(
      adminBusinessBillingConfigProvider(widget.businessId),
    );

    return AlertDialog(
      title: Text(context.l10n.billingAdminDialogTitle(widget.businessName)),
      content: SizedBox(
        width: 480,
        child: configAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(error.toString()),
          data: (config) {
            if (!_initialized) {
              _enabled = config.billingEnabled;
              _currency = config.currency;
              _amountController.text = config.amountCents == null
                  ? ''
                  : (config.amountCents! / 100).toStringAsFixed(2);
              _notesController.text = config.notes ?? '';
              _initialized = true;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  value: _enabled,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _enabled = value),
                  title: Text(context.l10n.billingAdminEnabledLabel),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  enabled: _enabled && !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+([,.]\d{0,2})?'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: context.l10n.billingMonthlyAmountLabel,
                    prefixText: '€ ',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _currency,
                  items: const [
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: _enabled && !_saving
                      ? (value) => setState(() => _currency = value ?? 'EUR')
                      : null,
                  decoration: InputDecoration(
                    labelText: context.l10n.billingCurrencyLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  enabled: !_saving,
                  maxLength: 255,
                  decoration: InputDecoration(
                    labelText: context.l10n.billingNotesLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (config.status.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${context.l10n.billingStatusLabel}: ${config.status}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(context),
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.actionSave),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final amountCents = _enabled
        ? _parseAmountCents(_amountController.text)
        : null;
    if (_enabled && (amountCents == null || amountCents <= 0)) {
      await FeedbackDialog.showError(
        context,
        title: context.l10n.errorTitle,
        message: context.l10n.billingAmountRequired,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(billingRepositoryProvider)
          .updateAdminConfig(
            businessId: widget.businessId,
            billingEnabled: _enabled,
            amountCents: amountCents,
            currency: _currency,
            providerCode: _enabled ? 'stripe' : null,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      ref.invalidate(adminBusinessBillingConfigProvider(widget.businessId));
      ref.invalidate(businessesProvider);
      if (context.mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (context.mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.errorTitle,
          message: e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int? _parseAmountCents(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    final parsed = double.tryParse(normalized);
    if (parsed == null) return null;
    return (parsed * 100).round();
  }
}
