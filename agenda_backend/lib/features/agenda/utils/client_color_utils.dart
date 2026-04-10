import 'package:flutter/material.dart';

import '../../../core/models/appointment.dart';

const int _noClientColorSeed = -1;
// Hue sequence intentionally ordered to maximize contrast between neighbors.
const List<double> _hueSequence = [
  0,
  210,
  120,
  40,
  285,
  165,
  330,
  80,
  250,
  20,
  140,
  300,
  190,
  55,
  265,
  100,
  355,
  230,
];
const List<double> _saturationVariants = [0.68, 0.78, 0.58];
const List<double> _lightnessVariantsLight = [0.58, 0.50, 0.64];
const List<double> _lightnessVariantsDark = [0.56, 0.50, 0.62];

Color resolveClientColorForAppointment(
  BuildContext context,
  Appointment appointment,
) {
  final seed = appointment.clientId ?? _noClientColorSeed;
  final hash = _stableHash(seed);
  final hueIndex = hash % _hueSequence.length;
  var hue = _hueSequence[hueIndex];

  // Small deterministic offset reduces collisions when different clients map
  // to the same base hue bucket.
  final offsetIndex = (hash ~/ _hueSequence.length) % 7; // 0..6
  final hueOffset = (offsetIndex - 3) * 2.5; // -7.5..+7.5
  hue = (hue + hueOffset) % 360;
  if (hue < 0) hue += 360;

  final variantIndex = (hash ~/ _hueSequence.length) % _saturationVariants.length;
  final saturation = _saturationVariants[variantIndex];
  final lightnessOptions = Theme.of(context).brightness == Brightness.dark
      ? _lightnessVariantsDark
      : _lightnessVariantsLight;
  final lightness = lightnessOptions[variantIndex];

  return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
}

int _stableHash(int value) {
  var x = value;
  x = ((x >> 16) ^ x) * 0x45d9f3b;
  x = ((x >> 16) ^ x) * 0x45d9f3b;
  x = (x >> 16) ^ x;
  return x & 0x7fffffff;
}
