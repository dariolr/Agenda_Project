import 'package:flutter/material.dart';

class BookingMessageSegment {
  const BookingMessageSegment({required this.text, required this.isBold});

  final String text;
  final bool isBold;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BookingMessageSegment &&
            runtimeType == other.runtimeType &&
            text == other.text &&
            isBold == other.isBold;
  }

  @override
  int get hashCode => Object.hash(text, isBold);

  @override
  String toString() {
    return 'BookingMessageSegment(text: $text, isBold: $isBold)';
  }
}

List<BookingMessageSegment> parseBookingBoldMessage(String text) {
  if (text.isEmpty) {
    return const [];
  }

  final segments = <BookingMessageSegment>[];
  var index = 0;

  void addNormal(String value) {
    if (value.isNotEmpty) {
      segments.add(BookingMessageSegment(text: value, isBold: false));
    }
  }

  while (index < text.length) {
    final start = text.indexOf('**', index);
    if (start == -1) {
      addNormal(text.substring(index));
      break;
    }

    final end = text.indexOf('**', start + 2);
    if (end == -1) {
      addNormal(text.substring(index));
      break;
    }

    final boldText = text.substring(start + 2, end);
    if (boldText.isEmpty) {
      addNormal(text.substring(index, end + 2));
      index = end + 2;
      continue;
    }

    addNormal(text.substring(index, start));
    segments.add(BookingMessageSegment(text: boldText, isBold: true));
    index = end + 2;
  }

  return segments;
}

class BookingFormattedMessageText extends StatelessWidget {
  const BookingFormattedMessageText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final spans = parseBookingBoldMessage(text)
        .map(
          (segment) => TextSpan(
            text: segment.text,
            style: segment.isBold
                ? effectiveStyle.copyWith(fontWeight: FontWeight.w600)
                : effectiveStyle,
          ),
        )
        .toList(growable: false);

    return Text.rich(
      TextSpan(children: spans),
      style: effectiveStyle,
      textAlign: textAlign,
    );
  }
}
