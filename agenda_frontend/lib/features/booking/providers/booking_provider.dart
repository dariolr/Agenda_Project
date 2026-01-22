import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/booking_request.dart';
import '../../../core/models/location.dart';
import '../../../core/models/service.dart';
import '../../../core/models/service_category.dart';
import '../../../core/models/service_package.dart';
import '../../../core/models/staff.dart';
import '../../../core/models/time_slot.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/services/pending_booking_storage.dart';
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
  final effectiveLocation = ref.watch(effectiveLocationProvider);

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

  final allowStaffSelection = effectiveLocation != null
      ? effectiveLocation.allowCustomerChooseStaff
      : true;

  return BookingConfig(
    allowStaffSelection: allowStaffSelection,
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

/// Provider per il numero massimo di giorni prenotabili in anticipo
final maxBookingAdvanceDaysProvider = Provider<int>((ref) {
  final effectiveLocation = ref.watch(effectiveLocationProvider);
  if (effectiveLocation != null) {
    return effectiveLocation.maxBookingAdvanceDays;
  }

  final locationsAsync = ref.watch(locationsProvider);
  final fallbackLocationId = ref.watch(bookingConfigProvider).locationId;
  return locationsAsync.maybeWhen(
        data: (locations) {
          if (locations.isEmpty) return 90;
          final fallback = locations.firstWhere(
            (l) => l.id == fallbackLocationId,
            orElse: () => locations.first,
          );
          return fallback.maxBookingAdvanceDays;
        },
        orElse: () => 90,
      ) ??
      90;
});

/// Step del flow di prenotazione
enum BookingStep { location, services, staff, dateTime, summary, confirmation }

/// Stato del flow di prenotazione
class BookingFlowState {
  final BookingStep currentStep;
  final BookingRequest request;
  final bool isLoading;
  final String? errorMessage;
  final String? errorCode;
  final String? confirmedBookingId;
  final bool isStaffAutoSelected;

  const BookingFlowState({
    this.currentStep = BookingStep.location,
    this.request = const BookingRequest(),
    this.isLoading = false,
    this.errorMessage,
    this.errorCode,
    this.confirmedBookingId,
    this.isStaffAutoSelected = false,
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
    String? errorCode,
    String? confirmedBookingId,
    bool clearError = false,
    bool? isStaffAutoSelected,
  }) => BookingFlowState(
    currentStep: currentStep ?? this.currentStep,
    request: request ?? this.request,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    errorCode: clearError ? null : (errorCode ?? this.errorCode),
    confirmedBookingId: confirmedBookingId ?? this.confirmedBookingId,
    isStaffAutoSelected: isStaffAutoSelected ?? this.isStaffAutoSelected,
  );
}

class BookingTotals {
  final double totalPrice;
  final int totalDurationMinutes;
  final List<ServicePackage> selectedPackages;
  final Set<int> coveredServiceIds;
  final int selectedItemCount;

  const BookingTotals({
    required this.totalPrice,
    required this.totalDurationMinutes,
    required this.selectedPackages,
    required this.coveredServiceIds,
    required this.selectedItemCount,
  });
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
    ref.listen<Location?>(effectiveLocationProvider, (previous, next) {
      if (previous?.id == next?.id) return;
      state = state.copyWith(
        request: state.request.copyWith(
          clearStaff: true,
          clearStaffSelections: true,
          clearAnyOperatorSelections: true,
          clearSlot: true,
        ),
        isStaffAutoSelected: false,
      );
    });
    ref.listen<int?>(urlLocationIdProvider, (previous, next) {
      if (previous == next) return;
      state = state.copyWith(
        request: state.request.copyWith(
          clearStaff: true,
          clearStaffSelections: true,
          clearAnyOperatorSelections: true,
          clearSlot: true,
        ),
        isStaffAutoSelected: false,
      );
    });
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
    // Note: availableDatesProvider si resetta automaticamente via listeners
    // quando cambiano services/staff
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
      state = state.copyWith(currentStep: nextStep, clearError: true);
      // Il prefetch viene gestito automaticamente dai listener in DateTimeStep
    }
  }

  /// Avanza dallo step servizi con auto-selezione staff se possibile
  Future<void> nextFromServicesWithAutoStaff() async {
    if (state.currentStep != BookingStep.services) {
      nextStep();
      return;
    }
    if (!_config.allowStaffSelection) {
      state = state.copyWith(
        request: state.request.copyWith(
          clearStaff: true,
          clearAnyOperatorSelections: true,
          clearSlot: true,
        ),
        isStaffAutoSelected: false,
      );
      nextStep();
      return;
    }

    final locationId = ref.read(effectiveLocationIdProvider);
    final services = state.request.services;
    final serviceIds = services.map((s) => s.id).toList();
    if (locationId <= 0 || serviceIds.isEmpty) return;

    state = state.copyWith(
      isLoading: true,
      currentStep: BookingStep.staff,
      clearError: true,
    );

    try {
      final repository = ref.read(bookingRepositoryProvider);
      final allStaff = await repository.getStaff(locationId);

      // Per ogni servizio, trova gli operatori che possono erogarlo
      final staffByService = <int, List<Staff>>{};
      for (final service in services) {
        staffByService[service.id] =
            allStaff.where((s) => s.serviceIds.contains(service.id)).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }

      // Pre-seleziona automaticamente gli operatori per servizi con un solo operatore
      final autoSelected = <int, Staff?>{};
      var allAutoSelected = true;
      for (final service in services) {
        final staffForService = staffByService[service.id] ?? [];
        if (staffForService.length == 1) {
          autoSelected[service.id] = staffForService.first;
        } else {
          autoSelected[service.id] = null;
          allAutoSelected = false;
        }
      }

      // Se tutti i servizi hanno un solo operatore, auto-seleziona e mostra lo step
      if (allAutoSelected && services.isNotEmpty) {
        final isSingleService = services.length == 1;
        final selectedStaff = isSingleService
            ? autoSelected[services.first.id]
            : null;
        state = state.copyWith(
          request: state.request.copyWith(
            selectedStaff: selectedStaff,
            selectedStaffByService: autoSelected,
            clearSlot: true,
            anyOperatorSelected: false,
          ),
          isStaffAutoSelected: false,
          currentStep: BookingStep.staff,
        );
        return;
      }

      // Altrimenti mostra lo step staff con le pre-selezioni
      state = state.copyWith(
        request: state.request.copyWith(
          selectedStaffByService: autoSelected,
          clearSlot: true,
          anyOperatorSelected: false,
        ),
        isStaffAutoSelected: false,
        currentStep: BookingStep.staff,
      );
    } finally {
      state = state.copyWith(isLoading: false);
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

    final updatedRequest = _resetRequestForStep(prevStep);
    final shouldClearSelectedDate = _shouldClearSelectedDate(prevStep);
    final shouldResetAutoStaff = _shouldResetAutoStaff(prevStep);
    final shouldResetAvailability = _shouldResetAvailability(prevStep);

    state = state.copyWith(
      currentStep: prevStep,
      request: updatedRequest,
      clearError: true,
      isStaffAutoSelected: shouldResetAutoStaff
          ? false
          : state.isStaffAutoSelected,
    );

    // Note: availableDatesProvider si resetta automaticamente via listeners
    // quando cambiano services/staff. Resettiamo solo focusedMonth e selectedDate.
    if (shouldResetAvailability) {
      ref.read(focusedMonthProvider.notifier).state = DateTime.now();
    }

    if (shouldClearSelectedDate) {
      ref.read(selectedDateProvider.notifier).state = null;
    }
  }

  /// Vai a uno step specifico
  void goToStep(BookingStep step) {
    // Non permettere di tornare allo step location se c'è una sola location
    if (step == BookingStep.location && !_hasMultipleLocations) {
      return;
    }
    if (step.index < state.currentStep.index) {
      final updatedRequest = _resetRequestForStep(step);
      final shouldClearSelectedDate = _shouldClearSelectedDate(step);
      final shouldResetAutoStaff = _shouldResetAutoStaff(step);
      final shouldResetAvailability = _shouldResetAvailability(step);

      state = state.copyWith(
        currentStep: step,
        request: updatedRequest,
        clearError: true,
        isStaffAutoSelected: shouldResetAutoStaff
            ? false
            : state.isStaffAutoSelected,
      );

      // Note: availableDatesProvider si resetta automaticamente via listeners
      // quando cambiano services/staff. Resettiamo solo focusedMonth e selectedDate.
      if (shouldResetAvailability) {
        ref.read(focusedMonthProvider.notifier).state = DateTime.now();
      }

      if (shouldClearSelectedDate) {
        ref.read(selectedDateProvider.notifier).state = null;
      }
    }
  }

  BookingRequest _resetRequestForStep(BookingStep step) {
    final request = state.request;
    switch (step) {
      case BookingStep.location:
        return request.copyWith(
          services: const [],
          clearStaff: true,
          clearStaffSelections: true,
          clearAnyOperatorSelections: true,
          clearSlot: true,
          clearNotes: true,
        );
      case BookingStep.services:
        return request.copyWith(
          clearStaff: true,
          clearStaffSelections: true,
          clearAnyOperatorSelections: true,
          clearSlot: true,
          clearNotes: true,
        );
      case BookingStep.staff:
        return request.copyWith(clearSlot: true, clearNotes: true);
      case BookingStep.dateTime:
        return request.copyWith(clearSlot: true, clearNotes: true);
      case BookingStep.summary:
      case BookingStep.confirmation:
        return request;
    }
  }

  bool _shouldClearSelectedDate(BookingStep step) {
    switch (step) {
      case BookingStep.location:
      case BookingStep.services:
      case BookingStep.staff:
      case BookingStep.dateTime:
        return true;
      case BookingStep.summary:
      case BookingStep.confirmation:
        return false;
    }
  }

  bool _shouldResetAutoStaff(BookingStep step) {
    switch (step) {
      case BookingStep.location:
      case BookingStep.services:
      case BookingStep.staff:
        return true;
      case BookingStep.dateTime:
      case BookingStep.summary:
      case BookingStep.confirmation:
        return false;
    }
  }

  bool _shouldResetAvailability(BookingStep step) {
    switch (step) {
      case BookingStep.location:
      case BookingStep.services:
      case BookingStep.staff:
      case BookingStep.dateTime:
        return true;
      case BookingStep.summary:
      case BookingStep.confirmation:
        return false;
    }
  }

  /// Toggle selezione servizio
  void toggleService(Service service) {
    final currentServices = List<Service>.from(state.request.services);
    final selectedServiceIds = Set<int>.from(state.request.selectedServiceIds);
    final packageServiceIds = state.request.selectedPackageServiceIds;

    final isSelected = selectedServiceIds.contains(service.id);
    if (isSelected) {
      selectedServiceIds.remove(service.id);
      if (!packageServiceIds.contains(service.id)) {
        currentServices.removeWhere((s) => s.id == service.id);
      }
    } else {
      selectedServiceIds.add(service.id);
      if (!currentServices.any((s) => s.id == service.id)) {
        currentServices.add(service);
      }
    }

    final shouldClearStaff = !_config.allowStaffSelection;
    final updatedStaffByService =
        Map<int, Staff?>.from(state.request.selectedStaffByService)
          ..removeWhere(
            (serviceId, _) => !currentServices.any((s) => s.id == serviceId),
          );

    // Quando cambiano i servizi, resetta slot selezionato
    state = state.copyWith(
      request: state.request.copyWith(
        services: currentServices,
        selectedServiceIds: selectedServiceIds,
        selectedStaffByService: shouldClearStaff ? {} : updatedStaffByService,
        clearStaff: shouldClearStaff,
        clearAnyOperatorSelections: shouldClearStaff,
        clearSlot: true,
      ),
      clearError: true,
      isStaffAutoSelected: shouldClearStaff ? false : state.isStaffAutoSelected,
    );
  }

  /// Aggiunge servizi in ordine (usato per pacchetti)
  void addServicesFromPackage(List<Service> servicesInOrder) {
    if (servicesInOrder.isEmpty) return;

    final currentServices = List<Service>.from(state.request.services);
    for (final service in servicesInOrder) {
      if (!currentServices.any((s) => s.id == service.id)) {
        currentServices.add(service);
      }
    }

    final shouldClearStaff = !_config.allowStaffSelection;
    final updatedStaffByService =
        Map<int, Staff?>.from(state.request.selectedStaffByService)
          ..removeWhere(
            (serviceId, _) => !currentServices.any((s) => s.id == serviceId),
          );

    state = state.copyWith(
      request: state.request.copyWith(
        services: currentServices,
        selectedStaffByService: shouldClearStaff ? {} : updatedStaffByService,
        clearStaff: shouldClearStaff,
        clearAnyOperatorSelections: shouldClearStaff,
        clearSlot: true,
      ),
      clearError: true,
      isStaffAutoSelected: shouldClearStaff ? false : state.isStaffAutoSelected,
    );
  }

  /// Toggle pacchetto come selezione servizi
  void togglePackageSelection(
    ServicePackage package,
    List<Service> availableServices,
  ) {
    final serviceIds = package.orderedServiceIds;
    if (serviceIds.isEmpty) return;

    final currentServices = List<Service>.from(state.request.services);
    final selectedPackageIds = Set<int>.from(state.request.selectedPackageIds);
    final packageServicesByPackage = Map<int, List<int>>.from(
      state.request.selectedPackageServiceIdsByPackage,
    );
    final selectedServiceIds = Set<int>.from(state.request.selectedServiceIds);

    final servicesById = {for (final s in availableServices) s.id: s};
    for (final item in package.items) {
      servicesById.putIfAbsent(
        item.serviceId,
        () => _serviceFromPackageItem(package, item),
      );
    }
    if (selectedPackageIds.contains(package.id)) {
      selectedPackageIds.remove(package.id);
      packageServicesByPackage.remove(package.id);
    } else {
      selectedPackageIds.add(package.id);
      packageServicesByPackage[package.id] = List<int>.from(serviceIds);
    }

    final packageServiceIds = packageServicesByPackage.values
        .expand((ids) => ids)
        .toSet();

    currentServices.removeWhere(
      (s) =>
          !selectedServiceIds.contains(s.id) &&
          !packageServiceIds.contains(s.id),
    );

    for (final id in packageServiceIds) {
      if (!currentServices.any((s) => s.id == id)) {
        final service = servicesById[id];
        if (service != null) {
          currentServices.add(service);
        }
      }
    }

    final shouldClearStaff = !_config.allowStaffSelection;
    final updatedStaffByService =
        Map<int, Staff?>.from(state.request.selectedStaffByService)
          ..removeWhere(
            (serviceId, _) => !currentServices.any((s) => s.id == serviceId),
          );

    state = state.copyWith(
      request: state.request.copyWith(
        services: currentServices,
        selectedPackageIds: selectedPackageIds,
        selectedPackageServiceIdsByPackage: packageServicesByPackage,
        selectedStaffByService: shouldClearStaff ? {} : updatedStaffByService,
        clearStaff: shouldClearStaff,
        clearAnyOperatorSelections: shouldClearStaff,
        clearSlot: true,
      ),
      clearError: true,
      isStaffAutoSelected: shouldClearStaff ? false : state.isStaffAutoSelected,
    );
  }

  Service _serviceFromPackageItem(
    ServicePackage package,
    ServicePackageItem item,
  ) {
    final price = (item.price ?? 0).toDouble();
    final categoryId = package.categoryId;
    return Service(
      id: item.serviceId,
      businessId: _config.businessId,
      categoryId: categoryId,
      name: item.name ?? package.name,
      durationMinutes: item.durationMinutes ?? 0,
      price: price,
      isFree: price == 0,
      isBookableOnline: true,
      isActive: item.serviceIsActive && item.variantIsActive,
    );
  }

  /// Seleziona staff specifico (resetta "qualsiasi operatore")
  void selectStaff(Staff? staff) {
    // Se staff è null, usa selectAnyOperator() invece
    if (staff == null) {
      selectAnyOperator();
      return;
    }

    state = state.copyWith(
      request: state.request.copyWith(
        selectedStaff: staff,
        selectedStaffByService: const {},
        anyOperatorSelected: false,
        clearSlot: true, // Resetta slot quando cambia staff
      ),
      clearError: true,
      isStaffAutoSelected: false,
    );
  }

  /// Seleziona staff per servizio (usato con allowMultiStaffBooking = true)
  void selectStaffForService(Service service, Staff? staff) {
    final updated = Map<int, Staff?>.from(state.request.selectedStaffByService);
    updated[service.id] = staff;
    final isSingleService = state.request.services.length == 1;
    state = state.copyWith(
      request: state.request.copyWith(
        selectedStaff: isSingleService ? staff : state.request.selectedStaff,
        selectedStaffByService: updated,
        clearStaff: isSingleService && staff == null,
        clearSlot: true,
        anyOperatorSelected: false,
      ),
      clearError: true,
      isStaffAutoSelected: false,
    );
  }

  /// Seleziona "qualsiasi operatore" (caso semplice, un solo staff per tutti i servizi)
  void selectAnyOperator() {
    state = state.copyWith(
      request: state.request.copyWith(
        selectedStaff: null,
        selectedStaffByService: const {},
        anyOperatorSelected: true,
        clearStaff: true,
        clearSlot: true,
      ),
      clearError: true,
      isStaffAutoSelected: false,
    );
  }

  /// Seleziona "qualsiasi operatore" per i servizi con più operatori,
  /// ma mantiene l'operatore selezionato per i servizi con un solo operatore
  /// NOTA: Usato solo con allowMultiStaffBooking = true
  void selectAnyOperatorForAllServices(Map<int, List<Staff>> staffByService) {
    // Per i servizi con un solo operatore, mantieni quell'operatore
    final selectedStaffByService = <int, Staff?>{};
    for (final entry in staffByService.entries) {
      if (entry.value.length == 1) {
        selectedStaffByService[entry.key] = entry.value.first;
      }
    }

    state = state.copyWith(
      request: state.request.copyWith(
        selectedStaff: null,
        selectedStaffByService: selectedStaffByService,
        anyOperatorSelected: true,
        clearStaff: true,
        clearSlot: true,
      ),
      clearError: true,
      isStaffAutoSelected: false,
    );
  }

  /// Seleziona staff automaticamente e disabilita ritorno allo step staff
  void autoSelectStaff(Staff staff) {
    final services = state.request.services;
    final updated = Map<int, Staff?>.from(state.request.selectedStaffByService);
    if (services.isNotEmpty) {
      updated[services.first.id] = staff;
    }
    state = state.copyWith(
      request: state.request.copyWith(
        selectedStaff: staff,
        clearStaff: false,
        selectedStaffByService: updated,
        clearSlot: true,
        anyOperatorSelected: false,
      ),
      clearError: true,
      isStaffAutoSelected: true,
    );
  }

  /// Seleziona slot temporale
  void selectTimeSlot(TimeSlot slot) {
    state = state.copyWith(
      request: state.request.copyWith(selectedSlot: slot),
      clearError: true,
    );
  }

  /// Aggiorna note
  void updateNotes(String notes) {
    state = state.copyWith(request: state.request.copyWith(notes: notes));
  }

  /// Conferma prenotazione
  /// Ritorna:
  /// - true: prenotazione confermata con successo
  /// - false: errore generico
  /// - Lancia TokenExpiredException se il token è scaduto (401)
  Future<bool> confirmBooking() async {
    debugPrint('[confirmBooking] isComplete=${state.request.isComplete}');
    debugPrint(
      '[confirmBooking] services=${state.request.services.map((s) => s.id).toList()}',
    );
    debugPrint(
      '[confirmBooking] selectedSlot=${state.request.selectedSlot?.startTime}',
    );
    debugPrint(
      '[confirmBooking] selectedStaff=${state.request.selectedStaff?.id}',
    );
    debugPrint(
      '[confirmBooking] selectedStaffByService=${state.request.selectedStaffByService}',
    );
    debugPrint(
      '[confirmBooking] anyOperatorSelected=${state.request.anyOperatorSelected}',
    );
    debugPrint('[confirmBooking] singleStaffId=${state.request.singleStaffId}');

    if (!state.request.isComplete) {
      debugPrint('[confirmBooking] ABORT: request not complete');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    // Salva lo stato PRIMA di tentare la conferma (per recovery in caso di 401)
    final locationId = ref.read(effectiveLocationIdProvider);
    final businessId = _config.businessId;
    final selectedLocation = ref.read(selectedLocationProvider);

    await PendingBookingStorage.save(
      PendingBookingData.fromBookingRequest(
        businessId: businessId,
        locationId: locationId,
        selectedLocation: selectedLocation,
        request: state.request,
      ),
    );

    try {
      final services = state.request.services;

      List<Map<String, dynamic>>? items;
      final shouldUseItems =
          services.length > 1 &&
          state.request.hasOnlyStaffSelectionForAllServices;
      if (shouldUseItems) {
        if (!state.request.hasStaffSelectionForAllServices) {
          state = state.copyWith(isLoading: false);
          return false;
        }
        var currentStart = state.request.selectedSlot!.startTime;
        items = [];
        for (final service in services) {
          final staff = state.request.staffForService(service.id);
          if (staff == null) {
            state = state.copyWith(isLoading: false);
            return false;
          }
          items.add({
            'service_id': service.id,
            'staff_id': staff.id,
            // Invia orario come ISO locale (NO toUtc - il backend gestisce il timezone)
            'start_time': currentStart.toIso8601String(),
          });
          currentStart = currentStart.add(
            Duration(minutes: service.durationMinutes),
          );
        }
      }

      final staffId = state.request.singleStaffId;
      // Se ci sono più servizi senza selezione staff specifica,
      // trattiamo come "qualsiasi operatore" (staffId = null)
      // Questo è valido quando:
      // - Lo step staff è stato saltato (allowStaffSelection = false)
      // - L'utente ha selezionato "qualsiasi operatore"
      // - Non c'è selezione per servizio
      if (!shouldUseItems && services.length > 1) {
        // OK: procedi con staffId (che sarà null per "qualsiasi operatore")
      }

      final result = await _repository.confirmBooking(
        businessId: businessId,
        locationId: locationId,
        serviceIds: services.map((s) => s.id).toList(),
        startTime: state.request.selectedSlot!.startTime,
        staffId: staffId,
        notes: state.request.notes,
        items: items,
      );

      // Prenotazione confermata - elimina lo stato salvato
      await PendingBookingStorage.clear();

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
    } on ApiException catch (e) {
      // Se è 401, converti in TokenExpiredException
      // (il refresh token è già stato tentato dall'interceptor)
      if (e.isUnauthorized) {
        state = state.copyWith(isLoading: false);
        throw const TokenExpiredException(
          'Sessione scaduta. Effettua nuovamente il login.',
        );
      }
      // Altri errori API - elimina lo stato salvato
      await PendingBookingStorage.clear();
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        errorCode: e.code,
      );
      return false;
    } on TokenExpiredException {
      // Token scaduto - lo stato è già salvato, rilancia per gestione UI
      state = state.copyWith(isLoading: false);
      rethrow;
    } catch (e) {
      // Errore generico - elimina lo stato salvato
      await PendingBookingStorage.clear();
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        errorCode: null,
      );
      return false;
    }
  }

  /// Ripristina una prenotazione salvata (dopo login da token scaduto)
  Future<bool> restorePendingBooking() async {
    final pending = await PendingBookingStorage.load();
    if (pending == null) return false;

    // Verifica che il business corrisponda
    if (pending.businessId != _config.businessId) {
      await PendingBookingStorage.clear();
      return false;
    }

    // Ripristina lo stato
    state = state.copyWith(
      currentStep: BookingStep.summary,
      request: pending.toBookingRequest(),
    );

    // Ripristina la location selezionata se presente
    final location = pending.selectedLocation;
    if (location != null) {
      ref.read(selectedLocationProvider.notifier).select(location);
    }

    // Pulisci lo storage
    await PendingBookingStorage.clear();

    return true;
  }

  /// Verifica se c'è una prenotazione in sospeso
  Future<bool> hasPendingBooking() => PendingBookingStorage.hasPendingBooking();
}

