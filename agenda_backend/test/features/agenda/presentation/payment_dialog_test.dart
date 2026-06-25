import 'package:agenda_backend/core/l10n/l10n.dart';
import 'package:agenda_backend/core/models/booking_payment.dart';
import 'package:agenda_backend/core/models/booking_payment_computed.dart';
import 'package:agenda_backend/core/models/booking_payment_line.dart';
import 'package:agenda_backend/features/agenda/presentation/dialogs/payment_dialog.dart';
import 'package:agenda_backend/features/agenda/providers/booking_payment_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('payment dialog ignores legacy auto discount in discount field', (
    tester,
  ) async {
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
          theme: ThemeData(
            useMaterial3: false,
            splashFactory: NoSplash.splashFactory,
          ),
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

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.first.controller?.text, '30,00');
    expect(
      fields
          .map((field) => field.controller?.text)
          .whereType<String>()
          .contains('10,00'),
      isFalse,
    );
  });

  testWidgets(
    'payment dialog normalizes loaded payment to current applied total',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const loadedPayment = BookingPayment(
        bookingId: 1,
        clientId: 1,
        isActive: true,
        currency: 'EUR',
        totalDueCents: 10000,
        note: null,
        lines: [
          BookingPaymentLine(
            type: BookingPaymentLineType.cash,
            amountCents: 3000,
          ),
          BookingPaymentLine(
            type: BookingPaymentLineType.voucher,
            amountCents: 500,
          ),
          BookingPaymentLine(
            type: BookingPaymentLineType.discount,
            amountCents: 2000,
            meta: {'source': 'appointment_amount_adjustment'},
          ),
          BookingPaymentLine(
            type: BookingPaymentLineType.discount,
            amountCents: 1000,
            meta: {'source': 'manual'},
          ),
        ],
        computed: BookingPaymentComputed(
          totalPaidCents: 3500,
          totalDiscountCents: 3000,
          balanceCents: 3500,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingPaymentProvider(
              1,
            ).overrideWith((ref) async => loadedPayment),
          ],
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: false,
              splashFactory: NoSplash.splashFactory,
            ),
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
                            totalPrice: 80,
                            currencyCode: 'EUR',
                            bookingId: 1,
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

      final fieldValues = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.controller?.text)
          .whereType<String>()
          .toList();

      expect(fieldValues.first, '80,00');
      expect(fieldValues, contains('30,00'));
      expect(fieldValues, contains('5,00'));
      expect(fieldValues, contains('10,00'));
      expect(fieldValues, isNot(contains('20,00')));
    },
  );
}
