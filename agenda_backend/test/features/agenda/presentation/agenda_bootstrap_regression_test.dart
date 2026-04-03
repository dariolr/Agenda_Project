import 'package:agenda_backend/core/l10n/l10n.dart';
import 'package:agenda_backend/core/models/appointment.dart';
import 'package:agenda_backend/core/models/availability_exception.dart';
import 'package:agenda_backend/core/models/location.dart';
import 'package:agenda_backend/core/models/service_variant.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/models/staff_planning.dart';
import 'package:agenda_backend/core/services/preferences_service.dart';
import 'package:agenda_backend/features/agenda/domain/staff_filter_mode.dart';
import 'package:agenda_backend/features/agenda/presentation/agenda_screen.dart';
import 'package:agenda_backend/features/agenda/providers/agenda_display_settings_provider.dart';
import 'package:agenda_backend/features/agenda/providers/appointment_providers.dart';
import 'package:agenda_backend/features/agenda/providers/booking_reschedule_capability_provider.dart';
import 'package:agenda_backend/features/agenda/providers/business_providers.dart';
import 'package:agenda_backend/features/agenda/providers/calendar_view_mode_provider.dart';
import 'package:agenda_backend/features/agenda/providers/date_range_provider.dart';
import 'package:agenda_backend/features/agenda/providers/initial_scroll_provider.dart';
import 'package:agenda_backend/features/agenda/providers/location_providers.dart';
import 'package:agenda_backend/features/agenda/providers/staff_filter_providers.dart';
import 'package:agenda_backend/features/agenda/providers/staff_slot_availability_provider.dart';
import 'package:agenda_backend/features/agenda/providers/tenant_time_provider.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:agenda_backend/features/staff/providers/availability_exceptions_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_planning_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

class _TestCurrentBusinessId extends CurrentBusinessId {
  @override
  int build() => 11;
}

class _TestCurrentLocationId extends CurrentLocationId {
  @override
  int build() => 7;
}

class _TestLocationsNotifier extends LocationsNotifier {
  _TestLocationsNotifier(this._locations);

  final List<Location> _locations;

  @override
  List<Location> build() => _locations;
}

class _TestStaffNotifier extends StaffNotifier {
  _TestStaffNotifier(this._staff);

  final List<Staff> _staff;

  @override
  Future<List<Staff>> build() async => _staff;
}

class _TestAppointmentsNotifier extends AppointmentsNotifier {
  @override
  Future<List<Appointment>> build() async => const <Appointment>[];
}

class _TestServiceVariantsNotifier extends ServiceVariantsNotifier {
  @override
  Future<List<ServiceVariant>> build() async => const <ServiceVariant>[];
}

class _TestStaffPlanningsNotifier extends StaffPlanningsNotifier {
  @override
  Map<int, List<StaffPlanning>> build() => const <int, List<StaffPlanning>>{};
}

class _TestStaffFilterModeNotifier extends StaffFilterModeNotifier {
  @override
  StaffFilterMode build() => StaffFilterMode.allTeam;
}

class _TestCalendarViewModeNotifier extends CalendarViewModeNotifier {
  @override
  CalendarViewMode build() => CalendarViewMode.day;
}

class _TestAgendaDateNotifier extends AgendaDateNotifier {
  @override
  DateTime build() => DateTime(2026, 4, 3);
}

class _TestAvailabilityExceptionsNotifier extends AvailabilityExceptionsNotifier {
  @override
  Future<Map<int, List<AvailabilityException>>> build() async =>
      const <int, List<AvailabilityException>>{};

  @override
  Future<void> loadExceptionsForStaff(
    int staffId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {}
}

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  testWidgets(
    'Agenda bootstrap keeps local loader during defer and reveals content only after initial scroll is done',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const location = Location(
        id: 7,
        businessId: 11,
        name: 'Roma Centro',
        isDefault: true,
      );
      const staff = Staff(
        id: 19,
        businessId: 11,
        name: 'Patrizia',
        surname: 'Franco',
        color: Colors.pink,
        locationIds: <int>[7],
      );
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentBusinessIdProvider.overrideWith(_TestCurrentBusinessId.new),
          currentLocationIdProvider.overrideWith(_TestCurrentLocationId.new),
          locationsProvider.overrideWith(() => _TestLocationsNotifier([location])),
          locationsLoadedProvider.overrideWith((ref) => true),
          allStaffProvider.overrideWith(() => _TestStaffNotifier([staff])),
          filteredStaffProvider.overrideWith((ref) => const <Staff>[staff]),
          staffForCurrentLocationProvider.overrideWith(
            (ref) => const <Staff>[staff],
          ),
          appointmentsProvider.overrideWith(_TestAppointmentsNotifier.new),
          serviceVariantsProvider.overrideWith(_TestServiceVariantsNotifier.new),
          staffPlanningsProvider.overrideWith(_TestStaffPlanningsNotifier.new),
          staffFilterModeProvider.overrideWith(_TestStaffFilterModeNotifier.new),
          calendarViewModeProvider.overrideWith(
            _TestCalendarViewModeNotifier.new,
          ),
          agendaDateProvider.overrideWith(_TestAgendaDateNotifier.new),
          canUseBookingRescheduleProvider.overrideWith((ref) => true),
          effectiveUseServiceColorsForAppointmentsProvider.overrideWith(
            (ref) => false,
          ),
          effectiveTenantTimezoneProvider.overrideWith((ref) => 'Europe/Rome'),
          availabilityExceptionsProvider.overrideWith(
            _TestAvailabilityExceptionsNotifier.new,
          ),
          unavailableSlotRangesProvider.overrideWith(
            (ref, staffId) => const <({int startIndex, int count})>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('it'),
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: L10n.delegate.supportedLocales,
            home: const Scaffold(body: AgendaScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Anti-regressione: durante il defer della viewport il loader locale deve restare visibile.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Quando lo scroll iniziale è completato, la viewport deve apparire e il loader sparire.
      container.read(initialScrollDoneProvider.notifier).markDone();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
