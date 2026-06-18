import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/widgets/app_form.dart';
import '../../agenda/providers/business_providers.dart';
import '../domain/booking_form_models.dart';
import '../providers/booking_forms_provider.dart';

class BookingFormsScreen extends ConsumerStatefulWidget {
  const BookingFormsScreen({super.key});

  @override
  ConsumerState<BookingFormsScreen> createState() => _BookingFormsScreenState();
}

class _BookingFormsScreenState extends ConsumerState<BookingFormsScreen> {
  BookingForm? _selected;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _internalNameController = TextEditingController();
  bool _isActive = true;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _internalNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formsAsync = ref.watch(bookingFormsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.bookingFormsAdminTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _newForm,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.bookingFormsNew),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: formsAsync.when(
                  data: (forms) => _buildContent(context, forms),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text(error.toString())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<BookingForm> forms) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final list = _buildList(context, forms);
    final detail = _buildDetail(context);
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 360, child: list),
          const VerticalDivider(width: 32),
          Expanded(child: detail),
        ],
      );
    }
    return ListView(children: [list, const SizedBox(height: 16), detail]);
  }

  Widget _buildList(BuildContext context, List<BookingForm> forms) {
    final l10n = context.l10n;
    if (forms.isEmpty) {
      return Center(child: Text(l10n.bookingFormsEmpty));
    }
    return ListView.separated(
      itemCount: forms.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final form = forms[index];
        return ListTile(
          selected: _selected?.id == form.id,
          leading: Icon(
            form.isActive
                ? Icons.assignment_outlined
                : Icons.visibility_off_outlined,
          ),
          title: Text(form.title),
          subtitle: Text(
            l10n.bookingFormsListMeta(
              form.fieldsCount ?? form.fields.length,
              form.assignmentsCount ?? form.assignments.length,
            ),
          ),
          onTap: () => _selectForm(form),
        );
      },
    );
  }

  Widget _buildDetail(BuildContext context) {
    final l10n = context.l10n;
    if (_selected == null && _titleController.text.isEmpty) {
      return Center(child: Text(l10n.bookingFormsSelectHint));
    }
    return ListView(
      children: [
        TextField(
          controller: _titleController,
          decoration: InputDecoration(labelText: l10n.bookingFormsFieldTitle),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: l10n.bookingFormsFieldDescription,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _internalNameController,
          decoration: InputDecoration(
            labelText: l10n.bookingFormsFieldInternalName,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.bookingFormsActive),
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _saving ? null : _saveForm,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(l10n.actionSave),
            ),
            if (_selected != null)
              OutlinedButton.icon(
                onPressed: _saving ? null : _assignBusinessWide,
                icon: const Icon(Icons.public_outlined),
                label: Text(l10n.bookingFormsAssignBusiness),
              ),
          ],
        ),
        if (_selected != null) ...[
          const SizedBox(height: 24),
          Text(
            l10n.bookingFormsFieldsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final field in _selected!.fields)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(field.label),
              subtitle: Text(
                '${field.fieldType}${field.isRequired ? ' · ${l10n.bookingFormsRequired}' : ''}',
              ),
              trailing: IconButton(
                tooltip: l10n.actionDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: _saving ? null : () => _deleteField(field),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _saving ? null : _showAddFieldDialog,
            icon: const Icon(Icons.add),
            label: Text(l10n.bookingFormsAddField),
          ),
        ],
      ],
    );
  }

  void _newForm() {
    setState(() {
      _selected = null;
      _titleController.clear();
      _descriptionController.clear();
      _internalNameController.clear();
      _isActive = true;
    });
  }

  Future<void> _selectForm(BookingForm form) async {
    final businessId = ref.read(currentBusinessIdProvider);
    final detailed = await ref
        .read(bookingFormsRepositoryProvider)
        .show(businessId, form.id);
    setState(() {
      _selected = detailed;
      _titleController.text = detailed.title;
      _descriptionController.text = detailed.description ?? '';
      _internalNameController.text = detailed.internalName ?? '';
      _isActive = detailed.isActive;
    });
  }

  Future<void> _saveForm() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final saved = await ref
          .read(bookingFormsRepositoryProvider)
          .saveForm(
            businessId,
            formId: _selected?.id,
            data: {
              'title': title,
              'description': _descriptionController.text.trim(),
              'internal_name': _internalNameController.text.trim(),
              'is_active': _isActive,
            },
          );
      await _selectForm(saved);
      ref.invalidate(bookingFormsProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _assignBusinessWide() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final updated = await ref
          .read(bookingFormsRepositoryProvider)
          .setBusinessAssignment(businessId, _selected!.id);
      setState(() => _selected = updated);
      ref.invalidate(bookingFormsProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteField(BookingFormField field) async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final updated = await ref
          .read(bookingFormsRepositoryProvider)
          .deactivateField(businessId, _selected!.id, field.id);
      setState(() => _selected = updated);
      ref.invalidate(bookingFormsProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAddFieldDialog() async {
    if (_selected == null) return;
    final result = await AppForm.show<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _BookingFormFieldDialog(),
    );
    if (result == null) return;
    setState(() => _saving = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final updated = await ref
          .read(bookingFormsRepositoryProvider)
          .addField(businessId, _selected!.id, result);
      setState(() => _selected = updated);
      ref.invalidate(bookingFormsProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _BookingFormFieldDialog extends StatefulWidget {
  const _BookingFormFieldDialog();

  @override
  State<_BookingFormFieldDialog> createState() =>
      _BookingFormFieldDialogState();
}

class _BookingFormFieldDialogState extends State<_BookingFormFieldDialog> {
  final _labelController = TextEditingController();
  final _optionsController = TextEditingController();
  String _fieldType = 'short_text';
  bool _required = false;

  @override
  void dispose() {
    _labelController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final requiresOptions =
        _fieldType == 'single_choice' || _fieldType == 'multiple_choice';
    return AlertDialog(
      title: Text(l10n.bookingFormsAddField),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _fieldType,
              decoration: InputDecoration(
                labelText: l10n.bookingFormsFieldType,
              ),
              items: [
                DropdownMenuItem(
                  value: 'short_text',
                  child: Text(l10n.bookingFormsFieldTypeShortText),
                ),
                DropdownMenuItem(
                  value: 'long_text',
                  child: Text(l10n.bookingFormsFieldTypeLongText),
                ),
                DropdownMenuItem(
                  value: 'single_choice',
                  child: Text(l10n.bookingFormsFieldTypeSingleChoice),
                ),
                DropdownMenuItem(
                  value: 'multiple_choice',
                  child: Text(l10n.bookingFormsFieldTypeMultipleChoice),
                ),
                DropdownMenuItem(
                  value: 'checkbox',
                  child: Text(l10n.bookingFormsFieldTypeCheckbox),
                ),
                DropdownMenuItem(
                  value: 'consent',
                  child: Text(l10n.bookingFormsFieldTypeConsent),
                ),
                DropdownMenuItem(
                  value: 'info_text',
                  child: Text(l10n.bookingFormsFieldTypeInfoText),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _fieldType = value;
                  if (_fieldType == 'info_text') _required = false;
                });
              },
            ),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l10n.bookingFormsFieldLabel,
              ),
            ),
            if (requiresOptions)
              TextField(
                controller: _optionsController,
                decoration: InputDecoration(
                  labelText: l10n.bookingFormsOptionsHint,
                ),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _required,
              onChanged: _fieldType == 'info_text'
                  ? null
                  : (value) => setState(() => _required = value ?? false),
              title: Text(l10n.bookingFormsRequired),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            final label = _labelController.text.trim();
            if (label.isEmpty) return;
            final options = _optionsController.text
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .map((line) => {'value': line, 'label': line})
                .toList();
            Navigator.of(context).pop({
              'field_type': _fieldType,
              'label': label,
              'is_required': _required,
              if (options.isNotEmpty) 'options': options,
            });
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
