import 'package:agenda_backend/core/environment/app_environment.dart';
import 'package:agenda_backend/core/environment/app_environment_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppEnvironmentRawConfig baseRaw({
    required String appEnv,
    String apiBaseUrl = 'https://demo-api.romeolab.it',
    String webBaseUrl = 'https://demo-gestionale.romeolab.it',
    bool? demoMode,
    bool? allowRealEmails,
    bool? allowRealWhatsapp,
    bool? allowRealPayments,
    bool? allowExternalWebhooks,
    bool? allowDestructiveBusinessActions,
    bool? allowPlanChanges,
    bool? allowRealExports,
    bool? showDemoBanner,
    bool? demoResetExpected,
    bool? demoAutoLoginEnabled,
  }) {
    return AppEnvironmentRawConfig(
      appEnv: appEnv,
      apiBaseUrl: apiBaseUrl,
      webBaseUrl: webBaseUrl,
      demoMode: demoMode,
      allowRealEmails: allowRealEmails,
      allowRealWhatsapp: allowRealWhatsapp,
      allowRealPayments: allowRealPayments,
      allowExternalWebhooks: allowExternalWebhooks,
      allowDestructiveBusinessActions: allowDestructiveBusinessActions,
      allowPlanChanges: allowPlanChanges,
      allowRealExports: allowRealExports,
      showDemoBanner: showDemoBanner,
      demoResetExpected: demoResetExpected,
      demoAutoLoginEnabled: demoAutoLoginEnabled,
    );
  }

  group('AppEnvironmentConfig', () {
    test('resolves production defaults as real-enabled', () {
      final config = AppEnvironmentConfig.fromRaw(
        baseRaw(
          appEnv: 'production',
          apiBaseUrl: 'https://api.romeolab.it',
          webBaseUrl: 'https://gestionale.romeolab.it',
        ),
      );

      expect(config.environment, AppEnvironment.production);
      expect(config.allowRealEmails, isTrue);
      expect(config.allowRealPayments, isTrue);
      expect(config.showDemoBanner, isFalse);
    });

    test('resolves demo defaults as safe', () {
      final config = AppEnvironmentConfig.fromRaw(
        baseRaw(appEnv: 'demo', demoMode: true),
      );

      expect(config.environment, AppEnvironment.demo);
      expect(config.allowRealEmails, isFalse);
      expect(config.allowRealWhatsapp, isFalse);
      expect(config.allowRealPayments, isFalse);
      expect(config.allowExternalWebhooks, isFalse);
      expect(config.allowDestructiveBusinessActions, isFalse);
      expect(config.allowPlanChanges, isFalse);
      expect(config.allowRealExports, isFalse);
      expect(config.showDemoBanner, isTrue);
      expect(config.demoResetExpected, isTrue);
    });

    test('throws on unknown APP_ENV', () {
      expect(
        () => AppEnvironmentConfig.fromRaw(baseRaw(appEnv: 'qa')),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when DEMO_MODE is inconsistent with APP_ENV', () {
      expect(
        () => AppEnvironmentConfig.fromRaw(
          baseRaw(appEnv: 'production', demoMode: true),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when demo enables sensitive flags', () {
      expect(
        () => AppEnvironmentConfig.fromRaw(
          baseRaw(appEnv: 'demo', demoMode: true, allowRealEmails: true),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when demo points to production API', () {
      expect(
        () => AppEnvironmentConfig.fromRaw(
          baseRaw(
            appEnv: 'demo',
            demoMode: true,
            apiBaseUrl: 'https://api.romeolab.it',
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws on invalid API URL', () {
      expect(
        () => AppEnvironmentConfig.fromRaw(
          baseRaw(appEnv: 'local', apiBaseUrl: 'not-valid-url'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
