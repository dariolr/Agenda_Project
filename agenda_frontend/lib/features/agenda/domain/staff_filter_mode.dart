/// Modalità di filtro per lo staff nell'agenda.
enum StaffFilterMode {
  /// Mostra tutto il team (tutti gli staff della location).
  allTeam,

  /// Mostra solo il team di turno (staff con disponibilità nel giorno selezionato).
  onDutyTeam,

  /// Selezione manuale di uno o più membri dello staff.
  custom,
}
