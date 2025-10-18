import 'package:flutter/material.dart';

import '../../../core/l10n/l10_extension.dart'; // 🌍

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.servicesTitle, // 🌍
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
