import 'package:agenda_backend/core/models/booking_payment.dart';
import 'package:agenda_backend/core/models/booking_payment_computed.dart';
import 'package:agenda_backend/core/models/booking_payment_line.dart';
import 'package:agenda_backend/core/models/service_variant.dart';
import 'package:agenda_backend/features/agenda/domain/booking_payment_preview.dart';
import 'package:agenda_backend/features/agenda/domain/service_item_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildBookingPaymentPreview', () {
    test('new booking with single service keeps original base and auto discount', () {
      final preview = buildBookingPaymentPreview(
        bookingId: 0,
        clientId: 10,
        currency: 'EUR',
        referenceTotalCents: 3000,
        currentTotalCents: 2000,
      );

      expect(preview.totalDueCents, 3000);
      expect(preview.lines, hasLength(1));
      expect(preview.lines.single.type, BookingPaymentLineType.discount);
      expect(preview.lines.single.amountCents, 1000);
      expect(
        preview.lines.single.meta?['source'],
        bookingPaymentAutoDiscountSourceTag,
      );
    });

    test('new booking with multi service keeps summed original base and auto discount', () {
      final preview = buildBookingPaymentPreview(
        bookingId: 0,
        clientId: 10,
        currency: 'EUR',
        referenceTotalCents: 7000,
        currentTotalCents: 5000,
      );

      expect(preview.totalDueCents, 7000);
      expect(preview.lines, hasLength(1));
      expect(preview.lines.single.type, BookingPaymentLineType.discount);
      expect(preview.lines.single.amountCents, 2000);
    });

    test('editing existing booking rebuilds auto discount and preserves manual discount', () {
      const persisted = BookingPayment(
        bookingId: 99,
        clientId: 11,
        isActive: true,
        currency: 'EUR',
        totalDueCents: 7000,
        note: 'keep',
        lines: [
          BookingPaymentLine(
            type: BookingPaymentLineType.discount,
            amountCents: 700,
            meta: {'source': 'appointment_amount_adjustment'},
          ),
          BookingPaymentLine(
            type: BookingPaymentLineType.discount,
            amountCents: 500,
            meta: {'source': 'manual'},
          ),
        ],
        computed: BookingPaymentComputed(
          totalPaidCents: 0,
          totalDiscountCents: 0,
          balanceCents: 0,
        ),
      );

      final preview = buildBookingPaymentPreview(
        bookingId: 99,
        clientId: 11,
        currency: 'EUR',
        referenceTotalCents: 7000,
        currentTotalCents: 5000,
        basePayment: persisted,
      );

      expect(preview.totalDueCents, 7000);
      expect(preview.note, 'keep');
      expect(preview.lines, hasLength(2));

      final manual = preview.lines.firstWhere(
        (line) => line.meta?['source'] == bookingPaymentManualDiscountSourceTag,
      );
      final auto = preview.lines.firstWhere(
        (line) => line.meta?['source'] == bookingPaymentAutoDiscountSourceTag,
      );

      expect(manual.amountCents, 500);
      expect(auto.amountCents, 2000);
    });
  });

  group('paymentExceedsCurrentDue', () {
    test('returns true when non-discount payment coverage exceeds current due', () {
      const payment = BookingPayment(
        bookingId: 1,
        clientId: 1,
        isActive: true,
        currency: 'EUR',
        totalDueCents: 3000,
        note: null,
        lines: [
          BookingPaymentLine(
            type: BookingPaymentLineType.cash,
            amountCents: 1500,
          ),
          BookingPaymentLine(
            type: BookingPaymentLineType.voucher,
            amountCents: 1000,
          ),
          BookingPaymentLine(
            type: BookingPaymentLineType.discount,
            amountCents: 900,
            meta: {'source': 'manual'},
          ),
        ],
        computed: BookingPaymentComputed(
          totalPaidCents: 0,
          totalDiscountCents: 0,
          balanceCents: 0,
        ),
      );

      expect(
        paymentExceedsCurrentDue(payment: payment, currentTotalCents: 2000),
        isTrue,
      );
    });

    test('ignores discount when checking if payment exceeds current due', () {
      const payment = BookingPayment(
        bookingId: 1,
        clientId: 1,
        isActive: true,
        currency: 'EUR',
        totalDueCents: 3000,
        note: null,
        lines: [
          BookingPaymentLine(
            type: BookingPaymentLineType.cash,
            amountCents: 1000,
          ),
          BookingPaymentLine(
            type: BookingPaymentLineType.discount,
            amountCents: 2000,
            meta: {'source': 'manual'},
          ),
        ],
        computed: BookingPaymentComputed(
          totalPaidCents: 0,
          totalDiscountCents: 0,
          balanceCents: 0,
        ),
      );

      expect(
        paymentExceedsCurrentDue(payment: payment, currentTotalCents: 1000),
        isFalse,
      );
    });
  });

  group('computeServiceItemsTotalCents', () {
    test('uses custom prices when present and variant prices otherwise', () {
      final total = computeServiceItemsTotalCents(
        items: const [
          ServiceItemData(
            key: '1',
            serviceId: 1,
            serviceVariantId: 11,
            staffId: 1,
            startTime: TimeOfDay(hour: 10, minute: 0),
            price: 20,
          ),
          ServiceItemData(
            key: '2',
            serviceId: 2,
            serviceVariantId: 22,
            staffId: 1,
            startTime: TimeOfDay(hour: 10, minute: 30),
          ),
        ],
        variants: const [
          ServiceVariant(
            id: 11,
            serviceId: 1,
            locationId: 1,
            durationMinutes: 30,
            price: 30,
          ),
          ServiceVariant(
            id: 22,
            serviceId: 2,
            locationId: 1,
            durationMinutes: 30,
            price: 15,
          ),
        ],
      );

      expect(total, 3500);
    });
  });
}
