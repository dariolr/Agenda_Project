import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

class BillingExternalLink extends StatelessWidget {
  const BillingExternalLink({
    super.key,
    required this.url,
    required this.icon,
    required this.label,
    this.onActivated,
    this.loading = false,
    this.tonal = false,
  });

  final String? url;
  final IconData icon;
  final String label;
  final VoidCallback? onActivated;
  final bool loading;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url ?? '');
    final enabled =
        !loading && uri != null && uri.hasScheme && uri.host.isNotEmpty;
    final effectiveIcon = loading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon);

    if (!enabled) {
      return _buildButton(context, null, effectiveIcon);
    }

    return Link(
      uri: uri,
      target: LinkTarget.blank,
      builder: (context, followLink) {
        return _buildButton(context, () {
          onActivated?.call();
          followLink?.call();
        }, effectiveIcon);
      },
    );
  }

  Widget _buildButton(
    BuildContext context,
    VoidCallback? onPressed,
    Widget effectiveIcon,
  ) {
    if (tonal) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: effectiveIcon,
        label: Text(label),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: effectiveIcon,
      label: Text(label),
    );
  }
}
