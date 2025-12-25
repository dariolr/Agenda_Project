import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/booking_request.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/time_slot.dart';
import '../data/booking_repository.dart';
import '../domain/booking_config.dart';

/// Provider per il repository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

/// Provider per la configurazione del booking
final bookingConfigProvider = Provider<BookingConfig>((ref) {
  return defaultBookingConfig;
});

/// Step del flow di prenotazione
enum BookingStep { services, staff, dateTime, summary, confirmation }

/// Stato del flow di prenotazione
class BookingFlowState {
  final BookingStep currentStep;
  final BookingRequest request;
  final bool isLoading;
  final String? errorMessage;
  final String? confirmedBookingId;

  const BookingFlowState({
    this.currentStep = BookingStep.services,
    this.request = const BookingRequest(),
    this.isLoading = false,
    this.errorMessage,
    this.confirmedBookingId,
  });

  bool get canGoBack =>
      currentStep.index > 0 && currentStep != BookingStep.confirmation;

  bool get canGoNext {
    switch (currentStep) {
      case BookingStep.services:
        return request.services.isNotEmpty;
      case BookingStep.staff:
        return true; // Staff opzionale
      case BookingStep.dateTime:
        return request.selectedSlot != null;
      case BookingStep.summary:
        return request.isComplete;
      case BookingStep.confirmation:
        return false;
    }
  }

  BookingFlowState copyWith({
    BookingStep? currentStep,
    BookingRequest? request,
    bool? isLoading,
    String? errorMessage,
    String? confirmedBookingId,
    bool clearError = false,
  }) => BookingFlowState(
    currentStep: currentStep ?? this.currentStep,
    request: request ?? this.request,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    confirmedBookingId: confirmedBookingId ?? this.confirmedBookingId,
  );
}

/// Provider principale per il flow di prenotazione
final bookingFlowProvider =
    NotifierProvider<BookingFlowNotifier, BookingFlowState>(
      BookingFlowNotifier.new,
    );

class BookingFlowNotifier extends Notifier<BookingFlowState> {
  @override
  BookingFlowState build() => const BookingFlowState();

  BookingRepository get _repository => ref.read(bookingRepositoryProvider);
  BookingConfig get _config => ref.read(bookingConfigProvider);

  /// Reset del flow
  void reset() {
    state = const BookingFlowState();
  }

  /// Vai allo step successivo
  void nextStep() {
    if (!state.canGoNext) return;

    final nextIndex = state.currentStep.index + 1;
    if (nextIndex < BookingStep.values.length) {
      // Se staff selection è disabilitata, salta lo step staff
      var nextStep = BookingStep.values[nextIndex];
      if (nextStep == BookingStep.staff && !_config.allowStaffSelection) {
        nextStep = BookingStep.dateTime;
      }
      state = state.copyWith(currentStep: nextStep);
    }
  }

  /// Vai allo step precedente
  void previousStep() {
    if (!state.canGoBack) return;

    var prevIndex = state.currentStep.index - 1;
    var prevStep = BookingStep.values[prevIndex];

    // Se staff selection è disabilitata, salta lo step staff
    if (prevStep == BookingStep.staff && !_config.allowStaffSelection) {
      prevIndex--;
      prevStep = BookingStep.values[prevIndex];
    }

    state = state.copyWith(currentStep: prevStep);
  }

  /// Vai a uno step specifico
  void goToStep(BookingStep step) {
    if (step.index < state.currentStep.index) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Toggle selezione servizio
  void toggleService(Service service) {
    final currentServices = List<Service>.from(state.request.services);

    if (currentServices.any((s) => s.id == service.id)) {
      currentServices.removeWhere((s) => s.id == service.id);
    } else {
      currentServices.add(service);
    }

    // Quando cambiano i servizi, resetta slot selezionato
    state = state.copyWith(
      request: state.request.copyWith(
        services: currentServices,
        clearSlot: true,
      ),
    );
  }

  /// Seleziona staff
  void selectStaff(Staff? staff) {
    state = state.copyWith(
      request: state.request.copyWith(
        selectedStaff: staff,
        clearStaff: staff == null,
        clearSlot: true, // Resetta slot quando cambia staff
      ),
    );
  }

  /// Seleziona slot temporale
  void selectTimeSlot(TimeSlot slot) {
    state = state.copyWith(request: state.request.copyWith(selectedSlot: slot));
  }

  /// Aggiorna note
  void updateNotes(String notes) {
    state = state.copyWith(request: state.request.copyWith(notes: notes));
  }

  /// Conferma prenotazione
  Future<bool> confirmBooking() async {
    if (!state.request.isComplete) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final bookingId = await _repository.confirmBooking(
        businessId: _config.businessId,
        locationId: _config.locationId,
        serviceIds: state.request.services.map((s) => s.id).toList(),
        startTime: state.request.selectedSlot!.startTime,
        staffId: state.request.selectedStaff?.id,
        notes: state.request.notes,
      );

      state = state.copyWith(
        isLoading: false,
        currentStep: BookingStep.confirmation,
        confirmedBookingId: bookingId,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

/// Provider per le categorie
final categoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final repository = ref.read(bookingRepositoryProvider);
  final config = ref.read(bookingConfigProvider);
  final categories = await repository.getCategories(config.businessId);
  // Ordina per sortOrder (crea una nuova lista per evitare modificare const)
  final sortedCategories = List<ServiceCategory>.from(categories);
  sortedCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return sortedCategories;
});

/// Provider per i servizi
final servicesProvider = FutureProvider<List<Service>>((ref) async {
  final repository = ref.read(bookingRepositoryProvider);
  final config = ref.read(bookingConfigProvider);
  final services = await repository.getServices(config.businessId);
  // Ordina per sortOrder (crea una nuova lista per evitare modificare const)
  final sortedServices = List<Service>.from(services);
  sortedServices.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return sortedServices;
});

/// Provider per lo staff
final staffProvider = FutureProvider<List<Staff>>((ref) async {
  final repository = ref.read(bookingRepositoryProvider);
  final config = ref.read(bookingConfigProvider);
  final staff = await repository.getStaff(config.businessId);
  // Ordina per sortOrder (crea una nuova lista per evitare modificare const)
  final sortedStaff = List<Staff>.from(staff);
  sortedStaff.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return sortedStaff;
});

/// Provider per la data selezionata nel calendario
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

/// Provider per gli slot disponibili
final availableSlotsProvider = FutureProvider<List<TimeSlot>>((ref) async {
  final repository = ref.read(bookingRepositoryProvider);
  final config = ref.read(bookingConfigProvider);
  final bookingState = ref.watch(bookingFlowProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  if (selectedDate == null || bookingState.request.services.isEmpty) {
    return [];
  }

  return repository.getAvailableSlots(
    businessId: config.businessId,
    locationId: config.locationId,
    date: selectedDate,
    totalDurationMinutes: bookingState.request.totalDurationMinutes,
    staffId: bookingState.request.selectedStaff?.id,
  );
});

/// Provider per la prima data disponibile
final firstAvailableDateProvider = FutureProvider<DateTime>((ref) async {
  final repository = ref.read(bookingRepositoryProvider);
  final config = ref.read(bookingConfigProvider);
  final bookingState = ref.watch(bookingFlowProvider);

  return repository.getFirstAvailableDate(
    businessId: config.businessId,
    locationId: config.locationId,
    totalDurationMinutes: bookingState.request.totalDurationMinutes,
    staffId: bookingState.request.selectedStaff?.id,
  );
});