/// Dati servizi (categories + services in un'unica chiamata API)
class ServicesData {
  final List<ServiceCategory> categories;
  final List<Service> services;

  const ServicesData({required this.categories, required this.services});

  /// Servizi prenotabili online
  List<Service> get bookableServices =>
      services.where((s) => s.isBookableOnline && s.isActive).toList();

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

/// Provider per i pacchetti di servizi
class ServicePackagesNotifier
    extends StateNotifier<AsyncValue<List<ServicePackage>>> {
  final Ref _ref;
  bool _hasFetched = false;
  int? _lastLocationId;

  ServicePackagesNotifier(this._ref) : super(const AsyncValue.loading()) {
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
      final packages = await repository.getServicePackages(locationId);
      state = AsyncValue.data(packages);
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

final servicePackagesProvider =
    StateNotifierProvider<
      ServicePackagesNotifier,
      AsyncValue<List<ServicePackage>>
    >((ref) => ServicePackagesNotifier(ref));

final bookingTotalsProvider = Provider<BookingTotals>((ref) {
  final bookingState = ref.watch(bookingFlowProvider);
  final services = bookingState.request.services;
  final selectedServiceIds = services.map((s) => s.id).toSet();
  final packages = ref.watch(servicePackagesProvider).value ?? [];
  final selectedPackageIds = bookingState.request.selectedPackageIds;

  final selectedPackages = <ServicePackage>[];
  final coveredServiceIds = <int>{};
  for (final pkg in packages) {
    if (!pkg.isActive || pkg.isBroken) continue;
    if (!selectedPackageIds.contains(pkg.id)) continue;
    final ids = pkg.orderedServiceIds;
    if (ids.isEmpty) continue;
    if (ids.every(selectedServiceIds.contains)) {
      selectedPackages.add(pkg);
      coveredServiceIds.addAll(ids);
    }
  }

  var totalPrice = 0.0;
  var totalDuration = 0;
  for (final pkg in selectedPackages) {
    totalPrice += pkg.effectivePrice;
    totalDuration += pkg.effectiveDurationMinutes;
  }

  final remainingServices = services
      .where((s) => !coveredServiceIds.contains(s.id))
      .toList();
  for (final service in remainingServices) {
    totalPrice += service.isFree ? 0 : service.price;
    totalDuration +=
        service.totalDurationMinutes; // Include processing_time + blocked_time
  }

  final selectedItemCount = selectedPackages.length + remainingServices.length;

  return BookingTotals(
    totalPrice: totalPrice,
    totalDurationMinutes: totalDuration,
    selectedPackages: selectedPackages,
    coveredServiceIds: coveredServiceIds,
    selectedItemCount: selectedItemCount,
  );
});

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

/// Provider per lo staff
final staffProvider =
    StateNotifierProvider<AvailableStaffNotifier, AsyncValue<List<Staff>>>(
      (ref) => AvailableStaffNotifier(ref),
    );

/// Provider per la data selezionata nel calendario
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

/// Provider per il mese attualmente focalizzato nel calendario
final focusedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Notifier per le date disponibili (con slot reali)
/// Carica le date disponibili in blocchi di 15 giorni per performance
class AvailableDatesNotifier extends StateNotifier<AsyncValue<Set<DateTime>>> {
  final Ref _ref;
  String? _lastKey;
  int _loadedDays = 0;
  bool _isLoadingMore = false;
  bool _didPreload = false;
  final Set<DateTime> _allDates = {};
  static const int _chunkSize = 15;

  AvailableDatesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen(effectiveLocationIdProvider, (_, __) => _reset());
    _ref.listen(maxBookingAdvanceDaysProvider, (_, __) => _reset());
    _ref.listen(
      bookingFlowProvider.select((s) => s.request.services),
      (_, __) => _reset(),
      fireImmediately: true,
    );
    _ref.listen(
      bookingFlowProvider.select((s) => s.request.singleStaffId),
      (_, __) => _reset(),
    );
  }

  void _reset() {
    final key = _currentKey();
    debugPrint(
      '[AvailableDatesNotifier] _reset called, key=$key, lastKey=$_lastKey',
    );
    if (key != null && _lastKey == key) {
      debugPrint('[AvailableDatesNotifier] Key unchanged, skipping reset');
      return;
    }
    debugPrint('[AvailableDatesNotifier] Resetting with new key');
    _lastKey = key;
    _loadedDays = 0;
    _allDates.clear();
    _didPreload = false;
    // Forza interruzione del caricamento in corso per permettere il nuovo
    _isLoadingMore = false;
    _loadNextChunk();
  }

  void resetForNewSelection() {
    _lastKey = null;
    _loadedDays = 0;
    _allDates.clear();
    _didPreload = false;
    // Forza interruzione del caricamento in corso
    _isLoadingMore = false;
    state = const AsyncValue.loading();
    _loadNextChunk();
  }

  String? _currentKey() {
    final locationId = _ref.read(effectiveLocationIdProvider);
    final maxDays = _ref.read(maxBookingAdvanceDaysProvider);
    final bookingState = _ref.read(bookingFlowProvider);
    final serviceIds = bookingState.request.services.map((s) => s.id).toList();
    final staffId = bookingState.request.singleStaffId;

    if (locationId <= 0 || serviceIds.isEmpty) {
      return null;
    }
    return '$locationId|$maxDays|${staffId ?? 0}|${serviceIds.join(',')}';
  }

  /// Carica il prossimo blocco di 15 giorni
  Future<void> loadMore() async {
    final maxDays = _ref.read(maxBookingAdvanceDaysProvider);
    if (_loadedDays >= maxDays || _isLoadingMore) return;
    await _loadNextChunk();
  }

  /// Carica fino a coprire almeno il giorno richiesto (indice relativo a oggi)
  Future<void> loadUntilDay(int dayIndex) async {
    if (dayIndex < 0 || _isLoadingMore) return;
    final maxDays = _ref.read(maxBookingAdvanceDaysProvider);
    if (maxDays <= 0) return;

    final target = (dayIndex + _chunkSize).clamp(0, maxDays);
    while (_loadedDays < target) {
      final before = _loadedDays;
      await _loadNextChunk();
      if (_loadedDays == before) {
        break;
      }
    }
  }

  /// Verifica se ci sono altri giorni da caricare
  bool get hasMore {
    final maxDays = _ref.read(maxBookingAdvanceDaysProvider);
    return _loadedDays < maxDays;
  }

  /// Numero di giorni già caricati
  int get loadedDays => _loadedDays;

  Future<void> _loadNextChunk() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    final locationId = _ref.read(effectiveLocationIdProvider);
    final maxDays = _ref.read(maxBookingAdvanceDaysProvider);
    final bookingState = _ref.read(bookingFlowProvider);
    final serviceIds = bookingState.request.services.map((s) => s.id).toList();
    final staffId = bookingState.request.singleStaffId;

    debugPrint(
      '[AvailableDatesNotifier] _loadNextChunk: locationId=$locationId, serviceIds=$serviceIds, staffId=$staffId, loadedDays=$_loadedDays, maxDays=$maxDays',
    );

    if (locationId <= 0 || serviceIds.isEmpty) {
      state = const AsyncValue.data({});
      _isLoadingMore = false;
      return;
    }

    // Se è il primo caricamento, mostra loading
    if (_loadedDays == 0) {
      state = const AsyncValue.loading();
    }

    try {
      final repository = _ref.read(bookingRepositoryProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Calcola il range di giorni da caricare
      final startDay = _loadedDays;
      final endDay = (startDay + _chunkSize).clamp(0, maxDays);

      // Carica le date per questo blocco di giorni
      for (var i = startDay; i < endDay; i++) {
        final date = today.add(Duration(days: i));
        try {
          final slots = await repository.getAvailableSlots(
            locationId: locationId,
            date: date,
            serviceIds: serviceIds,
            staffId: staffId,
          );
          if (slots.isNotEmpty) {
            _allDates.add(DateTime(date.year, date.month, date.day));
          }
        } catch (_) {
          // Ignora errori per singoli giorni
        }
      }

      _loadedDays = endDay;
      state = AsyncValue.data(Set.from(_allDates));

      if (!_didPreload) {
        _didPreload = true;
        if (_loadedDays < maxDays) {
          Future(() async {
            await _loadNextChunk();
          });
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }
}

/// Provider per le date disponibili (slot reali)
final availableDatesProvider =
    StateNotifierProvider<AvailableDatesNotifier, AsyncValue<Set<DateTime>>>(
      (ref) => AvailableDatesNotifier(ref),
    );

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

  final services = bookingState.request.services;
  if (services.isEmpty) {
    return [];
  }

  // Con allowMultiStaffBooking = false, usiamo sempre la chiamata standard
  // che cerca uno staff capace di fare TUTTI i servizi
  return repository.getAvailableSlots(
    locationId: locationId,
    date: selectedDate,
    serviceIds: services.map((s) => s.id).toList(),
    staffId: bookingState.request.singleStaffId,
  );

  // === CODICE MULTI-STAFF (DISABILITATO) ===
  // Riabilitare quando allowMultiStaffBooking = true in BookingConfig
  // e l'API multi-staff è implementata.
  /*
  final selectedStaffByService = bookingState.request.selectedStaffByService;
  final hasPerServiceSelection =
      services.length > 1 &&
      selectedStaffByService.isNotEmpty &&
      !bookingState.request.anyOperatorSelected;
  final allAnyOperatorSelected =
      bookingState.request.allServicesAnyOperatorSelected &&
      selectedStaffByService.isEmpty;

  if (!hasPerServiceSelection || allAnyOperatorSelected) {
    return repository.getAvailableSlots(
      locationId: locationId,
      date: selectedDate,
      serviceIds: services.map((s) => s.id).toList(),
      staffId: bookingState.request.singleStaffId,
    );
  }

  final slotsByService = <int, List<TimeSlot>>{};
  for (final service in services) {
    final staffId = selectedStaffByService[service.id]?.id;
    final slots = await repository.getAvailableSlots(
      locationId: locationId,
      date: selectedDate,
      serviceIds: [service.id],
      staffId: staffId,
    );
    slotsByService[service.id] = slots;
    if (slots.isEmpty) {
      return [];
    }
  }

  final totalDuration = services.fold<int>(
    0,
    (sum, service) => sum + service.totalDurationMinutes, // Include processing_time + blocked_time
  );
  final startSets = <int, Set<int>>{};
  for (final entry in slotsByService.entries) {
    startSets[entry.key] = entry.value
        .map((s) => s.startTime.millisecondsSinceEpoch)
        .toSet();
  }

  final baseService = services.first;
  final baseStarts = startSets[baseService.id] ?? {};
  if (baseStarts.isEmpty) {
    return [];
  }

  // Calcola gli offset per ogni servizio, arrotondando al prossimo multiplo
  // di 15 minuti (granularità degli slot API)
  const slotInterval = 15;
  final offsets = <int>[];
  var running = 0;
  for (final service in services) {
    offsets.add(running);
    final duration = service.durationMinutes;
    final roundedDuration =
        ((duration + slotInterval - 1) ~/ slotInterval) * slotInterval;
    running += roundedDuration;
  }

  final available = <TimeSlot>[];
  for (final startEpoch in baseStarts) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(startEpoch);
    var valid = true;
    for (var i = 0; i < services.length; i++) {
      final service = services[i];
      final requiredStart = startTime.add(Duration(minutes: offsets[i]));
      final requiredEpoch = requiredStart.millisecondsSinceEpoch;
      final set = startSets[service.id];
      if (set == null || !set.contains(requiredEpoch)) {
        valid = false;
        break;
      }
    }
    if (valid) {
      available.add(
        TimeSlot(
          startTime: startTime,
          endTime: startTime.add(Duration(minutes: totalDuration)),
        ),
      );
    }
  }
  available.sort((a, b) => a.startTime.compareTo(b.startTime));
  return available;
  */
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
    staffId: bookingState.request.singleStaffId,
  );
});

/// Notifier per lo staff disponibile (planning + slots reali)
class AvailableStaffNotifier extends StateNotifier<AsyncValue<List<Staff>>> {
  final Ref _ref;
  bool _hasFetched = false;
  String? _lastKey;
  List<Staff> _allStaff = const [];

  AvailableStaffNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen(
      effectiveLocationIdProvider,
      (_, __) => _invalidate(),
      fireImmediately: true,
    );
    _ref.listen(
      bookingFlowProvider.select((s) => s.currentStep),
      (_, __) => _invalidate(),
    );
    _ref.listen(
      bookingFlowProvider.select((s) => s.request.services),
      (_, __) => _applyFilter(),
    );
  }

  void _invalidate() {
    _hasFetched = false;
    _loadData();
  }

  Future<void> _loadData() async {
    final currentStep = _ref.read(bookingFlowProvider).currentStep;
    if (currentStep != BookingStep.staff) {
      return;
    }

    final locationId = _ref.read(effectiveLocationIdProvider);
    final bookingState = _ref.read(bookingFlowProvider);
    final serviceIds = bookingState.request.services.map((s) => s.id).toList();

    final key = '$locationId|${serviceIds.join(',')}';
    if (_hasFetched && _lastKey == key) return;
    _lastKey = key;
    _hasFetched = true;

    if (locationId <= 0 || serviceIds.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final repository = _ref.read(bookingRepositoryProvider);
      _allStaff = await repository.getStaff(locationId);
      _applyFilter();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _applyFilter() {
    final bookingState = _ref.read(bookingFlowProvider);
    final serviceIds = bookingState.request.services.map((s) => s.id).toList();
    if (serviceIds.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    final serviceIdSet = serviceIds.toSet();
    final availableStaff = _allStaff.where((s) {
      if (s.serviceIds.isEmpty) {
        return false;
      }
      return s.serviceIds.any(serviceIdSet.contains);
    }).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    state = AsyncValue.data(availableStaff);
  }
}
