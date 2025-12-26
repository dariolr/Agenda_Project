/// Configurazione per il flow di prenotazione
class BookingConfig {
  /// Consente all'utente di scegliere l'operatore
  final bool allowStaffSelection;
  
  /// ID del business
  final int businessId;
  
  /// ID della location (sede)
  final int locationId;

  const BookingConfig({
    this.allowStaffSelection = true,
    required this.businessId,
    required this.locationId,
  });
}

/// Provider per la configurazione (può essere configurato dall'esterno)
const defaultBookingConfig = BookingConfig(
  allowStaffSelection: true,
  businessId: 1,
  locationId: 1,
);
