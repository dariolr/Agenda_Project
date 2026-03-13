import 'package:agenda_backend/core/l10n/l10n.dart';
import 'package:agenda_backend/core/models/booking_payment.dart';
import 'package:agenda_backend/core/models/booking_payment_computed.dart';
import 'package:agenda_backend/core/models/booking_payment_line.dart';
import 'package:agenda_backend/features/agenda/presentation/dialogs/payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'payment dialog shows booking base amount from initial payment totalDueCents',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const initialPayment = BookingPayment(
        bookingId: 1,
        clientId: 1,
        isActive: true,
        currency: 'EUR',
        totalDueCents: 3000,
        note: null,
        lines: [
          BookingPaymentLine(
            type: BookingPaymentLineType.discount,
            amountCents: 1000,
            meta: {'source': 'appointment_amount_adjustment'},
          ),
        ],
        computed: BookingPaymentComputed(
          totalPaidCents: 0,
          totalDiscountCents: 0,
          balanceCents: 0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('it'),
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: L10n.delegate.supportedLocales,
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton(
                        onPressed: () {
                          showPaymentDialog(
                            context,
                            ref,
                            totalPrice: 20,
                            currencyCode: 'EUR',
                            bookingId: 1,
                            initialPayment: initialPayment,
                          );
                        },
                        child: const Text('open'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Importo prenotazione'), findsOneWidget);

      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.first.controller?.text, '30,00');
      expect(
        fields
            .map((field) => field.controller?.text)
            .whereType<String>()
            .contains('10,00'),
        isTrue,
      );
    },
  );
}
