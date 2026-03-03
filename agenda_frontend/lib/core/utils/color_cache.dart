import 'package:flutter/material.dart';

import 'color_cache_stub.dart'
    if (dart.library.html) 'color_cache_web.dart';

const _prefix = 'agenda_primary_color_';

Color? loadCachedBusinessColor(String slug) {
  final hex = colorCacheGet('$_prefix$slug');
  if (hex == null || hex.isEmpty) return null;
  final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

void saveCachedBusinessColor(String slug, Color color) {
  final hex = '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  colorCacheSet('$_prefix$slug', hex);
}
