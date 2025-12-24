import 'package:flutter/material.dart';

class ColorUtils {
  /// Restituisce il colore in formato esadecimale '#AARRGGBB'
  static String toHex(Color color) {
    final int argb = color.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// Converte una stringa esadecimale '#AARRGGBB' o '#RRGGBB' in un Color
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('FF');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
