import 'package:agenda_backend/core/environment/app_environment_config.dart';
import 'package:agenda_backend/core/network/api_client.dart';
import 'package:agenda_backend/core/network/token_storage_interface.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? _refreshToken;

  @override
  Future<void> clearRefreshToken() async {
    _refreshToken = null;
  }

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
  }
}

void main() {
  setUpAll(() {
    AppEnvironmentConfig.bootstrap();
  });

  group('ApiClient.updateAppointment notify_client', () {
    test('sends notify_client=true by default', () async {
      final dio = Dio();
      Map<String, dynamic>? capturedBody;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = Map<String, dynamic>.from(
              options.data as Map<String, dynamic>,
            );
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {'ok': true},
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(tokenStorage: _MemoryTokenStorage(), dio: dio);

      await client.updateAppointment(
        locationId: 10,
        appointmentId: 99,
        startTime: '2026-03-17T10:00:00',
        endTime: '2026-03-17T10:30:00',
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['notify_client'], isTrue);
    });

    test('sends notify_client=false when explicitly disabled', () async {
      final dio = Dio();
      Map<String, dynamic>? capturedBody;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = Map<String, dynamic>.from(
              options.data as Map<String, dynamic>,
            );
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {'ok': true},
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(tokenStorage: _MemoryTokenStorage(), dio: dio);

      await client.updateAppointment(
        locationId: 10,
        appointmentId: 100,
        startTime: '2026-03-17T11:00:00',
        endTime: '2026-03-17T11:30:00',
        notifyClient: false,
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!['notify_client'], isFalse);
    });
  });
}
