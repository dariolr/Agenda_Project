import '/core/models/whatsapp_config.dart';
import '/core/models/whatsapp_go_live_check.dart';

class WhatsappEmbeddedSignupResult {
  final WhatsappConfig config;
  final List<int> autoMappedLocationIds;
  final WhatsappGoLiveCheck? goLiveCheck;
  final List<String> nextSteps;
  final int? sessionInfoVersion;

  const WhatsappEmbeddedSignupResult({
    required this.config,
    required this.autoMappedLocationIds,
    required this.goLiveCheck,
    required this.nextSteps,
    required this.sessionInfoVersion,
  });

  factory WhatsappEmbeddedSignupResult.fromJson(Map<String, dynamic> json) {
    final configMap = Map<String, dynamic>.from(
      (json['config'] as Map?) ?? const <String, dynamic>{},
    );
    final autoMapped = (json['auto_mapped_location_ids'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList(growable: false) ??
        const <int>[];
    final nextSteps = (json['next_steps'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];

    WhatsappGoLiveCheck? check;
    final rawCheck = json['go_live_check'];
    if (rawCheck is Map) {
      final map = Map<String, dynamic>.from(rawCheck);
      check = WhatsappGoLiveCheck(
        phoneNumberActive: map['phone_number_active'] == true || map['phone'] == true,
        webhookVerified: map['webhook_verified'] == true || map['webhook'] == true,
        templateApproved: map['template_approved'] == true || map['template'] == true,
        optInActive: map['opt_in_active'] == true || map['optin'] == true,
      );
    }

    return WhatsappEmbeddedSignupResult(
      config: WhatsappConfig.fromJson(configMap),
      autoMappedLocationIds: autoMapped,
      goLiveCheck: check,
      nextSteps: nextSteps,
      sessionInfoVersion: (json['session_info_version'] as num?)?.toInt(),
    );
  }
}
