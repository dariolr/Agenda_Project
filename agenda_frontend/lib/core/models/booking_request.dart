import 'service.dart';
import 'staff.dart';
import 'time_slot.dart';

/// Modello per la richiesta di prenotazione
class BookingRequest {
  final List<Service> services;
  final Staff? selectedStaff;
  final Map<int, Staff?> selectedStaffByService;
  final bool anyOperatorSelected;
  final TimeSlot? selectedSlot;
  final String? notes;

  const BookingRequest({
    this.services = const [],
    this.selectedStaff,
    this.selectedStaffByService = const {},
    this.anyOperatorSelected = false,
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
  bool get isComplete => services.isNotEmpty && selectedSlot != null;

  bool get hasStaffSelectionForAllServices {
    if (services.isEmpty) return false;
    if (anyOperatorSelected) return true;
    if (services.length > 1) {
      return services.every((s) => selectedStaffByService[s.id] != null);
    }
    if (selectedStaffByService.isNotEmpty) {
      return services.every((s) => selectedStaffByService[s.id] != null);
    }
    return selectedStaff != null;
  }

  bool get hasOnlyStaffSelectionForAllServices {
    if (services.isEmpty) return false;
    if (anyOperatorSelected) return false;
    if (services.length > 1) {
      return services.every((s) => selectedStaffByService[s.id] != null);
    }
    if (selectedStaffByService.isNotEmpty) {
      return services.every((s) => selectedStaffByService[s.id] != null);
    }
    return selectedStaff != null;
  }

  bool get allServicesAnyOperatorSelected {
    if (services.isEmpty) return false;
    if (services.length > 1) {
      return anyOperatorSelected;
    }
    if (selectedStaffByService.isNotEmpty) {
      return anyOperatorSelected;
    }
    return anyOperatorSelected || selectedStaff == null;
  }

  int? get singleStaffId {
    if (selectedStaffByService.isNotEmpty) {
      if (anyOperatorSelected) {
        return null;
      }
      final staffIds = selectedStaffByService.values
          .whereType<Staff>()
          .map((s) => s.id)
          .toSet();
      if (staffIds.length == 1 &&
          services.every((s) => selectedStaffByService[s.id] != null)) {
        return staffIds.first;
      }
      return null;
    }
    return selectedStaff?.id;
  }

  Staff? staffForService(int serviceId) {
    if (anyOperatorSelected) {
      return null;
    }
    if (selectedStaffByService.isNotEmpty) {
      return selectedStaffByService[serviceId];
    }
    return selectedStaff;
  }

  bool isAnyOperatorForService(int serviceId) => anyOperatorSelected;

  BookingRequest copyWith({
    List<Service>? services,
    Staff? selectedStaff,
    Map<int, Staff?>? selectedStaffByService,
    bool? anyOperatorSelected,
    TimeSlot? selectedSlot,
    String? notes,
    bool clearStaff = false,
    bool clearStaffSelections = false,
    bool clearAnyOperatorSelections = false,
    bool clearSlot = false,
    bool clearNotes = false,
  }) => BookingRequest(
    services: services ?? this.services,
    selectedStaff: clearStaff ? null : (selectedStaff ?? this.selectedStaff),
    selectedStaffByService: clearStaffSelections
        ? {}
        : (selectedStaffByService ?? this.selectedStaffByService),
    anyOperatorSelected: clearAnyOperatorSelections
        ? false
        : (anyOperatorSelected ?? this.anyOperatorSelected),
    selectedSlot: clearSlot ? null : (selectedSlot ?? this.selectedSlot),
    notes: clearNotes ? null : (notes ?? this.notes),
  );

  Map<String, dynamic> toJson() => {
    'service_ids': services.map((s) => s.id).toList(),
    if (selectedStaff != null) 'staff_id': selectedStaff!.id,
    if (selectedSlot != null)
      'start_time': selectedSlot!.startTime.toIso8601String(),
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}
