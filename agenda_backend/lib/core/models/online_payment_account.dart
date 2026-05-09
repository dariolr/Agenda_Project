class OnlinePaymentAccount {
  const OnlinePaymentAccount({
    required this.providerCode,
    required this.mode,
    required this.isEnabled,
    required this.onboardingStatus,
    required this.chargesEnabled,
    required this.payoutsEnabled,
    required this.detailsSubmitted,
    this.lastErrorCode,
    this.lastErrorMessage,
  });

  final String providerCode;
  final String mode;
  final bool isEnabled;
  final String onboardingStatus;
  final bool chargesEnabled;
  final bool payoutsEnabled;
  final bool detailsSubmitted;
  final String? lastErrorCode;
  final String? lastErrorMessage;

  bool get isActive => onboardingStatus == 'active';

  factory OnlinePaymentAccount.fromJson(Map<String, dynamic> json) {
    return OnlinePaymentAccount(
      providerCode: json['provider_code']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'test',
      isEnabled: json['is_enabled'] == true || json['is_enabled'] == 1,
      onboardingStatus:
          json['onboarding_status']?.toString() ?? 'not_configured',
      chargesEnabled:
          json['charges_enabled'] == true || json['charges_enabled'] == 1,
      payoutsEnabled:
          json['payouts_enabled'] == true || json['payouts_enabled'] == 1,
      detailsSubmitted:
          json['details_submitted'] == true || json['details_submitted'] == 1,
      lastErrorCode: json['last_error_code']?.toString(),
      lastErrorMessage: json['last_error_message']?.toString(),
    );
  }
}
