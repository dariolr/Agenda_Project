import 'package:agenda_frontend/core/environment/app_environment.dart';
import 'package:agenda_frontend/core/environment/app_environment_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppEnvironmentRawConfig baseRaw({
    required String appEnv,
    String apiBaseUrl = 'https://demo-api.romeolab.it',
    String webBaseUrl = 'https://demo-prenota.romeolab.it',
    bool? demoMode,
    bool? showDemoBanner,
    bool? demoResetExpected,
    bool? demoAutoLoginEnabled,
    bool? allowRealPayments,
    bool? allowExternalWebhooks,
    bool? allowRealExports,
  }) {
    return AppEnvironmentRawConfig(
      appEnv: appEnv,
      apiBaseUrl: apiBaseUrl,
      webBaseUrl: webBaseUrl,
      demoMode: demoMode,
      showDemoBanner: showDemoBanner,
      demoResetExpected: demoResetExpected,
      demoAutoLoginEnabled: demoAutoLoginEnabled,
      allowRealPayments: allowRealPayments,
      allowExternalWebhooks: allowExternalWebhooks,
      allowRealExports: allowRealExports,
    );
  }

  group('AppEnvironmentConfig', () {
    test('resolves production defaults', () {
      final config = AppEnvironmentConfig.fromRaw(
        baseRaw(
          appEnv: 'production',
          apiBaseUrl: 'https://api.romeolab.it',
          webBaseUrl: 'https://prenota.romeolab.it',
        ),
      );

      expect(config.environment, AppEnvironment.production);
      expect(config.allowRealPayments, isTrue);
      expect(config.showDemoBanner, isFalse);
    });

    test('resolves demo defaults as safe', () {
      final config = AppEnvironmentConfig.fromRaw(
        baseRaw(appEnv: 'demo', demoMode: true),
      );

      expect(config.environment, AppEnvironment.demo);
      expect(config.allowRealPayments, isFalse);
      expect(config.allowExternalWebhooks, isFalse);
      expect(config.allowRealExports, isFalse);
      expect(config.showDemoBanner, isTrue);
      expect(config.demoResetExpected, isTrue);
    });

    test('throws for unknown APP_ENV', () {
      expect(
        () => AppEnvironmentConfig.fromRaw(baseRaw(appEnv: 'qa')),
        throwsA(isA<StateError>()),
      );
    });

    test('throws if demo enables sensitive flag', () {
      expect(
        () => AppEnvironmentConfig.fromRaw(
          baseRaw(appEnv: 'demo', demoMode: true, allowRealPayments: true),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws if demo points to production API', () {
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
  });
}
