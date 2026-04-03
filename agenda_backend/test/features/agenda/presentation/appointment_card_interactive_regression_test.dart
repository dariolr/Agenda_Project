import 'package:agenda_backend/core/models/appointment.dart';
import 'package:agenda_backend/features/agenda/presentation/screens/widgets/appointment_card_interactive.dart';
import 'package:agenda_backend/features/agenda/providers/agenda_display_settings_provider.dart';
import 'package:agenda_backend/features/agenda/providers/agenda_interaction_lock_provider.dart';
import 'package:agenda_backend/features/auth/providers/current_business_user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'AppointmentCardInteractive does not crash when appointment.price is null',
    (tester) async {
      final appointment = Appointment(
        id: 1,
        bookingId: 10,
        businessId: 3,
        locationId: 3,
        staffId: 19,
        serviceId: 372,
        serviceVariantId: 370,
        clientName: 'Pausa Pausa',
        serviceName: 'Pausa - Free',
        startTime: DateTime(2026, 7, 3, 12, 0),
        endTime: DateTime(2026, 7, 3, 12, 30),
        price: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectiveShowAppointmentPriceInCardProvider.overrideWith(
              (ref) => true,
            ),
            agendaCardColorOpacityProvider.overrideWith((ref) => 0.85),
            agendaExtraMinutesBandIntensityProvider.overrideWith(
              (ref) => 0.25,
            ),
            agendaHoverUnrelatedCardDimIntensityProvider.overrideWith(
              (ref) => 0.0,
            ),
            agendaCardTextScaleProvider.overrideWith((ref) => 1.0),
            currentUserCanManageBookingsProvider.overrideWith((ref) => false),
            agendaCardHoverProvider.overrideWith(_TestAgendaCardHoverNotifier.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 180,
                  height: 56,
                  child: AppointmentCardInteractive(
                    appointment: appointment,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(AppointmentCardInteractive), findsOneWidget);
    },
  );
}

class _TestAgendaCardHoverNotifier extends AgendaCardHoverNotifier {
  @override
  bool build() => false;

  @override
  void enter() {}

  @override
  void exit() {}
}
