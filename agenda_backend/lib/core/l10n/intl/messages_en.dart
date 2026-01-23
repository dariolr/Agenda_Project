// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(name) => "Availability – ${name}";

  static String m1(fields) => "Changed fields: ${fields}";

  static String m2(clientName) => "${clientName}\'s appointments";

  static String m3(hours) => "${hours} hour";

  static String m4(hours, minutes) => "${hours} hour ${minutes} min";

  static String m5(minutes) => "${minutes} min";

  static String m6(id) => "Exception not found: ${id}";

  static String m7(factor) => "No builder available for ${factor}";

  static String m8(path) => "Page not found: ${path}";

  static String m9(count) =>
      "${count} ${Intl.plural(count, one: 'day', other: 'days')}";

  static String m10(dates) => "Some days were not saved: ${dates}.";

  static String m11(details) => "Some days were not saved: ${details}.";

  static String m12(hours) => "${hours}h";

  static String m13(hours, minutes) => "${hours}h ${minutes}m";

  static String m14(date) => "Last visit: ${date}";

  static String m15(newTime, staffName) =>
      "The appointment will be moved to ${newTime} for ${staffName}.";

  static String m16(date) => "Expires on ${date}";

  static String m17(email) => "Invite sent to ${email}";

  static String m18(name) => "Invited by ${name}";

  static String m19(count) => "${count} pending invites";

  static String m20(name) => "Do you want to remove ${name} from the team?";

  static String m21(email) => "Do you want to revoke the invite for ${email}?";

  static String m22(hoursA, hoursB, total) =>
      "Week A: ${hoursA}h | Week B: ${hoursB}h | Tot: ${total}h";

  static String m23(week) => "Current week: ${week}";

  static String m24(count) => "Show expired (${count})";

  static String m25(from) => "Valid from ${from}";

  static String m26(from, to) => "Valid from ${from} to ${to}";

  static String m27(from) => "From ${from}";

  static String m28(from, to) => "From ${from} to ${to}";

  static String m29(hours) => "${hours}h/week";

  static String m30(count) => "${count} appointments";

  static String m31(index, total) => "${index} of ${total}";

  static String m32(count) => "${count} appointments created";

  static String m33(count) => "${count} skipped due to conflicts";

  static String m34(index, total) =>
      "This is appointment ${index} of ${total} in the series.";

  static String m35(index, total) =>
      "This is appointment ${index} of ${total} in the series.";

  static String m36(count) => "${count} eligible team members";

  static String m37(count) =>
      "${Intl.plural(count, one: '1 service selected', other: '${count} services selected')}";

  static String m38(dayName) =>
      "Delete the weekly time slot for every ${dayName}";

  static String m39(date) => "Delete only the time slot of ${date}";

  static String m40(dayName) =>
      "Edit the weekly time slot for every ${dayName}";

  static String m41(date) => "Edit only the time slot of ${date}";

  static String m42(count) => "${count} eligible services";

  static String m43(count) =>
      "${Intl.plural(count, one: '1 day', other: '${count} days')}";

  static String m44(count) =>
      "${Intl.plural(count, one: '1 hour', other: '${count} hours')}";

  static String m45(selected, total) => "${selected} of ${total}";

  static String m46(hours) => "${hours} hours total";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "actionCancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "actionClose": MessageLookupByLibrary.simpleMessage("Close"),
    "actionConfirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "actionDelete": MessageLookupByLibrary.simpleMessage("Delete"),
    "actionDeleteBooking": MessageLookupByLibrary.simpleMessage(
      "Delete booking",
    ),
    "actionDiscard": MessageLookupByLibrary.simpleMessage("Cancel"),
    "actionEdit": MessageLookupByLibrary.simpleMessage("Edit"),
    "actionKeepEditing": MessageLookupByLibrary.simpleMessage("Keep editing"),
    "actionSave": MessageLookupByLibrary.simpleMessage("Save"),
    "addClientToAppointment": MessageLookupByLibrary.simpleMessage(
      "Add a client to the appointment",
    ),
    "addPackage": MessageLookupByLibrary.simpleMessage("Add package"),
    "addService": MessageLookupByLibrary.simpleMessage("Add service"),
    "addServiceTooltip": MessageLookupByLibrary.simpleMessage("Add service"),
    "additionalTimeOptionBlocked": MessageLookupByLibrary.simpleMessage(
      "Blocked time",
    ),
    "additionalTimeOptionProcessing": MessageLookupByLibrary.simpleMessage(
      "Processing time",
    ),
    "additionalTimeSwitch": MessageLookupByLibrary.simpleMessage(
      "Additional time",
    ),
    "agendaAdd": MessageLookupByLibrary.simpleMessage("Add"),
    "agendaAddAppointment": MessageLookupByLibrary.simpleMessage(
      "New appointment",
    ),
    "agendaAddBlock": MessageLookupByLibrary.simpleMessage("New block"),
    "agendaAddTitle": MessageLookupByLibrary.simpleMessage("Add a..."),
    "agendaNextDay": MessageLookupByLibrary.simpleMessage("Next day"),
    "agendaNextMonth": MessageLookupByLibrary.simpleMessage("Next month"),
    "agendaNextWeek": MessageLookupByLibrary.simpleMessage("Next Week"),
    "agendaNoLocations": MessageLookupByLibrary.simpleMessage(
      "No locations available",
    ),
    "agendaNoOnDutyTeamTitle": MessageLookupByLibrary.simpleMessage(
      "No team members on duty today",
    ),
    "agendaNoSelectedTeamTitle": MessageLookupByLibrary.simpleMessage(
      "No selected team members",
    ),
    "agendaPrevDay": MessageLookupByLibrary.simpleMessage("Previous day"),
    "agendaPrevMonth": MessageLookupByLibrary.simpleMessage("Previous month"),
    "agendaPrevWeek": MessageLookupByLibrary.simpleMessage("Previous Week"),
    "agendaSelectLocation": MessageLookupByLibrary.simpleMessage(
      "Select location",
    ),
    "agendaShowAllTeamButton": MessageLookupByLibrary.simpleMessage(
      "View all team",
    ),
    "agendaToday": MessageLookupByLibrary.simpleMessage("Today"),
    "allLocations": MessageLookupByLibrary.simpleMessage("All locations"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Agenda Platform"),
    "applyClientToAllAppointmentsMessage": MessageLookupByLibrary.simpleMessage(
      "The client will also be associated with the appointments in this booking that have been assigned to other staff members.",
    ),
    "applyClientToAllAppointmentsTitle": MessageLookupByLibrary.simpleMessage(
      "Apply client to entire booking?",
    ),
    "appointmentDialogTitleEdit": MessageLookupByLibrary.simpleMessage(
      "Edit appointment",
    ),
    "appointmentDialogTitleNew": MessageLookupByLibrary.simpleMessage(
      "New appointment",
    ),
    "appointmentNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Appointment note",
    ),
    "appointmentNotesTitle": MessageLookupByLibrary.simpleMessage("Notes"),
    "appointmentPriceFree": MessageLookupByLibrary.simpleMessage("Free"),
    "appointmentPriceHint": MessageLookupByLibrary.simpleMessage(
      "Custom price",
    ),
    "appointmentPriceLabel": MessageLookupByLibrary.simpleMessage("Price"),
    "appointmentPriceResetTooltip": MessageLookupByLibrary.simpleMessage(
      "Reset to service price",
    ),
    "atLeastOneServiceRequired": MessageLookupByLibrary.simpleMessage(
      "Add at least one service",
    ),
    "authEmail": MessageLookupByLibrary.simpleMessage("Email"),
    "authFirstName": MessageLookupByLibrary.simpleMessage("First Name"),
    "authForgotPassword": MessageLookupByLibrary.simpleMessage(
      "Forgot password?",
    ),
    "authForgotPasswordInfo": MessageLookupByLibrary.simpleMessage(
      "Contact the system administrator to reset your password.",
    ),
    "authInvalidEmail": MessageLookupByLibrary.simpleMessage("Invalid email"),
    "authLastName": MessageLookupByLibrary.simpleMessage("Last Name"),
    "authLogin": MessageLookupByLibrary.simpleMessage("Sign In"),
    "authLoginFailed": MessageLookupByLibrary.simpleMessage(
      "Invalid credentials. Please try again.",
    ),
    "authLoginFooter": MessageLookupByLibrary.simpleMessage(
      "Access reserved for authorized operators",
    ),
    "authLoginSubtitle": MessageLookupByLibrary.simpleMessage(
      "Sign in to the management system",
    ),
    "authLogout": MessageLookupByLibrary.simpleMessage("Sign Out"),
    "authPassword": MessageLookupByLibrary.simpleMessage("Password"),
    "authPasswordTooShort": MessageLookupByLibrary.simpleMessage(
      "Password too short",
    ),
    "authPhone": MessageLookupByLibrary.simpleMessage("Phone"),
    "authRememberMe": MessageLookupByLibrary.simpleMessage("Remember me"),
    "authRequiredField": MessageLookupByLibrary.simpleMessage("Required field"),
    "authResetPasswordError": MessageLookupByLibrary.simpleMessage(
      "An error occurred. Please try again later.",
    ),
    "authResetPasswordMessage": MessageLookupByLibrary.simpleMessage(
      "Enter your email. We will send you a link to reset your password.",
    ),
    "authResetPasswordSend": MessageLookupByLibrary.simpleMessage("Send"),
    "authResetPasswordSuccess": MessageLookupByLibrary.simpleMessage(
      "If the email exists in our system, you will receive a password reset link.",
    ),
    "authResetPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Reset password",
    ),
    "availabilitySave": MessageLookupByLibrary.simpleMessage("Save changes"),
    "availabilityTitle": MessageLookupByLibrary.simpleMessage(
      "Weekly availability",
    ),
    "availabilityTitleFor": m0,
    "blockAllDay": MessageLookupByLibrary.simpleMessage("All day"),
    "blockDialogTitleEdit": MessageLookupByLibrary.simpleMessage("Edit block"),
    "blockDialogTitleNew": MessageLookupByLibrary.simpleMessage("New block"),
    "blockEndTime": MessageLookupByLibrary.simpleMessage("End time"),
    "blockReason": MessageLookupByLibrary.simpleMessage("Reason (optional)"),
    "blockReasonHint": MessageLookupByLibrary.simpleMessage(
      "E.g. Meeting, Break, etc.",
    ),
    "blockSelectStaff": MessageLookupByLibrary.simpleMessage("Select team"),
    "blockSelectStaffError": MessageLookupByLibrary.simpleMessage(
      "Select at least one team member",
    ),
    "blockStartTime": MessageLookupByLibrary.simpleMessage("Start time"),
    "blockTimeError": MessageLookupByLibrary.simpleMessage(
      "End time must be after start time",
    ),
    "bookableOnlineSwitch": MessageLookupByLibrary.simpleMessage(
      "Bookable online",
    ),
    "bookingDetails": MessageLookupByLibrary.simpleMessage("Booking details"),
    "bookingHistoryActorCustomer": MessageLookupByLibrary.simpleMessage(
      "Customer",
    ),
    "bookingHistoryActorStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "bookingHistoryActorSystem": MessageLookupByLibrary.simpleMessage("System"),
    "bookingHistoryChangedFields": m1,
    "bookingHistoryEmpty": MessageLookupByLibrary.simpleMessage(
      "No events recorded",
    ),
    "bookingHistoryError": MessageLookupByLibrary.simpleMessage(
      "Error loading history",
    ),
    "bookingHistoryEventAppointmentUpdated":
        MessageLookupByLibrary.simpleMessage("Appointment updated"),
    "bookingHistoryEventCancelled": MessageLookupByLibrary.simpleMessage(
      "Booking cancelled",
    ),
    "bookingHistoryEventCreated": MessageLookupByLibrary.simpleMessage(
      "Booking created",
    ),
    "bookingHistoryEventDurationChanged": MessageLookupByLibrary.simpleMessage(
      "Duration changed",
    ),
    "bookingHistoryEventItemAdded": MessageLookupByLibrary.simpleMessage(
      "Service added",
    ),
    "bookingHistoryEventItemDeleted": MessageLookupByLibrary.simpleMessage(
      "Service removed",
    ),
    "bookingHistoryEventPriceChanged": MessageLookupByLibrary.simpleMessage(
      "Price changed",
    ),
    "bookingHistoryEventReplaced": MessageLookupByLibrary.simpleMessage(
      "Booking rescheduled",
    ),
    "bookingHistoryEventStaffChanged": MessageLookupByLibrary.simpleMessage(
      "Staff changed",
    ),
    "bookingHistoryEventTimeChanged": MessageLookupByLibrary.simpleMessage(
      "Time changed",
    ),
    "bookingHistoryEventUpdated": MessageLookupByLibrary.simpleMessage(
      "Booking updated",
    ),
    "bookingHistoryLoading": MessageLookupByLibrary.simpleMessage(
      "Loading history...",
    ),
    "bookingHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Booking history",
    ),
    "bookingItems": MessageLookupByLibrary.simpleMessage("Services"),
    "bookingNotes": MessageLookupByLibrary.simpleMessage("Booking notes"),
    "bookingStaffNotEligibleWarning": MessageLookupByLibrary.simpleMessage(
      "Warning: the selected team member is not eligible for this service.",
    ),
    "bookingTotal": MessageLookupByLibrary.simpleMessage("Total"),
    "bookingUnavailableTimeWarningAppointment":
        MessageLookupByLibrary.simpleMessage(
          "Warning: the appointment time includes unavailable slots for the chosen team.",
        ),
    "bookingUnavailableTimeWarningService": MessageLookupByLibrary.simpleMessage(
      "Warning: this service time includes unavailable slots for the chosen team.",
    ),
    "cancelledBadge": MessageLookupByLibrary.simpleMessage("CANCELLED"),
    "cannotDeleteCategoryContent": MessageLookupByLibrary.simpleMessage(
      "This category contains one or more services.",
    ),
    "cannotDeleteTitle": MessageLookupByLibrary.simpleMessage("Cannot delete"),
    "cannotUndoWarning": MessageLookupByLibrary.simpleMessage(
      "This action cannot be undone.",
    ),
    "categoryDuplicateError": MessageLookupByLibrary.simpleMessage(
      "A category with this name already exists",
    ),
    "clientAppointmentsEmpty": MessageLookupByLibrary.simpleMessage(
      "No appointments",
    ),
    "clientAppointmentsPast": MessageLookupByLibrary.simpleMessage("Past"),
    "clientAppointmentsTitle": m2,
    "clientAppointmentsUpcoming": MessageLookupByLibrary.simpleMessage(
      "Upcoming",
    ),
    "clientLockedHint": MessageLookupByLibrary.simpleMessage(
      "Client cannot be changed for this appointment",
    ),
    "clientNoteLabel": MessageLookupByLibrary.simpleMessage("Client note"),
    "clientOptionalHint": MessageLookupByLibrary.simpleMessage(
      "Leave empty if you don\'t want to associate a client with the appointment",
    ),
    "clientsEdit": MessageLookupByLibrary.simpleMessage("Edit client"),
    "clientsEmpty": MessageLookupByLibrary.simpleMessage("No clients"),
    "clientsNew": MessageLookupByLibrary.simpleMessage("New client"),
    "clientsTitle": MessageLookupByLibrary.simpleMessage("Clients List"),
    "createCategoryButtonLabel": MessageLookupByLibrary.simpleMessage(
      "New category",
    ),
    "createNewClient": MessageLookupByLibrary.simpleMessage(
      "Create new client",
    ),
    "currentWeek": MessageLookupByLibrary.simpleMessage("Current week"),
    "dayFridayFull": MessageLookupByLibrary.simpleMessage("Friday"),
    "dayMondayFull": MessageLookupByLibrary.simpleMessage("Monday"),
    "daySaturdayFull": MessageLookupByLibrary.simpleMessage("Saturday"),
    "daySundayFull": MessageLookupByLibrary.simpleMessage("Sunday"),
    "dayThursdayFull": MessageLookupByLibrary.simpleMessage("Thursday"),
    "dayTuesdayFull": MessageLookupByLibrary.simpleMessage("Tuesday"),
    "dayWednesdayFull": MessageLookupByLibrary.simpleMessage("Wednesday"),
    "deleteAppointmentConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "The appointment will be removed. This action cannot be undone.",
    ),
    "deleteAppointmentConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Delete appointment?",
    ),
    "deleteBookingConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "All linked services will be removed. This action cannot be undone.",
    ),
    "deleteBookingConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Delete entire booking?",
    ),
    "deleteClientConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "The client will be permanently deleted. This action cannot be undone.",
    ),
    "deleteClientConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Delete client?",
    ),
    "deleteConfirmationTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm deletion?",
    ),
    "deleteServiceQuestion": MessageLookupByLibrary.simpleMessage(
      "Delete this service?",
    ),
    "discardChangesMessage": MessageLookupByLibrary.simpleMessage(
      "You have unsaved changes. Do you want to discard them?",
    ),
    "discardChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Unsaved changes",
    ),
    "duplicateAction": MessageLookupByLibrary.simpleMessage("Duplicate"),
    "durationHour": m3,
    "durationHourMinute": m4,
    "durationMinute": m5,
    "editCategoryTitle": MessageLookupByLibrary.simpleMessage("Edit category"),
    "editServiceTitle": MessageLookupByLibrary.simpleMessage("Edit service"),
    "emptyCategoriesNotReorderableNote": MessageLookupByLibrary.simpleMessage(
      "Categories without services cannot be reordered and stay at the end.",
    ),
    "errorExceptionNotFound": m6,
    "errorFormFactorBuilderMissing": m7,
    "errorFormFactorBuilderRequired": MessageLookupByLibrary.simpleMessage(
      "Specify at least one builder for form factor",
    ),
    "errorNotFound": m8,
    "errorServiceNotFound": MessageLookupByLibrary.simpleMessage(
      "Service not found",
    ),
    "errorTitle": MessageLookupByLibrary.simpleMessage("Error"),
    "exceptionAllDay": MessageLookupByLibrary.simpleMessage("All day"),
    "exceptionAvailableNoEffect": MessageLookupByLibrary.simpleMessage(
      "Extra availability must add hours beyond the base availability.",
    ),
    "exceptionDateFrom": MessageLookupByLibrary.simpleMessage("Start date"),
    "exceptionDateTo": MessageLookupByLibrary.simpleMessage("End date"),
    "exceptionDeleteMessage": MessageLookupByLibrary.simpleMessage(
      "The exception will be permanently deleted.",
    ),
    "exceptionDeleteShift": MessageLookupByLibrary.simpleMessage(
      "Delete exception",
    ),
    "exceptionDeleteShiftDesc": MessageLookupByLibrary.simpleMessage(
      "Restore base availability",
    ),
    "exceptionDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Delete exception?",
    ),
    "exceptionDialogTitleEdit": MessageLookupByLibrary.simpleMessage(
      "Edit exception",
    ),
    "exceptionDialogTitleNew": MessageLookupByLibrary.simpleMessage(
      "New exception",
    ),
    "exceptionDuration": MessageLookupByLibrary.simpleMessage(
      "Duration (days)",
    ),
    "exceptionDurationDays": m9,
    "exceptionEditShift": MessageLookupByLibrary.simpleMessage(
      "Edit exception",
    ),
    "exceptionEditShiftDesc": MessageLookupByLibrary.simpleMessage(
      "Edit the times of this exception",
    ),
    "exceptionEndTime": MessageLookupByLibrary.simpleMessage("End time"),
    "exceptionPartialSaveInfo": m10,
    "exceptionPartialSaveInfoDetailed": m11,
    "exceptionPartialSaveMessage": MessageLookupByLibrary.simpleMessage(
      "The days below were not congruent and were not saved:",
    ),
    "exceptionPartialSaveTitle": MessageLookupByLibrary.simpleMessage(
      "Exceptions not saved",
    ),
    "exceptionPeriodDuration": MessageLookupByLibrary.simpleMessage("Duration"),
    "exceptionPeriodMode": MessageLookupByLibrary.simpleMessage("Period"),
    "exceptionPeriodRange": MessageLookupByLibrary.simpleMessage("From - To"),
    "exceptionPeriodSingle": MessageLookupByLibrary.simpleMessage("Single day"),
    "exceptionReason": MessageLookupByLibrary.simpleMessage(
      "Reason (optional)",
    ),
    "exceptionReasonExtraShift": MessageLookupByLibrary.simpleMessage(
      "Extra shift",
    ),
    "exceptionReasonHint": MessageLookupByLibrary.simpleMessage(
      "E.g. Holiday, Medical visit, Extra shift...",
    ),
    "exceptionReasonMedicalVisit": MessageLookupByLibrary.simpleMessage(
      "Medical visit",
    ),
    "exceptionReasonVacation": MessageLookupByLibrary.simpleMessage("Vacation"),
    "exceptionSelectTime": MessageLookupByLibrary.simpleMessage("Select time"),
    "exceptionStartTime": MessageLookupByLibrary.simpleMessage("Start time"),
    "exceptionTimeError": MessageLookupByLibrary.simpleMessage(
      "End time must be after start time",
    ),
    "exceptionType": MessageLookupByLibrary.simpleMessage("Exception type"),
    "exceptionTypeAvailable": MessageLookupByLibrary.simpleMessage("Available"),
    "exceptionTypeUnavailable": MessageLookupByLibrary.simpleMessage(
      "Unavailable",
    ),
    "exceptionUnavailableNoBase": MessageLookupByLibrary.simpleMessage(
      "You can\'t add unavailability on a day with no base availability.",
    ),
    "exceptionUnavailableNoOverlap": MessageLookupByLibrary.simpleMessage(
      "Unavailability must overlap the base availability.",
    ),
    "exceptionsAdd": MessageLookupByLibrary.simpleMessage("Add exception"),
    "exceptionsEmpty": MessageLookupByLibrary.simpleMessage(
      "No exceptions configured",
    ),
    "exceptionsTitle": MessageLookupByLibrary.simpleMessage("Exceptions"),
    "fieldBlockedTimeLabel": MessageLookupByLibrary.simpleMessage(
      "Blocked time",
    ),
    "fieldCategoryRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "Category *",
    ),
    "fieldDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Description",
    ),
    "fieldDurationRequiredError": MessageLookupByLibrary.simpleMessage(
      "Please select a duration",
    ),
    "fieldDurationRequiredLabel": MessageLookupByLibrary.simpleMessage(
      "Duration *",
    ),
    "fieldNameRequiredError": MessageLookupByLibrary.simpleMessage(
      "Name is required",
    ),
    "fieldNameRequiredLabel": MessageLookupByLibrary.simpleMessage("Name *"),
    "fieldPriceLabel": MessageLookupByLibrary.simpleMessage("Price"),
    "fieldProcessingTimeLabel": MessageLookupByLibrary.simpleMessage(
      "Processing time",
    ),
    "filterAll": MessageLookupByLibrary.simpleMessage("All"),
    "filterInactive": MessageLookupByLibrary.simpleMessage("Inactive"),
    "filterNew": MessageLookupByLibrary.simpleMessage("New"),
    "filterVIP": MessageLookupByLibrary.simpleMessage("VIP"),
    "formClient": MessageLookupByLibrary.simpleMessage("Client"),
    "formDate": MessageLookupByLibrary.simpleMessage("Date"),
    "formEmail": MessageLookupByLibrary.simpleMessage("Email"),
    "formFirstName": MessageLookupByLibrary.simpleMessage("First name"),
    "formLastName": MessageLookupByLibrary.simpleMessage("Last name"),
    "formNotes": MessageLookupByLibrary.simpleMessage(
      "Notes (not visible to client)",
    ),
    "formPhone": MessageLookupByLibrary.simpleMessage("Phone"),
    "formService": MessageLookupByLibrary.simpleMessage("Service"),
    "formServices": MessageLookupByLibrary.simpleMessage("Services"),
    "formStaff": MessageLookupByLibrary.simpleMessage("Team"),
    "freeLabel": MessageLookupByLibrary.simpleMessage("Free"),
    "freeServiceSwitch": MessageLookupByLibrary.simpleMessage("Free service"),
    "hoursHoursOnly": m12,
    "hoursMinutesCompact": m13,
    "labelSelect": MessageLookupByLibrary.simpleMessage("Select"),
    "labelStaff": MessageLookupByLibrary.simpleMessage("Team:"),
    "lastVisitLabel": m14,
    "minutesLabel": MessageLookupByLibrary.simpleMessage("min"),
    "moveAppointmentConfirmMessage": m15,
    "moveAppointmentConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm move?",
    ),
    "navAgenda": MessageLookupByLibrary.simpleMessage("Agenda"),
    "navClients": MessageLookupByLibrary.simpleMessage("Clients"),
    "navProfile": MessageLookupByLibrary.simpleMessage("Profile"),
    "navServices": MessageLookupByLibrary.simpleMessage("Services"),
    "navStaff": MessageLookupByLibrary.simpleMessage("Team"),
    "newCategoryTitle": MessageLookupByLibrary.simpleMessage("New category"),
    "newServiceTitle": MessageLookupByLibrary.simpleMessage("New service"),
    "noClientForAppointment": MessageLookupByLibrary.simpleMessage(
      "No client for the appointment",
    ),
    "noServicesAdded": MessageLookupByLibrary.simpleMessage(
      "No services added",
    ),
    "noServicesInCategory": MessageLookupByLibrary.simpleMessage(
      "No services in this category",
    ),
    "noStaffAvailable": MessageLookupByLibrary.simpleMessage(
      "No team available",
    ),
    "notBookableOnline": MessageLookupByLibrary.simpleMessage(
      "Not bookable online",
    ),
    "notesPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Notes about the appointment...",
    ),
    "operatorsEditRole": MessageLookupByLibrary.simpleMessage("Edit role"),
    "operatorsEmpty": MessageLookupByLibrary.simpleMessage(
      "No operators configured",
    ),
    "operatorsExpires": m16,
    "operatorsInviteCopied": MessageLookupByLibrary.simpleMessage(
      "Invite link copied",
    ),
    "operatorsInviteEmail": MessageLookupByLibrary.simpleMessage("Email"),
    "operatorsInviteRole": MessageLookupByLibrary.simpleMessage("Role"),
    "operatorsInviteSend": MessageLookupByLibrary.simpleMessage("Send invite"),
    "operatorsInviteSubtitle": MessageLookupByLibrary.simpleMessage(
      "Send an invite via email",
    ),
    "operatorsInviteSuccess": m17,
    "operatorsInviteTitle": MessageLookupByLibrary.simpleMessage(
      "Invite operator",
    ),
    "operatorsInvitedBy": m18,
    "operatorsPendingInvites": MessageLookupByLibrary.simpleMessage(
      "Pending invites",
    ),
    "operatorsPendingInvitesCount": m19,
    "operatorsRemove": MessageLookupByLibrary.simpleMessage("Remove operator"),
    "operatorsRemoveConfirm": m20,
    "operatorsRemoveSuccess": MessageLookupByLibrary.simpleMessage(
      "Operator removed",
    ),
    "operatorsRevokeInvite": MessageLookupByLibrary.simpleMessage(
      "Revoke invite",
    ),
    "operatorsRevokeInviteConfirm": m21,
    "operatorsRoleAdmin": MessageLookupByLibrary.simpleMessage("Administrator"),
    "operatorsRoleDescription": MessageLookupByLibrary.simpleMessage(
      "Select access level",
    ),
    "operatorsRoleManager": MessageLookupByLibrary.simpleMessage("Manager"),
    "operatorsRoleOwner": MessageLookupByLibrary.simpleMessage("Owner"),
    "operatorsRoleStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "operatorsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Manage who can access the platform",
    ),
    "operatorsTitle": MessageLookupByLibrary.simpleMessage("Operators"),
    "operatorsYou": MessageLookupByLibrary.simpleMessage("You"),
    "planningActive": MessageLookupByLibrary.simpleMessage("Active"),
    "planningBiweeklyHours": m22,
    "planningCreateTitle": MessageLookupByLibrary.simpleMessage("New planning"),
    "planningCurrentWeek": m23,
    "planningDeleteConfirm": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this planning? Weekly schedules will be removed.",
    ),
    "planningDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Delete planning",
    ),
    "planningEditTitle": MessageLookupByLibrary.simpleMessage("Edit planning"),
    "planningFuture": MessageLookupByLibrary.simpleMessage("Future"),
    "planningHideExpired": MessageLookupByLibrary.simpleMessage("Hide expired"),
    "planningListAdd": MessageLookupByLibrary.simpleMessage("Add planning"),
    "planningListEmpty": MessageLookupByLibrary.simpleMessage(
      "No planning defined",
    ),
    "planningListTitle": MessageLookupByLibrary.simpleMessage("Planning"),
    "planningOpenEnded": MessageLookupByLibrary.simpleMessage("No end date"),
    "planningPast": MessageLookupByLibrary.simpleMessage("Past"),
    "planningSelectDate": MessageLookupByLibrary.simpleMessage("Select date"),
    "planningSetEndDate": MessageLookupByLibrary.simpleMessage("Set end date"),
    "planningShowExpired": m24,
    "planningType": MessageLookupByLibrary.simpleMessage("Planning type"),
    "planningTypeBiweekly": MessageLookupByLibrary.simpleMessage("Biweekly"),
    "planningTypeWeekly": MessageLookupByLibrary.simpleMessage("Weekly"),
    "planningValidFrom": MessageLookupByLibrary.simpleMessage(
      "Validity start date",
    ),
    "planningValidFromOnly": m25,
    "planningValidFromTo": m26,
    "planningValidTo": MessageLookupByLibrary.simpleMessage(
      "Validity end date",
    ),
    "planningValidityFrom": m27,
    "planningValidityRange": m28,
    "planningWeekA": MessageLookupByLibrary.simpleMessage("Week A"),
    "planningWeekB": MessageLookupByLibrary.simpleMessage("Week B"),
    "planningWeeklyHours": m29,
    "priceNotAvailable": MessageLookupByLibrary.simpleMessage("N/A"),
    "priceStartingFromPrefix": MessageLookupByLibrary.simpleMessage(
      "starting from",
    ),
    "priceStartingFromSwitch": MessageLookupByLibrary.simpleMessage(
      "Price “starting from”",
    ),
    "profileTitle": MessageLookupByLibrary.simpleMessage("Profile"),
    "recurrenceAfter": MessageLookupByLibrary.simpleMessage("After"),
    "recurrenceDay": MessageLookupByLibrary.simpleMessage("day"),
    "recurrenceDays": MessageLookupByLibrary.simpleMessage("days"),
    "recurrenceEnds": MessageLookupByLibrary.simpleMessage("Ends"),
    "recurrenceEvery": MessageLookupByLibrary.simpleMessage("Every"),
    "recurrenceFrequency": MessageLookupByLibrary.simpleMessage("Frequency"),
    "recurrenceMonth": MessageLookupByLibrary.simpleMessage("month"),
    "recurrenceMonths": MessageLookupByLibrary.simpleMessage("months"),
    "recurrenceNever": MessageLookupByLibrary.simpleMessage("Never"),
    "recurrenceOccurrences": MessageLookupByLibrary.simpleMessage(
      "occurrences",
    ),
    "recurrenceOnDate": MessageLookupByLibrary.simpleMessage("On"),
    "recurrencePreviewCount": m30,
    "recurrencePreviewTitle": MessageLookupByLibrary.simpleMessage(
      "Scheduled dates",
    ),
    "recurrenceRepeatBooking": MessageLookupByLibrary.simpleMessage(
      "Repeat this appointment",
    ),
    "recurrenceSelectDate": MessageLookupByLibrary.simpleMessage("Select date"),
    "recurrenceSeriesIcon": MessageLookupByLibrary.simpleMessage(
      "Recurring appointment",
    ),
    "recurrenceSeriesOf": m31,
    "recurrenceSummaryCreated": m32,
    "recurrenceSummaryError": MessageLookupByLibrary.simpleMessage(
      "Error creating series",
    ),
    "recurrenceSummarySkipped": m33,
    "recurrenceSummaryTitle": MessageLookupByLibrary.simpleMessage(
      "Series created",
    ),
    "recurrenceWeek": MessageLookupByLibrary.simpleMessage("week"),
    "recurrenceWeeks": MessageLookupByLibrary.simpleMessage("weeks"),
    "recurringDeleteChooseScope": MessageLookupByLibrary.simpleMessage(
      "Which appointments do you want to delete?",
    ),
    "recurringDeleteMessage": m34,
    "recurringDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Delete recurring appointment",
    ),
    "recurringEditChooseScope": MessageLookupByLibrary.simpleMessage(
      "Which appointments do you want to edit?",
    ),
    "recurringEditMessage": m35,
    "recurringEditTitle": MessageLookupByLibrary.simpleMessage(
      "Edit recurring appointment",
    ),
    "recurringScopeAll": MessageLookupByLibrary.simpleMessage("All"),
    "recurringScopeOnlyThis": MessageLookupByLibrary.simpleMessage(
      "Only this one",
    ),
    "recurringScopeThisAndFuture": MessageLookupByLibrary.simpleMessage(
      "This and future",
    ),
    "removeClient": MessageLookupByLibrary.simpleMessage("Remove client"),
    "reorderCategoriesLabel": MessageLookupByLibrary.simpleMessage(
      "Categories",
    ),
    "reorderHelpDescription": MessageLookupByLibrary.simpleMessage(
      "Reorder categories and services by dragging them: the same order will be applied to online booking. Select whether to sort categories or services.",
    ),
    "reorderServicesLabel": MessageLookupByLibrary.simpleMessage("Services"),
    "reorderTitle": MessageLookupByLibrary.simpleMessage("Reorder"),
    "searchClientPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Search client...",
    ),
    "selectClientTitle": MessageLookupByLibrary.simpleMessage("Select client"),
    "selectService": MessageLookupByLibrary.simpleMessage("Select service"),
    "selectStaffTitle": MessageLookupByLibrary.simpleMessage("Select team"),
    "serviceColorLabel": MessageLookupByLibrary.simpleMessage("Service color"),
    "serviceDuplicateCopyWord": MessageLookupByLibrary.simpleMessage("Copy"),
    "serviceDuplicateError": MessageLookupByLibrary.simpleMessage(
      "A service with this name already exists",
    ),
    "serviceEligibleStaffCount": m36,
    "serviceEligibleStaffNone": MessageLookupByLibrary.simpleMessage(
      "No eligible team members",
    ),
    "servicePackageActiveLabel": MessageLookupByLibrary.simpleMessage(
      "Package active",
    ),
    "servicePackageBrokenLabel": MessageLookupByLibrary.simpleMessage(
      "Invalid",
    ),
    "servicePackageCreatedMessage": MessageLookupByLibrary.simpleMessage(
      "The package has been created.",
    ),
    "servicePackageCreatedTitle": MessageLookupByLibrary.simpleMessage(
      "Package created",
    ),
    "servicePackageDeleteError": MessageLookupByLibrary.simpleMessage(
      "Failed to delete the package.",
    ),
    "servicePackageDeleteMessage": MessageLookupByLibrary.simpleMessage(
      "This action cannot be undone.",
    ),
    "servicePackageDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Delete package?",
    ),
    "servicePackageDeletedMessage": MessageLookupByLibrary.simpleMessage(
      "The package has been deleted.",
    ),
    "servicePackageDeletedTitle": MessageLookupByLibrary.simpleMessage(
      "Package deleted",
    ),
    "servicePackageDescriptionLabel": MessageLookupByLibrary.simpleMessage(
      "Description",
    ),
    "servicePackageEditTitle": MessageLookupByLibrary.simpleMessage(
      "Edit package",
    ),
    "servicePackageExpandError": MessageLookupByLibrary.simpleMessage(
      "Unable to expand the selected package.",
    ),
    "servicePackageInactiveLabel": MessageLookupByLibrary.simpleMessage(
      "Inactive",
    ),
    "servicePackageNameLabel": MessageLookupByLibrary.simpleMessage(
      "Package name",
    ),
    "servicePackageNewMenu": MessageLookupByLibrary.simpleMessage(
      "New package",
    ),
    "servicePackageNewTitle": MessageLookupByLibrary.simpleMessage(
      "New package",
    ),
    "servicePackageNoServices": MessageLookupByLibrary.simpleMessage(
      "No services selected",
    ),
    "servicePackageOrderLabel": MessageLookupByLibrary.simpleMessage(
      "Service order",
    ),
    "servicePackageOverrideDurationLabel": MessageLookupByLibrary.simpleMessage(
      "Package duration (min)",
    ),
    "servicePackageOverridePriceLabel": MessageLookupByLibrary.simpleMessage(
      "Package price",
    ),
    "servicePackageSaveError": MessageLookupByLibrary.simpleMessage(
      "Failed to save the package.",
    ),
    "servicePackageServicesLabel": MessageLookupByLibrary.simpleMessage(
      "Included services",
    ),
    "servicePackageServicesRequired": MessageLookupByLibrary.simpleMessage(
      "Select at least one service",
    ),
    "servicePackageUpdatedMessage": MessageLookupByLibrary.simpleMessage(
      "The package has been updated.",
    ),
    "servicePackageUpdatedTitle": MessageLookupByLibrary.simpleMessage(
      "Package updated",
    ),
    "servicePackagesEmptyState": MessageLookupByLibrary.simpleMessage(
      "No packages available",
    ),
    "servicePackagesTabLabel": MessageLookupByLibrary.simpleMessage("Packages"),
    "servicePackagesTitle": MessageLookupByLibrary.simpleMessage("Packages"),
    "serviceSeedCategoryBodyDescription": MessageLookupByLibrary.simpleMessage(
      "Services dedicated to body wellness",
    ),
    "serviceSeedCategoryBodyName": MessageLookupByLibrary.simpleMessage(
      "Body Treatments",
    ),
    "serviceSeedCategoryFaceDescription": MessageLookupByLibrary.simpleMessage(
      "Aesthetic and rejuvenating care for the face",
    ),
    "serviceSeedCategoryFaceName": MessageLookupByLibrary.simpleMessage(
      "Facial Treatments",
    ),
    "serviceSeedCategorySportsDescription":
        MessageLookupByLibrary.simpleMessage(
          "Programs designed for athletes and active people",
        ),
    "serviceSeedCategorySportsName": MessageLookupByLibrary.simpleMessage(
      "Sports Treatments",
    ),
    "serviceSeedServiceFaceDescription": MessageLookupByLibrary.simpleMessage(
      "Cleansing and illuminating treatment",
    ),
    "serviceSeedServiceFaceName": MessageLookupByLibrary.simpleMessage(
      "Facial Treatment",
    ),
    "serviceSeedServiceRelaxDescription": MessageLookupByLibrary.simpleMessage(
      "Relaxing 30-minute treatment",
    ),
    "serviceSeedServiceRelaxName": MessageLookupByLibrary.simpleMessage(
      "Relax Massage",
    ),
    "serviceSeedServiceSportDescription": MessageLookupByLibrary.simpleMessage(
      "Intensive decontracting treatment",
    ),
    "serviceSeedServiceSportName": MessageLookupByLibrary.simpleMessage(
      "Sports Massage",
    ),
    "serviceStartsAfterMidnight": MessageLookupByLibrary.simpleMessage(
      "Cannot add service: the time exceeds midnight. Change the start time or staff member.",
    ),
    "servicesLabel": MessageLookupByLibrary.simpleMessage("services"),
    "servicesNewServiceMenu": MessageLookupByLibrary.simpleMessage(
      "New service",
    ),
    "servicesSelectedCount": m37,
    "servicesTabLabel": MessageLookupByLibrary.simpleMessage("Services"),
    "setPriceToEnable": MessageLookupByLibrary.simpleMessage(
      "Set a price to enable this option",
    ),
    "shiftDeleteAll": MessageLookupByLibrary.simpleMessage(
      "Delete all these shifts",
    ),
    "shiftDeleteAllDesc": m38,
    "shiftDeleteThisOnly": MessageLookupByLibrary.simpleMessage(
      "Delete only this shift",
    ),
    "shiftDeleteThisOnlyDesc": m39,
    "shiftEditAll": MessageLookupByLibrary.simpleMessage(
      "Edit all these shifts",
    ),
    "shiftEditAllDesc": m40,
    "shiftEditThisOnly": MessageLookupByLibrary.simpleMessage(
      "Edit only this shift",
    ),
    "shiftEditThisOnlyDesc": m41,
    "shiftEditTitle": MessageLookupByLibrary.simpleMessage("Edit shift"),
    "shiftEndTime": MessageLookupByLibrary.simpleMessage("End time"),
    "shiftStartTime": MessageLookupByLibrary.simpleMessage("Start time"),
    "sortByCreatedAtAsc": MessageLookupByLibrary.simpleMessage(
      "Created (oldest)",
    ),
    "sortByCreatedAtDesc": MessageLookupByLibrary.simpleMessage(
      "Created (newest)",
    ),
    "sortByLastNameAsc": MessageLookupByLibrary.simpleMessage(
      "Last name (A-Z)",
    ),
    "sortByLastNameDesc": MessageLookupByLibrary.simpleMessage(
      "Last name (Z-A)",
    ),
    "sortByNameAsc": MessageLookupByLibrary.simpleMessage("Name (A-Z)"),
    "sortByNameDesc": MessageLookupByLibrary.simpleMessage("Name (Z-A)"),
    "sortByTitle": MessageLookupByLibrary.simpleMessage("Sort by"),
    "staffEditHours": MessageLookupByLibrary.simpleMessage("Edit hours"),
    "staffFilterAllTeam": MessageLookupByLibrary.simpleMessage("All team"),
    "staffFilterOnDuty": MessageLookupByLibrary.simpleMessage("On duty team"),
    "staffFilterSelectMembers": MessageLookupByLibrary.simpleMessage(
      "Select team members",
    ),
    "staffFilterTitle": MessageLookupByLibrary.simpleMessage("Filter team"),
    "staffFilterTooltip": MessageLookupByLibrary.simpleMessage("Filter team"),
    "staffHubAvailabilitySubtitle": MessageLookupByLibrary.simpleMessage(
      "Configure weekly working hours",
    ),
    "staffHubAvailabilityTitle": MessageLookupByLibrary.simpleMessage(
      "Availability",
    ),
    "staffHubNotYetAvailable": MessageLookupByLibrary.simpleMessage(
      "Not yet available",
    ),
    "staffHubStatsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Performance and workloads",
    ),
    "staffHubStatsTitle": MessageLookupByLibrary.simpleMessage("Statistics"),
    "staffHubTeamSubtitle": MessageLookupByLibrary.simpleMessage(
      "Manage members and roles",
    ),
    "staffHubTeamTitle": MessageLookupByLibrary.simpleMessage("Team"),
    "staffNotBookableOnlineMessage": MessageLookupByLibrary.simpleMessage(
      "This team member is not enabled for online bookings. You can change this in the staff edit form.",
    ),
    "staffNotBookableOnlineTitle": MessageLookupByLibrary.simpleMessage(
      "Not bookable online",
    ),
    "staffNotBookableOnlineTooltip": MessageLookupByLibrary.simpleMessage(
      "Not bookable online",
    ),
    "staffScreenPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Team Screen",
    ),
    "switchBusiness": MessageLookupByLibrary.simpleMessage("Switch"),
    "teamAddStaff": MessageLookupByLibrary.simpleMessage("Add team member"),
    "teamChooseLocationSingleButton": MessageLookupByLibrary.simpleMessage(
      "Select location",
    ),
    "teamChooseLocationsButton": MessageLookupByLibrary.simpleMessage(
      "Select locations",
    ),
    "teamDeleteLocationBlockedMessage": MessageLookupByLibrary.simpleMessage(
      "Remove all team members assigned to this location first.",
    ),
    "teamDeleteLocationBlockedTitle": MessageLookupByLibrary.simpleMessage(
      "Cannot delete location",
    ),
    "teamDeleteLocationMessage": MessageLookupByLibrary.simpleMessage(
      "The location will be removed from the team. This action cannot be undone.",
    ),
    "teamDeleteLocationTitle": MessageLookupByLibrary.simpleMessage(
      "Delete location?",
    ),
    "teamDeleteStaffMessage": MessageLookupByLibrary.simpleMessage(
      "The member will be removed from the team. This action cannot be undone.",
    ),
    "teamDeleteStaffTitle": MessageLookupByLibrary.simpleMessage(
      "Delete team member?",
    ),
    "teamEditLocationTitle": MessageLookupByLibrary.simpleMessage(
      "Edit location",
    ),
    "teamEditStaffTitle": MessageLookupByLibrary.simpleMessage(
      "Edit team member",
    ),
    "teamEligibleServicesCount": m42,
    "teamEligibleServicesLabel": MessageLookupByLibrary.simpleMessage(
      "Eligible services",
    ),
    "teamEligibleServicesNone": MessageLookupByLibrary.simpleMessage(
      "No eligible services",
    ),
    "teamEligibleStaffLabel": MessageLookupByLibrary.simpleMessage(
      "Eligible team members",
    ),
    "teamLocationAddressLabel": MessageLookupByLibrary.simpleMessage("Address"),
    "teamLocationAllowCustomerChooseStaffHint":
        MessageLookupByLibrary.simpleMessage(
          "If disabled, the system assigns the team member automatically",
        ),
    "teamLocationAllowCustomerChooseStaffLabel":
        MessageLookupByLibrary.simpleMessage(
          "Allow customers to choose the team member",
        ),
    "teamLocationBookingLimitsSection": MessageLookupByLibrary.simpleMessage(
      "Online booking limits",
    ),
    "teamLocationDays": m43,
    "teamLocationEmailHint": MessageLookupByLibrary.simpleMessage(
      "Email for customer notifications",
    ),
    "teamLocationEmailLabel": MessageLookupByLibrary.simpleMessage("Email"),
    "teamLocationHours": m44,
    "teamLocationIsActiveHint": MessageLookupByLibrary.simpleMessage(
      "If disabled, the location will not be visible to customers",
    ),
    "teamLocationIsActiveLabel": MessageLookupByLibrary.simpleMessage(
      "Location active",
    ),
    "teamLocationLabel": MessageLookupByLibrary.simpleMessage("Location"),
    "teamLocationMaxBookingAdvanceHint": MessageLookupByLibrary.simpleMessage(
      "How far ahead customers can book",
    ),
    "teamLocationMaxBookingAdvanceLabel": MessageLookupByLibrary.simpleMessage(
      "Maximum booking advance",
    ),
    "teamLocationMinBookingNoticeHint": MessageLookupByLibrary.simpleMessage(
      "How far in advance customers must book",
    ),
    "teamLocationMinBookingNoticeLabel": MessageLookupByLibrary.simpleMessage(
      "Minimum booking notice",
    ),
    "teamLocationNameLabel": MessageLookupByLibrary.simpleMessage(
      "Location name",
    ),
    "teamLocationsLabel": MessageLookupByLibrary.simpleMessage("Locations"),
    "teamNewLocationTitle": MessageLookupByLibrary.simpleMessage(
      "New location",
    ),
    "teamNewStaffTitle": MessageLookupByLibrary.simpleMessage(
      "New team member",
    ),
    "teamNoStaffInLocation": MessageLookupByLibrary.simpleMessage(
      "No team members in this location",
    ),
    "teamReorderHelpDescription": MessageLookupByLibrary.simpleMessage(
      "Reorder locations and team members by dragging them. Select whether to sort locations or team. The order will also apply in the agenda section.",
    ),
    "teamSelectAllLocations": MessageLookupByLibrary.simpleMessage(
      "Select all",
    ),
    "teamSelectAllServices": MessageLookupByLibrary.simpleMessage("Select all"),
    "teamSelectedServicesButton": MessageLookupByLibrary.simpleMessage(
      "Selected services",
    ),
    "teamSelectedServicesCount": m45,
    "teamServicesLabel": MessageLookupByLibrary.simpleMessage("Services"),
    "teamStaffBookableOnlineLabel": MessageLookupByLibrary.simpleMessage(
      "Enabled for online bookings",
    ),
    "teamStaffColorLabel": MessageLookupByLibrary.simpleMessage("Color"),
    "teamStaffLabel": MessageLookupByLibrary.simpleMessage("Team"),
    "teamStaffLocationsLabel": MessageLookupByLibrary.simpleMessage(
      "Assigned locations",
    ),
    "teamStaffMultiLocationWarning": MessageLookupByLibrary.simpleMessage(
      "If the member works across multiple locations, make sure availability aligns with the selected locations.",
    ),
    "teamStaffNameLabel": MessageLookupByLibrary.simpleMessage("First name"),
    "teamStaffSurnameLabel": MessageLookupByLibrary.simpleMessage("Last name"),
    "validationInvalidEmail": MessageLookupByLibrary.simpleMessage(
      "Invalid email",
    ),
    "validationInvalidNumber": MessageLookupByLibrary.simpleMessage(
      "Invalid number",
    ),
    "validationInvalidPhone": MessageLookupByLibrary.simpleMessage(
      "Invalid phone",
    ),
    "validationNameOrLastNameRequired": MessageLookupByLibrary.simpleMessage(
      "Enter at least first name or last name",
    ),
    "validationRequired": MessageLookupByLibrary.simpleMessage("Required"),
    "weeklyScheduleAddShift": MessageLookupByLibrary.simpleMessage("Add shift"),
    "weeklyScheduleFor": MessageLookupByLibrary.simpleMessage("to"),
    "weeklyScheduleNotWorking": MessageLookupByLibrary.simpleMessage(
      "Not working",
    ),
    "weeklyScheduleRemoveShift": MessageLookupByLibrary.simpleMessage(
      "Remove shift",
    ),
    "weeklyScheduleTitle": MessageLookupByLibrary.simpleMessage("Weekly"),
    "weeklyScheduleTotalHours": m46,
  };
}
