import 'dart:async';

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
/// Usato dal gestionale (agenda_backend)
class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  String? _accessToken;
  bool _isRefreshing = false;
  final List<void Function()> _pendingRequests = [];

  ApiClient({required TokenStorage tokenStorage, Dio? dio})
    : _tokenStorage = tokenStorage,
      _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    debugPrint('🔗 API baseUrl: ${ApiConfig.baseUrl}');
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

  /// GET /v1/clients?business_id=X
  Future<Map<String, dynamic>> getClients(int businessId) async {
    return get(ApiConfig.clients, queryParameters: {'business_id': businessId});
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
  }) async {
    final data = <String, dynamic>{};
    if (startTime != null) data['start_time'] = startTime;
    if (endTime != null) data['end_time'] = endTime;
    if (staffId != null) data['staff_id'] = staffId;

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

  /// PUT /v1/locations/{location_id}/bookings/{booking_id}
  Future<Map<String, dynamic>> updateBooking({
    required int locationId,
    required int bookingId,
    String? status,
    String? notes,
  }) async {
    final data = <String, dynamic>{};
    if (status != null) {
      data['status'] = status;
    }
    if (notes != null) {
      data['notes'] = notes;
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
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParameters = <String, dynamic>{'limit': limit, 'offset': offset};
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    final response = await get(
      '/v1/admin/businesses',
      queryParameters: queryParameters,
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

  // ========== LOCATIONS CRUD ==========

  /// GET /v1/businesses/{business_id}/locations
  Future<List<Map<String, dynamic>>> getLocations(int businessId) async {
    final response = await get('/v1/businesses/$businessId/locations');
    return (response['data'] as List).cast<Map<String, dynamic>>();
  }

  /// POST /v1/businesses/{business_id}/locations
  Future<Map<String, dynamic>> createLocation({
    required int businessId,
    required String name,
    String? address,
    String? phone,
    String? email,
    String? timezone,
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
        if (isActive != null) 'is_active': isActive,
      },
    );
    return response['location'] as Map<String, dynamic>;
  }

  /// PUT /v1/locations/{id}
  Future<Map<String, dynamic>> updateLocation({
    required int locationId,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? timezone,
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
        if (isActive != null) 'is_active': isActive,
      },
    );
    return response['location'] as Map<String, dynamic>;
  }

  /// DELETE /v1/locations/{id}
  Future<void> deleteLocation(int locationId) async {
    await delete('/v1/locations/$locationId');
  }

  // ========== STAFF CRUD ==========

  /// GET /v1/businesses/{business_id}/staff
  Future<List<Map<String, dynamic>>> getStaffByBusiness(int businessId) async {
    final response = await get('/v1/businesses/$businessId/staff');
    return (response['staff'] as List).cast<Map<String, dynamic>>();
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
      },
    );
    return response['staff'] as Map<String, dynamic>;
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
      },
    );
    return response['staff'] as Map<String, dynamic>;
  }

  /// DELETE /v1/staff/{id}
  Future<void> deleteStaff(int staffId) async {
    await delete('/v1/staff/$staffId');
  }

  // ========== BUSINESS USERS (OPERATORS) ==========

  /// GET /v1/businesses/{business_id}/users
  /// Lista operatori di un business.
  Future<List<Map<String, dynamic>>> getBusinessUsers(int businessId) async {
    final response = await get(ApiConfig.businessUsers(businessId));
    return (response['data']['users'] as List).cast<Map<String, dynamic>>();
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
    return response['data'] as Map<String, dynamic>;
  }

  /// PATCH /v1/businesses/{business_id}/users/{user_id}
  /// Aggiorna il ruolo di un operatore.
  Future<Map<String, dynamic>> updateBusinessUser({
    required int businessId,
    required int userId,
    required String role,
  }) async {
    final response = await patch(
      ApiConfig.businessUser(businessId, userId),
      data: {'role': role},
    );
    return response['data'] as Map<String, dynamic>;
  }

  /// DELETE /v1/businesses/{business_id}/users/{user_id}
  /// Rimuove un operatore dal business.
  Future<void> removeBusinessUser({
    required int businessId,
    required int userId,
  }) async {
    await delete(ApiConfig.businessUser(businessId, userId));
  }

  // ========== BUSINESS INVITATIONS ==========

  /// GET /v1/businesses/{business_id}/invitations
  /// Lista inviti pendenti.
  Future<List<Map<String, dynamic>>> getBusinessInvitations(
    int businessId,
  ) async {
    final response = await get(ApiConfig.businessInvitations(businessId));
    return (response['data']['invitations'] as List)
        .cast<Map<String, dynamic>>();
  }

  /// POST /v1/businesses/{business_id}/invitations
  /// Crea un nuovo invito via email.
  Future<Map<String, dynamic>> createBusinessInvitation({
    required int businessId,
    required String email,
    required String role,
  }) async {
    final response = await post(
      ApiConfig.businessInvitations(businessId),
      data: {'email': email, 'role': role},
    );
    return response['data'] as Map<String, dynamic>;
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
    return response['data'] as Map<String, dynamic>;
  }

  /// POST /v1/invitations/{token}/accept
  /// Accetta un invito (richiede autenticazione).
  Future<Map<String, dynamic>> acceptInvitation(String token) async {
    final response = await post(ApiConfig.acceptInvitation(token));
    return response['data'] as Map<String, dynamic>;
  }
}
