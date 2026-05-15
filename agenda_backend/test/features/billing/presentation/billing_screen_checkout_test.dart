import 'package:agenda_backend/core/l10n/l10n.dart';
import 'package:agenda_backend/core/models/user.dart';
import 'package:agenda_backend/core/network/api_client.dart';
import 'package:agenda_backend/features/agenda/providers/business_providers.dart';
import 'package:agenda_backend/features/auth/domain/auth_state.dart';
import 'package:agenda_backend/features/auth/providers/auth_provider.dart';
import 'package:agenda_backend/features/billing/data/billing_repository.dart';
import 'package:agenda_backend/features/billing/domain/billing_config_view_model.dart';
import 'package:agenda_backend/features/billing/presentation/billing_screen.dart';
import 'package:agenda_backend/features/billing/providers/billing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState.authenticated(
      User(
        id: 1,
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }
}

class _FakeCurrentBusinessIdNotifier extends CurrentBusinessId {
  @override
  int build() => 42;
}

class _FailingBillingRepository implements BillingRepository {
  int createCheckoutCalls = 0;

  @override
  Future<String> createCheckoutSession(int businessId) async {
    createCheckoutCalls += 1;
    throw const ApiException(
      code: 'checkout_already_started',
      message: 'Checkout has already been started for this business',
      statusCode: 409,
    );
  }

  @override
  Future<String> createPortalSession(int businessId) async {
    throw StateError('Unexpected portal call');
  }

  @override
  Future<BillingConfigViewModel> getAdminConfig(int businessId) async {
    return _inactiveBilling;
  }

  @override
  Future<BillingConfigViewModel> getSubscription(
    int businessId, {
    bool checkoutCancelled = false,
  }) async {
    return _inactiveBilling;
  }

  @override
  Future<void> updateAdminConfig({
    required int businessId,
    required bool billingEnabled,
    required int? amountCents,
    required String currency,
    required String? providerCode,
    String? notes,
  }) async {}
}

const _inactiveBilling = BillingConfigViewModel(
  billingEnabled: true,
  billingMode: 'fixed',
  billingIntervalUnit: 'month',
  billingIntervalCount: 1,
  amountCents: 2900,
  currency: 'EUR',
  providerCode: 'stripe',
  providerCustomerId: null,
  providerSubscriptionId: null,
  status: 'inactive',
  currentPeriodStart: null,
  currentPeriodEnd: null,
  cancelAtPeriodEnd: false,
  canceledAt: null,
  lastPaymentAt: null,
  lastPaymentFailedAt: null,
  lastCheckoutSessionId: null,
  checkoutRetryable: true,
  checkoutState: null,
  canStartCheckout: true,
  canOpenPortal: false,
);

void main() {
  testWidgets('billing checkout preparation stops after incoherent state', (
    tester,
  ) async {
    final repository = _FailingBillingRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_FakeAuthNotifier.new),
          currentBusinessIdProvider.overrideWith(
            _FakeCurrentBusinessIdNotifier.new,
          ),
          billingRepositoryProvider.overrideWithValue(repository),
          billingSubscriptionProvider.overrideWith((ref) async {
            return _inactiveBilling;
          }),
        ],
        child: const MaterialApp(
          locale: Locale('it'),
          localizationsDelegates: [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('it'), Locale('en')],
          home: BillingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(repository.createCheckoutCalls, 1);
    expect(
      find.text(
        'Pagamento già avviato. Completa il pagamento aperto prima di riprovare.',
      ),
      findsOneWidget,
    );

    for (var i = 0; i < 5; i += 1) {
      await tester.pump();
    }

    expect(repository.createCheckoutCalls, 1);
  });
}
