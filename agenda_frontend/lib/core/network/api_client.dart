import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'token_storage.dart';

/// Eccezione API custom
class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;
  final dynamic details;

  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.details,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isSlotConflict => code == 'slot_conflict';

  @override
  String toString() => 'ApiException($code): $message';
}

/// Client HTTP per comunicare con agenda_core API
class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  String? _accessToken;

  ApiClient({required TokenStorage tokenStorage, Dio? dio})
    : _tokenStorage = tokenStorage,
      _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';

    // Interceptor per logging in debug
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    // Interceptor per auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Gestione token expired - auto refresh
          if (error.response?.statusCode == 401 &&
              error.response?.data?['error']?['code'] == 'token_expired') {
            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                // Riprova la richiesta originale
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $_accessToken';
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              }
            } catch (_) {
              // Refresh fallito, propaga errore originale
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Imposta access token in memoria
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Verifica se autenticato
  bool get isAuthenticated => _accessToken != null;

  /// Tenta refresh del token
  Future<bool> _refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post(
        ApiConfig.authRefresh,
        data: {'refresh_token': refreshToken},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        _accessToken = data['access_token'];
        await _tokenStorage.saveRefreshToken(data['refresh_token']);
        return true;
      }
    } catch (_) {
      // Token non valido, pulisci storage
      await _tokenStorage.clearRefreshToken();
    }
    return false;
  }

  /// Tenta di ripristinare sessione da refresh token
  Future<Map<String, dynamic>?> tryRestoreSession() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _dio.post(
        ApiConfig.authRefresh,
        data: {'refresh_token': refreshToken},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        _accessToken = data['access_token'];
        await _tokenStorage.saveRefreshToken(data['refresh_token']);

        // Fetch user profile
        return await getMe();
      }
    } catch (_) {
      await _tokenStorage.clearRefreshToken();
    }
    return null;
  }

  /// Esegue richiesta GET
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Esegue richiesta POST
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: headers != null ? Options(headers: headers) : null,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Esegue richiesta DELETE
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Gestisce risposta API
  Map<String, dynamic> _handleResponse(Response response) {
    final body = response.data as Map<String, dynamic>;
    if (body['success'] == true) {
      return body['data'] as Map<String, dynamic>? ?? {};
    }
    throw ApiException(
      code: body['error']?['code'] ?? 'unknown_error',
      message: body['error']?['message'] ?? 'Unknown error',
      statusCode: response.statusCode ?? 500,
      details: body['error']?['details'],
    );
  }

  /// Gestisce errori Dio
  ApiException _handleError(DioException error) {
    final response = error.response;
    if (response != null) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return ApiException(
          code: body['error']?['code'] ?? 'api_error',
          message: body['error']?['message'] ?? error.message ?? 'API Error',
          statusCode: response.statusCode ?? 500,
          details: body['error']?['details'],
        );
      }
    }
    return ApiException(
      code: 'network_error',
      message: error.message ?? 'Network error',
      statusCode: error.response?.statusCode ?? 0,
    );
  }

  // ========== AUTH ENDPOINTS ==========

  /// POST /v1/auth/login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await post(
      ApiConfig.authLogin,
      data: {'email': email, 'password': password},
    );

    _accessToken = data['access_token'];
    await _tokenStorage.saveRefreshToken(data['refresh_token']);

    return data;
  }

  /// POST /v1/auth/logout
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    try {
      await post(ApiConfig.authLogout, data: {'refresh_token': refreshToken});
    } finally {
      _accessToken = null;
      await _tokenStorage.clearRefreshToken();
    }
  }

  /// GET /v1/me
  Future<Map<String, dynamic>> getMe() async {
    return get(ApiConfig.authMe);
  }

  /// POST /v1/auth/register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final data = await post(
      ApiConfig.authRegister,
      data: {
        'email': email,
        'password': password,
        'name': name,
        if (phone != null) 'phone': phone,
      },
    );

    _accessToken = data['access_token'];
    await _tokenStorage.saveRefreshToken(data['refresh_token']);

    return data;
  }

  /// POST /v1/auth/forgot-password
  Future<void> forgotPassword({required String email}) async {
    await post(ApiConfig.authForgotPassword, data: {'email': email});
  }

  /// POST /v1/auth/reset-password
  Future<void> resetPasswordWithToken({
    required String token,
    required String password,
  }) async {
    await post(
      ApiConfig.authResetPassword,
      data: {'token': token, 'password': password},
    );
  }

  /// POST /v1/me/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await post(
      ApiConfig.meChangePassword,
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }

  /// GET /v1/me/bookings
  Future<Map<String, dynamic>> getMyBookings() async {
    return get(ApiConfig.meBookings);
  }

  // ========== PUBLIC BROWSE ENDPOINTS ==========

  /// GET /v1/businesses/by-slug/{slug}
  /// Recupera un business dal suo slug (pubblico, no auth)
  Future<Map<String, dynamic>> getBusinessBySlug(String slug) async {
    return get(ApiConfig.businessBySlug(slug));
  }

  /// GET /v1/services?location_id=X
  Future<Map<String, dynamic>> getServices(int locationId) async {
    return get(
      ApiConfig.services,
      queryParameters: {'location_id': locationId},
    );
  }

  /// GET /v1/staff?location_id=X
  Future<Map<String, dynamic>> getStaff(int locationId) async {
    return get(ApiConfig.staff, queryParameters: {'location_id': locationId});
  }

  /// GET /v1/availability?location_id=X&date=YYYY-MM-DD&service_ids=1,2&staff_id=N
  Future<Map<String, dynamic>> getAvailability({
    required int locationId,
    required String date,
    required List<int> serviceIds,
    int? staffId,
  }) async {
    final params = <String, dynamic>{
      'location_id': locationId,
      'date': date,
      'service_ids': serviceIds.join(','),
    };
    if (staffId != null) {
      params['staff_id'] = staffId;
    }
    return get(ApiConfig.availability, queryParameters: params);
  }

  // ========== BOOKING ENDPOINT ==========

  /// POST /v1/locations/{location_id}/bookings
  Future<Map<String, dynamic>> createBooking({
    required int locationId,
    required String idempotencyKey,
    required List<int> serviceIds,
    required String startTime,
    int? staffId,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'service_ids': serviceIds,
      'start_time': startTime,
    };
    if (staffId != null) {
      data['staff_id'] = staffId;
    }
    if (notes != null && notes.isNotEmpty) {
      data['notes'] = notes;
    }

    return post(
      ApiConfig.bookings(locationId),
      data: data,
      headers: {'X-Idempotency-Key': idempotencyKey},
    );
  }

  /// DELETE /v1/locations/{location_id}/bookings/{id}
  /// NOTE: Richiede location_id, quindi serve prima recuperare il booking completo
  /// da GET /v1/me/bookings per ottenere il location_id associato
  Future<void> deleteBooking(int locationId, int bookingId) async {
    await delete('/v1/locations/$locationId/bookings/$bookingId');
  }

  /// PUT /v1/locations/{location_id}/bookings/{id}
  /// Reschedule booking (modifica data/ora)
  Future<Map<String, dynamic>> updateBooking({
    required int locationId,
    required int bookingId,
    required String startTime,
    String? notes,
  }) async {
    final data = <String, dynamic>{'start_time': startTime};
    if (notes != null) {
      data['notes'] = notes;
    }

    return await _dio
        .put('/v1/locations/$locationId/bookings/$bookingId', data: data)
        .then((response) => _handleResponse(response))
        .catchError((e) => throw _handleError(e as DioException));
  }
}
