import 'package:flutter/material.dart';

import '../../domain/clients.dart';

class ClientForm extends StatefulWidget {
  const ClientForm({super.key, this.initial});

  final Client? initial;

  @override
  State<ClientForm> createState() => ClientFormState();
}

class ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _email = TextEditingController(text: widget.initial?.email ?? '');
    _phone = TextEditingController(text: widget.initial?.phone ?? '');
    _notes = TextEditingController(text: widget.initial?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
          final isWide = MediaQuery.of(context).size.width >= 720;
          return SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: isWide ? 320 : double.infinity,
                    child: TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Nome'), // TODO l10n
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Richiesto' : null, // TODO l10n
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 320 : double.infinity,
                    child: TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'), // TODO l10n
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return null;
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(t)) return 'Email non valida'; // TODO l10n
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 220 : double.infinity,
                    child: TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(labelText: 'Telefono'), // TODO l10n
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return null;
                        final phoneRegex = RegExp(r'^[0-9+()\-\s]{6,}$');
                        if (!phoneRegex.hasMatch(t)) return 'Telefono non valido'; // TODO l10n
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 480 : double.infinity,
                    child: TextFormField(
                      controller: _notes,
                      decoration: const InputDecoration(labelText: 'Note'), // TODO l10n
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          );
