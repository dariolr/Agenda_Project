import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '/core/models/location_closure.dart';
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
/// Usato dal gestionale (agenda_backend)
class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final void Function()? onSessionExpired;

  String? _accessToken;
  bool _isRefreshing = false;
  final List<void Function()> _pendingRequests = [];

  ApiClient({
    required TokenStorage tokenStorage,
    Dio? dio,
    this.onSessionExpired,
  }) : _tokenStorage = tokenStorage,
       _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';

    // Interceptor per logging SOLO errori in debug
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) {
            debugPrint('*** DioException ***');
            debugPrint('uri: ${error.requestOptions.uri}');
            debugPrint('statusCode: ${error.response?.statusCode}');
            debugPrint('Response: ${error.response?.data}');
            debugPrint(
              'hasAuthHeader: ${error.requestOptions.headers.containsKey('Authorization')}',
            );
            debugPrint('errorType: ${error.type}');
            debugPrint('errorMessage: ${error.message}');
            handler.next(error);
          },
        ),
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
          // Gestione token expired - auto refresh con single-flight
          if (error.response?.statusCode == 401 &&
              error.response?.data?['error']?['code'] == 'token_expired') {
            try {
              final refreshed = await _refreshTokenWithLock();
              if (refreshed) {
                // Riprova la richiesta originale
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $_accessToken';
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } else {
                // Refresh fallito, sessione scaduta
                _triggerSessionExpired();
              }
            } catch (_) {
              // Refresh fallito, sessione scaduta
              _triggerSessionExpired();
            }
          }
          // Gestione 401 generico (token invalid, unauthorized)
          // MA NON per errori di login (invalid_credentials) o registrazione
          else if (error.response?.statusCode == 401) {
            final errorCode = error.response?.data?['error']?['code'];
            // Non triggerare session expired per errori di credenziali
            if (errorCode != 'invalid_credentials') {
              _triggerSessionExpired();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Notifica che la sessione è scaduta
  void _triggerSessionExpired() {
    _accessToken = null;
    _tokenStorage.clearRefreshToken();
    if (onSessionExpired != null) {
      onSessionExpired!();
    }
  }

  /// Imposta access token in memoria
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Verifica se autenticato
  bool get isAuthenticated => _accessToken != null;

  /// Tenta refresh del token con lock per evitare refresh concorrenti
  Future<bool> _refreshTokenWithLock() async {
    if (_isRefreshing) {
      // Aspetta che il refresh in corso finisca
      final completer = Completer<void>();
      _pendingRequests.add(completer.complete);
      await completer.future;
      return _accessToken != null;
    }

    _isRefreshing = true;
    try {
      final success = await _refreshToken();
      // Sblocca le richieste in attesa
      for (final callback in _pendingRequests) {
        callback();
      }
      _pendingRequests.clear();
      return success;
    } finally {
      _isRefreshing = false;
    }
  }

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
    } catch (e) {
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
      // ignore: avoid_print
      //print('DEBUG GET $path response.data: ${response.data}');
      return _handleResponse(response);
    } on DioException catch (e) {
      // ignore: avoid_print
      //print('DEBUG GET $path DioException: ${e.message}');
      // ignore: avoid_print
      //print('DEBUG GET $path response: ${e.response?.data}');
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

  /// Esegue richiesta POST e ritorna la risposta raw (senza estrarre 'data')
  /// Usato per endpoint che non wrappano la risposta in 'data'
  Future<Map<String, dynamic>> postRawResponse(
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
      final body = _bodyAsMapOrThrow(response);
      if (body['success'] == true) {
        return body;
      }
      throw ApiException(
        code: body['error']?['code'] ?? 'unknown_error',
        message: body['error']?['message'] ?? 'Unknown error',
        statusCode: response.statusCode ?? 500,
        details: body['error']?['details'],
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Esegue richiesta PUT
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Esegue richiesta PATCH
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Esegue richiesta DELETE
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Gestisce risposta API
  Map<String, dynamic> _handleResponse(Response response) {
    final body = _bodyAsMapOrThrow(response);
    if (body['success'] == true) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      // Per risposte con data come List, ritorna wrapper
      return {'_list': data, '_raw': body};
    }
    throw ApiException(
      code: body['error']?['code'] ?? 'unknown_error',
      message: body['error']?['message'] ?? 'Unknown error',
      statusCode: response.statusCode ?? 500,
      details: body['error']?['details'],
    );
  }

  Map<String, dynamic> _bodyAsMapOrThrow(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    throw ApiException(
      code: 'invalid_response',
      message: 'Invalid server response format',
      statusCode: response.statusCode ?? 500,
      details: {'response_type': body.runtimeType.toString()},
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

  /// POST /v1/auth/register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? name,
    String? phone,
  }) async {
    final payload = <String, dynamic>{'email': email, 'password': password};
    if (firstName != null) payload['first_name'] = firstName;
    if (lastName != null) payload['last_name'] = lastName;
    if (name != null) payload['name'] = name;
    if (phone != null) payload['phone'] = phone;

    final data = await post(ApiConfig.authRegister, data: payload);

    _accessToken = data['access_token'];
    await _tokenStorage.saveRefreshToken(data['refresh_token']);

    return data;
  }

  /// POST /v1/auth/forgot-password
  Future<void> forgotPassword(String email) async {
    await post(ApiConfig.authForgotPassword, data: {'email': email});
  }

  /// GET /v1/auth/verify-reset-token/{token}
  /// Verifica se un token di reset è valido prima di mostrare il form.
  Future<void> verifyResetToken(String token) async {
    await get('${ApiConfig.authVerifyResetToken}/$token');
  }

  /// POST /v1/auth/reset-password
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await post(
      ApiConfig.authResetPassword,
      data: {'token': token, 'password': password},
    );
  }

  /// POST /v1/me/change-password - Cambia password utente autenticato
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await post(
      ApiConfig.authChangePassword,
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
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

  /// PUT /v1/me - Aggiorna profilo utente
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;

    return put(ApiConfig.authMe, data: data);
  }

  // ========== PUBLIC BROWSE ENDPOINTS ==========

  /// GET /v1/services?location_id=X
  Future<Map<String, dynamic>> getServices(int locationId) async {
    return get(
      ApiConfig.services,
      queryParameters: {'location_id': locationId},
    );
  }

  /// GET /v1/staff/{staff_id}/services/popular
  /// Ritorna i servizi più prenotati per uno staff.
  /// Restituisce lista vuota se la location dello staff ha meno di 25 servizi.
  Future<Map<String, dynamic>> getPopularServices(int staffId) async {
    return get(ApiConfig.popularServices(staffId));
  }

  /// GET /v1/locations/{location_id}/service-packages
  Future<Map<String, dynamic>> getServicePackages(int locationId) async {
    return get(ApiConfig.servicePackages(locationId));
  }

  /// GET /v1/locations/{location_id}/service-packages/{id}/expand
  Future<Map<String, dynamic>> expandServicePackage({
    required int locationId,
    required int packageId,
  }) async {
    return get(ApiConfig.servicePackageExpand(locationId, packageId));
  }

  /// POST /v1/locations/{location_id}/service-packages
  Future<Map<String, dynamic>> createServicePackage({
    required int locationId,
    required String name,
    required int categoryId,
    required List<int> serviceIds,
    String? description,
    double? overridePrice,
    int? overrideDurationMinutes,
    bool isActive = true,
  }) async {
    return post(
      ApiConfig.servicePackages(locationId),
      data: {
        'name': name,
        'category_id': categoryId,
        'service_ids': serviceIds,
        if (description != null) 'description': description,
        if (overridePrice != null) 'override_price': overridePrice,
        if (overrideDurationMinutes != null)
          'override_duration_minutes': overrideDurationMinutes,
        'is_active': isActive,
      },
    );
  }

  /// PUT /v1/locations/{location_id}/service-packages/{id}
  Future<Map<String, dynamic>> updateServicePackage({
    required int locationId,
    required int packageId,
    String? name,
    int? categoryId,
    String? description,
    double? overridePrice,
    int? overrideDurationMinutes,
    bool setOverridePriceNull = false,
    bool setOverrideDurationNull = false,
    bool? isActive,
    List<int>? serviceIds,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (categoryId != null) data['category_id'] = categoryId;
    if (description != null) data['description'] = description;
    if (overridePrice != null || setOverridePriceNull) {
      data['override_price'] = overridePrice;
    }
    if (overrideDurationMinutes != null || setOverrideDurationNull) {
      data['override_duration_minutes'] = overrideDurationMinutes;
    }
    if (isActive != null) data['is_active'] = isActive;
    if (serviceIds != null) data['service_ids'] = serviceIds;

    return put(ApiConfig.servicePackage(locationId, packageId), data: data);
  }

  /// DELETE /v1/locations/{location_id}/service-packages/{id}
  Future<void> deleteServicePackage({
    required int locationId,
    required int packageId,
  }) async {
    await delete(ApiConfig.servicePackage(locationId, packageId));
  }

  /// GET /v1/staff?location_id=X
  Future<Map<String, dynamic>> getStaff(int locationId) async {
    return get(ApiConfig.staff, queryParameters: {'location_id': locationId});
  }

  /// GET /v1/availability
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

  // ========== GESTIONALE ENDPOINTS ==========

  /// GET /v1/clients?business_id=X[&limit=N][&offset=N][&search=term][&sort=name_asc]
  Future<Map<String, dynamic>> getClients(
    int businessId, {
    int? limit,
    int? offset,
    String? search,
    String? sort,
  }) async {
    final params = <String, dynamic>{'business_id': businessId};
    if (limit != null) params['limit'] = limit;
    if (offset != null) params['offset'] = offset;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;
    return get(ApiConfig.clients, queryParameters: params);
  }

  /// GET /v1/locations/{location_id}/appointments?date=YYYY-MM-DD
  Future<Map<String, dynamic>> getAppointments({
    required int locationId,
    required String date,
  }) async {
    return get(
      ApiConfig.appointments(locationId),
      queryParameters: {'date': date},
    );
  }

  /// PATCH /v1/locations/{location_id}/appointments/{id}
  Future<Map<String, dynamic>> updateAppointment({
    required int locationId,
    required int appointmentId,
    String? startTime,
    String? endTime,
    int? staffId,
    int? serviceId,
    int? serviceVariantId,
    String? serviceNameSnapshot,
    int? clientId,
    String? clientName,
    String? clientNameSnapshot,
    int? extraBlockedMinutes,
    int? extraProcessingMinutes,
    double? price,
    bool priceExplicitlySet = false,
  }) async {
    final data = <String, dynamic>{};
    if (startTime != null) data['start_time'] = startTime;
    if (endTime != null) data['end_time'] = endTime;
    if (staffId != null) data['staff_id'] = staffId;
    if (serviceId != null) data['service_id'] = serviceId;
    if (serviceVariantId != null) data['service_variant_id'] = serviceVariantId;
    if (serviceNameSnapshot != null) {
      data['service_name_snapshot'] = serviceNameSnapshot;
    }
    if (clientId != null) data['client_id'] = clientId;
    if (clientName != null) data['client_name'] = clientName;
    if (clientNameSnapshot != null) {
      data['client_name_snapshot'] = clientNameSnapshot;
    }
    if (extraBlockedMinutes != null) {
      data['extra_blocked_minutes'] = extraBlockedMinutes;
    }
    if (extraProcessingMinutes != null) {
      data['extra_processing_minutes'] = extraProcessingMinutes;
    }
    if (priceExplicitlySet) {
      data['price'] = price;
    }

    try {
      final response = await _dio.patch(
        ApiConfig.appointment(locationId, appointmentId),
        data: data,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST /v1/locations/{location_id}/appointments/{id}/cancel
  Future<void> cancelAppointment({
    required int locationId,
    required int appointmentId,
  }) async {
    await post(ApiConfig.appointmentCancel(locationId, appointmentId));
  }

  /// POST /v1/bookings/{booking_id}/items
  /// Add a new booking item (appointment) to an existing booking
  Future<Map<String, dynamic>> addBookingItem({
    required int bookingId,
    required int locationId,
    required int staffId,
    required int serviceId,
    required int serviceVariantId,
    required String startTime,
    required String endTime,
    String? serviceNameSnapshot,
    String? clientNameSnapshot,
    double? price,
    int? extraBlockedMinutes,
    int? extraProcessingMinutes,
  }) async {
    final data = <String, dynamic>{
      'location_id': locationId,
      'staff_id': staffId,
      'service_id': serviceId,
      'service_variant_id': serviceVariantId,
      'start_time': startTime,
      'end_time': endTime,
    };
    if (serviceNameSnapshot != null) {
      data['service_name_snapshot'] = serviceNameSnapshot;
    }
    if (clientNameSnapshot != null) {
      data['client_name_snapshot'] = clientNameSnapshot;
    }
    if (price != null) data['price'] = price;
    if (extraBlockedMinutes != null) {
      data['extra_blocked_minutes'] = extraBlockedMinutes;
    }
    if (extraProcessingMinutes != null) {
      data['extra_processing_minutes'] = extraProcessingMinutes;
    }

    try {
      final response = await _dio.post(
        ApiConfig.bookingItems(bookingId),
        data: data,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE /v1/bookings/{booking_id}/items/{item_id}
  /// Delete a single booking item (appointment) from a booking
  Future<void> deleteBookingItem({
    required int bookingId,
    required int itemId,
  }) async {
    try {
      await _dio.delete(ApiConfig.bookingItem(bookingId, itemId));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /v1/locations/{location_id}/bookings?date=YYYY-MM-DD
  Future<Map<String, dynamic>> getBookings({
    required int locationId,
    required String date,
    int? staffId,
  }) async {
    final params = <String, dynamic>{'date': date};
    if (staffId != null) {
      params['staff_id'] = staffId;
    }
    return get(ApiConfig.bookings(locationId), queryParameters: params);
  }

  /// GET /v1/locations/{location_id}/bookings/{booking_id}
  Future<Map<String, dynamic>> getBooking({
    required int locationId,
    required int bookingId,
  }) async {
    return get(ApiConfig.booking(locationId, bookingId));
  }

  /// GET /v1/bookings/{booking_id}/history
  Future<Map<String, dynamic>> getBookingHistory({
    required int bookingId,
  }) async {
    return get(ApiConfig.bookingHistory(bookingId));
  }

  /// POST /v1/locations/{location_id}/bookings
  Future<Map<String, dynamic>> createBooking({
    required int locationId,
    required String idempotencyKey,
    required List<int> serviceIds,
    required String startTime,
    int? staffId,
    int? clientId,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'service_ids': serviceIds,
      'start_time': startTime,
    };
    if (staffId != null) {
      data['staff_id'] = staffId;
    }
    if (clientId != null) {
      data['client_id'] = clientId;
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

  /// POST /v1/locations/{location_id}/bookings (new items format)
  Future<Map<String, dynamic>> createBookingWithItems({
    required int locationId,
    required String idempotencyKey,
    required List<Map<String, dynamic>> items,
    int? clientId,
    String? notes,
  }) async {
    final data = <String, dynamic>{'items': items};
    if (clientId != null) {
      data['client_id'] = clientId;
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

  /// PUT /v1/locations/{location_id}/bookings/{booking_id}
  Future<Map<String, dynamic>> updateBooking({
    required int locationId,
    required int bookingId,
    String? status,
    String? notes,
    int? clientId,
    bool clearClient = false,
  }) async {
    final data = <String, dynamic>{};
    if (status != null) {
      data['status'] = status;
    }
    if (notes != null) {
      data['notes'] = notes;
    }
    // clearClient: invia client_id: null per rimuovere il cliente
    // clientId: invia client_id: valore per assegnare un cliente
    if (clearClient) {
      data['client_id'] = null;
    } else if (clientId != null) {
      data['client_id'] = clientId;
    }
    return put(ApiConfig.booking(locationId, bookingId), data: data);
  }

  /// DELETE /v1/locations/{location_id}/bookings/{booking_id}
  Future<void> deleteBooking({
    required int locationId,
    required int bookingId,
  }) async {
    await delete(ApiConfig.booking(locationId, bookingId));
  }

  /// GET /v1/businesses/{business_id}/bookings/list
  /// Lista prenotazioni con filtri avanzati per il gestionale.
  Future<Map<String, dynamic>> getBookingsList({
    required int businessId,
    int? locationId,
    List<int>? locationIds,
    int? staffId,
    List<int>? staffIds,
    List<int>? serviceIds,
    String? clientSearch,
    List<String>? status,
    String? source,
    String? startDate,
    String? endDate,
    bool includePast = false,
    String sortBy = 'appointment', // 'appointment' or 'created'
    String sortOrder = 'desc', // 'asc' or 'desc'
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParameters = <String, dynamic>{
      'include_past': includePast ? 'true' : 'false',
      'sort_by': sortBy,
      'sort_order': sortOrder,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    // Support both single and multi-select
    if (locationIds != null && locationIds.isNotEmpty) {
      queryParameters['location_ids'] = locationIds.join(',');
    } else if (locationId != null) {
      queryParameters['location_id'] = locationId.toString();
    }
    if (staffIds != null && staffIds.isNotEmpty) {
      queryParameters['staff_ids'] = staffIds.join(',');
    } else if (staffId != null) {
      queryParameters['staff_id'] = staffId.toString();
    }
    if (serviceIds != null && serviceIds.isNotEmpty) {
      queryParameters['service_ids'] = serviceIds.join(',');
    }
    if (clientSearch != null && clientSearch.isNotEmpty) {
      queryParameters['client_search'] = clientSearch;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status.join(',');
    }
    if (source != null && source.isNotEmpty) {
      queryParameters['source'] = source;
    }
    if (startDate != null) {
      queryParameters['start_date'] = startDate;
    }
    if (endDate != null) {
      queryParameters['end_date'] = endDate;
    }

    return get(
      ApiConfig.bookingsList(businessId),
      queryParameters: queryParameters,
    );
  }

  /// GET /v1/businesses/{business_id}/booking-notifications
  /// Lista notifiche associate alle prenotazioni.
  Future<Map<String, dynamic>> getBookingNotifications({
    required int businessId,
    String? search,
    List<String>? status,
    List<String>? channels,
    String? startDate,
    String? endDate,
    String sortBy = 'created', // 'created' | 'scheduled' | 'sent'
    String sortOrder = 'desc', // 'asc' | 'desc'
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParameters = <String, dynamic>{
      'sort_by': sortBy,
      'sort_order': sortOrder,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status.join(',');
    }
    if (channels != null && channels.isNotEmpty) {
      queryParameters['channel'] = channels.join(',');
    }
    if (startDate != null) {
      queryParameters['start_date'] = startDate;
    }
    if (endDate != null) {
      queryParameters['end_date'] = endDate;
    }

    return get(
      ApiConfig.bookingNotifications(businessId),
      queryParameters: queryParameters,
    );
  }

  /// GET /v1/businesses
  Future<List<Map<String, dynamic>>> getBusinesses() async {
    final response = await get('/v1/businesses');
    // API ritorna { data: { data: [...] } } per lista business
    final data = response['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    // Se è un oggetto con chiave 'data' o 'businesses'
    if (data is Map) {
      final list = data['data'] ?? data['businesses'] ?? [];
      return (list as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// GET /v1/admin/businesses
  /// Superadmin only: lista tutti i business.
  Future<List<Map<String, dynamic>>> getAdminBusinesses({
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    final response = await get(
      '/v1/admin/businesses',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    // _handleResponse ritorna body['data'], quindi response = { businesses: [...], pagination: {...} }
    return (response['businesses'] as List).cast<Map<String, dynamic>>();
  }

  /// POST /v1/admin/businesses
  /// Superadmin only: crea un nuovo business.
  /// Se adminEmail fornito, invia email di benvenuto all'admin con link per impostare password.
  Future<Map<String, dynamic>> createAdminBusiness({
    required String name,
    required String slug,
    String? adminEmail,
    String? email,
    String? phone,
    String? onlineBookingsNotificationEmail,
    String? serviceColorPalette,
    String timezone = 'Europe/Rome',
    String currency = 'EUR',
    String? adminFirstName,
    String? adminLastName,
  }) async {
    final response = await post(
      '/v1/admin/businesses',
      data: {
        'name': name,
        'slug': slug,
        if (adminEmail != null && adminEmail.isNotEmpty)
          'admin_email': adminEmail,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (onlineBookingsNotificationEmail != null)
          'online_bookings_notification_email': onlineBookingsNotificationEmail,
        if (serviceColorPalette != null)
          'service_color_palette': serviceColorPalette,
        'timezone': timezone,
        'currency': currency,
        if (adminFirstName != null) 'admin_first_name': adminFirstName,
        if (adminLastName != null) 'admin_last_name': adminLastName,
      },
    );
    // _handleResponse già ritorna body['data'], quindi response È il business
    return response;
  }

  /// PUT /v1/admin/businesses/{id}
  /// Superadmin only: aggiorna un business esistente.
  /// Se adminEmail cambia, trasferisce ownership e invia email al nuovo admin.
  Future<Map<String, dynamic>> updateAdminBusiness({
    required int businessId,
    String? name,
    String? slug,
    String? email,
    String? phone,
    String? onlineBookingsNotificationEmail,
    String? serviceColorPalette,
    String? timezone,
    String? currency,
    String? adminEmail,
  }) async {
    final response = await put(
      '/v1/admin/businesses/$businessId',
      data: {
        if (name != null) 'name': name,
        if (slug != null) 'slug': slug,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (onlineBookingsNotificationEmail != null)
          'online_bookings_notification_email': onlineBookingsNotificationEmail,
        if (serviceColorPalette != null)
          'service_color_palette': serviceColorPalette,
        if (timezone != null) 'timezone': timezone,
        if (currency != null) 'currency': currency,
        if (adminEmail != null) 'admin_email': adminEmail,
      },
    );
    return response;
  }

  /// POST /v1/admin/businesses/{id}/resend-invite
  /// Superadmin only: reinvia email di invito all'admin.
  Future<void> resendAdminInvite(int businessId) async {
    await post('/v1/admin/businesses/$businessId/resend-invite');
  }

  /// PUT /v1/admin/businesses/{id}/suspend
  /// Superadmin only: sospende un business con messaggio opzionale.
  Future<Map<String, dynamic>> suspendBusiness({
    required int businessId,
    required bool isSuspended,
    String? suspensionMessage,
  }) async {
    final response = await put(
      '/v1/admin/businesses/$businessId',
      data: {
        'is_suspended': isSuspended,
        if (suspensionMessage != null) 'suspension_message': suspensionMessage,
        if (!isSuspended) 'suspension_message': null,
      },
    );
    return response;
  }

  /// DELETE /v1/admin/businesses/{id}
  /// Superadmin only: soft-delete un business (is_active = 0).
  Future<void> deleteAdminBusiness(int businessId) async {
    await delete('/v1/admin/businesses/$businessId');
  }

  // ========== LOCATIONS CRUD ==========

  /// GET /v1/businesses/{business_id}/locations
  Future<List<Map<String, dynamic>>> getLocations(int businessId) async {
    final response = await get('/v1/businesses/$businessId/locations');
    final locations =
        response['locations'] ?? response['_list'] ?? response['data'];
    if (locations is List) {
      return locations.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  /// POST /v1/businesses/{business_id}/locations
  Future<Map<String, dynamic>> createLocation({
    required int businessId,
    required String name,
    String? address,
    String? phone,
    String? email,
    String? timezone,
    int? minBookingNoticeHours,
    int? maxBookingAdvanceDays,
    bool? allowCustomerChooseStaff,
    bool? isActive,
  }) async {
    final response = await post(
      '/v1/businesses/$businessId/locations',
      data: {
        'name': name,
        if (address != null && address.isNotEmpty) 'address': address,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
        if (minBookingNoticeHours != null)
          'min_booking_notice_hours': minBookingNoticeHours,
        if (maxBookingAdvanceDays != null)
          'max_booking_advance_days': maxBookingAdvanceDays,
        if (allowCustomerChooseStaff != null)
          'allow_customer_choose_staff': allowCustomerChooseStaff,
        if (isActive != null) 'is_active': isActive,
      },
    );
    final location = response['location'];
    if (location is Map<String, dynamic>) {
      return location;
    }
    if (location is Map) {
      return Map<String, dynamic>.from(location);
    }
    return _asMapPayload(response);
  }

  /// PUT /v1/locations/{id}
  Future<Map<String, dynamic>> updateLocation({
    required int locationId,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? timezone,
    int? minBookingNoticeHours,
    int? maxBookingAdvanceDays,
    bool? allowCustomerChooseStaff,
    int? slotIntervalMinutes,
    String? slotDisplayMode,
    int? minGapMinutes,
    bool? isActive,
  }) async {
    final response = await put(
      '/v1/locations/$locationId',
      data: {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (timezone != null) 'timezone': timezone,
        if (minBookingNoticeHours != null)
          'min_booking_notice_hours': minBookingNoticeHours,
        if (maxBookingAdvanceDays != null)
          'max_booking_advance_days': maxBookingAdvanceDays,
        if (allowCustomerChooseStaff != null)
          'allow_customer_choose_staff': allowCustomerChooseStaff,
        if (slotIntervalMinutes != null)
          'slot_interval_minutes': slotIntervalMinutes,
        if (slotDisplayMode != null) 'slot_display_mode': slotDisplayMode,
        if (minGapMinutes != null) 'min_gap_minutes': minGapMinutes,
        if (isActive != null) 'is_active': isActive,
      },
    );
    final location = response['location'];
    if (location is Map<String, dynamic>) {
      return location;
    }
    if (location is Map) {
      return Map<String, dynamic>.from(location);
    }
    return _asMapPayload(response);
  }

  /// DELETE /v1/locations/{id}
  Future<void> deleteLocation(int locationId) async {
    await delete('/v1/locations/$locationId');
  }

  /// POST /v1/locations/reorder - Batch update locations sort_order
  Future<Map<String, dynamic>> reorderLocations({
    required List<Map<String, dynamic>> locations,
  }) async {
    return post('/v1/locations/reorder', data: {'locations': locations});
  }

  // ========== SERVICES CRUD ==========

  /// POST /v1/businesses/{business_id}/services
  /// Creates a service with variants for multiple locations
  Future<Map<String, dynamic>> createServiceMultiLocation({
    required int businessId,
    required List<int> locationIds,
    required String name,
    int? categoryId,
    String? description,
    int durationMinutes = 30,
    double price = 0,
    String? colorHex,
    bool isBookableOnline = true,
    bool isPriceStartingFrom = false,
    int? processingTime,
    int? blockedTime,
  }) async {
    final response = await post(
      '/v1/businesses/$businessId/services',
      data: {
        'name': name,
        'location_ids': locationIds,
        if (categoryId != null) 'category_id': categoryId,
        if (description != null && description.isNotEmpty)
          'description': description,
        'duration_minutes': durationMinutes,
        'price': price,
        if (colorHex != null && colorHex.isNotEmpty) 'color': colorHex,
        'is_bookable_online': isBookableOnline,
        'is_price_starting_from': isPriceStartingFrom,
        if (processingTime != null) 'processing_time': processingTime,
        if (blockedTime != null) 'blocked_time': blockedTime,
      },
    );
    return response;
  }

  /// POST /v1/locations/{location_id}/services
  Future<Map<String, dynamic>> createService({
    required int locationId,
    required String name,
    int? categoryId,
    String? description,
    int durationMinutes = 30,
    double price = 0,
    String? colorHex,
    bool isBookableOnline = true,
    bool isPriceStartingFrom = false,
    int? processingTime,
    int? blockedTime,
  }) async {
    final response = await post(
      '/v1/locations/$locationId/services',
      data: {
        'name': name,
        if (categoryId != null) 'category_id': categoryId,
        if (description != null && description.isNotEmpty)
          'description': description,
        'duration_minutes': durationMinutes,
        'price': price,
        if (colorHex != null && colorHex.isNotEmpty) 'color': colorHex,
        'is_bookable_online': isBookableOnline,
        'is_price_starting_from': isPriceStartingFrom,
        if (processingTime != null) 'processing_time': processingTime,
        if (blockedTime != null) 'blocked_time': blockedTime,
      },
    );
    return response;
  }

  /// PUT /v1/services/{id}
  Future<Map<String, dynamic>> updateService({
    required int serviceId,
    required int locationId,
    String? name,
    int? categoryId,
    bool setCategoryIdNull = false,
    String? description,
    bool setDescriptionNull = false,
    int? durationMinutes,
    double? price,
    String? colorHex,
    bool? isBookableOnline,
    bool? isPriceStartingFrom,
    int? sortOrder,
    int? processingTime,
    int? blockedTime,
  }) async {
    final response = await put(
      '/v1/services/$serviceId',
      data: {
        'location_id': locationId,
        if (name != null) 'name': name,
        if (setCategoryIdNull)
          'category_id': null
        else if (categoryId != null)
          'category_id': categoryId,
        if (setDescriptionNull)
          'set_description_null': true
        else if (description != null)
          'description': description,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (price != null) 'price': price,
        if (colorHex != null) 'color': colorHex,
        if (isBookableOnline != null) 'is_bookable_online': isBookableOnline,
        if (isPriceStartingFrom != null)
          'is_price_starting_from': isPriceStartingFrom,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (processingTime != null) 'processing_time': processingTime,
        if (blockedTime != null) 'blocked_time': blockedTime,
      },
    );
    return response;
  }

  /// DELETE /v1/services/{id}
  Future<void> deleteService(int serviceId) async {
    await delete('/v1/services/$serviceId');
  }

  /// GET /v1/services/{id}/locations
  /// Returns the list of location IDs where this service has an active variant.
  Future<List<int>> getServiceLocations(int serviceId) async {
    final response = await get('/v1/services/$serviceId/locations');
    final locationIds = response['location_ids'] as List<dynamic>? ?? [];
    return locationIds.map((e) => e as int).toList();
  }

  /// PUT /v1/services/{id}/locations
  /// Updates the locations associated with a service.
  Future<List<int>> updateServiceLocations({
    required int serviceId,
    required List<int> locationIds,
  }) async {
    final response = await put(
      '/v1/services/$serviceId/locations',
      data: {'location_ids': locationIds},
    );
    final updatedIds = response['location_ids'] as List<dynamic>? ?? [];
    return updatedIds.map((e) => e as int).toList();
  }

  // ========== SERVICE CATEGORIES CRUD ==========

  /// GET /v1/businesses/{business_id}/categories
  Future<Map<String, dynamic>> getServiceCategories(int businessId) async {
    return get('/v1/businesses/$businessId/categories');
  }

  /// POST /v1/businesses/{business_id}/categories
  Future<Map<String, dynamic>> createServiceCategory({
    required int businessId,
    required String name,
    String? description,
  }) async {
    return post(
      '/v1/businesses/$businessId/categories',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
  }

  /// PUT /v1/categories/{id}
  Future<Map<String, dynamic>> updateServiceCategory({
    required int categoryId,
    String? name,
    String? description,
    int? sortOrder,
  }) async {
    return put(
      '/v1/categories/$categoryId',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
  }

  /// DELETE /v1/categories/{id}
  Future<void> deleteServiceCategory(int categoryId) async {
    await delete('/v1/categories/$categoryId');
  }

  /// POST /v1/services/reorder - Batch update services sort_order and category_id
  Future<Map<String, dynamic>> reorderServices({
    required List<Map<String, dynamic>> services,
  }) async {
    return post('/v1/services/reorder', data: {'services': services});
  }

  /// POST /v1/service-packages/reorder - Batch update packages sort_order and category_id
  Future<Map<String, dynamic>> reorderServicePackages({
    required List<Map<String, dynamic>> packages,
  }) async {
    return post('/v1/service-packages/reorder', data: {'packages': packages});
  }

  /// POST /v1/categories/reorder - Batch update categories sort_order
  Future<Map<String, dynamic>> reorderCategories({
    required List<Map<String, dynamic>> categories,
  }) async {
    return post('/v1/categories/reorder', data: {'categories': categories});
  }

  // ========== SERVICE VARIANT RESOURCES ==========

  /// GET /v1/service-variants/{id}/resources
  Future<Map<String, dynamic>> getServiceVariantResources(
    int serviceVariantId,
  ) async {
    return get('/v1/service-variants/$serviceVariantId/resources');
  }

  /// PUT /v1/service-variants/{id}/resources - Replace all resource requirements
  Future<Map<String, dynamic>> setServiceVariantResources({
    required int serviceVariantId,
    required List<Map<String, dynamic>> resources,
  }) async {
    return put(
      '/v1/service-variants/$serviceVariantId/resources',
      data: {'resources': resources},
    );
  }

  /// POST /v1/service-variants/{id}/resources - Add single resource requirement
  Future<Map<String, dynamic>> addServiceVariantResource({
    required int serviceVariantId,
    required int resourceId,
    int quantity = 1,
  }) async {
    return post(
      '/v1/service-variants/$serviceVariantId/resources',
      data: {'resource_id': resourceId, 'quantity': quantity},
    );
  }

  /// DELETE /v1/service-variants/{id}/resources/{resource_id}
  Future<void> removeServiceVariantResource({
    required int serviceVariantId,
    required int resourceId,
  }) async {
    await delete(
      '/v1/service-variants/$serviceVariantId/resources/$resourceId',
    );
  }

  /// GET /v1/resources/{id}/services - Get services that require this resource
  Future<Map<String, dynamic>> getResourceServices(int resourceId) async {
    return get('/v1/resources/$resourceId/services');
  }

  /// PUT /v1/resources/{id}/services - Set services that require this resource
  Future<Map<String, dynamic>> setResourceServices({
    required int resourceId,
    required List<Map<String, dynamic>> services,
  }) async {
    return put(
      '/v1/resources/$resourceId/services',
      data: {'services': services},
    );
  }

  // ========== STAFF CRUD ==========

  /// GET /v1/businesses/{business_id}/staff
  Future<List<Map<String, dynamic>>> getStaffByBusiness(int businessId) async {
    final response = await get('/v1/businesses/$businessId/staff');
    final staff = response['staff'] ?? response['_list'];
    if (staff is List) {
      return staff.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  /// POST /v1/businesses/{business_id}/staff
  Future<Map<String, dynamic>> createStaff({
    required int businessId,
    required String name,
    String? surname,
    String? colorHex,
    String? avatarUrl,
    bool? isBookableOnline,
    List<int>? locationIds,
    List<int>? serviceIds,
  }) async {
    final response = await post(
      '/v1/businesses/$businessId/staff',
      data: {
        'name': name,
        if (surname != null && surname.isNotEmpty) 'surname': surname,
        if (colorHex != null) 'color_hex': colorHex,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (isBookableOnline != null) 'is_bookable_online': isBookableOnline,
        if (locationIds != null && locationIds.isNotEmpty)
          'location_ids': locationIds,
        if (serviceIds != null) 'service_ids': serviceIds,
      },
    );
    final staff = response['staff'];
    if (staff is Map<String, dynamic>) {
      return staff;
    }
    if (staff is Map) {
      return Map<String, dynamic>.from(staff);
    }
    return _asMapPayload(response);
  }

  /// PUT /v1/staff/{id}
  Future<Map<String, dynamic>> updateStaff({
    required int staffId,
    String? name,
    String? surname,
    String? colorHex,
    String? avatarUrl,
    bool? isBookableOnline,
    int? sortOrder,
    List<int>? locationIds,
    List<int>? serviceIds,
  }) async {
    final response = await put(
      '/v1/staff/$staffId',
      data: {
        if (name != null) 'name': name,
        if (surname != null) 'surname': surname,
        if (colorHex != null) 'color_hex': colorHex,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (isBookableOnline != null) 'is_bookable_online': isBookableOnline,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (locationIds != null) 'location_ids': locationIds,
        if (serviceIds != null) 'service_ids': serviceIds,
      },
    );
    final staff = response['staff'];
    if (staff is Map<String, dynamic>) {
      return staff;
    }
    if (staff is Map) {
      return Map<String, dynamic>.from(staff);
    }
    return _asMapPayload(response);
  }

  /// DELETE /v1/staff/{id}
  Future<void> deleteStaff(int staffId) async {
    await delete('/v1/staff/$staffId');
  }

  /// POST /v1/staff/reorder - Batch update staff sort_order
  Future<Map<String, dynamic>> reorderStaff({
    required List<Map<String, dynamic>> staff,
  }) async {
    return post('/v1/staff/reorder', data: {'staff': staff});
  }

  // ========== BUSINESS USERS (OPERATORS) ==========

  /// GET /v1/businesses/{business_id}/users
  /// Lista operatori di un business.
  Future<List<Map<String, dynamic>>> getBusinessUsers(int businessId) async {
    final response = await get(ApiConfig.businessUsers(businessId));
    final users = response['users'] ?? response['_list'];
    if (users is List) {
      return users.cast<Map<String, dynamic>>();
    }
    return const <Map<String, dynamic>>[];
  }

  /// POST /v1/businesses/{business_id}/users
  /// Aggiunge un utente esistente al business.
  Future<Map<String, dynamic>> addBusinessUser({
    required int businessId,
    required int userId,
    required String role,
  }) async {
    final response = await post(
      ApiConfig.businessUsers(businessId),
      data: {'user_id': userId, 'role': role},
    );
    return _asMapPayload(response);
  }

  /// PATCH /v1/businesses/{business_id}/users/{user_id}
  /// Aggiorna il ruolo e lo scope di un operatore.
  Future<Map<String, dynamic>> updateBusinessUser({
    required int businessId,
    required int userId,
    required String role,
    String? scopeType,
    List<int>? locationIds,
    int? staffId,
  }) async {
    final data = <String, dynamic>{'role': role};
    if (scopeType != null) data['scope_type'] = scopeType;
    if (locationIds != null) data['location_ids'] = locationIds;
    if (staffId != null) {
      data['staff_id'] = staffId;
    } else if (role != 'staff') {
      // Clear staff link when moving away from staff role.
      data['staff_id'] = null;
    }

    final response = await patch(
      ApiConfig.businessUser(businessId, userId),
      data: data,
    );
    return _asMapPayload(response);
  }

  /// DELETE /v1/businesses/{business_id}/users/{user_id}
  /// Rimuove un operatore dal business.
  Future<void> removeBusinessUser({
    required int businessId,
    required int userId,
  }) async {
    await delete(ApiConfig.businessUser(businessId, userId));
  }

  /// GET /v1/me/business/{business_id}
  /// Ottiene il contesto dell'utente corrente per un business (scope_type, location_ids).
  Future<Map<String, dynamic>> getMyBusinessContext(int businessId) async {
    final response = await get('/v1/me/business/$businessId');
    return _asMapPayload(response);
  }

  // ========== BUSINESS INVITATIONS ==========

  /// GET /v1/businesses/{business_id}/invitations
  /// Lista inviti del business.
  Future<List<Map<String, dynamic>>> getBusinessInvitations(
    int businessId, {
    String status = 'pending',
  }) async {
    final response = await get(
      ApiConfig.businessInvitations(businessId),
      queryParameters: {'status': status},
    );
    final invitations = response['invitations'] ?? response['_list'];
    if (invitations is List) {
      return invitations.cast<Map<String, dynamic>>();
    }
    return const <Map<String, dynamic>>[];
  }

  /// POST /v1/businesses/{business_id}/invitations
  /// Crea un nuovo invito via email.
  Future<Map<String, dynamic>> createBusinessInvitation({
    required int businessId,
    required String email,
    required String role,
    String scopeType = 'business',
    List<int>? locationIds,
    int? staffId,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'role': role,
      'scope_type': scopeType,
    };
    if (locationIds != null && locationIds.isNotEmpty) {
      data['location_ids'] = locationIds;
    }
    if (staffId != null) {
      data['staff_id'] = staffId;
    }

    final response = await post(
      ApiConfig.businessInvitations(businessId),
      data: data,
    );
    return _asMapPayload(response);
  }

  /// DELETE /v1/businesses/{business_id}/invitations/{invitation_id}
  /// Revoca un invito pendente.
  Future<void> revokeBusinessInvitation({
    required int businessId,
    required int invitationId,
  }) async {
    await delete(ApiConfig.businessInvitation(businessId, invitationId));
  }

  /// GET /v1/invitations/{token}
  /// Dettagli di un invito (endpoint pubblico).
  Future<Map<String, dynamic>> getInvitationByToken(String token) async {
    final response = await get(ApiConfig.invitationByToken(token));
    return _asMapPayload(response);
  }

  /// POST /v1/invitations/{token}/accept
  /// Accetta un invito (richiede autenticazione).
  Future<Map<String, dynamic>> acceptInvitation(String token) async {
    final response = await post(ApiConfig.acceptInvitation(token));
    return _asMapPayload(response);
  }

  /// POST /v1/invitations/{token}/accept-public
  /// Accetta invito senza autenticazione (account già esistente).
  Future<Map<String, dynamic>> acceptInvitationPublic(String token) async {
    final response = await post(ApiConfig.acceptInvitationPublic(token));
    return _asMapPayload(response);
  }

  /// POST /v1/invitations/{token}/decline
  /// Rifiuta un invito (richiede autenticazione).
  Future<Map<String, dynamic>> declineInvitation(String token) async {
    final response = await post(ApiConfig.declineInvitation(token));
    return _asMapPayload(response);
  }

  /// POST /v1/invitations/{token}/register
  /// Crea account operatore da invito e accetta invito.
  Future<Map<String, dynamic>> registerInvitation({
    required String token,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final response = await post(
      ApiConfig.registerInvitation(token),
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
      },
    );
    final data = _asMapPayload(response);
    if (data['access_token'] is String) {
      _accessToken = data['access_token'] as String;
    }
    if (data['refresh_token'] is String) {
      await _tokenStorage.saveRefreshToken(data['refresh_token'] as String);
    }
    return data;
  }

  /// Normalizza payload map per endpoint legacy/nuovi.
  /// `_handleResponse` ritorna già `data`, ma alcuni endpoint possono
  /// ancora essere wrappati in `{ data: {...} }`.
  Map<String, dynamic> _asMapPayload(Map<String, dynamic> response) {
    final nested = response['data'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    return response;
  }

  // ========== STAFF SCHEDULES ==========

  /// GET /v1/businesses/{business_id}/staff/schedules
  /// Ottiene gli schedules di tutti gli staff di un business.
  /// Ritorna `Map<int, Map<int, List<Map>>>` (staffId -> day -> shifts)
  Future<Map<int, Map<int, List<Map<String, String>>>>> getStaffSchedulesAll(
    int businessId,
  ) async {
    final response = await get(ApiConfig.staffSchedulesAll(businessId));
    // _handleResponse già ritorna body['data'], quindi response = { schedules: {...} }
    final data = response['schedules'];
    if (data is! Map<String, dynamic>) {
      return const <int, Map<int, List<Map<String, String>>>>{};
    }

    final Map<int, Map<int, List<Map<String, String>>>> result = {};
    for (final entry in data.entries) {
      final staffId = int.parse(entry.key);
      if (entry.value is! Map<String, dynamic>) {
        continue;
      }
      final weekData = entry.value as Map<String, dynamic>;

      result[staffId] = {};
      for (final dayEntry in weekData.entries) {
        final day = int.parse(dayEntry.key);
        final shifts = (dayEntry.value as List)
            .map(
              (s) => {
                'start_time': s['start_time'] as String,
                'end_time': s['end_time'] as String,
              },
            )
            .toList();
        result[staffId]![day] = shifts;
      }
    }
    return result;
  }

  /// GET /v1/staff/{id}/schedules
  /// Ottiene lo schedule settimanale di uno staff.
  /// Ritorna `Map<int, List<Map>>` (day -> shifts)
  Future<Map<int, List<Map<String, String>>>> getStaffSchedule(
    int staffId,
  ) async {
    final response = await get(ApiConfig.staffSchedule(staffId));
    // _handleResponse già ritorna body['data'], quindi response = { staff_id: X, schedule: {...} }
    final data = response['schedule'];
    if (data is! Map<String, dynamic>) {
      return const <int, List<Map<String, String>>>{};
    }

    final Map<int, List<Map<String, String>>> result = {};
    for (final entry in data.entries) {
      final day = int.parse(entry.key);
      final shifts = (entry.value as List)
          .map(
            (s) => {
              'start_time': s['start_time'] as String,
              'end_time': s['end_time'] as String,
            },
          )
          .toList();
      result[day] = shifts;
    }
    return result;
  }

  /// PUT /v1/staff/{id}/schedules
  /// Salva lo schedule settimanale di uno staff (sostituisce l'esistente).
  Future<Map<int, List<Map<String, String>>>> saveStaffSchedule({
    required int staffId,
    required Map<int, List<Map<String, String>>> schedule,
  }) async {
    // Converti keys da int a String per JSON
    final scheduleJson = <String, dynamic>{};
    for (final entry in schedule.entries) {
      scheduleJson[entry.key.toString()] = entry.value;
    }

    final response = await put(
      ApiConfig.staffSchedule(staffId),
      data: {'schedule': scheduleJson},
    );

    // _handleResponse già ritorna body['data'], quindi response = { staff_id: X, schedule: {...} }
    final data = response['schedule'];
    if (data is! Map<String, dynamic>) {
      return const <int, List<Map<String, String>>>{};
    }
    final Map<int, List<Map<String, String>>> result = {};
    for (final entry in data.entries) {
      final day = int.parse(entry.key);
      final shifts = (entry.value as List)
          .map(
            (s) => {
              'start_time': s['start_time'] as String,
              'end_time': s['end_time'] as String,
            },
          )
          .toList();
      result[day] = shifts;
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Staff Availability Exceptions
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get all availability exceptions for all staff in a business
  /// GET /v1/businesses/{businessId}/staff/availability-exceptions
  Future<Map<int, List<Map<String, dynamic>>>>
  getStaffAvailabilityExceptionsAll(
    int businessId, {
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams['from_date'] = fromDate;
    if (toDate != null) queryParams['to_date'] = toDate;

    final response = await get(
      '/v1/businesses/$businessId/staff/availability-exceptions',
      queryParameters: queryParams,
    );

    // response = { exceptions: { staffId: [...], ... } }
    final exceptionsMap = response['exceptions'];
    if (exceptionsMap is! Map<String, dynamic>) {
      return const <int, List<Map<String, dynamic>>>{};
    }
    final Map<int, List<Map<String, dynamic>>> result = {};

    for (final entry in exceptionsMap.entries) {
      final staffId = int.parse(entry.key);
      final exceptionsList = (entry.value as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      result[staffId] = exceptionsList;
    }

    return result;
  }

  /// Get availability exceptions for a single staff member
  /// GET /v1/staff/{staffId}/availability-exceptions
  Future<List<Map<String, dynamic>>> getStaffAvailabilityExceptions(
    int staffId, {
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams['from_date'] = fromDate;
    if (toDate != null) queryParams['to_date'] = toDate;

    final response = await get(
      '/v1/staff/$staffId/availability-exceptions',
      queryParameters: queryParams,
    );

    // response = { staff_id: X, exceptions: [...] }
    final exceptions = (response['exceptions'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return exceptions;
  }

  /// Create a new availability exception for a staff member
  /// POST /v1/staff/{staffId}/availability-exceptions
  Future<Map<String, dynamic>> createStaffAvailabilityException({
    required int staffId,
    required String date,
    String? startTime,
    String? endTime,
    String type = 'unavailable',
    String? reasonCode,
    String? reason,
  }) async {
    final data = <String, dynamic>{'date': date, 'type': type};
    if (startTime != null) data['start_time'] = startTime;
    if (endTime != null) data['end_time'] = endTime;
    if (reasonCode != null) data['reason_code'] = reasonCode;
    if (reason != null) data['reason'] = reason;

    final response = await post(
      '/v1/staff/$staffId/availability-exceptions',
      data: data,
    );

    // response = { exception: {...} }
    return Map<String, dynamic>.from(response['exception'] as Map);
  }

  /// Update an existing availability exception
  /// PUT /v1/staff/availability-exceptions/{exceptionId}
  Future<Map<String, dynamic>> updateStaffAvailabilityException({
    required int exceptionId,
    String? date,
    String? startTime,
    String? endTime,
    String? type,
    String? reasonCode,
    String? reason,
  }) async {
    final data = <String, dynamic>{};
    if (date != null) data['date'] = date;
    if (startTime != null) data['start_time'] = startTime;
    if (endTime != null) data['end_time'] = endTime;
    if (type != null) data['type'] = type;
    if (reasonCode != null) data['reason_code'] = reasonCode;
    if (reason != null) data['reason'] = reason;

    final response = await put(
      '/v1/staff/availability-exceptions/$exceptionId',
      data: data,
    );

    // response = { exception: {...} }
    return Map<String, dynamic>.from(response['exception'] as Map);
  }

  /// Delete an availability exception
  /// DELETE /v1/staff/availability-exceptions/{exceptionId}
  Future<void> deleteStaffAvailabilityException(int exceptionId) async {
    await delete('/v1/staff/availability-exceptions/$exceptionId');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Resources
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get all resources for a business
  /// GET /v1/businesses/{businessId}/resources
  Future<List<Map<String, dynamic>>> getResourcesByBusiness(
    int businessId,
  ) async {
    final response = await get('/v1/businesses/$businessId/resources');
    return (response['resources'] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  /// Get resources for a location
  /// GET /v1/locations/{locationId}/resources
  Future<List<Map<String, dynamic>>> getResourcesByLocation(
    int locationId,
  ) async {
    final response = await get('/v1/locations/$locationId/resources');
    return (response['resources'] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  /// Create a new resource
  /// POST /v1/locations/{locationId}/resources
  Future<Map<String, dynamic>> createResource({
    required int locationId,
    required String name,
    String? type,
    int quantity = 1,
    String? note,
    int sortOrder = 0,
  }) async {
    final response = await post(
      '/v1/locations/$locationId/resources',
      data: {
        'name': name,
        if (type != null) 'type': type,
        'quantity': quantity,
        if (note != null) 'note': note,
        'sort_order': sortOrder,
      },
    );
    return Map<String, dynamic>.from(response['resource'] as Map);
  }

  /// Update a resource
  /// PUT /v1/resources/{resourceId}
  Future<Map<String, dynamic>> updateResource({
    required int resourceId,
    String? name,
    String? type,
    int? quantity,
    String? note,
    int? sortOrder,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (type != null) data['type'] = type;
    if (quantity != null) data['quantity'] = quantity;
    if (note != null) data['note'] = note;
    if (sortOrder != null) data['sort_order'] = sortOrder;

    final response = await put('/v1/resources/$resourceId', data: data);
    return Map<String, dynamic>.from(response['resource'] as Map);
  }

  /// Delete a resource
  /// DELETE /v1/resources/{resourceId}
  Future<void> deleteResource(int resourceId) async {
    await delete('/v1/resources/$resourceId');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Time Blocks
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get time blocks for a location in a date range
  /// GET /v1/locations/{locationId}/time-blocks
  Future<List<Map<String, dynamic>>> getTimeBlocks(
    int locationId, {
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams['from_date'] = fromDate;
    if (toDate != null) queryParams['to_date'] = toDate;

    final response = await get(
      '/v1/locations/$locationId/time-blocks',
      queryParameters: queryParams,
    );
    return (response['time_blocks'] as List)
        .map((b) => Map<String, dynamic>.from(b as Map))
        .toList();
  }

  /// Create a new time block
  /// POST /v1/locations/{locationId}/time-blocks
  Future<Map<String, dynamic>> createTimeBlock({
    required int locationId,
    required String startTime,
    required String endTime,
    required List<int> staffIds,
    bool isAllDay = false,
    String? reason,
  }) async {
    final response = await post(
      '/v1/locations/$locationId/time-blocks',
      data: {
        'start_time': startTime,
        'end_time': endTime,
        'staff_ids': staffIds,
        'is_all_day': isAllDay,
        if (reason != null) 'reason': reason,
      },
    );
    return Map<String, dynamic>.from(response['time_block'] as Map);
  }

  /// Update a time block
  /// PUT /v1/time-blocks/{blockId}
  Future<Map<String, dynamic>> updateTimeBlock({
    required int blockId,
    String? startTime,
    String? endTime,
    List<int>? staffIds,
    bool? isAllDay,
    String? reason,
  }) async {
    final data = <String, dynamic>{};
    if (startTime != null) data['start_time'] = startTime;
    if (endTime != null) data['end_time'] = endTime;
    if (staffIds != null) data['staff_ids'] = staffIds;
    if (isAllDay != null) data['is_all_day'] = isAllDay;
    if (reason != null) data['reason'] = reason;

    final response = await put('/v1/time-blocks/$blockId', data: data);
    return Map<String, dynamic>.from(response['time_block'] as Map);
  }

  /// Delete a time block
  /// DELETE /v1/time-blocks/{blockId}
  Future<void> deleteTimeBlock(int blockId) async {
    await delete('/v1/time-blocks/$blockId');
  }

  // ========== STAFF PLANNING ENDPOINTS ==========

  /// Get all plannings for a staff member
  /// GET /v1/staff/{staffId}/plannings
  Future<List<Map<String, dynamic>>> getStaffPlannings(int staffId) async {
    final response = await get(ApiConfig.staffPlannings(staffId));
    // _handleResponse wrappa le liste in {'_list': data}
    final plannings = response['_list'] as List<dynamic>? ?? [];
    return plannings.cast<Map<String, dynamic>>();
  }

  /// Get planning valid for a specific date
  /// GET /v1/staff/{staffId}/planning?date=YYYY-MM-DD
  Future<Map<String, dynamic>?> getStaffPlanningForDate({
    required int staffId,
    required String date,
  }) async {
    final response = await get(
      ApiConfig.staffPlanningForDate(staffId),
      queryParameters: {'date': date},
    );
    final planning = response['planning'];
    if (planning is Map<String, dynamic>) {
      return planning;
    }
    if (planning is Map) {
      return Map<String, dynamic>.from(planning);
    }
    return null;
  }

  /// Get available slots for a staff on a date
  /// GET /v1/staff/{staffId}/planning-availability?date=YYYY-MM-DD
  Future<List<int>> getStaffPlanningAvailability({
    required int staffId,
    required String date,
  }) async {
    final response = await get(
      ApiConfig.staffPlanningAvailability(staffId),
      queryParameters: {'date': date},
    );
    final slots = response['slots'] as List<dynamic>? ?? [];
    return slots.cast<int>();
  }

  /// Create a new staff planning
  /// POST /v1/staff/{staffId}/plannings
  Future<Map<String, dynamic>> createStaffPlanning({
    required int staffId,
    required String type,
    required String validFrom,
    String? validTo,
    required List<Map<String, dynamic>> templates,
  }) async {
    // _handleResponse già estrae body['data'], quindi response È il planning
    final response = await post(
      ApiConfig.staffPlannings(staffId),
      data: {
        'type': type,
        'valid_from': validFrom,
        if (validTo != null) 'valid_to': validTo,
        'templates': templates,
      },
    );
    return Map<String, dynamic>.from(response);
  }

  /// Update an existing staff planning
  /// PUT /v1/staff/{staffId}/plannings/{planningId}
  Future<Map<String, dynamic>> updateStaffPlanning({
    required int staffId,
    required int planningId,
    String? type,
    String? validFrom,
    String? validTo,
    bool setValidToNull = false,
    List<Map<String, dynamic>>? templates,
  }) async {
    final data = <String, dynamic>{};
    if (type != null) data['type'] = type;
    if (validFrom != null) data['valid_from'] = validFrom;
    if (validTo != null) {
      data['valid_to'] = validTo;
    } else if (setValidToNull) {
      data['valid_to'] = null;
    }
    if (templates != null) data['templates'] = templates;

    // _handleResponse già estrae body['data'], quindi response È il planning
    final response = await put(
      ApiConfig.staffPlanning(staffId, planningId),
      data: data,
    );
    return Map<String, dynamic>.from(response);
  }

  /// Delete a staff planning
  /// DELETE /v1/staff/{staffId}/plannings/{planningId}
  Future<void> deleteStaffPlanning(int staffId, int planningId) async {
    await delete(ApiConfig.staffPlanning(staffId, planningId));
  }

  // ==========================================================================
  // CLOSURES (Chiusure multi-location)
  // ==========================================================================

  /// Recupera tutte le chiusure per un business
  Future<List<LocationClosure>> getClosures(int businessId) async {
    try {
      final response = await _dio.get('/v1/businesses/$businessId/closures');
      final body = _bodyAsMapOrThrow(response);
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final List<dynamic> closures = data['closures'] ?? [];
      return closures
          .map((json) => LocationClosure.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Recupera le chiusure di un business in un range di date specifico
  Future<List<LocationClosure>> getClosuresInRange({
    required int businessId,
    required DateTime startDate,
    required DateTime endDate,
    int? locationId,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/businesses/$businessId/closures/in-range',
        queryParameters: {
          'start_date': startDate.toIso8601String().split('T').first,
          'end_date': endDate.toIso8601String().split('T').first,
          if (locationId != null) 'location_id': locationId,
        },
      );
      final body = _bodyAsMapOrThrow(response);
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final List<dynamic> closures = data['closures'] ?? [];
      return closures
          .map((json) => LocationClosure.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crea una nuova chiusura (applicabile a più location)
  Future<LocationClosure> createClosure({
    required int businessId,
    required List<int> locationIds,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '/v1/businesses/$businessId/closures',
        data: {
          'location_ids': locationIds,
          'start_date': startDate.toIso8601String().split('T').first,
          'end_date': endDate.toIso8601String().split('T').first,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      final body = _bodyAsMapOrThrow(response);
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
      return LocationClosure.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Aggiorna una chiusura esistente
  Future<LocationClosure> updateClosure({
    required int closureId,
    required List<int> locationIds,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final response = await _dio.put(
        '/v1/closures/$closureId',
        data: {
          'location_ids': locationIds,
          'start_date': startDate.toIso8601String().split('T').first,
          'end_date': endDate.toIso8601String().split('T').first,
          if (reason != null) 'reason': reason,
        },
      );
      final body = _bodyAsMapOrThrow(response);
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
      return LocationClosure.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Elimina una chiusura
  Future<void> deleteClosure(int closureId) async {
    try {
      await _dio.delete('/v1/closures/$closureId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
