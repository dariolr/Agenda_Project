import 'package:agenda_backend/core/l10n/l10n.dart';
import 'package:agenda_backend/core/models/location.dart';
import 'package:agenda_backend/core/models/service.dart';
import 'package:agenda_backend/core/models/staff.dart';
import 'package:agenda_backend/core/models/user.dart';
import 'package:agenda_backend/features/agenda/providers/location_providers.dart';
import 'package:agenda_backend/features/agenda/providers/tenant_time_provider.dart';
import 'package:agenda_backend/features/auth/domain/auth_state.dart';
import 'package:agenda_backend/features/auth/providers/auth_provider.dart';
import 'package:agenda_backend/features/reports/presentation/reports_screen.dart';
import 'package:agenda_backend/features/reports/providers/reports_filter_provider.dart';
import 'package:agenda_backend/features/reports/providers/reports_provider.dart';
import 'package:agenda_backend/features/services/providers/services_provider.dart';
import 'package:agenda_backend/features/staff/providers/staff_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState.authenticated(
      User(
        id: 1,
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }
}

class _FakeLocationsNotifier extends LocationsNotifier {
  _FakeLocationsNotifier(this._locations);

  final List<Location> _locations;

  @override
  List<Location> build() => _locations;
}

class _FakeServicesNotifier extends ServicesNotifier {
  @override
  Future<List<Service>> build() async => const <Service>[];
}

class _FakeStaffNotifier extends StaffNotifier {
  @override
  Future<List<Staff>> build() async => const <Staff>[];
}

class _FakeReportsNotifier extends ReportsNotifier {
  @override
  ReportsState build() => const ReportsState();

  @override
  Future<void> fetchReport(ReportParams params) async {
    state = ReportsState(params: params, isLoading: false);
  }
}

class _FakeWorkHoursReportNotifier extends WorkHoursReportNotifier {
  @override
  WorkHoursReportState build() => const WorkHoursReportState();

  @override
  Future<void> fetchReport(ReportParams params) async {
    state = WorkHoursReportState(params: params, isLoading: false);
  }
}

void main() {
  testWidgets(
    'reports screen applies week range coming from agenda launch request',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final location = Location(
        id: 7,
        businessId: 11,
        name: 'Roma',
        isDefault: true,
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_FakeAuthNotifier.new),
          locationsProvider.overrideWith(() => _FakeLocationsNotifier([location])),
          currentLocationProvider.overrideWith((ref) => location),
          tenantTodayProvider.overrideWith((ref) => DateTime(2026, 3, 13)),
          tenantNowProvider.overrideWith((ref) => DateTime(2026, 3, 13, 10)),
          servicesProvider.overrideWith(_FakeServicesNotifier.new),
          allStaffProvider.overrideWith(_FakeStaffNotifier.new),
          reportsProvider.overrideWith(_FakeReportsNotifier.new),
          workHoursReportProvider.overrideWith(
            _FakeWorkHoursReportNotifier.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(agendaReportLaunchProvider.notifier).request(
        startDate: DateTime(2026, 3, 9),
        endDate: DateTime(2026, 3, 15),
        locationId: location.id,
      );

      final router = GoRouter(
        initialLocation: '/report',
        routes: [
          GoRoute(
            path: '/report',
            builder: (context, state) =>
                const Scaffold(body: ReportsScreen()),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('it'),
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: L10n.delegate.supportedLocales,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final filterState = container.read(reportsFilterProvider);
      expect(filterState.startDate, DateTime(2026, 3, 9));
      expect(filterState.endDate, DateTime(2026, 3, 15));

      final reportsState = container.read(reportsProvider);
      expect(reportsState.params?.startDate, DateTime(2026, 3, 9));
      expect(reportsState.params?.endDate, DateTime(2026, 3, 15));
      expect(reportsState.params?.locationIds, <int>[location.id]);
    },
  );
}
