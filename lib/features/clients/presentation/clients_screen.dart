import 'package:flutter/material.dart';

import '../../../core/l10n/l10_extension.dart'; // 🌍

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ❗️ Niente Scaffold o AppBar
    return Center(
      child: Text(
        context.l10n.clientsTitle, // 🌍
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
