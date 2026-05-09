import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/navigation/same_tab_redirect.dart';

class PaymentResultScreen extends ConsumerStatefulWidget {
  const PaymentResultScreen({super.key});

  @override
  ConsumerState<PaymentResultScreen> createState() =>
      _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  Timer? _timer;
  String? _paymentStatus;
  String? _bookingStatus;
  bool _canRetry = false;
  bool _isLoading = true;
  bool _isRetrying = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatus();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (_attempts >= 8 || _paymentStatus == 'paid') {
          _timer?.cancel();
          return;
        }
        _loadStatus();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final paymentId = _paymentId;
    if (paymentId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _attempts += 1;
      _isLoading = _paymentStatus == null;
    });

    try {
      final result = await ref
          .read(apiClientProvider)
          .getOnlineBookingPaymentStatus(paymentId);
      if (!mounted) return;
      setState(() {
        _paymentStatus = result['status']?.toString();
        _bookingStatus = result['booking_status']?.toString();
        _canRetry = result['can_retry'] == true;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _retry() async {
    final paymentId = _paymentId;
    if (paymentId == null) return;
    setState(() => _isRetrying = true);
    try {
      final result = await ref
          .read(apiClientProvider)
          .retryOnlineBookingPayment(paymentId);
      final checkoutUrl = result['checkout_url']?.toString();
      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        redirectSameTab(checkoutUrl);
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  int? get _paymentId {
    final value = GoRouterState.of(context).uri.queryParameters['payment_id'];
    return value == null ? null : int.tryParse(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slug = GoRouterState.of(context).pathParameters['slug'];
    final isPaid = _paymentStatus == 'paid' || _bookingStatus == 'confirmed';
    final isTerminalError = [
      'failed',
      'expired',
      'cancelled',
    ].contains(_paymentStatus);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentResultTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Icon(
                    isPaid
                        ? Icons.check_circle_outline
                        : isTerminalError
                        ? Icons.error_outline
                        : Icons.hourglass_top,
                    size: 56,
                    color: isPaid
                        ? Colors.green
                        : isTerminalError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                const SizedBox(height: 20),
                Text(
                  isPaid
                      ? l10n.paymentResultSuccessTitle
                      : isTerminalError
                      ? l10n.paymentResultFailedTitle
                      : l10n.paymentResultPendingTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isPaid
                      ? l10n.paymentResultSuccessMessage
                      : isTerminalError
                      ? l10n.paymentResultFailedMessage
                      : l10n.paymentResultPendingMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    if (_canRetry && !isPaid)
                      ElevatedButton(
                        onPressed: _isRetrying ? null : _retry,
                        child: _isRetrying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.paymentResultRetry),
                      ),
                    OutlinedButton(
                      onPressed: slug == null
                          ? null
                          : () => context.go('/$slug/my-bookings'),
                      child: Text(l10n.paymentResultMyBookings),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
