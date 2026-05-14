import 'package:agenda_backend/features/online_payments/presentation/online_payments_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Stripe return callback URL is canonicalized to clean online payments route',
    () {
      final canonical = canonicalOnlinePaymentsCallbackUri(
        Uri.parse(
          '/altro/pagamenti-online?from_altro=1&stripe_connect_return=1&provider=stripe&onboarding=legacy',
        ),
      );

      expect(canonical, '/altro/pagamenti-online');
    },
  );

  test(
    'Stripe refresh callback URL is canonicalized to clean online payments route',
    () {
      final canonical = canonicalOnlinePaymentsCallbackUri(
        Uri.parse(
          '/altro/pagamenti-online?stripe_connect_refresh=1&provider=stripe',
        ),
      );

      expect(canonical, '/altro/pagamenti-online');
    },
  );

  test(
    'Stripe new return callback URL is canonicalized to clean online payments route',
    () {
      final canonical = canonicalOnlinePaymentsCallbackUri(
        Uri.parse('/altro/pagamenti-online?provider=stripe&onboarding=return'),
      );

      expect(canonical, '/altro/pagamenti-online');
    },
  );

  test(
    'Stripe new refresh callback URL is canonicalized to clean online payments route',
    () {
      final canonical = canonicalOnlinePaymentsCallbackUri(
        Uri.parse('/altro/pagamenti-online?provider=stripe&onboarding=refresh'),
      );

      expect(canonical, '/altro/pagamenti-online');
    },
  );
}
