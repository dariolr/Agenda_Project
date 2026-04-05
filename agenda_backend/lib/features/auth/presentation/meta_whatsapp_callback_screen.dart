import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/core/l10n/l10_extension.dart';

class MetaWhatsappCallbackScreen extends StatelessWidget {
  const MetaWhatsappCallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.whatsappEmbeddedSignupSuccessTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 56),
                const SizedBox(height: 12),
                Text(
                  l10n.whatsappEmbeddedSignupSuccessTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.whatsappEmbeddedSignupHint,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: Text(l10n.actionClose),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
