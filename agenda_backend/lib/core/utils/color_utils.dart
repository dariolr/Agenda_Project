import 'package:flutter/material.dart';

class ColorUtils {
  /// Restituisce il colore in formato esadecimale '#RRGGBB' (senza alpha)
  static String toHex(Color color) {
    final int argb = color.toARGB32();
    // Prendi solo gli ultimi 6 caratteri (RGB, ignora alpha)
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// Converte una stringa esadecimale '#AARRGGBB' o '#RRGGBB' in un Color
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    // Se 6 caratteri (o 7 con #), aggiungi alpha FF
    if (hexString.length == 6 || hexString.length == 7) buffer.write('FF');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
