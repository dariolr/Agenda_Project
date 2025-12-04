import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/clients.dart';
import '../../providers/clients_providers.dart';
import '../widgets/client_form.dart';

/// Mostra il dialog per creare o modificare un cliente.
/// Su mobile usa un modal bottom sheet full-screen, su tablet/desktop un dialog.
Future<void> showClientEditDialog(
  BuildContext context,
  WidgetRef ref, {
  Client? client,
}) async {
  final formFactor = ref.read(formFactorProvider);

  if (formFactor == AppFormFactor.mobile) {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ClientEditBottomSheet(initial: client),
    );
  } else {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClientEditDialog(initial: client),
    );
  }
}

class ClientEditDialog extends ConsumerStatefulWidget {
  const ClientEditDialog({super.key, this.initial});

  final Client? initial;

  @override
  ConsumerState<ClientEditDialog> createState() => _ClientEditDialogState();
}

class _ClientEditDialogState extends ConsumerState<ClientEditDialog> {
  final _form = GlobalKey<ClientFormState>();
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final screenWidth = MediaQuery.of(context).size.width;
    // Larghezza dialog: min 400, max 560, responsive
    final dialogWidth = screenWidth < 600 ? screenWidth * 0.95 : 560.0;

    return AppFormDialog(
      title: Text(
        isEditing ? context.l10n.clientsEdit : context.l10n.clientsNew,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 400, maxWidth: dialogWidth),
        child: ClientForm(
          key: _form,
          initial: widget.initial,
          onChanged: () {
            if (!_hasChanges) setState(() => _hasChanges = true);
          },
        ),
      ),
      actions: [
        // Pulsante elimina (solo in modifica)
        if (isEditing)
          TextButton(
            onPressed: _onDelete,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.actionDelete),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => _onCancel(context),
          child: Text(context.l10n.actionCancel),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: _onSave, child: Text(context.l10n.actionSave)),
      ],
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
    if (widget.initial == null) {
      ref.read(clientsProvider.notifier).addClient(client);
    } else {
      ref.read(clientsProvider.notifier).updateClient(client);
    }
    Navigator.of(context).pop();
  }
}

/// Bottom sheet full-screen per modifica/creazione cliente su mobile.
class ClientEditBottomSheet extends ConsumerStatefulWidget {
  const ClientEditBottomSheet({super.key, this.initial});

  final Client? initial;

  @override
  ConsumerState<ClientEditBottomSheet> createState() =>
      _ClientEditBottomSheetState();
}

class _ClientEditBottomSheetState extends ConsumerState<ClientEditBottomSheet> {
  final _form = GlobalKey<ClientFormState>();
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Header con titolo e azioni
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _onCancel(context),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditing ? l10n.clientsEdit : l10n.clientsNew,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (isEditing)
                    IconButton(
                      onPressed: _onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  FilledButton(
                    onPressed: _onSave,
                    child: Text(l10n.actionSave),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Form scrollabile
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: ClientForm(
                  key: _form,
                  initial: widget.initial,
                  onChanged: () {
                    if (!_hasChanges) setState(() => _hasChanges = true);
                  },
                ),
              ),
            ),
          ],
        );
      },
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
    if (widget.initial == null) {
      ref.read(clientsProvider.notifier).addClient(client);
    } else {
      ref.read(clientsProvider.notifier).updateClient(client);
    }
    Navigator.of(context).pop();
  }
}
