import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10_extension.dart';

/// Lista dei prefissi telefonici più comuni
const kPhonePrefixes = <PhonePrefix>[
  PhonePrefix('+39', 'IT', '🇮🇹'),
  PhonePrefix('+1', 'US', '🇺🇸'),
  PhonePrefix('+44', 'GB', '🇬🇧'),
  PhonePrefix('+49', 'DE', '🇩🇪'),
  PhonePrefix('+33', 'FR', '🇫🇷'),
  PhonePrefix('+34', 'ES', '🇪🇸'),
  PhonePrefix('+41', 'CH', '🇨🇭'),
  PhonePrefix('+43', 'AT', '🇦🇹'),
  PhonePrefix('+31', 'NL', '🇳🇱'),
  PhonePrefix('+32', 'BE', '🇧🇪'),
  PhonePrefix('+351', 'PT', '🇵🇹'),
  PhonePrefix('+48', 'PL', '🇵🇱'),
  PhonePrefix('+420', 'CZ', '🇨🇿'),
  PhonePrefix('+385', 'HR', '🇭🇷'),
  PhonePrefix('+386', 'SI', '🇸🇮'),
  PhonePrefix('+40', 'RO', '🇷🇴'),
  PhonePrefix('+30', 'GR', '🇬🇷'),
  PhonePrefix('+7', 'RU', '🇷🇺'),
  PhonePrefix('+86', 'CN', '🇨🇳'),
  PhonePrefix('+81', 'JP', '🇯🇵'),
  PhonePrefix('+82', 'KR', '🇰🇷'),
  PhonePrefix('+91', 'IN', '🇮🇳'),
  PhonePrefix('+61', 'AU', '🇦🇺'),
  PhonePrefix('+55', 'BR', '🇧🇷'),
  PhonePrefix('+52', 'MX', '🇲🇽'),
  PhonePrefix('+54', 'AR', '🇦🇷'),
];

/// Modello per un prefisso telefonico
class PhonePrefix {
  final String code;
  final String countryCode;
  final String flag;

  const PhonePrefix(this.code, this.countryCode, this.flag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhonePrefix &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// Estrae prefisso e numero da un telefono completo
/// Ritorna (prefix, number)
(String prefix, String number) parsePhoneWithPrefix(
  String? phone, {
  String defaultPrefix = '+39',
}) {
  if (phone == null || phone.isEmpty) {
    return (defaultPrefix, '');
  }

  final cleaned = phone.replaceAll(RegExp(r'\s+'), '');

  // Cerca un prefisso conosciuto
  for (final p in kPhonePrefixes) {
    if (cleaned.startsWith(p.code)) {
      return (p.code, cleaned.substring(p.code.length));
    }
  }

  // Prova a estrarre un prefisso generico +XX o +XXX
  if (cleaned.startsWith('+')) {
    final match = RegExp(r'^\+\d{1,3}').firstMatch(cleaned);
    if (match != null) {
      return (match.group(0)!, cleaned.substring(match.end));
    }
  }

  // Nessun prefisso trovato, usa il default
  return (defaultPrefix, phone);
}

/// Combina prefisso e numero in un formato standard
String formatPhoneWithPrefix(String prefix, String number) {
  final cleanNumber = number.replaceAll(RegExp(r'\s+'), '');
  if (cleanNumber.isEmpty) return '';
  return '$prefix $cleanNumber';
}

/// Widget per input telefono con prefisso selezionabile
class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    this.labelText,
    required this.defaultPrefix,
    this.initialPhone,
    this.onChanged,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.isDense = false,
    this.useOutlineBorder = false,
  });

  /// Label opzionale. Se null, il campo non mostra label interna.
  final String? labelText;
  final String defaultPrefix;
  final String? initialPhone;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;

  /// Se true, usa InputDecoration.isDense = true.
  final bool isDense;

  /// Se true, usa OutlineInputBorder invece del default UnderlineInputBorder.
  final bool useOutlineBorder;

  @override
  State<PhoneInputField> createState() => PhoneInputFieldState();
}

