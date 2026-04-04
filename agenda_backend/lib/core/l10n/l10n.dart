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

  /// `Agenda Platform`
  String get appTitle {
    return Intl.message(
      'Agenda Platform',
      name: 'appTitle',
      desc: '',
      args: [],
    );
  }

  /// `Agenda`
  String get navAgenda {
    return Intl.message('Agenda', name: 'navAgenda', desc: '', args: []);
  }

  /// `Clients`
  String get navClients {
    return Intl.message('Clients', name: 'navClients', desc: '', args: []);
  }

  /// `Services`
  String get navServices {
    return Intl.message('Services', name: 'navServices', desc: '', args: []);
  }

  /// `Team`
  String get navStaff {
    return Intl.message('Team', name: 'navStaff', desc: '', args: []);
  }

  /// `Profile`
  String get navProfile {
    return Intl.message('Profile', name: 'navProfile', desc: '', args: []);
  }

  /// `More`
  String get navMore {
    return Intl.message('More', name: 'navMore', desc: '', args: []);
  }

  /// `Clients List`
  String get clientsTitle {
    return Intl.message(
      'Clients List',
      name: 'clientsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Specify at least one builder for form factor`
  String get errorFormFactorBuilderRequired {
    return Intl.message(
      'Specify at least one builder for form factor',
      name: 'errorFormFactorBuilderRequired',
      desc: '',
      args: [],
    );
  }

  /// `No builder available for {factor}`
  String errorFormFactorBuilderMissing(String factor) {
    return Intl.message(
      'No builder available for $factor',
      name: 'errorFormFactorBuilderMissing',
      desc: '',
      args: [factor],
    );
  }

  /// `Error`
  String get errorTitle {
    return Intl.message('Error', name: 'errorTitle', desc: '', args: []);
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

  /// `Service not found`
  String get errorServiceNotFound {
    return Intl.message(
      'Service not found',
      name: 'errorServiceNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Exception not found: {id}`
  String errorExceptionNotFound(int id) {
    return Intl.message(
      'Exception not found: $id',
      name: 'errorExceptionNotFound',
      desc: '',
      args: [id],
    );
  }

  /// `Team Screen`
  String get staffScreenPlaceholder {
    return Intl.message(
      'Team Screen',
      name: 'staffScreenPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get actionDelete {
    return Intl.message('Delete', name: 'actionDelete', desc: '', args: []);
  }

  /// `Cancel`
  String get actionCancel {
    return Intl.message('Cancel', name: 'actionCancel', desc: '', args: []);
  }

  /// `Confirm`
  String get actionConfirm {
    return Intl.message('Confirm', name: 'actionConfirm', desc: '', args: []);
  }

  /// `Close`
  String get actionClose {
    return Intl.message('Close', name: 'actionClose', desc: '', args: []);
  }

  /// `Retry`
  String get actionRetry {
    return Intl.message('Retry', name: 'actionRetry', desc: '', args: []);
  }

  /// `Reschedule`
  String get actionReschedule {
    return Intl.message(
      'Reschedule',
      name: 'actionReschedule',
      desc: '',
      args: [],
    );
  }

  /// `Confirm deletion?`
  String get deleteConfirmationTitle {
    return Intl.message(
      'Confirm deletion?',
      name: 'deleteConfirmationTitle',
      desc: '',
      args: [],
    );
  }

  /// `Reschedule mode active: select a date and click a slot.`
  String get bookingRescheduleModeHint {
    return Intl.message(
      'Reschedule mode active: select a date and click a slot.',
      name: 'bookingRescheduleModeHint',
      desc: '',
      args: [],
    );
  }

  /// `Reschedule mode active: select a slot in the current week or change week to choose another date.`
  String get bookingRescheduleModeHintWeekSame {
    return Intl.message(
      'Reschedule mode active: select a slot in the current week or change week to choose another date.',
      name: 'bookingRescheduleModeHintWeekSame',
      desc: '',
      args: [],
    );
  }

  /// `Reschedule mode active: select a date (including another week) and click a slot.`
  String get bookingRescheduleModeHintWeekDifferent {
    return Intl.message(
      'Reschedule mode active: select a date (including another week) and click a slot.',
      name: 'bookingRescheduleModeHintWeekDifferent',
      desc: '',
      args: [],
    );
  }

  /// `Rescheduling is not available in multi-staff weekly view. Select a single staff member or switch to day view.`
  String get bookingRescheduleNotAvailableForCurrentView {
    return Intl.message(
      'Rescheduling is not available in multi-staff weekly view. Select a single staff member or switch to day view.',
      name: 'bookingRescheduleNotAvailableForCurrentView',
      desc: '',
      args: [],
    );
  }

  /// `Cancel reschedule`
  String get bookingRescheduleCancelAction {
    return Intl.message(
      'Cancel reschedule',
      name: 'bookingRescheduleCancelAction',
      desc: '',
      args: [],
    );
  }

  /// `Confirm reschedule?`
  String get bookingRescheduleConfirmTitle {
    return Intl.message(
      'Confirm reschedule?',
      name: 'bookingRescheduleConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `The booking will be moved to {date} at {time} for {staffName}.`
  String bookingRescheduleConfirmMessage(
    String date,
    String time,
    String staffName,
  ) {
    return Intl.message(
      'The booking will be moved to $date at $time for $staffName.',
      name: 'bookingRescheduleConfirmMessage',
      desc: '',
      args: [date, time, staffName],
    );
  }

  /// `Unable to reschedule the booking.`
  String get bookingRescheduleMoveFailed {
    return Intl.message(
      'Unable to reschedule the booking.',
      name: 'bookingRescheduleMoveFailed',
      desc: '',
      args: [],
    );
  }

  /// `Unable to reschedule: one or more services would fall outside the selected day.`
  String get bookingRescheduleOutOfDayBlocked {
    return Intl.message(
      'Unable to reschedule: one or more services would fall outside the selected day.',
      name: 'bookingRescheduleOutOfDayBlocked',
      desc: '',
      args: [],
    );
  }

  /// `Booking not found.`
  String get bookingRescheduleMissingBooking {
    return Intl.message(
      'Booking not found.',
      name: 'bookingRescheduleMissingBooking',
      desc: '',
      args: [],
    );
  }

  /// `Today`
  String get agendaToday {
    return Intl.message('Today', name: 'agendaToday', desc: '', args: []);
  }

  /// `View`
  String get agendaViewMode {
    return Intl.message('View', name: 'agendaViewMode', desc: '', args: []);
  }

  /// `Switch to day by day`
  String get agendaViewModeSwitchToDay {
    return Intl.message(
      'Switch to day by day',
      name: 'agendaViewModeSwitchToDay',
      desc: '',
      args: [],
    );
  }

  /// `Switch to week by week`
  String get agendaViewModeSwitchToWeek {
    return Intl.message(
      'Switch to week by week',
      name: 'agendaViewModeSwitchToWeek',
      desc: '',
      args: [],
    );
  }

  /// `Previous day`
  String get agendaPrevDay {
    return Intl.message(
      'Previous day',
      name: 'agendaPrevDay',
      desc: '',
      args: [],
    );
  }

  /// `Next day`
  String get agendaNextDay {
    return Intl.message('Next day', name: 'agendaNextDay', desc: '', args: []);
  }

  /// `Previous Week`
  String get agendaPrevWeek {
    return Intl.message(
      'Previous Week',
      name: 'agendaPrevWeek',
      desc: '',
      args: [],
    );
  }

  /// `Next Week`
  String get agendaNextWeek {
    return Intl.message(
      'Next Week',
      name: 'agendaNextWeek',
      desc: '',
      args: [],
    );
  }

  /// `Previous month`
  String get agendaPrevMonth {
    return Intl.message(
      'Previous month',
      name: 'agendaPrevMonth',
      desc: '',
      args: [],
    );
  }

  /// `Next month`
  String get agendaNextMonth {
    return Intl.message(
      'Next month',
      name: 'agendaNextMonth',
      desc: '',
      args: [],
    );
  }

  /// `No locations available`
  String get agendaNoLocations {
    return Intl.message(
      'No locations available',
      name: 'agendaNoLocations',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load this week's appointments.`
  String get agendaWeeklyLoadError {
    return Intl.message(
      'Unable to load this week\'s appointments.',
      name: 'agendaWeeklyLoadError',
      desc: '',
      args: [],
    );
  }

  /// `Select location`
  String get agendaSelectLocation {
    return Intl.message(
      'Select location',
      name: 'agendaSelectLocation',
      desc: '',
      args: [],
    );
  }

  /// `All locations`
  String get allLocations {
    return Intl.message(
      'All locations',
      name: 'allLocations',
      desc: '',
      args: [],
    );
  }

  /// `Weekly availability`
  String get availabilityTitle {
    return Intl.message(
      'Weekly availability',
      name: 'availabilityTitle',
      desc: '',
      args: [],
    );
  }

  /// `Availability – {name}`
  String availabilityTitleFor(String name) {
    return Intl.message(
      'Availability – $name',
      name: 'availabilityTitleFor',
      desc: '',
      args: [name],
    );
  }

  /// `Save changes`
  String get availabilitySave {
    return Intl.message(
      'Save changes',
      name: 'availabilitySave',
      desc: '',
      args: [],
    );
  }

  /// `Current week`
  String get currentWeek {
    return Intl.message(
      'Current week',
      name: 'currentWeek',
      desc: '',
      args: [],
    );
  }

  /// `{hours}h {minutes}m`
  String hoursMinutesCompact(Object hours, Object minutes) {
    return Intl.message(
      '${hours}h ${minutes}m',
      name: 'hoursMinutesCompact',
      desc: '',
      args: [hours, minutes],
    );
  }

  /// `{hours}h`
  String hoursHoursOnly(Object hours) {
    return Intl.message(
      '${hours}h',
      name: 'hoursHoursOnly',
      desc: '',
      args: [hours],
    );
  }

  /// `Team:`
  String get labelStaff {
    return Intl.message('Team:', name: 'labelStaff', desc: '', args: []);
  }

  /// `Select`
  String get labelSelect {
    return Intl.message('Select', name: 'labelSelect', desc: '', args: []);
  }

  /// `Availability`
  String get staffHubAvailabilityTitle {
    return Intl.message(
      'Availability',
      name: 'staffHubAvailabilityTitle',
      desc: '',
      args: [],
    );
  }

  /// `Configure weekly working hours`
  String get staffHubAvailabilitySubtitle {
    return Intl.message(
      'Configure weekly working hours',
      name: 'staffHubAvailabilitySubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Team`
  String get staffHubTeamTitle {
    return Intl.message('Team', name: 'staffHubTeamTitle', desc: '', args: []);
  }

  /// `Manage members and roles`
  String get staffHubTeamSubtitle {
    return Intl.message(
      'Manage members and roles',
      name: 'staffHubTeamSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Statistics`
  String get staffHubStatsTitle {
    return Intl.message(
      'Statistics',
      name: 'staffHubStatsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Performance and workloads`
  String get staffHubStatsSubtitle {
    return Intl.message(
      'Performance and workloads',
      name: 'staffHubStatsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Not yet available`
  String get staffHubNotYetAvailable {
    return Intl.message(
      'Not yet available',
      name: 'staffHubNotYetAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Edit hours`
  String get staffEditHours {
    return Intl.message(
      'Edit hours',
      name: 'staffEditHours',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get actionEdit {
    return Intl.message('Edit', name: 'actionEdit', desc: '', args: []);
  }

  /// `{minutes} min`
  String durationMinute(Object minutes) {
    return Intl.message(
      '$minutes min',
      name: 'durationMinute',
      desc: '',
      args: [minutes],
    );
  }

  /// `{hours} hour`
  String durationHour(Object hours) {
    return Intl.message(
      '$hours hour',
      name: 'durationHour',
      desc: '',
      args: [hours],
    );
  }

  /// `{hours} hour {minutes} min`
  String durationHourMinute(Object hours, Object minutes) {
    return Intl.message(
      '$hours hour $minutes min',
      name: 'durationHourMinute',
      desc: '',
      args: [hours, minutes],
    );
  }

  /// `Free`
  String get freeLabel {
    return Intl.message('Free', name: 'freeLabel', desc: '', args: []);
  }

  /// `starting from`
  String get priceStartingFromPrefix {
    return Intl.message(
      'starting from',
      name: 'priceStartingFromPrefix',
      desc: '',
      args: [],
    );
  }

  /// `N/A`
  String get priceNotAvailable {
    return Intl.message('N/A', name: 'priceNotAvailable', desc: '', args: []);
  }

  /// `New client`
  String get clientsNew {
    return Intl.message('New client', name: 'clientsNew', desc: '', args: []);
  }

  /// `Edit client`
  String get clientsEdit {
    return Intl.message('Edit client', name: 'clientsEdit', desc: '', args: []);
  }

  /// `No clients`
  String get clientsEmpty {
    return Intl.message('No clients', name: 'clientsEmpty', desc: '', args: []);
  }

  /// `Save`
  String get actionSave {
    return Intl.message('Save', name: 'actionSave', desc: '', args: []);
  }

  /// `All`
  String get filterAll {
    return Intl.message('All', name: 'filterAll', desc: '', args: []);
  }

  /// `VIP`
  String get filterVIP {
    return Intl.message('VIP', name: 'filterVIP', desc: '', args: []);
  }

  /// `Inactive`
  String get filterInactive {
    return Intl.message('Inactive', name: 'filterInactive', desc: '', args: []);
  }

  /// `New`
  String get filterNew {
    return Intl.message('New', name: 'filterNew', desc: '', args: []);
  }

  /// `First name`
  String get formFirstName {
    return Intl.message(
      'First name',
      name: 'formFirstName',
      desc: '',
      args: [],
    );
  }

  /// `Last name`
  String get formLastName {
    return Intl.message('Last name', name: 'formLastName', desc: '', args: []);
  }

  /// `Email`
  String get formEmail {
    return Intl.message('Email', name: 'formEmail', desc: '', args: []);
  }

  /// `Phone`
  String get formPhone {
    return Intl.message('Phone', name: 'formPhone', desc: '', args: []);
  }

  /// `Notes (not visible to client)`
  String get formNotes {
    return Intl.message(
      'Notes (not visible to client)',
      name: 'formNotes',
      desc: '',
      args: [],
    );
  }

  /// `Required`
  String get validationRequired {
    return Intl.message(
      'Required',
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

  /// `Last visit: {date}`
  String lastVisitLabel(String date) {
    return Intl.message(
      'Last visit: $date',
      name: 'lastVisitLabel',
      desc: '',
      args: [date],
    );
  }

  /// `Enter at least first name or last name`
  String get validationNameOrLastNameRequired {
    return Intl.message(
      'Enter at least first name or last name',
      name: 'validationNameOrLastNameRequired',
      desc: '',
      args: [],
    );
  }

  /// `Services`
  String get servicesTabLabel {
    return Intl.message(
      'Services',
      name: 'servicesTabLabel',
      desc: '',
      args: [],
    );
  }

  /// `Packages`
  String get servicePackagesTabLabel {
    return Intl.message(
      'Packages',
      name: 'servicePackagesTabLabel',
      desc: '',
      args: [],
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

  /// `Most popular`
  String get popularServicesTitle {
    return Intl.message(
      'Most popular',
      name: 'popularServicesTitle',
      desc: '',
      args: [],
    );
  }

  /// `No packages available`
  String get servicePackagesEmptyState {
    return Intl.message(
      'No packages available',
      name: 'servicePackagesEmptyState',
      desc: '',
      args: [],
    );
  }

  /// `New package`
  String get servicePackageNewMenu {
    return Intl.message(
      'New package',
      name: 'servicePackageNewMenu',
      desc: '',
      args: [],
    );
  }

  /// `New package`
  String get servicePackageNewTitle {
    return Intl.message(
      'New package',
      name: 'servicePackageNewTitle',
      desc: '',
      args: [],
    );
  }

  /// `Edit package`
  String get servicePackageEditTitle {
    return Intl.message(
      'Edit package',
      name: 'servicePackageEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Package name`
  String get servicePackageNameLabel {
    return Intl.message(
      'Package name',
      name: 'servicePackageNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get servicePackageDescriptionLabel {
    return Intl.message(
      'Description',
      name: 'servicePackageDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Package price`
  String get servicePackageOverridePriceLabel {
    return Intl.message(
      'Package price',
      name: 'servicePackageOverridePriceLabel',
      desc: '',
      args: [],
    );
  }

  /// `Package duration (min)`
  String get servicePackageOverrideDurationLabel {
    return Intl.message(
      'Package duration (min)',
      name: 'servicePackageOverrideDurationLabel',
      desc: '',
      args: [],
    );
  }

  /// `Package active`
  String get servicePackageActiveLabel {
    return Intl.message(
      'Package active',
      name: 'servicePackageActiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `Included services`
  String get servicePackageServicesLabel {
    return Intl.message(
      'Included services',
      name: 'servicePackageServicesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Service order`
  String get servicePackageOrderLabel {
    return Intl.message(
      'Service order',
      name: 'servicePackageOrderLabel',
      desc: '',
      args: [],
    );
  }

  /// `No services selected`
  String get servicePackageNoServices {
    return Intl.message(
      'No services selected',
      name: 'servicePackageNoServices',
      desc: '',
      args: [],
    );
  }

  /// `Select at least one service`
  String get servicePackageServicesRequired {
    return Intl.message(
      'Select at least one service',
      name: 'servicePackageServicesRequired',
      desc: '',
      args: [],
    );
  }

  /// `Package created`
  String get servicePackageCreatedTitle {
    return Intl.message(
      'Package created',
      name: 'servicePackageCreatedTitle',
      desc: '',
      args: [],
    );
  }

  /// `The package has been created.`
  String get servicePackageCreatedMessage {
    return Intl.message(
      'The package has been created.',
      name: 'servicePackageCreatedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Package updated`
  String get servicePackageUpdatedTitle {
    return Intl.message(
      'Package updated',
      name: 'servicePackageUpdatedTitle',
      desc: '',
      args: [],
    );
  }

  /// `The package has been updated.`
  String get servicePackageUpdatedMessage {
    return Intl.message(
      'The package has been updated.',
      name: 'servicePackageUpdatedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Failed to save the package.`
  String get servicePackageSaveError {
    return Intl.message(
      'Failed to save the package.',
      name: 'servicePackageSaveError',
      desc: '',
      args: [],
    );
  }

  /// `Delete package?`
  String get servicePackageDeleteTitle {
    return Intl.message(
      'Delete package?',
      name: 'servicePackageDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `This action cannot be undone.`
  String get servicePackageDeleteMessage {
    return Intl.message(
      'This action cannot be undone.',
      name: 'servicePackageDeleteMessage',
      desc: '',
      args: [],
    );
  }

  /// `Package deleted`
  String get servicePackageDeletedTitle {
    return Intl.message(
      'Package deleted',
      name: 'servicePackageDeletedTitle',
      desc: '',
      args: [],
    );
  }

  /// `The package has been deleted.`
  String get servicePackageDeletedMessage {
    return Intl.message(
      'The package has been deleted.',
      name: 'servicePackageDeletedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Failed to delete the package.`
  String get servicePackageDeleteError {
    return Intl.message(
      'Failed to delete the package.',
      name: 'servicePackageDeleteError',
      desc: '',
      args: [],
    );
  }

  /// `Inactive`
  String get servicePackageInactiveLabel {
    return Intl.message(
      'Inactive',
      name: 'servicePackageInactiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `Invalid`
  String get servicePackageBrokenLabel {
    return Intl.message(
      'Invalid',
      name: 'servicePackageBrokenLabel',
      desc: '',
      args: [],
    );
  }

  /// `services`
  String get servicesLabel {
    return Intl.message('services', name: 'servicesLabel', desc: '', args: []);
  }

  /// `min`
  String get minutesLabel {
    return Intl.message('min', name: 'minutesLabel', desc: '', args: []);
  }

  /// `Add package`
  String get addPackage {
    return Intl.message('Add package', name: 'addPackage', desc: '', args: []);
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

  /// `Invalid number`
  String get validationInvalidNumber {
    return Intl.message(
      'Invalid number',
      name: 'validationInvalidNumber',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get agendaAdd {
    return Intl.message('Add', name: 'agendaAdd', desc: '', args: []);
  }

  /// `Add a...`
  String get agendaAddTitle {
    return Intl.message('Add a...', name: 'agendaAddTitle', desc: '', args: []);
  }

  /// `New appointment`
  String get agendaAddAppointment {
    return Intl.message(
      'New appointment',
      name: 'agendaAddAppointment',
      desc: '',
      args: [],
    );
  }

  /// `New block`
  String get agendaAddBlock {
    return Intl.message(
      'New block',
      name: 'agendaAddBlock',
      desc: '',
      args: [],
    );
  }

  /// `New appointment`
  String get appointmentDialogTitleNew {
    return Intl.message(
      'New appointment',
      name: 'appointmentDialogTitleNew',
      desc: '',
      args: [],
    );
  }

  /// `Edit appointment`
  String get appointmentDialogTitleEdit {
    return Intl.message(
      'Edit appointment',
      name: 'appointmentDialogTitleEdit',
      desc: '',
      args: [],
    );
  }

  /// `Date`
  String get formDate {
    return Intl.message('Date', name: 'formDate', desc: '', args: []);
  }

  /// `Service`
  String get formService {
    return Intl.message('Service', name: 'formService', desc: '', args: []);
  }

  /// `Client`
  String get formClient {
    return Intl.message('Client', name: 'formClient', desc: '', args: []);
  }

  /// `Team`
  String get formStaff {
    return Intl.message('Team', name: 'formStaff', desc: '', args: []);
  }

  /// `Booking details`
  String get bookingDetails {
    return Intl.message(
      'Booking details',
      name: 'bookingDetails',
      desc: '',
      args: [],
    );
  }

  /// `Booking notes`
  String get bookingNotes {
    return Intl.message(
      'Booking notes',
      name: 'bookingNotes',
      desc: '',
      args: [],
    );
  }

  /// `Notes`
  String get appointmentNotesTitle {
    return Intl.message(
      'Notes',
      name: 'appointmentNotesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Appointment note`
  String get appointmentNoteLabel {
    return Intl.message(
      'Appointment note',
      name: 'appointmentNoteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Client note`
  String get clientNoteLabel {
    return Intl.message(
      'Client note',
      name: 'clientNoteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Services`
  String get bookingItems {
    return Intl.message('Services', name: 'bookingItems', desc: '', args: []);
  }

  /// `Total`
  String get bookingTotal {
    return Intl.message('Total', name: 'bookingTotal', desc: '', args: []);
  }

  /// `Warning: the appointment time includes unavailable slots for the chosen team.`
  String get bookingUnavailableTimeWarningAppointment {
    return Intl.message(
      'Warning: the appointment time includes unavailable slots for the chosen team.',
      name: 'bookingUnavailableTimeWarningAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Warning: this service time includes unavailable slots for the chosen team.`
  String get bookingUnavailableTimeWarningService {
    return Intl.message(
      'Warning: this service time includes unavailable slots for the chosen team.',
      name: 'bookingUnavailableTimeWarningService',
      desc: '',
      args: [],
    );
  }

  /// `Warning: the selected team member is not eligible for this service.`
  String get bookingStaffNotEligibleWarning {
    return Intl.message(
      'Warning: the selected team member is not eligible for this service.',
      name: 'bookingStaffNotEligibleWarning',
      desc: '',
      args: [],
    );
  }

  /// `Delete booking`
  String get actionDeleteBooking {
    return Intl.message(
      'Delete booking',
      name: 'actionDeleteBooking',
      desc: '',
      args: [],
    );
  }

  /// `Delete appointment?`
  String get deleteAppointmentConfirmTitle {
    return Intl.message(
      'Delete appointment?',
      name: 'deleteAppointmentConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `The appointment will be removed. This action cannot be undone.`
  String get deleteAppointmentConfirmMessage {
    return Intl.message(
      'The appointment will be removed. This action cannot be undone.',
      name: 'deleteAppointmentConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Delete entire booking?`
  String get deleteBookingConfirmTitle {
    return Intl.message(
      'Delete entire booking?',
      name: 'deleteBookingConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `All linked services will be removed. This action cannot be undone.`
  String get deleteBookingConfirmMessage {
    return Intl.message(
      'All linked services will be removed. This action cannot be undone.',
      name: 'deleteBookingConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Locations`
  String get teamLocationsLabel {
    return Intl.message(
      'Locations',
      name: 'teamLocationsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Team`
  String get teamStaffLabel {
    return Intl.message('Team', name: 'teamStaffLabel', desc: '', args: []);
  }

  /// `Add team member`
  String get teamAddStaff {
    return Intl.message(
      'Add team member',
      name: 'teamAddStaff',
      desc: '',
      args: [],
    );
  }

  /// `No team members in this location`
  String get teamNoStaffInLocation {
    return Intl.message(
      'No team members in this location',
      name: 'teamNoStaffInLocation',
      desc: '',
      args: [],
    );
  }

  /// `Cannot delete location`
  String get teamDeleteLocationBlockedTitle {
    return Intl.message(
      'Cannot delete location',
      name: 'teamDeleteLocationBlockedTitle',
      desc: '',
      args: [],
    );
  }

  /// `Remove all team members assigned to this location first.`
  String get teamDeleteLocationBlockedMessage {
    return Intl.message(
      'Remove all team members assigned to this location first.',
      name: 'teamDeleteLocationBlockedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Delete location?`
  String get teamDeleteLocationTitle {
    return Intl.message(
      'Delete location?',
      name: 'teamDeleteLocationTitle',
      desc: '',
      args: [],
    );
  }

  /// `The location will be removed from the team. This action cannot be undone.`
  String get teamDeleteLocationMessage {
    return Intl.message(
      'The location will be removed from the team. This action cannot be undone.',
      name: 'teamDeleteLocationMessage',
      desc: '',
      args: [],
    );
  }

  /// `Delete team member?`
  String get teamDeleteStaffTitle {
    return Intl.message(
      'Delete team member?',
      name: 'teamDeleteStaffTitle',
      desc: '',
      args: [],
    );
  }

  /// `The member will be removed from the team. This action cannot be undone.`
  String get teamDeleteStaffMessage {
    return Intl.message(
      'The member will be removed from the team. This action cannot be undone.',
      name: 'teamDeleteStaffMessage',
      desc: '',
      args: [],
    );
  }

  /// `New location`
  String get teamNewLocationTitle {
    return Intl.message(
      'New location',
      name: 'teamNewLocationTitle',
      desc: '',
      args: [],
    );
  }

  /// `Edit location`
  String get teamEditLocationTitle {
    return Intl.message(
      'Edit location',
      name: 'teamEditLocationTitle',
      desc: '',
      args: [],
    );
  }

  /// `Location name`
  String get teamLocationNameLabel {
    return Intl.message(
      'Location name',
      name: 'teamLocationNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get teamLocationAddressLabel {
    return Intl.message(
      'Address',
      name: 'teamLocationAddressLabel',
      desc: '',
      args: [],
    );
  }

  /// `Country`
  String get teamLocationCountryLabel {
    return Intl.message(
      'Country',
      name: 'teamLocationCountryLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. IT`
  String get teamLocationCountryHint {
    return Intl.message(
      'e.g. IT',
      name: 'teamLocationCountryHint',
      desc: '',
      args: [],
    );
  }

  /// `Italy`
  String get teamLocationCountryItaly {
    return Intl.message(
      'Italy',
      name: 'teamLocationCountryItaly',
      desc: '',
      args: [],
    );
  }

  /// `France`
  String get teamLocationCountryFrance {
    return Intl.message(
      'France',
      name: 'teamLocationCountryFrance',
      desc: '',
      args: [],
    );
  }

  /// `Spain`
  String get teamLocationCountrySpain {
    return Intl.message(
      'Spain',
      name: 'teamLocationCountrySpain',
      desc: '',
      args: [],
    );
  }

  /// `Germany`
  String get teamLocationCountryGermany {
    return Intl.message(
      'Germany',
      name: 'teamLocationCountryGermany',
      desc: '',
      args: [],
    );
  }

  /// `United Kingdom`
  String get teamLocationCountryUnitedKingdom {
    return Intl.message(
      'United Kingdom',
      name: 'teamLocationCountryUnitedKingdom',
      desc: '',
      args: [],
    );
  }

  /// `United States`
  String get teamLocationCountryUnitedStates {
    return Intl.message(
      'United States',
      name: 'teamLocationCountryUnitedStates',
      desc: '',
      args: [],
    );
  }

  /// `Switzerland`
  String get teamLocationCountrySwitzerland {
    return Intl.message(
      'Switzerland',
      name: 'teamLocationCountrySwitzerland',
      desc: '',
      args: [],
    );
  }

  /// `Austria`
  String get teamLocationCountryAustria {
    return Intl.message(
      'Austria',
      name: 'teamLocationCountryAustria',
      desc: '',
      args: [],
    );
  }

  /// `Portugal`
  String get teamLocationCountryPortugal {
    return Intl.message(
      'Portugal',
      name: 'teamLocationCountryPortugal',
      desc: '',
      args: [],
    );
  }

  /// `Netherlands`
  String get teamLocationCountryNetherlands {
    return Intl.message(
      'Netherlands',
      name: 'teamLocationCountryNetherlands',
      desc: '',
      args: [],
    );
  }

  /// `Belgium`
  String get teamLocationCountryBelgium {
    return Intl.message(
      'Belgium',
      name: 'teamLocationCountryBelgium',
      desc: '',
      args: [],
    );
  }

  /// `Timezone`
  String get teamLocationTimezoneLabel {
    return Intl.message(
      'Timezone',
      name: 'teamLocationTimezoneLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. Europe/Rome`
  String get teamLocationTimezoneHint {
    return Intl.message(
      'e.g. Europe/Rome',
      name: 'teamLocationTimezoneHint',
      desc: '',
      args: [],
    );
  }

  /// `Default online booking language`
  String get teamLocationBookingDefaultLocaleLabel {
    return Intl.message(
      'Default online booking language',
      name: 'teamLocationBookingDefaultLocaleLabel',
      desc: '',
      args: [],
    );
  }

  /// `Sets the initial language for the booking frontend. It does not change timezone or admin app language.`
  String get teamLocationBookingDefaultLocaleHint {
    return Intl.message(
      'Sets the initial language for the booking frontend. It does not change timezone or admin app language.',
      name: 'teamLocationBookingDefaultLocaleHint',
      desc: '',
      args: [],
    );
  }

  /// `Automatic`
  String get teamLocationBookingDefaultLocaleAuto {
    return Intl.message(
      'Automatic',
      name: 'teamLocationBookingDefaultLocaleAuto',
      desc: '',
      args: [],
    );
  }

  /// `Italian`
  String get teamLocationBookingDefaultLocaleItalian {
    return Intl.message(
      'Italian',
      name: 'teamLocationBookingDefaultLocaleItalian',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get teamLocationBookingDefaultLocaleEnglish {
    return Intl.message(
      'English',
      name: 'teamLocationBookingDefaultLocaleEnglish',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get teamLocationEmailLabel {
    return Intl.message(
      'Email',
      name: 'teamLocationEmailLabel',
      desc: '',
      args: [],
    );
  }

  /// `Email for customer notifications`
  String get teamLocationEmailHint {
    return Intl.message(
      'Email for customer notifications',
      name: 'teamLocationEmailHint',
      desc: '',
      args: [],
    );
  }

  /// `Online booking configuration for this location`
  String get teamLocationOnlineBookingSettingsSection {
    return Intl.message(
      'Online booking configuration for this location',
      name: 'teamLocationOnlineBookingSettingsSection',
      desc: '',
      args: [],
    );
  }

  /// `Online booking nomenclature`
  String get teamLocationNomenclatureSection {
    return Intl.message(
      'Online booking nomenclature',
      name: 'teamLocationNomenclatureSection',
      desc: '',
      args: [],
    );
  }

  /// `Add only the labels you want to override. They will apply to all users.`
  String get teamLocationNomenclatureEditorIntro {
    return Intl.message(
      'Add only the labels you want to override. They will apply to all users.',
      name: 'teamLocationNomenclatureEditorIntro',
      desc: '',
      args: [],
    );
  }

  /// `Service provider selection icon`
  String get teamLocationStaffIconKeyLabel {
    return Intl.message(
      'Service provider selection icon',
      name: 'teamLocationStaffIconKeyLabel',
      desc: '',
      args: [],
    );
  }

  /// `Icon shown in online booking for service provider selection`
  String get teamLocationStaffIconKeyHint {
    return Intl.message(
      'Icon shown in online booking for service provider selection',
      name: 'teamLocationStaffIconKeyHint',
      desc: '',
      args: [],
    );
  }

  /// `Enter custom text (optional)`
  String get teamLocationNomenclatureInputHint {
    return Intl.message(
      'Enter custom text (optional)',
      name: 'teamLocationNomenclatureInputHint',
      desc: '',
      args: [],
    );
  }

  /// `Default: {value}.`
  String teamLocationNomenclatureDefaultValue(String value) {
    return Intl.message(
      'Default: $value.',
      name: 'teamLocationNomenclatureDefaultValue',
      desc: '',
      args: [value],
    );
  }

  /// `Leave empty to keep default.`
  String get teamLocationNomenclatureLeaveEmptyHint {
    return Intl.message(
      'Leave empty to keep default.',
      name: 'teamLocationNomenclatureLeaveEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `It must include "{count}".`
  String teamLocationNomenclatureCountPlaceholderNote(Object count) {
    return Intl.message(
      'It must include "$count".',
      name: 'teamLocationNomenclatureCountPlaceholderNote',
      desc: '',
      args: [count],
    );
  }

  /// `Key`
  String get teamLocationNomenclatureKeyLabel {
    return Intl.message(
      'Key',
      name: 'teamLocationNomenclatureKeyLabel',
      desc: '',
      args: [],
    );
  }

  /// `Custom text`
  String get teamLocationNomenclatureValueLabel {
    return Intl.message(
      'Custom text',
      name: 'teamLocationNomenclatureValueLabel',
      desc: '',
      args: [],
    );
  }

  /// `Add label`
  String get teamLocationNomenclatureAddRow {
    return Intl.message(
      'Add label',
      name: 'teamLocationNomenclatureAddRow',
      desc: '',
      args: [],
    );
  }

  /// `The same key has been entered more than once.`
  String get teamLocationNomenclatureDuplicateKey {
    return Intl.message(
      'The same key has been entered more than once.',
      name: 'teamLocationNomenclatureDuplicateKey',
      desc: '',
      args: [],
    );
  }

  /// `For "services_selected_many" you must include the count placeholder.`
  String get teamLocationNomenclatureCountPlaceholderError {
    return Intl.message(
      'For "services_selected_many" you must include the count placeholder.',
      name: 'teamLocationNomenclatureCountPlaceholderError',
      desc: '',
      args: [],
    );
  }

  /// `Nomenclature JSON`
  String get teamLocationBookingTextOverridesLabel {
    return Intl.message(
      'Nomenclature JSON',
      name: 'teamLocationBookingTextOverridesLabel',
      desc: '',
      args: [],
    );
  }

  /// `{"default":{"services_title":"Choose activities"}}`
  String get teamLocationBookingTextOverridesHint {
    return Intl.message(
      '{"default":{"services_title":"Choose activities"}}',
      name: 'teamLocationBookingTextOverridesHint',
      desc: '',
      args: [],
    );
  }

  /// `Single block only: required key "default".`
  String get teamLocationBookingTextOverridesHelper {
    return Intl.message(
      'Single block only: required key "default".',
      name: 'teamLocationBookingTextOverridesHelper',
      desc: '',
      args: [],
    );
  }

  /// `Invalid JSON. Provide an object with non-empty phrases.`
  String get teamLocationBookingTextOverridesInvalid {
    return Intl.message(
      'Invalid JSON. Provide an object with non-empty phrases.',
      name: 'teamLocationBookingTextOverridesInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Only the "default" block is allowed.`
  String get teamLocationBookingTextOverridesDefaultOnly {
    return Intl.message(
      'Only the "default" block is allowed.',
      name: 'teamLocationBookingTextOverridesDefaultOnly',
      desc: '',
      args: [],
    );
  }

  /// `Team label`
  String get teamLocationStaffDisplayLabel {
    return Intl.message(
      'Team label',
      name: 'teamLocationStaffDisplayLabel',
      desc: '',
      args: [],
    );
  }

  /// `E.g. Team member, Resource, Specialist`
  String get teamLocationStaffDisplayHint {
    return Intl.message(
      'E.g. Team member, Resource, Specialist',
      name: 'teamLocationStaffDisplayHint',
      desc: '',
      args: [],
    );
  }

  /// `Service label`
  String get teamLocationServiceDisplayLabel {
    return Intl.message(
      'Service label',
      name: 'teamLocationServiceDisplayLabel',
      desc: '',
      args: [],
    );
  }

  /// `E.g. Service, Treatment, Session`
  String get teamLocationServiceDisplayHint {
    return Intl.message(
      'E.g. Service, Treatment, Session',
      name: 'teamLocationServiceDisplayHint',
      desc: '',
      args: [],
    );
  }

  /// `Location label`
  String get teamLocationLocationDisplayLabel {
    return Intl.message(
      'Location label',
      name: 'teamLocationLocationDisplayLabel',
      desc: '',
      args: [],
    );
  }

  /// `E.g. Location, Place, Room`
  String get teamLocationLocationDisplayHint {
    return Intl.message(
      'E.g. Location, Place, Room',
      name: 'teamLocationLocationDisplayHint',
      desc: '',
      args: [],
    );
  }

  /// `Location active`
  String get teamLocationIsActiveLabel {
    return Intl.message(
      'Location active',
      name: 'teamLocationIsActiveLabel',
      desc: '',
      args: [],
    );
  }

  /// `If disabled, the location will not be visible to customers`
  String get teamLocationIsActiveHint {
    return Intl.message(
      'If disabled, the location will not be visible to customers',
      name: 'teamLocationIsActiveHint',
      desc: '',
      args: [],
    );
  }

  /// `Online booking limits`
  String get teamLocationBookingLimitsSection {
    return Intl.message(
      'Online booking limits',
      name: 'teamLocationBookingLimitsSection',
      desc: '',
      args: [],
    );
  }

  /// `Allow customers to choose the service provider`
  String get teamLocationAllowCustomerChooseStaffLabel {
    return Intl.message(
      'Allow customers to choose the service provider',
      name: 'teamLocationAllowCustomerChooseStaffLabel',
      desc: '',
      args: [],
    );
  }

  /// `If disabled, the system assigns the service provider automatically`
  String get teamLocationAllowCustomerChooseStaffHint {
    return Intl.message(
      'If disabled, the system assigns the service provider automatically',
      name: 'teamLocationAllowCustomerChooseStaffHint',
      desc: '',
      args: [],
    );
  }

  /// `Minimum booking notice`
  String get teamLocationMinBookingNoticeLabel {
    return Intl.message(
      'Minimum booking notice',
      name: 'teamLocationMinBookingNoticeLabel',
      desc: '',
      args: [],
    );
  }

  /// `How far in advance customers must book`
  String get teamLocationMinBookingNoticeHint {
    return Intl.message(
      'How far in advance customers must book',
      name: 'teamLocationMinBookingNoticeHint',
      desc: '',
      args: [],
    );
  }

  /// `Maximum booking advance`
  String get teamLocationMaxBookingAdvanceLabel {
    return Intl.message(
      'Maximum booking advance',
      name: 'teamLocationMaxBookingAdvanceLabel',
      desc: '',
      args: [],
    );
  }

  /// `How far ahead customers can book`
  String get teamLocationMaxBookingAdvanceHint {
    return Intl.message(
      'How far ahead customers can book',
      name: 'teamLocationMaxBookingAdvanceHint',
      desc: '',
      args: [],
    );
  }

  /// `Modify/cancel window`
  String get teamLocationCancellationHoursLabel {
    return Intl.message(
      'Modify/cancel window',
      name: 'teamLocationCancellationHoursLabel',
      desc: '',
      args: [],
    );
  }

  /// `Minimum time before the appointment during which customers can still modify or cancel`
  String get teamLocationCancellationHoursHint {
    return Intl.message(
      'Minimum time before the appointment during which customers can still modify or cancel',
      name: 'teamLocationCancellationHoursHint',
      desc: '',
      args: [],
    );
  }

  /// `Use business policy`
  String get teamLocationCancellationHoursUseBusiness {
    return Intl.message(
      'Use business policy',
      name: 'teamLocationCancellationHoursUseBusiness',
      desc: '',
      args: [],
    );
  }

  /// `Use business policy ({value})`
  String teamLocationCancellationHoursUseBusinessWithValue(String value) {
    return Intl.message(
      'Use business policy ($value)',
      name: 'teamLocationCancellationHoursUseBusinessWithValue',
      desc: '',
      args: [value],
    );
  }

  /// `Always`
  String get teamLocationCancellationHoursAlways {
    return Intl.message(
      'Always',
      name: 'teamLocationCancellationHoursAlways',
      desc: '',
      args: [],
    );
  }

  /// `Never`
  String get teamLocationCancellationHoursNever {
    return Intl.message(
      'Never',
      name: 'teamLocationCancellationHoursNever',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 hour} other{{count} hours}}`
  String teamLocationHours(int count) {
    return Intl.plural(
      count,
      one: '1 hour',
      other: '$count hours',
      name: 'teamLocationHours',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 day} other{{count} days}}`
  String teamLocationDays(int count) {
    return Intl.plural(
      count,
      one: '1 day',
      other: '$count days',
      name: 'teamLocationDays',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 minute} other{{count} minutes}}`
  String teamLocationMinutes(int count) {
    return Intl.plural(
      count,
      one: '1 minute',
      other: '$count minutes',
      name: 'teamLocationMinutes',
      desc: '',
      args: [count],
    );
  }

  /// `Smart time slots`
  String get teamLocationSmartSlotSection {
    return Intl.message(
      'Smart time slots',
      name: 'teamLocationSmartSlotSection',
      desc: '',
      args: [],
    );
  }

  /// `Configure how available times are shown to customers booking online. This does not change staff planning.`
  String get teamLocationSmartSlotDescription {
    return Intl.message(
      'Configure how available times are shown to customers booking online. This does not change staff planning.',
      name: 'teamLocationSmartSlotDescription',
      desc: '',
      args: [],
    );
  }

  /// `Time slot interval`
  String get teamLocationSlotIntervalLabel {
    return Intl.message(
      'Time slot interval',
      name: 'teamLocationSlotIntervalLabel',
      desc: '',
      args: [],
    );
  }

  /// `How many minutes between each available slot in online booking (does not affect staff planning slots)`
  String get teamLocationSlotIntervalHint {
    return Intl.message(
      'How many minutes between each available slot in online booking (does not affect staff planning slots)',
      name: 'teamLocationSlotIntervalHint',
      desc: '',
      args: [],
    );
  }

  /// `Display mode`
  String get teamLocationSlotDisplayModeLabel {
    return Intl.message(
      'Display mode',
      name: 'teamLocationSlotDisplayModeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Maximum availability`
  String get teamLocationSlotDisplayModeAll {
    return Intl.message(
      'Maximum availability',
      name: 'teamLocationSlotDisplayModeAll',
      desc: '',
      args: [],
    );
  }

  /// `Reduce empty gaps`
  String get teamLocationSlotDisplayModeMinGap {
    return Intl.message(
      'Reduce empty gaps',
      name: 'teamLocationSlotDisplayModeMinGap',
      desc: '',
      args: [],
    );
  }

  /// `Show all available time slots`
  String get teamLocationSlotDisplayModeAllHint {
    return Intl.message(
      'Show all available time slots',
      name: 'teamLocationSlotDisplayModeAllHint',
      desc: '',
      args: [],
    );
  }

  /// `Hide slots that would create gaps too small to fill`
  String get teamLocationSlotDisplayModeMinGapHint {
    return Intl.message(
      'Hide slots that would create gaps too small to fill',
      name: 'teamLocationSlotDisplayModeMinGapHint',
      desc: '',
      args: [],
    );
  }

  /// `Minimum acceptable gap`
  String get teamLocationMinGapLabel {
    return Intl.message(
      'Minimum acceptable gap',
      name: 'teamLocationMinGapLabel',
      desc: '',
      args: [],
    );
  }

  /// `Hide time slots that leave less than this time free`
  String get teamLocationMinGapHint {
    return Intl.message(
      'Hide time slots that leave less than this time free',
      name: 'teamLocationMinGapHint',
      desc: '',
      args: [],
    );
  }

  /// `New team member`
  String get teamNewStaffTitle {
    return Intl.message(
      'New team member',
      name: 'teamNewStaffTitle',
      desc: '',
      args: [],
    );
  }

  /// `Edit team member`
  String get teamEditStaffTitle {
    return Intl.message(
      'Edit team member',
      name: 'teamEditStaffTitle',
      desc: '',
      args: [],
    );
  }

  /// `First name`
  String get teamStaffNameLabel {
    return Intl.message(
      'First name',
      name: 'teamStaffNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Last name`
  String get teamStaffSurnameLabel {
    return Intl.message(
      'Last name',
      name: 'teamStaffSurnameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Color`
  String get teamStaffColorLabel {
    return Intl.message(
      'Color',
      name: 'teamStaffColorLabel',
      desc: '',
      args: [],
    );
  }

  /// `Assigned locations`
  String get teamStaffLocationsLabel {
    return Intl.message(
      'Assigned locations',
      name: 'teamStaffLocationsLabel',
      desc: '',
      args: [],
    );
  }

  /// `If the member works across multiple locations, make sure availability aligns with the selected locations.`
  String get teamStaffMultiLocationWarning {
    return Intl.message(
      'If the member works across multiple locations, make sure availability aligns with the selected locations.',
      name: 'teamStaffMultiLocationWarning',
      desc: '',
      args: [],
    );
  }

  /// `Eligible team members`
  String get teamEligibleStaffLabel {
    return Intl.message(
      'Eligible team members',
      name: 'teamEligibleStaffLabel',
      desc: '',
      args: [],
    );
  }

  /// `Eligible services`
  String get teamEligibleServicesLabel {
    return Intl.message(
      'Eligible services',
      name: 'teamEligibleServicesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select all`
  String get teamSelectAllServices {
    return Intl.message(
      'Select all',
      name: 'teamSelectAllServices',
      desc: '',
      args: [],
    );
  }

  /// `{count} eligible services`
  String teamEligibleServicesCount(int count) {
    return Intl.message(
      '$count eligible services',
      name: 'teamEligibleServicesCount',
      desc: '',
      args: [count],
    );
  }

  /// `No eligible services`
  String get teamEligibleServicesNone {
    return Intl.message(
      'No eligible services',
      name: 'teamEligibleServicesNone',
      desc: '',
      args: [],
    );
  }

  /// `Selected services`
  String get teamSelectedServicesButton {
    return Intl.message(
      'Selected services',
      name: 'teamSelectedServicesButton',
      desc: '',
      args: [],
    );
  }

  /// `{selected} of {total}`
  String teamSelectedServicesCount(int selected, int total) {
    return Intl.message(
      '$selected of $total',
      name: 'teamSelectedServicesCount',
      desc: '',
      args: [selected, total],
    );
  }

  /// `Services`
  String get teamServicesLabel {
    return Intl.message(
      'Services',
      name: 'teamServicesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select locations`
  String get teamChooseLocationsButton {
    return Intl.message(
      'Select locations',
      name: 'teamChooseLocationsButton',
      desc: '',
      args: [],
    );
  }

  /// `Select location`
  String get teamChooseLocationSingleButton {
    return Intl.message(
      'Select location',
      name: 'teamChooseLocationSingleButton',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get teamLocationLabel {
    return Intl.message(
      'Location',
      name: 'teamLocationLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select all`
  String get teamSelectAllLocations {
    return Intl.message(
      'Select all',
      name: 'teamSelectAllLocations',
      desc: '',
      args: [],
    );
  }

  /// `Enabled for online bookings`
  String get teamStaffBookableOnlineLabel {
    return Intl.message(
      'Enabled for online bookings',
      name: 'teamStaffBookableOnlineLabel',
      desc: '',
      args: [],
    );
  }

  /// `Not bookable online`
  String get staffNotBookableOnlineTooltip {
    return Intl.message(
      'Not bookable online',
      name: 'staffNotBookableOnlineTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Not bookable online`
  String get staffNotBookableOnlineTitle {
    return Intl.message(
      'Not bookable online',
      name: 'staffNotBookableOnlineTitle',
      desc: '',
      args: [],
    );
  }

  /// `This team member is not enabled for online bookings. You can change this in the staff edit form.`
  String get staffNotBookableOnlineMessage {
    return Intl.message(
      'This team member is not enabled for online bookings. You can change this in the staff edit form.',
      name: 'staffNotBookableOnlineMessage',
      desc: '',
      args: [],
    );
  }

  /// `{count} eligible team members`
  String serviceEligibleStaffCount(int count) {
    return Intl.message(
      '$count eligible team members',
      name: 'serviceEligibleStaffCount',
      desc: '',
      args: [count],
    );
  }

  /// `No eligible team members`
  String get serviceEligibleStaffNone {
    return Intl.message(
      'No eligible team members',
      name: 'serviceEligibleStaffNone',
      desc: '',
      args: [],
    );
  }

  /// `Available locations`
  String get serviceLocationsLabel {
    return Intl.message(
      'Available locations',
      name: 'serviceLocationsLabel',
      desc: '',
      args: [],
    );
  }

  /// `{count} of {total} locations`
  String serviceLocationsCount(int count, int total) {
    return Intl.message(
      '$count of $total locations',
      name: 'serviceLocationsCount',
      desc: '',
      args: [count, total],
    );
  }

  /// `Reorder locations and team members by dragging them. Select whether to sort locations or team. The order will also apply in the agenda section.`
  String get teamReorderHelpDescription {
    return Intl.message(
      'Reorder locations and team members by dragging them. Select whether to sort locations or team. The order will also apply in the agenda section.',
      name: 'teamReorderHelpDescription',
      desc: '',
      args: [],
    );
  }

  /// `New category`
  String get createCategoryButtonLabel {
    return Intl.message(
      'New category',
      name: 'createCategoryButtonLabel',
      desc: '',
      args: [],
    );
  }

  /// `New service`
  String get servicesNewServiceMenu {
    return Intl.message(
      'New service',
      name: 'servicesNewServiceMenu',
      desc: '',
      args: [],
    );
  }

  /// `Reorder`
  String get reorderTitle {
    return Intl.message('Reorder', name: 'reorderTitle', desc: '', args: []);
  }

  /// `Add service`
  String get addServiceTooltip {
    return Intl.message(
      'Add service',
      name: 'addServiceTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Cannot delete`
  String get cannotDeleteTitle {
    return Intl.message(
      'Cannot delete',
      name: 'cannotDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `This category contains one or more services.`
  String get cannotDeleteCategoryContent {
    return Intl.message(
      'This category contains one or more services.',
      name: 'cannotDeleteCategoryContent',
      desc: '',
      args: [],
    );
  }

  /// `No services in this category`
  String get noServicesInCategory {
    return Intl.message(
      'No services in this category',
      name: 'noServicesInCategory',
      desc: '',
      args: [],
    );
  }

  /// `Not bookable online`
  String get notBookableOnline {
    return Intl.message(
      'Not bookable online',
      name: 'notBookableOnline',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate`
  String get duplicateAction {
    return Intl.message(
      'Duplicate',
      name: 'duplicateAction',
      desc: '',
      args: [],
    );
  }

  /// `Delete this service?`
  String get deleteServiceQuestion {
    return Intl.message(
      'Delete this service?',
      name: 'deleteServiceQuestion',
      desc: '',
      args: [],
    );
  }

  /// `This action cannot be undone.`
  String get cannotUndoWarning {
    return Intl.message(
      'This action cannot be undone.',
      name: 'cannotUndoWarning',
      desc: '',
      args: [],
    );
  }

  /// `New category`
  String get newCategoryTitle {
    return Intl.message(
      'New category',
      name: 'newCategoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Edit category`
  String get editCategoryTitle {
    return Intl.message(
      'Edit category',
      name: 'editCategoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Name *`
  String get fieldNameRequiredLabel {
    return Intl.message(
      'Name *',
      name: 'fieldNameRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Name is required`
  String get fieldNameRequiredError {
    return Intl.message(
      'Name is required',
      name: 'fieldNameRequiredError',
      desc: '',
      args: [],
    );
  }

  /// `A category with this name already exists`
  String get categoryDuplicateError {
    return Intl.message(
      'A category with this name already exists',
      name: 'categoryDuplicateError',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get fieldDescriptionLabel {
    return Intl.message(
      'Description',
      name: 'fieldDescriptionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Service color`
  String get serviceColorLabel {
    return Intl.message(
      'Service color',
      name: 'serviceColorLabel',
      desc: '',
      args: [],
    );
  }

  /// `New service`
  String get newServiceTitle {
    return Intl.message(
      'New service',
      name: 'newServiceTitle',
      desc: '',
      args: [],
    );
  }

  /// `Edit service`
  String get editServiceTitle {
    return Intl.message(
      'Edit service',
      name: 'editServiceTitle',
      desc: '',
      args: [],
    );
  }

  /// `Category *`
  String get fieldCategoryRequiredLabel {
    return Intl.message(
      'Category *',
      name: 'fieldCategoryRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Duration *`
  String get fieldDurationRequiredLabel {
    return Intl.message(
      'Duration *',
      name: 'fieldDurationRequiredLabel',
      desc: '',
      args: [],
    );
  }

  /// `Please select a duration`
  String get fieldDurationRequiredError {
    return Intl.message(
      'Please select a duration',
      name: 'fieldDurationRequiredError',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get fieldPriceLabel {
    return Intl.message('Price', name: 'fieldPriceLabel', desc: '', args: []);
  }

  /// `Processing time`
  String get fieldProcessingTimeLabel {
    return Intl.message(
      'Processing time',
      name: 'fieldProcessingTimeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Blocked time`
  String get fieldBlockedTimeLabel {
    return Intl.message(
      'Blocked time',
      name: 'fieldBlockedTimeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Additional time`
  String get additionalTimeSwitch {
    return Intl.message(
      'Additional time',
      name: 'additionalTimeSwitch',
      desc: '',
      args: [],
    );
  }

  /// `Processing time`
  String get additionalTimeOptionProcessing {
    return Intl.message(
      'Processing time',
      name: 'additionalTimeOptionProcessing',
      desc: '',
      args: [],
    );
  }

  /// `Blocked time`
  String get additionalTimeOptionBlocked {
    return Intl.message(
      'Blocked time',
      name: 'additionalTimeOptionBlocked',
      desc: '',
      args: [],
    );
  }

  /// `Bookable online`
  String get bookableOnlineSwitch {
    return Intl.message(
      'Bookable online',
      name: 'bookableOnlineSwitch',
      desc: '',
      args: [],
    );
  }

  /// `Free service`
  String get freeServiceSwitch {
    return Intl.message(
      'Free service',
      name: 'freeServiceSwitch',
      desc: '',
      args: [],
    );
  }

  /// `Price “starting from”`
  String get priceStartingFromSwitch {
    return Intl.message(
      'Price “starting from”',
      name: 'priceStartingFromSwitch',
      desc: '',
      args: [],
    );
  }

  /// `Set a price to enable this option`
  String get setPriceToEnable {
    return Intl.message(
      'Set a price to enable this option',
      name: 'setPriceToEnable',
      desc: '',
      args: [],
    );
  }

  /// `A service with this name already exists`
  String get serviceDuplicateError {
    return Intl.message(
      'A service with this name already exists',
      name: 'serviceDuplicateError',
      desc: '',
      args: [],
    );
  }

  /// `Reorder categories and services by dragging them: the same order will be applied to online booking. Select whether to sort categories or services.`
  String get reorderHelpDescription {
    return Intl.message(
      'Reorder categories and services by dragging them: the same order will be applied to online booking. Select whether to sort categories or services.',
      name: 'reorderHelpDescription',
      desc: '',
      args: [],
    );
  }

  /// `Categories`
  String get reorderCategoriesLabel {
    return Intl.message(
      'Categories',
      name: 'reorderCategoriesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Services`
  String get reorderServicesLabel {
    return Intl.message(
      'Services',
      name: 'reorderServicesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Categories without services cannot be reordered and stay at the end.`
  String get emptyCategoriesNotReorderableNote {
    return Intl.message(
      'Categories without services cannot be reordered and stay at the end.',
      name: 'emptyCategoriesNotReorderableNote',
      desc: '',
      args: [],
    );
  }

  /// `Body Treatments`
  String get serviceSeedCategoryBodyName {
    return Intl.message(
      'Body Treatments',
      name: 'serviceSeedCategoryBodyName',
      desc: '',
      args: [],
    );
  }

  /// `Services dedicated to body wellness`
  String get serviceSeedCategoryBodyDescription {
    return Intl.message(
      'Services dedicated to body wellness',
      name: 'serviceSeedCategoryBodyDescription',
      desc: '',
      args: [],
    );
  }

  /// `Sports Treatments`
  String get serviceSeedCategorySportsName {
    return Intl.message(
      'Sports Treatments',
      name: 'serviceSeedCategorySportsName',
      desc: '',
      args: [],
    );
  }

  /// `Programs designed for athletes and active people`
  String get serviceSeedCategorySportsDescription {
    return Intl.message(
      'Programs designed for athletes and active people',
      name: 'serviceSeedCategorySportsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Facial Treatments`
  String get serviceSeedCategoryFaceName {
    return Intl.message(
      'Facial Treatments',
      name: 'serviceSeedCategoryFaceName',
      desc: '',
      args: [],
    );
  }

  /// `Aesthetic and rejuvenating care for the face`
  String get serviceSeedCategoryFaceDescription {
    return Intl.message(
      'Aesthetic and rejuvenating care for the face',
      name: 'serviceSeedCategoryFaceDescription',
      desc: '',
      args: [],
    );
  }

  /// `Relax Massage`
  String get serviceSeedServiceRelaxName {
    return Intl.message(
      'Relax Massage',
      name: 'serviceSeedServiceRelaxName',
      desc: '',
      args: [],
    );
  }

  /// `Relaxing 30-minute treatment`
  String get serviceSeedServiceRelaxDescription {
    return Intl.message(
      'Relaxing 30-minute treatment',
      name: 'serviceSeedServiceRelaxDescription',
      desc: '',
      args: [],
    );
  }

  /// `Sports Massage`
  String get serviceSeedServiceSportName {
    return Intl.message(
      'Sports Massage',
      name: 'serviceSeedServiceSportName',
      desc: '',
      args: [],
    );
  }

  /// `Intensive decontracting treatment`
  String get serviceSeedServiceSportDescription {
    return Intl.message(
      'Intensive decontracting treatment',
      name: 'serviceSeedServiceSportDescription',
      desc: '',
      args: [],
    );
  }

  /// `Facial Treatment`
  String get serviceSeedServiceFaceName {
    return Intl.message(
      'Facial Treatment',
      name: 'serviceSeedServiceFaceName',
      desc: '',
      args: [],
    );
  }

  /// `Cleansing and illuminating treatment`
  String get serviceSeedServiceFaceDescription {
    return Intl.message(
      'Cleansing and illuminating treatment',
      name: 'serviceSeedServiceFaceDescription',
      desc: '',
      args: [],
    );
  }

  /// `Copy`
  String get serviceDuplicateCopyWord {
    return Intl.message(
      'Copy',
      name: 'serviceDuplicateCopyWord',
      desc: '',
      args: [],
    );
  }

  /// `Confirm move?`
  String get moveAppointmentConfirmTitle {
    return Intl.message(
      'Confirm move?',
      name: 'moveAppointmentConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Send notification to client?`
  String get rescheduleNotifyDecisionTitle {
    return Intl.message(
      'Send notification to client?',
      name: 'rescheduleNotifyDecisionTitle',
      desc: '',
      args: [],
    );
  }

  /// `The booking start time changed. Do you want to send a client notification? Unsent reminders will be adjusted automatically.`
  String get rescheduleNotifyDecisionMessage {
    return Intl.message(
      'The booking start time changed. Do you want to send a client notification? Unsent reminders will be adjusted automatically.',
      name: 'rescheduleNotifyDecisionMessage',
      desc: '',
      args: [],
    );
  }

  /// `Send notification`
  String get rescheduleNotifyDecisionSend {
    return Intl.message(
      'Send notification',
      name: 'rescheduleNotifyDecisionSend',
      desc: '',
      args: [],
    );
  }

  /// `Do not send`
  String get rescheduleNotifyDecisionSkip {
    return Intl.message(
      'Do not send',
      name: 'rescheduleNotifyDecisionSkip',
      desc: '',
      args: [],
    );
  }

  /// `Send client notification and adjust unsent reminders`
  String get moveConfirmNotifyCheckbox {
    return Intl.message(
      'Send client notification and adjust unsent reminders',
      name: 'moveConfirmNotifyCheckbox',
      desc: '',
      args: [],
    );
  }

  /// `Multi-service booking`
  String get multiServiceMoveDecisionTitle {
    return Intl.message(
      'Multi-service booking',
      name: 'multiServiceMoveDecisionTitle',
      desc: '',
      args: [],
    );
  }

  /// `This booking contains multiple services. Choose how to proceed.`
  String get multiServiceMoveDecisionMessage {
    return Intl.message(
      'This booking contains multiple services. Choose how to proceed.',
      name: 'multiServiceMoveDecisionMessage',
      desc: '',
      args: [],
    );
  }

  /// `Move entire booking`
  String get multiServiceMoveDecisionMoveBooking {
    return Intl.message(
      'Move entire booking',
      name: 'multiServiceMoveDecisionMoveBooking',
      desc: '',
      args: [],
    );
  }

  /// `Move only this service`
  String get multiServiceMoveDecisionSplitService {
    return Intl.message(
      'Move only this service',
      name: 'multiServiceMoveDecisionSplitService',
      desc: '',
      args: [],
    );
  }

  /// `Move not available`
  String get multiServiceMoveSplitUnavailableTitle {
    return Intl.message(
      'Move not available',
      name: 'multiServiceMoveSplitUnavailableTitle',
      desc: '',
      args: [],
    );
  }

  /// `Moving a single service requires an atomic split not available in the current API. Use "Move entire booking".`
  String get multiServiceMoveSplitUnavailableMessage {
    return Intl.message(
      'Moving a single service requires an atomic split not available in the current API. Use "Move entire booking".',
      name: 'multiServiceMoveSplitUnavailableMessage',
      desc: '',
      args: [],
    );
  }

  /// `Move blocked`
  String get multiServiceNonFirstMoveBlockedTitle {
    return Intl.message(
      'Move blocked',
      name: 'multiServiceNonFirstMoveBlockedTitle',
      desc: '',
      args: [],
    );
  }

  /// `For multi-service bookings, only the first service can be moved.`
  String get multiServiceNonFirstMoveBlockedMessage {
    return Intl.message(
      'For multi-service bookings, only the first service can be moved.',
      name: 'multiServiceNonFirstMoveBlockedMessage',
      desc: '',
      args: [],
    );
  }

  /// `The appointment will be moved to {newTime} for {staffName}.`
  String moveAppointmentConfirmMessage(String newTime, String staffName) {
    return Intl.message(
      'The appointment will be moved to $newTime for $staffName.',
      name: 'moveAppointmentConfirmMessage',
      desc: '',
      args: [newTime, staffName],
    );
  }

  /// `Unsaved changes`
  String get discardChangesTitle {
    return Intl.message(
      'Unsaved changes',
      name: 'discardChangesTitle',
      desc: '',
      args: [],
    );
  }

  /// `You have unsaved changes. Do you want to discard them?`
  String get discardChangesMessage {
    return Intl.message(
      'You have unsaved changes. Do you want to discard them?',
      name: 'discardChangesMessage',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get actionDiscard {
    return Intl.message('Cancel', name: 'actionDiscard', desc: '', args: []);
  }

  /// `Keep editing`
  String get actionKeepEditing {
    return Intl.message(
      'Keep editing',
      name: 'actionKeepEditing',
      desc: '',
      args: [],
    );
  }

  /// `Delete client?`
  String get deleteClientConfirmTitle {
    return Intl.message(
      'Delete client?',
      name: 'deleteClientConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `The client will be permanently deleted. This action cannot be undone.`
  String get deleteClientConfirmMessage {
    return Intl.message(
      'The client will be permanently deleted. This action cannot be undone.',
      name: 'deleteClientConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Name (A-Z)`
  String get sortByNameAsc {
    return Intl.message(
      'Name (A-Z)',
      name: 'sortByNameAsc',
      desc: '',
      args: [],
    );
  }

  /// `Name (Z-A)`
  String get sortByNameDesc {
    return Intl.message(
      'Name (Z-A)',
      name: 'sortByNameDesc',
      desc: '',
      args: [],
    );
  }

  /// `Last name (A-Z)`
  String get sortByLastNameAsc {
    return Intl.message(
      'Last name (A-Z)',
      name: 'sortByLastNameAsc',
      desc: '',
      args: [],
    );
  }

  /// `Last name (Z-A)`
  String get sortByLastNameDesc {
    return Intl.message(
      'Last name (Z-A)',
      name: 'sortByLastNameDesc',
      desc: '',
      args: [],
    );
  }

  /// `Created (newest)`
  String get sortByCreatedAtDesc {
    return Intl.message(
      'Created (newest)',
      name: 'sortByCreatedAtDesc',
      desc: '',
      args: [],
    );
  }

  /// `Created (oldest)`
  String get sortByCreatedAtAsc {
    return Intl.message(
      'Created (oldest)',
      name: 'sortByCreatedAtAsc',
      desc: '',
      args: [],
    );
  }

  /// `{clientName}'s appointments`
  String clientAppointmentsTitle(String clientName) {
    return Intl.message(
      '$clientName\'s appointments',
      name: 'clientAppointmentsTitle',
      desc: '',
      args: [clientName],
    );
  }

  /// `Upcoming`
  String get clientAppointmentsUpcoming {
    return Intl.message(
      'Upcoming',
      name: 'clientAppointmentsUpcoming',
      desc: '',
      args: [],
    );
  }

  /// `Past`
  String get clientAppointmentsPast {
    return Intl.message(
      'Past',
      name: 'clientAppointmentsPast',
      desc: '',
      args: [],
    );
  }

  /// `No appointments`
  String get clientAppointmentsEmpty {
    return Intl.message(
      'No appointments',
      name: 'clientAppointmentsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Filter team`
  String get staffFilterTooltip {
    return Intl.message(
      'Filter team',
      name: 'staffFilterTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Filter team`
  String get staffFilterTitle {
    return Intl.message(
      'Filter team',
      name: 'staffFilterTitle',
      desc: '',
      args: [],
    );
  }

  /// `All team`
  String get staffFilterAllTeam {
    return Intl.message(
      'All team',
      name: 'staffFilterAllTeam',
      desc: '',
      args: [],
    );
  }

  /// `On duty team`
  String get staffFilterOnDuty {
    return Intl.message(
      'On duty team',
      name: 'staffFilterOnDuty',
      desc: '',
      args: [],
    );
  }

  /// `No team members on duty today`
  String get agendaNoOnDutyTeamTitle {
    return Intl.message(
      'No team members on duty today',
      name: 'agendaNoOnDutyTeamTitle',
      desc: '',
      args: [],
    );
  }

  /// `No selected team members`
  String get agendaNoSelectedTeamTitle {
    return Intl.message(
      'No selected team members',
      name: 'agendaNoSelectedTeamTitle',
      desc: '',
      args: [],
    );
  }

  /// `View all team`
  String get agendaShowAllTeamButton {
    return Intl.message(
      'View all team',
      name: 'agendaShowAllTeamButton',
      desc: '',
      args: [],
    );
  }

  /// `Select team members`
  String get staffFilterSelectMembers {
    return Intl.message(
      'Select team members',
      name: 'staffFilterSelectMembers',
      desc: '',
      args: [],
    );
  }

  /// `New block`
  String get blockDialogTitleNew {
    return Intl.message(
      'New block',
      name: 'blockDialogTitleNew',
      desc: '',
      args: [],
    );
  }

  /// `Edit block`
  String get blockDialogTitleEdit {
    return Intl.message(
      'Edit block',
      name: 'blockDialogTitleEdit',
      desc: '',
      args: [],
    );
  }

  /// `All day`
  String get blockAllDay {
    return Intl.message('All day', name: 'blockAllDay', desc: '', args: []);
  }

  /// `Start time`
  String get blockStartTime {
    return Intl.message(
      'Start time',
      name: 'blockStartTime',
      desc: '',
      args: [],
    );
  }

  /// `End time`
  String get blockEndTime {
    return Intl.message('End time', name: 'blockEndTime', desc: '', args: []);
  }

  /// `Select team`
  String get blockSelectStaff {
    return Intl.message(
      'Select team',
      name: 'blockSelectStaff',
      desc: '',
      args: [],
    );
  }

  /// `Select at least one team member`
  String get blockSelectStaffError {
    return Intl.message(
      'Select at least one team member',
      name: 'blockSelectStaffError',
      desc: '',
      args: [],
    );
  }

  /// `End time must be after start time`
  String get blockTimeError {
    return Intl.message(
      'End time must be after start time',
      name: 'blockTimeError',
      desc: '',
      args: [],
    );
  }

  /// `Reason (optional)`
  String get blockReason {
    return Intl.message(
      'Reason (optional)',
      name: 'blockReason',
      desc: '',
      args: [],
    );
  }

  /// `E.g. Meeting, Break, etc.`
  String get blockReasonHint {
    return Intl.message(
      'E.g. Meeting, Break, etc.',
      name: 'blockReasonHint',
      desc: '',
      args: [],
    );
  }

  /// `Cannot add service: the time exceeds midnight. Change the start time or staff member.`
  String get serviceStartsAfterMidnight {
    return Intl.message(
      'Cannot add service: the time exceeds midnight. Change the start time or staff member.',
      name: 'serviceStartsAfterMidnight',
      desc: '',
      args: [],
    );
  }

  /// `Sort by`
  String get sortByTitle {
    return Intl.message('Sort by', name: 'sortByTitle', desc: '', args: []);
  }

  /// `Select team`
  String get selectStaffTitle {
    return Intl.message(
      'Select team',
      name: 'selectStaffTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add a client to the appointment`
  String get addClientToAppointment {
    return Intl.message(
      'Add a client to the appointment',
      name: 'addClientToAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Leave empty if you don't want to associate a client with the appointment`
  String get clientOptionalHint {
    return Intl.message(
      'Leave empty if you don\'t want to associate a client with the appointment',
      name: 'clientOptionalHint',
      desc: '',
      args: [],
    );
  }

  /// `Select client`
  String get selectClientTitle {
    return Intl.message(
      'Select client',
      name: 'selectClientTitle',
      desc: '',
      args: [],
    );
  }

  /// `Remove client`
  String get removeClient {
    return Intl.message(
      'Remove client',
      name: 'removeClient',
      desc: '',
      args: [],
    );
  }

  /// `Search client...`
  String get searchClientPlaceholder {
    return Intl.message(
      'Search client...',
      name: 'searchClientPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Create new client`
  String get createNewClient {
    return Intl.message(
      'Create new client',
      name: 'createNewClient',
      desc: '',
      args: [],
    );
  }

  /// `No client for the appointment`
  String get noClientForAppointment {
    return Intl.message(
      'No client for the appointment',
      name: 'noClientForAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Services`
  String get formServices {
    return Intl.message('Services', name: 'formServices', desc: '', args: []);
  }

  /// `Search service...`
  String get searchServices {
    return Intl.message(
      'Search service...',
      name: 'searchServices',
      desc: '',
      args: [],
    );
  }

  /// `Show all services`
  String get showAllServices {
    return Intl.message(
      'Show all services',
      name: 'showAllServices',
      desc: '',
      args: [],
    );
  }

  /// `No services found`
  String get noServicesFound {
    return Intl.message(
      'No services found',
      name: 'noServicesFound',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 service selected} other{{count} services selected}}`
  String servicesSelectedCount(int count) {
    return Intl.plural(
      count,
      one: '1 service selected',
      other: '$count services selected',
      name: 'servicesSelectedCount',
      desc: '',
      args: [count],
    );
  }

  /// `Add service`
  String get addService {
    return Intl.message('Add service', name: 'addService', desc: '', args: []);
  }

  /// `Add service/package`
  String get addServiceOrPackage {
    return Intl.message(
      'Add service/package',
      name: 'addServiceOrPackage',
      desc: '',
      args: [],
    );
  }

  /// `Select service`
  String get selectService {
    return Intl.message(
      'Select service',
      name: 'selectService',
      desc: '',
      args: [],
    );
  }

  /// `No services added`
  String get noServicesAdded {
    return Intl.message(
      'No services added',
      name: 'noServicesAdded',
      desc: '',
      args: [],
    );
  }

  /// `Add at least one service`
  String get atLeastOneServiceRequired {
    return Intl.message(
      'Add at least one service',
      name: 'atLeastOneServiceRequired',
      desc: '',
      args: [],
    );
  }

  /// `Notes about the appointment...`
  String get notesPlaceholder {
    return Intl.message(
      'Notes about the appointment...',
      name: 'notesPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `No team available`
  String get noStaffAvailable {
    return Intl.message(
      'No team available',
      name: 'noStaffAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Weekly`
  String get weeklyScheduleTitle {
    return Intl.message(
      'Weekly',
      name: 'weeklyScheduleTitle',
      desc: '',
      args: [],
    );
  }

  /// `{hours} hours total`
  String weeklyScheduleTotalHours(int hours) {
    return Intl.message(
      '$hours hours total',
      name: 'weeklyScheduleTotalHours',
      desc: '',
      args: [hours],
    );
  }

  /// `Not working`
  String get weeklyScheduleNotWorking {
    return Intl.message(
      'Not working',
      name: 'weeklyScheduleNotWorking',
      desc: '',
      args: [],
    );
  }

  /// `to`
  String get weeklyScheduleFor {
    return Intl.message('to', name: 'weeklyScheduleFor', desc: '', args: []);
  }

  /// `Add shift`
  String get weeklyScheduleAddShift {
    return Intl.message(
      'Add shift',
      name: 'weeklyScheduleAddShift',
      desc: '',
      args: [],
    );
  }

  /// `Remove shift`
  String get weeklyScheduleRemoveShift {
    return Intl.message(
      'Remove shift',
      name: 'weeklyScheduleRemoveShift',
      desc: '',
      args: [],
    );
  }

  /// `Monday`
  String get dayMondayFull {
    return Intl.message('Monday', name: 'dayMondayFull', desc: '', args: []);
  }

  /// `Tuesday`
  String get dayTuesdayFull {
    return Intl.message('Tuesday', name: 'dayTuesdayFull', desc: '', args: []);
  }

  /// `Wednesday`
  String get dayWednesdayFull {
    return Intl.message(
      'Wednesday',
      name: 'dayWednesdayFull',
      desc: '',
      args: [],
    );
  }

  /// `Thursday`
  String get dayThursdayFull {
    return Intl.message(
      'Thursday',
      name: 'dayThursdayFull',
      desc: '',
      args: [],
    );
  }

  /// `Friday`
  String get dayFridayFull {
    return Intl.message('Friday', name: 'dayFridayFull', desc: '', args: []);
  }

  /// `Saturday`
  String get daySaturdayFull {
    return Intl.message(
      'Saturday',
      name: 'daySaturdayFull',
      desc: '',
      args: [],
    );
  }

  /// `Sunday`
  String get daySundayFull {
    return Intl.message('Sunday', name: 'daySundayFull', desc: '', args: []);
  }

  /// `New exception`
  String get exceptionDialogTitleNew {
    return Intl.message(
      'New exception',
      name: 'exceptionDialogTitleNew',
      desc: '',
      args: [],
    );
  }

  /// `Edit exception`
  String get exceptionDialogTitleEdit {
    return Intl.message(
      'Edit exception',
      name: 'exceptionDialogTitleEdit',
      desc: '',
      args: [],
    );
  }

  /// `Exception type`
  String get exceptionType {
    return Intl.message(
      'Exception type',
      name: 'exceptionType',
      desc: '',
      args: [],
    );
  }

  /// `Unavailable`
  String get exceptionTypeUnavailable {
    return Intl.message(
      'Unavailable',
      name: 'exceptionTypeUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Available`
  String get exceptionTypeAvailable {
    return Intl.message(
      'Available',
      name: 'exceptionTypeAvailable',
      desc: '',
      args: [],
    );
  }

  /// `All day`
  String get exceptionAllDay {
    return Intl.message('All day', name: 'exceptionAllDay', desc: '', args: []);
  }

  /// `Start time`
  String get exceptionStartTime {
    return Intl.message(
      'Start time',
      name: 'exceptionStartTime',
      desc: '',
      args: [],
    );
  }

  /// `End time`
  String get exceptionEndTime {
    return Intl.message(
      'End time',
      name: 'exceptionEndTime',
      desc: '',
      args: [],
    );
  }

  /// `Reason (optional)`
  String get exceptionReason {
    return Intl.message(
      'Reason (optional)',
      name: 'exceptionReason',
      desc: '',
      args: [],
    );
  }

  /// `Vacation`
  String get exceptionReasonVacation {
    return Intl.message(
      'Vacation',
      name: 'exceptionReasonVacation',
      desc: '',
      args: [],
    );
  }

  /// `Extra shift`
  String get exceptionReasonExtraShift {
    return Intl.message(
      'Extra shift',
      name: 'exceptionReasonExtraShift',
      desc: '',
      args: [],
    );
  }

  /// `Medical visit`
  String get exceptionReasonMedicalVisit {
    return Intl.message(
      'Medical visit',
      name: 'exceptionReasonMedicalVisit',
      desc: '',
      args: [],
    );
  }

  /// `E.g. Holiday, Medical visit, Extra shift...`
  String get exceptionReasonHint {
    return Intl.message(
      'E.g. Holiday, Medical visit, Extra shift...',
      name: 'exceptionReasonHint',
      desc: '',
      args: [],
    );
  }

  /// `End time must be after start time`
  String get exceptionTimeError {
    return Intl.message(
      'End time must be after start time',
      name: 'exceptionTimeError',
      desc: '',
      args: [],
    );
  }

  /// `You can't add unavailability on a day with no base availability.`
  String get exceptionUnavailableNoBase {
    return Intl.message(
      'You can\'t add unavailability on a day with no base availability.',
      name: 'exceptionUnavailableNoBase',
      desc: '',
      args: [],
    );
  }

  /// `Unavailability must overlap the base availability.`
  String get exceptionUnavailableNoOverlap {
    return Intl.message(
      'Unavailability must overlap the base availability.',
      name: 'exceptionUnavailableNoOverlap',
      desc: '',
      args: [],
    );
  }

  /// `Extra availability must add hours beyond the base availability.`
  String get exceptionAvailableNoEffect {
    return Intl.message(
      'Extra availability must add hours beyond the base availability.',
      name: 'exceptionAvailableNoEffect',
      desc: '',
      args: [],
    );
  }

  /// `Some days were not saved: {dates}.`
  String exceptionPartialSaveInfo(Object dates) {
    return Intl.message(
      'Some days were not saved: $dates.',
      name: 'exceptionPartialSaveInfo',
      desc: '',
      args: [dates],
    );
  }

  /// `Some days were not saved: {details}.`
  String exceptionPartialSaveInfoDetailed(Object details) {
    return Intl.message(
      'Some days were not saved: $details.',
      name: 'exceptionPartialSaveInfoDetailed',
      desc: '',
      args: [details],
    );
  }

  /// `Exceptions not saved`
  String get exceptionPartialSaveTitle {
    return Intl.message(
      'Exceptions not saved',
      name: 'exceptionPartialSaveTitle',
      desc: '',
      args: [],
    );
  }

  /// `The days below were not congruent and were not saved:`
  String get exceptionPartialSaveMessage {
    return Intl.message(
      'The days below were not congruent and were not saved:',
      name: 'exceptionPartialSaveMessage',
      desc: '',
      args: [],
    );
  }

  /// `Delete exception?`
  String get exceptionDeleteTitle {
    return Intl.message(
      'Delete exception?',
      name: 'exceptionDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `The exception will be permanently deleted.`
  String get exceptionDeleteMessage {
    return Intl.message(
      'The exception will be permanently deleted.',
      name: 'exceptionDeleteMessage',
      desc: '',
      args: [],
    );
  }

  /// `Select time`
  String get exceptionSelectTime {
    return Intl.message(
      'Select time',
      name: 'exceptionSelectTime',
      desc: '',
      args: [],
    );
  }

  /// `Exceptions`
  String get exceptionsTitle {
    return Intl.message(
      'Exceptions',
      name: 'exceptionsTitle',
      desc: '',
      args: [],
    );
  }

  /// `No exceptions configured`
  String get exceptionsEmpty {
    return Intl.message(
      'No exceptions configured',
      name: 'exceptionsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Add exception`
  String get exceptionsAdd {
    return Intl.message(
      'Add exception',
      name: 'exceptionsAdd',
      desc: '',
      args: [],
    );
  }

  /// `Period`
  String get exceptionPeriodMode {
    return Intl.message(
      'Period',
      name: 'exceptionPeriodMode',
      desc: '',
      args: [],
    );
  }

  /// `Single day`
  String get exceptionPeriodSingle {
    return Intl.message(
      'Single day',
      name: 'exceptionPeriodSingle',
      desc: '',
      args: [],
    );
  }

  /// `From - To`
  String get exceptionPeriodRange {
    return Intl.message(
      'From - To',
      name: 'exceptionPeriodRange',
      desc: '',
      args: [],
    );
  }

  /// `Duration`
  String get exceptionPeriodDuration {
    return Intl.message(
      'Duration',
      name: 'exceptionPeriodDuration',
      desc: '',
      args: [],
    );
  }

  /// `Start date`
  String get exceptionDateFrom {
    return Intl.message(
      'Start date',
      name: 'exceptionDateFrom',
      desc: '',
      args: [],
    );
  }

  /// `End date`
  String get exceptionDateTo {
    return Intl.message(
      'End date',
      name: 'exceptionDateTo',
      desc: '',
      args: [],
    );
  }

  /// `Duration (days)`
  String get exceptionDuration {
    return Intl.message(
      'Duration (days)',
      name: 'exceptionDuration',
      desc: '',
      args: [],
    );
  }

  /// `{count} {count, plural, =1{day} other{days}}`
  String exceptionDurationDays(int count) {
    return Intl.message(
      '$count ${Intl.plural(count, one: 'day', other: 'days')}',
      name: 'exceptionDurationDays',
      desc: '',
      args: [count],
    );
  }

  /// `Delete only this shift`
  String get shiftDeleteThisOnly {
    return Intl.message(
      'Delete only this shift',
      name: 'shiftDeleteThisOnly',
      desc: '',
      args: [],
    );
  }

  /// `Delete only the time slot of {date}`
  String shiftDeleteThisOnlyDesc(String date) {
    return Intl.message(
      'Delete only the time slot of $date',
      name: 'shiftDeleteThisOnlyDesc',
      desc: '',
      args: [date],
    );
  }

  /// `Delete all these shifts`
  String get shiftDeleteAll {
    return Intl.message(
      'Delete all these shifts',
      name: 'shiftDeleteAll',
      desc: '',
      args: [],
    );
  }

  /// `Delete the weekly time slot for every {dayName}`
  String shiftDeleteAllDesc(String dayName) {
    return Intl.message(
      'Delete the weekly time slot for every $dayName',
      name: 'shiftDeleteAllDesc',
      desc: '',
      args: [dayName],
    );
  }

  /// `Edit only this shift`
  String get shiftEditThisOnly {
    return Intl.message(
      'Edit only this shift',
      name: 'shiftEditThisOnly',
      desc: '',
      args: [],
    );
  }

  /// `Edit only the time slot of {date}`
  String shiftEditThisOnlyDesc(String date) {
    return Intl.message(
      'Edit only the time slot of $date',
      name: 'shiftEditThisOnlyDesc',
      desc: '',
      args: [date],
    );
  }

  /// `Edit all these shifts`
  String get shiftEditAll {
    return Intl.message(
      'Edit all these shifts',
      name: 'shiftEditAll',
      desc: '',
      args: [],
    );
  }

  /// `Edit the weekly time slot for every {dayName}`
  String shiftEditAllDesc(String dayName) {
    return Intl.message(
      'Edit the weekly time slot for every $dayName',
      name: 'shiftEditAllDesc',
      desc: '',
      args: [dayName],
    );
  }

  /// `Edit shift`
  String get shiftEditTitle {
    return Intl.message(
      'Edit shift',
      name: 'shiftEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Start time`
  String get shiftStartTime {
    return Intl.message(
      'Start time',
      name: 'shiftStartTime',
      desc: '',
      args: [],
    );
  }

  /// `End time`
  String get shiftEndTime {
    return Intl.message('End time', name: 'shiftEndTime', desc: '', args: []);
  }

  /// `Edit exception`
  String get exceptionEditShift {
    return Intl.message(
      'Edit exception',
      name: 'exceptionEditShift',
      desc: '',
      args: [],
    );
  }

  /// `Edit the times of this exception`
  String get exceptionEditShiftDesc {
    return Intl.message(
      'Edit the times of this exception',
      name: 'exceptionEditShiftDesc',
      desc: '',
      args: [],
    );
  }

  /// `Delete exception`
  String get exceptionDeleteShift {
    return Intl.message(
      'Delete exception',
      name: 'exceptionDeleteShift',
      desc: '',
      args: [],
    );
  }

  /// `Restore base availability`
  String get exceptionDeleteShiftDesc {
    return Intl.message(
      'Restore base availability',
      name: 'exceptionDeleteShiftDesc',
      desc: '',
      args: [],
    );
  }

  /// `Client cannot be changed for this appointment`
  String get clientLockedHint {
    return Intl.message(
      'Client cannot be changed for this appointment',
      name: 'clientLockedHint',
      desc: '',
      args: [],
    );
  }

  /// `Apply client to entire booking?`
  String get applyClientToAllAppointmentsTitle {
    return Intl.message(
      'Apply client to entire booking?',
      name: 'applyClientToAllAppointmentsTitle',
      desc: '',
      args: [],
    );
  }

  /// `The client will also be associated with the appointments in this booking that have been assigned to other staff members.`
  String get applyClientToAllAppointmentsMessage {
    return Intl.message(
      'The client will also be associated with the appointments in this booking that have been assigned to other staff members.',
      name: 'applyClientToAllAppointmentsMessage',
      desc: '',
      args: [],
    );
  }

  /// `Operators`
  String get operatorsTitle {
    return Intl.message(
      'Operators',
      name: 'operatorsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Manage who can access the platform`
  String get operatorsSubtitle {
    return Intl.message(
      'Manage who can access the platform',
      name: 'operatorsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Permissions`
  String get permissionsTitle {
    return Intl.message(
      'Permissions',
      name: 'permissionsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Manage operator access and roles`
  String get permissionsDescription {
    return Intl.message(
      'Manage operator access and roles',
      name: 'permissionsDescription',
      desc: '',
      args: [],
    );
  }

  /// `No operators configured`
  String get operatorsEmpty {
    return Intl.message(
      'No operators configured',
      name: 'operatorsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Invite operator`
  String get operatorsInviteTitle {
    return Intl.message(
      'Invite operator',
      name: 'operatorsInviteTitle',
      desc: '',
      args: [],
    );
  }

  /// `Send an invite via email`
  String get operatorsInviteSubtitle {
    return Intl.message(
      'Send an invite via email',
      name: 'operatorsInviteSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get operatorsInviteEmail {
    return Intl.message(
      'Email',
      name: 'operatorsInviteEmail',
      desc: '',
      args: [],
    );
  }

  /// `Role`
  String get operatorsInviteRole {
    return Intl.message(
      'Role',
      name: 'operatorsInviteRole',
      desc: '',
      args: [],
    );
  }

  /// `Send invite`
  String get operatorsInviteSend {
    return Intl.message(
      'Send invite',
      name: 'operatorsInviteSend',
      desc: '',
      args: [],
    );
  }

  /// `Invite sent to {email}`
  String operatorsInviteSuccess(String email) {
    return Intl.message(
      'Invite sent to $email',
      name: 'operatorsInviteSuccess',
      desc: '',
      args: [email],
    );
  }

  /// `An invite is already pending for this email. You can resend it from the pending invites list.`
  String get operatorsInviteAlreadyPending {
    return Intl.message(
      'An invite is already pending for this email. You can resend it from the pending invites list.',
      name: 'operatorsInviteAlreadyPending',
      desc: '',
      args: [],
    );
  }

  /// `This user already has access to the business.`
  String get operatorsInviteAlreadyHasAccess {
    return Intl.message(
      'This user already has access to the business.',
      name: 'operatorsInviteAlreadyHasAccess',
      desc: '',
      args: [],
    );
  }

  /// `Email sending is unavailable in this environment. Please contact support.`
  String get operatorsInviteEmailUnavailable {
    return Intl.message(
      'Email sending is unavailable in this environment. Please contact support.',
      name: 'operatorsInviteEmailUnavailable',
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

  /// `Unable to send the invitation email. Please try again later.`
  String get operatorsInviteEmailFailed {
    return Intl.message(
      'Unable to send the invitation email. Please try again later.',
      name: 'operatorsInviteEmailFailed',
      desc: '',
      args: [],
    );
  }

  /// `Unable to send invite`
  String get operatorsInviteError {
    return Intl.message(
      'Unable to send invite',
      name: 'operatorsInviteError',
      desc: '',
      args: [],
    );
  }

  /// `Invite link copied`
  String get operatorsInviteCopied {
    return Intl.message(
      'Invite link copied',
      name: 'operatorsInviteCopied',
      desc: '',
      args: [],
    );
  }

  /// `Accept invitation`
  String get invitationAcceptTitle {
    return Intl.message(
      'Accept invitation',
      name: 'invitationAcceptTitle',
      desc: '',
      args: [],
    );
  }

  /// `Checking invitation...`
  String get invitationAcceptLoading {
    return Intl.message(
      'Checking invitation...',
      name: 'invitationAcceptLoading',
      desc: '',
      args: [],
    );
  }

  /// `You were invited to collaborate with {businessName} as {role}.`
  String invitationAcceptIntro(String businessName, String role) {
    return Intl.message(
      'You were invited to collaborate with $businessName as $role.',
      name: 'invitationAcceptIntro',
      desc: '',
      args: [businessName, role],
    );
  }

  /// `Sign in with the invited email to continue.`
  String get invitationAcceptLoginRequired {
    return Intl.message(
      'Sign in with the invited email to continue.',
      name: 'invitationAcceptLoginRequired',
      desc: '',
      args: [],
    );
  }

  /// `Accept to continue`
  String get invitationAcceptLoginAction {
    return Intl.message(
      'Accept to continue',
      name: 'invitationAcceptLoginAction',
      desc: '',
      args: [],
    );
  }

  /// `Accept and sign in`
  String get invitationAcceptAndLoginAction {
    return Intl.message(
      'Accept and sign in',
      name: 'invitationAcceptAndLoginAction',
      desc: '',
      args: [],
    );
  }

  /// `Already have an account? Sign in to accept the invitation.`
  String get invitationAcceptHintExistingAccount {
    return Intl.message(
      'Already have an account? Sign in to accept the invitation.',
      name: 'invitationAcceptHintExistingAccount',
      desc: '',
      args: [],
    );
  }

  /// `No account yet? Register first.`
  String get invitationAcceptHintNoAccount {
    return Intl.message(
      'No account yet? Register first.',
      name: 'invitationAcceptHintNoAccount',
      desc: '',
      args: [],
    );
  }

  /// `Register to accept`
  String get invitationRegisterAction {
    return Intl.message(
      'Register to accept',
      name: 'invitationRegisterAction',
      desc: '',
      args: [],
    );
  }

  /// `Register to accept invitation`
  String get invitationRegisterTitle {
    return Intl.message(
      'Register to accept invitation',
      name: 'invitationRegisterTitle',
      desc: '',
      args: [],
    );
  }

  /// `Registering...`
  String get invitationRegisterInProgress {
    return Intl.message(
      'Registering...',
      name: 'invitationRegisterInProgress',
      desc: '',
      args: [],
    );
  }

  /// `Confirm password`
  String get invitationRegisterPasswordConfirm {
    return Intl.message(
      'Confirm password',
      name: 'invitationRegisterPasswordConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Password must be at least 8 characters long.`
  String get invitationRegisterPasswordTooShort {
    return Intl.message(
      'Password must be at least 8 characters long.',
      name: 'invitationRegisterPasswordTooShort',
      desc: '',
      args: [],
    );
  }

  /// `Password must include at least one uppercase letter, one lowercase letter, and one number.`
  String get invitationRegisterPasswordWeak {
    return Intl.message(
      'Password must include at least one uppercase letter, one lowercase letter, and one number.',
      name: 'invitationRegisterPasswordWeak',
      desc: '',
      args: [],
    );
  }

  /// `Passwords do not match.`
  String get invitationRegisterPasswordMismatch {
    return Intl.message(
      'Passwords do not match.',
      name: 'invitationRegisterPasswordMismatch',
      desc: '',
      args: [],
    );
  }

  /// `Email already registered. Sign in to accept the invitation.`
  String get invitationRegisterExistingUser {
    return Intl.message(
      'Email already registered. Sign in to accept the invitation.',
      name: 'invitationRegisterExistingUser',
      desc: '',
      args: [],
    );
  }

  /// `No account exists for this email yet. Use Register.`
  String get invitationAcceptRequiresRegistration {
    return Intl.message(
      'No account exists for this email yet. Use Register.',
      name: 'invitationAcceptRequiresRegistration',
      desc: '',
      args: [],
    );
  }

  /// `Accept invitation`
  String get invitationAcceptButton {
    return Intl.message(
      'Accept invitation',
      name: 'invitationAcceptButton',
      desc: '',
      args: [],
    );
  }

  /// `Accepting invitation...`
  String get invitationAcceptInProgress {
    return Intl.message(
      'Accepting invitation...',
      name: 'invitationAcceptInProgress',
      desc: '',
      args: [],
    );
  }

  /// `Decline invitation`
  String get invitationDeclineButton {
    return Intl.message(
      'Decline invitation',
      name: 'invitationDeclineButton',
      desc: '',
      args: [],
    );
  }

  /// `Declining invitation...`
  String get invitationDeclineInProgress {
    return Intl.message(
      'Declining invitation...',
      name: 'invitationDeclineInProgress',
      desc: '',
      args: [],
    );
  }

  /// `Invitation accepted`
  String get invitationAcceptSuccessTitle {
    return Intl.message(
      'Invitation accepted',
      name: 'invitationAcceptSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `You can now use the management app with assigned permissions.`
  String get invitationAcceptSuccessMessage {
    return Intl.message(
      'You can now use the management app with assigned permissions.',
      name: 'invitationAcceptSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Invitation declined`
  String get invitationDeclineSuccessTitle {
    return Intl.message(
      'Invitation declined',
      name: 'invitationDeclineSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `You declined the invitation. No permission has been granted.`
  String get invitationDeclineSuccessMessage {
    return Intl.message(
      'You declined the invitation. No permission has been granted.',
      name: 'invitationDeclineSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Go to login`
  String get invitationDeclineGoLogin {
    return Intl.message(
      'Go to login',
      name: 'invitationDeclineGoLogin',
      desc: '',
      args: [],
    );
  }

  /// `This invitation is not valid.`
  String get invitationAcceptErrorInvalid {
    return Intl.message(
      'This invitation is not valid.',
      name: 'invitationAcceptErrorInvalid',
      desc: '',
      args: [],
    );
  }

  /// `This invitation has expired.`
  String get invitationAcceptErrorExpired {
    return Intl.message(
      'This invitation has expired.',
      name: 'invitationAcceptErrorExpired',
      desc: '',
      args: [],
    );
  }

  /// `This invitation is linked to a different email. Sign out from the current account, then reopen this invitation link and sign in with the invited email.`
  String get invitationAcceptErrorEmailMismatch {
    return Intl.message(
      'This invitation is linked to a different email. Sign out from the current account, then reopen this invitation link and sign in with the invited email.',
      name: 'invitationAcceptErrorEmailMismatch',
      desc: '',
      args: [],
    );
  }

  /// `Go to application`
  String get invitationGoToApplication {
    return Intl.message(
      'Go to application',
      name: 'invitationGoToApplication',
      desc: '',
      args: [],
    );
  }

  /// `Unable to complete the operation. Please try again.`
  String get invitationAcceptErrorGeneric {
    return Intl.message(
      'Unable to complete the operation. Please try again.',
      name: 'invitationAcceptErrorGeneric',
      desc: '',
      args: [],
    );
  }

  /// `Access`
  String get operatorsScopeTitle {
    return Intl.message(
      'Access',
      name: 'operatorsScopeTitle',
      desc: '',
      args: [],
    );
  }

  /// `All locations`
  String get operatorsScopeBusiness {
    return Intl.message(
      'All locations',
      name: 'operatorsScopeBusiness',
      desc: '',
      args: [],
    );
  }

  /// `Full access to all business locations`
  String get operatorsScopeBusinessDesc {
    return Intl.message(
      'Full access to all business locations',
      name: 'operatorsScopeBusinessDesc',
      desc: '',
      args: [],
    );
  }

  /// `Specific locations`
  String get operatorsScopeLocations {
    return Intl.message(
      'Specific locations',
      name: 'operatorsScopeLocations',
      desc: '',
      args: [],
    );
  }

  /// `Access limited to selected locations`
  String get operatorsScopeLocationsDesc {
    return Intl.message(
      'Access limited to selected locations',
      name: 'operatorsScopeLocationsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Select locations`
  String get operatorsScopeSelectLocations {
    return Intl.message(
      'Select locations',
      name: 'operatorsScopeSelectLocations',
      desc: '',
      args: [],
    );
  }

  /// `Select at least one location`
  String get operatorsScopeLocationsRequired {
    return Intl.message(
      'Select at least one location',
      name: 'operatorsScopeLocationsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Pending invites`
  String get operatorsPendingInvites {
    return Intl.message(
      'Pending invites',
      name: 'operatorsPendingInvites',
      desc: '',
      args: [],
    );
  }

  /// `{count} pending invites`
  String operatorsPendingInvitesCount(int count) {
    return Intl.message(
      '$count pending invites',
      name: 'operatorsPendingInvitesCount',
      desc: '',
      args: [count],
    );
  }

  /// `Revoke invite`
  String get operatorsRevokeInvite {
    return Intl.message(
      'Revoke invite',
      name: 'operatorsRevokeInvite',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to revoke the invite for {email}?`
  String operatorsRevokeInviteConfirm(String email) {
    return Intl.message(
      'Do you want to revoke the invite for $email?',
      name: 'operatorsRevokeInviteConfirm',
      desc: '',
      args: [email],
    );
  }

  /// `Delete invite`
  String get operatorsDeleteInvite {
    return Intl.message(
      'Delete invite',
      name: 'operatorsDeleteInvite',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to permanently delete the invite for {email}?`
  String operatorsDeleteInviteConfirm(String email) {
    return Intl.message(
      'Do you want to permanently delete the invite for $email?',
      name: 'operatorsDeleteInviteConfirm',
      desc: '',
      args: [email],
    );
  }

  /// `Edit role`
  String get operatorsEditRole {
    return Intl.message(
      'Edit role',
      name: 'operatorsEditRole',
      desc: '',
      args: [],
    );
  }

  /// `Remove operator`
  String get operatorsRemove {
    return Intl.message(
      'Remove operator',
      name: 'operatorsRemove',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to remove {name} from the team?`
  String operatorsRemoveConfirm(String name) {
    return Intl.message(
      'Do you want to remove $name from the team?',
      name: 'operatorsRemoveConfirm',
      desc: '',
      args: [name],
    );
  }

  /// `Operator removed`
  String get operatorsRemoveSuccess {
    return Intl.message(
      'Operator removed',
      name: 'operatorsRemoveSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Owner`
  String get operatorsRoleOwner {
    return Intl.message(
      'Owner',
      name: 'operatorsRoleOwner',
      desc: '',
      args: [],
    );
  }

  /// `Administrator`
  String get operatorsRoleAdmin {
    return Intl.message(
      'Administrator',
      name: 'operatorsRoleAdmin',
      desc: '',
      args: [],
    );
  }

  /// `Full access to all features. Can manage other operators and modify business settings.`
  String get operatorsRoleAdminDesc {
    return Intl.message(
      'Full access to all features. Can manage other operators and modify business settings.',
      name: 'operatorsRoleAdminDesc',
      desc: '',
      args: [],
    );
  }

  /// `Manager`
  String get operatorsRoleManager {
    return Intl.message(
      'Manager',
      name: 'operatorsRoleManager',
      desc: '',
      args: [],
    );
  }

  /// `Manages agenda and clients. Can view and manage all appointments, but cannot manage operators or settings.`
  String get operatorsRoleManagerDesc {
    return Intl.message(
      'Manages agenda and clients. Can view and manage all appointments, but cannot manage operators or settings.',
      name: 'operatorsRoleManagerDesc',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get operatorsRoleStaff {
    return Intl.message(
      'Staff',
      name: 'operatorsRoleStaff',
      desc: '',
      args: [],
    );
  }

  /// `Views and manages only own appointments. Can create bookings assigned to themselves.`
  String get operatorsRoleStaffDesc {
    return Intl.message(
      'Views and manages only own appointments. Can create bookings assigned to themselves.',
      name: 'operatorsRoleStaffDesc',
      desc: '',
      args: [],
    );
  }

  /// `Viewer`
  String get operatorsRoleViewer {
    return Intl.message(
      'Viewer',
      name: 'operatorsRoleViewer',
      desc: '',
      args: [],
    );
  }

  /// `Can view appointments, services, staff, and availability. No edits allowed.`
  String get operatorsRoleViewerDesc {
    return Intl.message(
      'Can view appointments, services, staff, and availability. No edits allowed.',
      name: 'operatorsRoleViewerDesc',
      desc: '',
      args: [],
    );
  }

  /// `Select access level`
  String get operatorsRoleDescription {
    return Intl.message(
      'Select access level',
      name: 'operatorsRoleDescription',
      desc: '',
      args: [],
    );
  }

  /// `You`
  String get operatorsYou {
    return Intl.message('You', name: 'operatorsYou', desc: '', args: []);
  }

  /// `Invited by {name}`
  String operatorsInvitedBy(String name) {
    return Intl.message(
      'Invited by $name',
      name: 'operatorsInvitedBy',
      desc: '',
      args: [name],
    );
  }

  /// `Expires on {date}`
  String operatorsExpires(String date) {
    return Intl.message(
      'Expires on $date',
      name: 'operatorsExpires',
      desc: '',
      args: [date],
    );
  }

  /// `Accepted on {date}`
  String operatorsAcceptedOn(String date) {
    return Intl.message(
      'Accepted on $date',
      name: 'operatorsAcceptedOn',
      desc: '',
      args: [date],
    );
  }

  /// `{count} archived invites`
  String operatorsInvitesHistoryCount(int count) {
    return Intl.message(
      '$count archived invites',
      name: 'operatorsInvitesHistoryCount',
      desc: '',
      args: [count],
    );
  }

  /// `Pending`
  String get operatorsInviteStatusPending {
    return Intl.message(
      'Pending',
      name: 'operatorsInviteStatusPending',
      desc: '',
      args: [],
    );
  }

  /// `Accepted`
  String get operatorsInviteStatusAccepted {
    return Intl.message(
      'Accepted',
      name: 'operatorsInviteStatusAccepted',
      desc: '',
      args: [],
    );
  }

  /// `Declined`
  String get operatorsInviteStatusDeclined {
    return Intl.message(
      'Declined',
      name: 'operatorsInviteStatusDeclined',
      desc: '',
      args: [],
    );
  }

  /// `Revoked`
  String get operatorsInviteStatusRevoked {
    return Intl.message(
      'Revoked',
      name: 'operatorsInviteStatusRevoked',
      desc: '',
      args: [],
    );
  }

  /// `Expired`
  String get operatorsInviteStatusExpired {
    return Intl.message(
      'Expired',
      name: 'operatorsInviteStatusExpired',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to the management system`
  String get authLoginSubtitle {
    return Intl.message(
      'Sign in to the management system',
      name: 'authLoginSubtitle',
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

  /// `Sign In`
  String get authLogin {
    return Intl.message('Sign In', name: 'authLogin', desc: '', args: []);
  }

  /// `Sign Out`
  String get authLogout {
    return Intl.message('Sign Out', name: 'authLogout', desc: '', args: []);
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

  /// `Forgot password?`
  String get authForgotPassword {
    return Intl.message(
      'Forgot password?',
      name: 'authForgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Contact the system administrator to reset your password.`
  String get authForgotPasswordInfo {
    return Intl.message(
      'Contact the system administrator to reset your password.',
      name: 'authForgotPasswordInfo',
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

  /// `Enter your email. We will send you a link to reset your password.`
  String get authResetPasswordMessage {
    return Intl.message(
      'Enter your email. We will send you a link to reset your password.',
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

  /// `If the email exists in our system, you will receive a password reset link.`
  String get authResetPasswordSuccess {
    return Intl.message(
      'If the email exists in our system, you will receive a password reset link.',
      name: 'authResetPasswordSuccess',
      desc: '',
      args: [],
    );
  }

  /// `An error occurred. Please try again later.`
  String get authResetPasswordError {
    return Intl.message(
      'An error occurred. Please try again later.',
      name: 'authResetPasswordError',
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

  /// `Invalid email`
  String get authInvalidEmail {
    return Intl.message(
      'Invalid email',
      name: 'authInvalidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Password too short`
  String get authPasswordTooShort {
    return Intl.message(
      'Password too short',
      name: 'authPasswordTooShort',
      desc: '',
      args: [],
    );
  }

  /// `Invalid credentials. Please try again.`
  String get authLoginFailed {
    return Intl.message(
      'Invalid credentials. Please try again.',
      name: 'authLoginFailed',
      desc: '',
      args: [],
    );
  }

  /// `Could not connect to the server. Check your internet connection.`
  String get authNetworkError {
    return Intl.message(
      'Could not connect to the server. Check your internet connection.',
      name: 'authNetworkError',
      desc: '',
      args: [],
    );
  }

  /// `Connection timed out. Please try again.`
  String get networkTimeoutError {
    return Intl.message(
      'Connection timed out. Please try again.',
      name: 'networkTimeoutError',
      desc: '',
      args: [],
    );
  }

  /// `Could not connect to the server. Check your internet connection.`
  String get networkConnectionError {
    return Intl.message(
      'Could not connect to the server. Check your internet connection.',
      name: 'networkConnectionError',
      desc: '',
      args: [],
    );
  }

  /// `The request was cancelled before it could complete. Please try again.`
  String get networkRequestCancelled {
    return Intl.message(
      'The request was cancelled before it could complete. Please try again.',
      name: 'networkRequestCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Network error. Please try again.`
  String get networkUnknownError {
    return Intl.message(
      'Network error. Please try again.',
      name: 'networkUnknownError',
      desc: '',
      args: [],
    );
  }

  /// `Internal server error. Please try again later.`
  String get serverError500 {
    return Intl.message(
      'Internal server error. Please try again later.',
      name: 'serverError500',
      desc: '',
      args: [],
    );
  }

  /// `Service temporarily unavailable (bad gateway). Please try again.`
  String get serverError502 {
    return Intl.message(
      'Service temporarily unavailable (bad gateway). Please try again.',
      name: 'serverError502',
      desc: '',
      args: [],
    );
  }

  /// `Service temporarily unavailable. Please try again shortly.`
  String get serverError503 {
    return Intl.message(
      'Service temporarily unavailable. Please try again shortly.',
      name: 'serverError503',
      desc: '',
      args: [],
    );
  }

  /// `Server response timeout. Please try again.`
  String get serverError504 {
    return Intl.message(
      'Server response timeout. Please try again.',
      name: 'serverError504',
      desc: '',
      args: [],
    );
  }

  /// `Access reserved for authorized operators`
  String get authLoginFooter {
    return Intl.message(
      'Access reserved for authorized operators',
      name: 'authLoginFooter',
      desc: '',
      args: [],
    );
  }

  /// `First Name`
  String get authFirstName {
    return Intl.message(
      'First Name',
      name: 'authFirstName',
      desc: '',
      args: [],
    );
  }

  /// `Last Name`
  String get authLastName {
    return Intl.message('Last Name', name: 'authLastName', desc: '', args: []);
  }

  /// `Phone`
  String get authPhone {
    return Intl.message('Phone', name: 'authPhone', desc: '', args: []);
  }

  /// `Switch`
  String get switchBusiness {
    return Intl.message('Switch', name: 'switchBusiness', desc: '', args: []);
  }

  /// `Rail starts at top`
  String get superadminRailStartTopLabel {
    return Intl.message(
      'Rail starts at top',
      name: 'superadminRailStartTopLabel',
      desc: '',
      args: [],
    );
  }

  /// `If enabled, on desktop the navigation rail starts from the top edge without toolbar.`
  String get superadminRailStartTopHelp {
    return Intl.message(
      'If enabled, on desktop the navigation rail starts from the top edge without toolbar.',
      name: 'superadminRailStartTopHelp',
      desc: '',
      args: [],
    );
  }

  /// `Profile`
  String get profileTitle {
    return Intl.message('Profile', name: 'profileTitle', desc: '', args: []);
  }

  /// `Profile updated successfully`
  String get profileUpdateSuccess {
    return Intl.message(
      'Profile updated successfully',
      name: 'profileUpdateSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Warning: changing email will update your login credentials`
  String get profileEmailChangeWarning {
    return Intl.message(
      'Warning: changing email will update your login credentials',
      name: 'profileEmailChangeWarning',
      desc: '',
      args: [],
    );
  }

  /// `Change password`
  String get profileChangePassword {
    return Intl.message(
      'Change password',
      name: 'profileChangePassword',
      desc: '',
      args: [],
    );
  }

  /// `Admin language`
  String get profileLanguageLabel {
    return Intl.message(
      'Admin language',
      name: 'profileLanguageLabel',
      desc: '',
      args: [],
    );
  }

  /// `Italian`
  String get profileLanguageItalian {
    return Intl.message(
      'Italian',
      name: 'profileLanguageItalian',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get profileLanguageEnglish {
    return Intl.message(
      'English',
      name: 'profileLanguageEnglish',
      desc: '',
      args: [],
    );
  }

  /// `Use system language`
  String get profileLanguageUseSystem {
    return Intl.message(
      'Use system language',
      name: 'profileLanguageUseSystem',
      desc: '',
      args: [],
    );
  }

  /// `Switch business`
  String get profileSwitchBusiness {
    return Intl.message(
      'Switch business',
      name: 'profileSwitchBusiness',
      desc: '',
      args: [],
    );
  }

  /// `New planning`
  String get planningCreateTitle {
    return Intl.message(
      'New planning',
      name: 'planningCreateTitle',
      desc: '',
      args: [],
    );
  }

  /// `Edit planning`
  String get planningEditTitle {
    return Intl.message(
      'Edit planning',
      name: 'planningEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Delete planning`
  String get planningDeleteTitle {
    return Intl.message(
      'Delete planning',
      name: 'planningDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this planning? Weekly schedules will be removed.`
  String get planningDeleteConfirm {
    return Intl.message(
      'Are you sure you want to delete this planning? Weekly schedules will be removed.',
      name: 'planningDeleteConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Planning type`
  String get planningType {
    return Intl.message(
      'Planning type',
      name: 'planningType',
      desc: '',
      args: [],
    );
  }

  /// `Weekly`
  String get planningTypeWeekly {
    return Intl.message(
      'Weekly',
      name: 'planningTypeWeekly',
      desc: '',
      args: [],
    );
  }

  /// `Biweekly`
  String get planningTypeBiweekly {
    return Intl.message(
      'Biweekly',
      name: 'planningTypeBiweekly',
      desc: '',
      args: [],
    );
  }

  /// `Unavailable`
  String get planningTypeUnavailable {
    return Intl.message(
      'Unavailable',
      name: 'planningTypeUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Validity start date`
  String get planningValidFrom {
    return Intl.message(
      'Validity start date',
      name: 'planningValidFrom',
      desc: '',
      args: [],
    );
  }

  /// `Validity end date`
  String get planningValidTo {
    return Intl.message(
      'Validity end date',
      name: 'planningValidTo',
      desc: '',
      args: [],
    );
  }

  /// `No end date`
  String get planningOpenEnded {
    return Intl.message(
      'No end date',
      name: 'planningOpenEnded',
      desc: '',
      args: [],
    );
  }

  /// `Valid from {from} to {to}`
  String planningValidFromTo(String from, String to) {
    return Intl.message(
      'Valid from $from to $to',
      name: 'planningValidFromTo',
      desc: '',
      args: [from, to],
    );
  }

  /// `Valid from {from}`
  String planningValidFromOnly(String from) {
    return Intl.message(
      'Valid from $from',
      name: 'planningValidFromOnly',
      desc: '',
      args: [from],
    );
  }

  /// `{hours}h/week`
  String planningWeeklyHours(int hours) {
    return Intl.message(
      '${hours}h/week',
      name: 'planningWeeklyHours',
      desc: '',
      args: [hours],
    );
  }

  /// `Week A: {hoursA}h | Week B: {hoursB}h | Tot: {total}h`
  String planningBiweeklyHours(int hoursA, int hoursB, int total) {
    return Intl.message(
      'Week A: ${hoursA}h | Week B: ${hoursB}h | Tot: ${total}h',
      name: 'planningBiweeklyHours',
      desc: '',
      args: [hoursA, hoursB, total],
    );
  }

  /// `{duration}/week`
  String planningWeeklyDuration(String duration) {
    return Intl.message(
      '$duration/week',
      name: 'planningWeeklyDuration',
      desc: '',
      args: [duration],
    );
  }

  /// `Week A: {durationA} | Week B: {durationB} | Tot: {totalDuration}`
  String planningBiweeklyDuration(
    String durationA,
    String durationB,
    String totalDuration,
  ) {
    return Intl.message(
      'Week A: $durationA | Week B: $durationB | Tot: $totalDuration',
      name: 'planningBiweeklyDuration',
      desc: '',
      args: [durationA, durationB, totalDuration],
    );
  }

  /// `Show expired ({count})`
  String planningShowExpired(int count) {
    return Intl.message(
      'Show expired ($count)',
      name: 'planningShowExpired',
      desc: '',
      args: [count],
    );
  }

  /// `Hide expired`
  String get planningHideExpired {
    return Intl.message(
      'Hide expired',
      name: 'planningHideExpired',
      desc: '',
      args: [],
    );
  }

  /// `Set end date`
  String get planningSetEndDate {
    return Intl.message(
      'Set end date',
      name: 'planningSetEndDate',
      desc: '',
      args: [],
    );
  }

  /// `Select date`
  String get planningSelectDate {
    return Intl.message(
      'Select date',
      name: 'planningSelectDate',
      desc: '',
      args: [],
    );
  }

  /// `Planning`
  String get planningListTitle {
    return Intl.message(
      'Planning',
      name: 'planningListTitle',
      desc: '',
      args: [],
    );
  }

  /// `No planning defined`
  String get planningListEmpty {
    return Intl.message(
      'No planning defined',
      name: 'planningListEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Add planning`
  String get planningListAdd {
    return Intl.message(
      'Add planning',
      name: 'planningListAdd',
      desc: '',
      args: [],
    );
  }

  /// `Week A`
  String get planningWeekA {
    return Intl.message('Week A', name: 'planningWeekA', desc: '', args: []);
  }

  /// `Week B`
  String get planningWeekB {
    return Intl.message('Week B', name: 'planningWeekB', desc: '', args: []);
  }

  /// `Current week: {week}`
  String planningCurrentWeek(String week) {
    return Intl.message(
      'Current week: $week',
      name: 'planningCurrentWeek',
      desc: '',
      args: [week],
    );
  }

  /// `From {from} to {to}`
  String planningValidityRange(String from, String to) {
    return Intl.message(
      'From $from to $to',
      name: 'planningValidityRange',
      desc: '',
      args: [from, to],
    );
  }

  /// `From {from}`
  String planningValidityFrom(String from) {
    return Intl.message(
      'From $from',
      name: 'planningValidityFrom',
      desc: '',
      args: [from],
    );
  }

  /// `Active`
  String get planningActive {
    return Intl.message('Active', name: 'planningActive', desc: '', args: []);
  }

  /// `Future`
  String get planningFuture {
    return Intl.message('Future', name: 'planningFuture', desc: '', args: []);
  }

  /// `Past`
  String get planningPast {
    return Intl.message('Past', name: 'planningPast', desc: '', args: []);
  }

  /// `Price`
  String get appointmentPriceLabel {
    return Intl.message(
      'Price',
      name: 'appointmentPriceLabel',
      desc: '',
      args: [],
    );
  }

  /// `Custom price`
  String get appointmentPriceHint {
    return Intl.message(
      'Custom price',
      name: 'appointmentPriceHint',
      desc: '',
      args: [],
    );
  }

  /// `Reset to service price`
  String get appointmentPriceResetTooltip {
    return Intl.message(
      'Reset to service price',
      name: 'appointmentPriceResetTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Free`
  String get appointmentPriceFree {
    return Intl.message(
      'Free',
      name: 'appointmentPriceFree',
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

  /// `Email sent to customer`
  String get bookingHistoryEventNotificationSent {
    return Intl.message(
      'Email sent to customer',
      name: 'bookingHistoryEventNotificationSent',
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

  /// `Booking rescheduled`
  String get bookingHistoryEventReplaced {
    return Intl.message(
      'Booking rescheduled',
      name: 'bookingHistoryEventReplaced',
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

  /// `Customer`
  String get bookingHistoryActorCustomer {
    return Intl.message(
      'Customer',
      name: 'bookingHistoryActorCustomer',
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

  /// `Type: {channel}`
  String bookingHistoryNotificationChannel(Object channel) {
    return Intl.message(
      'Type: $channel',
      name: 'bookingHistoryNotificationChannel',
      desc: '',
      args: [channel],
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

  /// `Subject: {subject}`
  String bookingHistoryNotificationSubject(Object subject) {
    return Intl.message(
      'Subject: $subject',
      name: 'bookingHistoryNotificationSubject',
      desc: '',
      args: [subject],
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

  /// `CANCELLED`
  String get clientAppointmentsCancelledBadge {
    return Intl.message(
      'CANCELLED',
      name: 'clientAppointmentsCancelledBadge',
      desc: '',
      args: [],
    );
  }

  /// `Repeat this appointment`
  String get recurrenceRepeatBooking {
    return Intl.message(
      'Repeat this appointment',
      name: 'recurrenceRepeatBooking',
      desc: '',
      args: [],
    );
  }

  /// `Repeat this block`
  String get recurrenceRepeatBlock {
    return Intl.message(
      'Repeat this block',
      name: 'recurrenceRepeatBlock',
      desc: '',
      args: [],
    );
  }

  /// `Frequency`
  String get recurrenceFrequency {
    return Intl.message(
      'Frequency',
      name: 'recurrenceFrequency',
      desc: '',
      args: [],
    );
  }

  /// `Every`
  String get recurrenceEvery {
    return Intl.message('Every', name: 'recurrenceEvery', desc: '', args: []);
  }

  /// `day`
  String get recurrenceDay {
    return Intl.message('day', name: 'recurrenceDay', desc: '', args: []);
  }

  /// `days`
  String get recurrenceDays {
    return Intl.message('days', name: 'recurrenceDays', desc: '', args: []);
  }

  /// `week`
  String get recurrenceWeek {
    return Intl.message('week', name: 'recurrenceWeek', desc: '', args: []);
  }

  /// `weeks`
  String get recurrenceWeeks {
    return Intl.message('weeks', name: 'recurrenceWeeks', desc: '', args: []);
  }

  /// `month`
  String get recurrenceMonth {
    return Intl.message('month', name: 'recurrenceMonth', desc: '', args: []);
  }

  /// `months`
  String get recurrenceMonths {
    return Intl.message('months', name: 'recurrenceMonths', desc: '', args: []);
  }

  /// `Ends`
  String get recurrenceEnds {
    return Intl.message('Ends', name: 'recurrenceEnds', desc: '', args: []);
  }

  /// `For one year`
  String get recurrenceNever {
    return Intl.message(
      'For one year',
      name: 'recurrenceNever',
      desc: '',
      args: [],
    );
  }

  /// `After`
  String get recurrenceAfter {
    return Intl.message('After', name: 'recurrenceAfter', desc: '', args: []);
  }

  /// `occurrences`
  String get recurrenceOccurrences {
    return Intl.message(
      'occurrences',
      name: 'recurrenceOccurrences',
      desc: '',
      args: [],
    );
  }

  /// `On`
  String get recurrenceOnDate {
    return Intl.message('On', name: 'recurrenceOnDate', desc: '', args: []);
  }

  /// `Select date`
  String get recurrenceSelectDate {
    return Intl.message(
      'Select date',
      name: 'recurrenceSelectDate',
      desc: '',
      args: [],
    );
  }

  /// `Appointment preview`
  String get recurrencePreviewTitle {
    return Intl.message(
      'Appointment preview',
      name: 'recurrencePreviewTitle',
      desc: '',
      args: [],
    );
  }

  /// `{count} appointments`
  String recurrencePreviewCount(int count) {
    return Intl.message(
      '$count appointments',
      name: 'recurrencePreviewCount',
      desc: '',
      args: [count],
    );
  }

  /// `{count} selected`
  String recurrencePreviewSelected(int count) {
    return Intl.message(
      '$count selected',
      name: 'recurrencePreviewSelected',
      desc: '',
      args: [count],
    );
  }

  /// `{count} conflicts`
  String recurrencePreviewConflicts(int count) {
    return Intl.message(
      '$count conflicts',
      name: 'recurrencePreviewConflicts',
      desc: '',
      args: [count],
    );
  }

  /// `Uncheck the dates you don't want to create`
  String get recurrencePreviewHint {
    return Intl.message(
      'Uncheck the dates you don\'t want to create',
      name: 'recurrencePreviewHint',
      desc: '',
      args: [],
    );
  }

  /// `Skip due to conflict`
  String get recurrencePreviewConflictSkip {
    return Intl.message(
      'Skip due to conflict',
      name: 'recurrencePreviewConflictSkip',
      desc: '',
      args: [],
    );
  }

  /// `Create anyway`
  String get recurrencePreviewConflictForce {
    return Intl.message(
      'Create anyway',
      name: 'recurrencePreviewConflictForce',
      desc: '',
      args: [],
    );
  }

  /// `Create {count} appointments`
  String recurrencePreviewConfirm(int count) {
    return Intl.message(
      'Create $count appointments',
      name: 'recurrencePreviewConfirm',
      desc: '',
      args: [count],
    );
  }

  /// `Series created`
  String get recurrenceSummaryTitle {
    return Intl.message(
      'Series created',
      name: 'recurrenceSummaryTitle',
      desc: '',
      args: [],
    );
  }

  /// `{count} appointments created`
  String recurrenceSummaryCreated(int count) {
    return Intl.message(
      '$count appointments created',
      name: 'recurrenceSummaryCreated',
      desc: '',
      args: [count],
    );
  }

  /// `{count} skipped due to conflicts`
  String recurrenceSummarySkipped(int count) {
    return Intl.message(
      '$count skipped due to conflicts',
      name: 'recurrenceSummarySkipped',
      desc: '',
      args: [count],
    );
  }

  /// `Error creating series`
  String get recurrenceSummaryError {
    return Intl.message(
      'Error creating series',
      name: 'recurrenceSummaryError',
      desc: '',
      args: [],
    );
  }

  /// `Appointments:`
  String get recurrenceSummaryAppointments {
    return Intl.message(
      'Appointments:',
      name: 'recurrenceSummaryAppointments',
      desc: '',
      args: [],
    );
  }

  /// `Skipped due to conflict`
  String get recurrenceSummaryConflict {
    return Intl.message(
      'Skipped due to conflict',
      name: 'recurrenceSummaryConflict',
      desc: '',
      args: [],
    );
  }

  /// `Deleted`
  String get recurrenceSummaryDeleted {
    return Intl.message(
      'Deleted',
      name: 'recurrenceSummaryDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Recurring appointment`
  String get recurrenceSeriesIcon {
    return Intl.message(
      'Recurring appointment',
      name: 'recurrenceSeriesIcon',
      desc: '',
      args: [],
    );
  }

  /// `{index} of {total}`
  String recurrenceSeriesOf(int index, int total) {
    return Intl.message(
      '$index of $total',
      name: 'recurrenceSeriesOf',
      desc: '',
      args: [index, total],
    );
  }

  /// `Delete recurring appointment`
  String get recurringDeleteTitle {
    return Intl.message(
      'Delete recurring appointment',
      name: 'recurringDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `This is appointment {index} of {total} in the series.`
  String recurringDeleteMessage(int index, int total) {
    return Intl.message(
      'This is appointment $index of $total in the series.',
      name: 'recurringDeleteMessage',
      desc: '',
      args: [index, total],
    );
  }

  /// `Which appointments do you want to delete?`
  String get recurringDeleteChooseScope {
    return Intl.message(
      'Which appointments do you want to delete?',
      name: 'recurringDeleteChooseScope',
      desc: '',
      args: [],
    );
  }

  /// `Edit recurring appointment`
  String get recurringEditTitle {
    return Intl.message(
      'Edit recurring appointment',
      name: 'recurringEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `This is appointment {index} of {total} in the series.`
  String recurringEditMessage(int index, int total) {
    return Intl.message(
      'This is appointment $index of $total in the series.',
      name: 'recurringEditMessage',
      desc: '',
      args: [index, total],
    );
  }

  /// `Which appointments do you want to edit?`
  String get recurringEditChooseScope {
    return Intl.message(
      'Which appointments do you want to edit?',
      name: 'recurringEditChooseScope',
      desc: '',
      args: [],
    );
  }

  /// `Only this one`
  String get recurringScopeOnlyThis {
    return Intl.message(
      'Only this one',
      name: 'recurringScopeOnlyThis',
      desc: '',
      args: [],
    );
  }

  /// `This and future`
  String get recurringScopeThisAndFuture {
    return Intl.message(
      'This and future',
      name: 'recurringScopeThisAndFuture',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get recurringScopeAll {
    return Intl.message('All', name: 'recurringScopeAll', desc: '', args: []);
  }

  /// `Total duration: {duration}`
  String bookingTotalDuration(String duration) {
    return Intl.message(
      'Total duration: $duration',
      name: 'bookingTotalDuration',
      desc: '',
      args: [duration],
    );
  }

  /// `Total: {price}`
  String bookingTotalPrice(String price) {
    return Intl.message(
      'Total: $price',
      name: 'bookingTotalPrice',
      desc: '',
      args: [price],
    );
  }

  /// `A client must be selected for recurring appointments`
  String get recurrenceClientRequired {
    return Intl.message(
      'A client must be selected for recurring appointments',
      name: 'recurrenceClientRequired',
      desc: '',
      args: [],
    );
  }

  /// `Overlaps`
  String get recurrenceConflictHandling {
    return Intl.message(
      'Overlaps',
      name: 'recurrenceConflictHandling',
      desc: '',
      args: [],
    );
  }

  /// `Skip conflicting dates`
  String get recurrenceConflictSkip {
    return Intl.message(
      'Skip conflicting dates',
      name: 'recurrenceConflictSkip',
      desc: '',
      args: [],
    );
  }

  /// `Don't create appointments if there are overlaps`
  String get recurrenceConflictSkipDescription {
    return Intl.message(
      'Don\'t create appointments if there are overlaps',
      name: 'recurrenceConflictSkipDescription',
      desc: '',
      args: [],
    );
  }

  /// `Create anyway`
  String get recurrenceConflictForce {
    return Intl.message(
      'Create anyway',
      name: 'recurrenceConflictForce',
      desc: '',
      args: [],
    );
  }

  /// `Create appointments even if there are overlaps`
  String get recurrenceConflictForceDescription {
    return Intl.message(
      'Create appointments even if there are overlaps',
      name: 'recurrenceConflictForceDescription',
      desc: '',
      args: [],
    );
  }

  /// `Reports`
  String get reportsTitle {
    return Intl.message('Reports', name: 'reportsTitle', desc: '', args: []);
  }

  /// `No data available`
  String get reportsNoData {
    return Intl.message(
      'No data available',
      name: 'reportsNoData',
      desc: '',
      args: [],
    );
  }

  /// `Refresh`
  String get actionRefresh {
    return Intl.message('Refresh', name: 'actionRefresh', desc: '', args: []);
  }

  /// `Period presets`
  String get reportsPresets {
    return Intl.message(
      'Period presets',
      name: 'reportsPresets',
      desc: '',
      args: [],
    );
  }

  /// `Choose period`
  String get reportsPresetCustom {
    return Intl.message(
      'Choose period',
      name: 'reportsPresetCustom',
      desc: '',
      args: [],
    );
  }

  /// `Today`
  String get reportsPresetToday {
    return Intl.message(
      'Today',
      name: 'reportsPresetToday',
      desc: '',
      args: [],
    );
  }

  /// `Yesterday`
  String get reportsPresetYesterday {
    return Intl.message(
      'Yesterday',
      name: 'reportsPresetYesterday',
      desc: '',
      args: [],
    );
  }

  /// `This week`
  String get reportsPresetWeek {
    return Intl.message(
      'This week',
      name: 'reportsPresetWeek',
      desc: '',
      args: [],
    );
  }

  /// `Current month`
  String get reportsPresetMonth {
    return Intl.message(
      'Current month',
      name: 'reportsPresetMonth',
      desc: '',
      args: [],
    );
  }

  /// `Last month`
  String get reportsPresetLastMonth {
    return Intl.message(
      'Last month',
      name: 'reportsPresetLastMonth',
      desc: '',
      args: [],
    );
  }

  /// `Current quarter`
  String get reportsPresetQuarter {
    return Intl.message(
      'Current quarter',
      name: 'reportsPresetQuarter',
      desc: '',
      args: [],
    );
  }

  /// `Current semester`
  String get reportsPresetSemester {
    return Intl.message(
      'Current semester',
      name: 'reportsPresetSemester',
      desc: '',
      args: [],
    );
  }

  /// `Current year`
  String get reportsPresetYear {
    return Intl.message(
      'Current year',
      name: 'reportsPresetYear',
      desc: '',
      args: [],
    );
  }

  /// `Last 3 months`
  String get reportsPresetLast3Months {
    return Intl.message(
      'Last 3 months',
      name: 'reportsPresetLast3Months',
      desc: '',
      args: [],
    );
  }

  /// `Last 6 months`
  String get reportsPresetLast6Months {
    return Intl.message(
      'Last 6 months',
      name: 'reportsPresetLast6Months',
      desc: '',
      args: [],
    );
  }

  /// `Previous year`
  String get reportsPresetLastYear {
    return Intl.message(
      'Previous year',
      name: 'reportsPresetLastYear',
      desc: '',
      args: [],
    );
  }

  /// `Include full period (future included)`
  String get reportsFullPeriodToggle {
    return Intl.message(
      'Include full period (future included)',
      name: 'reportsFullPeriodToggle',
      desc: '',
      args: [],
    );
  }

  /// `Locations`
  String get reportsFilterLocations {
    return Intl.message(
      'Locations',
      name: 'reportsFilterLocations',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get reportsFilterStaff {
    return Intl.message(
      'Staff',
      name: 'reportsFilterStaff',
      desc: '',
      args: [],
    );
  }

  /// `Services`
  String get reportsFilterServices {
    return Intl.message(
      'Services',
      name: 'reportsFilterServices',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get reportsFilterStatus {
    return Intl.message(
      'Status',
      name: 'reportsFilterStatus',
      desc: '',
      args: [],
    );
  }

  /// `Confirmed`
  String get statusConfirmed {
    return Intl.message(
      'Confirmed',
      name: 'statusConfirmed',
      desc: '',
      args: [],
    );
  }

  /// `Completed`
  String get statusCompleted {
    return Intl.message(
      'Completed',
      name: 'statusCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled`
  String get statusCancelled {
    return Intl.message(
      'Cancelled',
      name: 'statusCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Select all`
  String get actionSelectAll {
    return Intl.message(
      'Select all',
      name: 'actionSelectAll',
      desc: '',
      args: [],
    );
  }

  /// `Deselect all`
  String get actionDeselectAll {
    return Intl.message(
      'Deselect all',
      name: 'actionDeselectAll',
      desc: '',
      args: [],
    );
  }

  /// `Apply`
  String get actionApply {
    return Intl.message('Apply', name: 'actionApply', desc: '', args: []);
  }

  /// `Appointments`
  String get reportsTotalAppointments {
    return Intl.message(
      'Appointments',
      name: 'reportsTotalAppointments',
      desc: '',
      args: [],
    );
  }

  /// `Revenue`
  String get reportsTotalRevenue {
    return Intl.message(
      'Revenue',
      name: 'reportsTotalRevenue',
      desc: '',
      args: [],
    );
  }

  /// `Total collected`
  String get reportsAppointmentsAmount {
    return Intl.message(
      'Total collected',
      name: 'reportsAppointmentsAmount',
      desc: '',
      args: [],
    );
  }

  /// `Hours worked`
  String get reportsTotalHours {
    return Intl.message(
      'Hours worked',
      name: 'reportsTotalHours',
      desc: '',
      args: [],
    );
  }

  /// `Occupancy`
  String get reportsOccupancyPercentage {
    return Intl.message(
      'Occupancy',
      name: 'reportsOccupancyPercentage',
      desc: '',
      args: [],
    );
  }

  /// `Unique clients`
  String get reportsUniqueClients {
    return Intl.message(
      'Unique clients',
      name: 'reportsUniqueClients',
      desc: '',
      args: [],
    );
  }

  /// `By staff`
  String get reportsByStaff {
    return Intl.message('By staff', name: 'reportsByStaff', desc: '', args: []);
  }

  /// `By location`
  String get reportsByLocation {
    return Intl.message(
      'By location',
      name: 'reportsByLocation',
      desc: '',
      args: [],
    );
  }

  /// `By service`
  String get reportsByService {
    return Intl.message(
      'By service',
      name: 'reportsByService',
      desc: '',
      args: [],
    );
  }

  /// `By day of week`
  String get reportsByDayOfWeek {
    return Intl.message(
      'By day of week',
      name: 'reportsByDayOfWeek',
      desc: '',
      args: [],
    );
  }

  /// `By period`
  String get reportsByPeriod {
    return Intl.message(
      'By period',
      name: 'reportsByPeriod',
      desc: '',
      args: [],
    );
  }

  /// `By hour`
  String get reportsByHour {
    return Intl.message('By hour', name: 'reportsByHour', desc: '', args: []);
  }

  /// `Staff`
  String get reportsWorkHoursTitle {
    return Intl.message(
      'Staff',
      name: 'reportsWorkHoursTitle',
      desc: '',
      args: [],
    );
  }

  /// `Appointments`
  String get reportsTabAppointments {
    return Intl.message(
      'Appointments',
      name: 'reportsTabAppointments',
      desc: '',
      args: [],
    );
  }

  /// `Team`
  String get reportsTabStaff {
    return Intl.message('Team', name: 'reportsTabStaff', desc: '', args: []);
  }

  /// `Summary of scheduled, worked hours and absences`
  String get reportsWorkHoursSubtitle {
    return Intl.message(
      'Summary of scheduled, worked hours and absences',
      name: 'reportsWorkHoursSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Scheduled`
  String get reportsWorkHoursScheduled {
    return Intl.message(
      'Scheduled',
      name: 'reportsWorkHoursScheduled',
      desc: '',
      args: [],
    );
  }

  /// `Booked`
  String get reportsWorkHoursWorked {
    return Intl.message(
      'Booked',
      name: 'reportsWorkHoursWorked',
      desc: '',
      args: [],
    );
  }

  /// `Blocked`
  String get reportsWorkHoursBlocked {
    return Intl.message(
      'Blocked',
      name: 'reportsWorkHoursBlocked',
      desc: '',
      args: [],
    );
  }

  /// `Time Off`
  String get reportsWorkHoursOff {
    return Intl.message(
      'Time Off',
      name: 'reportsWorkHoursOff',
      desc: '',
      args: [],
    );
  }

  /// `Effective`
  String get reportsWorkHoursAvailable {
    return Intl.message(
      'Effective',
      name: 'reportsWorkHoursAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Occupancy`
  String get reportsWorkHoursUtilization {
    return Intl.message(
      'Occupancy',
      name: 'reportsWorkHoursUtilization',
      desc: '',
      args: [],
    );
  }

  /// `Scheduled`
  String get reportsColScheduledHours {
    return Intl.message(
      'Scheduled',
      name: 'reportsColScheduledHours',
      desc: '',
      args: [],
    );
  }

  /// `Booked`
  String get reportsColWorkedHours {
    return Intl.message(
      'Booked',
      name: 'reportsColWorkedHours',
      desc: '',
      args: [],
    );
  }

  /// `Blocked`
  String get reportsColBlockedHours {
    return Intl.message(
      'Blocked',
      name: 'reportsColBlockedHours',
      desc: '',
      args: [],
    );
  }

  /// `Time Off`
  String get reportsColOffHours {
    return Intl.message(
      'Time Off',
      name: 'reportsColOffHours',
      desc: '',
      args: [],
    );
  }

  /// `Effective`
  String get reportsColAvailableHours {
    return Intl.message(
      'Effective',
      name: 'reportsColAvailableHours',
      desc: '',
      args: [],
    );
  }

  /// `Occupancy`
  String get reportsColUtilization {
    return Intl.message(
      'Occupancy',
      name: 'reportsColUtilization',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get reportsColStaff {
    return Intl.message('Staff', name: 'reportsColStaff', desc: '', args: []);
  }

  /// `Appointments`
  String get reportsColAppointments {
    return Intl.message(
      'Appointments',
      name: 'reportsColAppointments',
      desc: '',
      args: [],
    );
  }

  /// `Amount`
  String get reportsColRevenue {
    return Intl.message(
      'Amount',
      name: 'reportsColRevenue',
      desc: '',
      args: [],
    );
  }

  /// `Hours`
  String get reportsColHours {
    return Intl.message('Hours', name: 'reportsColHours', desc: '', args: []);
  }

  /// `Average`
  String get reportsColAvgRevenue {
    return Intl.message(
      'Average',
      name: 'reportsColAvgRevenue',
      desc: '',
      args: [],
    );
  }

  /// `%`
  String get reportsColPercentage {
    return Intl.message('%', name: 'reportsColPercentage', desc: '', args: []);
  }

  /// `Location`
  String get reportsColLocation {
    return Intl.message(
      'Location',
      name: 'reportsColLocation',
      desc: '',
      args: [],
    );
  }

  /// `Service`
  String get reportsColService {
    return Intl.message(
      'Service',
      name: 'reportsColService',
      desc: '',
      args: [],
    );
  }

  /// `Category`
  String get reportsColCategory {
    return Intl.message(
      'Category',
      name: 'reportsColCategory',
      desc: '',
      args: [],
    );
  }

  /// `Avg. duration`
  String get reportsColAvgDuration {
    return Intl.message(
      'Avg. duration',
      name: 'reportsColAvgDuration',
      desc: '',
      args: [],
    );
  }

  /// `Day`
  String get reportsColDay {
    return Intl.message('Day', name: 'reportsColDay', desc: '', args: []);
  }

  /// `Period`
  String get reportsColPeriod {
    return Intl.message('Period', name: 'reportsColPeriod', desc: '', args: []);
  }

  /// `Hour`
  String get reportsColHour {
    return Intl.message('Hour', name: 'reportsColHour', desc: '', args: []);
  }

  /// `Monday`
  String get dayMonday {
    return Intl.message('Monday', name: 'dayMonday', desc: '', args: []);
  }

  /// `Tuesday`
  String get dayTuesday {
    return Intl.message('Tuesday', name: 'dayTuesday', desc: '', args: []);
  }

  /// `Wednesday`
  String get dayWednesday {
    return Intl.message('Wednesday', name: 'dayWednesday', desc: '', args: []);
  }

  /// `Thursday`
  String get dayThursday {
    return Intl.message('Thursday', name: 'dayThursday', desc: '', args: []);
  }

  /// `Friday`
  String get dayFriday {
    return Intl.message('Friday', name: 'dayFriday', desc: '', args: []);
  }

  /// `Saturday`
  String get daySaturday {
    return Intl.message('Saturday', name: 'daySaturday', desc: '', args: []);
  }

  /// `Sunday`
  String get daySunday {
    return Intl.message('Sunday', name: 'daySunday', desc: '', args: []);
  }

  /// `Required resources`
  String get serviceRequiredResourcesLabel {
    return Intl.message(
      'Required resources',
      name: 'serviceRequiredResourcesLabel',
      desc: '',
      args: [],
    );
  }

  /// `No resources required`
  String get resourceNoneLabel {
    return Intl.message(
      'No resources required',
      name: 'resourceNoneLabel',
      desc: '',
      args: [],
    );
  }

  /// `Select resources`
  String get resourceSelectLabel {
    return Intl.message(
      'Select resources',
      name: 'resourceSelectLabel',
      desc: '',
      args: [],
    );
  }

  /// `Resources`
  String get resourcesTitle {
    return Intl.message(
      'Resources',
      name: 'resourcesTitle',
      desc: '',
      args: [],
    );
  }

  /// `No resources configured for this location`
  String get resourcesEmpty {
    return Intl.message(
      'No resources configured for this location',
      name: 'resourcesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Resources are equipment or spaces (e.g., cabins, beds) that can be associated with services`
  String get resourcesEmptyHint {
    return Intl.message(
      'Resources are equipment or spaces (e.g., cabins, beds) that can be associated with services',
      name: 'resourcesEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `New resource`
  String get resourceNew {
    return Intl.message(
      'New resource',
      name: 'resourceNew',
      desc: '',
      args: [],
    );
  }

  /// `Edit resource`
  String get resourceEdit {
    return Intl.message(
      'Edit resource',
      name: 'resourceEdit',
      desc: '',
      args: [],
    );
  }

  /// `Resource name`
  String get resourceNameLabel {
    return Intl.message(
      'Resource name',
      name: 'resourceNameLabel',
      desc: '',
      args: [],
    );
  }

  /// `Available quantity`
  String get resourceQuantityLabel {
    return Intl.message(
      'Available quantity',
      name: 'resourceQuantityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Type (optional)`
  String get resourceTypeLabel {
    return Intl.message(
      'Type (optional)',
      name: 'resourceTypeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Notes (optional)`
  String get resourceNoteLabel {
    return Intl.message(
      'Notes (optional)',
      name: 'resourceNoteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Delete this resource?`
  String get resourceDeleteConfirm {
    return Intl.message(
      'Delete this resource?',
      name: 'resourceDeleteConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Services using this resource will no longer be constrained by its availability`
  String get resourceDeleteWarning {
    return Intl.message(
      'Services using this resource will no longer be constrained by its availability',
      name: 'resourceDeleteWarning',
      desc: '',
      args: [],
    );
  }

  /// `Services using this resource`
  String get resourceServicesLabel {
    return Intl.message(
      'Services using this resource',
      name: 'resourceServicesLabel',
      desc: '',
      args: [],
    );
  }

  /// `No services associated`
  String get resourceNoServicesSelected {
    return Intl.message(
      'No services associated',
      name: 'resourceNoServicesSelected',
      desc: '',
      args: [],
    );
  }

  /// `Select services`
  String get resourceSelectServices {
    return Intl.message(
      'Select services',
      name: 'resourceSelectServices',
      desc: '',
      args: [],
    );
  }

  /// `1 service`
  String get resourceServiceCountSingular {
    return Intl.message(
      '1 service',
      name: 'resourceServiceCountSingular',
      desc: '',
      args: [],
    );
  }

  /// `{count} services`
  String resourceServiceCountPlural(int count) {
    return Intl.message(
      '$count services',
      name: 'resourceServiceCountPlural',
      desc: '',
      args: [count],
    );
  }

  /// `Qty required`
  String get resourceQuantityRequired {
    return Intl.message(
      'Qty required',
      name: 'resourceQuantityRequired',
      desc: '',
      args: [],
    );
  }

  /// `Bookings List`
  String get bookingsListTitle {
    return Intl.message(
      'Bookings List',
      name: 'bookingsListTitle',
      desc: '',
      args: [],
    );
  }

  /// `No bookings found`
  String get bookingsListEmpty {
    return Intl.message(
      'No bookings found',
      name: 'bookingsListEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Try adjusting your search filters`
  String get bookingsListEmptyHint {
    return Intl.message(
      'Try adjusting your search filters',
      name: 'bookingsListEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `Filters`
  String get bookingsListFilterTitle {
    return Intl.message(
      'Filters',
      name: 'bookingsListFilterTitle',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get bookingsListFilterLocation {
    return Intl.message(
      'Location',
      name: 'bookingsListFilterLocation',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get bookingsListFilterStaff {
    return Intl.message(
      'Staff',
      name: 'bookingsListFilterStaff',
      desc: '',
      args: [],
    );
  }

  /// `Service`
  String get bookingsListFilterService {
    return Intl.message(
      'Service',
      name: 'bookingsListFilterService',
      desc: '',
      args: [],
    );
  }

  /// `Search client`
  String get bookingsListFilterClient {
    return Intl.message(
      'Search client',
      name: 'bookingsListFilterClient',
      desc: '',
      args: [],
    );
  }

  /// `Name, email or phone`
  String get bookingsListFilterClientHint {
    return Intl.message(
      'Name, email or phone',
      name: 'bookingsListFilterClientHint',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get bookingsListFilterStatus {
    return Intl.message(
      'Status',
      name: 'bookingsListFilterStatus',
      desc: '',
      args: [],
    );
  }

  /// `Period`
  String get bookingsListFilterPeriod {
    return Intl.message(
      'Period',
      name: 'bookingsListFilterPeriod',
      desc: '',
      args: [],
    );
  }

  /// `Include past`
  String get bookingsListFilterIncludePast {
    return Intl.message(
      'Include past',
      name: 'bookingsListFilterIncludePast',
      desc: '',
      args: [],
    );
  }

  /// `Future only`
  String get bookingsListFilterFutureOnly {
    return Intl.message(
      'Future only',
      name: 'bookingsListFilterFutureOnly',
      desc: '',
      args: [],
    );
  }

  /// `Appointment date`
  String get bookingsListSortByAppointment {
    return Intl.message(
      'Appointment date',
      name: 'bookingsListSortByAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Creation date`
  String get bookingsListSortByCreated {
    return Intl.message(
      'Creation date',
      name: 'bookingsListSortByCreated',
      desc: '',
      args: [],
    );
  }

  /// `Ascending`
  String get bookingsListSortAsc {
    return Intl.message(
      'Ascending',
      name: 'bookingsListSortAsc',
      desc: '',
      args: [],
    );
  }

  /// `Descending`
  String get bookingsListSortDesc {
    return Intl.message(
      'Descending',
      name: 'bookingsListSortDesc',
      desc: '',
      args: [],
    );
  }

  /// `Date/Time`
  String get bookingsListColumnDateTime {
    return Intl.message(
      'Date/Time',
      name: 'bookingsListColumnDateTime',
      desc: '',
      args: [],
    );
  }

  /// `Created on`
  String get bookingsListColumnCreatedAt {
    return Intl.message(
      'Created on',
      name: 'bookingsListColumnCreatedAt',
      desc: '',
      args: [],
    );
  }

  /// `Created by`
  String get bookingsListColumnCreatedBy {
    return Intl.message(
      'Created by',
      name: 'bookingsListColumnCreatedBy',
      desc: '',
      args: [],
    );
  }

  /// `Client`
  String get bookingsListColumnClient {
    return Intl.message(
      'Client',
      name: 'bookingsListColumnClient',
      desc: '',
      args: [],
    );
  }

  /// `Services`
  String get bookingsListColumnServices {
    return Intl.message(
      'Services',
      name: 'bookingsListColumnServices',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get bookingsListColumnStaff {
    return Intl.message(
      'Staff',
      name: 'bookingsListColumnStaff',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get bookingsListColumnStatus {
    return Intl.message(
      'Status',
      name: 'bookingsListColumnStatus',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get bookingsListColumnPrice {
    return Intl.message(
      'Price',
      name: 'bookingsListColumnPrice',
      desc: '',
      args: [],
    );
  }

  /// `Actions`
  String get bookingsListColumnActions {
    return Intl.message(
      'Actions',
      name: 'bookingsListColumnActions',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get bookingsListActionEdit {
    return Intl.message(
      'Edit',
      name: 'bookingsListActionEdit',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get bookingsListActionCancel {
    return Intl.message(
      'Cancel',
      name: 'bookingsListActionCancel',
      desc: '',
      args: [],
    );
  }

  /// `Details`
  String get bookingsListActionView {
    return Intl.message(
      'Details',
      name: 'bookingsListActionView',
      desc: '',
      args: [],
    );
  }

  /// `Confirmed`
  String get bookingsListStatusConfirmed {
    return Intl.message(
      'Confirmed',
      name: 'bookingsListStatusConfirmed',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled`
  String get bookingsListStatusCancelled {
    return Intl.message(
      'Cancelled',
      name: 'bookingsListStatusCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Completed`
  String get bookingsListStatusCompleted {
    return Intl.message(
      'Completed',
      name: 'bookingsListStatusCompleted',
      desc: '',
      args: [],
    );
  }

  /// `No show`
  String get bookingsListStatusNoShow {
    return Intl.message(
      'No show',
      name: 'bookingsListStatusNoShow',
      desc: '',
      args: [],
    );
  }

  /// `Pending`
  String get bookingsListStatusPending {
    return Intl.message(
      'Pending',
      name: 'bookingsListStatusPending',
      desc: '',
      args: [],
    );
  }

  /// `Replaced`
  String get bookingsListStatusReplaced {
    return Intl.message(
      'Replaced',
      name: 'bookingsListStatusReplaced',
      desc: '',
      args: [],
    );
  }

  /// `Online`
  String get bookingsListSourceOnline {
    return Intl.message(
      'Online',
      name: 'bookingsListSourceOnline',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get bookingsListSourcePhone {
    return Intl.message(
      'Phone',
      name: 'bookingsListSourcePhone',
      desc: '',
      args: [],
    );
  }

  /// `Walk-in`
  String get bookingsListSourceWalkIn {
    return Intl.message(
      'Walk-in',
      name: 'bookingsListSourceWalkIn',
      desc: '',
      args: [],
    );
  }

  /// `Back office`
  String get bookingsListSourceInternal {
    return Intl.message(
      'Back office',
      name: 'bookingsListSourceInternal',
      desc: '',
      args: [],
    );
  }

  /// `{count} bookings`
  String bookingsListTotalCount(int count) {
    return Intl.message(
      '$count bookings',
      name: 'bookingsListTotalCount',
      desc: '',
      args: [count],
    );
  }

  /// `Load more`
  String get bookingsListLoadMore {
    return Intl.message(
      'Load more',
      name: 'bookingsListLoadMore',
      desc: '',
      args: [],
    );
  }

  /// `Reset filters`
  String get bookingsListResetFilters {
    return Intl.message(
      'Reset filters',
      name: 'bookingsListResetFilters',
      desc: '',
      args: [],
    );
  }

  /// `All locations`
  String get bookingsListAllLocations {
    return Intl.message(
      'All locations',
      name: 'bookingsListAllLocations',
      desc: '',
      args: [],
    );
  }

  /// `All staff`
  String get bookingsListAllStaff {
    return Intl.message(
      'All staff',
      name: 'bookingsListAllStaff',
      desc: '',
      args: [],
    );
  }

  /// `All services`
  String get bookingsListAllServices {
    return Intl.message(
      'All services',
      name: 'bookingsListAllServices',
      desc: '',
      args: [],
    );
  }

  /// `All statuses`
  String get bookingsListAllStatus {
    return Intl.message(
      'All statuses',
      name: 'bookingsListAllStatus',
      desc: '',
      args: [],
    );
  }

  /// `Cancel booking?`
  String get bookingsListCancelConfirmTitle {
    return Intl.message(
      'Cancel booking?',
      name: 'bookingsListCancelConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `This action cannot be undone.`
  String get bookingsListCancelConfirmMessage {
    return Intl.message(
      'This action cannot be undone.',
      name: 'bookingsListCancelConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Booking cancelled`
  String get bookingsListCancelSuccess {
    return Intl.message(
      'Booking cancelled',
      name: 'bookingsListCancelSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get bookingsListLoading {
    return Intl.message(
      'Loading...',
      name: 'bookingsListLoading',
      desc: '',
      args: [],
    );
  }

  /// `No client`
  String get bookingsListNoClient {
    return Intl.message(
      'No client',
      name: 'bookingsListNoClient',
      desc: '',
      args: [],
    );
  }

  /// `Manage services, categories and pricing`
  String get moreServicesDescription {
    return Intl.message(
      'Manage services, categories and pricing',
      name: 'moreServicesDescription',
      desc: '',
      args: [],
    );
  }

  /// `Manage business locations`
  String get moreLocationsDescription {
    return Intl.message(
      'Manage business locations',
      name: 'moreLocationsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Manage operators, locations and working hours`
  String get moreTeamDescription {
    return Intl.message(
      'Manage operators, locations and working hours',
      name: 'moreTeamDescription',
      desc: '',
      args: [],
    );
  }

  /// `View statistics and business performance`
  String get moreReportsDescription {
    return Intl.message(
      'View statistics and business performance',
      name: 'moreReportsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Browse booking history`
  String get moreBookingsDescription {
    return Intl.message(
      'Browse booking history',
      name: 'moreBookingsDescription',
      desc: '',
      args: [],
    );
  }

  /// `View booking notifications history`
  String get moreBookingNotificationsDescription {
    return Intl.message(
      'View booking notifications history',
      name: 'moreBookingNotificationsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Manage your personal data and credentials`
  String get moreProfileDescription {
    return Intl.message(
      'Manage your personal data and credentials',
      name: 'moreProfileDescription',
      desc: '',
      args: [],
    );
  }

  /// `Switch to another business`
  String get moreSwitchBusinessDescription {
    return Intl.message(
      'Switch to another business',
      name: 'moreSwitchBusinessDescription',
      desc: '',
      args: [],
    );
  }

  /// `Booking Notifications`
  String get bookingNotificationsTitle {
    return Intl.message(
      'Booking Notifications',
      name: 'bookingNotificationsTitle',
      desc: '',
      args: [],
    );
  }

  /// `{count} notifications`
  String bookingNotificationsTotalCount(int count) {
    return Intl.message(
      '$count notifications',
      name: 'bookingNotificationsTotalCount',
      desc: '',
      args: [count],
    );
  }

  /// `No notifications found`
  String get bookingNotificationsEmpty {
    return Intl.message(
      'No notifications found',
      name: 'bookingNotificationsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Try adjusting your search filters`
  String get bookingNotificationsEmptyHint {
    return Intl.message(
      'Try adjusting your search filters',
      name: 'bookingNotificationsEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `Load more`
  String get bookingNotificationsLoadMore {
    return Intl.message(
      'Load more',
      name: 'bookingNotificationsLoadMore',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get bookingNotificationsSearchLabel {
    return Intl.message(
      'Search',
      name: 'bookingNotificationsSearchLabel',
      desc: '',
      args: [],
    );
  }

  /// `Client, recipient, subject`
  String get bookingNotificationsSearchHint {
    return Intl.message(
      'Client, recipient, subject',
      name: 'bookingNotificationsSearchHint',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get bookingNotificationsFilterStatus {
    return Intl.message(
      'Status',
      name: 'bookingNotificationsFilterStatus',
      desc: '',
      args: [],
    );
  }

  /// `Type`
  String get bookingNotificationsFilterType {
    return Intl.message(
      'Type',
      name: 'bookingNotificationsFilterType',
      desc: '',
      args: [],
    );
  }

  /// `All statuses`
  String get bookingNotificationsStatusAll {
    return Intl.message(
      'All statuses',
      name: 'bookingNotificationsStatusAll',
      desc: '',
      args: [],
    );
  }

  /// `Pending`
  String get bookingNotificationsStatusPending {
    return Intl.message(
      'Pending',
      name: 'bookingNotificationsStatusPending',
      desc: '',
      args: [],
    );
  }

  /// `Processing`
  String get bookingNotificationsStatusProcessing {
    return Intl.message(
      'Processing',
      name: 'bookingNotificationsStatusProcessing',
      desc: '',
      args: [],
    );
  }

  /// `Sent`
  String get bookingNotificationsStatusSent {
    return Intl.message(
      'Sent',
      name: 'bookingNotificationsStatusSent',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get bookingNotificationsStatusFailed {
    return Intl.message(
      'Failed',
      name: 'bookingNotificationsStatusFailed',
      desc: '',
      args: [],
    );
  }

  /// `All types`
  String get bookingNotificationsTypeAll {
    return Intl.message(
      'All types',
      name: 'bookingNotificationsTypeAll',
      desc: '',
      args: [],
    );
  }

  /// `Booking created`
  String get bookingNotificationsChannelConfirmed {
    return Intl.message(
      'Booking created',
      name: 'bookingNotificationsChannelConfirmed',
      desc: '',
      args: [],
    );
  }

  /// `Booking rescheduled`
  String get bookingNotificationsChannelRescheduled {
    return Intl.message(
      'Booking rescheduled',
      name: 'bookingNotificationsChannelRescheduled',
      desc: '',
      args: [],
    );
  }

  /// `Booking cancelled`
  String get bookingNotificationsChannelCancelled {
    return Intl.message(
      'Booking cancelled',
      name: 'bookingNotificationsChannelCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Booking reminder`
  String get bookingNotificationsChannelReminder {
    return Intl.message(
      'Booking reminder',
      name: 'bookingNotificationsChannelReminder',
      desc: '',
      args: [],
    );
  }

  /// `Type`
  String get bookingNotificationsFieldType {
    return Intl.message(
      'Type',
      name: 'bookingNotificationsFieldType',
      desc: '',
      args: [],
    );
  }

  /// `Client`
  String get bookingNotificationsFieldClient {
    return Intl.message(
      'Client',
      name: 'bookingNotificationsFieldClient',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get bookingNotificationsFieldLocation {
    return Intl.message(
      'Location',
      name: 'bookingNotificationsFieldLocation',
      desc: '',
      args: [],
    );
  }

  /// `Appointment`
  String get bookingNotificationsFieldAppointment {
    return Intl.message(
      'Appointment',
      name: 'bookingNotificationsFieldAppointment',
      desc: '',
      args: [],
    );
  }

  /// `Recipient`
  String get bookingNotificationsFieldRecipient {
    return Intl.message(
      'Recipient',
      name: 'bookingNotificationsFieldRecipient',
      desc: '',
      args: [],
    );
  }

  /// `Created at`
  String get bookingNotificationsFieldCreatedAt {
    return Intl.message(
      'Created at',
      name: 'bookingNotificationsFieldCreatedAt',
      desc: '',
      args: [],
    );
  }

  /// `Last attempt`
  String get bookingNotificationsFieldLastAttemptAt {
    return Intl.message(
      'Last attempt',
      name: 'bookingNotificationsFieldLastAttemptAt',
      desc: '',
      args: [],
    );
  }

  /// `Sent at`
  String get bookingNotificationsFieldSentAt {
    return Intl.message(
      'Sent at',
      name: 'bookingNotificationsFieldSentAt',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get bookingNotificationsFieldError {
    return Intl.message(
      'Error',
      name: 'bookingNotificationsFieldError',
      desc: '',
      args: [],
    );
  }

  /// `Body`
  String get bookingNotificationsFieldBody {
    return Intl.message(
      'Body',
      name: 'bookingNotificationsFieldBody',
      desc: '',
      args: [],
    );
  }

  /// `View body`
  String get bookingNotificationsActionViewBody {
    return Intl.message(
      'View body',
      name: 'bookingNotificationsActionViewBody',
      desc: '',
      args: [],
    );
  }

  /// `Notification body`
  String get bookingNotificationsBodyDialogTitle {
    return Intl.message(
      'Notification body',
      name: 'bookingNotificationsBodyDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Notification body not available`
  String get bookingNotificationsBodyUnavailable {
    return Intl.message(
      'Notification body not available',
      name: 'bookingNotificationsBodyUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `No subject`
  String get bookingNotificationsNoSubject {
    return Intl.message(
      'No subject',
      name: 'bookingNotificationsNoSubject',
      desc: '',
      args: [],
    );
  }

  /// `N/A`
  String get bookingNotificationsNotAvailable {
    return Intl.message(
      'N/A',
      name: 'bookingNotificationsNotAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Online bookings notification email`
  String get businessOnlineBookingsNotificationEmailLabel {
    return Intl.message(
      'Online bookings notification email',
      name: 'businessOnlineBookingsNotificationEmailLabel',
      desc: '',
      args: [],
    );
  }

  /// `e.g. bookings@business.com`
  String get businessOnlineBookingsNotificationEmailHint {
    return Intl.message(
      'e.g. bookings@business.com',
      name: 'businessOnlineBookingsNotificationEmailHint',
      desc: '',
      args: [],
    );
  }

  /// `Receives notifications only when customers create/modify/cancel online bookings`
  String get businessOnlineBookingsNotificationEmailHelper {
    return Intl.message(
      'Receives notifications only when customers create/modify/cancel online bookings',
      name: 'businessOnlineBookingsNotificationEmailHelper',
      desc: '',
      args: [],
    );
  }

  /// `Service color palette`
  String get businessServiceColorPaletteLabel {
    return Intl.message(
      'Service color palette',
      name: 'businessServiceColorPaletteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Defines colors used in service selection and agenda cards`
  String get businessServiceColorPaletteHelper {
    return Intl.message(
      'Defines colors used in service selection and agenda cards',
      name: 'businessServiceColorPaletteHelper',
      desc: '',
      args: [],
    );
  }

  /// `Darker (recommended)`
  String get businessServiceColorPaletteEnhanced {
    return Intl.message(
      'Darker (recommended)',
      name: 'businessServiceColorPaletteEnhanced',
      desc: '',
      args: [],
    );
  }

  /// `Original`
  String get businessServiceColorPaletteLegacy {
    return Intl.message(
      'Original',
      name: 'businessServiceColorPaletteLegacy',
      desc: '',
      args: [],
    );
  }

  /// `Access other application features`
  String get moreSubtitle {
    return Intl.message(
      'Access other application features',
      name: 'moreSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Closure dates`
  String get closuresTitle {
    return Intl.message(
      'Closure dates',
      name: 'closuresTitle',
      desc: '',
      args: [],
    );
  }

  /// `From today`
  String get closuresFilterFromToday {
    return Intl.message(
      'From today',
      name: 'closuresFilterFromToday',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get closuresFilterAll {
    return Intl.message('All', name: 'closuresFilterAll', desc: '', args: []);
  }

  /// `No closures scheduled`
  String get closuresEmpty {
    return Intl.message(
      'No closures scheduled',
      name: 'closuresEmpty',
      desc: '',
      args: [],
    );
  }

  /// `No closures scheduled for the selected period`
  String get closuresEmptyForPeriod {
    return Intl.message(
      'No closures scheduled for the selected period',
      name: 'closuresEmptyForPeriod',
      desc: '',
      args: [],
    );
  }

  /// `Add business closure periods (e.g. holidays, vacations)`
  String get closuresEmptyHint {
    return Intl.message(
      'Add business closure periods (e.g. holidays, vacations)',
      name: 'closuresEmptyHint',
      desc: '',
      args: [],
    );
  }

  /// `Upcoming closures`
  String get closuresUpcoming {
    return Intl.message(
      'Upcoming closures',
      name: 'closuresUpcoming',
      desc: '',
      args: [],
    );
  }

  /// `Previous closures`
  String get closuresPast {
    return Intl.message(
      'Previous closures',
      name: 'closuresPast',
      desc: '',
      args: [],
    );
  }

  /// `for a total of {count, plural, =1{1 day} other{{count} days}}`
  String closuresTotalDays(int count) {
    return Intl.message(
      'for a total of ${Intl.plural(count, one: '1 day', other: '$count days')}',
      name: 'closuresTotalDays',
      desc: '',
      args: [count],
    );
  }

  /// `New closure`
  String get closuresNewTitle {
    return Intl.message(
      'New closure',
      name: 'closuresNewTitle',
      desc: '',
      args: [],
    );
  }

  /// `Edit closure`
  String get closuresEditTitle {
    return Intl.message(
      'Edit closure',
      name: 'closuresEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Start date`
  String get closuresStartDate {
    return Intl.message(
      'Start date',
      name: 'closuresStartDate',
      desc: '',
      args: [],
    );
  }

  /// `End date`
  String get closuresEndDate {
    return Intl.message(
      'End date',
      name: 'closuresEndDate',
      desc: '',
      args: [],
    );
  }

  /// `Reason (optional)`
  String get closuresReason {
    return Intl.message(
      'Reason (optional)',
      name: 'closuresReason',
      desc: '',
      args: [],
    );
  }

  /// `e.g. Holiday, Summer vacation, Maintenance...`
  String get closuresReasonHint {
    return Intl.message(
      'e.g. Holiday, Summer vacation, Maintenance...',
      name: 'closuresReasonHint',
      desc: '',
      args: [],
    );
  }

  /// `Delete this closure?`
  String get closuresDeleteConfirm {
    return Intl.message(
      'Delete this closure?',
      name: 'closuresDeleteConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Booking slots during this period will become available again.`
  String get closuresDeleteConfirmMessage {
    return Intl.message(
      'Booking slots during this period will become available again.',
      name: 'closuresDeleteConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Dates overlap with an existing closure`
  String get closuresOverlapError {
    return Intl.message(
      'Dates overlap with an existing closure',
      name: 'closuresOverlapError',
      desc: '',
      args: [],
    );
  }

  /// `End date must be equal to or after start date`
  String get closuresInvalidDateRange {
    return Intl.message(
      'End date must be equal to or after start date',
      name: 'closuresInvalidDateRange',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 day} other{{count} days}}`
  String closuresDays(int count) {
    return Intl.plural(
      count,
      one: '1 day',
      other: '$count days',
      name: 'closuresDays',
      desc: '',
      args: [count],
    );
  }

  /// `Single day`
  String get closuresSingleDay {
    return Intl.message(
      'Single day',
      name: 'closuresSingleDay',
      desc: '',
      args: [],
    );
  }

  /// `Date range`
  String get closuresDateRange {
    return Intl.message(
      'Date range',
      name: 'closuresDateRange',
      desc: '',
      args: [],
    );
  }

  /// `Closure added`
  String get closuresAddSuccess {
    return Intl.message(
      'Closure added',
      name: 'closuresAddSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Closure updated`
  String get closuresUpdateSuccess {
    return Intl.message(
      'Closure updated',
      name: 'closuresUpdateSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Closure deleted`
  String get closuresDeleteSuccess {
    return Intl.message(
      'Closure deleted',
      name: 'closuresDeleteSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Affected locations`
  String get closuresLocations {
    return Intl.message(
      'Affected locations',
      name: 'closuresLocations',
      desc: '',
      args: [],
    );
  }

  /// `Select all`
  String get closuresSelectAll {
    return Intl.message(
      'Select all',
      name: 'closuresSelectAll',
      desc: '',
      args: [],
    );
  }

  /// `Deselect all`
  String get closuresDeselectAll {
    return Intl.message(
      'Deselect all',
      name: 'closuresDeselectAll',
      desc: '',
      args: [],
    );
  }

  /// `Select at least one location`
  String get closuresSelectAtLeastOneLocation {
    return Intl.message(
      'Select at least one location',
      name: 'closuresSelectAtLeastOneLocation',
      desc: '',
      args: [],
    );
  }

  /// `No locations configured`
  String get closuresNoLocations {
    return Intl.message(
      'No locations configured',
      name: 'closuresNoLocations',
      desc: '',
      args: [],
    );
  }

  /// `All locations`
  String get closuresAllLocations {
    return Intl.message(
      'All locations',
      name: 'closuresAllLocations',
      desc: '',
      args: [],
    );
  }

  /// `Add closure`
  String get closuresAddButton {
    return Intl.message(
      'Add closure',
      name: 'closuresAddButton',
      desc: '',
      args: [],
    );
  }

  /// `Import national holidays`
  String get closuresImportHolidays {
    return Intl.message(
      'Import national holidays',
      name: 'closuresImportHolidays',
      desc: '',
      args: [],
    );
  }

  /// `Import national holidays`
  String get closuresImportHolidaysTitle {
    return Intl.message(
      'Import national holidays',
      name: 'closuresImportHolidaysTitle',
      desc: '',
      args: [],
    );
  }

  /// `Holidays are determined by an external service: Nager.Date`
  String get closuresImportHolidaysExternalSourceInfo {
    return Intl.message(
      'Holidays are determined by an external service: Nager.Date',
      name: 'closuresImportHolidaysExternalSourceInfo',
      desc: '',
      args: [],
    );
  }

  /// `Copy link`
  String get closuresImportHolidaysCopyLinkAction {
    return Intl.message(
      'Copy link',
      name: 'closuresImportHolidaysCopyLinkAction',
      desc: '',
      args: [],
    );
  }

  /// `Link copied`
  String get closuresImportHolidaysLinkCopied {
    return Intl.message(
      'Link copied',
      name: 'closuresImportHolidaysLinkCopied',
      desc: '',
      args: [],
    );
  }

  /// `Year:`
  String get closuresImportHolidaysYear {
    return Intl.message(
      'Year:',
      name: 'closuresImportHolidaysYear',
      desc: '',
      args: [],
    );
  }

  /// `Apply to locations:`
  String get closuresImportHolidaysLocations {
    return Intl.message(
      'Apply to locations:',
      name: 'closuresImportHolidaysLocations',
      desc: '',
      args: [],
    );
  }

  /// `Select holidays to import:`
  String get closuresImportHolidaysList {
    return Intl.message(
      'Select holidays to import:',
      name: 'closuresImportHolidaysList',
      desc: '',
      args: [],
    );
  }

  /// `Import {count, plural, =1{1 holiday} other{{count} holidays}}`
  String closuresImportHolidaysAction(int count) {
    return Intl.message(
      'Import ${Intl.plural(count, one: '1 holiday', other: '$count holidays')}',
      name: 'closuresImportHolidaysAction',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 holiday imported} other{{count} holidays imported}}`
  String closuresImportHolidaysSuccess(int count) {
    return Intl.plural(
      count,
      one: '1 holiday imported',
      other: '$count holidays imported',
      name: 'closuresImportHolidaysSuccess',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 holiday already added} other{{count} holidays already added}} (marked with ✓)`
  String closuresImportHolidaysAlreadyAdded(int count) {
    return Intl.message(
      '${Intl.plural(count, one: '1 holiday already added', other: '$count holidays already added')} (marked with ✓)',
      name: 'closuresImportHolidaysAlreadyAdded',
      desc: '',
      args: [count],
    );
  }

  /// `Automatic holidays are not available for the country configured in the location.`
  String get closuresImportHolidaysUnsupportedCountry {
    return Intl.message(
      'Automatic holidays are not available for the country configured in the location.',
      name: 'closuresImportHolidaysUnsupportedCountry',
      desc: '',
      args: [],
    );
  }

  /// `No classes in the selected day.`
  String get classEventsEmpty {
    return Intl.message(
      'No classes in the selected day.',
      name: 'classEventsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Classes`
  String get classEventsTitle {
    return Intl.message(
      'Classes',
      name: 'classEventsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Class`
  String get classEventsUntitled {
    return Intl.message(
      'Class',
      name: 'classEventsUntitled',
      desc: '',
      args: [],
    );
  }

  /// `Book`
  String get classEventsActionBook {
    return Intl.message(
      'Book',
      name: 'classEventsActionBook',
      desc: '',
      args: [],
    );
  }

  /// `Cancel booking`
  String get classEventsActionCancelBooking {
    return Intl.message(
      'Cancel booking',
      name: 'classEventsActionCancelBooking',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get classEventsAddButton {
    return Intl.message(
      'Add',
      name: 'classEventsAddButton',
      desc: '',
      args: [],
    );
  }

  /// `Scheduling`
  String get classEventsCreateTitle {
    return Intl.message(
      'Scheduling',
      name: 'classEventsCreateTitle',
      desc: '',
      args: [],
    );
  }

  /// `New schedule`
  String get classEventsNewScheduleButton {
    return Intl.message(
      'New schedule',
      name: 'classEventsNewScheduleButton',
      desc: '',
      args: [],
    );
  }

  /// `Edit scheduling`
  String get classEventsEditTitle {
    return Intl.message(
      'Edit scheduling',
      name: 'classEventsEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Edit mode`
  String get classEventsEditModeLabel {
    return Intl.message(
      'Edit mode',
      name: 'classEventsEditModeLabel',
      desc: '',
      args: [],
    );
  }

  /// `Title (optional)`
  String get classEventsFieldTitleOptional {
    return Intl.message(
      'Title (optional)',
      name: 'classEventsFieldTitleOptional',
      desc: '',
      args: [],
    );
  }

  /// `Class type`
  String get classEventsFieldClassType {
    return Intl.message(
      'Class type',
      name: 'classEventsFieldClassType',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get classEventsFieldLocation {
    return Intl.message(
      'Location',
      name: 'classEventsFieldLocation',
      desc: '',
      args: [],
    );
  }

  /// `Staff`
  String get classEventsFieldStaff {
    return Intl.message(
      'Staff',
      name: 'classEventsFieldStaff',
      desc: '',
      args: [],
    );
  }

  /// `Date`
  String get classEventsFieldDate {
    return Intl.message(
      'Date',
      name: 'classEventsFieldDate',
      desc: '',
      args: [],
    );
  }

  /// `Start time`
  String get classEventsFieldStartTime {
    return Intl.message(
      'Start time',
      name: 'classEventsFieldStartTime',
      desc: '',
      args: [],
    );
  }

  /// `End time`
  String get classEventsFieldEndTime {
    return Intl.message(
      'End time',
      name: 'classEventsFieldEndTime',
      desc: '',
      args: [],
    );
  }

  /// `Repeat schedule`
  String get classEventsRepeatSchedule {
    return Intl.message(
      'Repeat schedule',
      name: 'classEventsRepeatSchedule',
      desc: '',
      args: [],
    );
  }

  /// `Do not create schedules if there are overlaps`
  String get classEventsRecurrenceConflictSkipDescription {
    return Intl.message(
      'Do not create schedules if there are overlaps',
      name: 'classEventsRecurrenceConflictSkipDescription',
      desc: '',
      args: [],
    );
  }

  /// `Create schedules even if there are overlaps`
  String get classEventsRecurrenceConflictForceDescription {
    return Intl.message(
      'Create schedules even if there are overlaps',
      name: 'classEventsRecurrenceConflictForceDescription',
      desc: '',
      args: [],
    );
  }

  /// `Schedule preview`
  String get classEventsRecurrencePreviewTitle {
    return Intl.message(
      'Schedule preview',
      name: 'classEventsRecurrencePreviewTitle',
      desc: '',
      args: [],
    );
  }

  /// `Deselect schedules you do not want to create`
  String get classEventsRecurrencePreviewHint {
    return Intl.message(
      'Deselect schedules you do not want to create',
      name: 'classEventsRecurrencePreviewHint',
      desc: '',
      args: [],
    );
  }

  /// `Create {count} schedules`
  String classEventsRecurrencePreviewConfirm(int count) {
    return Intl.message(
      'Create $count schedules',
      name: 'classEventsRecurrencePreviewConfirm',
      desc: '',
      args: [count],
    );
  }

  /// `Capacity`
  String get classEventsFieldCapacity {
    return Intl.message(
      'Capacity',
      name: 'classEventsFieldCapacity',
      desc: '',
      args: [],
    );
  }

  /// `No enabled location for this class type`
  String get classEventsNoLocationsForClassType {
    return Intl.message(
      'No enabled location for this class type',
      name: 'classEventsNoLocationsForClassType',
      desc: '',
      args: [],
    );
  }

  /// `Fill all required fields`
  String get classEventsValidationRequired {
    return Intl.message(
      'Fill all required fields',
      name: 'classEventsValidationRequired',
      desc: '',
      args: [],
    );
  }

  /// `End time must be after start time`
  String get classEventsValidationEndAfterStart {
    return Intl.message(
      'End time must be after start time',
      name: 'classEventsValidationEndAfterStart',
      desc: '',
      args: [],
    );
  }

  /// `No class types available`
  String get classEventsNoClassTypes {
    return Intl.message(
      'No class types available',
      name: 'classEventsNoClassTypes',
      desc: '',
      args: [],
    );
  }

  /// `No staff available for selected location`
  String get classEventsNoStaffForLocation {
    return Intl.message(
      'No staff available for selected location',
      name: 'classEventsNoStaffForLocation',
      desc: '',
      args: [],
    );
  }

  /// `Existing schedules`
  String get classEventsSchedulesListTitle {
    return Intl.message(
      'Existing schedules',
      name: 'classEventsSchedulesListTitle',
      desc: '',
      args: [],
    );
  }

  /// `No schedules`
  String get classEventsSchedulesListEmpty {
    return Intl.message(
      'No schedules',
      name: 'classEventsSchedulesListEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Future`
  String get classEventsFutureBadge {
    return Intl.message(
      'Future',
      name: 'classEventsFutureBadge',
      desc: '',
      args: [],
    );
  }

  /// `Expired`
  String get classEventsExpiredBadge {
    return Intl.message(
      'Expired',
      name: 'classEventsExpiredBadge',
      desc: '',
      args: [],
    );
  }

  /// `Show expired too`
  String get classEventsShowExpiredSchedules {
    return Intl.message(
      'Show expired too',
      name: 'classEventsShowExpiredSchedules',
      desc: '',
      args: [],
    );
  }

  /// `Delete schedule?`
  String get classEventsSchedulesDeleteConfirmTitle {
    return Intl.message(
      'Delete schedule?',
      name: 'classEventsSchedulesDeleteConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Deleting the schedule will also delete any existing bookings.`
  String get classEventsSchedulesDeleteConfirmMessage {
    return Intl.message(
      'Deleting the schedule will also delete any existing bookings.',
      name: 'classEventsSchedulesDeleteConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Schedule deleted`
  String get classEventsSchedulesDeleteSuccessTitle {
    return Intl.message(
      'Schedule deleted',
      name: 'classEventsSchedulesDeleteSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `The schedule and related bookings have been deleted`
  String get classEventsSchedulesDeleteSuccessMessage {
    return Intl.message(
      'The schedule and related bookings have been deleted',
      name: 'classEventsSchedulesDeleteSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Schedule updated`
  String get classEventsSchedulesUpdateSuccessTitle {
    return Intl.message(
      'Schedule updated',
      name: 'classEventsSchedulesUpdateSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `Schedule updated successfully`
  String get classEventsSchedulesUpdateSuccessMessage {
    return Intl.message(
      'Schedule updated successfully',
      name: 'classEventsSchedulesUpdateSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Class created`
  String get classEventsCreateSuccessTitle {
    return Intl.message(
      'Class created',
      name: 'classEventsCreateSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `The class was created successfully`
  String get classEventsCreateSuccessMessage {
    return Intl.message(
      'The class was created successfully',
      name: 'classEventsCreateSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Unable to create class`
  String get classEventsCreateErrorMessage {
    return Intl.message(
      'Unable to create class',
      name: 'classEventsCreateErrorMessage',
      desc: '',
      args: [],
    );
  }

  /// `Class types`
  String get classTypesManageButton {
    return Intl.message(
      'Class types',
      name: 'classTypesManageButton',
      desc: '',
      args: [],
    );
  }

  /// `Class types`
  String get classTypesManageTitle {
    return Intl.message(
      'Class types',
      name: 'classTypesManageTitle',
      desc: '',
      args: [],
    );
  }

  /// `New type`
  String get classTypesAddButton {
    return Intl.message(
      'New type',
      name: 'classTypesAddButton',
      desc: '',
      args: [],
    );
  }

  /// `No class types configured`
  String get classTypesEmpty {
    return Intl.message(
      'No class types configured',
      name: 'classTypesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get classTypesStatusActive {
    return Intl.message(
      'Active',
      name: 'classTypesStatusActive',
      desc: '',
      args: [],
    );
  }

  /// `Inactive`
  String get classTypesStatusInactive {
    return Intl.message(
      'Inactive',
      name: 'classTypesStatusInactive',
      desc: '',
      args: [],
    );
  }

  /// `New class type`
  String get classTypesCreateTitle {
    return Intl.message(
      'New class type',
      name: 'classTypesCreateTitle',
      desc: '',
      args: [],
    );
  }

  /// `Edit class type`
  String get classTypesEditTitle {
    return Intl.message(
      'Edit class type',
      name: 'classTypesEditTitle',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get classTypesFieldName {
    return Intl.message(
      'Name',
      name: 'classTypesFieldName',
      desc: '',
      args: [],
    );
  }

  /// `Description (optional)`
  String get classTypesFieldDescriptionOptional {
    return Intl.message(
      'Description (optional)',
      name: 'classTypesFieldDescriptionOptional',
      desc: '',
      args: [],
    );
  }

  /// `Type active`
  String get classTypesFieldIsActive {
    return Intl.message(
      'Type active',
      name: 'classTypesFieldIsActive',
      desc: '',
      args: [],
    );
  }

  /// `Class type created`
  String get classTypesCreateSuccessTitle {
    return Intl.message(
      'Class type created',
      name: 'classTypesCreateSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `Class type created successfully`
  String get classTypesCreateSuccessMessage {
    return Intl.message(
      'Class type created successfully',
      name: 'classTypesCreateSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Class type updated`
  String get classTypesUpdateSuccessTitle {
    return Intl.message(
      'Class type updated',
      name: 'classTypesUpdateSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `Class type updated successfully`
  String get classTypesUpdateSuccessMessage {
    return Intl.message(
      'Class type updated successfully',
      name: 'classTypesUpdateSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Scheduling`
  String get classTypesActionScheduleClass {
    return Intl.message(
      'Scheduling',
      name: 'classTypesActionScheduleClass',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate`
  String get classTypesActionClone {
    return Intl.message(
      'Duplicate',
      name: 'classTypesActionClone',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get classTypesActionDeactivate {
    return Intl.message(
      'Delete',
      name: 'classTypesActionDeactivate',
      desc: '',
      args: [],
    );
  }

  /// `Reactivate`
  String get classTypesActionReactivate {
    return Intl.message(
      'Reactivate',
      name: 'classTypesActionReactivate',
      desc: '',
      args: [],
    );
  }

  /// `Copy`
  String get classTypesCloneSuffix {
    return Intl.message(
      'Copy',
      name: 'classTypesCloneSuffix',
      desc: '',
      args: [],
    );
  }

  /// `Class type duplicated`
  String get classTypesCloneSuccessTitle {
    return Intl.message(
      'Class type duplicated',
      name: 'classTypesCloneSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `Class type duplicated successfully`
  String get classTypesCloneSuccessMessage {
    return Intl.message(
      'Class type duplicated successfully',
      name: 'classTypesCloneSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Delete class type?`
  String get classTypesDeleteConfirmTitle {
    return Intl.message(
      'Delete class type?',
      name: 'classTypesDeleteConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `This action permanently deletes the class type.`
  String get classTypesDeleteConfirmMessage {
    return Intl.message(
      'This action permanently deletes the class type.',
      name: 'classTypesDeleteConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Class type deleted`
  String get classTypesDeleteSuccessTitle {
    return Intl.message(
      'Class type deleted',
      name: 'classTypesDeleteSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `Class type has been deleted`
  String get classTypesDeleteSuccessMessage {
    return Intl.message(
      'Class type has been deleted',
      name: 'classTypesDeleteSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Cannot delete class type because there are associated schedules`
  String get classTypesDeleteInUseErrorMessage {
    return Intl.message(
      'Cannot delete class type because there are associated schedules',
      name: 'classTypesDeleteInUseErrorMessage',
      desc: '',
      args: [],
    );
  }

  /// `Delete class type?`
  String get classTypesDeactivateConfirmTitle {
    return Intl.message(
      'Delete class type?',
      name: 'classTypesDeactivateConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `The class type will be deactivated and unavailable for new schedules.`
  String get classTypesDeactivateConfirmMessage {
    return Intl.message(
      'The class type will be deactivated and unavailable for new schedules.',
      name: 'classTypesDeactivateConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Reactivate class type?`
  String get classTypesReactivateConfirmTitle {
    return Intl.message(
      'Reactivate class type?',
      name: 'classTypesReactivateConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `The class type will be available again for new schedules.`
  String get classTypesReactivateConfirmMessage {
    return Intl.message(
      'The class type will be available again for new schedules.',
      name: 'classTypesReactivateConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Class type deleted`
  String get classTypesDeactivateSuccessTitle {
    return Intl.message(
      'Class type deleted',
      name: 'classTypesDeactivateSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `Class type has been deactivated`
  String get classTypesDeactivateSuccessMessage {
    return Intl.message(
      'Class type has been deactivated',
      name: 'classTypesDeactivateSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Class type reactivated`
  String get classTypesReactivateSuccessTitle {
    return Intl.message(
      'Class type reactivated',
      name: 'classTypesReactivateSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `Class type has been reactivated`
  String get classTypesReactivateSuccessMessage {
    return Intl.message(
      'Class type has been reactivated',
      name: 'classTypesReactivateSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Unable to save class type`
  String get classTypesMutationErrorMessage {
    return Intl.message(
      'Unable to save class type',
      name: 'classTypesMutationErrorMessage',
      desc: '',
      args: [],
    );
  }

  /// `Participants`
  String get classEventsParticipantsTitle {
    return Intl.message(
      'Participants',
      name: 'classEventsParticipantsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Confirmed: {confirmed}/{capacity} • Waitlist: {waitlist}`
  String classEventsCapacitySummary(int confirmed, int capacity, int waitlist) {
    return Intl.message(
      'Confirmed: $confirmed/$capacity • Waitlist: $waitlist',
      name: 'classEventsCapacitySummary',
      desc: '',
      args: [confirmed, capacity, waitlist],
    );
  }

  /// `Customer {customerId}`
  String classEventsParticipantCustomer(int customerId) {
    return Intl.message(
      'Customer $customerId',
      name: 'classEventsParticipantCustomer',
      desc: '',
      args: [customerId],
    );
  }

  /// `Payment`
  String get paymentDialogTitle {
    return Intl.message(
      'Payment',
      name: 'paymentDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `Payment`
  String get actionPayment {
    return Intl.message('Payment', name: 'actionPayment', desc: '', args: []);
  }

  /// `Cash`
  String get paymentMethodCash {
    return Intl.message('Cash', name: 'paymentMethodCash', desc: '', args: []);
  }

  /// `Debit/Credit Card`
  String get paymentMethodCard {
    return Intl.message(
      'Debit/Credit Card',
      name: 'paymentMethodCard',
      desc: '',
      args: [],
    );
  }

  /// `Discount`
  String get paymentMethodDiscount {
    return Intl.message(
      'Discount',
      name: 'paymentMethodDiscount',
      desc: '',
      args: [],
    );
  }

  /// `Voucher/Package`
  String get paymentMethodVoucher {
    return Intl.message(
      'Voucher/Package',
      name: 'paymentMethodVoucher',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get paymentMethodOther {
    return Intl.message(
      'Other',
      name: 'paymentMethodOther',
      desc: '',
      args: [],
    );
  }

  /// `Still to pay`
  String get paymentMethodPending {
    return Intl.message(
      'Still to pay',
      name: 'paymentMethodPending',
      desc: '',
      args: [],
    );
  }

  /// `Booking cost`
  String get paymentTotalCost {
    return Intl.message(
      'Booking cost',
      name: 'paymentTotalCost',
      desc: '',
      args: [],
    );
  }

  /// `Booking amount`
  String get paymentBookingAmount {
    return Intl.message(
      'Booking amount',
      name: 'paymentBookingAmount',
      desc: '',
      args: [],
    );
  }

  /// `Amount due`
  String get paymentAmountDue {
    return Intl.message(
      'Amount due',
      name: 'paymentAmountDue',
      desc: '',
      args: [],
    );
  }

  /// `Total appointments`
  String get paymentRequired {
    return Intl.message(
      'Total appointments',
      name: 'paymentRequired',
      desc: '',
      args: [],
    );
  }

  /// `Total appointments to collect`
  String get paymentAppointmentsToCollect {
    return Intl.message(
      'Total appointments to collect',
      name: 'paymentAppointmentsToCollect',
      desc: '',
      args: [],
    );
  }

  /// `Total to collect`
  String get paymentTotalToCollect {
    return Intl.message(
      'Total to collect',
      name: 'paymentTotalToCollect',
      desc: '',
      args: [],
    );
  }

  /// `Total collected`
  String get paymentEntered {
    return Intl.message(
      'Total collected',
      name: 'paymentEntered',
      desc: '',
      args: [],
    );
  }

  /// `Paid amount`
  String get paymentTotalPaid {
    return Intl.message(
      'Paid amount',
      name: 'paymentTotalPaid',
      desc: '',
      args: [],
    );
  }

  /// `Total cash and cards`
  String get paymentCashAndCardTotal {
    return Intl.message(
      'Total cash and cards',
      name: 'paymentCashAndCardTotal',
      desc: '',
      args: [],
    );
  }

  /// `Outstanding to collect`
  String get paymentOutstanding {
    return Intl.message(
      'Outstanding to collect',
      name: 'paymentOutstanding',
      desc: '',
      args: [],
    );
  }

  /// `Remaining`
  String get paymentRemaining {
    return Intl.message(
      'Remaining',
      name: 'paymentRemaining',
      desc: '',
      args: [],
    );
  }

  /// `The payments and other coverages already entered exceed the new amount due. Update the payment first, then save the booking.`
  String get bookingPaymentExceedsDueMessage {
    return Intl.message(
      'The payments and other coverages already entered exceed the new amount due. Update the payment first, then save the booking.',
      name: 'bookingPaymentExceedsDueMessage',
      desc: '',
      args: [],
    );
  }

  /// `Payment notes`
  String get paymentNotesLabel {
    return Intl.message(
      'Payment notes',
      name: 'paymentNotesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Notes about the payment...`
  String get paymentNotesPlaceholder {
    return Intl.message(
      'Notes about the payment...',
      name: 'paymentNotesPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `Payment methods`
  String get paymentMethodsTitle {
    return Intl.message(
      'Payment methods',
      name: 'paymentMethodsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Manage business payment method types`
  String get paymentMethodsDescription {
    return Intl.message(
      'Manage business payment method types',
      name: 'paymentMethodsDescription',
      desc: '',
      args: [],
    );
  }

  /// `You can change the payment type order by dragging them.`
  String get paymentMethodsReorderHint {
    return Intl.message(
      'You can change the payment type order by dragging them.',
      name: 'paymentMethodsReorderHint',
      desc: '',
      args: [],
    );
  }

  /// `No payment methods available`
  String get paymentMethodsEmpty {
    return Intl.message(
      'No payment methods available',
      name: 'paymentMethodsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Add method`
  String get paymentMethodsAdd {
    return Intl.message(
      'Add method',
      name: 'paymentMethodsAdd',
      desc: '',
      args: [],
    );
  }

  /// `Edit method`
  String get paymentMethodsEdit {
    return Intl.message(
      'Edit method',
      name: 'paymentMethodsEdit',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get paymentMethodsFieldName {
    return Intl.message(
      'Name',
      name: 'paymentMethodsFieldName',
      desc: '',
      args: [],
    );
  }

  /// `Order`
  String get paymentMethodsFieldSort {
    return Intl.message(
      'Order',
      name: 'paymentMethodsFieldSort',
      desc: '',
      args: [],
    );
  }

  /// `Enter a payment method name`
  String get paymentMethodsNameRequired {
    return Intl.message(
      'Enter a payment method name',
      name: 'paymentMethodsNameRequired',
      desc: '',
      args: [],
    );
  }

  /// `Delete payment method`
  String get paymentMethodsDeleteTitle {
    return Intl.message(
      'Delete payment method',
      name: 'paymentMethodsDeleteTitle',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to delete "{name}"?`
  String paymentMethodsDeleteMessage(Object name) {
    return Intl.message(
      'Do you want to delete "$name"?',
      name: 'paymentMethodsDeleteMessage',
      desc: '',
      args: [name],
    );
  }

  /// `Business Configuration`
  String get moreSectionBusinessConfig {
    return Intl.message(
      'Business Configuration',
      name: 'moreSectionBusinessConfig',
      desc: '',
      args: [],
    );
  }

  /// `Data Analysis`
  String get moreSectionDataAnalysis {
    return Intl.message(
      'Data Analysis',
      name: 'moreSectionDataAnalysis',
      desc: '',
      args: [],
    );
  }

  /// `Manage your profile`
  String get moreSectionProfileManage {
    return Intl.message(
      'Manage your profile',
      name: 'moreSectionProfileManage',
      desc: '',
      args: [],
    );
  }

  /// `Manage classes and group schedules`
  String get moreClassEventsDescription {
    return Intl.message(
      'Manage classes and group schedules',
      name: 'moreClassEventsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Daily report`
  String get agendaDailyReportAction {
    return Intl.message(
      'Daily report',
      name: 'agendaDailyReportAction',
      desc: '',
      args: [],
    );
  }

  /// `Weekly report`
  String get agendaWeeklyReportAction {
    return Intl.message(
      'Weekly report',
      name: 'agendaWeeklyReportAction',
      desc: '',
      args: [],
    );
  }

  /// `Report displayed date`
  String get agendaReportDisplayedDateAction {
    return Intl.message(
      'Report displayed date',
      name: 'agendaReportDisplayedDateAction',
      desc: '',
      args: [],
    );
  }

  /// `Report displayed week`
  String get agendaReportDisplayedWeekAction {
    return Intl.message(
      'Report displayed week',
      name: 'agendaReportDisplayedWeekAction',
      desc: '',
      args: [],
    );
  }

  /// `WhatsApp`
  String get whatsappTabTitle {
    return Intl.message(
      'WhatsApp',
      name: 'whatsappTabTitle',
      desc: '',
      args: [],
    );
  }

  /// `WhatsApp integration`
  String get whatsappPanelTitle {
    return Intl.message(
      'WhatsApp integration',
      name: 'whatsappPanelTitle',
      desc: '',
      args: [],
    );
  }

  /// `Manage numbers, location mappings, test sends, and outbox monitoring`
  String get whatsappPanelSubtitle {
    return Intl.message(
      'Manage numbers, location mappings, test sends, and outbox monitoring',
      name: 'whatsappPanelSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Select one business to manage WhatsApp integration.`
  String get whatsappSelectBusinessHint {
    return Intl.message(
      'Select one business to manage WhatsApp integration.',
      name: 'whatsappSelectBusinessHint',
      desc: '',
      args: [],
    );
  }

  /// `Refresh`
  String get whatsappRefresh {
    return Intl.message('Refresh', name: 'whatsappRefresh', desc: '', args: []);
  }

  /// `Run worker`
  String get whatsappRunWorker {
    return Intl.message(
      'Run worker',
      name: 'whatsappRunWorker',
      desc: '',
      args: [],
    );
  }

  /// `Go-live check`
  String get whatsappGoLiveCheck {
    return Intl.message(
      'Go-live check',
      name: 'whatsappGoLiveCheck',
      desc: '',
      args: [],
    );
  }

  /// `Go-live check business`
  String get whatsappGoLiveCheckBusiness {
    return Intl.message(
      'Go-live check business',
      name: 'whatsappGoLiveCheckBusiness',
      desc: '',
      args: [],
    );
  }

  /// `Go-live check location`
  String get whatsappGoLiveCheckLocation {
    return Intl.message(
      'Go-live check location',
      name: 'whatsappGoLiveCheckLocation',
      desc: '',
      args: [],
    );
  }

  /// `Scope: business`
  String get whatsappGoLiveScopeBusiness {
    return Intl.message(
      'Scope: business',
      name: 'whatsappGoLiveScopeBusiness',
      desc: '',
      args: [],
    );
  }

  /// `No active locations`
  String get whatsappNoLocationBannerTitle {
    return Intl.message(
      'No active locations',
      name: 'whatsappNoLocationBannerTitle',
      desc: '',
      args: [],
    );
  }

  /// `To use WhatsApp, create at least one active location first.`
  String get whatsappNoLocationBannerMessage {
    return Intl.message(
      'To use WhatsApp, create at least one active location first.',
      name: 'whatsappNoLocationBannerMessage',
      desc: '',
      args: [],
    );
  }

  /// `Create location`
  String get whatsappCreateLocationCta {
    return Intl.message(
      'Create location',
      name: 'whatsappCreateLocationCta',
      desc: '',
      args: [],
    );
  }

  /// `Run checks to verify if this business is ready for production go-live.`
  String get whatsappGoLiveHint {
    return Intl.message(
      'Run checks to verify if this business is ready for production go-live.',
      name: 'whatsappGoLiveHint',
      desc: '',
      args: [],
    );
  }

  /// `Configuration ready for go-live`
  String get whatsappGoLiveReady {
    return Intl.message(
      'Configuration ready for go-live',
      name: 'whatsappGoLiveReady',
      desc: '',
      args: [],
    );
  }

  /// `Configuration is incomplete`
  String get whatsappGoLiveNotReady {
    return Intl.message(
      'Configuration is incomplete',
      name: 'whatsappGoLiveNotReady',
      desc: '',
      args: [],
    );
  }

  /// `WhatsApp number active`
  String get whatsappCheckPhoneNumberActive {
    return Intl.message(
      'WhatsApp number active',
      name: 'whatsappCheckPhoneNumberActive',
      desc: '',
      args: [],
    );
  }

  /// `Webhook verified`
  String get whatsappCheckWebhookVerified {
    return Intl.message(
      'Webhook verified',
      name: 'whatsappCheckWebhookVerified',
      desc: '',
      args: [],
    );
  }

  /// `Utility template approved`
  String get whatsappCheckTemplateApproved {
    return Intl.message(
      'Utility template approved',
      name: 'whatsappCheckTemplateApproved',
      desc: '',
      args: [],
    );
  }

  /// `Client opt-in active`
  String get whatsappCheckOptInActive {
    return Intl.message(
      'Client opt-in active',
      name: 'whatsappCheckOptInActive',
      desc: '',
      args: [],
    );
  }

  /// `Configurations`
  String get whatsappStatsConfigs {
    return Intl.message(
      'Configurations',
      name: 'whatsappStatsConfigs',
      desc: '',
      args: [],
    );
  }

  /// `Location mappings`
  String get whatsappStatsMappings {
    return Intl.message(
      'Location mappings',
      name: 'whatsappStatsMappings',
      desc: '',
      args: [],
    );
  }

  /// `Queued messages`
  String get whatsappStatsQueued {
    return Intl.message(
      'Queued messages',
      name: 'whatsappStatsQueued',
      desc: '',
      args: [],
    );
  }

  /// `Failed messages`
  String get whatsappStatsFailed {
    return Intl.message(
      'Failed messages',
      name: 'whatsappStatsFailed',
      desc: '',
      args: [],
    );
  }

  /// `Numbers and configurations`
  String get whatsappConfigsTitle {
    return Intl.message(
      'Numbers and configurations',
      name: 'whatsappConfigsTitle',
      desc: '',
      args: [],
    );
  }

  /// `New configuration`
  String get whatsappAddConfig {
    return Intl.message(
      'New configuration',
      name: 'whatsappAddConfig',
      desc: '',
      args: [],
    );
  }

  /// `No configurations found.`
  String get whatsappNoConfigs {
    return Intl.message(
      'No configurations found.',
      name: 'whatsappNoConfigs',
      desc: '',
      args: [],
    );
  }

  /// `Edit configuration`
  String get whatsappEditConfig {
    return Intl.message(
      'Edit configuration',
      name: 'whatsappEditConfig',
      desc: '',
      args: [],
    );
  }

  /// `Delete WhatsApp configuration?`
  String get whatsappDeleteConfigTitle {
    return Intl.message(
      'Delete WhatsApp configuration?',
      name: 'whatsappDeleteConfigTitle',
      desc: '',
      args: [],
    );
  }

  /// `This action removes the configuration and related mappings.`
  String get whatsappDeleteConfigMessage {
    return Intl.message(
      'This action removes the configuration and related mappings.',
      name: 'whatsappDeleteConfigMessage',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number ID`
  String get whatsappFieldPhoneNumberId {
    return Intl.message(
      'Phone Number ID',
      name: 'whatsappFieldPhoneNumberId',
      desc: '',
      args: [],
    );
  }

  /// `WABA ID`
  String get whatsappFieldWabaId {
    return Intl.message(
      'WABA ID',
      name: 'whatsappFieldWabaId',
      desc: '',
      args: [],
    );
  }

  /// `Access token`
  String get whatsappFieldAccessToken {
    return Intl.message(
      'Access token',
      name: 'whatsappFieldAccessToken',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get whatsappFieldStatus {
    return Intl.message(
      'Status',
      name: 'whatsappFieldStatus',
      desc: '',
      args: [],
    );
  }

  /// `Default`
  String get whatsappFieldDefault {
    return Intl.message(
      'Default',
      name: 'whatsappFieldDefault',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get whatsappStatusActive {
    return Intl.message(
      'Active',
      name: 'whatsappStatusActive',
      desc: '',
      args: [],
    );
  }

  /// `Inactive`
  String get whatsappStatusInactive {
    return Intl.message(
      'Inactive',
      name: 'whatsappStatusInactive',
      desc: '',
      args: [],
    );
  }

  /// `Pending`
  String get whatsappStatusPending {
    return Intl.message(
      'Pending',
      name: 'whatsappStatusPending',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get whatsappStatusError {
    return Intl.message(
      'Error',
      name: 'whatsappStatusError',
      desc: '',
      args: [],
    );
  }

  /// `Location to number mapping`
  String get whatsappLocationMappingTitle {
    return Intl.message(
      'Location to number mapping',
      name: 'whatsappLocationMappingTitle',
      desc: '',
      args: [],
    );
  }

  /// `Only one active location: mapping is not required.`
  String get whatsappSingleLocationMappingHint {
    return Intl.message(
      'Only one active location: mapping is not required.',
      name: 'whatsappSingleLocationMappingHint',
      desc: '',
      args: [],
    );
  }

  /// `No active locations available.`
  String get whatsappNoLocations {
    return Intl.message(
      'No active locations available.',
      name: 'whatsappNoLocations',
      desc: '',
      args: [],
    );
  }

  /// `Unassigned`
  String get whatsappUnassigned {
    return Intl.message(
      'Unassigned',
      name: 'whatsappUnassigned',
      desc: '',
      args: [],
    );
  }

  /// `Template test send`
  String get whatsappTestSendTitle {
    return Intl.message(
      'Template test send',
      name: 'whatsappTestSendTitle',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get whatsappFieldLocation {
    return Intl.message(
      'Location',
      name: 'whatsappFieldLocation',
      desc: '',
      args: [],
    );
  }

  /// `Booking ID`
  String get whatsappFieldBookingId {
    return Intl.message(
      'Booking ID',
      name: 'whatsappFieldBookingId',
      desc: '',
      args: [],
    );
  }

  /// `Client ID`
  String get whatsappFieldClientId {
    return Intl.message(
      'Client ID',
      name: 'whatsappFieldClientId',
      desc: '',
      args: [],
    );
  }

  /// `Recipient phone`
  String get whatsappFieldRecipientPhone {
    return Intl.message(
      'Recipient phone',
      name: 'whatsappFieldRecipientPhone',
      desc: '',
      args: [],
    );
  }

  /// `Template name`
  String get whatsappFieldTemplateName {
    return Intl.message(
      'Template name',
      name: 'whatsappFieldTemplateName',
      desc: '',
      args: [],
    );
  }

  /// `Template variables (JSON)`
  String get whatsappFieldTemplateVariables {
    return Intl.message(
      'Template variables (JSON)',
      name: 'whatsappFieldTemplateVariables',
      desc: '',
      args: [],
    );
  }

  /// `Queue test`
  String get whatsappQueueTest {
    return Intl.message(
      'Queue test',
      name: 'whatsappQueueTest',
      desc: '',
      args: [],
    );
  }

  /// `Queue and send`
  String get whatsappQueueAndSendTest {
    return Intl.message(
      'Queue and send',
      name: 'whatsappQueueAndSendTest',
      desc: '',
      args: [],
    );
  }

  /// `WhatsApp outbox`
  String get whatsappOutboxTitle {
    return Intl.message(
      'WhatsApp outbox',
      name: 'whatsappOutboxTitle',
      desc: '',
      args: [],
    );
  }

  /// `No messages in outbox.`
  String get whatsappOutboxEmpty {
    return Intl.message(
      'No messages in outbox.',
      name: 'whatsappOutboxEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Delivered`
  String get whatsappOutboxDelivered {
    return Intl.message(
      'Delivered',
      name: 'whatsappOutboxDelivered',
      desc: '',
      args: [],
    );
  }

  /// `Read`
  String get whatsappOutboxRead {
    return Intl.message('Read', name: 'whatsappOutboxRead', desc: '', args: []);
  }

  /// `Send now`
  String get whatsappSendNow {
    return Intl.message(
      'Send now',
      name: 'whatsappSendNow',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get whatsappRetryNow {
    return Intl.message('Retry', name: 'whatsappRetryNow', desc: '', args: []);
  }

  /// `Last update`
  String get whatsappLastUpdate {
    return Intl.message(
      'Last update',
      name: 'whatsappLastUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Fill in all required fields.`
  String get whatsappValidationRequired {
    return Intl.message(
      'Fill in all required fields.',
      name: 'whatsappValidationRequired',
      desc: '',
      args: [],
    );
  }

  /// `Template variables JSON is invalid.`
  String get whatsappInvalidJson {
    return Intl.message(
      'Template variables JSON is invalid.',
      name: 'whatsappInvalidJson',
      desc: '',
      args: [],
    );
  }

  /// `WhatsApp updated`
  String get whatsappSavedSuccessTitle {
    return Intl.message(
      'WhatsApp updated',
      name: 'whatsappSavedSuccessTitle',
      desc: '',
      args: [],
    );
  }

  /// `WhatsApp changes were saved successfully.`
  String get whatsappSavedSuccessMessage {
    return Intl.message(
      'WhatsApp changes were saved successfully.',
      name: 'whatsappSavedSuccessMessage',
      desc: '',
      args: [],
    );
  }

  /// `Outbox worker completed successfully.`
  String get whatsappWorkerCompleted {
    return Intl.message(
      'Outbox worker completed successfully.',
      name: 'whatsappWorkerCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Message queued successfully.`
  String get whatsappQueuedOnly {
    return Intl.message(
      'Message queued successfully.',
      name: 'whatsappQueuedOnly',
      desc: '',
      args: [],
    );
  }

  /// `Message queued and sent.`
  String get whatsappQueuedAndSent {
    return Intl.message(
      'Message queued and sent.',
      name: 'whatsappQueuedAndSent',
      desc: '',
      args: [],
    );
  }

  /// `Display settings`
  String get agendaDisplaySettingsAction {
    return Intl.message(
      'Display settings',
      name: 'agendaDisplaySettingsAction',
      desc: '',
      args: [],
    );
  }

  /// `Agenda Settings`
  String get agendaDisplaySettingsSuperadminTitle {
    return Intl.message(
      'Agenda Settings',
      name: 'agendaDisplaySettingsSuperadminTitle',
      desc: '',
      args: [],
    );
  }

  /// `Card text zoom`
  String get agendaDisplaySettingsCardTextZoomLabel {
    return Intl.message(
      'Card text zoom',
      name: 'agendaDisplaySettingsCardTextZoomLabel',
      desc: '',
      args: [],
    );
  }

  /// `Color intensity`
  String get agendaDisplaySettingsCardColorOpacityLabel {
    return Intl.message(
      'Color intensity',
      name: 'agendaDisplaySettingsCardColorOpacityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Additional extra-band intensity`
  String get agendaDisplaySettingsExtraMinutesBandIntensityLabel {
    return Intl.message(
      'Additional extra-band intensity',
      name: 'agendaDisplaySettingsExtraMinutesBandIntensityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Unrelated card dimming intensity (desktop hover)`
  String get agendaDisplaySettingsHoverUnrelatedDimIntensityLabel {
    return Intl.message(
      'Unrelated card dimming intensity (desktop hover)',
      name: 'agendaDisplaySettingsHoverUnrelatedDimIntensityLabel',
      desc: '',
      args: [],
    );
  }

  /// `Show prices in cards`
  String get agendaDisplaySettingsShowPricesLabel {
    return Intl.message(
      'Show prices in cards',
      name: 'agendaDisplaySettingsShowPricesLabel',
      desc: '',
      args: [],
    );
  }

  /// `Show cancelled appointments`
  String get agendaDisplaySettingsShowCancelledLabel {
    return Intl.message(
      'Show cancelled appointments',
      name: 'agendaDisplaySettingsShowCancelledLabel',
      desc: '',
      args: [],
    );
  }

  /// `Card colors from:`
  String get agendaDisplaySettingsServiceColorsLabel {
    return Intl.message(
      'Card colors from:',
      name: 'agendaDisplaySettingsServiceColorsLabel',
      desc: '',
      args: [],
    );
  }

  /// `Reset defaults`
  String get agendaDisplaySettingsResetDefaultsAction {
    return Intl.message(
      'Reset defaults',
      name: 'agendaDisplaySettingsResetDefaultsAction',
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
