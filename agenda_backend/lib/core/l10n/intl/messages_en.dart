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

  static String m2(type) => "Email sent of type: ${type}";

  static String m3(channel) => "Type: ${channel}";

  static String m4(email) => "Recipient: ${email}";

  static String m5(dateTime) => "Sent at: ${dateTime}";

  static String m6(subject) => "Subject: ${subject}";

  static String m7(count) => "${count} notifications";

  static String m8(date, time, staffName) =>
      "The booking will be moved to ${date} at ${time} for ${staffName}.";

  static String m9(duration) => "Total duration: ${duration}";

  static String m10(price) => "Total: ${price}";

  static String m11(count) => "${count} bookings";

  static String m12(confirmed, capacity, waitlist) =>
      "Confirmed: ${confirmed}/${capacity} • Waitlist: ${waitlist}";

  static String m13(customerId) => "Customer ${customerId}";

  static String m14(count) => "Create ${count} schedules";

  static String m15(clientName) => "${clientName}\'s appointments";

  static String m16(count) =>
      "${Intl.plural(count, one: '1 day', other: '${count} days')}";

  static String m17(count) =>
      "Import ${Intl.plural(count, one: '1 holiday', other: '${count} holidays')}";

  static String m18(count) =>
      "${Intl.plural(count, one: '1 holiday already added', other: '${count} holidays already added')} (marked with ✓)";

  static String m19(count) =>
      "${Intl.plural(count, one: '1 holiday imported', other: '${count} holidays imported')}";

  static String m20(count) =>
      "for a total of ${Intl.plural(count, one: '1 day', other: '${count} days')}";

  static String m21(hours) => "${hours} hour";

  static String m22(hours, minutes) => "${hours} hour ${minutes} min";

  static String m23(minutes) => "${minutes} min";

  static String m24(id) => "Exception not found: ${id}";

  static String m25(factor) => "No builder available for ${factor}";

  static String m26(path) => "Page not found: ${path}";

  static String m27(count) =>
      "${count} ${Intl.plural(count, one: 'day', other: 'days')}";

  static String m28(dates) => "Some days were not saved: ${dates}.";

  static String m29(details) => "Some days were not saved: ${details}.";

  static String m30(hours) => "${hours}h";

  static String m31(hours, minutes) => "${hours}h ${minutes}m";

  static String m32(businessName, role) =>
      "You were invited to collaborate with ${businessName} as ${role}.";

  static String m33(date) => "Last visit: ${date}";

  static String m34(newTime, staffName) =>
      "The appointment will be moved to ${newTime} for ${staffName}.";

  static String m35(date) => "Accepted on ${date}";

  static String m36(email) =>
      "Do you want to permanently delete the invite for ${email}?";

  static String m37(date) => "Expires on ${date}";

  static String m38(email) => "Invite sent to ${email}";

  static String m39(name) => "Invited by ${name}";

  static String m40(count) => "${count} archived invites";

  static String m41(count) => "${count} pending invites";

  static String m42(name) => "Do you want to remove ${name} from the team?";

  static String m43(email) => "Do you want to revoke the invite for ${email}?";

  static String m44(durationA, durationB, totalDuration) =>
      "Week A: ${durationA} | Week B: ${durationB} | Tot: ${totalDuration}";

  static String m45(hoursA, hoursB, total) =>
      "Week A: ${hoursA}h | Week B: ${hoursB}h | Tot: ${total}h";

  static String m46(week) => "Current week: ${week}";

  static String m47(count) => "Show expired (${count})";

  static String m48(from) => "Valid from ${from}";

  static String m49(from, to) => "Valid from ${from} to ${to}";

  static String m50(from) => "From ${from}";

  static String m51(from, to) => "From ${from} to ${to}";

  static String m52(duration) => "${duration}/week";

  static String m53(hours) => "${hours}h/week";

  static String m54(count) => "Create ${count} appointments";

  static String m55(count) => "${count} conflicts";

  static String m56(count) => "${count} appointments";

  static String m57(count) => "${count} selected";

  static String m58(index, total) => "${index} of ${total}";

  static String m59(count) => "${count} appointments created";

  static String m60(count) => "${count} skipped due to conflicts";

  static String m61(index, total) =>
      "This is appointment ${index} of ${total} in the series.";

  static String m62(index, total) =>
      "This is appointment ${index} of ${total} in the series.";

  static String m63(count) => "${count} services";

  static String m64(count) => "${count} eligible team members";

  static String m65(count, total) => "${count} of ${total} locations";

  static String m66(count) =>
      "${Intl.plural(count, one: '1 service selected', other: '${count} services selected')}";

  static String m67(dayName) =>
      "Delete the weekly time slot for every ${dayName}";

  static String m68(date) => "Delete only the time slot of ${date}";

  static String m69(dayName) =>
      "Edit the weekly time slot for every ${dayName}";

  static String m70(date) => "Edit only the time slot of ${date}";

  static String m71(count) => "${count} eligible services";

  static String m72(value) => "Use business policy (${value})";

  static String m73(count) =>
      "${Intl.plural(count, one: '1 day', other: '${count} days')}";

  static String m74(count) =>
      "${Intl.plural(count, one: '1 hour', other: '${count} hours')}";

  static String m75(count) =>
      "${Intl.plural(count, one: '1 minute', other: '${count} minutes')}";

  static String m76(selected, total) => "${selected} of ${total}";

  static String m77(hours) => "${hours} hours total";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "actionApply": MessageLookupByLibrary.simpleMessage("Apply"),
    "actionCancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "actionClose": MessageLookupByLibrary.simpleMessage("Close"),
    "actionConfirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "actionDelete": MessageLookupByLibrary.simpleMessage("Delete"),
    "actionDeleteBooking": MessageLookupByLibrary.simpleMessage(
      "Delete booking",
    ),
    "actionDeselectAll": MessageLookupByLibrary.simpleMessage("Deselect all"),
    "actionDiscard": MessageLookupByLibrary.simpleMessage("Cancel"),
    "actionEdit": MessageLookupByLibrary.simpleMessage("Edit"),
    "actionKeepEditing": MessageLookupByLibrary.simpleMessage("Keep editing"),
    "actionRefresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "actionReschedule": MessageLookupByLibrary.simpleMessage("Reschedule"),
    "actionRetry": MessageLookupByLibrary.simpleMessage("Retry"),
    "actionSave": MessageLookupByLibrary.simpleMessage("Save"),
    "actionSelectAll": MessageLookupByLibrary.simpleMessage("Select all"),
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
    "authNetworkError": MessageLookupByLibrary.simpleMessage(
      "Could not connect to the server. Check your internet connection.",
    ),
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
    "bookingHistoryEventNotificationSent": MessageLookupByLibrary.simpleMessage(
      "Email sent to customer",
    ),
    "bookingHistoryEventNotificationSentTitle": m2,
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
    "bookingHistoryNotificationChannel": m3,
    "bookingHistoryNotificationChannelCancelled":
        MessageLookupByLibrary.simpleMessage("Booking cancellation"),
    "bookingHistoryNotificationChannelConfirmed":
        MessageLookupByLibrary.simpleMessage("Booking confirmation"),
    "bookingHistoryNotificationChannelReminder":
        MessageLookupByLibrary.simpleMessage("Booking reminder"),
    "bookingHistoryNotificationChannelRescheduled":
        MessageLookupByLibrary.simpleMessage("Booking rescheduled"),
    "bookingHistoryNotificationRecipient": m4,
    "bookingHistoryNotificationSentAt": m5,
    "bookingHistoryNotificationSubject": m6,
    "bookingHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Booking history",
    ),
    "bookingItems": MessageLookupByLibrary.simpleMessage("Services"),
    "bookingNotes": MessageLookupByLibrary.simpleMessage("Booking notes"),
    "bookingNotificationsChannelCancelled":
        MessageLookupByLibrary.simpleMessage("Booking cancelled"),
    "bookingNotificationsChannelConfirmed":
        MessageLookupByLibrary.simpleMessage("Booking created"),
    "bookingNotificationsChannelReminder": MessageLookupByLibrary.simpleMessage(
      "Booking reminder",
    ),
    "bookingNotificationsChannelRescheduled":
        MessageLookupByLibrary.simpleMessage("Booking rescheduled"),
    "bookingNotificationsEmpty": MessageLookupByLibrary.simpleMessage(
      "No notifications found",
    ),
    "bookingNotificationsEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Try adjusting your search filters",
    ),
    "bookingNotificationsFieldAppointment":
        MessageLookupByLibrary.simpleMessage("Appointment"),
    "bookingNotificationsFieldClient": MessageLookupByLibrary.simpleMessage(
      "Client",
    ),
    "bookingNotificationsFieldCreatedAt": MessageLookupByLibrary.simpleMessage(
      "Created at",
    ),
    "bookingNotificationsFieldError": MessageLookupByLibrary.simpleMessage(
      "Error",
    ),
    "bookingNotificationsFieldLocation": MessageLookupByLibrary.simpleMessage(
      "Location",
    ),
    "bookingNotificationsFieldRecipient": MessageLookupByLibrary.simpleMessage(
      "Recipient",
    ),
    "bookingNotificationsFieldSentAt": MessageLookupByLibrary.simpleMessage(
      "Sent at",
    ),
    "bookingNotificationsFieldType": MessageLookupByLibrary.simpleMessage(
      "Type",
    ),
    "bookingNotificationsFilterStatus": MessageLookupByLibrary.simpleMessage(
      "Status",
    ),
    "bookingNotificationsFilterType": MessageLookupByLibrary.simpleMessage(
      "Type",
    ),
    "bookingNotificationsLoadMore": MessageLookupByLibrary.simpleMessage(
      "Load more",
    ),
    "bookingNotificationsNoSubject": MessageLookupByLibrary.simpleMessage(
      "No subject",
    ),
    "bookingNotificationsNotAvailable": MessageLookupByLibrary.simpleMessage(
      "N/A",
    ),
    "bookingNotificationsSearchHint": MessageLookupByLibrary.simpleMessage(
      "Client, recipient, subject",
    ),
    "bookingNotificationsSearchLabel": MessageLookupByLibrary.simpleMessage(
      "Search",
    ),
    "bookingNotificationsStatusAll": MessageLookupByLibrary.simpleMessage(
      "All statuses",
    ),
    "bookingNotificationsStatusFailed": MessageLookupByLibrary.simpleMessage(
      "Failed",
    ),
    "bookingNotificationsStatusPending": MessageLookupByLibrary.simpleMessage(
      "Pending",
    ),
    "bookingNotificationsStatusProcessing":
        MessageLookupByLibrary.simpleMessage("Processing"),
    "bookingNotificationsStatusSent": MessageLookupByLibrary.simpleMessage(
      "Sent",
    ),
    "bookingNotificationsTitle": MessageLookupByLibrary.simpleMessage(
      "Booking Notifications",
    ),
    "bookingNotificationsTotalCount": m7,
    "bookingNotificationsTypeAll": MessageLookupByLibrary.simpleMessage(
      "All types",
    ),
    "bookingRescheduleCancelAction": MessageLookupByLibrary.simpleMessage(
      "Cancel reschedule",
    ),
    "bookingRescheduleConfirmMessage": m8,
    "bookingRescheduleConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm reschedule?",
    ),
    "bookingRescheduleMissingBooking": MessageLookupByLibrary.simpleMessage(
      "Booking not found.",
    ),
    "bookingRescheduleModeHint": MessageLookupByLibrary.simpleMessage(
      "Reschedule mode active: select a date and click a slot.",
    ),
    "bookingRescheduleMoveFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to reschedule the booking.",
    ),
    "bookingStaffNotEligibleWarning": MessageLookupByLibrary.simpleMessage(
      "Warning: the selected team member is not eligible for this service.",
    ),
    "bookingTotal": MessageLookupByLibrary.simpleMessage("Total"),
    "bookingTotalDuration": m9,
    "bookingTotalPrice": m10,
    "bookingUnavailableTimeWarningAppointment":
        MessageLookupByLibrary.simpleMessage(
          "Warning: the appointment time includes unavailable slots for the chosen team.",
        ),
    "bookingUnavailableTimeWarningService": MessageLookupByLibrary.simpleMessage(
      "Warning: this service time includes unavailable slots for the chosen team.",
    ),
    "bookingsListActionCancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "bookingsListActionEdit": MessageLookupByLibrary.simpleMessage("Edit"),
    "bookingsListActionView": MessageLookupByLibrary.simpleMessage("Details"),
    "bookingsListAllLocations": MessageLookupByLibrary.simpleMessage(
      "All locations",
    ),
    "bookingsListAllServices": MessageLookupByLibrary.simpleMessage(
      "All services",
    ),
    "bookingsListAllStaff": MessageLookupByLibrary.simpleMessage("All staff"),
    "bookingsListAllStatus": MessageLookupByLibrary.simpleMessage(
      "All statuses",
    ),
    "bookingsListCancelConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "This action cannot be undone.",
    ),
    "bookingsListCancelConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Cancel booking?",
    ),
    "bookingsListCancelSuccess": MessageLookupByLibrary.simpleMessage(
      "Booking cancelled",
    ),
    "bookingsListColumnActions": MessageLookupByLibrary.simpleMessage(
      "Actions",
    ),
    "bookingsListColumnClient": MessageLookupByLibrary.simpleMessage("Client"),
    "bookingsListColumnCreatedAt": MessageLookupByLibrary.simpleMessage(
      "Created on",
    ),
    "bookingsListColumnCreatedBy": MessageLookupByLibrary.simpleMessage(
      "Created by",
    ),
    "bookingsListColumnDateTime": MessageLookupByLibrary.simpleMessage(
      "Date/Time",
    ),
    "bookingsListColumnPrice": MessageLookupByLibrary.simpleMessage("Price"),
    "bookingsListColumnServices": MessageLookupByLibrary.simpleMessage(
      "Services",
    ),
    "bookingsListColumnStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "bookingsListColumnStatus": MessageLookupByLibrary.simpleMessage("Status"),
    "bookingsListEmpty": MessageLookupByLibrary.simpleMessage(
      "No bookings found",
    ),
    "bookingsListEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Try adjusting your search filters",
    ),
    "bookingsListFilterClient": MessageLookupByLibrary.simpleMessage(
      "Search client",
    ),
    "bookingsListFilterClientHint": MessageLookupByLibrary.simpleMessage(
      "Name, email or phone",
    ),
    "bookingsListFilterFutureOnly": MessageLookupByLibrary.simpleMessage(
      "Future only",
    ),
    "bookingsListFilterIncludePast": MessageLookupByLibrary.simpleMessage(
      "Include past",
    ),
    "bookingsListFilterLocation": MessageLookupByLibrary.simpleMessage(
      "Location",
    ),
    "bookingsListFilterPeriod": MessageLookupByLibrary.simpleMessage("Period"),
    "bookingsListFilterService": MessageLookupByLibrary.simpleMessage(
      "Service",
    ),
    "bookingsListFilterStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "bookingsListFilterStatus": MessageLookupByLibrary.simpleMessage("Status"),
    "bookingsListFilterTitle": MessageLookupByLibrary.simpleMessage("Filters"),
    "bookingsListLoadMore": MessageLookupByLibrary.simpleMessage("Load more"),
    "bookingsListLoading": MessageLookupByLibrary.simpleMessage("Loading..."),
    "bookingsListNoClient": MessageLookupByLibrary.simpleMessage("No client"),
    "bookingsListResetFilters": MessageLookupByLibrary.simpleMessage(
      "Reset filters",
    ),
    "bookingsListSortAsc": MessageLookupByLibrary.simpleMessage("Ascending"),
    "bookingsListSortByAppointment": MessageLookupByLibrary.simpleMessage(
      "Appointment date",
    ),
    "bookingsListSortByCreated": MessageLookupByLibrary.simpleMessage(
      "Creation date",
    ),
    "bookingsListSortDesc": MessageLookupByLibrary.simpleMessage("Descending"),
    "bookingsListSourceInternal": MessageLookupByLibrary.simpleMessage(
      "Back office",
    ),
    "bookingsListSourceOnline": MessageLookupByLibrary.simpleMessage("Online"),
    "bookingsListSourcePhone": MessageLookupByLibrary.simpleMessage("Phone"),
    "bookingsListSourceWalkIn": MessageLookupByLibrary.simpleMessage("Walk-in"),
    "bookingsListStatusCancelled": MessageLookupByLibrary.simpleMessage(
      "Cancelled",
    ),
    "bookingsListStatusCompleted": MessageLookupByLibrary.simpleMessage(
      "Completed",
    ),
    "bookingsListStatusConfirmed": MessageLookupByLibrary.simpleMessage(
      "Confirmed",
    ),
    "bookingsListStatusNoShow": MessageLookupByLibrary.simpleMessage("No show"),
    "bookingsListStatusPending": MessageLookupByLibrary.simpleMessage(
      "Pending",
    ),
    "bookingsListStatusReplaced": MessageLookupByLibrary.simpleMessage(
      "Replaced",
    ),
    "bookingsListTitle": MessageLookupByLibrary.simpleMessage("Bookings List"),
    "bookingsListTotalCount": m11,
    "businessOnlineBookingsNotificationEmailHelper":
        MessageLookupByLibrary.simpleMessage(
          "Receives notifications only when customers create/modify/cancel online bookings",
        ),
    "businessOnlineBookingsNotificationEmailHint":
        MessageLookupByLibrary.simpleMessage("e.g. bookings@business.com"),
    "businessOnlineBookingsNotificationEmailLabel":
        MessageLookupByLibrary.simpleMessage(
          "Online bookings notification email",
        ),
    "businessServiceColorPaletteEnhanced": MessageLookupByLibrary.simpleMessage(
      "Darker (recommended)",
    ),
    "businessServiceColorPaletteHelper": MessageLookupByLibrary.simpleMessage(
      "Defines colors used in service selection and agenda cards",
    ),
    "businessServiceColorPaletteLabel": MessageLookupByLibrary.simpleMessage(
      "Service color palette",
    ),
    "businessServiceColorPaletteLegacy": MessageLookupByLibrary.simpleMessage(
      "Original",
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
    "classEventsActionBook": MessageLookupByLibrary.simpleMessage("Book"),
    "classEventsActionCancelBooking": MessageLookupByLibrary.simpleMessage(
      "Cancel booking",
    ),
    "classEventsAddButton": MessageLookupByLibrary.simpleMessage("Add"),
    "classEventsCapacitySummary": m12,
    "classEventsCreateErrorMessage": MessageLookupByLibrary.simpleMessage(
      "Unable to create class",
    ),
    "classEventsCreateSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "The class was created successfully",
    ),
    "classEventsCreateSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "Class created",
    ),
    "classEventsCreateTitle": MessageLookupByLibrary.simpleMessage(
      "Scheduling",
    ),
    "classEventsEditModeLabel": MessageLookupByLibrary.simpleMessage(
      "Edit mode",
    ),
    "classEventsEditTitle": MessageLookupByLibrary.simpleMessage(
      "Edit scheduling",
    ),
    "classEventsEmpty": MessageLookupByLibrary.simpleMessage(
      "No classes in the selected day.",
    ),
    "classEventsExpiredBadge": MessageLookupByLibrary.simpleMessage("Expired"),
    "classEventsFieldCapacity": MessageLookupByLibrary.simpleMessage(
      "Capacity",
    ),
    "classEventsFieldClassType": MessageLookupByLibrary.simpleMessage(
      "Class type",
    ),
    "classEventsFieldDate": MessageLookupByLibrary.simpleMessage("Date"),
    "classEventsFieldEndTime": MessageLookupByLibrary.simpleMessage("End time"),
    "classEventsFieldLocation": MessageLookupByLibrary.simpleMessage(
      "Location",
    ),
    "classEventsFieldStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "classEventsFieldStartTime": MessageLookupByLibrary.simpleMessage(
      "Start time",
    ),
    "classEventsFieldTitleOptional": MessageLookupByLibrary.simpleMessage(
      "Title (optional)",
    ),
    "classEventsFutureBadge": MessageLookupByLibrary.simpleMessage("Future"),
    "classEventsNewScheduleButton": MessageLookupByLibrary.simpleMessage(
      "New schedule",
    ),
    "classEventsNoClassTypes": MessageLookupByLibrary.simpleMessage(
      "No class types available",
    ),
    "classEventsNoLocationsForClassType": MessageLookupByLibrary.simpleMessage(
      "No enabled location for this class type",
    ),
    "classEventsNoStaffForLocation": MessageLookupByLibrary.simpleMessage(
      "No staff available for selected location",
    ),
    "classEventsParticipantCustomer": m13,
    "classEventsParticipantsTitle": MessageLookupByLibrary.simpleMessage(
      "Participants",
    ),
    "classEventsRecurrenceConflictForceDescription":
        MessageLookupByLibrary.simpleMessage(
          "Create schedules even if there are overlaps",
        ),
    "classEventsRecurrenceConflictSkipDescription":
        MessageLookupByLibrary.simpleMessage(
          "Do not create schedules if there are overlaps",
        ),
    "classEventsRecurrencePreviewConfirm": m14,
    "classEventsRecurrencePreviewHint": MessageLookupByLibrary.simpleMessage(
      "Deselect schedules you do not want to create",
    ),
    "classEventsRecurrencePreviewTitle": MessageLookupByLibrary.simpleMessage(
      "Schedule preview",
    ),
    "classEventsRepeatSchedule": MessageLookupByLibrary.simpleMessage(
      "Repeat schedule",
    ),
    "classEventsSchedulesDeleteConfirmMessage":
        MessageLookupByLibrary.simpleMessage(
          "Deleting the schedule will also delete any existing bookings.",
        ),
    "classEventsSchedulesDeleteConfirmTitle":
        MessageLookupByLibrary.simpleMessage("Delete schedule?"),
    "classEventsSchedulesDeleteSuccessMessage":
        MessageLookupByLibrary.simpleMessage(
          "The schedule and related bookings have been deleted",
        ),
    "classEventsSchedulesDeleteSuccessTitle":
        MessageLookupByLibrary.simpleMessage("Schedule deleted"),
    "classEventsSchedulesListEmpty": MessageLookupByLibrary.simpleMessage(
      "No schedules",
    ),
    "classEventsSchedulesListTitle": MessageLookupByLibrary.simpleMessage(
      "Existing schedules",
    ),
    "classEventsSchedulesUpdateSuccessMessage":
        MessageLookupByLibrary.simpleMessage("Schedule updated successfully"),
    "classEventsSchedulesUpdateSuccessTitle":
        MessageLookupByLibrary.simpleMessage("Schedule updated"),
    "classEventsShowExpiredSchedules": MessageLookupByLibrary.simpleMessage(
      "Show expired too",
    ),
    "classEventsTitle": MessageLookupByLibrary.simpleMessage("Classes"),
    "classEventsUntitled": MessageLookupByLibrary.simpleMessage("Class"),
    "classEventsValidationEndAfterStart": MessageLookupByLibrary.simpleMessage(
      "End time must be after start time",
    ),
    "classEventsValidationRequired": MessageLookupByLibrary.simpleMessage(
      "Fill all required fields",
    ),
    "classTypesActionClone": MessageLookupByLibrary.simpleMessage("Duplicate"),
    "classTypesActionDeactivate": MessageLookupByLibrary.simpleMessage(
      "Delete",
    ),
    "classTypesActionReactivate": MessageLookupByLibrary.simpleMessage(
      "Reactivate",
    ),
    "classTypesActionScheduleClass": MessageLookupByLibrary.simpleMessage(
      "Scheduling",
    ),
    "classTypesAddButton": MessageLookupByLibrary.simpleMessage("New type"),
    "classTypesCloneSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "Class type duplicated successfully",
    ),
    "classTypesCloneSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "Class type duplicated",
    ),
    "classTypesCloneSuffix": MessageLookupByLibrary.simpleMessage("Copy"),
    "classTypesCreateSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "Class type created successfully",
    ),
    "classTypesCreateSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "Class type created",
    ),
    "classTypesCreateTitle": MessageLookupByLibrary.simpleMessage(
      "New class type",
    ),
    "classTypesDeactivateConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "The class type will be deactivated and unavailable for new schedules.",
    ),
    "classTypesDeactivateConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Delete class type?",
    ),
    "classTypesDeactivateSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "Class type has been deactivated",
    ),
    "classTypesDeactivateSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "Class type deleted",
    ),
    "classTypesDeleteConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "This action permanently deletes the class type.",
    ),
    "classTypesDeleteConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Delete class type?",
    ),
    "classTypesDeleteInUseErrorMessage": MessageLookupByLibrary.simpleMessage(
      "Cannot delete class type because there are associated schedules",
    ),
    "classTypesDeleteSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "Class type has been deleted",
    ),
    "classTypesDeleteSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "Class type deleted",
    ),
    "classTypesEditTitle": MessageLookupByLibrary.simpleMessage(
      "Edit class type",
    ),
    "classTypesEmpty": MessageLookupByLibrary.simpleMessage(
      "No class types configured",
    ),
    "classTypesFieldDescriptionOptional": MessageLookupByLibrary.simpleMessage(
      "Description (optional)",
    ),
    "classTypesFieldIsActive": MessageLookupByLibrary.simpleMessage(
      "Type active",
    ),
    "classTypesFieldName": MessageLookupByLibrary.simpleMessage("Name"),
    "classTypesManageButton": MessageLookupByLibrary.simpleMessage(
      "Class types",
    ),
    "classTypesManageTitle": MessageLookupByLibrary.simpleMessage(
      "Class types",
    ),
    "classTypesMutationErrorMessage": MessageLookupByLibrary.simpleMessage(
      "Unable to save class type",
    ),
    "classTypesReactivateConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "The class type will be available again for new schedules.",
    ),
    "classTypesReactivateConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Reactivate class type?",
    ),
    "classTypesReactivateSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "Class type has been reactivated",
    ),
    "classTypesReactivateSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "Class type reactivated",
    ),
    "classTypesStatusActive": MessageLookupByLibrary.simpleMessage("Active"),
    "classTypesStatusInactive": MessageLookupByLibrary.simpleMessage(
      "Inactive",
    ),
    "classTypesUpdateSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "Class type updated successfully",
    ),
    "classTypesUpdateSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "Class type updated",
    ),
    "clientAppointmentsCancelledBadge": MessageLookupByLibrary.simpleMessage(
      "CANCELLED",
    ),
    "clientAppointmentsEmpty": MessageLookupByLibrary.simpleMessage(
      "No appointments",
    ),
    "clientAppointmentsPast": MessageLookupByLibrary.simpleMessage("Past"),
    "clientAppointmentsTitle": m15,
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
    "closuresAddButton": MessageLookupByLibrary.simpleMessage("Add closure"),
    "closuresAddSuccess": MessageLookupByLibrary.simpleMessage("Closure added"),
    "closuresAllLocations": MessageLookupByLibrary.simpleMessage(
      "All locations",
    ),
    "closuresDateRange": MessageLookupByLibrary.simpleMessage("Date range"),
    "closuresDays": m16,
    "closuresDeleteConfirm": MessageLookupByLibrary.simpleMessage(
      "Delete this closure?",
    ),
    "closuresDeleteConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "Booking slots during this period will become available again.",
    ),
    "closuresDeleteSuccess": MessageLookupByLibrary.simpleMessage(
      "Closure deleted",
    ),
    "closuresDeselectAll": MessageLookupByLibrary.simpleMessage("Deselect all"),
    "closuresEditTitle": MessageLookupByLibrary.simpleMessage("Edit closure"),
    "closuresEmpty": MessageLookupByLibrary.simpleMessage(
      "No closures scheduled",
    ),
    "closuresEmptyForPeriod": MessageLookupByLibrary.simpleMessage(
      "No closures scheduled for the selected period",
    ),
    "closuresEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Add business closure periods (e.g. holidays, vacations)",
    ),
    "closuresEndDate": MessageLookupByLibrary.simpleMessage("End date"),
    "closuresFilterAll": MessageLookupByLibrary.simpleMessage("All"),
    "closuresFilterFromToday": MessageLookupByLibrary.simpleMessage(
      "From today",
    ),
    "closuresImportHolidays": MessageLookupByLibrary.simpleMessage(
      "Import holidays",
    ),
    "closuresImportHolidaysAction": m17,
    "closuresImportHolidaysAlreadyAdded": m18,
    "closuresImportHolidaysList": MessageLookupByLibrary.simpleMessage(
      "Select holidays to import:",
    ),
    "closuresImportHolidaysLocations": MessageLookupByLibrary.simpleMessage(
      "Apply to locations:",
    ),
    "closuresImportHolidaysSuccess": m19,
    "closuresImportHolidaysTitle": MessageLookupByLibrary.simpleMessage(
      "Import national holidays",
    ),
    "closuresImportHolidaysUnsupportedCountry":
        MessageLookupByLibrary.simpleMessage(
          "Automatic holidays are not available for the country configured in the location.",
        ),
    "closuresImportHolidaysYear": MessageLookupByLibrary.simpleMessage("Year:"),
    "closuresInvalidDateRange": MessageLookupByLibrary.simpleMessage(
      "End date must be equal to or after start date",
    ),
    "closuresLocations": MessageLookupByLibrary.simpleMessage(
      "Affected locations",
    ),
    "closuresNewTitle": MessageLookupByLibrary.simpleMessage("New closure"),
    "closuresNoLocations": MessageLookupByLibrary.simpleMessage(
      "No locations configured",
    ),
    "closuresOverlapError": MessageLookupByLibrary.simpleMessage(
      "Dates overlap with an existing closure",
    ),
    "closuresPast": MessageLookupByLibrary.simpleMessage("Previous closures"),
    "closuresReason": MessageLookupByLibrary.simpleMessage("Reason (optional)"),
    "closuresReasonHint": MessageLookupByLibrary.simpleMessage(
      "e.g. Holiday, Summer vacation, Maintenance...",
    ),
    "closuresSelectAll": MessageLookupByLibrary.simpleMessage("Select all"),
    "closuresSelectAtLeastOneLocation": MessageLookupByLibrary.simpleMessage(
      "Select at least one location",
    ),
    "closuresSingleDay": MessageLookupByLibrary.simpleMessage("Single day"),
    "closuresStartDate": MessageLookupByLibrary.simpleMessage("Start date"),
    "closuresTitle": MessageLookupByLibrary.simpleMessage("Closure dates"),
    "closuresTotalDays": m20,
    "closuresUpcoming": MessageLookupByLibrary.simpleMessage(
      "Upcoming closures",
    ),
    "closuresUpdateSuccess": MessageLookupByLibrary.simpleMessage(
      "Closure updated",
    ),
    "createCategoryButtonLabel": MessageLookupByLibrary.simpleMessage(
      "New category",
    ),
    "createNewClient": MessageLookupByLibrary.simpleMessage(
      "Create new client",
    ),
    "currentWeek": MessageLookupByLibrary.simpleMessage("Current week"),
    "dayFriday": MessageLookupByLibrary.simpleMessage("Friday"),
    "dayFridayFull": MessageLookupByLibrary.simpleMessage("Friday"),
    "dayMonday": MessageLookupByLibrary.simpleMessage("Monday"),
    "dayMondayFull": MessageLookupByLibrary.simpleMessage("Monday"),
    "daySaturday": MessageLookupByLibrary.simpleMessage("Saturday"),
    "daySaturdayFull": MessageLookupByLibrary.simpleMessage("Saturday"),
    "daySunday": MessageLookupByLibrary.simpleMessage("Sunday"),
    "daySundayFull": MessageLookupByLibrary.simpleMessage("Sunday"),
    "dayThursday": MessageLookupByLibrary.simpleMessage("Thursday"),
    "dayThursdayFull": MessageLookupByLibrary.simpleMessage("Thursday"),
    "dayTuesday": MessageLookupByLibrary.simpleMessage("Tuesday"),
    "dayTuesdayFull": MessageLookupByLibrary.simpleMessage("Tuesday"),
    "dayWednesday": MessageLookupByLibrary.simpleMessage("Wednesday"),
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
    "durationHour": m21,
    "durationHourMinute": m22,
    "durationMinute": m23,
    "editCategoryTitle": MessageLookupByLibrary.simpleMessage("Edit category"),
    "editServiceTitle": MessageLookupByLibrary.simpleMessage("Edit service"),
    "emptyCategoriesNotReorderableNote": MessageLookupByLibrary.simpleMessage(
      "Categories without services cannot be reordered and stay at the end.",
    ),
    "errorExceptionNotFound": m24,
    "errorFormFactorBuilderMissing": m25,
    "errorFormFactorBuilderRequired": MessageLookupByLibrary.simpleMessage(
      "Specify at least one builder for form factor",
    ),
    "errorNotFound": m26,
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
    "exceptionDurationDays": m27,
    "exceptionEditShift": MessageLookupByLibrary.simpleMessage(
      "Edit exception",
    ),
    "exceptionEditShiftDesc": MessageLookupByLibrary.simpleMessage(
      "Edit the times of this exception",
    ),
    "exceptionEndTime": MessageLookupByLibrary.simpleMessage("End time"),
    "exceptionPartialSaveInfo": m28,
    "exceptionPartialSaveInfoDetailed": m29,
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
    "hoursHoursOnly": m30,
    "hoursMinutesCompact": m31,
    "invitationAcceptAndLoginAction": MessageLookupByLibrary.simpleMessage(
      "Accept and sign in",
    ),
    "invitationAcceptButton": MessageLookupByLibrary.simpleMessage(
      "Accept invitation",
    ),
    "invitationAcceptErrorEmailMismatch": MessageLookupByLibrary.simpleMessage(
      "This invitation is linked to a different email. Sign out from the current account, then reopen this invitation link and sign in with the invited email.",
    ),
    "invitationAcceptErrorExpired": MessageLookupByLibrary.simpleMessage(
      "This invitation has expired.",
    ),
    "invitationAcceptErrorGeneric": MessageLookupByLibrary.simpleMessage(
      "Unable to complete the operation. Please try again.",
    ),
    "invitationAcceptErrorInvalid": MessageLookupByLibrary.simpleMessage(
      "This invitation is not valid.",
    ),
    "invitationAcceptHintExistingAccount": MessageLookupByLibrary.simpleMessage(
      "Already have an account? Sign in to accept the invitation.",
    ),
    "invitationAcceptHintNoAccount": MessageLookupByLibrary.simpleMessage(
      "No account yet? Register first.",
    ),
    "invitationAcceptInProgress": MessageLookupByLibrary.simpleMessage(
      "Accepting invitation...",
    ),
    "invitationAcceptIntro": m32,
    "invitationAcceptLoading": MessageLookupByLibrary.simpleMessage(
      "Checking invitation...",
    ),
    "invitationAcceptLoginAction": MessageLookupByLibrary.simpleMessage(
      "Accept to continue",
    ),
    "invitationAcceptLoginRequired": MessageLookupByLibrary.simpleMessage(
      "Sign in with the invited email to continue.",
    ),
    "invitationAcceptRequiresRegistration":
        MessageLookupByLibrary.simpleMessage(
          "No account exists for this email yet. Use Register.",
        ),
    "invitationAcceptSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "You can now use the management app with assigned permissions.",
    ),
    "invitationAcceptSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "Invitation accepted",
    ),
    "invitationAcceptTitle": MessageLookupByLibrary.simpleMessage(
      "Accept invitation",
    ),
    "invitationDeclineButton": MessageLookupByLibrary.simpleMessage(
      "Decline invitation",
    ),
    "invitationDeclineGoLogin": MessageLookupByLibrary.simpleMessage(
      "Go to login",
    ),
    "invitationDeclineInProgress": MessageLookupByLibrary.simpleMessage(
      "Declining invitation...",
    ),
    "invitationDeclineSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "You declined the invitation. No permission has been granted.",
    ),
    "invitationDeclineSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "Invitation declined",
    ),
    "invitationGoToApplication": MessageLookupByLibrary.simpleMessage(
      "Go to application",
    ),
    "invitationRegisterAction": MessageLookupByLibrary.simpleMessage(
      "Register to accept",
    ),
    "invitationRegisterExistingUser": MessageLookupByLibrary.simpleMessage(
      "Email already registered. Sign in to accept the invitation.",
    ),
    "invitationRegisterInProgress": MessageLookupByLibrary.simpleMessage(
      "Registering...",
    ),
    "invitationRegisterPasswordConfirm": MessageLookupByLibrary.simpleMessage(
      "Confirm password",
    ),
    "invitationRegisterPasswordMismatch": MessageLookupByLibrary.simpleMessage(
      "Passwords do not match.",
    ),
    "invitationRegisterPasswordTooShort": MessageLookupByLibrary.simpleMessage(
      "Password must be at least 8 characters long.",
    ),
    "invitationRegisterPasswordWeak": MessageLookupByLibrary.simpleMessage(
      "Password must include at least one uppercase letter, one lowercase letter, and one number.",
    ),
    "invitationRegisterTitle": MessageLookupByLibrary.simpleMessage(
      "Register to accept invitation",
    ),
    "labelSelect": MessageLookupByLibrary.simpleMessage("Select"),
    "labelStaff": MessageLookupByLibrary.simpleMessage("Team:"),
    "lastVisitLabel": m33,
    "minutesLabel": MessageLookupByLibrary.simpleMessage("min"),
    "moreBookingNotificationsDescription": MessageLookupByLibrary.simpleMessage(
      "View booking notifications history",
    ),
    "moreBookingsDescription": MessageLookupByLibrary.simpleMessage(
      "Browse booking history",
    ),
    "moreProfileDescription": MessageLookupByLibrary.simpleMessage(
      "Manage your personal data and credentials",
    ),
    "moreReportsDescription": MessageLookupByLibrary.simpleMessage(
      "View statistics and business performance",
    ),
    "moreServicesDescription": MessageLookupByLibrary.simpleMessage(
      "Manage services, categories and pricing",
    ),
    "moreSubtitle": MessageLookupByLibrary.simpleMessage(
      "Access other application features",
    ),
    "moreSwitchBusinessDescription": MessageLookupByLibrary.simpleMessage(
      "Switch to another business",
    ),
    "moreTeamDescription": MessageLookupByLibrary.simpleMessage(
      "Manage operators, locations and working hours",
    ),
    "moveAppointmentConfirmMessage": m34,
    "moveAppointmentConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm move?",
    ),
    "navAgenda": MessageLookupByLibrary.simpleMessage("Agenda"),
    "navClients": MessageLookupByLibrary.simpleMessage("Clients"),
    "navMore": MessageLookupByLibrary.simpleMessage("More"),
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
    "noServicesFound": MessageLookupByLibrary.simpleMessage(
      "No services found",
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
    "operatorsAcceptedOn": m35,
    "operatorsDeleteInvite": MessageLookupByLibrary.simpleMessage(
      "Delete invite",
    ),
    "operatorsDeleteInviteConfirm": m36,
    "operatorsEditRole": MessageLookupByLibrary.simpleMessage("Edit role"),
    "operatorsEmpty": MessageLookupByLibrary.simpleMessage(
      "No operators configured",
    ),
    "operatorsExpires": m37,
    "operatorsInviteAlreadyHasAccess": MessageLookupByLibrary.simpleMessage(
      "This user already has access to the business.",
    ),
    "operatorsInviteAlreadyPending": MessageLookupByLibrary.simpleMessage(
      "An invite is already pending for this email. You can resend it from the pending invites list.",
    ),
    "operatorsInviteCopied": MessageLookupByLibrary.simpleMessage(
      "Invite link copied",
    ),
    "operatorsInviteEmail": MessageLookupByLibrary.simpleMessage("Email"),
    "operatorsInviteEmailFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to send the invitation email. Please try again later.",
    ),
    "operatorsInviteEmailUnavailable": MessageLookupByLibrary.simpleMessage(
      "Email sending is unavailable in this environment. Please contact support.",
    ),
    "operatorsInviteError": MessageLookupByLibrary.simpleMessage(
      "Unable to send invite",
    ),
    "operatorsInviteRole": MessageLookupByLibrary.simpleMessage("Role"),
    "operatorsInviteSend": MessageLookupByLibrary.simpleMessage("Send invite"),
    "operatorsInviteStatusAccepted": MessageLookupByLibrary.simpleMessage(
      "Accepted",
    ),
    "operatorsInviteStatusDeclined": MessageLookupByLibrary.simpleMessage(
      "Declined",
    ),
    "operatorsInviteStatusExpired": MessageLookupByLibrary.simpleMessage(
      "Expired",
    ),
    "operatorsInviteStatusPending": MessageLookupByLibrary.simpleMessage(
      "Pending",
    ),
    "operatorsInviteStatusRevoked": MessageLookupByLibrary.simpleMessage(
      "Revoked",
    ),
    "operatorsInviteSubtitle": MessageLookupByLibrary.simpleMessage(
      "Send an invite via email",
    ),
    "operatorsInviteSuccess": m38,
    "operatorsInviteTitle": MessageLookupByLibrary.simpleMessage(
      "Invite operator",
    ),
    "operatorsInvitedBy": m39,
    "operatorsInvitesHistoryCount": m40,
    "operatorsPendingInvites": MessageLookupByLibrary.simpleMessage(
      "Pending invites",
    ),
    "operatorsPendingInvitesCount": m41,
    "operatorsRemove": MessageLookupByLibrary.simpleMessage("Remove operator"),
    "operatorsRemoveConfirm": m42,
    "operatorsRemoveSuccess": MessageLookupByLibrary.simpleMessage(
      "Operator removed",
    ),
    "operatorsRevokeInvite": MessageLookupByLibrary.simpleMessage(
      "Revoke invite",
    ),
    "operatorsRevokeInviteConfirm": m43,
    "operatorsRoleAdmin": MessageLookupByLibrary.simpleMessage("Administrator"),
    "operatorsRoleAdminDesc": MessageLookupByLibrary.simpleMessage(
      "Full access to all features. Can manage other operators and modify business settings.",
    ),
    "operatorsRoleDescription": MessageLookupByLibrary.simpleMessage(
      "Select access level",
    ),
    "operatorsRoleManager": MessageLookupByLibrary.simpleMessage("Manager"),
    "operatorsRoleManagerDesc": MessageLookupByLibrary.simpleMessage(
      "Manages agenda and clients. Can view and manage all appointments, but cannot manage operators or settings.",
    ),
    "operatorsRoleOwner": MessageLookupByLibrary.simpleMessage("Owner"),
    "operatorsRoleStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "operatorsRoleStaffDesc": MessageLookupByLibrary.simpleMessage(
      "Views and manages only own appointments. Can create bookings assigned to themselves.",
    ),
    "operatorsRoleViewer": MessageLookupByLibrary.simpleMessage("Viewer"),
    "operatorsRoleViewerDesc": MessageLookupByLibrary.simpleMessage(
      "Can view appointments, services, staff, and availability. No edits allowed.",
    ),
    "operatorsScopeBusiness": MessageLookupByLibrary.simpleMessage(
      "All locations",
    ),
    "operatorsScopeBusinessDesc": MessageLookupByLibrary.simpleMessage(
      "Full access to all business locations",
    ),
    "operatorsScopeLocations": MessageLookupByLibrary.simpleMessage(
      "Specific locations",
    ),
    "operatorsScopeLocationsDesc": MessageLookupByLibrary.simpleMessage(
      "Access limited to selected locations",
    ),
    "operatorsScopeLocationsRequired": MessageLookupByLibrary.simpleMessage(
      "Select at least one location",
    ),
    "operatorsScopeSelectLocations": MessageLookupByLibrary.simpleMessage(
      "Select locations",
    ),
    "operatorsScopeTitle": MessageLookupByLibrary.simpleMessage("Access"),
    "operatorsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Manage who can access the platform",
    ),
    "operatorsTitle": MessageLookupByLibrary.simpleMessage("Operators"),
    "operatorsYou": MessageLookupByLibrary.simpleMessage("You"),
    "permissionsDescription": MessageLookupByLibrary.simpleMessage(
      "Manage operator access and roles",
    ),
    "permissionsTitle": MessageLookupByLibrary.simpleMessage("Permissions"),
    "planningActive": MessageLookupByLibrary.simpleMessage("Active"),
    "planningBiweeklyDuration": m44,
    "planningBiweeklyHours": m45,
    "planningCreateTitle": MessageLookupByLibrary.simpleMessage("New planning"),
    "planningCurrentWeek": m46,
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
    "planningShowExpired": m47,
    "planningType": MessageLookupByLibrary.simpleMessage("Planning type"),
    "planningTypeBiweekly": MessageLookupByLibrary.simpleMessage("Biweekly"),
    "planningTypeUnavailable": MessageLookupByLibrary.simpleMessage(
      "Unavailable",
    ),
    "planningTypeWeekly": MessageLookupByLibrary.simpleMessage("Weekly"),
    "planningValidFrom": MessageLookupByLibrary.simpleMessage(
      "Validity start date",
    ),
    "planningValidFromOnly": m48,
    "planningValidFromTo": m49,
    "planningValidTo": MessageLookupByLibrary.simpleMessage(
      "Validity end date",
    ),
    "planningValidityFrom": m50,
    "planningValidityRange": m51,
    "planningWeekA": MessageLookupByLibrary.simpleMessage("Week A"),
    "planningWeekB": MessageLookupByLibrary.simpleMessage("Week B"),
    "planningWeeklyDuration": m52,
    "planningWeeklyHours": m53,
    "popularServicesTitle": MessageLookupByLibrary.simpleMessage(
      "Most popular",
    ),
    "priceNotAvailable": MessageLookupByLibrary.simpleMessage("N/A"),
    "priceStartingFromPrefix": MessageLookupByLibrary.simpleMessage(
      "starting from",
    ),
    "priceStartingFromSwitch": MessageLookupByLibrary.simpleMessage(
      "Price “starting from”",
    ),
    "profileChangePassword": MessageLookupByLibrary.simpleMessage(
      "Change password",
    ),
    "profileEmailChangeWarning": MessageLookupByLibrary.simpleMessage(
      "Warning: changing email will update your login credentials",
    ),
    "profileSwitchBusiness": MessageLookupByLibrary.simpleMessage(
      "Switch business",
    ),
    "profileTitle": MessageLookupByLibrary.simpleMessage("Profile"),
    "profileUpdateSuccess": MessageLookupByLibrary.simpleMessage(
      "Profile updated successfully",
    ),
    "recurrenceAfter": MessageLookupByLibrary.simpleMessage("After"),
    "recurrenceClientRequired": MessageLookupByLibrary.simpleMessage(
      "A client must be selected for recurring appointments",
    ),
    "recurrenceConflictForce": MessageLookupByLibrary.simpleMessage(
      "Create anyway",
    ),
    "recurrenceConflictForceDescription": MessageLookupByLibrary.simpleMessage(
      "Create appointments even if there are overlaps",
    ),
    "recurrenceConflictHandling": MessageLookupByLibrary.simpleMessage(
      "Overlaps",
    ),
    "recurrenceConflictSkip": MessageLookupByLibrary.simpleMessage(
      "Skip conflicting dates",
    ),
    "recurrenceConflictSkipDescription": MessageLookupByLibrary.simpleMessage(
      "Don\'t create appointments if there are overlaps",
    ),
    "recurrenceDay": MessageLookupByLibrary.simpleMessage("day"),
    "recurrenceDays": MessageLookupByLibrary.simpleMessage("days"),
    "recurrenceEnds": MessageLookupByLibrary.simpleMessage("Ends"),
    "recurrenceEvery": MessageLookupByLibrary.simpleMessage("Every"),
    "recurrenceFrequency": MessageLookupByLibrary.simpleMessage("Frequency"),
    "recurrenceMonth": MessageLookupByLibrary.simpleMessage("month"),
    "recurrenceMonths": MessageLookupByLibrary.simpleMessage("months"),
    "recurrenceNever": MessageLookupByLibrary.simpleMessage("For one year"),
    "recurrenceOccurrences": MessageLookupByLibrary.simpleMessage(
      "occurrences",
    ),
    "recurrenceOnDate": MessageLookupByLibrary.simpleMessage("On"),
    "recurrencePreviewConfirm": m54,
    "recurrencePreviewConflictForce": MessageLookupByLibrary.simpleMessage(
      "Create anyway",
    ),
    "recurrencePreviewConflictSkip": MessageLookupByLibrary.simpleMessage(
      "Skip due to conflict",
    ),
    "recurrencePreviewConflicts": m55,
    "recurrencePreviewCount": m56,
    "recurrencePreviewHint": MessageLookupByLibrary.simpleMessage(
      "Uncheck the dates you don\'t want to create",
    ),
    "recurrencePreviewSelected": m57,
    "recurrencePreviewTitle": MessageLookupByLibrary.simpleMessage(
      "Appointment preview",
    ),
    "recurrenceRepeatBlock": MessageLookupByLibrary.simpleMessage(
      "Repeat this block",
    ),
    "recurrenceRepeatBooking": MessageLookupByLibrary.simpleMessage(
      "Repeat this appointment",
    ),
    "recurrenceSelectDate": MessageLookupByLibrary.simpleMessage("Select date"),
    "recurrenceSeriesIcon": MessageLookupByLibrary.simpleMessage(
      "Recurring appointment",
    ),
    "recurrenceSeriesOf": m58,
    "recurrenceSummaryAppointments": MessageLookupByLibrary.simpleMessage(
      "Appointments:",
    ),
    "recurrenceSummaryConflict": MessageLookupByLibrary.simpleMessage(
      "Skipped due to conflict",
    ),
    "recurrenceSummaryCreated": m59,
    "recurrenceSummaryDeleted": MessageLookupByLibrary.simpleMessage("Deleted"),
    "recurrenceSummaryError": MessageLookupByLibrary.simpleMessage(
      "Error creating series",
    ),
    "recurrenceSummarySkipped": m60,
    "recurrenceSummaryTitle": MessageLookupByLibrary.simpleMessage(
      "Series created",
    ),
    "recurrenceWeek": MessageLookupByLibrary.simpleMessage("week"),
    "recurrenceWeeks": MessageLookupByLibrary.simpleMessage("weeks"),
    "recurringDeleteChooseScope": MessageLookupByLibrary.simpleMessage(
      "Which appointments do you want to delete?",
    ),
    "recurringDeleteMessage": m61,
    "recurringDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Delete recurring appointment",
    ),
    "recurringEditChooseScope": MessageLookupByLibrary.simpleMessage(
      "Which appointments do you want to edit?",
    ),
    "recurringEditMessage": m62,
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
    "reportsByDayOfWeek": MessageLookupByLibrary.simpleMessage(
      "By day of week",
    ),
    "reportsByHour": MessageLookupByLibrary.simpleMessage("By hour"),
    "reportsByLocation": MessageLookupByLibrary.simpleMessage("By location"),
    "reportsByPeriod": MessageLookupByLibrary.simpleMessage("By period"),
    "reportsByService": MessageLookupByLibrary.simpleMessage("By service"),
    "reportsByStaff": MessageLookupByLibrary.simpleMessage("By staff"),
    "reportsColAppointments": MessageLookupByLibrary.simpleMessage(
      "Appointments",
    ),
    "reportsColAvailableHours": MessageLookupByLibrary.simpleMessage(
      "Effective",
    ),
    "reportsColAvgDuration": MessageLookupByLibrary.simpleMessage(
      "Avg. duration",
    ),
    "reportsColAvgRevenue": MessageLookupByLibrary.simpleMessage("Average"),
    "reportsColBlockedHours": MessageLookupByLibrary.simpleMessage("Blocked"),
    "reportsColCategory": MessageLookupByLibrary.simpleMessage("Category"),
    "reportsColDay": MessageLookupByLibrary.simpleMessage("Day"),
    "reportsColHour": MessageLookupByLibrary.simpleMessage("Hour"),
    "reportsColHours": MessageLookupByLibrary.simpleMessage("Hours"),
    "reportsColLocation": MessageLookupByLibrary.simpleMessage("Location"),
    "reportsColOffHours": MessageLookupByLibrary.simpleMessage("Time Off"),
    "reportsColPercentage": MessageLookupByLibrary.simpleMessage("%"),
    "reportsColPeriod": MessageLookupByLibrary.simpleMessage("Period"),
    "reportsColRevenue": MessageLookupByLibrary.simpleMessage("Revenue"),
    "reportsColScheduledHours": MessageLookupByLibrary.simpleMessage(
      "Scheduled",
    ),
    "reportsColService": MessageLookupByLibrary.simpleMessage("Service"),
    "reportsColStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "reportsColUtilization": MessageLookupByLibrary.simpleMessage("Occupancy"),
    "reportsColWorkedHours": MessageLookupByLibrary.simpleMessage("Booked"),
    "reportsFilterLocations": MessageLookupByLibrary.simpleMessage("Locations"),
    "reportsFilterServices": MessageLookupByLibrary.simpleMessage("Services"),
    "reportsFilterStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "reportsFilterStatus": MessageLookupByLibrary.simpleMessage("Status"),
    "reportsFullPeriodToggle": MessageLookupByLibrary.simpleMessage(
      "Include full period (future included)",
    ),
    "reportsNoData": MessageLookupByLibrary.simpleMessage("No data available"),
    "reportsOccupancyPercentage": MessageLookupByLibrary.simpleMessage(
      "Occupancy",
    ),
    "reportsPresetCustom": MessageLookupByLibrary.simpleMessage(
      "Choose period",
    ),
    "reportsPresetLast3Months": MessageLookupByLibrary.simpleMessage(
      "Last 3 months",
    ),
    "reportsPresetLast6Months": MessageLookupByLibrary.simpleMessage(
      "Last 6 months",
    ),
    "reportsPresetLastMonth": MessageLookupByLibrary.simpleMessage(
      "Last month",
    ),
    "reportsPresetLastYear": MessageLookupByLibrary.simpleMessage(
      "Previous year",
    ),
    "reportsPresetMonth": MessageLookupByLibrary.simpleMessage("Current month"),
    "reportsPresetQuarter": MessageLookupByLibrary.simpleMessage(
      "Current quarter",
    ),
    "reportsPresetSemester": MessageLookupByLibrary.simpleMessage(
      "Current semester",
    ),
    "reportsPresetToday": MessageLookupByLibrary.simpleMessage("Today"),
    "reportsPresetWeek": MessageLookupByLibrary.simpleMessage("This week"),
    "reportsPresetYear": MessageLookupByLibrary.simpleMessage("Current year"),
    "reportsPresets": MessageLookupByLibrary.simpleMessage("Period presets"),
    "reportsTabAppointments": MessageLookupByLibrary.simpleMessage(
      "Appointments",
    ),
    "reportsTabStaff": MessageLookupByLibrary.simpleMessage("Team"),
    "reportsTitle": MessageLookupByLibrary.simpleMessage("Reports"),
    "reportsTotalAppointments": MessageLookupByLibrary.simpleMessage(
      "Appointments",
    ),
    "reportsTotalHours": MessageLookupByLibrary.simpleMessage("Hours worked"),
    "reportsTotalRevenue": MessageLookupByLibrary.simpleMessage("Revenue"),
    "reportsUniqueClients": MessageLookupByLibrary.simpleMessage(
      "Unique clients",
    ),
    "reportsWorkHoursAvailable": MessageLookupByLibrary.simpleMessage(
      "Effective",
    ),
    "reportsWorkHoursBlocked": MessageLookupByLibrary.simpleMessage("Blocked"),
    "reportsWorkHoursOff": MessageLookupByLibrary.simpleMessage("Time Off"),
    "reportsWorkHoursScheduled": MessageLookupByLibrary.simpleMessage(
      "Scheduled",
    ),
    "reportsWorkHoursSubtitle": MessageLookupByLibrary.simpleMessage(
      "Summary of scheduled, worked hours and absences",
    ),
    "reportsWorkHoursTitle": MessageLookupByLibrary.simpleMessage("Staff"),
    "reportsWorkHoursUtilization": MessageLookupByLibrary.simpleMessage(
      "Occupancy",
    ),
    "reportsWorkHoursWorked": MessageLookupByLibrary.simpleMessage("Booked"),
    "resourceDeleteConfirm": MessageLookupByLibrary.simpleMessage(
      "Delete this resource?",
    ),
    "resourceDeleteWarning": MessageLookupByLibrary.simpleMessage(
      "Services using this resource will no longer be constrained by its availability",
    ),
    "resourceEdit": MessageLookupByLibrary.simpleMessage("Edit resource"),
    "resourceNameLabel": MessageLookupByLibrary.simpleMessage("Resource name"),
    "resourceNew": MessageLookupByLibrary.simpleMessage("New resource"),
    "resourceNoServicesSelected": MessageLookupByLibrary.simpleMessage(
      "No services associated",
    ),
    "resourceNoneLabel": MessageLookupByLibrary.simpleMessage(
      "No resources required",
    ),
    "resourceNoteLabel": MessageLookupByLibrary.simpleMessage(
      "Notes (optional)",
    ),
    "resourceQuantityLabel": MessageLookupByLibrary.simpleMessage(
      "Available quantity",
    ),
    "resourceQuantityRequired": MessageLookupByLibrary.simpleMessage(
      "Qty required",
    ),
    "resourceSelectLabel": MessageLookupByLibrary.simpleMessage(
      "Select resources",
    ),
    "resourceSelectServices": MessageLookupByLibrary.simpleMessage(
      "Select services",
    ),
    "resourceServiceCountPlural": m63,
    "resourceServiceCountSingular": MessageLookupByLibrary.simpleMessage(
      "1 service",
    ),
    "resourceServicesLabel": MessageLookupByLibrary.simpleMessage(
      "Services using this resource",
    ),
    "resourceTypeLabel": MessageLookupByLibrary.simpleMessage(
      "Type (optional)",
    ),
    "resourcesEmpty": MessageLookupByLibrary.simpleMessage(
      "No resources configured for this location",
    ),
    "resourcesEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Resources are equipment or spaces (e.g., cabins, beds) that can be associated with services",
    ),
    "resourcesTitle": MessageLookupByLibrary.simpleMessage("Resources"),
    "searchClientPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Search client...",
    ),
    "searchServices": MessageLookupByLibrary.simpleMessage("Search service..."),
    "selectClientTitle": MessageLookupByLibrary.simpleMessage("Select client"),
    "selectService": MessageLookupByLibrary.simpleMessage("Select service"),
    "selectStaffTitle": MessageLookupByLibrary.simpleMessage("Select team"),
    "serviceColorLabel": MessageLookupByLibrary.simpleMessage("Service color"),
    "serviceDuplicateCopyWord": MessageLookupByLibrary.simpleMessage("Copy"),
    "serviceDuplicateError": MessageLookupByLibrary.simpleMessage(
      "A service with this name already exists",
    ),
    "serviceEligibleStaffCount": m64,
    "serviceEligibleStaffNone": MessageLookupByLibrary.simpleMessage(
      "No eligible team members",
    ),
    "serviceLocationsCount": m65,
    "serviceLocationsLabel": MessageLookupByLibrary.simpleMessage(
      "Available locations",
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
    "serviceRequiredResourcesLabel": MessageLookupByLibrary.simpleMessage(
      "Required resources",
    ),
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
    "servicesSelectedCount": m66,
    "servicesTabLabel": MessageLookupByLibrary.simpleMessage("Services"),
    "setPriceToEnable": MessageLookupByLibrary.simpleMessage(
      "Set a price to enable this option",
    ),
    "shiftDeleteAll": MessageLookupByLibrary.simpleMessage(
      "Delete all these shifts",
    ),
    "shiftDeleteAllDesc": m67,
    "shiftDeleteThisOnly": MessageLookupByLibrary.simpleMessage(
      "Delete only this shift",
    ),
    "shiftDeleteThisOnlyDesc": m68,
    "shiftEditAll": MessageLookupByLibrary.simpleMessage(
      "Edit all these shifts",
    ),
    "shiftEditAllDesc": m69,
    "shiftEditThisOnly": MessageLookupByLibrary.simpleMessage(
      "Edit only this shift",
    ),
    "shiftEditThisOnlyDesc": m70,
    "shiftEditTitle": MessageLookupByLibrary.simpleMessage("Edit shift"),
    "shiftEndTime": MessageLookupByLibrary.simpleMessage("End time"),
    "shiftStartTime": MessageLookupByLibrary.simpleMessage("Start time"),
    "showAllServices": MessageLookupByLibrary.simpleMessage(
      "Show all services",
    ),
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
    "statusCancelled": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("Completed"),
    "statusConfirmed": MessageLookupByLibrary.simpleMessage("Confirmed"),
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
    "teamEligibleServicesCount": m71,
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
    "teamLocationCancellationHoursAlways": MessageLookupByLibrary.simpleMessage(
      "Always",
    ),
    "teamLocationCancellationHoursHint": MessageLookupByLibrary.simpleMessage(
      "Minimum time before the appointment during which customers can still modify or cancel",
    ),
    "teamLocationCancellationHoursLabel": MessageLookupByLibrary.simpleMessage(
      "Modify/cancel window",
    ),
    "teamLocationCancellationHoursNever": MessageLookupByLibrary.simpleMessage(
      "Never",
    ),
    "teamLocationCancellationHoursUseBusiness":
        MessageLookupByLibrary.simpleMessage("Use business policy"),
    "teamLocationCancellationHoursUseBusinessWithValue": m72,
    "teamLocationDays": m73,
    "teamLocationEmailHint": MessageLookupByLibrary.simpleMessage(
      "Email for customer notifications",
    ),
    "teamLocationEmailLabel": MessageLookupByLibrary.simpleMessage("Email"),
    "teamLocationHours": m74,
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
    "teamLocationMinGapHint": MessageLookupByLibrary.simpleMessage(
      "Hide time slots that leave less than this time free",
    ),
    "teamLocationMinGapLabel": MessageLookupByLibrary.simpleMessage(
      "Minimum acceptable gap",
    ),
    "teamLocationMinutes": m75,
    "teamLocationNameLabel": MessageLookupByLibrary.simpleMessage(
      "Location name",
    ),
    "teamLocationSlotDisplayModeAll": MessageLookupByLibrary.simpleMessage(
      "Maximum availability",
    ),
    "teamLocationSlotDisplayModeAllHint": MessageLookupByLibrary.simpleMessage(
      "Show all available time slots",
    ),
    "teamLocationSlotDisplayModeLabel": MessageLookupByLibrary.simpleMessage(
      "Display mode",
    ),
    "teamLocationSlotDisplayModeMinGap": MessageLookupByLibrary.simpleMessage(
      "Reduce empty gaps",
    ),
    "teamLocationSlotDisplayModeMinGapHint":
        MessageLookupByLibrary.simpleMessage(
          "Hide slots that would create gaps too small to fill",
        ),
    "teamLocationSlotIntervalHint": MessageLookupByLibrary.simpleMessage(
      "How many minutes between each available slot in online booking (does not affect staff planning slots)",
    ),
    "teamLocationSlotIntervalLabel": MessageLookupByLibrary.simpleMessage(
      "Time slot interval",
    ),
    "teamLocationSmartSlotDescription": MessageLookupByLibrary.simpleMessage(
      "Configure how available times are shown to customers booking online. This does not change staff planning.",
    ),
    "teamLocationSmartSlotSection": MessageLookupByLibrary.simpleMessage(
      "Smart time slots",
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
    "teamSelectedServicesCount": m76,
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
    "weeklyScheduleTotalHours": m77,
  };
}
