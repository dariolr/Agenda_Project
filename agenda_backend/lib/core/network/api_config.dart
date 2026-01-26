/// Configurazione API per agenda_backend (gestionale)
class ApiConfig {
  /// Base URL dell'API - configurabile via environment
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.romeolab.it',
  );

  /// Verifica se siamo in ambiente staging
  static bool get isStaging => baseUrl.contains('api-staging.romeolab.it');

  /// Location ID di default (per MVP single-location)
  static const int defaultLocationId = 1;

  /// Business ID di default
  static const int defaultBusinessId = 1;

  /// Timeout per le richieste
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ========== AUTH ENDPOINTS ==========
  static const String authLogin = '/v1/auth/login';
  static const String authRegister = '/v1/auth/register';
  static const String authRefresh = '/v1/auth/refresh';
  static const String authLogout = '/v1/auth/logout';
  static const String authForgotPassword = '/v1/auth/forgot-password';
  static const String authVerifyResetToken = '/v1/auth/verify-reset-token';
  static const String authResetPassword = '/v1/auth/reset-password';
  static const String authChangePassword = '/v1/me/change-password';
  static const String authMe = '/v1/me';

  // ========== PUBLIC BROWSE ENDPOINTS ==========
  static const String services = '/v1/services';
  static const String staff = '/v1/staff';
  static const String availability = '/v1/availability';

  /// Servizi più prenotati per staff (gestionale)
  static String popularServices(int staffId) =>
      '/v1/staff/$staffId/services/popular';

  // ========== GESTIONALE ENDPOINTS ==========
  static const String clients = '/v1/clients';

  /// Appointments endpoint con location_id nel path
  static String appointments(int locationId) =>
      '/v1/locations/$locationId/appointments';

  /// Singolo appointment endpoint
  static String appointment(int locationId, int appointmentId) =>
      '/v1/locations/$locationId/appointments/$appointmentId';

  /// Cancel appointment endpoint
  static String appointmentCancel(int locationId, int appointmentId) =>
      '/v1/locations/$locationId/appointments/$appointmentId/cancel';

  /// Add item to existing booking endpoint
  static String bookingItems(int bookingId) => '/v1/bookings/$bookingId/items';

  /// Delete item from booking endpoint
  static String bookingItem(int bookingId, int itemId) =>
      '/v1/bookings/$bookingId/items/$itemId';

  /// Bookings endpoint con location_id nel path
  static String bookings(int locationId) =>
      '/v1/locations/$locationId/bookings';

  /// Singolo booking endpoint
  static String booking(int locationId, int bookingId) =>
      '/v1/locations/$locationId/bookings/$bookingId';

  /// Storico booking endpoint
  static String bookingHistory(int bookingId) =>
      '/v1/bookings/$bookingId/history';

  // ========== SERVICE PACKAGES ENDPOINTS ==========

  /// Lista pacchetti servizi per location
  static String servicePackages(int locationId) =>
      '/v1/locations/$locationId/service-packages';

  /// Singolo pacchetto servizi
  static String servicePackage(int locationId, int packageId) =>
      '/v1/locations/$locationId/service-packages/$packageId';

  /// Espansione pacchetto servizi
  static String servicePackageExpand(int locationId, int packageId) =>
      '/v1/locations/$locationId/service-packages/$packageId/expand';

  // ========== BUSINESS USERS (OPERATORS) ENDPOINTS ==========

  /// Lista operatori di un business
  static String businessUsers(int businessId) =>
      '/v1/businesses/$businessId/users';

  /// Singolo operatore
  static String businessUser(int businessId, int userId) =>
      '/v1/businesses/$businessId/users/$userId';

  // ========== BUSINESS INVITATIONS ENDPOINTS ==========

  /// Lista inviti pendenti di un business
  static String businessInvitations(int businessId) =>
      '/v1/businesses/$businessId/invitations';

  /// Singolo invito
  static String businessInvitation(int businessId, int invitationId) =>
      '/v1/businesses/$businessId/invitations/$invitationId';

  /// Dettagli invito pubblico (tramite token)
  static String invitationByToken(String token) => '/v1/invitations/$token';

  /// Accetta invito
  static String acceptInvitation(String token) =>
      '/v1/invitations/$token/accept';

  // ========== STAFF SCHEDULES ENDPOINTS ==========

  /// Lista tutti gli schedules degli staff di un business
  static String staffSchedulesAll(int businessId) =>
      '/v1/businesses/$businessId/staff/schedules';

  /// Schedule di uno staff specifico
  static String staffSchedule(int staffId) => '/v1/staff/$staffId/schedules';

  // ========== STAFF PLANNING ENDPOINTS ==========

  /// Lista tutti i planning di uno staff
  static String staffPlannings(int staffId) => '/v1/staff/$staffId/plannings';

  /// Singolo planning (per update/delete)
  static String staffPlanning(int staffId, int planningId) =>
      '/v1/staff/$staffId/plannings/$planningId';

  /// Planning valido per una data
  static String staffPlanningForDate(int staffId) =>
      '/v1/staff/$staffId/planning';

  /// Slot disponibili per una data
  static String staffPlanningAvailability(int staffId) =>
      '/v1/staff/$staffId/planning-availability';

  // ========== ADMIN BUSINESS SYNC ENDPOINTS ==========

  /// URL API Staging (per push da produzione)
  static const String stagingApiUrl = 'https://api-staging.romeolab.it';

  /// URL API Produzione (per push da staging)
  static const String productionApiUrl = 'https://api.romeolab.it';

  /// Export business data (superadmin only)
  static String businessExport(int businessId) =>
      '/v1/admin/businesses/$businessId/export';

  /// Export business data by slug (superadmin only)
  static String businessExportBySlug(String slug) =>
      '/v1/admin/businesses/by-slug/$slug/export';

  /// Import business data (superadmin only, staging only)
  static const String businessImport = '/v1/admin/businesses/import';

  /// Sync from production (superadmin only, staging only)
  static const String businessSyncFromProduction =
      '/v1/admin/businesses/sync-from-production';

  /// Push to staging - URL completo perché punta a staging anche da produzione
  static const String businessPushToStaging =
      '$stagingApiUrl/v1/admin/businesses/import';

  /// Push to production - URL completo perché punta a prod anche da staging
  static const String businessPushToProduction =
      '$productionApiUrl/v1/admin/businesses/import';
}
