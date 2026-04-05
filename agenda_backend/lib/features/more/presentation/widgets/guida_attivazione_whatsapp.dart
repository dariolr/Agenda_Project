import 'package:flutter/material.dart';

import '/core/l10n/l10_extension.dart';

class GuidaAttivazioneWhatsApp extends StatelessWidget {
  const GuidaAttivazioneWhatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
          l10n.whatsappGuideNeedDedicatedNumber,
          emphasizePrefix: true,
        ),
        _buildPuntoElenco(
          l10n.whatsappGuideNeedPaymentCard,
          emphasizePrefix: true,
        ),
        _buildPuntoElenco(
          l10n.whatsappGuideNeedVat,
          emphasizePrefix: true,
        ),
        const SizedBox(height: 18),
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
        _buildPuntoElenco(
          l10n.whatsappGuideManageNumberNewSim,
        ),
        _buildPuntoElenco(
          l10n.whatsappGuideManageNumberLandline,
        ),
        _buildPuntoElenco(
          l10n.whatsappGuideManageNumberCurrent,
        ),
        const SizedBox(height: 24),
        _buildTitolo(l10n.whatsappGuideStepsTitle),
        _buildPassaggio(
          1,
          l10n.whatsappGuideStep1,
        ),
        _buildPassaggio(
          2,
          l10n.whatsappGuideStep2,
        ),
        _buildPassaggio(
          3,
          l10n.whatsappGuideStep3,
        ),
        _buildPassaggio(
          4,
          l10n.whatsappGuideStep4,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.whatsappGuideTipTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                l10n.whatsappGuideTipBody,
              ),
            ],
          ),
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
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPuntoElenco(String testo, {bool emphasizePrefix = false}) {
    final splitIndex = testo.indexOf(':');
    final hasPrefix = emphasizePrefix && splitIndex > 0;
    final prefix = hasPrefix ? testo.substring(0, splitIndex).trim() : '';
    final suffix = hasPrefix ? testo.substring(splitIndex + 1).trimLeft() : testo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
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
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          SizedBox(width: 10),
          Expanded(child: Text(testo, style: TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

}
