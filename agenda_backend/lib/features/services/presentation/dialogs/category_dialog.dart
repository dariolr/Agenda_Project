import 'package:agenda_backend/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../providers/service_categories_provider.dart';
import '../../utils/service_validators.dart';

Future<void> showCategoryDialog(
  BuildContext context,
  WidgetRef ref, {
  ServiceCategory? category,
}) async {
  final notifier = ref.read(serviceCategoriesProvider.notifier);
  final allCategories = ref.read(serviceCategoriesProvider);

  final nameController = TextEditingController(text: category?.name ?? '');
  final descController = TextEditingController(
    text: category?.description ?? '',
  );

  bool nameError = false;
  bool duplicateError = false;
  bool isSaving = false;

  Widget buildContent(void Function(VoidCallback) setState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledFormField(
          label: context.l10n.fieldNameRequiredLabel,
          child: TextField(
            controller: nameController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: nameError
                  ? context.l10n.fieldNameRequiredError
                  : (duplicateError
                        ? context.l10n.categoryDuplicateError
                        : null),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.formRowSpacing),
        LabeledFormField(
          label: context.l10n.fieldDescriptionLabel,
          child: TextField(
            controller: descController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> handleSave() async {
    final rawName = nameController.text.trim();
    if (rawName.isEmpty) {
      nameError = true;
      return false;
    }

    final formattedName = rawName.toUpperCase();

    if (ServiceValidators.isDuplicateCategoryName(
      allCategories,
      formattedName,
      excludeId: category?.id,
    )) {
      duplicateError = true;
      return false;
    }

    final description = descController.text.trim().isEmpty
        ? null
        : descController.text.trim();

    if (category == null) {
      // Create new category via API
      final result = await notifier.createCategoryApi(
        name: formattedName,
        description: description,
      );
      return result != null;
    } else {
      // Update existing category via API
      final result = await notifier.updateCategoryApi(
        categoryId: category.id,
        name: formattedName,
        description: description,
      );
      return result != null;
    }
  }

  final title = category == null
      ? context.l10n.newCategoryTitle
      : context.l10n.editCategoryTitle;

  final builder = StatefulBuilder(
    builder: (ctx, setState) {
      final content = buildContent(setState);

      final cancelButton = SizedBox(
        width: AppButtonStyles.dialogButtonWidth,
        child: AppOutlinedActionButton(
          onPressed: isSaving ? null : () => Navigator.pop(ctx),
          padding: AppButtonStyles.dialogButtonPadding,
          child: Text(context.l10n.actionCancel),
        ),
      );

      final saveButton = SizedBox(
        width: AppButtonStyles.dialogButtonWidth,
        child: AppAsyncFilledButton(
          onPressed: isSaving
              ? null
              : () async {
                  setState(() => isSaving = true);
                  try {
                    final closed = await handleSave();
                    if (!closed) {
                      setState(() => isSaving = false);
                    } else {
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    }
                  } catch (e) {
                    setState(() => isSaving = false);
                  }
                },
          padding: AppButtonStyles.dialogButtonPadding,
          isLoading: isSaving,
          showSpinner: false,
          child: Text(context.l10n.actionSave),
        ),
      );

      return AppFormScaffold(
        title: Text(title),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            const SizedBox(height: 24),
            const SizedBox(height: AppSpacing.formRowSpacing),
          ],
        ),
        actions: [cancelButton, saveButton],
        isLoading: isSaving,
      );
    },
  );

  await AppForm.show(
    context: context,
    builder: (_) => builder,
    useRootNavigator: true,
    padding: EdgeInsets.zero,
  );
}
