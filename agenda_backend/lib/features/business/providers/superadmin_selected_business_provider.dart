import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/preferences_service.dart';
import '../../agenda/providers/agenda_bootstrap_provider.dart';
import '../../agenda/providers/agenda_display_settings_provider.dart';
import '../../agenda/providers/agenda_scroll_provider.dart';
import '../../agenda/providers/appointment_providers.dart';
import '../../agenda/providers/booking_reschedule_provider.dart';
import '../../agenda/providers/bookings_provider.dart';
import '../../agenda/providers/date_range_provider.dart';
import '../../agenda/providers/drag_session_provider.dart';
import '../../agenda/providers/dragged_appointment_provider.dart';
import '../../agenda/providers/dragged_base_range_provider.dart';
import '../../agenda/providers/initial_scroll_provider.dart';
import '../../agenda/providers/layout_config_provider.dart';
import '../../agenda/providers/location_providers.dart';
import '../../agenda/providers/pending_drop_provider.dart';
import '../../agenda/providers/resizing_provider.dart';
import '../../agenda/providers/resource_providers.dart';
import '../../agenda/providers/selected_appointment_provider.dart';
import '../../agenda/providers/staff_filter_providers.dart';
import '../../agenda/providers/temp_drag_time_provider.dart';
import '../../agenda/providers/time_blocks_provider.dart';
import '../../agenda/providers/weekly_appointments_provider.dart';
import '../../auth/providers/current_business_user_provider.dart';
import '../../booking_notifications/providers/whatsapp_integration_provider.dart';
import '../../bookings_list/providers/bookings_list_provider.dart';
import '../../class_events/providers/class_events_providers.dart';
import '../../clients/providers/clients_providers.dart';
import '../../payments/providers/payment_methods_provider.dart';
import '../../billing/providers/billing_provider.dart';
import '../../services/providers/service_categories_provider.dart';
import '../../services/providers/services_provider.dart';
import '../../staff/providers/availability_exceptions_provider.dart';
import '../../staff/providers/staff_providers.dart';
import 'location_closures_provider.dart';

/// Notifier per tracciare se il superadmin ha selezionato un business.
/// Quando è null, mostra la lista business.
/// Salva l'ultimo business visitato nelle preferenze per accesso rapido.
class SuperadminSelectedBusinessNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.read(preferencesServiceProvider);
    final picker = prefs.getSuperadminShowBusinessPickerOnLogin();
    final lastId = prefs.getSuperadminLastBusinessId();
    return picker ? null : lastId;
  }

  void select(int businessId) {
    state = businessId;
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setSuperadminLastBusinessId(businessId);
    prefs.setSuperadminShowBusinessPickerOnLogin(false);
  }

  /// Cambio business esplicito dall'utente: aggiorna lo stato e attende la
  /// persistenza delle preferenze prima di restituire il controllo.
  /// Usare al posto di [select] quando il chiamante deve coordinare
  /// invalidazioni Riverpod e navigazione GoRouter dopo la scrittura.
  Future<void> switchBusiness(int businessId) async {
    state = businessId;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setSuperadminLastBusinessId(businessId);
    await prefs.setSuperadminShowBusinessPickerOnLogin(false);
  }

  /// Pulisce la selezione e invalida tutti i provider relativi al business.
  void clear() {
    state = null;
  }

  /// Mostra la lista business al prossimo login del superadmin.
  /// Mantiene comunque l'ultimo business salvato per uso successivo.
  ///
  /// Non usare per il cambio business esplicito da UI già autenticata.
  /// Il cambio business deve navigare a /businesses?switch=1 senza azzerare saBiz.
  void showBusinessPickerOnNextLogin() {
    state = null;
    ref
        .read(preferencesServiceProvider)
        .setSuperadminShowBusinessPickerOnLogin(true);
  }

  /// Pulisce completamente la selezione, anche dalle preferenze.
  /// Da usare al logout o se il business viene eliminato.
  void clearCompletely() {
    state = null;
    final prefs = ref.read(preferencesServiceProvider);
    prefs.clearSuperadminLastBusinessId();
    prefs.clearSuperadminShowBusinessPickerOnLogin();
  }
}

/// Invalida tutti i provider che contengono dati specifici del business.
/// Da chiamare da UI/router, non dal notifier di selezione business, per evitare
/// dipendenze circolari durante la fase di invalidazione.
bool _isBusinessScopedInvalidationInProgress = false;

