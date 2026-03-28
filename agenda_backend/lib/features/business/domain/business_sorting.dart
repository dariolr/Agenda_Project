import '../../../core/models/business.dart';

const _priorityBusinessSlug = 'romeolab';

/// Ordina i business per le UI di selezione:
/// 1) slug "romeolab" sempre in cima
/// 2) poi nome alfabetico (case-insensitive)
/// 3) infine id per stabilità
List<Business> sortBusinessesForSelection(Iterable<Business> businesses) {
  final sorted = businesses.toList(growable: false);
  sorted.sort((a, b) {
    final aPriority = _normalizedSlug(a) == _priorityBusinessSlug ? 0 : 1;
    final bPriority = _normalizedSlug(b) == _priorityBusinessSlug ? 0 : 1;
    if (aPriority != bPriority) return aPriority.compareTo(bPriority);

    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (byName != 0) return byName;

    return a.id.compareTo(b.id);
  });
  return sorted;
}

String _normalizedSlug(Business business) =>
    (business.slug ?? '').trim().toLowerCase();
