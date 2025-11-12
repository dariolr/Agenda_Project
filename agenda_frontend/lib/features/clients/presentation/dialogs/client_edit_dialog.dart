import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../domain/clients.dart';
import '../../providers/clients_providers.dart';
import '../widgets/client_form_fixed.dart';

class ClientEditDialog extends ConsumerStatefulWidget {
  const ClientEditDialog({super.key, this.initial});

  final Client? initial;

  @override
  ConsumerState<ClientEditDialog> createState() => _ClientEditDialogState();
}

class _ClientEditDialogState extends ConsumerState<ClientEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _form = GlobalKey<ClientFormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initial == null
            ? context.l10n.clientsNew
            : context.l10n.clientsEdit,
      ),
      content: Form(
        key: _formKey,
        child: ClientForm(key: _form, initial: widget.initial),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(onPressed: _onSave, child: Text(context.l10n.actionSave)),
      ],
    );
  }

  void _onSave() {
    // Usa il form per costruire il Client
    final formState = _form.currentState;
    if (formState == null) return;
    final client = formState.buildClient();
    if (widget.initial == null) {
      ref.read(clientsProvider.notifier).addClient(client);
    } else {
      ref.read(clientsProvider.notifier).updateClient(client);
    }
    Navigator.of(context).pop();
  }
}
