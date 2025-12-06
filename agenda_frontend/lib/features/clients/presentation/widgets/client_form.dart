import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/widgets/labeled_form_field.dart';
import '../../../../core/widgets/phone_input_field.dart';
import '../../../agenda/providers/business_providers.dart';
import '../../domain/clients.dart';

class ClientForm extends ConsumerStatefulWidget {
  const ClientForm({super.key, this.initial, this.onChanged});

  final Client? initial;
  final VoidCallback? onChanged;

  @override
  ConsumerState<ClientForm> createState() => ClientFormState();
}

class ClientFormState extends ConsumerState<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneFieldKey = GlobalKey<PhoneInputFieldState>();

  late final TextEditingController _firstName = TextEditingController(
    text: widget.initial?.firstName ?? '',
  );
  late final TextEditingController _lastName = TextEditingController(
    text: widget.initial?.lastName ?? '',
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.initial?.email ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.initial?.notes ?? '',
  );

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  Client buildClient() {
    final base = widget.initial;
    final now = DateTime.now();
    final phoneState = _phoneFieldKey.currentState;
    final fullPhone = phoneState?.fullPhone;

    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();

    return Client(
      id: base?.id ?? -1,
      businessId: base?.businessId ?? ref.read(currentBusinessProvider).id,
      firstName: firstName.isEmpty ? null : StringUtils.toTitleCase(firstName),
      lastName: lastName.isEmpty ? null : StringUtils.toTitleCase(lastName),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      phone: (fullPhone == null || fullPhone.isEmpty) ? null : fullPhone,
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
    final business = ref.watch(currentBusinessProvider);
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Riga 1: Nome + Cognome
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledFormField(
                  label: l10n.formFirstName,
                  child: TextFormField(
                    controller: _firstName,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) {
                      _formKey.currentState?.validate();
                      widget.onChanged?.call();
                    },
                    validator: (v) {
                      final firstName = v?.trim() ?? '';
                      final lastName = _lastName.text.trim();
                      if (firstName.isEmpty && lastName.isEmpty) {
                        return l10n.validationNameOrLastNameRequired;
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.formFieldSpacing),
              Expanded(
                child: LabeledFormField(
                  label: l10n.formLastName,
                  child: TextFormField(
                    controller: _lastName,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) {
                      _formKey.currentState?.validate();
                      widget.onChanged?.call();
                    },
                    validator: (v) {
                      final lastName = v?.trim() ?? '';
                      final firstName = _firstName.text.trim();
                      if (firstName.isEmpty && lastName.isEmpty) {
                        return l10n.validationNameOrLastNameRequired;
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),

          // Riga 2: Email + Telefono
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledFormField(
                  label: l10n.formEmail,
                  child: TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => widget.onChanged?.call(),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(t)) {
                        return l10n.validationInvalidEmail;
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.formFieldSpacing),
              Expanded(
                child: LabeledFormField(
                  label: l10n.formPhone,
                  child: PhoneInputField(
                    key: _phoneFieldKey,
                    defaultPrefix: business.defaultPhonePrefix,
                    initialPhone: widget.initial?.phone,
                    isDense: true,
                    useOutlineBorder: true,
                    onChanged: (_) => widget.onChanged?.call(),
                    validator: (v) {
                      final t = v?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
                      if (t.isEmpty) return null;
                      if (!RegExp(r'^\d{6,15}$').hasMatch(t)) {
                        return l10n.validationInvalidPhone;
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.formRowSpacing),

          // Riga 3: Note (sempre full width)
          LabeledFormField(
            label: l10n.formNotes,
            child: TextFormField(
              controller: _notes,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              onChanged: (_) => widget.onChanged?.call(),
            ),
          ),
        ],
      ),
    );
  }
}
