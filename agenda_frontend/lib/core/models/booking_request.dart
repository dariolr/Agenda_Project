import 'service.dart';
import 'staff.dart';
import 'time_slot.dart';

/// Modello per la richiesta di prenotazione
class BookingRequest {
  final List<Service> services;
  final Staff? selectedStaff;
  final TimeSlot? selectedSlot;
  final String? notes;

  const BookingRequest({
    this.services = const [],
    this.selectedStaff,
    this.selectedSlot,
    this.notes,
  });

  /// Durata totale in minuti
  int get totalDurationMinutes =>
      services.fold(0, (sum, s) => sum + s.durationMinutes);

  /// Prezzo totale
  double get totalPrice =>
      services.fold(0.0, (sum, s) => sum + (s.isFree ? 0 : s.price));

  /// Formatta il prezzo totale
  String get formattedTotalPrice {
    if (totalPrice == 0) return 'Gratis';
    return '€${totalPrice.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Verifica se la prenotazione è completa
  bool get isComplete =>
      services.isNotEmpty && selectedSlot != null;

  BookingRequest copyWith({
    List<Service>? services,
    Staff? selectedStaff,
    TimeSlot? selectedSlot,
    String? notes,
    bool clearStaff = false,
    bool clearSlot = false,
  }) =>
      BookingRequest(
        services: services ?? this.services,
        selectedStaff: clearStaff ? null : (selectedStaff ?? this.selectedStaff),
        selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'service_ids': services.map((s) => s.id).toList(),
        if (selectedStaff != null) 'staff_id': selectedStaff!.id,
        if (selectedSlot != null) 'start_time': selectedSlot!.startTime.toIso8601String(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
