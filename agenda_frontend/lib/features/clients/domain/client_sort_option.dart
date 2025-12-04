/// Criteri di ordinamento per la lista clienti
enum ClientSortOption {
  /// Ordina per nome (A-Z)
  nameAsc,

  /// Ordina per nome (Z-A)
  nameDesc,

  /// Ordina per cognome (A-Z)
  lastNameAsc,

  /// Ordina per cognome (Z-A)
  lastNameDesc,

  /// Ordina per ultima visita (più recenti prima)
  lastVisitDesc,

  /// Ordina per ultima visita (meno recenti prima)
  lastVisitAsc,

  /// Ordina per data creazione (nuovi prima)
  createdAtDesc,

  /// Ordina per data creazione (vecchi prima)
  createdAtAsc,
}
