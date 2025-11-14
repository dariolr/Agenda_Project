import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service_category.dart';
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

  final nameController = TextEditingController(text: category?.name ?? '');
  final descController = TextEditingController(
    text: category?.description ?? '',
  );

  bool nameError = false;
  bool duplicateError = false;

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AppFormDialog(
        title: Text(
          category == null
              ? context.l10n.newCategoryTitle
              : context.l10n.editCategoryTitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: context.l10n.fieldNameRequiredLabel,
                errorText: nameError
                    ? context.l10n.fieldNameRequiredError
                    : (duplicateError
                          ? context.l10n.categoryDuplicateError
                          : null),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final rawName = nameController.text.trim();
              if (rawName.isEmpty) {
                setState(() => nameError = true);
                return;
              }

              final formattedName = ServiceTextUtils.normalizeTitleCased(
                rawName,
              );

              if (ServiceValidators.isDuplicateCategoryName(
                allCategories,
                formattedName,
                excludeId: category?.id,
              )) {
                setState(() => duplicateError = true);
                return;
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

              Navigator.pop(context);
            },
            child: Text(context.l10n.actionSave),
          ),
        ],
      ),
    ),
  );
}
