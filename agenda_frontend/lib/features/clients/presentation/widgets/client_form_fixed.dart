import 'package:flutter/material.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../domain/clients.dart';

class ClientForm extends StatefulWidget {
  const ClientForm({super.key, this.initial});

  final Client? initial;

  @override
  State<ClientForm> createState() => ClientFormState();
}

class ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.initial?.email ?? '',
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.initial?.phone ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.initial?.notes ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  Client buildClient() {
    final base = widget.initial;
    final now = DateTime.now();
    return Client(
      id: base?.id ?? -1,
      businessId: base?.businessId ?? 1,
      name: _name.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: base?.createdAt ?? now,
      lastVisit: base?.lastVisit,
      loyaltyPoints: base?.loyaltyPoints,
      tags: base?.tags,
      isArchived: base?.isArchived ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _fieldContainer(
              isWide ? 320 : double.infinity,
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: context.l10n.formName),
                textInputAction: TextInputAction.next,
                validator: (v) => v == null || v.trim().isEmpty
                    ? context.l10n.validationRequired
                    : null,
              ),
            ),
            _fieldContainer(
              isWide ? 320 : double.infinity,
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: context.l10n.formEmail),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return null; // optional
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(t))
                    return context.l10n.validationInvalidEmail;
                  return null;
                },
              ),
            ),
            _fieldContainer(
              isWide ? 220 : double.infinity,
              TextFormField(
                controller: _phone,
                decoration: InputDecoration(labelText: context.l10n.formPhone),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return null; // optional
                  final phoneRegex = RegExp(r'^[0-9+()\-\s]{6,}$');
                  if (!phoneRegex.hasMatch(t))
                    return context.l10n.validationInvalidPhone;
                  return null;
                },
              ),
            ),
            _fieldContainer(
              isWide ? 480 : double.infinity,
              TextFormField(
                controller: _notes,
                decoration: InputDecoration(labelText: context.l10n.formNotes),
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldContainer(double width, Widget child) {
    return SizedBox(width: width, child: child);
  }
}