void invalidateBusinessScopedProviders(Object refObj) {
  // Evita invalidazioni duplicate nello stesso ciclo di frame/microtask,
  // che con Riverpod 3 possono generare "Tried to rebuild ... multiple times".
  if (_isBusinessScopedInvalidationInProgress) return;
  _isBusinessScopedInvalidationInProgress = true;

  final ref = refObj as dynamic;
  try {
    // Staff
    ref.invalidate(allStaffProvider);

    // Locations
    ref.invalidate(locationsAsyncProvider);
    ref.invalidate(currentLocationProvider);

    // Services
    ref.invalidate(servicesProvider);
    ref.invalidate(serviceVariantsProvider);
    ref.invalidate(serviceCategoriesProvider);
    ref.invalidate(serviceStaffEligibilityProvider);
    ref.invalidate(paymentMethodsProvider);
    ref.invalidate(paymentMethodsWithInactiveProvider);
    ref.invalidate(billingSubscriptionProvider);

    // Clients
    ref.invalidate(clientsProvider);

    // Appointments
    ref.invalidate(appointmentsProvider);
    ref.invalidate(weeklyAppointmentsProvider);

    // Bookings (prenotazioni con note/clientName)
    ref.invalidate(bookingsProvider);

    // Resources
    ref.invalidate(resourcesProvider);

    // Time Blocks
    ref.invalidate(timeBlocksProvider);

    // Availability Exceptions
    ref.invalidate(availabilityExceptionsProvider);
    ref.invalidate(availabilityExceptionsRepositoryProvider);

    // Location Closures
    ref.invalidate(locationClosuresProvider);

    // UI State legato al business (contiene ID di entità business-specific)
    ref.invalidate(selectedStaffIdsProvider);
    ref.invalidate(staffFilterModeProvider);
    ref.invalidate(selectedAppointmentProvider);
    ref.invalidate(dragSessionProvider);
    ref.invalidate(draggedAppointmentIdProvider);
    ref.invalidate(draggedBaseRangeProvider);
    ref.invalidate(tempDragTimeProvider);
    ref.invalidate(resizingProvider);
    ref.invalidate(pendingDropProvider);
    ref.invalidate(bookingRescheduleSessionProvider);

    // NOTE: currentBusinessIdProvider NON va invalidato qui perché usa ref.listen
    // su superadminSelectedBusinessProvider, quindi si aggiorna automaticamente.
    // Invalidarlo qui creerebbe una dipendenza circolare.

    // Layout e UI state (per sicurezza, anche se sembrano UI-only)
    ref.invalidate(layoutConfigProvider);
    ref.invalidate(agendaDisplaySettingsProvider);
    ref.invalidate(effectiveShowAppointmentPriceInCardProvider);
    ref.invalidate(effectiveUseServiceColorsForAppointmentsProvider);
    ref.invalidate(effectiveShowCancelledAppointmentsProvider);
    ref.invalidate(agendaCardTextScaleProvider);
    ref.invalidate(agendaCardColorOpacityProvider);
    ref.invalidate(agendaExtraMinutesBandIntensityProvider);
    ref.invalidate(agendaBootstrapLoadingProvider);
    ref.invalidate(agendaBootstrapUnlockedProvider);
    ref.invalidate(agendaDateProvider);
    ref.invalidate(agendaScrollProvider);
    ref.invalidate(initialScrollDoneProvider);
    ref.invalidate(agendaVerticalOffsetProvider);

    // Class events
    ref.invalidate(classEventsProvider);
    ref.invalidate(classEventsForRangeProvider);
    ref.invalidate(classEventsForCurrentLocationDayProvider);
    ref.invalidate(classTypesProvider);
    ref.invalidate(selectedClassTypeIdProvider);

    // Business User Context (permessi location)
    ref.invalidate(currentBusinessUserContextProvider);

    // WhatsApp integration
    ref.invalidate(whatsappIntegrationProvider);

    // Bookings list filters e stato lista
    ref.invalidate(bookingsListFiltersProvider);
    ref.invalidate(bookingsListProvider);
  } finally {
    scheduleMicrotask(() {
      _isBusinessScopedInvalidationInProgress = false;
    });
  }
}

final superadminSelectedBusinessProvider =
    NotifierProvider<SuperadminSelectedBusinessNotifier, int?>(
      SuperadminSelectedBusinessNotifier.new,
    );
