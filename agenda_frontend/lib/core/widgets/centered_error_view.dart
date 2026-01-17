import 'package:flutter/material.dart';

class CenteredErrorView extends StatelessWidget {
  const CenteredErrorView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.retryLabel,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox.expand(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: colorScheme.error.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel ?? 'Riprova'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
