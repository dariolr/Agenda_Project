import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/booking_request.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/time_slot.dart';
import '../../../core/network/network_providers.dart';
import '../data/booking_repository.dart';
import '../domain/booking_config.dart';
import 'business_provider.dart';
import 'locations_provider.dart';

/// Provider per il repository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingRepository(apiClient);
});

/// Provider per la configurazione del booking (dinamico basato sul business corrente)
final bookingConfigProvider = Provider<BookingConfig>((ref) {
  final businessAsync = ref.watch(currentBusinessProvider);

  // Se il business è ancora in caricamento o ha errori, ritorna placeholder
  if (businessAsync.isLoading || businessAsync.hasError) {
    return placeholderBookingConfig;
  }

  final business = businessAsync.value;
  if (business == null) {
    // Business non trovato (slug non valido)
    return placeholderBookingConfig;
  }

  // Se il business non ha una location di default, segnala che esiste ma non è attivo
  final locationId = business.defaultLocationId;
  if (locationId == null) {
    return BookingConfig(
      allowStaffSelection: true,
      businessId: business.id,
      locationId: 0,
      businessExistsButNotActive: true,
    );
  }

  return BookingConfig(
    allowStaffSelection: true,
    businessId: business.id,
    locationId: locationId,
  );
});

/// Provider per la location ID effettiva (da location selezionata o default)
final effectiveLocationIdProvider = Provider<int>((ref) {
  final effectiveLocation = ref.watch(effectiveLocationProvider);
  if (effectiveLocation != null) {
    return effectiveLocation.id;
  }
  // Fallback alla config
  return ref.watch(bookingConfigProvider).locationId;
});

/// Step del flow di prenotazione
enum BookingStep { location, services, staff, dateTime, summary, confirmation }

/// Stato del flow di prenotazione
class BookingFlowState {
  final BookingStep currentStep;
  final BookingRequest request;
  final bool isLoading;
  final String? errorMessage;
  final String? confirmedBookingId;

  const BookingFlowState({
    this.currentStep = BookingStep.location,
    this.request = const BookingRequest(),
    this.isLoading = false,
    this.errorMessage,
    this.confirmedBookingId,
  });

  bool get canGoBack =>
      currentStep.index > 0 && currentStep != BookingStep.confirmation;

