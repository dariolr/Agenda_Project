import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/staff_filter_mode.dart';
import '../../services/providers/services_provider.dart';
import '../../staff/providers/staff_planning_provider.dart';
import '../../staff/providers/staff_providers.dart';
import 'appointment_providers.dart';
import 'business_providers.dart';
import 'layout_config_provider.dart';
import 'location_providers.dart';
import 'staff_filter_providers.dart';

/// Bootstrap condiviso dell'agenda (contenuti + controlli top).
///
/// `true` finché i dati iniziali non sono pronti.
final agendaBootstrapLoadingProvider = Provider<bool>((ref) {
  final staffAsync = ref.watch(allStaffProvider);
  final locations = ref.watch(locationsProvider);
  final locationsLoaded = ref.watch(locationsLoadedProvider);
  final currentLocationId = ref.watch(currentLocationIdProvider);
  final appointmentsAsync = ref.watch(appointmentsProvider);
  final currentBusinessId = ref.watch(currentBusinessIdProvider);
  final staffInCurrentLocation = ref.watch(staffForCurrentLocationProvider);
  final staffPlannings = ref.watch(staffPlanningsProvider);
  final staffFilterMode = ref.watch(staffFilterModeProvider);
  final layoutConfig = ref.watch(layoutConfigProvider);
  final serviceVariantsAsync = ref.watch(serviceVariantsProvider);
  final variants = serviceVariantsAsync.value ?? const [];

  final hasLocations = locations.isNotEmpty;
  final isWaitingForBusiness = currentBusinessId <= 0;
  final isWaitingForLocations = !locationsLoaded;
  final isWaitingForLocationSelection =
      locationsLoaded && hasLocations && currentLocationId == 0;

  final isInitialStaffLoad =
      staffAsync.isLoading && (staffAsync.asData?.value.isEmpty ?? true);
  final isInitialAppointmentsLoad =
      appointmentsAsync.isLoading &&
      (appointmentsAsync.asData?.value.isEmpty ?? true);

  final isPlanningBootstrapLoading =
      staffFilterMode == StaffFilterMode.onDutyTeam &&
      staffInCurrentLocation.isNotEmpty &&
      staffInCurrentLocation.any(
        (staff) =>
            !staffPlannings.containsKey(staff.id) &&
            ref.watch(ensureStaffPlanningLoadedProvider(staff.id)).isLoading,
      );

  final hasStaleVariantsForCurrentLocation =
      currentLocationId > 0 &&
      variants.isNotEmpty &&
      variants.any((variant) => variant.locationId != currentLocationId);
  final isServiceVariantsBootstrapLoading =
      layoutConfig.useServiceColorsForAppointments &&
      (serviceVariantsAsync.isLoading || hasStaleVariantsForCurrentLocation);

  return isWaitingForBusiness ||
      isWaitingForLocations ||
      isWaitingForLocationSelection ||
      isInitialStaffLoad ||
      isInitialAppointmentsLoad ||
      isPlanningBootstrapLoading ||
      isServiceVariantsBootstrapLoading;
});

/// Gate one-shot per la topbar agenda:
/// resta `false` durante il bootstrap iniziale del business corrente,
/// poi diventa `true` e non torna più `false` sui refresh transitori.
class AgendaBootstrapUnlockedNotifier extends Notifier<bool> {
  int? _lastBusinessId;
  bool _isUnlocked = false;

  @override
  bool build() {
    final businessId = ref.watch(currentBusinessIdProvider);
    final isLoading = ref.watch(agendaBootstrapLoadingProvider);

    if (_lastBusinessId != businessId) {
      _lastBusinessId = businessId;
      _isUnlocked = false;
    }

    if (businessId > 0 && !isLoading) {
      _isUnlocked = true;
    }

    return _isUnlocked;
  }
}

final agendaBootstrapUnlockedProvider =
    NotifierProvider<AgendaBootstrapUnlockedNotifier, bool>(
      AgendaBootstrapUnlockedNotifier.new,
    );
