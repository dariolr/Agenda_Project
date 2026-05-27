class BillingConfigViewModel {
  const BillingConfigViewModel({
    required this.billingEnabled,
    required this.billingMode,
    required this.billingIntervalUnit,
    required this.billingIntervalCount,
    required this.amountCents,
    required this.currency,
    required this.providerCode,
    required this.providerCustomerId,
    required this.providerSubscriptionId,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.canceledAt,
    required this.lastPaymentAt,
    required this.lastPaymentFailedAt,
    required this.lastCheckoutSessionId,
    required this.checkoutRetryable,
    required this.checkoutState,
    required this.canStartCheckout,
    required this.canOpenPortal,
    required this.accessBlocked,
    this.providerPriceReference,
    this.activationDeadlineAt,
    this.billingCycleAnchorAt,
    this.notes,
  });

  final bool billingEnabled;
  final String billingMode;
  final String? billingIntervalUnit;
  final int? billingIntervalCount;
  final int? amountCents;
  final String currency;
  final String? providerCode;
  final String? providerCustomerId;
  final String? providerSubscriptionId;
  final String status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime? canceledAt;
  final DateTime? lastPaymentAt;
  final DateTime? lastPaymentFailedAt;
  final String? lastCheckoutSessionId;
  final bool checkoutRetryable;
  final String? checkoutState;
  final bool canStartCheckout;
  final bool canOpenPortal;
  final bool accessBlocked;
  final String? providerPriceReference;
  final DateTime? activationDeadlineAt;
  final DateTime? billingCycleAnchorAt;
  final String? notes;

  factory BillingConfigViewModel.fromJson(Map<String, dynamic> json) {
    return BillingConfigViewModel(
      billingEnabled: json['billing_enabled'] as bool? ?? false,
      billingMode: json['billing_mode'] as String? ?? 'free',
      billingIntervalUnit: json['billing_interval_unit'] as String?,
      billingIntervalCount: json['billing_interval_count'] as int?,
      amountCents: json['amount_cents'] as int?,
      currency: json['currency'] as String? ?? 'EUR',
      providerCode: json['provider_code'] as String?,
      providerCustomerId:
          json['provider_customer_id'] as String? ??
          json['providerCustomerId'] as String?,
      providerSubscriptionId:
          json['provider_subscription_id'] as String? ??
          json['providerSubscriptionId'] as String?,
      status:
          json['status'] as String? ??
          json['subscription_status'] as String? ??
          'not_required',
      currentPeriodStart: _parseDate(
        json['current_period_start'] ?? json['currentPeriodStart'],
      ),
      currentPeriodEnd: _parseDate(
        json['current_period_end'] ?? json['currentPeriodEnd'],
      ),
      cancelAtPeriodEnd: _parseBool(
        json['cancel_at_period_end'] ?? json['cancelAtPeriodEnd'],
      ),
      canceledAt: _parseDate(json['canceled_at'] ?? json['canceledAt']),
      lastPaymentAt: _parseDate(
        json['last_payment_at'] ?? json['lastPaymentAt'],
      ),
      lastPaymentFailedAt: _parseDate(
        json['last_payment_failed_at'] ?? json['lastPaymentFailedAt'],
      ),
      lastCheckoutSessionId:
          json['last_checkout_session_id'] as String? ??
          json['lastCheckoutSessionId'] as String?,
      checkoutRetryable: _parseBool(
        json['checkout_retryable'] ?? json['checkoutRetryable'],
      ),
      checkoutState:
          json['checkout_state'] as String? ?? json['checkoutState'] as String?,
      canStartCheckout: json['can_start_checkout'] as bool? ?? false,
      canOpenPortal: json['can_open_portal'] as bool? ?? false,
      accessBlocked: json['access_blocked'] as bool? ?? false,
      providerPriceReference: json['provider_price_reference'] as String?,
      activationDeadlineAt: _parseDate(
        json['activation_deadline_at'] ?? json['activationDeadlineAt'],
      ),
      billingCycleAnchorAt: _parseDate(
        json['billing_cycle_anchor_at'] ?? json['billingCycleAnchorAt'],
      ),
      notes: json['notes'] as String?,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return ['1', 'true', 'yes', 'on'].contains(value.toLowerCase().trim());
    }
    return false;
  }
}
