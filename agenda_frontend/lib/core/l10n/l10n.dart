// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class L10n {
  L10n();

  static L10n? _current;

  static L10n get current {
    assert(
      _current != null,
      'No instance of L10n was loaded. Try to initialize the L10n delegate before accessing L10n.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<L10n> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = L10n();
      L10n._current = instance;

      return instance;
    });
  }

  static L10n of(BuildContext context) {
    final instance = L10n.maybeOf(context);
    assert(
      instance != null,
      'No instance of L10n present in the widget tree. Did you add L10n.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static L10n? maybeOf(BuildContext context) {
    return Localizations.of<L10n>(context, L10n);
  }

  /// `Book Online`
  String get appTitle {
    return Intl.message('Book Online', name: 'appTitle', desc: '', args: []);
  }

  /// `Back`
  String get actionBack {
    return Intl.message('Back', name: 'actionBack', desc: '', args: []);
  }

  /// `Next`
  String get actionNext {
    return Intl.message('Next', name: 'actionNext', desc: '', args: []);
  }

  /// `Confirm`
  String get actionConfirm {
    return Intl.message('Confirm', name: 'actionConfirm', desc: '', args: []);
  }

  /// `Cancel`
  String get actionCancel {
    return Intl.message('Cancel', name: 'actionCancel', desc: '', args: []);
  }

  /// `Delete`
  String get actionDelete {
    return Intl.message('Delete', name: 'actionDelete', desc: '', args: []);
  }

  /// `Close`
  String get actionClose {
    return Intl.message('Close', name: 'actionClose', desc: '', args: []);
  }

  /// `Retry`
  String get actionRetry {
    return Intl.message('Retry', name: 'actionRetry', desc: '', args: []);
  }

  /// `Login`
  String get actionLogin {
    return Intl.message('Login', name: 'actionLogin', desc: '', args: []);
  }

  /// `Register`
  String get actionRegister {
    return Intl.message('Register', name: 'actionRegister', desc: '', args: []);
  }

  /// `Logout`
  String get actionLogout {
    return Intl.message('Logout', name: 'actionLogout', desc: '', args: []);
  }

  /// `Loading...`
  String get loadingGeneric {
    return Intl.message(
      'Loading...',
      name: 'loadingGeneric',
      desc: '',
      args: [],
    );
  }

  /// `Session expired. Please log in again.`
  String get sessionExpired {
    return Intl.message(
      'Session expired. Please log in again.',
      name: 'sessionExpired',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get errorTitle {
    return Intl.message('Error', name: 'errorTitle', desc: '', args: []);
  }

  /// `An error occurred`
  String get errorGeneric {
    return Intl.message(
      'An error occurred',
      name: 'errorGeneric',
      desc: '',
      args: [],
    );
  }

  /// `Page not found: {path}`
  String errorNotFound(String path) {
    return Intl.message(
      'Page not found: $path',
      name: 'errorNotFound',
      desc: '',
      args: [path],
    );
  }

  /// `No availability for the selected date`
  String get errorNoAvailability {
    return Intl.message(
      'No availability for the selected date',
      name: 'errorNoAvailability',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load services. Check your connection and try again.`
  String get errorLoadingServices {
    return Intl.message(
      'Unable to load services. Check your connection and try again.',
      name: 'errorLoadingServices',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load staff. Check your connection and try again.`
  String get errorLoadingStaff {
    return Intl.message(
      'Unable to load staff. Check your connection and try again.',
      name: 'errorLoadingStaff',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load availability. Check your connection and try again.`
  String get errorLoadingAvailability {
    return Intl.message(
      'Unable to load availability. Check your connection and try again.',
      name: 'errorLoadingAvailability',
      desc: '',
      args: [],
    );
  }

  /// `Loading availability...`
  String get loadingAvailability {
    return Intl.message(
      'Loading availability...',
      name: 'loadingAvailability',
      desc: '',
      args: [],
    );
  }

  /// `No services available at the moment`
  String get servicesEmpty {
    return Intl.message(
      'No services available at the moment',
      name: 'servicesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `There are no services available for online booking at this business`
  String get servicesEmptySubtitle {
    return Intl.message(
      'There are no services available for online booking at this business',
      name: 'servicesEmptySubtitle',
      desc: '',
      args: [],
    );
  }

  /// `No staff available at the moment`
  String get staffEmpty {
    return Intl.message(
      'No staff available at the moment',
      name: 'staffEmpty',
      desc: '',
      args: [],
    );
  }

  /// `No staff member can perform all selected services. Try selecting fewer or different services.`
  String get noStaffForAllServices {
    return Intl.message(
      'No staff member can perform all selected services. Try selecting fewer or different services.',
      name: 'noStaffForAllServices',
      desc: '',
      args: [],
    );
  }

  /// `The connection is taking too long. Please try again.`
  String get errorConnectionTimeout {
    return Intl.message(
      'The connection is taking too long. Please try again.',
      name: 'errorConnectionTimeout',
      desc: '',
      args: [],
    );
  }

  /// `DEMO ENVIRONMENT`
  String get environmentDemoBannerTitle {
    return Intl.message(
      'DEMO ENVIRONMENT',
      name: 'environmentDemoBannerTitle',
      desc: '',
      args: [],
    );
  }

  /// `Data is reset periodically.`
  String get environmentDemoBannerSubtitle {
    return Intl.message(
      'Data is reset periodically.',
      name: 'environmentDemoBannerSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Business not found`
  String get errorBusinessNotFound {
    return Intl.message(
      'Business not found',
      name: 'errorBusinessNotFound',
      desc: '',
      args: [],
    );
  }

  /// `The requested business does not exist. Please check the URL or contact the business directly.`
  String get errorBusinessNotFoundSubtitle {
    return Intl.message(
      'The requested business does not exist. Please check the URL or contact the business directly.',
      name: 'errorBusinessNotFoundSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Business not active`
  String get errorBusinessNotActive {
    return Intl.message(
      'Business not active',
      name: 'errorBusinessNotActive',
      desc: '',
      args: [],
    );
  }

  /// `This business is not yet configured for online bookings. Please contact the business directly.`
  String get errorBusinessNotActiveSubtitle {
    return Intl.message(
      'This business is not yet configured for online bookings. Please contact the business directly.',
      name: 'errorBusinessNotActiveSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Location not available`
  String get errorLocationNotFound {
    return Intl.message(
      'Location not available',
      name: 'errorLocationNotFound',
      desc: '',
      args: [],
    );
  }

  /// `The selected location is not active. Contact the business for more information.`
  String get errorLocationNotFoundSubtitle {
    return Intl.message(
      'The selected location is not active. Contact the business for more information.',
      name: 'errorLocationNotFoundSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Service temporarily unavailable`
  String get errorServiceUnavailable {
    return Intl.message(
      'Service temporarily unavailable',
      name: 'errorServiceUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `{label} temporarily unavailable`
  String errorServiceUnavailableCustom(String label) {
    return Intl.message(
      '$label temporarily unavailable',
      name: 'errorServiceUnavailableCustom',
      desc: '',
      args: [label],
    );
  }

  /// `We are working to fix the issue. Please try again in a few minutes.`
  String get errorServiceUnavailableSubtitle {
    return Intl.message(
      'We are working to fix the issue. Please try again in a few minutes.',
      name: 'errorServiceUnavailableSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Welcome`
  String get authWelcome {
    return Intl.message('Welcome', name: 'authWelcome', desc: '', args: []);
  }

  /// `Login to your account`
  String get authLoginTitle {
    return Intl.message(
      'Login to your account',
      name: 'authLoginTitle',
      desc: '',
      args: [],
    );
  }

  /// `Create a new account`
  String get authRegisterTitle {
    return Intl.message(
      'Create a new account',
      name: 'authRegisterTitle',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get authEmail {
    return Intl.message('Email', name: 'authEmail', desc: '', args: []);
  }

  /// `Password`
  String get authPassword {
    return Intl.message('Password', name: 'authPassword', desc: '', args: []);
  }

  /// `Confirm password`
  String get authConfirmPassword {
    return Intl.message(
      'Confirm password',
      name: 'authConfirmPassword',
      desc: '',
      args: [],
    );
  }

  /// `First name`
  String get authFirstName {
    return Intl.message(
      'First name',
      name: 'authFirstName',
      desc: '',
      args: [],
    );
  }

  /// `Last name`
  String get authLastName {
    return Intl.message('Last name', name: 'authLastName', desc: '', args: []);
  }

  /// `Phone`
  String get authPhone {
    return Intl.message('Phone', name: 'authPhone', desc: '', args: []);
  }

  /// `Forgot password?`
  String get authForgotPassword {
    return Intl.message(
      'Forgot password?',
      name: 'authForgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Don't have an account?`
  String get authNoAccount {
    return Intl.message(
      'Don\'t have an account?',
      name: 'authNoAccount',
      desc: '',
      args: [],
    );
  }

  /// `Already have an account?`
  String get authHaveAccount {
    return Intl.message(
      'Already have an account?',
      name: 'authHaveAccount',
      desc: '',
      args: [],
    );
  }

  /// `Remember me`
  String get authRememberMe {
    return Intl.message(
      'Remember me',
      name: 'authRememberMe',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email`
  String get authInvalidEmail {
    return Intl.message(
      'Invalid email',
      name: 'authInvalidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Password must contain at least 8 characters, one uppercase, one lowercase and one number`
  String get authInvalidPassword {
    return Intl.message(
      'Password must contain at least 8 characters, one uppercase, one lowercase and one number',
      name: 'authInvalidPassword',
      desc: '',
      args: [],
    );
  }

  /// `Validation error: {message}`
  String authPasswordValidationError(Object message) {
    return Intl.message(
      'Validation error: $message',
      name: 'authPasswordValidationError',
      desc: '',
      args: [message],
    );
  }

  /// `Passwords don't match`
  String get authPasswordMismatch {
    return Intl.message(
      'Passwords don\'t match',
      name: 'authPasswordMismatch',
      desc: '',
      args: [],
    );
  }

  /// `Required field`
  String get authRequiredField {
    return Intl.message(
      'Required field',
      name: 'authRequiredField',
      desc: '',
      args: [],
    );
  }

  /// `Invalid phone number`
  String get authInvalidPhone {
    return Intl.message(
      'Invalid phone number',
      name: 'authInvalidPhone',
      desc: '',
      args: [],
    );
  }

  /// `Login successful`
  String get authLoginSuccess {
    return Intl.message(
      'Login successful',
      name: 'authLoginSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Registration completed`
  String get authRegisterSuccess {
    return Intl.message(
      'Registration completed',
      name: 'authRegisterSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Invalid credentials`
  String get authLoginFailed {
    return Intl.message(
      'Invalid credentials',
      name: 'authLoginFailed',
      desc: '',
      args: [],
    );
  }

  /// `Registration failed`
  String get authRegisterFailed {
    return Intl.message(
      'Registration failed',
      name: 'authRegisterFailed',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load business information. Please try again.`
  String get authBusinessNotFound {
    return Intl.message(
      'Unable to load business information. Please try again.',
      name: 'authBusinessNotFound',
      desc: '',
      args: [],
    );
  }

  /// `This email is already registered. Try logging in.`
  String get authEmailAlreadyRegistered {
    return Intl.message(
      'This email is already registered. Try logging in.',
      name: 'authEmailAlreadyRegistered',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email or password`
  String get authErrorInvalidCredentials {
    return Intl.message(
      'Invalid email or password',
      name: 'authErrorInvalidCredentials',
      desc: '',
      args: [],
    );
  }

  /// `Your account is disabled`
  String get authErrorAccountDisabled {
    return Intl.message(
      'Your account is disabled',
      name: 'authErrorAccountDisabled',
      desc: '',
      args: [],
    );
  }

  /// `For any appointment needs, please contact us. Thank you.`
  String get blockedCustomerContactMessage {
    return Intl.message(
      'For any appointment needs, please contact us. Thank you.',
      name: 'blockedCustomerContactMessage',
      desc: '',
      args: [],
    );
  }

  /// `Your session has expired. Please log in again.`
  String get authErrorTokenExpired {
    return Intl.message(
      'Your session has expired. Please log in again.',
      name: 'authErrorTokenExpired',
      desc: '',
      args: [],
    );
  }

  /// `Your session is not valid. Please log in again.`
  String get authErrorTokenInvalid {
    return Intl.message(
      'Your session is not valid. Please log in again.',
      name: 'authErrorTokenInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Your session has been revoked. Please log in again.`
  String get authErrorSessionRevoked {
    return Intl.message(
      'Your session has been revoked. Please log in again.',
      name: 'authErrorSessionRevoked',
      desc: '',
      args: [],
    );
  }

  /// `This email is already registered. Try logging in.`
  String get authErrorEmailAlreadyExists {
    return Intl.message(
      'This email is already registered. Try logging in.',
      name: 'authErrorEmailAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Password too weak. Please choose a stronger password.`
  String get authErrorWeakPassword {
    return Intl.message(
      'Password too weak. Please choose a stronger password.',
      name: 'authErrorWeakPassword',
      desc: '',
      args: [],
    );
  }

  /// `Invalid password reset token`
  String get authErrorInvalidResetToken {
    return Intl.message(
      'Invalid password reset token',
      name: 'authErrorInvalidResetToken',
      desc: '',
      args: [],
    );
  }

  /// `Password reset token has expired`
  String get authErrorResetTokenExpired {
    return Intl.message(
      'Password reset token has expired',
      name: 'authErrorResetTokenExpired',
      desc: '',
      args: [],
    );
  }

  /// `Reset password`
  String get authResetPasswordTitle {
    return Intl.message(
      'Reset password',
      name: 'authResetPasswordTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email and we'll send you instructions to reset your password.`
  String get authResetPasswordMessage {
    return Intl.message(
      'Enter your email and we\'ll send you instructions to reset your password.',
      name: 'authResetPasswordMessage',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get authResetPasswordSend {
    return Intl.message(
      'Send',
      name: 'authResetPasswordSend',
      desc: '',
      args: [],
    );
  }

  /// `Email sent! Check your inbox.`
  String get authResetPasswordSuccess {
    return Intl.message(
      'Email sent! Check your inbox.',
      name: 'authResetPasswordSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Error sending email. Please try again.`
  String get authResetPasswordError {
    return Intl.message(
      'Error sending email. Please try again.',
      name: 'authResetPasswordError',
      desc: '',
      args: [],
    );
  }

  /// `Email not found in our system. Please check the address or register.`
  String get authResetPasswordEmailNotFound {
    return Intl.message(
      'Email not found in our system. Please check the address or register.',
      name: 'authResetPasswordEmailNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Reset password`
  String get authResetPasswordConfirmTitle {
    return Intl.message(
      'Reset password',
      name: 'authResetPasswordConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter your new password`
  String get authResetPasswordConfirmMessage {
    return Intl.message(
      'Enter your new password',
      name: 'authResetPasswordConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `New password`
  String get authNewPassword {
    return Intl.message(
      'New password',
      name: 'authNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `Password reset successful!`
  String get authResetPasswordConfirmSuccess {
    return Intl.message(
      'Password reset successful!',
      name: 'authResetPasswordConfirmSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Invalid or expired token`
  String get authResetPasswordConfirmError {
    return Intl.message(
      'Invalid or expired token',
      name: 'authResetPasswordConfirmError',
      desc: '',
      args: [],
    );
  }

  /// `Change password`
  String get authChangePasswordTitle {
    return Intl.message(
      'Change password',
      name: 'authChangePasswordTitle',
      desc: '',
      args: [],
    );
  }

  /// `Current password`
  String get authCurrentPassword {
    return Intl.message(
      'Current password',
      name: 'authCurrentPassword',
      desc: '',
      args: [],
    );
  }

  /// `Password changed successfully`
  String get authChangePasswordSuccess {
    return Intl.message(
      'Password changed successfully',
      name: 'authChangePasswordSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Current password is incorrect`
  String get authChangePasswordError {
    return Intl.message(
      'Current password is incorrect',
      name: 'authChangePasswordError',
      desc: '',
      args: [],
    );
  }

  /// `Password too short (min. 8 characters)`
  String get authPasswordTooShort {
    return Intl.message(
      'Password too short (min. 8 characters)',
      name: 'authPasswordTooShort',
      desc: '',
      args: [],
    );
  }

  /// `Password must contain: uppercase, lowercase, number`
  String get authPasswordRequirements {
    return Intl.message(
      'Password must contain: uppercase, lowercase, number',
      name: 'authPasswordRequirements',
      desc: '',
      args: [],
    );
  }

  /// `Change password`
  String get authChangePassword {
    return Intl.message(
      'Change password',
      name: 'authChangePassword',
      desc: '',
      args: [],
    );
  }

  /// `To view your appointments, log in with your account or register if you don't have one yet.`
  String get authRedirectFromMyBookings {
    return Intl.message(
      'To view your appointments, log in with your account or register if you don\'t have one yet.',
      name: 'authRedirectFromMyBookings',
      desc: '',
      args: [],
    );
  }

  /// `To book an appointment, log in with your account or register if you don't have one yet.`
  String get authRedirectFromBooking {
    return Intl.message(
      'To book an appointment, log in with your account or register if you don\'t have one yet.',
      name: 'authRedirectFromBooking',
      desc: '',
      args: [],
    );
  }

  /// `Profile`
  String get profileTitle {
    return Intl.message('Profile', name: 'profileTitle', desc: '', args: []);
  }

  /// `Book appointment`
  String get bookingTitle {
    return Intl.message(
      'Book appointment',
      name: 'bookingTitle',
      desc: '',
      args: [],
    );
  }

  /// `service`
  String get bookingServiceSingularLabel {
    return Intl.message(
      'service',
      name: 'bookingServiceSingularLabel',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get bookingStepLocation {
    return Intl.message(
      'Location',
      name: 'bookingStepLocation',
      desc: '',
      args: [],
    );
  }

  /// `Services`
  String get bookingStepServices {
    return Intl.message(
      'Services',
      name: 'bookingStepServices',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get bookingStepStaff {
    return Intl.message('Staff', name: 'bookingStepStaff', desc: '', args: []);
  }

  /// `Date & Time`
  String get bookingStepDateTime {
    return Intl.message(
      'Date & Time',
      name: 'bookingStepDateTime',
      desc: '',
      args: [],
    );
  }

  /// `Summary`
  String get bookingStepSummary {
    return Intl.message(
      'Summary',
      name: 'bookingStepSummary',
      desc: '',
      args: [],
    );
  }

  /// `Choose {label}`
  String bookingChooseCustomLabel(String label) {
    return Intl.message(
      'Choose $label',
      name: 'bookingChooseCustomLabel',
      desc: '',
      args: [label],
    );
  }

  /// `Choose location`
  String get locationTitle {
    return Intl.message(
      'Choose location',
      name: 'locationTitle',
      desc: '',
      args: [],
    );
  }

  /// `Select where you want to book`
  String get locationSubtitle {
    return Intl.message(
      'Select where you want to book',
      name: 'locationSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `No location available`
  String get locationEmpty {
    return Intl.message(
      'No location available',
      name: 'locationEmpty',
      desc: '',
      args: [],
    );
  }

  /// `No {label} available`
  String locationEmptyCustom(String label) {
    return Intl.message(
      'No $label available',
      name: 'locationEmptyCustom',
      desc: '',
      args: [label],
    );
  }

  /// `Choose services`
  String get servicesTitle {
    return Intl.message(
      'Choose services',
      name: 'servicesTitle',
      desc: '',
      args: [],
    );
  }

  /// `You can select one or more services`
  String get servicesSubtitle {
    return Intl.message(
      'You can select one or more services',
      name: 'servicesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `You can select one or more {label}`
  String servicesSubtitleCustom(String label) {
    return Intl.message(
      'You can select one or more $label',
      name: 'servicesSubtitleCustom',
      desc: '',
      args: [label],
    );
  }

  /// `Packages`
  String get servicePackagesTitle {
    return Intl.message(
      'Packages',
      name: 'servicePackagesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Or pick a ready-made package`
  String get servicePackagesSubtitle {
    return Intl.message(
      'Or pick a ready-made package',
      name: 'servicePackagesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Loading packages...`
  String get servicePackagesLoading {
    return Intl.message(
      'Loading packages...',
      name: 'servicePackagesLoading',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load packages.`
  String get servicePackagesLoadError {
    return Intl.message(
      'Unable to load packages.',
      name: 'servicePackagesLoadError',
      desc: '',
      args: [],
    );
  }

  /// `Package`
  String get servicePackageLabel {
    return Intl.message(
      'Package',
      name: 'servicePackageLabel',
      desc: '',
      args: [],
    );
  }

  /// `Category {id}`
  String servicesCategoryFallbackName(int id) {
    return Intl.message(
      'Category $id',
      name: 'servicesCategoryFallbackName',
      desc: '',
      args: [id],
    );
  }

  /// `Unable to expand the selected package.`
  String get servicePackageExpandError {
    return Intl.message(
      'Unable to expand the selected package.',
      name: 'servicePackageExpandError',
      desc: '',
      args: [],
    );
  }

  /// `No {label} available at the moment`
  String servicesEmptyCustom(String label) {
    return Intl.message(
      'No $label available at the moment',
      name: 'servicesEmptyCustom',
      desc: '',
      args: [label],
    );
  }

  /// `There are no {label} available for online booking at this business`
  String servicesEmptySubtitleCustom(String label) {
    return Intl.message(
      'There are no $label available for online booking at this business',
      name: 'servicesEmptySubtitleCustom',
      desc: '',
      args: [label],
    );
  }

  /// `{count, plural, =0{No service selected} =1{1 service selected} other{{count} services selected}}`
  String servicesSelected(int count) {
    return Intl.plural(
      count,
      zero: 'No service selected',
      one: '1 service selected',
      other: '$count services selected',
      name: 'servicesSelected',
      desc: '',
      args: [count],
    );
  }

  /// `No {label} selected`
  String servicesSelectedNoneCustom(String label) {
    return Intl.message(
      'No $label selected',
      name: 'servicesSelectedNoneCustom',
      desc: '',
      args: [label],
    );
  }

  /// `1 {label} selected`
  String servicesSelectedOneCustom(String label) {
    return Intl.message(
      '1 $label selected',
      name: 'servicesSelectedOneCustom',
      desc: '',
      args: [label],
    );
  }

  /// `{count} {label} selected`
  String servicesSelectedManyCustom(int count, String label) {
    return Intl.message(
      '$count $label selected',
      name: 'servicesSelectedManyCustom',
      desc: '',
      args: [count, label],
    );
  }

  /// `Total: {total}`
  String servicesTotal(String total) {
    return Intl.message(
      'Total: $total',
      name: 'servicesTotal',
      desc: '',
      args: [total],
    );
  }

  /// `{duration} min`
  String servicesDuration(int duration) {
    return Intl.message(
      '$duration min',
      name: 'servicesDuration',
      desc: '',
      args: [duration],
    );
  }

  /// `Free`
  String get servicesFree {
    return Intl.message('Free', name: 'servicesFree', desc: '', args: []);
  }

  /// `from {price}`
  String servicesPriceFrom(String price) {
    return Intl.message(
      'from $price',
      name: 'servicesPriceFrom',
      desc: '',
      args: [price],
    );
  }

  /// `Choose staff member`
  String get staffTitle {
    return Intl.message(
      'Choose staff member',
      name: 'staffTitle',
      desc: '',
      args: [],
    );
  }

  /// `Select who you want to be served by`
  String get staffSubtitle {
    return Intl.message(
      'Select who you want to be served by',
      name: 'staffSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Select your preferred {label}`
  String staffSubtitleCustom(String label) {
    return Intl.message(
      'Select your preferred $label',
      name: 'staffSubtitleCustom',
      desc: '',
      args: [label],
    );
  }

  /// `Any available staff`
  String get staffAnyOperator {
    return Intl.message(
      'Any available staff',
      name: 'staffAnyOperator',
      desc: '',
      args: [],
    );
  }

  /// `We'll assign you the first available staff member`
  String get staffAnyOperatorSubtitle {
    return Intl.message(
      'We\'ll assign you the first available staff member',
      name: 'staffAnyOperatorSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Any available {label}`
  String staffAnyOperatorCustom(String label) {
    return Intl.message(
      'Any available $label',
      name: 'staffAnyOperatorCustom',
      desc: '',
      args: [label],
    );
  }

  /// `We'll assign you the first available {label}`
  String staffAnyOperatorSubtitleCustom(String label) {
    return Intl.message(
      'We\'ll assign you the first available $label',
      name: 'staffAnyOperatorSubtitleCustom',
      desc: '',
      args: [label],
    );
  }

  /// `No {label} available at the moment`
  String staffEmptyCustom(String label) {
    return Intl.message(
      'No $label available at the moment',
      name: 'staffEmptyCustom',
      desc: '',
      args: [label],
    );
  }

  /// `No {staffLabel} can perform all selected {serviceLabel}. Try selecting fewer or different {serviceLabel}.`
  String noStaffForAllServicesCustom(String staffLabel, String serviceLabel) {
    return Intl.message(
      'No $staffLabel can perform all selected $serviceLabel. Try selecting fewer or different $serviceLabel.',
      name: 'noStaffForAllServicesCustom',
      desc: '',
      args: [staffLabel, serviceLabel],
    );
  }

  /// `Choose date and time`
  String get dateTimeTitle {
    return Intl.message(
      'Choose date and time',
      name: 'dateTimeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Select when you want to book`
  String get dateTimeSubtitle {
    return Intl.message(
      'Select when you want to book',
      name: 'dateTimeSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `First available: {date}`
  String dateTimeFirstAvailable(String date) {
    return Intl.message(
      'First available: $date',
      name: 'dateTimeFirstAvailable',
      desc: '',
      args: [date],
    );
  }

  /// `Go to first available date`
  String get dateTimeGoToFirst {
    return Intl.message(
      'Go to first available date',
      name: 'dateTimeGoToFirst',
      desc: '',
      args: [],
    );
  }

  /// `Go to next available date`
  String get dateTimeGoToNext {
    return Intl.message(
      'Go to next available date',
      name: 'dateTimeGoToNext',
      desc: '',
      args: [],
    );
  }

  /// `No time slots available for this date`
  String get dateTimeNoSlots {
    return Intl.message(
      'No time slots available for this date',
      name: 'dateTimeNoSlots',
      desc: '',
      args: [],
    );
  }

  /// `Select a date`
  String get dateTimeSelectDate {
    return Intl.message(
      'Select a date',
      name: 'dateTimeSelectDate',
      desc: '',
      args: [],
    );
  }

  /// `Morning`
  String get dateTimeMorning {
    return Intl.message('Morning', name: 'dateTimeMorning', desc: '', args: []);
  }

  /// `Afternoon`
  String get dateTimeAfternoon {
    return Intl.message(
      'Afternoon',
      name: 'dateTimeAfternoon',
      desc: '',
      args: [],
    );
  }

  /// `Evening`
  String get dateTimeEvening {
    return Intl.message('Evening', name: 'dateTimeEvening', desc: '', args: []);
  }

  /// `Booking summary`
  String get summaryTitle {
    return Intl.message(
      'Booking summary',
      name: 'summaryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Review the details before confirming`
  String get summarySubtitle {
    return Intl.message(
      'Review the details before confirming',
      name: 'summarySubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Selected services`
  String get summaryServices {
    return Intl.message(
      'Selected services',
      name: 'summaryServices',
      desc: '',
      args: [],
    );
  }

  /// `Selected {label}`
  String summaryServicesCustom(String label) {
    return Intl.message(
      'Selected $label',
      name: 'summaryServicesCustom',
      desc: '',
      args: [label],
    );
  }

  /// `Staff member`
  String get summaryOperator {
    return Intl.message(
      'Staff member',
      name: 'summaryOperator',
      desc: '',
      args: [],
    );
  }

  /// `Date and time`
  String get summaryDateTime {
    return Intl.message(
      'Date and time',
      name: 'summaryDateTime',
      desc: '',
      args: [],
    );
  }

  /// `Modify/cancel policy`
  String get summaryCancellationPolicyTitle {
    return Intl.message(
      'Modify/cancel policy',
      name: 'summaryCancellationPolicyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Always`
  String get summaryCancellationPolicyAlways {
    return Intl.message(
      'Always',
      name: 'summaryCancellationPolicyAlways',
      desc: '',
      args: [],
    );
  }

  /// `Never (not allowed after booking)`
  String get summaryCancellationPolicyNever {
    return Intl.message(
      'Never (not allowed after booking)',
      name: 'summaryCancellationPolicyNever',
      desc: '',
      args: [],
    );
  }

  /// `Up to {hours} hours before`
  String summaryCancellationPolicyHours(int hours) {
    return Intl.message(
      'Up to $hours hours before',
      name: 'summaryCancellationPolicyHours',
      desc: '',
      args: [hours],
    );
  }

  /// `{days, plural, =1{Up to 1 day before} other{Up to {days} days before}}`
  String summaryCancellationPolicyDays(int days) {
    return Intl.plural(
      days,
      one: 'Up to 1 day before',
      other: 'Up to $days days before',
      name: 'summaryCancellationPolicyDays',
      desc: '',
      args: [days],
    );
  }

  /// `I accept the modify/cancel policy`
  String get summaryCancellationPolicyAcceptLabel {
    return Intl.message(
      'I accept the modify/cancel policy',
      name: 'summaryCancellationPolicyAcceptLabel',
      desc: '',
      args: [],
    );
  }

  /// `To confirm, you must accept the modify/cancel policy.`
  String get summaryCancellationPolicyAcceptRequiredError {
    return Intl.message(
      'To confirm, you must accept the modify/cancel policy.',
      name: 'summaryCancellationPolicyAcceptRequiredError',
      desc: '',
      args: [],
    );
  }

  /// `Total duration`
  String get summaryDuration {
    return Intl.message(
      'Total duration',
      name: 'summaryDuration',
      desc: '',
      args: [],
    );
  }

  /// `Total price`
  String get summaryPrice {
    return Intl.message(
      'Total price',
      name: 'summaryPrice',
      desc: '',
      args: [],
    );
  }

  /// `Notes (optional)`
  String get summaryNotes {
    return Intl.message(
      'Notes (optional)',
      name: 'summaryNotes',
      desc: '',
      args: [],
    );
  }

  /// `Add any notes for the appointment...`
  String get summaryNotesHint {
    return Intl.message(
      'Add any notes for the appointment...',
      name: 'summaryNotesHint',
      desc: '',
      args: [],
    );
  }

  /// `The selected time slot is no longer available`
  String get bookingErrorSlotConflict {
    return Intl.message(
      'The selected time slot is no longer available',
      name: 'bookingErrorSlotConflict',
      desc: '',
      args: [],
    );
  }

  /// `One or more selected services are not available`
  String get bookingErrorInvalidService {
    return Intl.message(
      'One or more selected services are not available',
      name: 'bookingErrorInvalidService',
      desc: '',
      args: [],
    );
  }

  /// `One or more selected {serviceLabel} are not available`
  String bookingErrorInvalidServiceCustom(String serviceLabel) {
    return Intl.message(
      'One or more selected $serviceLabel are not available',
      name: 'bookingErrorInvalidServiceCustom',
      desc: '',
      args: [serviceLabel],
    );
  }

  /// `The selected staff member is not available for these services`
  String get bookingErrorInvalidStaff {
    return Intl.message(
      'The selected staff member is not available for these services',
      name: 'bookingErrorInvalidStaff',
      desc: '',
      args: [],
    );
  }

  /// `The selected {staffLabel} is not available for these {serviceLabel}`
  String bookingErrorInvalidStaffCustom(
    String staffLabel,
    String serviceLabel,
  ) {
    return Intl.message(
      'The selected $staffLabel is not available for these $serviceLabel',
      name: 'bookingErrorInvalidStaffCustom',
      desc: '',
      args: [staffLabel, serviceLabel],
    );
  }

  /// `The selected location is not available`
  String get bookingErrorInvalidLocation {
    return Intl.message(
      'The selected location is not available',
      name: 'bookingErrorInvalidLocation',
      desc: '',
      args: [],
    );
  }

  /// `The selected {locationLabel} is not available`
  String bookingErrorInvalidLocationCustom(String locationLabel) {
    return Intl.message(
      'The selected $locationLabel is not available',
      name: 'bookingErrorInvalidLocationCustom',
      desc: '',
      args: [locationLabel],
    );
  }

  /// `The selected client is not valid`
  String get bookingErrorInvalidClient {
    return Intl.message(
      'The selected client is not valid',
      name: 'bookingErrorInvalidClient',
      desc: '',
      args: [],
    );
  }

  /// `The selected time is not valid`
  String get bookingErrorInvalidTime {
    return Intl.message(
      'The selected time is not valid',
      name: 'bookingErrorInvalidTime',
      desc: '',
      args: [],
    );
  }

  /// `The selected staff member is not available at this time`
  String get bookingErrorStaffUnavailable {
    return Intl.message(
      'The selected staff member is not available at this time',
      name: 'bookingErrorStaffUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `The selected {staffLabel} is not available at this time`
  String bookingErrorStaffUnavailableCustom(String staffLabel) {
    return Intl.message(
      'The selected $staffLabel is not available at this time',
      name: 'bookingErrorStaffUnavailableCustom',
      desc: '',
      args: [staffLabel],
    );
  }

  /// `Unable to load booking services`
  String get bookingErrorMissingServices {
    return Intl.message(
      'Unable to load booking services',
      name: 'bookingErrorMissingServices',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load booking {serviceLabel}`
  String bookingErrorMissingServicesCustom(String serviceLabel) {
    return Intl.message(
      'Unable to load booking $serviceLabel',
      name: 'bookingErrorMissingServicesCustom',
      desc: '',
      args: [serviceLabel],
    );
  }

  /// `The selected time is outside working hours`
  String get bookingErrorOutsideWorkingHours {
    return Intl.message(
      'The selected time is outside working hours',
      name: 'bookingErrorOutsideWorkingHours',
      desc: '',
      args: [],
    );
  }

  /// `Booking not found`
  String get bookingErrorNotFound {
    return Intl.message(
      'Booking not found',
      name: 'bookingErrorNotFound',
      desc: '',
      args: [],
    );
  }

  /// `You are not authorized to complete this action`
  String get bookingErrorUnauthorized {
    return Intl.message(
      'You are not authorized to complete this action',
      name: 'bookingErrorUnauthorized',
      desc: '',
      args: [],
    );
  }

  /// `Please check the entered data`
  String get bookingErrorValidation {
    return Intl.message(
      'Please check the entered data',
      name: 'bookingErrorValidation',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again`
  String get bookingErrorServer {
    return Intl.message(
      'Something went wrong. Please try again',
      name: 'bookingErrorServer',
      desc: '',
      args: [],
    );
  }

  /// `This booking cannot be modified`
  String get bookingErrorNotModifiable {
    return Intl.message(
      'This booking cannot be modified',
      name: 'bookingErrorNotModifiable',
      desc: '',
      args: [],
    );
  }

  /// `Booking confirmed!`
  String get confirmationTitle {
    return Intl.message(
      'Booking confirmed!',
      name: 'confirmationTitle',
      desc: '',
      args: [],
    );
  }

  /// `We've sent you a confirmation email`
  String get confirmationSubtitle {
    return Intl.message(
      'We\'ve sent you a confirmation email',
      name: 'confirmationSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Booking code: {id}`
  String confirmationBookingId(String id) {
    return Intl.message(
      'Booking code: $id',
      name: 'confirmationBookingId',
      desc: '',
      args: [id],
    );
  }

  /// `New booking`
  String get confirmationNewBooking {
    return Intl.message(
      'New booking',
      name: 'confirmationNewBooking',
      desc: '',
      args: [],
    );
  }

  /// `Go to home`
  String get confirmationGoHome {
    return Intl.message(
      'Go to home',
      name: 'confirmationGoHome',
      desc: '',
      args: [],
    );
  }

  /// `{minutes} min`
  String durationMinutes(int minutes) {
    return Intl.message(
      '$minutes min',
      name: 'durationMinutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `{minutes} min`
  String durationMinute(int minutes) {
    return Intl.message(
      '$minutes min',
      name: 'durationMinute',
      desc: '',
      args: [minutes],
    );
  }

  /// `{hours} hour`
  String durationHour(int hours) {
    return Intl.message(
      '$hours hour',
      name: 'durationHour',
      desc: '',
      args: [hours],
    );
  }

  /// `{hours} hour {minutes} min`
  String durationHourMinute(int hours, int minutes) {
    return Intl.message(
      '$hours hour $minutes min',
      name: 'durationHourMinute',
      desc: '',
      args: [hours, minutes],
    );
  }

  /// `€{price}`
  String priceFormat(String price) {
    return Intl.message(
      '€$price',
      name: 'priceFormat',
      desc: '',
      args: [price],
    );
  }

  /// `January`
  String get monthJanuary {
    return Intl.message('January', name: 'monthJanuary', desc: '', args: []);
  }

  /// `February`
  String get monthFebruary {
    return Intl.message('February', name: 'monthFebruary', desc: '', args: []);
  }

  /// `March`
  String get monthMarch {
    return Intl.message('March', name: 'monthMarch', desc: '', args: []);
  }

  /// `April`
  String get monthApril {
    return Intl.message('April', name: 'monthApril', desc: '', args: []);
  }

  /// `May`
  String get monthMay {
    return Intl.message('May', name: 'monthMay', desc: '', args: []);
  }

  /// `June`
  String get monthJune {
    return Intl.message('June', name: 'monthJune', desc: '', args: []);
  }

  /// `July`
  String get monthJuly {
    return Intl.message('July', name: 'monthJuly', desc: '', args: []);
  }

  /// `August`
  String get monthAugust {
    return Intl.message('August', name: 'monthAugust', desc: '', args: []);
  }

  /// `September`
  String get monthSeptember {
    return Intl.message(
      'September',
      name: 'monthSeptember',
      desc: '',
      args: [],
    );
  }

  /// `October`
  String get monthOctober {
    return Intl.message('October', name: 'monthOctober', desc: '', args: []);
  }

  /// `November`
  String get monthNovember {
    return Intl.message('November', name: 'monthNovember', desc: '', args: []);
  }

  /// `December`
  String get monthDecember {
    return Intl.message('December', name: 'monthDecember', desc: '', args: []);
  }

  /// `Mon`
  String get weekdayMon {
    return Intl.message('Mon', name: 'weekdayMon', desc: '', args: []);
  }

  /// `Tue`
  String get weekdayTue {
    return Intl.message('Tue', name: 'weekdayTue', desc: '', args: []);
  }

  /// `Wed`
  String get weekdayWed {
    return Intl.message('Wed', name: 'weekdayWed', desc: '', args: []);
  }

  /// `Thu`
  String get weekdayThu {
    return Intl.message('Thu', name: 'weekdayThu', desc: '', args: []);
  }

  /// `Fri`
  String get weekdayFri {
    return Intl.message('Fri', name: 'weekdayFri', desc: '', args: []);
  }

  /// `Sat`
  String get weekdaySat {
    return Intl.message('Sat', name: 'weekdaySat', desc: '', args: []);
  }

  /// `Sun`
  String get weekdaySun {
    return Intl.message('Sun', name: 'weekdaySun', desc: '', args: []);
  }

  /// `My bookings`
  String get myBookings {
    return Intl.message('My bookings', name: 'myBookings', desc: '', args: []);
  }

  /// `Upcoming`
  String get upcomingBookings {
    return Intl.message(
      'Upcoming',
      name: 'upcomingBookings',
      desc: '',
      args: [],
    );
  }

  /// `Past`
  String get pastBookings {
    return Intl.message('Past', name: 'pastBookings', desc: '', args: []);
  }

  /// `Cancelled`
  String get cancelledBookings {
    return Intl.message(
      'Cancelled',
      name: 'cancelledBookings',
      desc: '',
      args: [],
    );
  }

  /// `You have no upcoming bookings`
  String get noUpcomingBookings {
    return Intl.message(
      'You have no upcoming bookings',
      name: 'noUpcomingBookings',
      desc: '',
      args: [],
    );
  }

  /// `You have no past bookings`
  String get noPastBookings {
    return Intl.message(
      'You have no past bookings',
      name: 'noPastBookings',
      desc: '',
      args: [],
    );
  }

  /// `You have no cancelled bookings`
  String get noCancelledBookings {
    return Intl.message(
      'You have no cancelled bookings',
      name: 'noCancelledBookings',
      desc: '',
      args: [],
    );
  }

  /// `Error loading bookings`
  String get errorLoadingBookings {
    return Intl.message(
      'Error loading bookings',
      name: 'errorLoadingBookings',
      desc: '',
      args: [],
    );
  }

  /// `Modifiable`
  String get modifiable {
    return Intl.message('Modifiable', name: 'modifiable', desc: '', args: []);
  }

  /// `Not modifiable`
  String get notModifiable {
    return Intl.message(
      'Not modifiable',
      name: 'notModifiable',
      desc: '',
      args: [],
    );
  }

  /// `{days, plural, =1{Modifiable until tomorrow} other{Modifiable for {days} days}}`
  String modifiableUntilDays(int days) {
    return Intl.plural(
      days,
      one: 'Modifiable until tomorrow',
      other: 'Modifiable for $days days',
      name: 'modifiableUntilDays',
      desc: '',
      args: [days],
    );
  }

  /// `{hours, plural, =1{Modifiable for 1 hour} other{Modifiable for {hours} hours}}`
  String modifiableUntilHours(int hours) {
    return Intl.plural(
      hours,
      one: 'Modifiable for 1 hour',
      other: 'Modifiable for $hours hours',
      name: 'modifiableUntilHours',
      desc: '',
      args: [hours],
    );
  }

  /// `{minutes, plural, =1{Modifiable for 1 minute} other{Modifiable for {minutes} minutes}}`
  String modifiableUntilMinutes(int minutes) {
    return Intl.plural(
      minutes,
      one: 'Modifiable for 1 minute',
      other: 'Modifiable for $minutes minutes',
      name: 'modifiableUntilMinutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `Modifiable until {dateTime}`
  String modifiableUntilDateTime(Object dateTime) {
    return Intl.message(
      'Modifiable until $dateTime',
      name: 'modifiableUntilDateTime',
      desc: '',
      args: [dateTime],
    );
  }

  /// `The time window to modify or cancel this booking has expired.`
  String get modificationWindowExpired {
    return Intl.message(
      'The time window to modify or cancel this booking has expired.',
      name: 'modificationWindowExpired',
      desc: '',
      args: [],
    );
  }

  /// `The deadline to modify or cancel expired on {dateTime}.`
  String modificationWindowExpiredDateTime(Object dateTime) {
    return Intl.message(
      'The deadline to modify or cancel expired on $dateTime.',
      name: 'modificationWindowExpiredDateTime',
      desc: '',
      args: [dateTime],
    );
  }

  /// `Reschedule`
  String get modify {
    return Intl.message('Reschedule', name: 'modify', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Yes`
  String get yes {
    return Intl.message('Yes', name: 'yes', desc: '', args: []);
  }

  /// `No`
  String get no {
    return Intl.message('No', name: 'no', desc: '', args: []);
  }

  /// `Cancel booking`
  String get cancelBookingTitle {
    return Intl.message(
      'Cancel booking',
      name: 'cancelBookingTitle',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to cancel this booking?`
  String get cancelBookingConfirm {
    return Intl.message(
      'Are you sure you want to cancel this booking?',
      name: 'cancelBookingConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Booking cancelled successfully`
  String get bookingCancelled {
    return Intl.message(
      'Booking cancelled successfully',
      name: 'bookingCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Error cancelling booking`
  String get bookingCancelFailed {
    return Intl.message(
      'Error cancelling booking',
      name: 'bookingCancelFailed',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get actionCancelBooking {
    return Intl.message(
      'Cancel',
      name: 'actionCancelBooking',
      desc: 'Action to cancel a booking from the customer app',
      args: [],
    );
  }

  /// `Modify feature under development`
  String get modifyNotImplemented {
    return Intl.message(
      'Modify feature under development',
      name: 'modifyNotImplemented',
      desc: '',
      args: [],
    );
  }

  /// `Modify booking`
  String get rescheduleBookingTitle {
    return Intl.message(
      'Modify booking',
      name: 'rescheduleBookingTitle',
      desc: '',
      args: [],
    );
  }

  /// `Current booking`
  String get currentBooking {
    return Intl.message(
      'Current booking',
      name: 'currentBooking',
      desc: '',
      args: [],
    );
  }

  /// `Select new date`
  String get selectNewDate {
    return Intl.message(
      'Select new date',
      name: 'selectNewDate',
      desc: '',
      args: [],
    );
  }

  /// `Select date`
  String get selectDate {
    return Intl.message('Select date', name: 'selectDate', desc: '', args: []);
  }

  /// `Select new time`
  String get selectNewTime {
    return Intl.message(
      'Select new time',
      name: 'selectNewTime',
      desc: '',
      args: [],
    );
  }

  /// `Confirm changes`
  String get confirmReschedule {
    return Intl.message(
      'Confirm changes',
      name: 'confirmReschedule',
      desc: '',
      args: [],
    );
  }

  /// `Booking modified successfully`
  String get bookingRescheduled {
    return Intl.message(
      'Booking modified successfully',
      name: 'bookingRescheduled',
      desc: '',
      args: [],
    );
  }

  /// `The time slot is no longer available. Your original booking remains unchanged.`
  String get slotNoLongerAvailable {
    return Intl.message(
      'The time slot is no longer available. Your original booking remains unchanged.',
      name: 'slotNoLongerAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Booking updated`
  String get bookingUpdatedTitle {
    return Intl.message(
      'Booking updated',
      name: 'bookingUpdatedTitle',
      desc: '',
      args: [],
    );
  }

  /// `Required field`
  String get validationRequired {
    return Intl.message(
      'Required field',
      name: 'validationRequired',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email`
  String get validationInvalidEmail {
    return Intl.message(
      'Invalid email',
      name: 'validationInvalidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Invalid phone`
  String get validationInvalidPhone {
    return Intl.message(
      'Invalid phone',
      name: 'validationInvalidPhone',
      desc: '',
      args: [],
    );
  }

  /// `Booking history`
  String get bookingHistoryTitle {
    return Intl.message(
      'Booking history',
      name: 'bookingHistoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `No events recorded`
  String get bookingHistoryEmpty {
    return Intl.message(
      'No events recorded',
      name: 'bookingHistoryEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Loading history...`
  String get bookingHistoryLoading {
    return Intl.message(
      'Loading history...',
      name: 'bookingHistoryLoading',
      desc: '',
      args: [],
    );
  }

  /// `Error loading history`
  String get bookingHistoryError {
    return Intl.message(
      'Error loading history',
      name: 'bookingHistoryError',
      desc: '',
      args: [],
    );
  }

  /// `Booking created`
  String get bookingHistoryEventCreated {
    return Intl.message(
      'Booking created',
      name: 'bookingHistoryEventCreated',
      desc: '',
      args: [],
    );
  }

  /// `Booking updated`
  String get bookingHistoryEventUpdated {
    return Intl.message(
      'Booking updated',
      name: 'bookingHistoryEventUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Booking cancelled`
  String get bookingHistoryEventCancelled {
    return Intl.message(
      'Booking cancelled',
      name: 'bookingHistoryEventCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Service added`
  String get bookingHistoryEventItemAdded {
    return Intl.message(
      'Service added',
      name: 'bookingHistoryEventItemAdded',
      desc: '',
      args: [],
    );
  }

  /// `Service removed`
  String get bookingHistoryEventItemDeleted {
    return Intl.message(
      'Service removed',
      name: 'bookingHistoryEventItemDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Appointment updated`
  String get bookingHistoryEventAppointmentUpdated {
    return Intl.message(
      'Appointment updated',
      name: 'bookingHistoryEventAppointmentUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Time changed`
  String get bookingHistoryEventTimeChanged {
    return Intl.message(
      'Time changed',
      name: 'bookingHistoryEventTimeChanged',
      desc: '',
      args: [],
    );
  }

  /// `Staff changed`
  String get bookingHistoryEventStaffChanged {
    return Intl.message(
      'Staff changed',
      name: 'bookingHistoryEventStaffChanged',
      desc: '',
      args: [],
    );
  }

  /// `Price changed`
  String get bookingHistoryEventPriceChanged {
    return Intl.message(
      'Price changed',
      name: 'bookingHistoryEventPriceChanged',
      desc: '',
      args: [],
    );
  }

  /// `Duration changed`
  String get bookingHistoryEventDurationChanged {
    return Intl.message(
      'Duration changed',
      name: 'bookingHistoryEventDurationChanged',
      desc: '',
      args: [],
    );
  }

  /// `Booking replaced`
  String get bookingHistoryEventReplaced {
    return Intl.message(
      'Booking replaced',
      name: 'bookingHistoryEventReplaced',
      desc: '',
      args: [],
    );
  }

  /// `Email sent of type: {type}`
  String bookingHistoryEventNotificationSentTitle(Object type) {
    return Intl.message(
      'Email sent of type: $type',
      name: 'bookingHistoryEventNotificationSentTitle',
      desc: '',
      args: [type],
    );
  }

  /// `Customer`
  String get bookingHistoryActorCustomer {
    return Intl.message(
      'Customer',
      name: 'bookingHistoryActorCustomer',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get bookingHistoryActorStaff {
    return Intl.message(
      'Staff',
      name: 'bookingHistoryActorStaff',
      desc: '',
      args: [],
    );
  }

  /// `System`
  String get bookingHistoryActorSystem {
    return Intl.message(
      'System',
      name: 'bookingHistoryActorSystem',
      desc: '',
      args: [],
    );
  }

  /// `Recipient: {email}`
  String bookingHistoryNotificationRecipient(Object email) {
    return Intl.message(
      'Recipient: $email',
      name: 'bookingHistoryNotificationRecipient',
      desc: '',
      args: [email],
    );
  }

  /// `Sent at: {dateTime}`
  String bookingHistoryNotificationSentAt(Object dateTime) {
    return Intl.message(
      'Sent at: $dateTime',
      name: 'bookingHistoryNotificationSentAt',
      desc: '',
      args: [dateTime],
    );
  }

  /// `Booking confirmation`
  String get bookingHistoryNotificationChannelConfirmed {
    return Intl.message(
      'Booking confirmation',
      name: 'bookingHistoryNotificationChannelConfirmed',
      desc: '',
      args: [],
    );
  }

  /// `Booking reminder`
  String get bookingHistoryNotificationChannelReminder {
    return Intl.message(
      'Booking reminder',
      name: 'bookingHistoryNotificationChannelReminder',
      desc: '',
      args: [],
    );
  }

  /// `Booking cancellation`
  String get bookingHistoryNotificationChannelCancelled {
    return Intl.message(
      'Booking cancellation',
      name: 'bookingHistoryNotificationChannelCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Booking rescheduled`
  String get bookingHistoryNotificationChannelRescheduled {
    return Intl.message(
      'Booking rescheduled',
      name: 'bookingHistoryNotificationChannelRescheduled',
      desc: '',
      args: [],
    );
  }

  /// `Changed fields: {fields}`
  String bookingHistoryChangedFields(String fields) {
    return Intl.message(
      'Changed fields: $fields',
      name: 'bookingHistoryChangedFields',
      desc: '',
      args: [fields],
    );
  }

  /// `CANCELLED`
  String get cancelledBadge {
    return Intl.message(
      'CANCELLED',
      name: 'cancelledBadge',
      desc: '',
      args: [],
    );
  }

  /// `Business not found`
  String get businessNotFound {
    return Intl.message(
      'Business not found',
      name: 'businessNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Please check the URL or contact the business directly.`
  String get businessNotFoundHint {
    return Intl.message(
      'Please check the URL or contact the business directly.',
      name: 'businessNotFoundHint',
      desc: '',
      args: [],
    );
  }

  /// `Account linked to another business`
  String get wrongBusinessAuthTitle {
    return Intl.message(
      'Account linked to another business',
      name: 'wrongBusinessAuthTitle',
      desc: '',
      args: [],
    );
  }

  /// `To book at {businessName}, you need to log in with an account registered here.`
  String wrongBusinessAuthMessage(String businessName) {
    return Intl.message(
      'To book at $businessName, you need to log in with an account registered here.',
      name: 'wrongBusinessAuthMessage',
      desc: '',
      args: [businessName],
    );
  }

  /// `Log out and sign in here`
  String get wrongBusinessAuthAction {
    return Intl.message(
      'Log out and sign in here',
      name: 'wrongBusinessAuthAction',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<L10n> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'it'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<L10n> load(Locale locale) => L10n.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
