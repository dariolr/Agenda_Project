class WhatsappGoLiveCheck {
  final bool phoneNumberActive;
  final bool webhookVerified;
  final bool templateApproved;
  final bool optInActive;

  const WhatsappGoLiveCheck({
    required this.phoneNumberActive,
    required this.webhookVerified,
    required this.templateApproved,
    required this.optInActive,
  });

  bool get isReady =>
      phoneNumberActive && webhookVerified && templateApproved && optInActive;

  List<String> get missingChecks {
    final list = <String>[];
    if (!phoneNumberActive) list.add('phone_number_active');
    if (!webhookVerified) list.add('webhook_verified');
    if (!templateApproved) list.add('template_approved');
    if (!optInActive) list.add('opt_in_active');
    return list;
  }

  factory WhatsappGoLiveCheck.fromJson(Map<String, dynamic> json) {
    return WhatsappGoLiveCheck(
      phoneNumberActive: json['phone_number_active'] == true,
      webhookVerified: json['webhook_verified'] == true,
      templateApproved: json['template_approved'] == true,
      optInActive: json['opt_in_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone_number_active': phoneNumberActive,
      'webhook_verified': webhookVerified,
      'template_approved': templateApproved,
      'opt_in_active': optInActive,
    };
  }
}