class PhoneInputFieldState extends State<PhoneInputField>
    with WidgetsBindingObserver {
  late String _selectedPrefix;
  late final TextEditingController _controller;

  // Backup usato per ripristinare il testo su piattaforme (es. Chrome/Windows)
  // dove il browser può azzerare il campo attivo durante le transizioni
  // di lifecycle (alt-tab, cambio applicazione).
  String _backupText = '';
  bool _isBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final (prefix, number) = parsePhoneWithPrefix(
      widget.initialPhone,
      defaultPrefix: widget.defaultPrefix,
    );
    _selectedPrefix = prefix;
    _controller = TextEditingController(text: number);
    _backupText = number;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _isBackground = true;
      _backupText = _controller.text;
    } else if (state == AppLifecycleState.resumed) {
      final backup = _backupText;
      _isBackground = false;
      // Su alcuni browser (Chrome/Windows) il cambio finestra può azzerare
      // il controller del campo con focus. Il postFrameCallback garantisce
      // che eventuali eventi DOM arrivati durante il resume siano già stati
      // processati prima del ripristino.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_controller.text != backup) {
          _controller.value = TextEditingValue(
            text: backup,
            selection: TextSelection.collapsed(offset: backup.length),
          );
        }
      });
    }
  }

  /// Ritorna il numero di telefono completo (prefisso + numero).
  /// Il prefisso e il numero sono input separati: il numero viene usato così
  /// com'è, senza rimuovere cifre iniziali che coincidono col prefisso, perché
  /// esistono numeri reali che iniziano con quelle cifre (es. prefisso +39 e
  /// numero 339… del mobile TIM).
  String get fullPhone {
    final number = _controller.text.replaceAll(RegExp(r'\s+'), '');
    if (number.isEmpty) return '';
    return '$_selectedPrefix $number';
  }

  /// Ritorna solo il numero senza prefisso
  String get numberOnly => _controller.text.replaceAll(RegExp(r'\s+'), '');

  /// Ritorna il prefisso selezionato
  String get prefix => _selectedPrefix;

  void _notifyChange() {
    widget.onChanged?.call(fullPhone);
  }

  void _onTextChanged(String value) {
    if (!_isBackground) {
      _backupText = value;
    }
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        isDense: widget.isDense,
        border: widget.useOutlineBorder ? const OutlineInputBorder() : null,
        prefixIcon: _PrefixDropdown(
          selectedPrefix: _selectedPrefix,
          onChanged: (newPrefix) {
            setState(() => _selectedPrefix = newPrefix);
            _notifyChange();
          },
        ),
      ),
      keyboardType: TextInputType.phone,
      textInputAction: widget.textInputAction,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      onChanged: _onTextChanged,
      validator:
          widget.validator ??
          (v) {
            final t = v?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
            if (t.isEmpty) return null; // optional
            if (!RegExp(r'^\d{6,15}$').hasMatch(t)) {
              return context.l10n.validationInvalidPhone;
            }
            return null;
          },
    );
  }
}

/// Dropdown per selezionare il prefisso
class _PrefixDropdown extends StatelessWidget {
  const _PrefixDropdown({
    required this.selectedPrefix,
    required this.onChanged,
  });

  final String selectedPrefix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // Trova il prefisso corrente nella lista, altrimenti usa il primo
    final currentPrefix = kPhonePrefixes.firstWhere(
      (p) => p.code == selectedPrefix,
      orElse: () => kPhonePrefixes.first,
    );

    return ExcludeFocus(
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentPrefix.code,
            isDense: true,
            items: kPhonePrefixes.map((p) {
              return DropdownMenuItem<String>(
                value: p.code,
                child: Text(
                  '${p.flag} ${p.code}',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
            selectedItemBuilder: (context) {
              return kPhonePrefixes.map((p) {
                return Center(
                  child: Text(
                    '${p.flag} ${p.code}',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
