import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10_extension.dart';
import '../../../core/models/class_event.dart';
import '../../../core/models/location.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/service_package.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_form.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/feedback_dialog.dart';
import '../../../core/widgets/labeled_form_field.dart';
import '../../agenda/providers/business_providers.dart';
import '../../agenda/providers/location_providers.dart';
import '../../class_events/providers/class_events_providers.dart';
import '../../services/providers/service_categories_provider.dart';
import '../../services/providers/service_packages_provider.dart';
import '../../services/providers/services_provider.dart';
import '../domain/booking_form_models.dart';
import '../providers/booking_forms_provider.dart';

// ============================================================================
// SCREEN — elenco moduli (body-only). L'editor è una pagina full-screen
// pushata sul root navigator, così usa una sola AppBar (quella della pagina)
// senza sovrapporsi alla toolbar applicativa.
// ============================================================================

class BookingFormsScreen extends ConsumerWidget {
  const BookingFormsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FormsListView(
      onNew: () => openBookingFormEditor(context, ref),
      onOpen: (form) => openBookingFormEditor(context, ref, formId: form.id),
    );
  }
}

/// Apre l'editor di un modulo come pagina full-screen sul root navigator,
/// così usa la sola AppBar della pagina (nessuna barra duplicata).
/// Esposta per essere richiamata anche dall'azione "Aggiungi" nella toolbar
/// applicativa ([scaffold_with_navigation]).
Future<void> openBookingFormEditor(
  BuildContext context,
  WidgetRef ref, {
  int? formId,
}) async {
  await Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(builder: (_) => _FormEditorView(formId: formId)),
  );
  ref.invalidate(bookingFormsProvider);
}

// ============================================================================
// LIST VIEW
// ============================================================================

class _FormsListView extends ConsumerStatefulWidget {
  const _FormsListView({required this.onNew, required this.onOpen});

  final VoidCallback onNew;
  final ValueChanged<BookingForm> onOpen;

  @override
  ConsumerState<_FormsListView> createState() => _FormsListViewState();
}

class _FormsListViewState extends ConsumerState<_FormsListView> {
  // Ordine locale ottimistico durante il drag&drop.
  List<BookingForm>? _order;
  bool _persisting = false;

