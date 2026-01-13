import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/preferences_service.dart';
import '../../agenda/providers/agenda_scroll_provider.dart';
import '../../agenda/providers/appointment_providers.dart';
import '../../agenda/providers/bookings_provider.dart';
import '../../agenda/providers/business_providers.dart';
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
import '../../clients/providers/clients_providers.dart';
import '../../services/providers/service_categories_provider.dart';
import '../../services/providers/services_provider.dart';
import '../../staff/providers/availability_exceptions_provider.dart';
import '../../staff/providers/staff_providers.dart';

/// Notifier per tracciare se il superadmin ha selezionato un business.
/// Quando è null, mostra la lista business.
/// Salva l'ultimo business visitato nelle preferenze per accesso rapido.
class SuperadminSelectedBusinessNotifier extends Notifier<int?> {
  @override
  int? build() {
    // Carica l'ultimo business salvato dalle preferenze
    final prefs = ref.read(preferencesServiceProvider);
    return prefs.getSuperadminLastBusinessId();
  }

  void select(int businessId) {
    state = businessId;
    // Salva nelle preferenze per accesso rapido al prossimo login
    ref
        .read(preferencesServiceProvider)
        .setSuperadminLastBusinessId(businessId);
  }

  /// Pulisce la selezione e invalida tutti i provider relativi al business.
  void clear() {
    state = null;
    // NON rimuoviamo dalle preferenze: l'utente può tornare con "Cambia Business"
    // ma al prossimo login verrà comunque portato all'ultimo business

    // Invalida tutti i provider business-specific per forzare ricaricamento
    _invalidateBusinessProviders();
  }

  /// Pulisce completamente la selezione, anche dalle preferenze.
  /// Da usare al logout o se il business viene eliminato.
  void clearCompletely() {
    state = null;
    ref.read(preferencesServiceProvider).clearSuperadminLastBusinessId();
    _invalidateBusinessProviders();
  }

  /// Invalida tutti i provider che contengono dati specifici del business.
  void _invalidateBusinessProviders() {
    // Staff
    ref.invalidate(allStaffProvider);

    // Locations
    ref.invalidate(locationsProvider);
    ref.invalidate(currentLocationProvider);

    // Services
    ref.invalidate(servicesProvider);
    ref.invalidate(serviceCategoriesProvider);
    ref.invalidate(serviceStaffEligibilityProvider);

    // Clients
    ref.invalidate(clientsProvider);

    // Appointments
    ref.invalidate(appointmentsProvider);

    // Bookings (prenotazioni con note/clientName)
    ref.invalidate(bookingsProvider);

    // Resources
    ref.invalidate(resourcesProvider);

    // Time Blocks
    ref.invalidate(timeBlocksProvider);

    // Availability Exceptions
    ref.invalidate(availabilityExceptionsProvider);

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

    // Business ID corrente (currentBusinessProvider è derivato, si aggiorna da solo)
    ref.invalidate(currentBusinessIdProvider);

    // Layout e UI state (per sicurezza, anche se sembrano UI-only)
    ref.invalidate(layoutConfigProvider);
    ref.invalidate(agendaDateProvider);
    ref.invalidate(agendaScrollProvider);
    ref.invalidate(initialScrollDoneProvider);
    ref.invalidate(agendaVerticalOffsetProvider);
  }
}

final superadminSelectedBusinessProvider =
    NotifierProvider<SuperadminSelectedBusinessNotifier, int?>(
      SuperadminSelectedBusinessNotifier.new,
    );
