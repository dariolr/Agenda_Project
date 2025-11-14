import 'package:flutter/material.dart';

/// Widget riutilizzabile per i casi in cui una categoria non contiene servizi.
class ServicesEmptyState extends StatelessWidget {
  final String message;

  const ServicesEmptyState({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: textStyle?.copyWith(
                color: textStyle.color?.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
