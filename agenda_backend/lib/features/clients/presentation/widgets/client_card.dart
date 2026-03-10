import 'package:agenda_backend/app/widgets/staff_circle_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../auth/providers/current_business_user_provider.dart';
import '../../domain/clients.dart';
import '../../providers/clients_providers.dart';
import '../dialogs/client_appointments_dialog.dart';

class ClientCard extends ConsumerWidget {
  const ClientCard({super.key, required this.client, this.onTap});

  static const double _actionIconBoxSize = 32;
  static const double _blockedIndicatorBoxSize = 16;
  static const double _blockedIndicatorHitBoxSize = 32;
  static const double _actionIconGap = 8;
  static const double _actionColumnWidth =
      _actionIconBoxSize + _actionIconGap + _blockedIndicatorHitBoxSize;

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colonna sinistra: contenuto principale
            Expanded(
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
                        child: Text(
                          client.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
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
                  if (client.lastVisit != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _buildLastVisitLabel(context, client.lastVisit!),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),
            // Colonna destra: icone azione
            SizedBox(
              width: _actionColumnWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _DeleteButton(client: client),
                  const SizedBox(height: 8),
                  _AppointmentsButton(client: client, onCardTap: onTap),
                ],
              ),
            ),
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

/// Pulsante per aprire il dialog degli appuntamenti del cliente.
/// Non carica i dati in anticipo per evitare troppe chiamate API simultanee.
/// I dati vengono caricati solo all'apertura del dialog.
class _AppointmentsButton extends StatelessWidget {
  const _AppointmentsButton({required this.client, this.onCardTap});

  final Client client;
  final VoidCallback? onCardTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockedIconColor = theme.colorScheme.error.withOpacity(0.75);

    return Consumer(
      builder: (context, ref, _) => SizedBox(
        width: ClientCard._actionColumnWidth,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (client.blocked) ...[
              SizedBox(
                width: ClientCard._blockedIndicatorHitBoxSize,
                height: ClientCard._actionIconBoxSize,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Tooltip(
                    message: context.l10n.notBookableOnline,
                    child: SizedBox(
                      width: ClientCard._actionIconBoxSize,
                      height: ClientCard._actionIconBoxSize,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: ClientCard._blockedIndicatorBoxSize,
                        onPressed: onCardTap,
                        icon: Icon(
                          Icons.cloud_off_outlined,
                          size: ClientCard._blockedIndicatorBoxSize,
                          color: blockedIconColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ClientCard._actionIconGap),
            ],
            SizedBox(
              height: ClientCard._actionIconBoxSize,
              width: ClientCard._actionIconBoxSize,
              child: Tooltip(
                message: context.l10n.clientAppointmentsTitle(client.name),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onPressed: () =>
                      showClientAppointmentsDialog(context, ref, client: client),
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    final canManageClients = ref.watch(currentUserCanManageClientsProvider);

    if (!canManageClients) {
      return const SizedBox(
        width: ClientCard._actionIconBoxSize,
        height: ClientCard._actionIconBoxSize,
      );
    }

    return SizedBox(
      width: ClientCard._actionIconBoxSize,
      height: ClientCard._actionIconBoxSize,
      child: Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 18,
          tooltip: context.l10n.actionDelete,
          icon: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.error.withOpacity(0.7),
          ),
          onPressed: () => _onDelete(context, ref),
        ),
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
