/// Utility per la manipolazione delle stringhe
class StringUtils {
  const StringUtils._();

  /// Capitalizza la prima lettera di ogni parola (Title Case)
  /// Es: "mario rossi" → "Mario Rossi"
  /// Es: "GIOVANNI BIANCHI" → "Giovanni Bianchi"
  static String toTitleCase(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    final parts = trimmed.split(' ');
    return parts
        .map(
          (w) => w.isEmpty
              ? ''
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  /// Capitalizza solo la prima lettera della stringa
  /// Es: "mario rossi" → "Mario rossi"
  static String capitalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }

  /// Capitalizza la prima lettera, mantenendo il resto invariato
  /// Es: "mario ROSSI" → "Mario ROSSI"
  static String capitalizeFirst(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}
