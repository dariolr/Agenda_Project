import 'package:flutter/material.dart';

// Palette originale mantenuta per utilizzo futuro.
const List<Color> serviceColorPaletteLegacy = [
  // Reds
  Color(0xFFFFCDD2),
  Color(0xFFFFC1C9),
  Color(0xFFFFB4BC),
  // Oranges
  Color(0xFFFFD6B3),
  Color(0xFFFFC9A3),
  Color(0xFFFFBD93),
  // Yellows
  Color(0xFFFFF0B3),
  Color(0xFFFFE6A3),
  Color(0xFFFFDC93),
  // Yellow-greens
  Color(0xFFEAF2B3),
  Color(0xFFDFEAA3),
  Color(0xFFD4E293),
  // Greens
  Color(0xFFCDECCF),
  Color(0xFFC1E4C4),
  Color(0xFFB6DCB9),
  // Teals
  Color(0xFFBFE8E0),
  Color(0xFFB1DFD6),
  Color(0xFFA3D6CB),
  // Cyans
  Color(0xFFBDEFF4),
  Color(0xFFB0E6EF),
  Color(0xFFA3DDEA),
  // Blues
  Color(0xFFBFD9FF),
  Color(0xFFB0CEFF),
  Color(0xFFA1C3FF),
  // Indigos
  Color(0xFFC7D0FF),
  Color(0xFFBAC4FF),
  Color(0xFFADB8FF),
  // Purples
  Color(0xFFDCC9FF),
  Color(0xFFD0BDFF),
  Color(0xFFC4B1FF),
  // Pinks
  Color(0xFFFFC7E3),
  Color(0xFFFFB7D9),
  Color(0xFFFFA8CF),
];

// Palette attiva leggermente più scura per migliorare contrasto nelle card.
const List<Color> serviceColorPaletteEnhanced = [
  // Reds
  Color(0xFFFFB7BC),
  Color(0xFFFFADB5),
  Color(0xFFFFA2AA),
  // Oranges
  Color(0xFFFFC29D),
  Color(0xFFFFB58F),
  Color(0xFFFFAA81),
  // Yellows
  Color(0xFFFFDB9F),
  Color(0xFFFFD290),
  Color(0xFFFFC87F),
  // Yellow-greens
  Color(0xFFD3DA9F),
  Color(0xFFCBD690),
  Color(0xFFC2CE81),
  // Greens
  Color(0xFFB8D8BB),
  Color(0xFFAED0B1),
  Color(0xFFA0C8A6),
  // Teals
  Color(0xFFAAD3CC),
  Color(0xFF9DCCC2),
  Color(0xFF8FC0B5),
  // Cyans
  Color(0xFFA7D9DF),
  Color(0xFF9CD2DB),
  Color(0xFF8EC8D5),
  // Blues
  Color(0xFFAAC4EA),
  Color(0xFF9CB8EA),
  Color(0xFF8EAFE9),
  // Indigos
  Color(0xFFB2BBEA),
  Color(0xFFA6B0EA),
  Color(0xFF99A4E9),
  // Purples
  Color(0xFFC6B4EA),
  Color(0xFFBAA9EA),
  Color(0xFFAE9DE9),
  // Pinks
  Color(0xFFEAB2CE),
  Color(0xFFEAA4C5),
  Color(0xFFE994BB),
];

List<Color> serviceColorPaletteForSetting(String setting) {
  switch (setting) {
    case 'enhanced':
      return serviceColorPaletteEnhanced;
    case 'legacy':
    default:
      return serviceColorPaletteLegacy;
  }
}
