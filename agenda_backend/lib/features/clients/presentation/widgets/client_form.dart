import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/utils/color_utils.dart';
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
  late bool _isBookableOnline = !(widget.initial?.blocked ?? false);
  String? _selectedColorHex;

  static const List<Color> _clientPalette = [
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5E35B1),
    Color(0xFF3949AB),
    Color(0xFF1E88E5),
    Color(0xFF039BE5),
    Color(0xFF00ACC1),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFFC0CA33),
    Color(0xFFFDD835),
    Color(0xFFFFB300),
    Color(0xFFFB8C00),
    Color(0xFFF4511E),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColorHex = widget.initial?.colorHex;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickClientColor() async {
    final initialColor = _selectedColorHex == null
        ? _clientPalette.first
        : ColorUtils.fromHex(_selectedColorHex!);
    var tempColor = initialColor;
    final selected = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) => tempColor = color,
              enableAlpha: false,
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.72,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(tempColor),
              child: Text(context.l10n.actionConfirm),
            ),
          ],
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedColorHex = ColorUtils.toHex(selected));
    widget.onChanged?.call();
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
      colorHex: _selectedColorHex,
      createdAt: base?.createdAt ?? now,
      lastVisit: base?.lastVisit,
      loyaltyPoints: base?.loyaltyPoints,
      tags: base?.tags,
      isArchived: base?.isArchived ?? false,
      blocked: !_isBookableOnline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider);
    final l10n = context.l10n;
    final formFactor = ref.watch(formFactorProvider);
    final isSingleColumn = formFactor != AppFormFactor.desktop;
    final isEditingClient = (widget.initial?.id ?? 0) > 0;

    final firstNameField = LabeledFormField(
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
    );

    final lastNameField = LabeledFormField(
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
    );

    final emailField = LabeledFormField(
      label: l10n.formEmail,
      child: TextFormField(
        controller: _email,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          setState(() {});
          widget.onChanged?.call();
        },
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
    );

    final phoneField = LabeledFormField(
      label: l10n.formPhone,
      child: PhoneInputField(
        key: _phoneFieldKey,
        defaultPrefix: business.defaultPhonePrefix,
        initialPhone: widget.initial?.phone,
        isDense: true,
        useOutlineBorder: true,
        onChanged: (_) {
          setState(() {});
          widget.onChanged?.call();
        },
        validator: (v) {
          final t = v?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
          if (t.isEmpty) return null;
          if (!RegExp(r'^\d{6,15}$').hasMatch(t)) {
            return l10n.validationInvalidPhone;
          }
          return null;
        },
      ),
    );

    final notesField = LabeledFormField(
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
    );

    final emailValue = _email.text.trim();
    final phoneValue =
        (_phoneFieldKey.currentState?.fullPhone ?? widget.initial?.phone ?? '')
            .trim();
    final canEmail = _isValidEmail(emailValue);
    final canCall = _isValidPhone(phoneValue);
    final canWhatsApp = canCall;
    final showContactActionsInEditForm =
        isEditingClient && (canEmail || canCall || canWhatsApp);

    final contactActionsField = LabeledFormField(
      label: l10n.formClient,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.formFieldSpacing,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: canCall ? () => _openPhone(phoneValue) : null,
              icon: const Icon(Icons.call_outlined, size: 18),
              label: Text(l10n.formPhone),
            ),
            OutlinedButton.icon(
              onPressed: canEmail ? () => _openEmail(emailValue) : null,
              icon: const Icon(Icons.email_outlined, size: 18),
              label: Text(l10n.formEmail),
            ),
            OutlinedButton.icon(
              onPressed: canWhatsApp ? () => _openWhatsAppChat(phoneValue) : null,
              icon: Builder(
                builder: (context) {
                  final iconColor = IconTheme.of(context).color;
                  return SvgPicture.asset(
                    'assets/icons/whatsapp.svg',
                    width: 18,
                    height: 18,
                    colorFilter: iconColor == null
                        ? null
                        : ColorFilter.mode(iconColor, BlendMode.srcIn),
                  );
                },
              ),
              label: Text(l10n.whatsappTabTitle),
            ),
          ],
        ),
      ),
    );

    final selectedColorHex = _selectedColorHex?.trim().toUpperCase();
    final paletteHexes = {
      for (final color in _clientPalette) ColorUtils.toHex(color).toUpperCase(),
    };
    final showCustomSelectedColor =
        selectedColorHex != null &&
        selectedColorHex.isNotEmpty &&
        !paletteHexes.contains(selectedColorHex);
    final selectedCustomColor = showCustomSelectedColor
        ? ColorUtils.fromHex(selectedColorHex)
        : null;

    final colorField = LabeledFormField(
      label: l10n.clientColorLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ColorChoiceDot(
                color: null,
                selected: _selectedColorHex == null,
                onTap: () {
                  setState(() => _selectedColorHex = null);
                  widget.onChanged?.call();
                },
              ),
              for (final color in _clientPalette)
                _ColorChoiceDot(
                  color: color,
                  selected: selectedColorHex == ColorUtils.toHex(color).toUpperCase(),
                  onTap: () {
                    setState(() => _selectedColorHex = ColorUtils.toHex(color));
                    widget.onChanged?.call();
                  },
                ),
              if (selectedCustomColor != null)
                _ColorChoiceDot(
                  color: selectedCustomColor,
                  selected: true,
                  onTap: () {},
                ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickClientColor,
            icon: const Icon(Icons.palette_outlined, size: 18),
            label: Text(l10n.actionEdit),
          ),
        ],
      ),
    );

    final onlineBookingField = SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(l10n.bookableOnlineSwitch),
      value: _isBookableOnline,
      onChanged: (value) {
        setState(() => _isBookableOnline = value);
        widget.onChanged?.call();
      },
    );

    return Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSingleColumn) ...[
            firstNameField,
            const SizedBox(height: AppSpacing.formRowSpacing),
            lastNameField,
            const SizedBox(height: AppSpacing.formRowSpacing),
            emailField,
            const SizedBox(height: AppSpacing.formRowSpacing),
            phoneField,
            if (showContactActionsInEditForm) ...[
              const SizedBox(height: AppSpacing.formRowSpacing),
              contactActionsField,
            ],
            const SizedBox(height: AppSpacing.formRowSpacing),
            onlineBookingField,
            const SizedBox(height: AppSpacing.formRowSpacing),
            colorField,
            const SizedBox(height: AppSpacing.formRowSpacing),
            notesField,
          ] else ...[
            // Riga 1: Nome + Cognome
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: firstNameField),
                const SizedBox(width: AppSpacing.formFieldSpacing),
                Expanded(child: lastNameField),
              ],
            ),
            const SizedBox(height: AppSpacing.formRowSpacing),

            // Riga 2: Email + Telefono
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: emailField),
                const SizedBox(width: AppSpacing.formFieldSpacing),
                Expanded(child: phoneField),
              ],
            ),
            if (showContactActionsInEditForm) ...[
              const SizedBox(height: AppSpacing.formRowSpacing),
              contactActionsField,
            ],
            const SizedBox(height: AppSpacing.formRowSpacing),

            // Riga 3: Prenotabile online (full width)
            onlineBookingField,
            const SizedBox(height: AppSpacing.formRowSpacing),

            // Riga 4: Colore cliente (full width)
            colorField,
            const SizedBox(height: AppSpacing.formRowSpacing),

            // Riga 5: Note (sempre full width)
            notesField,
          ],
        ],
      ),
    );
  }
}

bool _isValidEmail(String email) {
  if (email.isEmpty) return false;
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return emailRegex.hasMatch(email);
}

bool _isValidPhone(String phone) {
  if (phone.isEmpty) return false;
  final normalized = phone.replaceAll(RegExp(r'\s+'), '');
  final phoneRegex = RegExp(r'^\+?\d{6,15}$');
  return phoneRegex.hasMatch(normalized);
}

Future<void> _openEmail(String email) async {
  final uri = Uri(scheme: 'mailto', path: email.trim());
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _openPhone(String phone) async {
  final normalized = phone.trim().replaceAll(RegExp(r'\s+'), '');
  final uri = Uri(scheme: 'tel', path: normalized);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _openWhatsAppChat(String phone) async {
  final digitsOnly = phone.replaceAll(RegExp(r'\D+'), '');
  if (digitsOnly.isEmpty) return;
  final uri = Uri.parse('https://wa.me/$digitsOnly');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _ColorChoiceDot extends StatelessWidget {
  const _ColorChoiceDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline.withOpacity(0.4);
    final fill = color ?? Theme.of(context).colorScheme.surface;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: color == null
            ? Icon(
                Icons.remove,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )
            : null,
      ),
    );
  }
}