  Future<void> _onReorder(
    List<BookingForm> forms,
    int oldIndex,
    int newIndex,
  ) async {
    if (_persisting) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final reordered = forms.toList();
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    setState(() {
      _order = reordered;
      _persisting = true;
    });
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      await ref.read(bookingFormsRepositoryProvider).reorderForms(businessId, [
        for (final f in reordered) f.id,
      ]);
      ref.invalidate(bookingFormsProvider);
    } finally {
      if (mounted) {
        setState(() {
          _persisting = false;
          _order = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formsAsync = ref.watch(bookingFormsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: formsAsync.when(
          data: (forms) => _buildList(context, _order ?? forms),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<BookingForm> forms) {
    final l10n = context.l10n;
    if (forms.isEmpty) {
      return _EmptyState(
        icon: Icons.assignment_outlined,
        title: l10n.bookingFormsEmpty,
        subtitle: l10n.bookingFormsAdminDescription,
        action: AppOutlinedActionButton(
          onPressed: widget.onNew,
          child: Text(l10n.bookingFormsNew),
        ),
      );
    }

    final reorderable = forms.length > 1;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: reorderable
            ? ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) => child,
                itemCount: forms.length,
                onReorder: (oldIndex, newIndex) =>
                    _onReorder(forms, oldIndex, newIndex),
                itemBuilder: (context, index) => Padding(
                  key: ValueKey('form-${forms[index].id}'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCard(context, forms[index], index: index),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                itemCount: forms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildCard(context, forms[index]),
              ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, BookingForm form, {int? index}) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final fieldsCount = form.fieldsCount ?? form.fields.length;
    final rulesCount = form.rulesCount ?? form.rules.length;
    final reasons = <String>[
      if (!form.isActive) l10n.bookingFormsWarningInactive,
      if (fieldsCount == 0) l10n.bookingFormsWarningNoFields,
      if (rulesCount == 0) l10n.bookingFormsWarningNoRules,
    ];
    final shown = reasons.isEmpty;

    return _FormCard(
      onTap: () => widget.onOpen(form),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index != null) ...[
                ReorderableDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8, top: 10),
                      child: Icon(
                        Icons.drag_indicator,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
              _LeadingIcon(active: form.isActive),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (form.internalName?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        form.internalName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      l10n.bookingFormsListMeta(fieldsCount, rulesCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusChip(shown: shown, active: form.isActive),
            ],
          ),
          if (!shown) ...[
            const SizedBox(height: 12),
            _WarningBanner(reasons: reasons),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// EDITOR VIEW — Modulo / Campi / Visibilità
// ============================================================================

class _FormEditorView extends ConsumerStatefulWidget {
  const _FormEditorView({this.formId});

  final int? formId;

  @override
  ConsumerState<_FormEditorView> createState() => _FormEditorViewState();
}

class _FormEditorViewState extends ConsumerState<_FormEditorView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _internalNameController = TextEditingController();

  bool _isActive = true;
  bool _saving = false;
  bool _loading = false;
  int _step = 0;

  BookingForm? _form;
  final List<BookingFormRule> _draftRules = [];

  @override
  void initState() {
    super.initState();
    if (widget.formId != null) {
      _loading = true;
      _loadDetail(widget.formId!);
    }
  }

  Future<void> _loadDetail(int formId) async {
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final detailed = await ref
          .read(bookingFormsRepositoryProvider)
          .show(businessId, formId);
      if (!mounted) return;
      setState(() {
        _form = detailed;
        _titleController.text = detailed.title;
        _descriptionController.text = detailed.description ?? '';
        _internalNameController.text = detailed.internalName ?? '';
        _isActive = detailed.isActive;
        _draftRules
          ..clear()
          ..addAll(detailed.rules);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _internalNameController.dispose();
    super.dispose();
  }

  // ---- status -------------------------------------------------------------

  List<String> _statusReasons() {
    final l10n = context.l10n;
    final form = _form;
    return <String>[
      if (!_isActive) l10n.bookingFormsWarningInactive,
      if (form == null || !form.fields.any((f) => f.isInputField))
        l10n.bookingFormsWarningNoFields,
      if (_draftRules.isEmpty) l10n.bookingFormsWarningNoRules,
    ];
  }

  // ---- persistence --------------------------------------------------------

  Future<void> _saveModule() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _step = 0);
      return;
    }
    setState(() => _saving = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final saved = await ref
          .read(bookingFormsRepositoryProvider)
          .saveForm(
            businessId,
            formId: _form?.id,
            data: {
              'title': title,
              'description': _descriptionController.text.trim(),
              'internal_name': _internalNameController.text.trim(),
              'is_active': _isActive,
            },
          );
      // Ricarico il dettaglio completo (campi + regole).
      final detailed = await ref
          .read(bookingFormsRepositoryProvider)
          .show(businessId, saved.id);
      if (!mounted) return;
      setState(() {
        _form = detailed;
        _draftRules
          ..clear()
          ..addAll(detailed.rules);
      });
      ref.invalidate(bookingFormsProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteForm() async {
    final form = _form;
    if (form == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: Text(context.l10n.bookingFormsDeleteTitle),
      content: Text(context.l10n.bookingFormsDeleteMessage),
      confirmLabel: context.l10n.actionDelete,
      cancelLabel: context.l10n.actionCancel,
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      await ref
          .read(bookingFormsRepositoryProvider)
          .deleteForm(businessId, form.id);
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _mutateForm(
    Future<BookingForm> Function(int businessId, int formId) action,
  ) async {
    final form = _form;
    if (form == null) return;
    setState(() => _saving = true);
    try {
      final businessId = ref.read(currentBusinessIdProvider);
      final updated = await action(businessId, form.id);
      if (!mounted) return;
      setState(() {
        _form = updated;
        _draftRules
          ..clear()
          ..addAll(updated.rules);
      });
      ref.invalidate(bookingFormsProvider);
    } catch (e) {
      if (mounted) {
        await FeedbackDialog.showError(
          context,
          title: context.l10n.bookingFormsFieldSaveError,
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---- fields -------------------------------------------------------------

  Future<void> _addOrEditField({BookingFormField? existing}) async {
    if (_form == null) return;
    final result = await AppForm.show<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BookingFormFieldDialog(initial: existing),
    );
    if (result == null) return;
    await _mutateForm((businessId, formId) {
      final repo = ref.read(bookingFormsRepositoryProvider);
      return existing == null
          ? repo.addField(businessId, formId, result)
          : repo.updateField(businessId, formId, existing.id, result);
    });
  }

  Future<void> _deleteField(BookingFormField field) async {
    final confirmed = await showConfirmDialog(
      context,
      title: Text(context.l10n.bookingFormsDeleteFieldTitle),
      content: Text(context.l10n.bookingFormsDeleteFieldMessage),
      confirmLabel: context.l10n.actionDelete,
      cancelLabel: context.l10n.actionCancel,
      danger: true,
    );
    if (confirmed != true) return;
    await _mutateForm(
      (businessId, formId) => ref
          .read(bookingFormsRepositoryProvider)
          .deactivateField(businessId, formId, field.id),
    );
  }

  Future<void> _reorderFields(int oldIndex, int newIndex) async {
    final form = _form;
    if (form == null) return;
    final fields = [...form.fields];
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final moved = fields.removeAt(oldIndex);
    fields.insert(newIndex, moved);
    // Aggiornamento ottimistico dell'ordine visivo.
    setState(() {
      _form = BookingForm(
        id: form.id,
        title: form.title,
        description: form.description,
        internalName: form.internalName,
        isActive: form.isActive,
        sortOrder: form.sortOrder,
        fieldsCount: form.fieldsCount,
        rulesCount: form.rulesCount,
        fields: fields,
        rules: form.rules,
      );
    });
    await _mutateForm(
      (businessId, formId) => ref
          .read(bookingFormsRepositoryProvider)
          .reorderFields(businessId, formId, [for (final f in fields) f.id]),
    );
  }

  // ---- regole di visualizzazione ------------------------------------------

  Future<void> _persistRules(List<BookingFormRule> rules) async {
    await _mutateForm(
      (businessId, formId) => ref
          .read(bookingFormsRepositoryProvider)
          .replaceRules(businessId, formId, rules),
    );
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      // Toolbar: solo il pulsante back. Titolo/stato/salva sono nel body.
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const SizedBox.shrink(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditorHeader(context),
                      const SizedBox(height: 24),
                      // Step selector (centrato)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                          child: _StepSelector(
                            step: _step,
                            onChanged: (value) => setState(() => _step = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Body
                      Expanded(
                        child: AbsorbPointer(
                          absorbing: _saving,
                          child: _buildStepBody(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEditorHeader(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final reasons = _statusReasons();
    final shown = reasons.isEmpty && _form != null;
    final title = _titleController.text.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Riga 1: titolo
          Text(
            title.isEmpty ? l10n.bookingFormsNew : title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Riga 2: sottotitolo (interamente leggibile)
          Text(
            l10n.bookingFormsEditorSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          // Riga 3: stato centrato (il pulsante Salva è nel tab Modulo)
          if (_form != null) ...[
            const SizedBox(height: 20),
            Center(
              child: _StatusChip(shown: shown, active: _isActive),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepBody(BuildContext context) {
    switch (_step) {
      case 1:
        return _buildFieldsStep(context);
      case 2:
        return _buildVisibilityStep(context);
      default:
        return _buildModuleStep(context);
    }
  }

  // ---- step 0: module -----------------------------------------------------

  Widget _buildModuleStep(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final reasons = _statusReasons();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        if (reasons.isNotEmpty) ...[
          _WarningBanner(reasons: reasons, dense: false),
          const SizedBox(height: 16),
        ],
        _SectionCard(
          icon: Icons.description_outlined,
          title: l10n.bookingFormsModuleDetailsTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledFormField(
                label: l10n.bookingFormsFieldTitle,
                child: TextField(
                  controller: _titleController,
                  decoration: _fieldDecoration(context),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              LabeledFormField(
                label: l10n.bookingFormsFieldDescription,
                child: TextField(
                  controller: _descriptionController,
                  decoration: _fieldDecoration(context),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
              LabeledFormField(
                label: l10n.bookingFormsFieldInternalName,
                child: TextField(
                  controller: _internalNameController,
                  decoration: _fieldDecoration(context),
                ),
              ),
              const _SectionSpacer(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.bookingFormsActive,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.bookingFormsActiveHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSwitch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Riga azioni: Elimina e Salva affiancati a destra.
        Row(
          children: [
            const Spacer(),
            if (_form != null) ...[
              AppDangerButton(
                onPressed: _saving ? null : _deleteForm,
                child: Text(l10n.actionDelete),
              ),
              const SizedBox(width: 12),
            ],
            AppFilledButton(
              onPressed: _saving ? null : _saveModule,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.actionSave),
            ),
          ],
        ),
      ],
    );
  }

  // ---- step 1: fields -----------------------------------------------------

  Widget _buildFieldsStep(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final form = _form;
    if (form == null) {
      return _SaveFirstPlaceholder(message: l10n.bookingFormsSaveModuleFirst);
    }
    final fields = form.fields;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header fisso: titolo "Campi" + pulsante Aggiungi (fuori dalla lista).
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.bookingFormsFieldsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppFilledButton(
                onPressed: _saving ? null : () => _addOrEditField(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.bookingFormsAddField),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Solo i campi sono nella lista scrollabile.
        Expanded(child: _buildFieldsList(context, fields)),
      ],
    );
  }

  Widget _buildFieldsList(BuildContext context, List<BookingFormField> fields) {
    final l10n = context.l10n;
    if (fields.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          _SectionCard(
            child: _EmptyState(
              icon: Icons.list_alt_outlined,
              title: l10n.bookingFormsFieldsEmpty,
              compact: true,
            ),
          ),
        ],
      );
    }
    if (fields.length == 1) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          _FieldCard(
            field: fields.first,
            onTap: _saving
                ? null
                : () => _addOrEditField(existing: fields.first),
            onDelete: _saving ? null : () => _deleteField(fields.first),
          ),
        ],
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => child,
      itemCount: fields.length,
      onReorder: _reorderFields,
      itemBuilder: (context, index) {
        final field = fields[index];
        return Padding(
          key: ValueKey('field-${field.id}'),
          padding: const EdgeInsets.only(bottom: 12),
          child: _FieldCard(
            field: field,
            index: index,
            onTap: _saving ? null : () => _addOrEditField(existing: field),
            onDelete: _saving ? null : () => _deleteField(field),
          ),
        );
      },
    );
  }

  // ---- step 2: visibility -------------------------------------------------

  Widget _buildVisibilityStep(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final form = _form;
    if (form == null) {
      return _SaveFirstPlaceholder(message: l10n.bookingFormsSaveModuleFirst);
    }

    final targets = _buildVisibilityTargets(
      locations: ref.watch(locationsProvider),
      categories: ref.watch(serviceCategoriesProvider),
      services: ref.watch(servicesProvider).value ?? const <Service>[],
      packages:
          ref.watch(servicePackagesProvider).value ?? const <ServicePackage>[],
      classEvents:
          ref.watch(classEventsProvider).value ?? const <ClassEvent>[],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        // Testo guida: ogni regola è un caso preciso; AND dentro, OR tra regole.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.bookingFormsRulesGuide,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          icon: Icons.rule_folder_outlined,
          title: l10n.bookingFormsRulesTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_draftRules.isEmpty)
                const _InlineNotice(
                  icon: Icons.warning_amber_rounded,
                  messageKey: _NoticeMessage.noRules,
                  tone: _NoticeTone.warning,
                )
              else
                for (var i = 0; i < _draftRules.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _RuleRow(
                    label: _ruleSentence(context, _draftRules[i], targets),
                    onDeleted: _saving
                        ? null
                        : () {
                            final next = [..._draftRules]..removeAt(i);
                            _persistRules(next);
                          },
                  ),
                ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: AppOutlinedActionButton(
                  onPressed: _saving ? null : () => _addRule(targets),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.bookingFormsRuleAdd),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addRule(_VisibilityTargets targets) async {
    final rule = await AppForm.show<BookingFormRule>(
      context: context,
      builder: (context) => _RuleBuilderDialog(targets: targets),
    );
    if (rule == null || rule.conditions.isEmpty) return;
    await _persistRules([..._draftRules, rule]);
  }

  String _ruleSentence(
    BuildContext context,
    BookingFormRule rule,
    _VisibilityTargets targets,
  ) {
    return _ruleSentenceText(context, rule, targets);
  }

  _VisibilityTargets _buildVisibilityTargets({
    required List<Location> locations,
    required List<ServiceCategory> categories,
    required List<Service> services,
    required List<ServicePackage> packages,
    required List<ClassEvent> classEvents,
  }) {
    return _VisibilityTargets(
      locations: [
        for (final location in locations)
          _AssignmentTarget(
            location.id,
            location.name,
            locationId: location.id,
          ),
      ],
      categories: [
        for (final category in categories)
          _AssignmentTarget(
            category.id,
            category.name,
            categoryId: category.id,
          ),
      ],
      appointments: [
        for (final service in services)
          if (service.serviceVariantId != null)
            _AppointmentTarget(
              scopeType: 'service_variant',
              id: service.serviceVariantId!,
              label: service.name,
              locationId: service.locationId,
            ),
        for (final servicePackage in packages)
          _AppointmentTarget(
            scopeType: 'service_package',
            id: servicePackage.id,
            label: servicePackage.name,
            locationId: servicePackage.locationId,
          ),
        for (final event in classEvents)
          _AppointmentTarget(
            scopeType: 'class_event',
            id: event.id,
            label: event.classTypeName?.isNotEmpty == true
                ? event.classTypeName!
                : '#${event.id}',
            locationId: event.locationId,
          ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.35)),
    ),
  );
}

/// Insieme degli elementi selezionabili nelle regole di visibilità.
class _VisibilityTargets {
  const _VisibilityTargets({
    required this.locations,
    required this.categories,
    required this.appointments,
  });

  final List<_AssignmentTarget> locations;
  final List<_AssignmentTarget> categories;
  final List<_AppointmentTarget> appointments;
}

/// Un tipo di appuntamento prenotabile (variante, pacchetto o lezione),
/// con la sede a cui è collegato.
class _AppointmentTarget {
  const _AppointmentTarget({
    required this.scopeType,
    required this.id,
    required this.label,
    this.locationId,
  });

  final String scopeType;
  final int id;
  final String label;
  final int? locationId;
}

/// Traduce una regola in una frase leggibile per l'operatore (senza simboli
/// tecnici come "+"). Esempi: "Solo sede Roma", "Massaggi nella sede Roma".
String _ruleSentenceText(
  BuildContext context,
  BookingFormRule rule,
  _VisibilityTargets targets,
) {
  final l10n = context.l10n;
  String? locationLabel;
  String? categoryLabel;
  String? appointmentLabel;
  var hasBusiness = false;

  for (final condition in rule.conditions) {
    final type = condition.scopeType;
    if (type == 'business') {
      hasBusiness = true;
    } else if (type == 'location') {
      locationLabel = _targetLabel(targets.locations, condition.scopeId);
    } else if (type == 'service_category') {
      categoryLabel = _targetLabel(targets.categories, condition.scopeId);
    } else {
      appointmentLabel = _appointmentTargetLabel(
        targets.appointments,
        type,
        condition.scopeId,
      );
    }
  }

  if (hasBusiness) return l10n.bookingFormsRuleBusiness;
  if (locationLabel != null && categoryLabel != null) {
    return l10n.bookingFormsRuleCategoryInLocation(categoryLabel, locationLabel);
  }
  if (locationLabel != null && appointmentLabel != null) {
    return l10n.bookingFormsRuleAppointmentInLocation(
      appointmentLabel,
      locationLabel,
    );
  }
  if (locationLabel != null) {
    return l10n.bookingFormsRuleLocationOnly(locationLabel);
  }
  if (categoryLabel != null) {
    return l10n.bookingFormsRuleCategoryOnly(categoryLabel);
  }
  if (appointmentLabel != null) {
    return l10n.bookingFormsRuleAppointmentOnly(appointmentLabel);
  }
  return l10n.bookingFormsRuleBusiness;
}

String? _targetLabel(List<_AssignmentTarget> list, int? id) {
  if (id == null) return null;
  for (final target in list) {
    if (target.id == id) return target.label;
  }
  return '#$id';
}

String? _appointmentTargetLabel(
  List<_AppointmentTarget> list,
  String scopeType,
  int? id,
) {
  if (id == null) return null;
  for (final target in list) {
    if (target.scopeType == scopeType && target.id == id) return target.label;
  }
  return '#$id';
}

class _AssignmentTarget {
  const _AssignmentTarget(
    this.id,
    this.label, {
    this.locationId,
    this.categoryId,
  });

  final int id;
  final String label;
  final int? locationId;
  final int? categoryId;
}

// ============================================================================
// SHARED PRESENTATION WIDGETS
// ============================================================================

class _StepSelector extends StatelessWidget {
  const _StepSelector({required this.step, required this.onChanged});

  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<int>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: 0,
          icon: const Icon(Icons.description_outlined, size: 18),
          label: Text(l10n.bookingFormsStepForm),
        ),
        ButtonSegment(
          value: 1,
          icon: const Icon(Icons.list_alt_outlined, size: 18),
          label: Text(l10n.bookingFormsStepFields),
        ),
        ButtonSegment(
          value: 2,
          icon: const Icon(Icons.public_outlined, size: 18),
          label: Text(l10n.bookingFormsStepVisibility),
        ),
      ],
      selected: {step},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.icon, this.title});

  final Widget child;
  final IconData? icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

class _SectionSpacer extends StatelessWidget {
  const _SectionSpacer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        active ? Icons.assignment_outlined : Icons.visibility_off_outlined,
        color: color,
        size: 22,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.shown, required this.active});

  final bool shown;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final Color color;
    final String label;
    final IconData icon;
    if (!active) {
      color = theme.colorScheme.onSurfaceVariant;
      label = l10n.bookingFormsStatusInactive;
      icon = Icons.pause_circle_outline;
    } else if (shown) {
      color = const Color(0xFF2E7D32);
      label = l10n.bookingFormsStatusShown;
      icon = Icons.check_circle_outline;
    } else {
      color = const Color(0xFFC62828);
      label = l10n.bookingFormsStatusHidden;
      icon = Icons.visibility_off_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.reasons, this.dense = true});

  final List<String> reasons;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    const color = Color(0xFFB26A00);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dense ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bookingFormsWontShowSummary,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reasons.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _NoticeTone { positive, warning }

enum _NoticeMessage { noRules }

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.messageKey,
    required this.tone,
  });

  final IconData icon;
  final _NoticeMessage messageKey;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = tone == _NoticeTone.positive
        ? const Color(0xFF2E7D32)
        : const Color(0xFFB26A00);
    final message = switch (messageKey) {
      _NoticeMessage.noRules => l10n.bookingFormsNoRulesHint,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Riga che mostra una regola come frase leggibile, con azione di rimozione.
class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, this.onDeleted});

  final String label;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDeleted != null)
            IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              icon: const Icon(Icons.close, size: 18),
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: onDeleted,
            ),
        ],
      ),
    );
  }
}

/// Dialog per comporre una regola di visualizzazione.
/// Combinazioni ammesse: solo business, solo sede, solo categoria, solo tipo
/// appuntamento, sede + categoria, sede + tipo appuntamento.
class _RuleBuilderDialog extends StatefulWidget {
  const _RuleBuilderDialog({required this.targets});

  final _VisibilityTargets targets;

  @override
  State<_RuleBuilderDialog> createState() => _RuleBuilderDialogState();
}

class _RuleBuilderDialogState extends State<_RuleBuilderDialog> {
  String _scope = 'business';
  int? _locationId;
  int? _categoryId;
  String _refine = 'none';
  _AppointmentTarget? _appointment;

  List<_AppointmentTarget> _appointmentsForLocation() {
    if (_locationId == null) return const [];
    return widget.targets.appointments
        .where((a) => a.locationId == _locationId)
        .toList();
  }

  BookingFormRule _draftRule() {
    switch (_scope) {
      case 'location':
        final conditions = <BookingFormCondition>[
          BookingFormCondition(scopeType: 'location', scopeId: _locationId),
        ];
        if (_refine == 'service_category' && _categoryId != null) {
          conditions.add(
            BookingFormCondition(
              scopeType: 'service_category',
              scopeId: _categoryId,
            ),
          );
        } else if (_refine == 'appointment' && _appointment != null) {
          conditions.add(
            BookingFormCondition(
              scopeType: _appointment!.scopeType,
              scopeId: _appointment!.id,
            ),
          );
        }
        return BookingFormRule(conditions: conditions);
      case 'service_category':
        return BookingFormRule(
          conditions: [
            BookingFormCondition(
              scopeType: 'service_category',
              scopeId: _categoryId,
            ),
          ],
        );
      case 'appointment':
        final appointment = _appointment;
        return BookingFormRule(
          conditions: appointment == null
              ? const []
              : [
                  BookingFormCondition(
                    scopeType: appointment.scopeType,
                    scopeId: appointment.id,
                  ),
                ],
        );
      case 'business':
      default:
        return const BookingFormRule(
          conditions: [BookingFormCondition(scopeType: 'business')],
        );
    }
  }

  bool _canSubmit() {
    switch (_scope) {
      case 'location':
        if (_locationId == null) return false;
        if (_refine == 'service_category') return _categoryId != null;
        if (_refine == 'appointment') return _appointment != null;
        return true;
      case 'service_category':
        return _categoryId != null;
      case 'appointment':
        return _appointment != null;
      case 'business':
      default:
        return true;
    }
  }

  void _submit() {
    final rule = _draftRule();
    if (rule.conditions.isEmpty) return;
    Navigator.of(context).pop(rule);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final targets = widget.targets;
    final hasCategories = targets.categories.isNotEmpty;
    final hasAppointments = targets.appointments.isNotEmpty;

    return AppFormScaffold(
      title: Text(l10n.bookingFormsRuleBuilderTitle),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledFormField(
            label: l10n.bookingFormsRuleScopeQuestion,
            child: Column(
              children: [
                _scopeTile('business', l10n.bookingFormsRuleScopeBusiness),
                _scopeTile('location', l10n.bookingFormsRuleScopeLocation),
                if (hasCategories)
                  _scopeTile(
                    'service_category',
                    l10n.bookingFormsRuleScopeCategory,
                  ),
                if (hasAppointments)
                  _scopeTile(
                    'appointment',
                    l10n.bookingFormsRuleScopeAppointment,
                  ),
              ],
            ),
          ),
          if (_scope == 'location') ...[
            const SizedBox(height: 16),
            LabeledFormField(
              label: l10n.bookingFormsRuleSelectLocation,
              child: DropdownButtonFormField<int>(
                initialValue: _locationId,
                decoration: _fieldDecoration(context),
                items: [
                  for (final location in targets.locations)
                    DropdownMenuItem(
                      value: location.id,
                      child: Text(location.label),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _locationId = value;
                  _appointment = null;
                }),
              ),
            ),
            const SizedBox(height: 16),
            LabeledFormField(
              label: l10n.bookingFormsRuleRefine,
              child: Column(
                children: [
                  _refineTile('none', l10n.bookingFormsRuleRefineNone),
                  if (hasCategories)
                    _refineTile(
                      'service_category',
                      l10n.bookingFormsRuleRefineCategory,
                    ),
                  if (hasAppointments)
                    _refineTile(
                      'appointment',
                      l10n.bookingFormsRuleRefineAppointment,
                    ),
                ],
              ),
            ),
            if (_refine == 'service_category') ...[
              const SizedBox(height: 12),
              _categoryDropdown(context),
            ],
            if (_refine == 'appointment') ...[
              const SizedBox(height: 12),
              _appointmentDropdown(context, _appointmentsForLocation()),
            ],
          ],
          if (_scope == 'service_category') ...[
            const SizedBox(height: 16),
            _categoryDropdown(context),
          ],
          if (_scope == 'appointment') ...[
            const SizedBox(height: 16),
            _appointmentDropdown(context, targets.appointments),
          ],
          if (_canSubmit()) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _ruleSentenceText(context, _draftRule(), targets),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        AppOutlinedActionButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        AppFilledButton(
          onPressed: _canSubmit() ? _submit : null,
          child: Text(l10n.bookingFormsRuleAdd),
        ),
      ],
    );
  }

  Widget _categoryDropdown(BuildContext context) {
    final l10n = context.l10n;
    return LabeledFormField(
      label: l10n.bookingFormsRuleSelectCategory,
      child: DropdownButtonFormField<int>(
        initialValue: _categoryId,
        decoration: _fieldDecoration(context),
        items: [
          for (final category in widget.targets.categories)
            DropdownMenuItem(value: category.id, child: Text(category.label)),
        ],
        onChanged: (value) => setState(() => _categoryId = value),
      ),
    );
  }

  Widget _appointmentDropdown(
    BuildContext context,
    List<_AppointmentTarget> items,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Text(
        l10n.bookingFormsRuleNoTargets,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final value = items.contains(_appointment) ? _appointment : null;
    return LabeledFormField(
      label: l10n.bookingFormsRuleSelectAppointment,
      child: DropdownButtonFormField<_AppointmentTarget>(
        key: ValueKey('appt-$_scope-$_locationId-$_refine'),
        initialValue: value,
        decoration: _fieldDecoration(context),
        items: [
          for (final appointment in items)
            DropdownMenuItem(
              value: appointment,
              child: Text(appointment.label),
            ),
        ],
        onChanged: (selected) => setState(() => _appointment = selected),
      ),
    );
  }

  Widget _scopeTile(String value, String label) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: value,
      // ignore: deprecated_member_use
      groupValue: _scope,
      title: Text(label),
      // ignore: deprecated_member_use
      onChanged: (selected) => setState(() {
        _scope = selected ?? 'business';
        _refine = 'none';
        _appointment = null;
        _categoryId = null;
      }),
    );
  }

  Widget _refineTile(String value, String label) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: value,
      // ignore: deprecated_member_use
      groupValue: _refine,
      title: Text(label),
      // ignore: deprecated_member_use
      onChanged: (selected) => setState(() {
        _refine = selected ?? 'none';
        _appointment = null;
        _categoryId = null;
      }),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.field,
    required this.onTap,
    required this.onDelete,
    this.index,
  });

  final BookingFormField field;

  /// Indice per il drag&drop. Se null, l'handle di riordino non viene mostrato
  /// (es. quando esiste un solo campo).
  final int? index;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              if (index != null) ...[
                ReorderableDragStartListener(
                  index: index!,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.drag_indicator,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                _fieldTypeIcon(field.fieldType),
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fieldTypeLabel(context, field.fieldType),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (field.isRequired)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.bookingFormsRequired,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                tooltip: l10n.actionDelete,
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.onSurfaceVariant,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 36 : 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class _SaveFirstPlaceholder extends StatelessWidget {
  const _SaveFirstPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _EmptyState(icon: Icons.save_outlined, title: message);
  }
}

IconData _fieldTypeIcon(String fieldType) {
  return switch (fieldType) {
    'short_text' => Icons.short_text,
    'long_text' => Icons.notes_outlined,
    'date' => Icons.calendar_today_outlined,
    'single_choice' => Icons.radio_button_checked,
    'segmented_choice' => Icons.splitscreen_outlined,
    'multiple_choice' => Icons.checklist_outlined,
    'checkbox' => Icons.check_box_outlined,
    'consent' => Icons.verified_user_outlined,
    'info_text' => Icons.info_outline,
    _ => Icons.help_outline,
  };
}

String _fieldTypeLabel(BuildContext context, String fieldType) {
  final l10n = context.l10n;
  return switch (fieldType) {
    'short_text' => l10n.bookingFormsFieldTypeShortText,
    'long_text' => l10n.bookingFormsFieldTypeLongText,
    'date' => l10n.bookingFormsFieldTypeDate,
    'single_choice' => l10n.bookingFormsFieldTypeSingleChoice,
    'segmented_choice' => l10n.bookingFormsFieldTypeSegmentedChoice,
    'multiple_choice' => l10n.bookingFormsFieldTypeMultipleChoice,
    'checkbox' => l10n.bookingFormsFieldTypeCheckbox,
    'consent' => l10n.bookingFormsFieldTypeConsent,
    'info_text' => l10n.bookingFormsFieldTypeInfoText,
    _ => fieldType,
  };
}

// ============================================================================
// FIELD DIALOG — creazione/modifica campo con anteprima live.
// ============================================================================

class _BookingFormFieldDialog extends StatefulWidget {
  const _BookingFormFieldDialog({this.initial});

  final BookingFormField? initial;

  @override
  State<_BookingFormFieldDialog> createState() =>
      _BookingFormFieldDialogState();
}

class _BookingFormFieldDialogState extends State<_BookingFormFieldDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _helpController;
  late final TextEditingController _consentUrlController;
  // Un controller per ogni opzione (campi a scelta).
  final List<TextEditingController> _optionControllers = [];
  late String _fieldType;
  late bool _required;
  bool _showOptionsError = false;

  static const _types = [
    'short_text',
    'long_text',
    'date',
    'single_choice',
    'segmented_choice',
    'multiple_choice',
    'checkbox',
    'consent',
    'info_text',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _labelController = TextEditingController(text: initial?.label ?? '');
    _helpController = TextEditingController(text: initial?.helpText ?? '');
    _consentUrlController = TextEditingController(
      text: initial?.consentUrl ?? '',
    );
    _fieldType = initial?.fieldType ?? 'short_text';
    _required = initial?.isRequired ?? false;
    for (final option in initial?.options ?? const <Map<String, String>>[]) {
      _optionControllers.add(
        TextEditingController(text: option['label'] ?? ''),
      );
    }
    _ensureMinOptions();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _helpController.dispose();
    _consentUrlController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _requiresOptions =>
      _fieldType == 'single_choice' ||
      _fieldType == 'segmented_choice' ||
      _fieldType == 'multiple_choice';

  bool get _isInfo => _fieldType == 'info_text';

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers.removeAt(index).dispose();
    });
  }

  /// I campi a scelta richiedono almeno due opzioni.
  void _ensureMinOptions() {
    if (_requiresOptions) {
      while (_optionControllers.length < 2) {
        _optionControllers.add(TextEditingController());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormScaffold(
      title: Text(
        widget.initial == null
            ? l10n.bookingFormsAddField
            : l10n.bookingFormsEditField,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledFormField(
            label: l10n.bookingFormsFieldType,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in _types)
                  _TypeChoiceChip(
                    icon: _fieldTypeIcon(type),
                    label: _fieldTypeLabel(context, type),
                    selected: _fieldType == type,
                    onTap: () => setState(() {
                      _fieldType = type;
                      if (_isInfo) _required = false;
                      _ensureMinOptions();
                    }),
                  ),
              ],
            ),
          ),
          if (_fieldType == 'consent') ...[
            const SizedBox(height: 16),
            LabeledFormField(
              label: l10n.bookingFormsConsentUrl,
              child: TextField(
                controller: _consentUrlController,
                decoration: _fieldDecoration(
                  context,
                  hint: l10n.bookingFormsConsentUrlHint,
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
          const SizedBox(height: 16),
          LabeledFormField(
            label: l10n.bookingFormsFieldLabel,
            child: TextField(
              controller: _labelController,
              decoration: _fieldDecoration(context),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          LabeledFormField(
            label: l10n.bookingFormsFieldHelpText,
            child: TextField(
              controller: _helpController,
              decoration: _fieldDecoration(context),
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_requiresOptions) ...[
            const SizedBox(height: 16),
            LabeledFormField(
              label: l10n.bookingFormsOptionsTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _optionControllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _optionControllers[i],
                              decoration: _fieldDecoration(
                                context,
                                hint: l10n.bookingFormsOptionHint,
                              ),
                              onChanged: (_) => setState(() {
                                if (_parsedOptions().isNotEmpty) {
                                  _showOptionsError = false;
                                }
                              }),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.actionDelete,
                            icon: const Icon(Icons.close),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            onPressed: _optionControllers.length > 2
                                ? () => _removeOption(i)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  if (_showOptionsError) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.bookingFormsOptionsRequired,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppOutlinedActionButton(
                      onPressed: _addOption,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.bookingFormsAddOption),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!_isInfo) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.bookingFormsRequired,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                AppSwitch(
                  value: _required,
                  onChanged: (value) => setState(() => _required = value),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _FieldPreview(
            fieldType: _fieldType,
            label: _labelController.text.trim(),
            helpText: _helpController.text.trim(),
            required: _required,
            options: _parsedOptions().map((o) => o['label']!).toList(),
            consentUrl: _fieldType == 'consent'
                ? _consentUrlController.text.trim()
                : null,
          ),
        ],
      ),
      actions: [
        AppOutlinedActionButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        AppFilledButton(onPressed: _submit, child: Text(l10n.actionSave)),
      ],
    );
  }

  List<Map<String, String>> _parsedOptions() {
    return _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .map((text) => {'value': text, 'label': text})
        .toList();
  }

  void _submit() {
    final label = _labelController.text.trim();
    if (label.isEmpty && _fieldType != 'consent') return;
    final options = _parsedOptions();
    // I tipi a scelta richiedono almeno due opzioni (validato anche lato server).
    if (_requiresOptions && options.length < 2) {
      setState(() => _showOptionsError = true);
      return;
    }
    final help = _helpController.text.trim();
    final consentUrl = _consentUrlController.text.trim();
    Navigator.of(context).pop({
      'field_type': _fieldType,
      'label': label,
      'is_required': _required,
      'help_text': help,
      'validation': _fieldType == 'consent' && consentUrl.isNotEmpty
          ? {'url': consentUrl}
          : <String, dynamic>{},
      // Invia le opzioni solo per i tipi a scelta: cambiando tipo verso un
      // campo non a scelta le vecchie opzioni vengono ripulite.
      'options': _requiresOptions ? options : <Map<String, String>>[],
    });
  }
}

class _TypeChoiceChip extends StatelessWidget {
  const _TypeChoiceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : Colors.grey.withValues(alpha: 0.35),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldPreview extends StatelessWidget {
  const _FieldPreview({
    required this.fieldType,
    required this.label,
    required this.helpText,
    required this.required,
    required this.options,
    this.consentUrl,
  });

  final String fieldType;
  final String label;
  final String helpText;
  final bool required;
  final List<String> options;
  final String? consentUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final displayLabel = label.isEmpty ? '' : label;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.bookingFormsFieldPreviewTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreviewBody(context, displayLabel),
          if (helpText.isNotEmpty && fieldType != 'info_text') ...[
            const SizedBox(height: 6),
            Text(
              helpText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewBody(BuildContext context, String displayLabel) {
    final theme = Theme.of(context);

    Widget labelText() => RichText(
      text: TextSpan(
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        children: [
          TextSpan(text: displayLabel),
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: theme.colorScheme.error),
            ),
        ],
      ),
    );

    switch (fieldType) {
      case 'info_text':
        return Text(displayLabel, style: theme.textTheme.bodyMedium);
      case 'long_text':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelText(),
            const SizedBox(height: 6),
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
            ),
          ],
        );
      case 'date':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelText(),
            const SizedBox(height: 6),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        );
      case 'single_choice':
      case 'segmented_choice':
      case 'multiple_choice':
        final isMulti = fieldType == 'multiple_choice';
        final opts = options.isEmpty ? ['—'] : options;
        if (fieldType == 'segmented_choice') {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelText(),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    for (final opt in opts)
                      ButtonSegment<String>(value: opt, label: Text(opt)),
                  ],
                  selected: const <String>{},
                  emptySelectionAllowed: true,
                  onSelectionChanged: null,
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelText(),
            const SizedBox(height: 6),
            for (final opt in opts)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      isMulti
                          ? Icons.check_box_outline_blank
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(opt, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        );
      case 'checkbox':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_box_outline_blank,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(child: labelText()),
          ],
        );
      case 'consent':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    labelText(),
                    if ((consentUrl ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        consentUrl!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      default: // short_text
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelText(),
            const SizedBox(height: 6),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
            ),
          ],
        );
    }
  }
}
