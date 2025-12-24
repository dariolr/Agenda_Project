import 'package:flutter/material.dart';
import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/clients.dart';
import '../../providers/clients_providers.dart';
import '../dialogs/client_appointments_dialog.dart';

class ClientCard extends ConsumerWidget {
  const ClientCard({super.key, required this.client, this.onTap});

  final Client client;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    //final tags = client.tags ?? const [];
    final email = client.email;
    final phone = client.phone;
    final isEmailValid = email != null && _isValidEmail(email);
    final isPhoneValid = phone != null && _isValidPhone(phone);
    final emailTap = isEmailValid ? () => _openEmail(email) : null;
    final phoneTap = isPhoneValid ? () => _openPhone(phone) : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StaffCircleAvatar(
                  height: 36,
                  color: scheme.primary,
                  isHighlighted: false,
                  initials: client.name.isNotEmpty
                      ? initialsFromName(client.name, maxChars: 2)
                      : '?',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(client.name, style: theme.textTheme.titleMedium),
                ),
                _DeleteButton(client: client),
              ],
            ),
            const SizedBox(height: 8),
            if (email != null)
              _LinkText(
                text: email,
                onTap: emailTap,
                style: theme.textTheme.bodySmall,
                linkColor: scheme.primary,
              ),
            if (client.email != null && client.phone != null)
              const SizedBox(height: 12),
            if (phone != null)
              _LinkText(
                text: phone,
                onTap: phoneTap,
                style: theme.textTheme.bodySmall,
                linkColor: scheme.primary,
              ),
            // Riga con ultima visita e icona appuntamenti
            Row(
              children: [
                if (client.lastVisit != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _buildLastVisitLabel(context, client.lastVisit!),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                _AppointmentsButton(client: client),
              ],
            ),
            /*
            if (tags.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: -4,
                children: [
                  for (final t in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t, style: theme.textTheme.labelSmall),
                    ),
                ],
              ),
            */
          ],
        ),
      ),
    );
  }

  String _buildLastVisitLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Esempio coerente con altre parti dell'app (e.g. staff widgets): d MMM y
    final formatted = DateFormat('d MMM y', locale).format(date);
    return context.l10n.lastVisitLabel(formatted);
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText({
    required this.text,
    required this.onTap,
    required this.style,
    required this.linkColor,
  });

  final String text;
  final VoidCallback? onTap;
  final TextStyle? style;
  final Color linkColor;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = onTap == null
        ? style
        : style?.copyWith(
                color: linkColor,
                decoration: TextDecoration.underline,
                decorationColor: linkColor,
              ) ??
              TextStyle(
                color: linkColor,
                decoration: TextDecoration.underline,
                decorationColor: linkColor,
              );
    return InkWell(
      onTap: onTap,
      child: Text(text, style: effectiveStyle),
    );
  }
}

bool _isValidEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return false;
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return emailRegex.hasMatch(trimmed);
}

bool _isValidPhone(String phone) {
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return false;
  final normalized = trimmed.replaceAll(RegExp(r'\s+'), '');
  final phoneRegex = RegExp(r'^\+?\d{6,15}$');
  return phoneRegex.hasMatch(normalized);
}

Future<void> _openEmail(String email) async {
  final uri = Uri(scheme: 'mailto', path: email.trim());
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _openPhone(String phone) async {
  final normalized = phone.trim().replaceAll(RegExp(r'\s+'), '');
  final uri = Uri(scheme: 'tel', path: normalized);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _AppointmentsButton extends ConsumerWidget {
  const _AppointmentsButton({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appointments = ref.watch(clientWithAppointmentsProvider(client.id));
    final now = DateTime.now();

    final upcoming = appointments.where((a) => a.startTime.isAfter(now)).length;
    final past = appointments.length - upcoming;
    final total = appointments.length;

    return InkWell(
      onTap: () => showClientAppointmentsDialog(context, ref, client: client),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            if (total > 0) ...[
              const SizedBox(width: 6),
              // Badge appuntamenti futuri (verde)
              if (upcoming > 0)
                _AppointmentBadge(
                  count: upcoming,
                  color: Colors.green,
                  icon: Icons.arrow_upward,
                ),
              if (upcoming > 0 && past > 0) const SizedBox(width: 4),
              // Badge appuntamenti passati (grigio)
              if (past > 0)
                _AppointmentBadge(
                  count: past,
                  color: theme.colorScheme.onSurfaceVariant,
                  icon: Icons.arrow_downward,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppointmentBadge extends StatelessWidget {
  const _AppointmentBadge({
    required this.count,
    required this.color,
    required this.icon,
  });

  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.error.withOpacity(0.7),
        ),
        onPressed: () => _onDelete(context, ref),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showConfirmDialog(
      context,
      title: Text(context.l10n.deleteClientConfirmTitle),
      content: Text(context.l10n.deleteClientConfirmMessage),
      confirmLabel: context.l10n.actionDelete,
      danger: true,
    );
    if (!confirm) return;

    ref.read(clientsProvider.notifier).deleteClient(client.id);
  }
}
