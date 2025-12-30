/// Configurazione per il flow di prenotazione
class BookingConfig {
  /// Consente all'utente di scegliere l'operatore
  final bool allowStaffSelection;

  /// ID del business
  final int businessId;

  /// ID della location (sede)
  final int locationId;

  /// True se il business esiste ma non ha location configurata
  final bool businessExistsButNotActive;

  const BookingConfig({
    this.allowStaffSelection = true,
    required this.businessId,
    required this.locationId,
    this.businessExistsButNotActive = false,
  });

  /// Crea una config valida solo se businessId e locationId sono noti
  bool get isValid => businessId > 0 && locationId > 0;
}

/// Config placeholder usata quando il business non è ancora caricato.
/// NON usare direttamente - serve solo come fallback temporaneo.
const placeholderBookingConfig = BookingConfig(
  allowStaffSelection: true,
  businessId: 0,
  locationId: 0,
);