  bool get canGoNext {
    switch (currentStep) {
      case BookingStep.location:
        return true; // Gestito dal provider
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
  BookingFlowState build() {
    // Determina lo step iniziale in base al numero di locations
    final hasMultipleLocations = ref.watch(hasMultipleLocationsProvider);
    final initialStep = hasMultipleLocations
        ? BookingStep.location
        : BookingStep.services;
    return BookingFlowState(currentStep: initialStep);
  }

  BookingRepository get _repository => ref.read(bookingRepositoryProvider);
  BookingConfig get _config => ref.read(bookingConfigProvider);
  bool get _hasMultipleLocations => ref.read(hasMultipleLocationsProvider);

  /// Reset del flow
  void reset() {
    final initialStep = _hasMultipleLocations
        ? BookingStep.location
        : BookingStep.services;
    state = BookingFlowState(currentStep: initialStep);
    // Reset anche la location selezionata
    ref.read(selectedLocationProvider.notifier).clear();
  }

  /// Vai allo step successivo
  void nextStep() {
    if (!state.canGoNext) return;

    final nextIndex = state.currentStep.index + 1;
    if (nextIndex < BookingStep.values.length) {
      var nextStep = BookingStep.values[nextIndex];

      // Se c'è una sola location, salta lo step location
      if (nextStep == BookingStep.location && !_hasMultipleLocations) {
        nextStep = BookingStep.services;
      }

      // Se staff selection è disabilitata, salta lo step staff
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

    // Se c'è una sola location, salta lo step location
    if (prevStep == BookingStep.location && !_hasMultipleLocations) {
      // Non andare oltre, siamo già al primo step
      return;
    }

    state = state.copyWith(currentStep: prevStep);
  }

  /// Vai a uno step specifico
  void goToStep(BookingStep step) {
    // Non permettere di tornare allo step location se c'è una sola location
    if (step == BookingStep.location && !_hasMultipleLocations) {
      return;
    }
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
      // Usa la location effettiva (selezionata o default)
      final locationId = ref.read(effectiveLocationIdProvider);

      final result = await _repository.confirmBooking(
        locationId: locationId,
        serviceIds: state.request.services.map((s) => s.id).toList(),
        startTime: state.request.selectedSlot!.startTime,
        staffId: state.request.selectedStaff?.id,
        notes: state.request.notes,
      );

      // Estrai booking ID dalla risposta
      final bookingId =
          result['id']?.toString() ??
          result['booking_id']?.toString() ??
          'confirmed';

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

/// Dati servizi (categories + services in un'unica chiamata API)
class ServicesData {
  final List<ServiceCategory> categories;
  final List<Service> services;

  const ServicesData({required this.categories, required this.services});

  /// Servizi prenotabili online
  List<Service> get bookableServices =>
      services.where((s) => s.isBookableOnline).toList();

  bool get isEmpty => bookableServices.isEmpty;
}

/// Notifier per gestire il caricamento dei servizi con controllo TOTALE sullo stato
class ServicesDataNotifier extends StateNotifier<AsyncValue<ServicesData>> {
  final Ref _ref;
  bool _hasFetched = false;
  int? _lastLocationId;

  ServicesDataNotifier(this._ref) : super(const AsyncValue.loading()) {
    // Ascolta cambiamenti della location effettiva
    _ref.listen(effectiveLocationIdProvider, (previous, next) {
      if (next > 0 && next != _lastLocationId) {
        _hasFetched = false;
        _lastLocationId = next;
        _loadData();
      }
    }, fireImmediately: true);
  }

  Future<void> _loadData() async {
    if (_hasFetched) return;

    final locationId = _ref.read(effectiveLocationIdProvider);
    if (locationId <= 0) return;

    _hasFetched = true;

    try {
      final repository = _ref.read(bookingRepositoryProvider);

      final result = await repository.getCategoriesWithServices(locationId);

      final sortedCategories = List<ServiceCategory>.from(result.categories)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final sortedServices = List<Service>.from(result.services)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      state = AsyncValue.data(
        ServicesData(categories: sortedCategories, services: sortedServices),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Forza il refresh dei dati (per retry manuale)
  Future<void> refresh() async {
    _hasFetched = false;
    state = const AsyncValue.loading();
    await _loadData();
  }
}

/// Provider unico per categorie e servizi (UNA sola chiamata API)
final servicesDataProvider =
    StateNotifierProvider<ServicesDataNotifier, AsyncValue<ServicesData>>(
      (ref) => ServicesDataNotifier(ref),
    );

/// Provider per le categorie (legacy - usa servicesDataProvider)
final categoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final asyncData = ref.watch(servicesDataProvider);
  return asyncData.whenData((data) => data.categories).value ?? [];
});

/// Provider per i servizi (legacy - usa servicesDataProvider)
final servicesProvider = FutureProvider<List<Service>>((ref) async {
  final asyncData = ref.watch(servicesDataProvider);
  return asyncData.whenData((data) => data.services).value ?? [];
});

/// Notifier per lo staff con protezione da loop
class StaffDataNotifier extends StateNotifier<AsyncValue<List<Staff>>> {
  final Ref _ref;
  bool _hasFetched = false;
  int? _lastLocationId;

  StaffDataNotifier(this._ref) : super(const AsyncValue.loading()) {
    // Ascolta cambiamenti della location effettiva
    _ref.listen(effectiveLocationIdProvider, (previous, next) {
      if (next > 0 && next != _lastLocationId) {
        _hasFetched = false;
        _lastLocationId = next;
        _loadData();
      }
    }, fireImmediately: true);
  }

  Future<void> _loadData() async {
    if (_hasFetched) return;

    final locationId = _ref.read(effectiveLocationIdProvider);
    if (locationId <= 0) return;

    _hasFetched = true;

    try {
      final repository = _ref.read(bookingRepositoryProvider);
      final staff = await repository.getStaff(locationId);
      final sortedStaff = List<Staff>.from(staff)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      state = AsyncValue.data(sortedStaff);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _hasFetched = false;
    state = const AsyncValue.loading();
    await _loadData();
  }
}

/// Provider per lo staff
final staffProvider =
    StateNotifierProvider<StaffDataNotifier, AsyncValue<List<Staff>>>(
      (ref) => StaffDataNotifier(ref),
    );

/// Provider per la data selezionata nel calendario
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

/// Provider per gli slot disponibili
final availableSlotsProvider = FutureProvider<List<TimeSlot>>((ref) async {
  final repository = ref.read(bookingRepositoryProvider);
  final locationId = ref.watch(effectiveLocationIdProvider);
  final bookingState = ref.watch(bookingFlowProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  if (locationId <= 0 ||
      selectedDate == null ||
      bookingState.request.services.isEmpty) {
    return [];
  }

  return repository.getAvailableSlots(
    locationId: locationId,
    date: selectedDate,
    serviceIds: bookingState.request.services.map((s) => s.id).toList(),
    staffId: bookingState.request.selectedStaff?.id,
  );
});

/// Provider per la prima data disponibile
final firstAvailableDateProvider = FutureProvider<DateTime>((ref) async {
  final repository = ref.read(bookingRepositoryProvider);
  final locationId = ref.watch(effectiveLocationIdProvider);
  final bookingState = ref.watch(bookingFlowProvider);

  if (locationId <= 0) {
    return DateTime.now().add(const Duration(days: 1));
  }

  return repository.getFirstAvailableDate(
    locationId: locationId,
    serviceIds: bookingState.request.services.map((s) => s.id).toList(),
    staffId: bookingState.request.selectedStaff?.id,
  );
});
