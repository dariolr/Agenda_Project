import 'package:agenda_frontend/features/booking/presentation/widgets/booking_formatted_message_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseBookingBoldMessage', () {
    test('returns no segments for empty text', () {
      expect(parseBookingBoldMessage(''), isEmpty);
    });

    test('returns one normal segment without bold markers', () {
      expect(parseBookingBoldMessage('Presentarsi 10 minuti prima.'), [
        const BookingMessageSegment(
          text: 'Presentarsi 10 minuti prima.',
          isBold: false,
        ),
      ]);
    });

    test('parses one bold segment', () {
      expect(parseBookingBoldMessage('Presentati **10 minuti prima**.'), [
        const BookingMessageSegment(text: 'Presentati ', isBold: false),
        const BookingMessageSegment(text: '10 minuti prima', isBold: true),
        const BookingMessageSegment(text: '.', isBold: false),
      ]);
    });

    test('parses multiple bold segments', () {
      expect(parseBookingBoldMessage('**Importante:** porta **documento**.'), [
        const BookingMessageSegment(text: 'Importante:', isBold: true),
        const BookingMessageSegment(text: ' porta ', isBold: false),
        const BookingMessageSegment(text: 'documento', isBold: true),
        const BookingMessageSegment(text: '.', isBold: false),
      ]);
    });

    test('keeps an unclosed marker as normal text', () {
      expect(parseBookingBoldMessage('Questo e **un testo non chiuso'), [
        const BookingMessageSegment(
          text: 'Questo e **un testo non chiuso',
          isBold: false,
        ),
      ]);
    });

    test('keeps empty markers as normal text', () {
      expect(parseBookingBoldMessage('Prima **** dopo'), [
        const BookingMessageSegment(text: 'Prima ****', isBold: false),
        const BookingMessageSegment(text: ' dopo', isBold: false),
      ]);
    });

    test('keeps HTML as normal text', () {
      const html = '<b>Importante</b> <script>alert(1)</script>';
      expect(parseBookingBoldMessage(html), [
        const BookingMessageSegment(text: html, isBold: false),
      ]);
    });

    test('preserves line breaks, accents and emoji', () {
      expect(
        parseBookingBoldMessage('**È importante** arrivare presto 😊\nOk'),
        [
          const BookingMessageSegment(text: 'È importante', isBold: true),
          const BookingMessageSegment(
            text: ' arrivare presto 😊\nOk',
            isBold: false,
          ),
        ],
      );
    });
  });
}
