import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/l10n/l10_extension.dart';

class GuidaAttivazioneWhatsApp extends StatelessWidget {
  const GuidaAttivazioneWhatsApp({super.key, this.publicBookingUrl});

  final String? publicBookingUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bookingUrl = publicBookingUrl?.trim();
    final hasPublicBookingUrl = bookingUrl != null && bookingUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            l10n.whatsappGuideTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.whatsappGuideIntro,
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
        const Divider(height: 40),
        _buildTitolo(l10n.whatsappGuideNeedsTitle),
        _buildPuntoElenco(
          l10n.whatsappGuideNeedMetaAccount,
          emphasizePrefix: true,
        ),
        _buildPuntoElenco(
          l10n.whatsappGuideNeedMetaBusinessAccount,
          emphasizePrefix: true,
        ),
        _buildPuntoElenco(
          l10n.whatsappGuideNeedDedicatedNumber,
          emphasizePrefix: true,
        ),
        _buildPuntoElenco(
          l10n.whatsappGuideNeedPaymentCard,
          emphasizePrefix: true,
        ),
        _buildPuntoElenco(
          l10n.whatsappGuideNeedWebsiteNotRequired,
          emphasizePrefix: true,
        ),
        if (hasPublicBookingUrl) ...[
          const SizedBox(height: 10),
          _PublicBookingLinkBox(url: bookingUrl),
        ],
        const SizedBox(height: 18),
        _buildInfoBox(
          title: l10n.whatsappGuideNoBusinessAccountTitle,
          body: l10n.whatsappGuideNoBusinessAccountBody,
        ),
        const SizedBox(height: 24),
        _buildTitolo(l10n.whatsappGuidePaymentsTitle),
        Text(
          l10n.whatsappGuidePaymentsBody,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 24),
        _buildTitolo(l10n.whatsappGuideProfessionalTitle),
        Text(
          l10n.whatsappGuideProfessionalBody,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 24),
        _buildTitolo(l10n.whatsappGuideManageNumberTitle),
        _buildPuntoElenco(l10n.whatsappGuideManageNumberNewSim),
        _buildPuntoElenco(l10n.whatsappGuideManageNumberLandline),
        _buildPuntoElenco(l10n.whatsappGuideManageNumberCurrent),
        const SizedBox(height: 24),
        _buildTitolo(l10n.whatsappGuideStepsTitle),
        _buildPassaggio(1, l10n.whatsappGuideStep1),
        _buildPassaggio(2, l10n.whatsappGuideStep2),
        _buildPassaggio(3, l10n.whatsappGuideStep3),
        _buildPassaggio(4, l10n.whatsappGuideStep4),
        _buildPassaggio(5, l10n.whatsappGuideStep5),
        _buildPassaggio(6, l10n.whatsappGuideStep6),
        const SizedBox(height: 24),
        _buildTitolo(l10n.whatsappGuideAfterConnectionTitle),
        _buildPuntoElenco(l10n.whatsappGuideAfterConnectionConfigSaved),
        _buildPuntoElenco(l10n.whatsappGuideAfterConnectionApprovalRequired),
        const SizedBox(height: 24),
        _buildInfoBox(
          title: l10n.whatsappGuideTipTitle,
          body: l10n.whatsappGuideTipBody,
          color: Colors.blue,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTitolo(String testo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        testo,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPuntoElenco(String testo, {bool emphasizePrefix = false}) {
    final splitIndex = testo.indexOf(':');
    final hasPrefix = emphasizePrefix && splitIndex > 0;
    final prefix = hasPrefix ? testo.substring(0, splitIndex).trim() : '';
    final suffix = hasPrefix
        ? testo.substring(splitIndex + 1).trimLeft()
        : testo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Expanded(
            child: hasPrefix
                ? RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(
                          text: '$prefix: ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: suffix),
                      ],
                    ),
                  )
                : Text(
                    testo,
                    style: const TextStyle(fontSize: 15, height: 1.3),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassaggio(int numero, String testo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.green,
            child: Text(
              '$numero',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(testo, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String body,
    MaterialColor color = Colors.green,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color[800]),
          ),
          const SizedBox(height: 5),
          Text(body, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}

class _PublicBookingLinkBox extends StatefulWidget {
  const _PublicBookingLinkBox({required this.url});

  final String url;

  @override
  State<_PublicBookingLinkBox> createState() => _PublicBookingLinkBoxState();
}

class _PublicBookingLinkBoxState extends State<_PublicBookingLinkBox> {
  Timer? _copiedTimer;
  bool _copied = false;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.whatsappGuidePublicBookingLinkTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.whatsappGuidePublicBookingLinkBody,
            style: const TextStyle(fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 10),
          SelectableText(
            widget.url,
            style: const TextStyle(fontSize: 13, height: 1.25),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _copyLink,
              icon: Icon(_copied ? Icons.check : Icons.copy_outlined),
              label: Text(
                _copied
                    ? l10n.whatsappGuidePublicBookingLinkCopiedAction
                    : l10n.whatsappGuidePublicBookingLinkCopyAction,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
