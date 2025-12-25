import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/time_slot.dart';

/// Repository per le prenotazioni (Mock API)
class BookingRepository {
  /// Recupera le categorie di servizi ordinate
  Future<List<ServiceCategory>> getCategories(int businessId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      const ServiceCategory(id: 1, businessId: 1, name: 'Taglio', sortOrder: 1),
      const ServiceCategory(id: 2, businessId: 1, name: 'Colore', sortOrder: 2),
      const ServiceCategory(id: 3, businessId: 1, name: 'Trattamenti', sortOrder: 3),
      const ServiceCategory(id: 4, businessId: 1, name: 'Styling', sortOrder: 4),
    ];
  }

  /// Recupera i servizi prenotabili online ordinati
  Future<List<Service>> getServices(int businessId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      // Categoria Taglio
      const Service(
        id: 1, businessId: 1, categoryId: 1,
        name: 'Taglio Uomo', durationMinutes: 30, price: 20.0, sortOrder: 1,
      ),
      const Service(
        id: 2, businessId: 1, categoryId: 1,
        name: 'Taglio Donna', durationMinutes: 45, price: 35.0, sortOrder: 2,
      ),
      const Service(
        id: 3, businessId: 1, categoryId: 1,
        name: 'Taglio Bambino', durationMinutes: 20, price: 15.0, sortOrder: 3,
      ),
      // Categoria Colore
      const Service(
        id: 4, businessId: 1, categoryId: 2,
        name: 'Colore Base', durationMinutes: 60, price: 45.0, sortOrder: 1,
      ),
      const Service(
        id: 5, businessId: 1, categoryId: 2,
        name: 'Meches', durationMinutes: 90, price: 65.0, sortOrder: 2,
      ),
      const Service(
        id: 6, businessId: 1, categoryId: 2,
        name: 'Balayage', durationMinutes: 120, price: 85.0, isPriceStartingFrom: true, sortOrder: 3,
      ),
      // Categoria Trattamenti
      const Service(
        id: 7, businessId: 1, categoryId: 3,
        name: 'Trattamento Ristrutturante', durationMinutes: 30, price: 25.0, sortOrder: 1,
      ),
      const Service(
        id: 8, businessId: 1, categoryId: 3,
        name: 'Maschera Nutriente', durationMinutes: 20, price: 15.0, sortOrder: 2,
      ),
      // Categoria Styling
      const Service(
        id: 9, businessId: 1, categoryId: 4,
        name: 'Piega', durationMinutes: 30, price: 20.0, sortOrder: 1,
      ),
      const Service(
        id: 10, businessId: 1, categoryId: 4,
        name: 'Acconciatura Sposa', durationMinutes: 90, price: 120.0, isPriceStartingFrom: true, sortOrder: 2,
      ),
    ];
  }

  /// Recupera gli staff prenotabili online
  Future<List<Staff>> getStaff(int businessId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return const [
      Staff(id: 1, businessId: 1, name: 'Marco', surname: 'Rossi', sortOrder: 1),
      Staff(id: 2, businessId: 1, name: 'Laura', surname: 'Bianchi', sortOrder: 2),
      Staff(id: 3, businessId: 1, name: 'Giuseppe', surname: 'Verdi', sortOrder: 3),
    ];
  }

  /// Recupera gli slot disponibili per una data e durata
  Future<List<TimeSlot>> getAvailableSlots({
    required int businessId,
    required int locationId,
    required DateTime date,
    required int totalDurationMinutes,
    int? staffId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final slots = <TimeSlot>[];
    final baseDate = DateTime(date.year, date.month, date.day);
    
    // Simula slot mattina (9:00 - 13:00)
    for (var hour = 9; hour < 13; hour++) {
      for (var minute = 0; minute < 60; minute += 30) {
        final start = baseDate.add(Duration(hours: hour, minutes: minute));
        final end = start.add(Duration(minutes: totalDurationMinutes));
        
        // Salta alcuni slot per simulare indisponibilità
        if (hour == 10 && minute == 30) continue;
        if (hour == 11 && minute == 0) continue;
        
        slots.add(TimeSlot(
          startTime: start,
          endTime: end,
          staffId: staffId,
        ));
      }
    }
    
    // Simula slot pomeriggio (14:00 - 19:00)
    for (var hour = 14; hour < 19; hour++) {
      for (var minute = 0; minute < 60; minute += 30) {
        final start = baseDate.add(Duration(hours: hour, minutes: minute));
        final end = start.add(Duration(minutes: totalDurationMinutes));
        
        // Salta alcuni slot per simulare indisponibilità
        if (hour == 15 && minute == 0) continue;
        if (hour == 16 && minute == 30) continue;
        
        slots.add(TimeSlot(
          startTime: start,
          endTime: end,
          staffId: staffId,
        ));
      }
    }
    
    return slots;
  }

  /// Trova la prima data disponibile
  Future<DateTime> getFirstAvailableDate({
    required int businessId,
    required int locationId,
    required int totalDurationMinutes,
    int? staffId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Simula: prima disponibilità domani
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// Conferma la prenotazione
  Future<String> confirmBooking({
    required int businessId,
    required int locationId,
    required List<int> serviceIds,
    required DateTime startTime,
    int? staffId,
    String? notes,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Genera un ID prenotazione mock
    final bookingId = 'BK${DateTime.now().millisecondsSinceEpoch}';
    return bookingId;
  }
}
