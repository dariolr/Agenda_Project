import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    required this.labelText,
    required this.defaultPrefix,
    this.initialPhone,
    this.onChanged,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });

  final String labelText;
  final String defaultPrefix;
  final String? initialPhone;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;

  @override
  State<PhoneInputField> createState() => PhoneInputFieldState();
}

class PhoneInputFieldState extends State<PhoneInputField> {
  late String _selectedPrefix;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final (prefix, number) = parsePhoneWithPrefix(
      widget.initialPhone,
      defaultPrefix: widget.defaultPrefix,
    );
    _selectedPrefix = prefix;
    _controller = TextEditingController(text: _formatNumber(number));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Ritorna il numero di telefono completo (prefisso + numero)
  String get fullPhone {
    final number = _controller.text.replaceAll(RegExp(r'\s+'), '');
    if (number.isEmpty) return '';
    return '$_selectedPrefix $number';
  }

  /// Ritorna solo il numero senza prefisso
  String get numberOnly => _controller.text.replaceAll(RegExp(r'\s+'), '');

  /// Ritorna il prefisso selezionato
  String get prefix => _selectedPrefix;

  String _formatNumber(String number) {
    final digits = number.replaceAll(RegExp(r'\s+'), '');
    if (digits.isEmpty) return '';

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  void _notifyChange() {
    widget.onChanged?.call(fullPhone);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
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
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
        _PhoneNumberFormatter(),
      ],
      onChanged: (_) => _notifyChange(),
      validator:
          widget.validator ??
          (v) {
            final t = v?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
            if (t.isEmpty) return null; // optional
            if (!RegExp(r'^\d{6,15}$').hasMatch(t)) {
              return 'Numero non valido';
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

    return Padding(
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
    );
  }
}

/// Formatta il numero di telefono aggiungendo spazi per leggibilità
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\s+'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
