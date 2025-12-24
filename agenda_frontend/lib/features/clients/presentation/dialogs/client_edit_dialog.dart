import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/clients.dart';
import '../../providers/clients_providers.dart';
import '../widgets/client_form.dart';

/// Mostra il dialog per creare o modificare un cliente.
/// Su mobile usa un modal bottom sheet full-screen, su tablet/desktop un dialog.
/// Ritorna il [Client] salvato (creato o modificato), oppure null se annullato.
///
/// Se [client] ha un id <= 0, il dialog sarà in modalità creazione.
/// Se [client] ha un id > 0, il dialog sarà in modalità modifica.
Future<Client?> showClientEditDialog(
  BuildContext context,
  WidgetRef ref, {
  Client? client,
}) async {
  final formFactor = ref.read(formFactorProvider);

  if (formFactor == AppFormFactor.desktop) {
    return await showDialog<Client>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClientEditDialog(initial: client),
    );
  } else {
    return await AppBottomSheet.show<Client>(
      context: context,
      useRootNavigator: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      heightFactor: AppBottomSheet.defaultHeightFactor,
      builder: (_) => ClientEditBottomSheet(initial: client),
    );
  }
}

class ClientEditDialog extends ConsumerStatefulWidget {
  const ClientEditDialog({super.key, this.initial});

  final Client? initial;

  /// Un cliente con id > 0 è esistente (modifica), altrimenti è nuovo (creazione).
  bool get isExistingClient => (initial?.id ?? 0) > 0;

  @override
  ConsumerState<ClientEditDialog> createState() => _ClientEditDialogState();
}

class _ClientEditDialogState extends ConsumerState<ClientEditDialog> {
  final _form = GlobalKey<ClientFormState>();
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isExistingClient;
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return DismissibleDialog(
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600, maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? l10n.clientsEdit : l10n.clientsNew,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: ClientForm(
                      key: _form,
                      initial: widget.initial,
                      onChanged: () {
                        if (!_hasChanges) setState(() => _hasChanges = true);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isEditing) ...[
                      SizedBox(
                        width: AppButtonStyles.dialogButtonWidth,
                        child: AppDangerButton(
                          onPressed: _onDelete,
                          padding: AppButtonStyles.dialogButtonPadding,
                          child: Text(l10n.actionDelete),
                        ),
                      ),
                      const Spacer(),
                    ],
                    SizedBox(
                      width: AppButtonStyles.dialogButtonWidth,
                      child: AppOutlinedActionButton(
                        onPressed: () => _onCancel(context),
                        padding: AppButtonStyles.dialogButtonPadding,
                        child: Text(l10n.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: AppButtonStyles.dialogButtonWidth,
                      child: AppFilledButton(
                        onPressed: _onSave,
                        padding: AppButtonStyles.dialogButtonPadding,
                        child: Text(l10n.actionSave),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCancel(BuildContext context) async {
    if (_hasChanges) {
      final confirm = await showConfirmDialog(
        context,
        title: Text(context.l10n.discardChangesTitle),
        content: Text(context.l10n.discardChangesMessage),
        confirmLabel: context.l10n.actionDiscard,
        cancelLabel: context.l10n.actionKeepEditing,
      );
      if (!confirm) return;
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _onDelete() async {
    final client = widget.initial;
    if (client == null) return;

    final confirm = await showConfirmDialog(
      context,
      title: Text(context.l10n.deleteClientConfirmTitle),
      content: Text(context.l10n.deleteClientConfirmMessage),
      confirmLabel: context.l10n.actionDelete,
      danger: true,
    );
    if (!confirm) return;

    ref.read(clientsProvider.notifier).deleteClient(client.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _onSave() {
    final formState = _form.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    final client = formState.buildClient();
    final Client savedClient;
    if (widget.isExistingClient) {
      ref.read(clientsProvider.notifier).updateClient(client);
      savedClient = client;
    } else {
      savedClient = ref.read(clientsProvider.notifier).addClient(client);
    }
    Navigator.of(context).pop(savedClient);
  }
}

/// Bottom sheet per modifica/creazione cliente su mobile.
/// Usa lo stesso layout degli altri bottom sheet dell'app.
class ClientEditBottomSheet extends ConsumerStatefulWidget {
  const ClientEditBottomSheet({super.key, this.initial});

  final Client? initial;

  /// Un cliente con id > 0 è esistente (modifica), altrimenti è nuovo (creazione).
  bool get isExistingClient => (initial?.id ?? 0) > 0;

  @override
  ConsumerState<ClientEditBottomSheet> createState() =>
      _ClientEditBottomSheetState();
}

class _ClientEditBottomSheetState extends ConsumerState<ClientEditBottomSheet> {
  final _form = GlobalKey<ClientFormState>();
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isExistingClient;
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final title = isEditing ? l10n.clientsEdit : l10n.clientsNew;

    // Azioni in basso - stesso stile di appointment_dialog
    final actions = <Widget>[
      if (isEditing)
        AppDangerButton(
          onPressed: _onDelete,
          padding: AppButtonStyles.dialogButtonPadding,
          child: Text(l10n.actionDelete),
        ),
      AppOutlinedActionButton(
        onPressed: () => _onCancel(context),
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionCancel),
      ),
      AppFilledButton(
        onPressed: _onSave,
        padding: AppButtonStyles.dialogButtonPadding,
        child: Text(l10n.actionSave),
      ),
    ];

    // Usa le stesse dimensioni dei bottoni del dialog appuntamento per
    // mantenere coerenza visiva tra i form.
    final bottomActions = actions
        .map(
          (a) => SizedBox(width: AppButtonStyles.dialogButtonWidth, child: a),
        )
        .toList();

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
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(title, style: theme.textTheme.titleLarge),
                        ),
                        ClientForm(
                          key: _form,
                          initial: widget.initial,
                          onChanged: () {
                            if (!_hasChanges) setState(() => _hasChanges = true);
                          },
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: AppSpacing.formRowSpacing),
                      ],
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

  Future<void> _onCancel(BuildContext context) async {
    if (_hasChanges) {
      final confirm = await showConfirmDialog(
        context,
        title: Text(context.l10n.discardChangesTitle),
        content: Text(context.l10n.discardChangesMessage),
        confirmLabel: context.l10n.actionDiscard,
        cancelLabel: context.l10n.actionKeepEditing,
      );
      if (!confirm) return;
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _onDelete() async {
    final client = widget.initial;
    if (client == null) return;

    final confirm = await showConfirmDialog(
      context,
      title: Text(context.l10n.deleteClientConfirmTitle),
      content: Text(context.l10n.deleteClientConfirmMessage),
      confirmLabel: context.l10n.actionDelete,
      danger: true,
    );
    if (!confirm) return;

    ref.read(clientsProvider.notifier).deleteClient(client.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _onSave() {
    final formState = _form.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    final client = formState.buildClient();
    final Client savedClient;
    if (widget.isExistingClient) {
      ref.read(clientsProvider.notifier).updateClient(client);
      savedClient = client;
    } else {
      savedClient = ref.read(clientsProvider.notifier).addClient(client);
    }
    Navigator.of(context).pop(savedClient);
  }
}
