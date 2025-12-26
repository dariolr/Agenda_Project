import 'package:agenda_backend/app/providers/form_factor_provider.dart';
import 'package:agenda_backend/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_dividers.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../agenda/providers/business_providers.dart';
import '../../providers/service_categories_provider.dart';
import '../../utils/service_validators.dart';

Future<void> showCategoryDialog(
  BuildContext context,
  WidgetRef ref, {
  ServiceCategory? category,
}) async {
  final notifier = ref.read(serviceCategoriesProvider.notifier);
  final allCategories = ref.read(serviceCategoriesProvider);
  final isDesktop = ref.read(formFactorProvider) == AppFormFactor.desktop;

  final nameController = TextEditingController(text: category?.name ?? '');
  final descController = TextEditingController(
    text: category?.description ?? '',
  );

  bool nameError = false;
  bool duplicateError = false;

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

    final formattedName = StringUtils.toTitleCase(rawName);

    if (ServiceValidators.isDuplicateCategoryName(
      allCategories,
      formattedName,
      excludeId: category?.id,
    )) {
      duplicateError = true;
      return false;
    }

    final newCategory = ServiceCategory(
      id: category?.id ?? DateTime.now().millisecondsSinceEpoch,
      businessId: ref.read(currentBusinessProvider).id,
      name: formattedName,
      description: descController.text.trim().isEmpty
          ? null
          : descController.text.trim(),
      sortOrder: category?.sortOrder ?? allCategories.length,
    );

    if (category == null) {
      notifier.addCategory(newCategory);
    } else {
      notifier.updateCategory(newCategory);
    }

    return true;
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
          onPressed: () => Navigator.pop(ctx),
          padding: AppButtonStyles.dialogButtonPadding,
          child: Text(context.l10n.actionCancel),
        ),
      );

      final saveButton = SizedBox(
        width: AppButtonStyles.dialogButtonWidth,
        child: AppFilledButton(
          onPressed: () async {
            final closed = await handleSave();
            if (!closed) {
              setState(() {});
            } else {
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            }
          },
          padding: AppButtonStyles.dialogButtonPadding,
          child: Text(context.l10n.actionSave),
        ),
      );

      if (isDesktop) {
        return DismissibleDialog(
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: Theme.of(ctx).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    content,
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        cancelButton,
                        const SizedBox(width: 8),
                        saveButton,
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
          builder: (ctx, constraints) {
            final isKeyboardOpen =
                MediaQuery.of(ctx).viewInsets.bottom > 0;
            return SizedBox(
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  title,
                                  style: Theme.of(ctx).textTheme.titleLarge,
                                ),
                              ),
                              content,
                              const SizedBox(height: 24),
                              const SizedBox(height: AppSpacing.formRowSpacing),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  if (!isKeyboardOpen) ...[
                    const AppBottomSheetDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: [cancelButton, saveButton],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: MediaQuery.of(ctx).viewPadding.bottom),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  if (isDesktop) {
    await showDialog(context: context, builder: (_) => builder);
  } else {
    await AppBottomSheet.show(
      context: context,
      builder: (_) => builder,
      useRootNavigator: true,
      padding: EdgeInsets.zero,
    );
  }
}
