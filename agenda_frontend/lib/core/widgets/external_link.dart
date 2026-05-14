import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

/// Wraps [builder] in a [Link] that opens [url] in a new browser tab.
///
/// If [url] is null or not a valid absolute HTTP/HTTPS URI, [builder] receives
/// a null callback so the caller can render a disabled state.
class ExternalLink extends StatelessWidget {
  const ExternalLink({super.key, required this.url, required this.builder});

  final String? url;
  final Widget Function(BuildContext context, VoidCallback? open) builder;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url ?? '');
    final valid = uri != null && uri.hasScheme && uri.host.isNotEmpty;
    if (!valid) return builder(context, null);
    return Link(
      uri: uri,
      target: LinkTarget.blank,
      builder: (ctx, followLink) => builder(ctx, followLink),
    );
  }
}

/// A [FilledButton] (or tonal variant) that opens [url] in a new tab.
///
/// Renders a spinner instead of [icon] while [loading] is true.
/// Disabled when [url] is null/invalid or while [loading].
class ExternalLinkButton extends StatelessWidget {
  const ExternalLinkButton({
    super.key,
    required this.url,
    required this.icon,
    required this.label,
    this.onOpened,
    this.loading = false,
    this.tonal = false,
  });

  final String? url;
  final IconData icon;
  final String label;
  final VoidCallback? onOpened;
  final bool loading;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = loading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon);

    return ExternalLink(
      url: loading ? null : url,
      builder: (ctx, open) {
        final onPressed = open != null
            ? () {
                onOpened?.call();
                open();
              }
            : null;
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
      },
    );
  }
}
