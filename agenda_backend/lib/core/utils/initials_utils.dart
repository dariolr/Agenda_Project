import 'package:characters/characters.dart';

/// Utility per generare iniziali in modo Unicode-safe (emoji incluse).
class InitialsUtils {
  const InitialsUtils._();

  static String fromName(String name, {int maxChars = 3}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || maxChars <= 0) return '';

    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = <String>[];

    final partList = parts.toList();
    if (partList.isNotEmpty) {
      initials.add(_firstGrapheme(partList.first));
    }

    for (int i = 1; i < partList.length && initials.length < maxChars; i++) {
      initials.add(_firstGrapheme(partList[i]));
    }

    if (partList.length == 1 && initials.length < maxChars) {
      final graphemes = trimmed.characters;
      if (graphemes.length > 1) {
        initials.add(graphemes.skip(1).first);
      }
    }

    return initials
        .map((g) => g.toUpperCase())
        .take(maxChars)
        .toList()
        .join();
  }

  static int length(String value) => value.characters.length;

  static String _firstGrapheme(String value) => value.characters.first;
}
