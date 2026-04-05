class WhatsappEmbeddedSignupLaunchResult {
  const WhatsappEmbeddedSignupLaunchResult({
    required this.code,
    required this.state,
    this.sessionInfoVersion,
    this.wabaId,
    this.phoneNumberId,
    this.displayPhoneNumber,
  });

  final String code;
  final String state;
  final int? sessionInfoVersion;
  final String? wabaId;
  final String? phoneNumberId;
  final String? displayPhoneNumber;
}
