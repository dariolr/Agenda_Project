import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/business_payment_method.dart';
import '../../../../core/widgets/feedback_dialog.dart';
import '../../../agenda/providers/business_providers.dart';
import '../../providers/payment_methods_provider.dart';

Future<bool> showPaymentMethodDialog(
  BuildContext context,
  WidgetRef ref, {
  BusinessPaymentMethod? existing,
}) async {
  final nameController = TextEditingController(text: existing?.name ?? '');

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          existing == null
              ? context.l10n.paymentMethodsAdd
              : context.l10n.paymentMethodsEdit,
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: context.l10n.paymentMethodsFieldName,
          ),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionSave),
          ),
        ],
      );
    },
  );

  if (result != true || !context.mounted) return false;

  final businessId = ref.read(currentBusinessIdProvider);
  if (businessId <= 0) return false;

  final name = nameController.text.trim();
  if (name.isEmpty) {
    await FeedbackDialog.showError(
      context,
      title: context.l10n.paymentMethodsTitle,
      message: context.l10n.paymentMethodsNameRequired,
    );
    return false;
  }

  try {
    final repository = ref.read(paymentMethodsRepositoryProvider);
    if (existing == null) {
      await repository.create(businessId: businessId, name: name);
    } else {
      await repository.update(
        businessId: businessId,
        methodId: existing.id,
        name: name,
        sortOrder: existing.sortOrder,
      );
    }
    ref.invalidate(paymentMethodsProvider);
    ref.invalidate(paymentMethodsWithInactiveProvider);
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    await FeedbackDialog.showError(
      context,
      title: context.l10n.paymentMethodsTitle,
      message: e.toString(),
    );
    return false;
  }
}
