import 'package:flutter/material.dart';

import '../../../core/models/appointment.dart';

const int _noClientColorSeed = -1;
const int _hueBuckets = 18;
const double _hueStep = 360 / _hueBuckets; // 20°
const List<double> _saturationVariants = [0.68, 0.78, 0.58];
const List<double> _lightnessVariantsLight = [0.58, 0.50, 0.64];
const List<double> _lightnessVariantsDark = [0.56, 0.50, 0.62];

Color resolveClientColorForAppointment(
  BuildContext context,
  Appointment appointment,
) {
  final seed = appointment.clientId ?? _noClientColorSeed;
  final hash = _stableHash(seed);
  final hueBucket = hash % _hueBuckets;
  // Permutazione dei bucket per evitare vicinanza cromatica frequente
  final permutedBucket = (hueBucket * 11) % _hueBuckets;
  final hue = permutedBucket * _hueStep;

  final variantIndex = (hash ~/ _hueBuckets) % _saturationVariants.length;
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
