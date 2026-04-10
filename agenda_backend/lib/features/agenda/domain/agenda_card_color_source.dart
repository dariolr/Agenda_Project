enum AgendaCardColorSource { services, team, clients }

extension AgendaCardColorSourceX on AgendaCardColorSource {
  String get storageValue => name;
}

AgendaCardColorSource? agendaCardColorSourceFromStorage(Object? value) {
  if (value == null) return null;

  if (value is String) {
    for (final source in AgendaCardColorSource.values) {
      if (source.name == value) return source;
    }
    return null;
  }

  // Legacy migration from old bool preference:
  // true => services, false => team.
  if (value is bool) {
    return value ? AgendaCardColorSource.services : AgendaCardColorSource.team;
  }

  return null;
}
