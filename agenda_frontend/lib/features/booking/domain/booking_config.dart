/// Configurazione per il flow di prenotazione
class BookingConfig {
  /// Consente all'utente di scegliere l'operatore
  final bool allowStaffSelection;

  /// Consente di selezionare staff diversi per servizi diversi nella stessa prenotazione.
  /// TEMPORANEAMENTE DISABILITATO: richiede implementazione API multi-staff.
  /// Per riabilitare, impostare a true qui e nel placeholderBookingConfig.
  final bool allowMultiStaffBooking;

  /// ID del business
  final int businessId;

  /// ID della location (sede)
  final int locationId;

  /// True se il business esiste ma non ha location configurata
  final bool businessExistsButNotActive;

  const BookingConfig({
    this.allowStaffSelection = true,
    this.allowMultiStaffBooking =
        false, // riabilitare quando API multi-staff pronta
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
  allowMultiStaffBooking: false, //  riabilitare quando API multi-staff pronta
  businessId: 0,
  locationId: 0,
);
