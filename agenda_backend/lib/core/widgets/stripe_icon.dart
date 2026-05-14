import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StripeIcon extends StatelessWidget {
  const StripeIcon({super.key, this.size = 24.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/stripe-blurple.svg',
      width: size,
      height: size,
    );
  }
}
