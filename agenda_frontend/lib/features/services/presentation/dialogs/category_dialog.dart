import 'package:agenda_frontend/app/providers/form_factor_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service_category.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_dialogs.dart';
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
  final descController = TextEditingController(text: category?.description ?? '');

  bool nameError = false;
  bool duplicateError = false;

  Widget buildContent(void Function(VoidCallback) setState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: context.l10n.fieldNameRequiredLabel,
            errorText: nameError
                ? context.l10n.fieldNameRequiredError
                : (duplicateError ? context.l10n.categoryDuplicateError : null),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: descController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.l10n.fieldDescriptionLabel,
          ),
        ),
      ],
    );
  }

  Future<void> handleSave() async {
    final rawName = nameController.text.trim();
    if (rawName.isEmpty) {
      nameError = true;
      return;
    }

    final formattedName = StringUtils.toTitleCase(rawName);

    if (ServiceValidators.isDuplicateCategoryName(
      allCategories,
      formattedName,
      excludeId: category?.id,
    )) {
      duplicateError = true;
      return;
    }

    final newCategory = ServiceCategory(
      id: category?.id ?? DateTime.now().millisecondsSinceEpoch,
      businessId: ref.read(currentBusinessProvider).id,
      name: formattedName,
      description:
          descController.text.trim().isEmpty ? null : descController.text.trim(),
      sortOrder: category?.sortOrder ?? allCategories.length,
    );

    if (category == null) {
      notifier.addCategory(newCategory);
    } else {
      notifier.updateCategory(newCategory);
    }

    Navigator.pop(context);
  }

  final title =
      category == null ? context.l10n.newCategoryTitle : context.l10n.editCategoryTitle;

  final builder = StatefulBuilder(
    builder: (ctx, setState) {
      final content = buildContent(setState);
      final actions = [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: () async {
            await handleSave();
            setState(() {});
          },
          child: Text(context.l10n.actionSave),
        ),
      ];

      final bottomActions = actions
          .map(
            (a) => ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 110),
              child: a,
            ),
          )
          .toList();

      if (isDesktop) {
        return AppFormDialog(
          title: Text(title),
          content: content,
          actions: actions,
        );
      }

      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
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
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: bottomActions,
                ),
              ),
              SizedBox(height: 32 + MediaQuery.of(ctx).viewPadding.bottom),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
    );
  }
}
