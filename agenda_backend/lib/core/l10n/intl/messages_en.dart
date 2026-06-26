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

  static String m1(date) =>
      "The free period ended on ${date}. To continue using the app, activate your subscription.";

  static String m2(date) => "Subscription activation is required by ${date}.";

  static String m3(currentPeriodEnd) =>
      "Subscription active until ${currentPeriodEnd}";

  static String m4(businessName) => "Billing ${businessName}";

  static String m5(url) =>
      "The customer will only be able to book items available in this category. If the category contains public items, only those will be shown. If it contains no public items, items available only by direct link will be shown.\n\n${url}";

  static String m6(url) =>
      "The customer will only be able to book this event.\n\n${url}";

  static String m7(url) =>
      "The customer will only be able to book this package.\n\n${url}";

  static String m8(url) =>
      "The customer will only be able to book this service.\n\n${url}";

  static String m9(url) =>
      "The customer will only be able to book with this staff member.\n\n${url}";

  static String m10(fields, rules) => "${fields} fields · ${rules} rules";

  static String m11(appointment, location) =>
      "${appointment} at location ${location}";

  static String m12(appointment) => "${appointment} only";

  static String m13(category, location) =>
      "${category} at location ${location}";

  static String m14(category) => "Category ${category} only";

  static String m15(location) => "Location ${location} only";

  static String m16(fields) => "Changed fields: ${fields}";

  static String m17(type) => "Email sent of type: ${type}";

  static String m18(type) => "Email not sent of type: ${type}";

  static String m19(channel) => "Type: ${channel}";

  static String m20(email) => "Recipient: ${email}";

  static String m21(dateTime) => "Sent at: ${dateTime}";

  static String m22(reason) => "Reason: ${reason}";

  static String m23(dateTime) => "Skipped at: ${dateTime}";

  static String m24(subject) => "Subject: ${subject}";

  static String m25(url) =>
      "The customer will open booking already filtered to this location.\n\n${url}";

  static String m26(count) => "${count} notifications";

  static String m27(date, time, staffName) =>
      "The booking will be moved to ${date} at ${time} for ${staffName}.";

  static String m28(duration) => "Total duration: ${duration}";

  static String m29(price) => "Total: ${price}";

  static String m30(count) => "${count} bookings";

  static String m31(count, percent, periodTotal) =>
      "${count} bookings (${percent}% of ${periodTotal})";

  static String m32(confirmed, capacity, waitlist) =>
      "Confirmed: ${confirmed}/${capacity} • Waitlist: ${waitlist}";

  static String m33(confirmed, capacity) =>
      "Confirmed: ${confirmed}/${capacity}";

  static String m34(customerId) => "Customer ${customerId}";

  static String m35(createdCount) => "Schedules created: ${createdCount}.";

  static String m36(createdCount, skippedCount) =>
      "Schedules created: ${createdCount}. Skipped: ${skippedCount}.";

  static String m37(count) => "Create ${count} schedules";

  static String m38(staffId) => "Inactive staff (ID: ${staffId})";

  static String m39(clientName) => "${clientName}\'s appointments";

  static String m40(count) =>
      "${Intl.plural(count, one: '1 day', other: '${count} days')}";

  static String m41(count) =>
      "Import ${Intl.plural(count, one: '1 holiday', other: '${count} holidays')}";

  static String m42(count) =>
      "${Intl.plural(count, one: '1 holiday already added', other: '${count} holidays already added')} (marked with ✓)";

  static String m43(count) =>
      "${Intl.plural(count, one: '1 holiday imported', other: '${count} holidays imported')}";

  static String m44(count) =>
      "for a total of ${Intl.plural(count, one: '1 day', other: '${count} days')}";

  static String m45(hours) => "${hours} hour";

  static String m46(hours, minutes) => "${hours} hour ${minutes} min";

  static String m47(minutes) => "${minutes} min";

  static String m48(id) => "Exception not found: ${id}";

  static String m49(factor) => "No builder available for ${factor}";

  static String m50(path) => "Page not found: ${path}";

  static String m51(count) =>
      "${count} ${Intl.plural(count, one: 'day', other: 'days')}";

  static String m52(dates) => "Some days were not saved: ${dates}.";

  static String m53(details) => "Some days were not saved: ${details}.";

  static String m54(hours) => "${hours}h";

  static String m55(hours, minutes) => "${hours}h ${minutes}m";

  static String m56(businessName, role) =>
      "You were invited to collaborate with ${businessName} as ${role}.";

  static String m57(date) => "Last visit: ${date}";

  static String m58(newTime, staffName) =>
      "The appointment will be moved to ${newTime} for ${staffName}.";

  static String m59(date) => "Accepted on ${date}";

  static String m60(email) =>
      "Do you want to permanently delete the invite for ${email}?";

  static String m61(date) => "Expires on ${date}";

  static String m62(email) => "Invite sent to ${email}";

  static String m63(name) => "Invited by ${name}";

  static String m64(count) => "${count} archived invites";

  static String m65(count) => "${count} pending invites";

  static String m66(name) => "Do you want to remove ${name} from the team?";

  static String m67(email) => "Do you want to revoke the invite for ${email}?";

  static String m68(name) => "Do you want to delete \"${name}\"?";

  static String m69(durationA, durationB, totalDuration) =>
      "Week A: ${durationA} | Week B: ${durationB} | Tot: ${totalDuration}";

  static String m70(hoursA, hoursB, total) =>
      "Week A: ${hoursA}h | Week B: ${hoursB}h | Tot: ${total}h";

  static String m71(week) => "Current week: ${week}";

  static String m72(count) => "Show expired (${count})";

  static String m73(from) => "Valid from ${from}";

  static String m74(from, to) => "Valid from ${from} to ${to}";

  static String m75(from) => "From ${from}";

  static String m76(from, to) => "From ${from} to ${to}";

  static String m77(duration) => "${duration}/week";

  static String m78(hours) => "${hours}h/week";

  static String m79(count) => "Create ${count} appointments";

  static String m80(count) => "${count} conflicts";

  static String m81(count) => "${count} appointments";

  static String m82(count) => "${count} selected";

  static String m83(index, total) => "${index} of ${total}";

  static String m84(count) => "${count} appointments created";

  static String m85(count) => "${count} skipped due to conflicts";

  static String m86(index, total) =>
      "This is appointment ${index} of ${total} in the series.";

  static String m87(index, total) =>
      "This is appointment ${index} of ${total} in the series.";

  static String m88(count) => "${count} services";

  static String m89(count) => "${count} eligible team members";

  static String m90(count, total) => "${count} of ${total} locations";

  static String m91(count) =>
      "${Intl.plural(count, one: '1 service selected', other: '${count} services selected')}";

  static String m92(dayName) =>
      "Delete the weekly time slot for every ${dayName}";

  static String m93(date) => "Delete only the time slot of ${date}";

  static String m94(dayName) =>
      "Edit the weekly time slot for every ${dayName}";

  static String m95(date) => "Edit only the time slot of ${date}";

  static String m96(count) => "${count} eligible services";

  static String m97(value) => "Use business policy (${value})";

  static String m98(count) =>
      "${Intl.plural(count, one: '1 day', other: '${count} days')}";

  static String m99(count) =>
      "${Intl.plural(count, one: '1 hour', other: '${count} hours')}";

  static String m100(count) =>
      "${Intl.plural(count, one: '1 minute', other: '${count} minutes')}";

  static String m101(count) => "It must include \"${count}\".";

  static String m102(value) => "Default: ${value}.";

  static String m103(selected, total) => "${selected} of ${total}";

  static String m104(hours) => "${hours} hours total";

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
    "actionNo": MessageLookupByLibrary.simpleMessage("No"),
    "actionPayment": MessageLookupByLibrary.simpleMessage("Payment"),
    "actionPreview": MessageLookupByLibrary.simpleMessage("Preview"),
    "actionRefresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "actionReschedule": MessageLookupByLibrary.simpleMessage("Reschedule"),
    "actionRetry": MessageLookupByLibrary.simpleMessage("Retry"),
    "actionSave": MessageLookupByLibrary.simpleMessage("Save"),
    "actionSelectAll": MessageLookupByLibrary.simpleMessage("Select all"),
    "actionYes": MessageLookupByLibrary.simpleMessage("Yes"),
    "addAppointmentTypeTooltip": MessageLookupByLibrary.simpleMessage(
      "Add appointment type.",
    ),
    "addClientToAppointment": MessageLookupByLibrary.simpleMessage(
      "Add a client to the appointment",
    ),
    "addPackage": MessageLookupByLibrary.simpleMessage("Add package"),
    "addService": MessageLookupByLibrary.simpleMessage("Add service"),
    "addServiceOrPackage": MessageLookupByLibrary.simpleMessage(
      "Add service/package",
    ),
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
    "agendaDailyReportAction": MessageLookupByLibrary.simpleMessage(
      "Daily report",
    ),
    "agendaDisplaySettingsAction": MessageLookupByLibrary.simpleMessage(
      "Display settings",
    ),
    "agendaDisplaySettingsCardColorOpacityLabel":
        MessageLookupByLibrary.simpleMessage("Color intensity"),
    "agendaDisplaySettingsCardTextZoomLabel":
        MessageLookupByLibrary.simpleMessage("Card text zoom"),
    "agendaDisplaySettingsColumnWidthLabel":
        MessageLookupByLibrary.simpleMessage("Minimum column width"),
    "agendaDisplaySettingsExpandStaffColumnsOnOverlapLabel":
        MessageLookupByLibrary.simpleMessage(
          "Expand columns when appointments overlap",
        ),
    "agendaDisplaySettingsExtraMinutesBandIntensityLabel":
        MessageLookupByLibrary.simpleMessage("Additional extra-band intensity"),
    "agendaDisplaySettingsHoverUnrelatedDimIntensityLabel":
        MessageLookupByLibrary.simpleMessage(
          "Unrelated card dimming intensity (desktop hover)",
        ),
    "agendaDisplaySettingsMobileColumnsLabel":
        MessageLookupByLibrary.simpleMessage("Visible columns"),
    "agendaDisplaySettingsResetDefaultsAction":
        MessageLookupByLibrary.simpleMessage("Reset defaults"),
    "agendaDisplaySettingsServiceColorsLabel":
        MessageLookupByLibrary.simpleMessage("Appointment color based on:"),
    "agendaDisplaySettingsShowCancelledLabel":
        MessageLookupByLibrary.simpleMessage("Show cancelled appointments"),
    "agendaDisplaySettingsShowPricesLabel":
        MessageLookupByLibrary.simpleMessage("Show prices in cards"),
    "agendaDisplaySettingsSlotHeightLabel":
        MessageLookupByLibrary.simpleMessage("Agenda slot height"),
    "agendaDisplaySettingsSuperadminTitle":
        MessageLookupByLibrary.simpleMessage("Agenda Settings"),
    "agendaDisplaySettingsUseRoundedCardCornersLabel":
        MessageLookupByLibrary.simpleMessage("Use rounded card corners"),
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
    "agendaReportDisplayedDateAction": MessageLookupByLibrary.simpleMessage(
      "Report displayed date",
    ),
    "agendaReportDisplayedWeekAction": MessageLookupByLibrary.simpleMessage(
      "Report displayed week",
    ),
    "agendaSelectLocation": MessageLookupByLibrary.simpleMessage(
      "Select location",
    ),
    "agendaShowAllTeamButton": MessageLookupByLibrary.simpleMessage(
      "View all team",
    ),
    "agendaToday": MessageLookupByLibrary.simpleMessage("Today"),
    "agendaViewMode": MessageLookupByLibrary.simpleMessage("View"),
    "agendaViewModeSwitchToDay": MessageLookupByLibrary.simpleMessage(
      "Switch to day by day",
    ),
    "agendaViewModeSwitchToWeek": MessageLookupByLibrary.simpleMessage(
      "Switch to week by week",
    ),
    "agendaWeeklyLoadError": MessageLookupByLibrary.simpleMessage(
      "Unable to load this week\'s appointments.",
    ),
    "agendaWeeklyReportAction": MessageLookupByLibrary.simpleMessage(
      "Weekly report",
    ),
    "allLocations": MessageLookupByLibrary.simpleMessage("All locations"),
    "apiErrorClassTypeNameExists": MessageLookupByLibrary.simpleMessage(
      "An event type with this name already exists.",
    ),
    "apiErrorDatabase": MessageLookupByLibrary.simpleMessage(
      "Service temporarily unavailable. Please try again later.",
    ),
    "apiErrorDemoBlocked": MessageLookupByLibrary.simpleMessage(
      "This action is blocked in demo mode.",
    ),
    "apiErrorForbidden": MessageLookupByLibrary.simpleMessage(
      "You do not have permission to perform this action.",
    ),
    "apiErrorInvalidCredentials": MessageLookupByLibrary.simpleMessage(
      "Invalid email or password.",
    ),
    "apiErrorInvalidRefreshToken": MessageLookupByLibrary.simpleMessage(
      "Your session is no longer valid. Please sign in again.",
    ),
    "apiErrorInvalidResetToken": MessageLookupByLibrary.simpleMessage(
      "The password reset link is not valid.",
    ),
    "apiErrorNotFound": MessageLookupByLibrary.simpleMessage(
      "The requested resource was not found.",
    ),
    "apiErrorResetTokenExpired": MessageLookupByLibrary.simpleMessage(
      "The password reset link has expired.",
    ),
    "apiErrorServiceCapacityFull": MessageLookupByLibrary.simpleMessage(
      "The selected slot has reached the maximum number of concurrent bookings.",
    ),
    "apiErrorSlotConflict": MessageLookupByLibrary.simpleMessage(
      "The selected time slot is no longer available.",
    ),
    "apiErrorStaffHasFutureBookings": MessageLookupByLibrary.simpleMessage(
      "Cannot delete this team member: future bookings are assigned to this member.",
    ),
    "apiErrorTokenExpired": MessageLookupByLibrary.simpleMessage(
      "Your session has expired. Please sign in again.",
    ),
    "apiErrorUnauthorized": MessageLookupByLibrary.simpleMessage(
      "Authentication required.",
    ),
    "apiErrorValidation": MessageLookupByLibrary.simpleMessage(
      "Please check the entered data.",
    ),
    "appTitle": MessageLookupByLibrary.simpleMessage("Agenda Platform"),
    "applyClientToAllAppointmentsMessage": MessageLookupByLibrary.simpleMessage(
      "The client will also be associated with the appointments in this booking that have been assigned to other staff members.",
    ),
    "applyClientToAllAppointmentsTitle": MessageLookupByLibrary.simpleMessage(
      "Apply client to entire booking?",
    ),
    "appointmentDialogBookingId": MessageLookupByLibrary.simpleMessage(
      "Booking ID",
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
    "billingAccessBlockedActivateAction": MessageLookupByLibrary.simpleMessage(
      "Activate subscription",
    ),
    "billingAccessBlockedMessage": MessageLookupByLibrary.simpleMessage(
      "The free period has ended. To continue using the app, activate your subscription.",
    ),
    "billingAccessBlockedMessageWithDate": m1,
    "billingAccessBlockedTitle": MessageLookupByLibrary.simpleMessage(
      "Subscription required",
    ),
    "billingActivateAction": MessageLookupByLibrary.simpleMessage(
      "Activate subscription",
    ),
    "billingActivationDeadlineHint": MessageLookupByLibrary.simpleMessage(
      "If set, the business can use the app for free until this date. After that, they must activate the subscription to continue.",
    ),
    "billingActivationDeadlineLabel": MessageLookupByLibrary.simpleMessage(
      "Subscription activation deadline",
    ),
    "billingActivationDeadlinePending": m2,
    "billingActiveTitle": MessageLookupByLibrary.simpleMessage(
      "Subscription active",
    ),
    "billingActiveUntilCancellationScheduledTitle": m3,
    "billingAdminDialogTitle": m4,
    "billingAdminEnabledLabel": MessageLookupByLibrary.simpleMessage(
      "Subject to billing",
    ),
    "billingAgendaNoticeAction": MessageLookupByLibrary.simpleMessage(
      "Activate subscription",
    ),
    "billingAgendaNoticeDismissTooltip": MessageLookupByLibrary.simpleMessage(
      "Hide until tomorrow",
    ),
    "billingAgendaNoticeMessage": MessageLookupByLibrary.simpleMessage(
      "Activate the business subscription to keep using the management app without interruptions.",
    ),
    "billingAgendaNoticeTitle": MessageLookupByLibrary.simpleMessage(
      "Subscription required",
    ),
    "billingAmountRequired": MessageLookupByLibrary.simpleMessage(
      "Enter a valid monthly amount.",
    ),
    "billingBillingEnabledLabel": MessageLookupByLibrary.simpleMessage(
      "billing_enabled",
    ),
    "billingCanOpenPortalFieldLabel": MessageLookupByLibrary.simpleMessage(
      "can_open_portal",
    ),
    "billingCanStartCheckoutFieldLabel": MessageLookupByLibrary.simpleMessage(
      "can_start_checkout",
    ),
    "billingCancelAtPeriodEndLabel": MessageLookupByLibrary.simpleMessage(
      "cancel_at_period_end",
    ),
    "billingCanceledAtFieldLabel": MessageLookupByLibrary.simpleMessage(
      "canceled_at",
    ),
    "billingCheckoutAlreadyStartedError": MessageLookupByLibrary.simpleMessage(
      "Checkout already started. Complete the open session before trying again.",
    ),
    "billingCheckoutCanceledMessage": MessageLookupByLibrary.simpleMessage(
      "Checkout canceled. You can try again whenever you want.",
    ),
    "billingCheckoutIncompleteMessage": MessageLookupByLibrary.simpleMessage(
      "Checkout not completed. You can retry the payment whenever you want.",
    ),
    "billingCheckoutStartedMessage": MessageLookupByLibrary.simpleMessage(
      "Checkout already started. Complete the open session before trying again.",
    ),
    "billingCurrencyLabel": MessageLookupByLibrary.simpleMessage("Currency"),
    "billingCurrentPeriodEndCancellationLabel":
        MessageLookupByLibrary.simpleMessage("Expires on"),
    "billingCurrentPeriodEndFieldLabel": MessageLookupByLibrary.simpleMessage(
      "current_period_end",
    ),
    "billingCurrentPeriodEndLabel": MessageLookupByLibrary.simpleMessage(
      "Next renewal",
    ),
    "billingCurrentPeriodStartFieldLabel": MessageLookupByLibrary.simpleMessage(
      "current_period_start",
    ),
    "billingCycleAnchorHint": MessageLookupByLibrary.simpleMessage(
      "If set and in the future, Stripe will use this date as the start of the first billing cycle.",
    ),
    "billingCycleAnchorLabel": MessageLookupByLibrary.simpleMessage(
      "Billing cycle anchor (Stripe)",
    ),
    "billingDescription": MessageLookupByLibrary.simpleMessage(
      "Billing status and subscription management.",
    ),
    "billingInactiveTitle": MessageLookupByLibrary.simpleMessage(
      "Subscription inactive",
    ),
    "billingLastCheckoutSessionIdLabel": MessageLookupByLibrary.simpleMessage(
      "last_checkout_session_id",
    ),
    "billingLastPaymentAtFieldLabel": MessageLookupByLibrary.simpleMessage(
      "last_payment_at",
    ),
    "billingLastPaymentFailedAtFieldLabel":
        MessageLookupByLibrary.simpleMessage("last_payment_failed_at"),
    "billingManageAction": MessageLookupByLibrary.simpleMessage(
      "Manage subscription",
    ),
    "billingMonthlyAmountLabel": MessageLookupByLibrary.simpleMessage(
      "Monthly amount",
    ),
    "billingNotRequiredMessage": MessageLookupByLibrary.simpleMessage(
      "This business is not subject to billing.",
    ),
    "billingNotRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "No billing required",
    ),
    "billingNotesLabel": MessageLookupByLibrary.simpleMessage("Notes"),
    "billingPaymentFailedTitle": MessageLookupByLibrary.simpleMessage(
      "Payment failed",
    ),
    "billingProviderCodeFieldLabel": MessageLookupByLibrary.simpleMessage(
      "provider_code",
    ),
    "billingProviderCustomerIdLabel": MessageLookupByLibrary.simpleMessage(
      "provider_customer_id",
    ),
    "billingProviderPriceReferenceLabel": MessageLookupByLibrary.simpleMessage(
      "provider_price_reference",
    ),
    "billingProviderSubscriptionIdLabel": MessageLookupByLibrary.simpleMessage(
      "provider_subscription_id",
    ),
    "billingReactivateAction": MessageLookupByLibrary.simpleMessage(
      "Reactivate subscription",
    ),
    "billingRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "Subscription required",
    ),
    "billingRetryActivationAction": MessageLookupByLibrary.simpleMessage(
      "Retry activation",
    ),
    "billingRetryPaymentAction": MessageLookupByLibrary.simpleMessage(
      "Retry payment",
    ),
    "billingStatusActive": MessageLookupByLibrary.simpleMessage("Active"),
    "billingStatusCanceled": MessageLookupByLibrary.simpleMessage("Canceled"),
    "billingStatusCancellationScheduled": MessageLookupByLibrary.simpleMessage(
      "Cancellation scheduled",
    ),
    "billingStatusError": MessageLookupByLibrary.simpleMessage("Error"),
    "billingStatusFieldLabel": MessageLookupByLibrary.simpleMessage("status"),
    "billingStatusInactive": MessageLookupByLibrary.simpleMessage("Inactive"),
    "billingStatusLabel": MessageLookupByLibrary.simpleMessage("Status"),
    "billingStatusNotRequired": MessageLookupByLibrary.simpleMessage(
      "Not required",
    ),
    "billingStatusPastDue": MessageLookupByLibrary.simpleMessage("Past due"),
    "billingStatusUnpaid": MessageLookupByLibrary.simpleMessage("Unpaid"),
    "billingSubscriptionAlreadyExistsError": MessageLookupByLibrary.simpleMessage(
      "A subscription already exists for this business. Use Manage subscription.",
    ),
    "billingSuperadminFieldsTitle": MessageLookupByLibrary.simpleMessage(
      "Billing fields",
    ),
    "billingTitle": MessageLookupByLibrary.simpleMessage("Subscription"),
    "blockAllDay": MessageLookupByLibrary.simpleMessage("All day"),
    "blockAllowOnlineBookingDuringBlock": MessageLookupByLibrary.simpleMessage(
      "Allow online bookings during this block",
    ),
    "blockDialogTitleEdit": MessageLookupByLibrary.simpleMessage("Edit block"),
    "blockDialogTitleNew": MessageLookupByLibrary.simpleMessage("New block"),
    "blockEndTime": MessageLookupByLibrary.simpleMessage("End time"),
    "blockPromemoriaDialogTitleEdit": MessageLookupByLibrary.simpleMessage(
      "Edit reminder",
    ),
    "blockPromemoriaDialogTitleNew": MessageLookupByLibrary.simpleMessage(
      "New reminder",
    ),
    "blockPromemoriaLabel": MessageLookupByLibrary.simpleMessage("Reminder"),
    "blockReason": MessageLookupByLibrary.simpleMessage("Reason (optional)"),
    "blockReasonHint": MessageLookupByLibrary.simpleMessage(
      "E.g. Meeting, Break, etc.",
    ),
    "blockRecurringDeleteChooseScope": MessageLookupByLibrary.simpleMessage(
      "Which blocks do you want to delete?",
    ),
    "blockRecurringDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Delete recurring block",
    ),
    "blockRecurringEditChooseScope": MessageLookupByLibrary.simpleMessage(
      "Which blocks do you want to edit?",
    ),
    "blockRecurringEditTitle": MessageLookupByLibrary.simpleMessage(
      "Edit recurring block",
    ),
    "blockRecurringIndicator": MessageLookupByLibrary.simpleMessage(
      "Recurring block",
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
    "bookingDirectLinkBusinessScopeAction":
        MessageLookupByLibrary.simpleMessage("Single business link"),
    "bookingDirectLinkCopiedCategoryMessage": m5,
    "bookingDirectLinkCopiedEventMessage": m6,
    "bookingDirectLinkCopiedPackageMessage": m7,
    "bookingDirectLinkCopiedServiceMessage": m8,
    "bookingDirectLinkCopiedStaffMessage": m9,
    "bookingDirectLinkCopyBusinessCategoryAction":
        MessageLookupByLibrary.simpleMessage("Copy business category link"),
    "bookingDirectLinkCopyStaffAction": MessageLookupByLibrary.simpleMessage(
      "Copy staff booking link",
    ),
    "bookingDirectLinkLocationChoiceTitle":
        MessageLookupByLibrary.simpleMessage("Choose location"),
    "bookingDirectLinkLocationScopeAction":
        MessageLookupByLibrary.simpleMessage("Location-specific link"),
    "bookingDirectLinkNoCompatibleLocationsMessage":
        MessageLookupByLibrary.simpleMessage(
          "There are no online locations compatible with this link.",
        ),
    "bookingDirectLinkScopeChoiceTitle": MessageLookupByLibrary.simpleMessage(
      "Choose link type",
    ),
    "bookingFormsActive": MessageLookupByLibrary.simpleMessage("Active"),
    "bookingFormsActiveHint": MessageLookupByLibrary.simpleMessage(
      "Inactive forms are never shown online.",
    ),
    "bookingFormsAddField": MessageLookupByLibrary.simpleMessage("Add field"),
    "bookingFormsAddOption": MessageLookupByLibrary.simpleMessage("Add option"),
    "bookingFormsAdminDescription": MessageLookupByLibrary.simpleMessage(
      "Collect information and consent during online booking",
    ),
    "bookingFormsAdminTitle": MessageLookupByLibrary.simpleMessage(
      "Online booking forms",
    ),
    "bookingFormsAssignBusiness": MessageLookupByLibrary.simpleMessage(
      "Show for the whole business",
    ),
    "bookingFormsAssignmentAdd": MessageLookupByLibrary.simpleMessage(
      "Add assignment",
    ),
    "bookingFormsAssignmentBusiness": MessageLookupByLibrary.simpleMessage(
      "Business",
    ),
    "bookingFormsAssignmentBusinessWide": MessageLookupByLibrary.simpleMessage(
      "Whole business",
    ),
    "bookingFormsAssignmentCategory": MessageLookupByLibrary.simpleMessage(
      "Category",
    ),
    "bookingFormsAssignmentClassEvent": MessageLookupByLibrary.simpleMessage(
      "Class",
    ),
    "bookingFormsAssignmentLocation": MessageLookupByLibrary.simpleMessage(
      "Location",
    ),
    "bookingFormsAssignmentNoTargets": MessageLookupByLibrary.simpleMessage(
      "No targets available for this scope",
    ),
    "bookingFormsAssignmentPackage": MessageLookupByLibrary.simpleMessage(
      "Package",
    ),
    "bookingFormsAssignmentScope": MessageLookupByLibrary.simpleMessage(
      "Scope",
    ),
    "bookingFormsAssignmentService": MessageLookupByLibrary.simpleMessage(
      "Service",
    ),
    "bookingFormsAssignmentTarget": MessageLookupByLibrary.simpleMessage(
      "Target",
    ),
    "bookingFormsAssignmentsSave": MessageLookupByLibrary.simpleMessage(
      "Save assignments",
    ),
    "bookingFormsAssignmentsTitle": MessageLookupByLibrary.simpleMessage(
      "Assignments",
    ),
    "bookingFormsConsentUrl": MessageLookupByLibrary.simpleMessage(
      "Policy link",
    ),
    "bookingFormsConsentUrlHint": MessageLookupByLibrary.simpleMessage(
      "https://...",
    ),
    "bookingFormsDeleteFieldMessage": MessageLookupByLibrary.simpleMessage(
      "The field will no longer be shown in the form. Existing submissions remain in history.",
    ),
    "bookingFormsDeleteFieldTitle": MessageLookupByLibrary.simpleMessage(
      "Remove field?",
    ),
    "bookingFormsDeleteMessage": MessageLookupByLibrary.simpleMessage(
      "The form will no longer be available for online bookings. Existing submissions remain in history.",
    ),
    "bookingFormsDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Delete form?",
    ),
    "bookingFormsEditField": MessageLookupByLibrary.simpleMessage("Edit field"),
    "bookingFormsEditorSubtitle": MessageLookupByLibrary.simpleMessage(
      "Configure the form, its fields and where it shows online.",
    ),
    "bookingFormsEmpty": MessageLookupByLibrary.simpleMessage(
      "No forms configured",
    ),
    "bookingFormsFieldDescription": MessageLookupByLibrary.simpleMessage(
      "Description",
    ),
    "bookingFormsFieldHelpText": MessageLookupByLibrary.simpleMessage(
      "Help text (optional)",
    ),
    "bookingFormsFieldInternalName": MessageLookupByLibrary.simpleMessage(
      "Internal name",
    ),
    "bookingFormsFieldLabel": MessageLookupByLibrary.simpleMessage("Label"),
    "bookingFormsFieldOptional": MessageLookupByLibrary.simpleMessage(
      "Optional",
    ),
    "bookingFormsFieldPreviewTitle": MessageLookupByLibrary.simpleMessage(
      "Preview",
    ),
    "bookingFormsFieldSaveError": MessageLookupByLibrary.simpleMessage(
      "Could not save the field",
    ),
    "bookingFormsFieldTitle": MessageLookupByLibrary.simpleMessage("Title"),
    "bookingFormsFieldType": MessageLookupByLibrary.simpleMessage("Field type"),
    "bookingFormsFieldTypeCheckbox": MessageLookupByLibrary.simpleMessage(
      "Checkbox",
    ),
    "bookingFormsFieldTypeConsent": MessageLookupByLibrary.simpleMessage(
      "Consent",
    ),
    "bookingFormsFieldTypeDate": MessageLookupByLibrary.simpleMessage("Date"),
    "bookingFormsFieldTypeInfoText": MessageLookupByLibrary.simpleMessage(
      "Info text",
    ),
    "bookingFormsFieldTypeLongText": MessageLookupByLibrary.simpleMessage(
      "Long text",
    ),
    "bookingFormsFieldTypeMultipleChoice": MessageLookupByLibrary.simpleMessage(
      "Multiple choice",
    ),
    "bookingFormsFieldTypeSegmentedChoice":
        MessageLookupByLibrary.simpleMessage("Segmented single choice"),
    "bookingFormsFieldTypeShortText": MessageLookupByLibrary.simpleMessage(
      "Short text",
    ),
    "bookingFormsFieldTypeSingleChoice": MessageLookupByLibrary.simpleMessage(
      "Single choice",
    ),
    "bookingFormsFieldsEmpty": MessageLookupByLibrary.simpleMessage(
      "No fields yet. Add the first one to get started.",
    ),
    "bookingFormsFieldsTitle": MessageLookupByLibrary.simpleMessage("Fields"),
    "bookingFormsListMeta": m10,
    "bookingFormsModuleDetailsTitle": MessageLookupByLibrary.simpleMessage(
      "Form details",
    ),
    "bookingFormsNew": MessageLookupByLibrary.simpleMessage("New form"),
    "bookingFormsNoAssignmentsHint": MessageLookupByLibrary.simpleMessage(
      "Without assignments the form will never appear online.",
    ),
    "bookingFormsNoRulesHint": MessageLookupByLibrary.simpleMessage(
      "Without rules the form will never appear online.",
    ),
    "bookingFormsOptionHint": MessageLookupByLibrary.simpleMessage(
      "Option text",
    ),
    "bookingFormsOptionsHint": MessageLookupByLibrary.simpleMessage(
      "Options, one per line",
    ),
    "bookingFormsOptionsRequired": MessageLookupByLibrary.simpleMessage(
      "Add at least two options for choice fields.",
    ),
    "bookingFormsOptionsTitle": MessageLookupByLibrary.simpleMessage("Options"),
    "bookingFormsReorderTooltip": MessageLookupByLibrary.simpleMessage(
      "Press and drag to reorder",
    ),
    "bookingFormsRequired": MessageLookupByLibrary.simpleMessage("Required"),
    "bookingFormsRuleAdd": MessageLookupByLibrary.simpleMessage("Add rule"),
    "bookingFormsRuleAppointmentInLocation": m11,
    "bookingFormsRuleAppointmentOnly": m12,
    "bookingFormsRuleBuilderTitle": MessageLookupByLibrary.simpleMessage(
      "New rule",
    ),
    "bookingFormsRuleBusiness": MessageLookupByLibrary.simpleMessage(
      "For all bookings",
    ),
    "bookingFormsRuleCategoryInLocation": m13,
    "bookingFormsRuleCategoryOnly": m14,
    "bookingFormsRuleLocationOnly": m15,
    "bookingFormsRuleNoTargets": MessageLookupByLibrary.simpleMessage(
      "No items available",
    ),
    "bookingFormsRuleRefine": MessageLookupByLibrary.simpleMessage(
      "Narrow further (optional)",
    ),
    "bookingFormsRuleRefineAppointment": MessageLookupByLibrary.simpleMessage(
      "To an appointment type",
    ),
    "bookingFormsRuleRefineCategory": MessageLookupByLibrary.simpleMessage(
      "To a category",
    ),
    "bookingFormsRuleRefineNone": MessageLookupByLibrary.simpleMessage(
      "No restriction",
    ),
    "bookingFormsRuleScopeAppointment": MessageLookupByLibrary.simpleMessage(
      "An appointment type",
    ),
    "bookingFormsRuleScopeBusiness": MessageLookupByLibrary.simpleMessage(
      "The whole business",
    ),
    "bookingFormsRuleScopeCategory": MessageLookupByLibrary.simpleMessage(
      "A category",
    ),
    "bookingFormsRuleScopeLocation": MessageLookupByLibrary.simpleMessage(
      "A location",
    ),
    "bookingFormsRuleScopeQuestion": MessageLookupByLibrary.simpleMessage(
      "What does it apply to?",
    ),
    "bookingFormsRuleSelectAppointment": MessageLookupByLibrary.simpleMessage(
      "Appointment type",
    ),
    "bookingFormsRuleSelectCategory": MessageLookupByLibrary.simpleMessage(
      "Category",
    ),
    "bookingFormsRuleSelectLocation": MessageLookupByLibrary.simpleMessage(
      "Location",
    ),
    "bookingFormsRulesGuide": MessageLookupByLibrary.simpleMessage(
      "Each rule defines when to show the form. All the conditions within the same rule must be met. To add another case, create a new rule.",
    ),
    "bookingFormsRulesTitle": MessageLookupByLibrary.simpleMessage(
      "Visibility rules",
    ),
    "bookingFormsSaveModuleFirst": MessageLookupByLibrary.simpleMessage(
      "Save the form to manage fields and visibility.",
    ),
    "bookingFormsSelectHint": MessageLookupByLibrary.simpleMessage(
      "Select a form or create a new one",
    ),
    "bookingFormsStatusHidden": MessageLookupByLibrary.simpleMessage(
      "Not shown online",
    ),
    "bookingFormsStatusInactive": MessageLookupByLibrary.simpleMessage(
      "Inactive",
    ),
    "bookingFormsStatusShown": MessageLookupByLibrary.simpleMessage(
      "Shown online",
    ),
    "bookingFormsStepFields": MessageLookupByLibrary.simpleMessage("Fields"),
    "bookingFormsStepForm": MessageLookupByLibrary.simpleMessage("Form"),
    "bookingFormsStepVisibility": MessageLookupByLibrary.simpleMessage(
      "Visibility",
    ),
    "bookingFormsVisibilityBusinessWideHint":
        MessageLookupByLibrary.simpleMessage(
          "It will be shown in every online booking.",
        ),
    "bookingFormsVisibilityIntro": MessageLookupByLibrary.simpleMessage(
      "Choose where to show the form during online booking. Scopes already covered by a broader rule are hidden to avoid redundancy.",
    ),
    "bookingFormsWarningInactive": MessageLookupByLibrary.simpleMessage(
      "Form disabled",
    ),
    "bookingFormsWarningNoFields": MessageLookupByLibrary.simpleMessage(
      "No active fields",
    ),
    "bookingFormsWarningNoRules": MessageLookupByLibrary.simpleMessage(
      "No visibility rules",
    ),
    "bookingFormsWhereShownTitle": MessageLookupByLibrary.simpleMessage(
      "Where it shows",
    ),
    "bookingFormsWontShowSummary": MessageLookupByLibrary.simpleMessage(
      "Won\'t be shown online",
    ),
    "bookingHistoryActorCustomer": MessageLookupByLibrary.simpleMessage(
      "Customer",
    ),
    "bookingHistoryActorStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "bookingHistoryActorSystem": MessageLookupByLibrary.simpleMessage("System"),
    "bookingHistoryChangedFields": m16,
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
    "bookingHistoryEventNotificationSentTitle": m17,
    "bookingHistoryEventNotificationSkippedTitle": m18,
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
    "bookingHistoryNotificationChannel": m19,
    "bookingHistoryNotificationChannelCancelled":
        MessageLookupByLibrary.simpleMessage("Booking cancellation"),
    "bookingHistoryNotificationChannelConfirmed":
        MessageLookupByLibrary.simpleMessage("Booking confirmation"),
    "bookingHistoryNotificationChannelReminder":
        MessageLookupByLibrary.simpleMessage("Booking reminder"),
    "bookingHistoryNotificationChannelRescheduled":
        MessageLookupByLibrary.simpleMessage("Booking rescheduled"),
    "bookingHistoryNotificationRecipient": m20,
    "bookingHistoryNotificationSentAt": m21,
    "bookingHistoryNotificationSkipReason": m22,
    "bookingHistoryNotificationSkippedAt": m23,
    "bookingHistoryNotificationSubject": m24,
    "bookingHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Booking history",
    ),
    "bookingItems": MessageLookupByLibrary.simpleMessage("Services"),
    "bookingLinkOpenAction": MessageLookupByLibrary.simpleMessage("Open link"),
    "bookingLocationLinkCopiedMessage": m25,
    "bookingLocationLinkCopyAction": MessageLookupByLibrary.simpleMessage(
      "Copy location link",
    ),
    "bookingLocationLinkMissingBusinessSlugMessage":
        MessageLookupByLibrary.simpleMessage(
          "Unable to create the link: business slug is not available.",
        ),
    "bookingModulesAction": MessageLookupByLibrary.simpleMessage("Modules"),
    "bookingModulesEmpty": MessageLookupByLibrary.simpleMessage(
      "No modules apply to this booking.",
    ),
    "bookingModulesError": MessageLookupByLibrary.simpleMessage(
      "Could not save the modules",
    ),
    "bookingModulesSaved": MessageLookupByLibrary.simpleMessage(
      "Modules saved",
    ),
    "bookingModulesTitle": MessageLookupByLibrary.simpleMessage(
      "Booking modules",
    ),
    "bookingNotes": MessageLookupByLibrary.simpleMessage("Booking notes"),
    "bookingNotificationsActionViewBody": MessageLookupByLibrary.simpleMessage(
      "View body",
    ),
    "bookingNotificationsBodyDialogTitle": MessageLookupByLibrary.simpleMessage(
      "Notification body",
    ),
    "bookingNotificationsBodyUnavailable": MessageLookupByLibrary.simpleMessage(
      "Notification body not available",
    ),
    "bookingNotificationsChannelCancelled":
        MessageLookupByLibrary.simpleMessage("Booking cancelled"),
    "bookingNotificationsChannelClassCancelled":
        MessageLookupByLibrary.simpleMessage("Event cancelled"),
    "bookingNotificationsChannelClassConfirmed":
        MessageLookupByLibrary.simpleMessage("Event confirmed"),
    "bookingNotificationsChannelClassPromoted":
        MessageLookupByLibrary.simpleMessage("Promoted from waitlist"),
    "bookingNotificationsChannelClassReminder":
        MessageLookupByLibrary.simpleMessage("Event reminder"),
    "bookingNotificationsChannelClassUpdated":
        MessageLookupByLibrary.simpleMessage("Event updated"),
    "bookingNotificationsChannelClassWaitlisted":
        MessageLookupByLibrary.simpleMessage("Event waitlist"),
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
    "bookingNotificationsFieldBody": MessageLookupByLibrary.simpleMessage(
      "Body",
    ),
    "bookingNotificationsFieldBookingKind":
        MessageLookupByLibrary.simpleMessage("Category"),
    "bookingNotificationsFieldClient": MessageLookupByLibrary.simpleMessage(
      "Client",
    ),
    "bookingNotificationsFieldCreatedAt": MessageLookupByLibrary.simpleMessage(
      "Created at",
    ),
    "bookingNotificationsFieldError": MessageLookupByLibrary.simpleMessage(
      "Error",
    ),
    "bookingNotificationsFieldLastAttemptAt":
        MessageLookupByLibrary.simpleMessage("Last attempt"),
    "bookingNotificationsFieldLocation": MessageLookupByLibrary.simpleMessage(
      "Location",
    ),
    "bookingNotificationsFieldProviderUsed":
        MessageLookupByLibrary.simpleMessage("Provider used"),
    "bookingNotificationsFieldRecipient": MessageLookupByLibrary.simpleMessage(
      "Recipient",
    ),
    "bookingNotificationsFieldSentAt": MessageLookupByLibrary.simpleMessage(
      "Sent at",
    ),
    "bookingNotificationsFieldType": MessageLookupByLibrary.simpleMessage(
      "Type",
    ),
    "bookingNotificationsFilterBookingKind":
        MessageLookupByLibrary.simpleMessage("Category"),
    "bookingNotificationsFilterProvider": MessageLookupByLibrary.simpleMessage(
      "Provider",
    ),
    "bookingNotificationsFilterStatus": MessageLookupByLibrary.simpleMessage(
      "Status",
    ),
    "bookingNotificationsFilterType": MessageLookupByLibrary.simpleMessage(
      "Type",
    ),
    "bookingNotificationsKindAll": MessageLookupByLibrary.simpleMessage("All"),
    "bookingNotificationsKindClass": MessageLookupByLibrary.simpleMessage(
      "Event",
    ),
    "bookingNotificationsKindClassPlural": MessageLookupByLibrary.simpleMessage(
      "Events",
    ),
    "bookingNotificationsKindService": MessageLookupByLibrary.simpleMessage(
      "Appointment",
    ),
    "bookingNotificationsKindServicePlural":
        MessageLookupByLibrary.simpleMessage("Appointments"),
    "bookingNotificationsLoadMore": MessageLookupByLibrary.simpleMessage(
      "Load more",
    ),
    "bookingNotificationsNoSubject": MessageLookupByLibrary.simpleMessage(
      "No subject",
    ),
    "bookingNotificationsNotAvailable": MessageLookupByLibrary.simpleMessage(
      "N/A",
    ),
    "bookingNotificationsProviderBlockedDemo":
        MessageLookupByLibrary.simpleMessage("Blocked demo"),
    "bookingNotificationsProviderBrevo": MessageLookupByLibrary.simpleMessage(
      "Brevo",
    ),
    "bookingNotificationsProviderEmail": MessageLookupByLibrary.simpleMessage(
      "Email",
    ),
    "bookingNotificationsProviderMailgun": MessageLookupByLibrary.simpleMessage(
      "Mailgun",
    ),
    "bookingNotificationsProviderSmtp": MessageLookupByLibrary.simpleMessage(
      "SMTP",
    ),
    "bookingNotificationsProviderWhatsapp":
        MessageLookupByLibrary.simpleMessage("WhatsApp"),
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
    "bookingNotificationsStatusSkipped": MessageLookupByLibrary.simpleMessage(
      "Skipped",
    ),
    "bookingNotificationsTitle": MessageLookupByLibrary.simpleMessage(
      "Booking Notifications",
    ),
    "bookingNotificationsTotalCount": m26,
    "bookingNotificationsTypeAll": MessageLookupByLibrary.simpleMessage(
      "All types",
    ),
    "bookingPaymentExceedsDueMessage": MessageLookupByLibrary.simpleMessage(
      "The payments and other coverages already entered exceed the new amount due. Update the payment first, then save the booking.",
    ),
    "bookingRescheduleCancelAction": MessageLookupByLibrary.simpleMessage(
      "Cancel reschedule",
    ),
    "bookingRescheduleConfirmMessage": m27,
    "bookingRescheduleConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm reschedule?",
    ),
    "bookingRescheduleMissingBooking": MessageLookupByLibrary.simpleMessage(
      "Booking not found.",
    ),
    "bookingRescheduleModeHint": MessageLookupByLibrary.simpleMessage(
      "Reschedule mode active: select a date and click a slot.",
    ),
    "bookingRescheduleModeHintWeekDifferent": MessageLookupByLibrary.simpleMessage(
      "Reschedule mode active: select a date (including another week) and click a slot.",
    ),
    "bookingRescheduleModeHintWeekSame": MessageLookupByLibrary.simpleMessage(
      "Reschedule mode active: select a slot in the current week or change week to choose another date.",
    ),
    "bookingRescheduleMoveFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to reschedule the booking.",
    ),
    "bookingRescheduleNotAvailableForCurrentView":
        MessageLookupByLibrary.simpleMessage(
          "Rescheduling is not available in multi-staff weekly view. Select a single staff member or switch to day view.",
        ),
    "bookingRescheduleOutOfDayBlocked": MessageLookupByLibrary.simpleMessage(
      "Unable to reschedule: one or more services would fall outside the selected day.",
    ),
    "bookingStaffNotEligibleWarning": MessageLookupByLibrary.simpleMessage(
      "Warning: the selected team member is not eligible for this service.",
    ),
    "bookingTotal": MessageLookupByLibrary.simpleMessage("Total"),
    "bookingTotalDuration": m28,
    "bookingTotalPrice": m29,
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
    "bookingsListStatusArrived": MessageLookupByLibrary.simpleMessage(
      "Arrived",
    ),
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
    "bookingsListTotalCount": m30,
    "bookingsListTotalWithPeriod": m31,
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
    "businessWhatsappEnabledHelper": MessageLookupByLibrary.simpleMessage(
      "Allows the business to use the WhatsApp integration.",
    ),
    "businessWhatsappEnabledLabel": MessageLookupByLibrary.simpleMessage(
      "Enable WhatsApp for this business",
    ),
    "businessWhatsappExistingClientsAssumeConsentedHelper":
        MessageLookupByLibrary.simpleMessage(
          "Use this only if the business declares it already has consent for existing clients. New clients will still need explicit consent.",
        ),
    "businessWhatsappExistingClientsAssumeConsentedLabel":
        MessageLookupByLibrary.simpleMessage(
          "Consider existing clients consented",
        ),
    "businessWhatsappExistingClientsExplicitOnlyHelper":
        MessageLookupByLibrary.simpleMessage(
          "Send WhatsApp messages only to clients who gave consent in the app.",
        ),
    "businessWhatsappExistingClientsExplicitOnlyLabel":
        MessageLookupByLibrary.simpleMessage("Require explicit consent"),
    "businessWhatsappExistingClientsOptInPolicyLabel":
        MessageLookupByLibrary.simpleMessage("Existing clients"),
    "businessWhatsappLocationMappingHelper": MessageLookupByLibrary.simpleMessage(
      "Allows different WhatsApp numbers to be assigned to individual locations.",
    ),
    "businessWhatsappLocationMappingLabel":
        MessageLookupByLibrary.simpleMessage("Enable location mapping"),
    "businessWhatsappMessagesEnabledHelper":
        MessageLookupByLibrary.simpleMessage(
          "Allows automatic WhatsApp messages to be queued and sent.",
        ),
    "businessWhatsappMessagesEnabledLabel":
        MessageLookupByLibrary.simpleMessage("Enable message sending"),
    "businessWhatsappSettingsDialogTitle": MessageLookupByLibrary.simpleMessage(
      "WhatsApp settings",
    ),
    "businessWhatsappSettingsMenuItem": MessageLookupByLibrary.simpleMessage(
      "WhatsApp",
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
      "A category with this name already exists. You can use it by selecting it in the Category field when creating a service, package, or class type.",
    ),
    "chooseServiceRemovalScopeAction": MessageLookupByLibrary.simpleMessage(
      "Remove service",
    ),
    "chooseServiceRemovalScopeTooltip": MessageLookupByLibrary.simpleMessage(
      "Choose how to remove this service",
    ),
    "classEventsActionBook": MessageLookupByLibrary.simpleMessage("Book"),
    "classEventsActionCancelBooking": MessageLookupByLibrary.simpleMessage(
      "Cancel booking",
    ),
    "classEventsAddButton": MessageLookupByLibrary.simpleMessage("Add"),
    "classEventsCapacitySummary": m32,
    "classEventsCapacitySummaryNoWaitlist": m33,
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
    "classEventsExpiredBadge": MessageLookupByLibrary.simpleMessage("Past"),
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
    "classEventsFieldPrice": MessageLookupByLibrary.simpleMessage("Price"),
    "classEventsFieldPriceFreeHint": MessageLookupByLibrary.simpleMessage(
      "Leave empty for free",
    ),
    "classEventsFieldStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "classEventsFieldStartTime": MessageLookupByLibrary.simpleMessage(
      "Start time",
    ),
    "classEventsFieldTitleOptional": MessageLookupByLibrary.simpleMessage(
      "Title (optional)",
    ),
    "classEventsFieldWaitlistEnabled": MessageLookupByLibrary.simpleMessage(
      "Enable waitlist",
    ),
    "classEventsFutureBadge": MessageLookupByLibrary.simpleMessage("Scheduled"),
    "classEventsNewScheduleButton": MessageLookupByLibrary.simpleMessage(
      "New class schedule",
    ),
    "classEventsNoClassTypes": MessageLookupByLibrary.simpleMessage(
      "No class types available",
    ),
    "classEventsNoLocationsForClassType": MessageLookupByLibrary.simpleMessage(
      "No enabled location for this class type",
    ),
    "classEventsNoScheduledDates": MessageLookupByLibrary.simpleMessage(
      "No scheduled dates",
    ),
    "classEventsNoStaffForLocation": MessageLookupByLibrary.simpleMessage(
      "No staff available for selected location",
    ),
    "classEventsNotifyParticipantsMessage": MessageLookupByLibrary.simpleMessage(
      "Do you want to send notification emails to the people affected by these changes?",
    ),
    "classEventsNotifyParticipantsTitle": MessageLookupByLibrary.simpleMessage(
      "Send email to participants?",
    ),
    "classEventsParticipantBookedAt": MessageLookupByLibrary.simpleMessage(
      "Booked at",
    ),
    "classEventsParticipantBookingNote": MessageLookupByLibrary.simpleMessage(
      "Booking note",
    ),
    "classEventsParticipantClientNote": MessageLookupByLibrary.simpleMessage(
      "Client note",
    ),
    "classEventsParticipantCustomer": m34,
    "classEventsParticipantsAddConfirmed": MessageLookupByLibrary.simpleMessage(
      "Add participant",
    ),
    "classEventsParticipantsAddWaitlist": MessageLookupByLibrary.simpleMessage(
      "Add to waitlist",
    ),
    "classEventsParticipantsConfirmedTitle":
        MessageLookupByLibrary.simpleMessage("Confirmed"),
    "classEventsParticipantsCopyList": MessageLookupByLibrary.simpleMessage(
      "Copy list",
    ),
    "classEventsParticipantsDemoteAction": MessageLookupByLibrary.simpleMessage(
      "Move to waitlist",
    ),
    "classEventsParticipantsEmptyConfirmed":
        MessageLookupByLibrary.simpleMessage("No confirmed participants"),
    "classEventsParticipantsEmptyWaitlist":
        MessageLookupByLibrary.simpleMessage("Nobody in waitlist"),
    "classEventsParticipantsListCopied": MessageLookupByLibrary.simpleMessage(
      "Copied to clipboard",
    ),
    "classEventsParticipantsListOpen": MessageLookupByLibrary.simpleMessage(
      "List view",
    ),
    "classEventsParticipantsListTitle": MessageLookupByLibrary.simpleMessage(
      "Participants list",
    ),
    "classEventsParticipantsLoadError": MessageLookupByLibrary.simpleMessage(
      "Unable to load participants",
    ),
    "classEventsParticipantsPriorityDown": MessageLookupByLibrary.simpleMessage(
      "Move down",
    ),
    "classEventsParticipantsPriorityUp": MessageLookupByLibrary.simpleMessage(
      "Move up",
    ),
    "classEventsParticipantsPromoteAction":
        MessageLookupByLibrary.simpleMessage("Promote to participant"),
    "classEventsParticipantsRemoveAction": MessageLookupByLibrary.simpleMessage(
      "Remove",
    ),
    "classEventsParticipantsSortFirstName":
        MessageLookupByLibrary.simpleMessage("First name"),
    "classEventsParticipantsSortLastName": MessageLookupByLibrary.simpleMessage(
      "Last name",
    ),
    "classEventsParticipantsSortRegistration":
        MessageLookupByLibrary.simpleMessage("Booking date"),
    "classEventsParticipantsTitle": MessageLookupByLibrary.simpleMessage(
      "Participants",
    ),
    "classEventsParticipantsWaitlistTitle":
        MessageLookupByLibrary.simpleMessage("Waitlist"),
    "classEventsPromoteWaitlistMessage": MessageLookupByLibrary.simpleMessage(
      "Do you want to automatically promote participants from the waitlist to fill the available spots?",
    ),
    "classEventsPromoteWaitlistTitle": MessageLookupByLibrary.simpleMessage(
      "Promote from waitlist",
    ),
    "classEventsRecurrenceConflictForceDescription":
        MessageLookupByLibrary.simpleMessage(
          "Create schedules even if there are overlaps",
        ),
    "classEventsRecurrenceConflictSkipDescription":
        MessageLookupByLibrary.simpleMessage(
          "Do not create schedules if there are overlaps",
        ),
    "classEventsRecurrenceCreateSummary": m35,
    "classEventsRecurrenceCreateSummaryWithSkipped": m36,
    "classEventsRecurrencePreviewConfirm": m37,
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
    "classEventsStaffInactiveChangeRequired": MessageLookupByLibrary.simpleMessage(
      "The assigned staff member is no longer active: select an active staff member to save.",
    ),
    "classEventsStaffInactiveOption": m38,
    "classEventsTitle": MessageLookupByLibrary.simpleMessage("Classes"),
    "classEventsUntitled": MessageLookupByLibrary.simpleMessage("Class"),
    "classEventsValidationCapacityBelowConfirmed":
        MessageLookupByLibrary.simpleMessage(
          "Capacity cannot be reduced below the number of confirmed participants",
        ),
    "classEventsValidationCapacityMin": MessageLookupByLibrary.simpleMessage(
      "Enter a minimum capacity",
    ),
    "classEventsValidationEndAfterStart": MessageLookupByLibrary.simpleMessage(
      "End time must be after start time",
    ),
    "classEventsValidationRequired": MessageLookupByLibrary.simpleMessage(
      "Fill all required fields",
    ),
    "classEventsWaitlistDisabledHint": MessageLookupByLibrary.simpleMessage(
      "Waitlist disabled — enable it if needed",
    ),
    "classTypesActionClone": MessageLookupByLibrary.simpleMessage("Duplicate"),
    "classTypesActionDeactivate": MessageLookupByLibrary.simpleMessage(
      "Delete",
    ),
    "classTypesActionNewSchedule": MessageLookupByLibrary.simpleMessage(
      "New Schedule",
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
    "classTypesCreateSuperadminOnlyMessage":
        MessageLookupByLibrary.simpleMessage(
          "Creating a class type is allowed only for superadmin users.",
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
    "classTypesDeleteHasFutureEventsMessage": MessageLookupByLibrary.simpleMessage(
      "There are future scheduled events linked to this event type. Delete or cancel those events before proceeding.",
    ),
    "classTypesDeleteHasFutureEventsTitle":
        MessageLookupByLibrary.simpleMessage("Cannot delete"),
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
    "classTypesFieldCategoryCode": MessageLookupByLibrary.simpleMessage(
      "Category",
    ),
    "classTypesFieldCategoryCodeNone": MessageLookupByLibrary.simpleMessage(
      "No category",
    ),
    "classTypesFieldDescriptionOptional": MessageLookupByLibrary.simpleMessage(
      "Description (optional)",
    ),
    "classTypesFieldIsActive": MessageLookupByLibrary.simpleMessage(
      "Type active",
    ),
    "classTypesFieldName": MessageLookupByLibrary.simpleMessage("Name"),
    "classTypesLocationsSelectionHelper": MessageLookupByLibrary.simpleMessage(
      "Select the locations where this class type can be scheduled. You can change this at any time.",
    ),
    "classTypesLocationsSelectionTitle": MessageLookupByLibrary.simpleMessage(
      "Enabled locations",
    ),
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
    "clientAppointmentsAction": MessageLookupByLibrary.simpleMessage(
      "Appointments",
    ),
    "clientAppointmentsCancelled": MessageLookupByLibrary.simpleMessage(
      "Cancelled",
    ),
    "clientAppointmentsCancelledBadge": MessageLookupByLibrary.simpleMessage(
      "CANCELLED",
    ),
    "clientAppointmentsEmpty": MessageLookupByLibrary.simpleMessage(
      "No appointments",
    ),
    "clientAppointmentsPast": MessageLookupByLibrary.simpleMessage("Past"),
    "clientAppointmentsTitle": m39,
    "clientAppointmentsUpcoming": MessageLookupByLibrary.simpleMessage(
      "Upcoming",
    ),
    "clientColorLabel": MessageLookupByLibrary.simpleMessage("Client color"),
    "clientContactsActionGroup": MessageLookupByLibrary.simpleMessage(
      "Contacts",
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
    "closuresDays": m40,
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
      "Import national holidays",
    ),
    "closuresImportHolidaysAction": m41,
    "closuresImportHolidaysAlreadyAdded": m42,
    "closuresImportHolidaysCopyLinkAction":
        MessageLookupByLibrary.simpleMessage("Copy booking link"),
    "closuresImportHolidaysExternalSourceInfo":
        MessageLookupByLibrary.simpleMessage(
          "Holidays are determined by an external service: Nager.Date",
        ),
    "closuresImportHolidaysLinkCopied": MessageLookupByLibrary.simpleMessage(
      "Link copied",
    ),
    "closuresImportHolidaysList": MessageLookupByLibrary.simpleMessage(
      "Select holidays to import:",
    ),
    "closuresImportHolidaysLocations": MessageLookupByLibrary.simpleMessage(
      "Apply to locations:",
    ),
    "closuresImportHolidaysSuccess": m43,
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
    "closuresTotalDays": m44,
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
    "deactivateServiceAction": MessageLookupByLibrary.simpleMessage(
      "Deactivate service",
    ),
    "deactivateServiceGloballyAction": MessageLookupByLibrary.simpleMessage(
      "Deactivate from all locations",
    ),
    "deactivateServiceMessage": MessageLookupByLibrary.simpleMessage(
      "The service will be deactivated and hidden from the management lists.",
    ),
    "deactivateServiceTitle": MessageLookupByLibrary.simpleMessage(
      "Deactivate this service?",
    ),
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
    "durationHour": m45,
    "durationHourMinute": m46,
    "durationMinute": m47,
    "editCategoryTitle": MessageLookupByLibrary.simpleMessage("Edit category"),
    "editServiceTitle": MessageLookupByLibrary.simpleMessage("Edit service"),
    "emptyCategoriesNotReorderableNote": MessageLookupByLibrary.simpleMessage(
      "Categories without services cannot be reordered and stay at the end.",
    ),
    "environmentDemoBannerSubtitle": MessageLookupByLibrary.simpleMessage(
      "Data is reset periodically.",
    ),
    "environmentDemoBannerTitle": MessageLookupByLibrary.simpleMessage(
      "DEMO ENVIRONMENT",
    ),
    "errorExceptionNotFound": m48,
    "errorFormFactorBuilderMissing": m49,
    "errorFormFactorBuilderRequired": MessageLookupByLibrary.simpleMessage(
      "Specify at least one builder for form factor",
    ),
    "errorNotFound": m50,
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
    "exceptionDurationDays": m51,
    "exceptionEditShift": MessageLookupByLibrary.simpleMessage(
      "Edit exception",
    ),
    "exceptionEditShiftDesc": MessageLookupByLibrary.simpleMessage(
      "Edit the times of this exception",
    ),
    "exceptionEndTime": MessageLookupByLibrary.simpleMessage("End time"),
    "exceptionPartialSaveInfo": m52,
    "exceptionPartialSaveInfoDetailed": m53,
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
    "forbiddenLocationScopeMessage": MessageLookupByLibrary.simpleMessage(
      "You do not have permission to modify data linked to a location outside your scope.",
    ),
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
    "hoursHoursOnly": m54,
    "hoursMinutesCompact": m55,
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
    "invitationAcceptIntro": m56,
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
    "lastVisitLabel": m57,
    "locationShowDurationToCustomerHint": MessageLookupByLibrary.simpleMessage(
      "If enabled, the duration is shown during online booking and in the booking list",
    ),
    "locationShowDurationToCustomerLabel": MessageLookupByLibrary.simpleMessage(
      "Show duration to customer",
    ),
    "locationShowPriceToCustomerHint": MessageLookupByLibrary.simpleMessage(
      "If enabled, the price is shown during online booking and in the booking list",
    ),
    "locationShowPriceToCustomerLabel": MessageLookupByLibrary.simpleMessage(
      "Show price to customer",
    ),
    "minutesLabel": MessageLookupByLibrary.simpleMessage("min"),
    "moreAppointmentTypesDescription": MessageLookupByLibrary.simpleMessage(
      "Manage services, events, categories and pricing",
    ),
    "moreAppointmentTypesTitle": MessageLookupByLibrary.simpleMessage(
      "Appointment types",
    ),
    "moreBookingNotificationsDescription": MessageLookupByLibrary.simpleMessage(
      "View booking notifications history",
    ),
    "moreBookingsDescription": MessageLookupByLibrary.simpleMessage(
      "Browse booking history",
    ),
    "moreClassEventsDescription": MessageLookupByLibrary.simpleMessage(
      "Manage classes and group schedules",
    ),
    "moreLocationsDescription": MessageLookupByLibrary.simpleMessage(
      "Manage business locations",
    ),
    "moreProfileDescription": MessageLookupByLibrary.simpleMessage(
      "Manage your personal data and credentials",
    ),
    "moreReportsDescription": MessageLookupByLibrary.simpleMessage(
      "View statistics and business performance",
    ),
    "moreSectionBusinessConfig": MessageLookupByLibrary.simpleMessage(
      "Business Configuration",
    ),
    "moreSectionDataAnalysis": MessageLookupByLibrary.simpleMessage(
      "Data Analysis",
    ),
    "moreSectionProfileManage": MessageLookupByLibrary.simpleMessage(
      "Manage your profile",
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
    "moreWhatsappBusinessDescription": MessageLookupByLibrary.simpleMessage(
      "Enable and configure WhatsApp messaging for automatic notifications.",
    ),
    "moreWhatsappBusinessGuidePlaceholderBody":
        MessageLookupByLibrary.simpleMessage(
          "This area will show the step-by-step operational guide to activate WhatsApp messaging.",
        ),
    "moreWhatsappBusinessGuidePlaceholderTitle":
        MessageLookupByLibrary.simpleMessage("Setup guide"),
    "moreWhatsappBusinessTitle": MessageLookupByLibrary.simpleMessage(
      "WhatsApp Business",
    ),
    "moveAppointmentConfirmMessage": m58,
    "moveAppointmentConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm move?",
    ),
    "moveConfirmNotifyCheckbox": MessageLookupByLibrary.simpleMessage(
      "Send client notification and adjust unsent reminders",
    ),
    "multiServiceMoveDecisionMessage": MessageLookupByLibrary.simpleMessage(
      "This booking contains multiple services. Choose how to proceed.",
    ),
    "multiServiceMoveDecisionMoveBooking": MessageLookupByLibrary.simpleMessage(
      "Move entire booking",
    ),
    "multiServiceMoveDecisionSplitService":
        MessageLookupByLibrary.simpleMessage("Move only this service"),
    "multiServiceMoveDecisionTitle": MessageLookupByLibrary.simpleMessage(
      "Multi-service booking",
    ),
    "multiServiceMoveSplitUnavailableMessage": MessageLookupByLibrary.simpleMessage(
      "Moving a single service requires an atomic split not available in the current API. Use \"Move entire booking\".",
    ),
    "multiServiceMoveSplitUnavailableTitle":
        MessageLookupByLibrary.simpleMessage("Move not available"),
    "multiServiceNonFirstMoveBlockedMessage":
        MessageLookupByLibrary.simpleMessage(
          "For multi-service bookings, only the first service can be moved.",
        ),
    "multiServiceNonFirstMoveBlockedTitle":
        MessageLookupByLibrary.simpleMessage("Move blocked"),
    "navAgenda": MessageLookupByLibrary.simpleMessage("Agenda"),
    "navClients": MessageLookupByLibrary.simpleMessage("Clients"),
    "navMore": MessageLookupByLibrary.simpleMessage("More"),
    "navProfile": MessageLookupByLibrary.simpleMessage("Profile"),
    "navServices": MessageLookupByLibrary.simpleMessage("Services"),
    "navStaff": MessageLookupByLibrary.simpleMessage("Team"),
    "networkConnectionError": MessageLookupByLibrary.simpleMessage(
      "Could not connect to the server. Check your internet connection.",
    ),
    "networkRequestCancelled": MessageLookupByLibrary.simpleMessage(
      "The request was cancelled before it could complete. Please try again.",
    ),
    "networkTimeoutError": MessageLookupByLibrary.simpleMessage(
      "Connection timed out. Please try again.",
    ),
    "networkUnknownError": MessageLookupByLibrary.simpleMessage(
      "Network error. Please try again.",
    ),
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
    "onlineBookingVisibilityDirectLinkOption":
        MessageLookupByLibrary.simpleMessage("Direct link only"),
    "onlineBookingVisibilityHiddenOption": MessageLookupByLibrary.simpleMessage(
      "Not bookable online",
    ),
    "onlineBookingVisibilityLabel": MessageLookupByLibrary.simpleMessage(
      "Online booking visibility",
    ),
    "onlineBookingVisibilityPublicOption": MessageLookupByLibrary.simpleMessage(
      "Visible on the public booking page",
    ),
    "operatorsAcceptedOn": m59,
    "operatorsAccessNone": MessageLookupByLibrary.simpleMessage("None"),
    "operatorsAccessSelected": MessageLookupByLibrary.simpleMessage(
      "Selected only",
    ),
    "operatorsAccessibleClassTypes": MessageLookupByLibrary.simpleMessage(
      "Accessible class types",
    ),
    "operatorsAccessibleServices": MessageLookupByLibrary.simpleMessage(
      "Accessible services",
    ),
    "operatorsAccessibleStaff": MessageLookupByLibrary.simpleMessage(
      "Accessible team members",
    ),
    "operatorsDeleteInvite": MessageLookupByLibrary.simpleMessage(
      "Delete invite",
    ),
    "operatorsDeleteInviteConfirm": m60,
    "operatorsEditRole": MessageLookupByLibrary.simpleMessage("Edit role"),
    "operatorsEmpty": MessageLookupByLibrary.simpleMessage(
      "No operators configured",
    ),
    "operatorsExpires": m61,
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
    "operatorsInviteSuccess": m62,
    "operatorsInviteTitle": MessageLookupByLibrary.simpleMessage(
      "Invite operator",
    ),
    "operatorsInvitedBy": m63,
    "operatorsInvitesHistoryCount": m64,
    "operatorsPendingInvites": MessageLookupByLibrary.simpleMessage(
      "Pending invites",
    ),
    "operatorsPendingInvitesCount": m65,
    "operatorsPermBookings": MessageLookupByLibrary.simpleMessage(
      "Manage bookings",
    ),
    "operatorsPermClients": MessageLookupByLibrary.simpleMessage(
      "Manage clients",
    ),
    "operatorsPermReports": MessageLookupByLibrary.simpleMessage(
      "Access reports",
    ),
    "operatorsPermServices": MessageLookupByLibrary.simpleMessage(
      "Manage services & pricing",
    ),
    "operatorsPermStaff": MessageLookupByLibrary.simpleMessage("Manage team"),
    "operatorsPermissionsTitle": MessageLookupByLibrary.simpleMessage(
      "Permissions",
    ),
    "operatorsRemove": MessageLookupByLibrary.simpleMessage("Remove operator"),
    "operatorsRemoveConfirm": m66,
    "operatorsRemoveSuccess": MessageLookupByLibrary.simpleMessage(
      "Operator removed",
    ),
    "operatorsRevokeInvite": MessageLookupByLibrary.simpleMessage(
      "Revoke invite",
    ),
    "operatorsRevokeInviteConfirm": m67,
    "operatorsRoleAdmin": MessageLookupByLibrary.simpleMessage("Administrator"),
    "operatorsRoleAdminDesc": MessageLookupByLibrary.simpleMessage(
      "Full access to all features. Can manage other operators and modify business settings.",
    ),
    "operatorsRoleCustom": MessageLookupByLibrary.simpleMessage(
      "Custom operator",
    ),
    "operatorsRoleCustomDesc": MessageLookupByLibrary.simpleMessage(
      "Fully configurable permissions and scope: choose what they can manage and which services, class types, and team members they operate on.",
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
    "parallelCapacityError": MessageLookupByLibrary.simpleMessage(
      "Enter a number greater than or equal to 1.",
    ),
    "parallelCapacityHint": MessageLookupByLibrary.simpleMessage(
      "Maximum number of clients bookable at the same time.",
    ),
    "parallelCapacityLabel": MessageLookupByLibrary.simpleMessage(
      "Concurrent bookings",
    ),
    "paymentAmountDue": MessageLookupByLibrary.simpleMessage("Amount due"),
    "paymentAppointmentsToCollect": MessageLookupByLibrary.simpleMessage(
      "Total appointments to collect",
    ),
    "paymentBookingAmount": MessageLookupByLibrary.simpleMessage(
      "Booking amount",
    ),
    "paymentCashAndCardTotal": MessageLookupByLibrary.simpleMessage(
      "Total cash and cards",
    ),
    "paymentDialogTitle": MessageLookupByLibrary.simpleMessage("Payment"),
    "paymentEntered": MessageLookupByLibrary.simpleMessage("Total collected"),
    "paymentMethodCard": MessageLookupByLibrary.simpleMessage(
      "Debit/Credit Card",
    ),
    "paymentMethodCash": MessageLookupByLibrary.simpleMessage("Cash"),
    "paymentMethodDiscount": MessageLookupByLibrary.simpleMessage("Discount"),
    "paymentMethodOther": MessageLookupByLibrary.simpleMessage("Other"),
    "paymentMethodPending": MessageLookupByLibrary.simpleMessage(
      "Still to pay",
    ),
    "paymentMethodVoucher": MessageLookupByLibrary.simpleMessage(
      "Voucher/Package",
    ),
    "paymentMethodsAdd": MessageLookupByLibrary.simpleMessage("Add method"),
    "paymentMethodsDeleteMessage": m68,
    "paymentMethodsDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Delete payment method",
    ),
    "paymentMethodsDescription": MessageLookupByLibrary.simpleMessage(
      "Manage business payment method types",
    ),
    "paymentMethodsEdit": MessageLookupByLibrary.simpleMessage("Edit method"),
    "paymentMethodsEmpty": MessageLookupByLibrary.simpleMessage(
      "No payment methods available",
    ),
    "paymentMethodsFieldIsRevenue": MessageLookupByLibrary.simpleMessage(
      "Count as revenue",
    ),
    "paymentMethodsFieldIsRevenueHelp": MessageLookupByLibrary.simpleMessage(
      "If enabled, payments with this method are counted as real revenue in reports. Disable for gift vouchers, gift cards, or prepaid packages.",
    ),
    "paymentMethodsFieldName": MessageLookupByLibrary.simpleMessage("Name"),
    "paymentMethodsFieldSort": MessageLookupByLibrary.simpleMessage("Order"),
    "paymentMethodsNameRequired": MessageLookupByLibrary.simpleMessage(
      "Enter a payment method name",
    ),
    "paymentMethodsNonRevenueBadge": MessageLookupByLibrary.simpleMessage(
      "Non-revenue",
    ),
    "paymentMethodsReorderHint": MessageLookupByLibrary.simpleMessage(
      "You can change the payment type order by dragging them.",
    ),
    "paymentMethodsRevenueBadge": MessageLookupByLibrary.simpleMessage(
      "Real revenue",
    ),
    "paymentMethodsTitle": MessageLookupByLibrary.simpleMessage(
      "Payment methods",
    ),
    "paymentNotesLabel": MessageLookupByLibrary.simpleMessage("Payment notes"),
    "paymentNotesPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Notes about the payment...",
    ),
    "paymentOutstanding": MessageLookupByLibrary.simpleMessage(
      "Outstanding to collect",
    ),
    "paymentRemaining": MessageLookupByLibrary.simpleMessage("Remaining"),
    "paymentRequired": MessageLookupByLibrary.simpleMessage(
      "Total appointments",
    ),
    "paymentStatusPaid": MessageLookupByLibrary.simpleMessage("Paid"),
    "paymentStatusPartial": MessageLookupByLibrary.simpleMessage(
      "Partially paid",
    ),
    "paymentStatusUnpaid": MessageLookupByLibrary.simpleMessage("Unpaid"),
    "paymentTotalCost": MessageLookupByLibrary.simpleMessage("Booking cost"),
    "paymentTotalPaid": MessageLookupByLibrary.simpleMessage("Paid amount"),
    "paymentTotalToCollect": MessageLookupByLibrary.simpleMessage(
      "Total to collect",
    ),
    "permissionsDescription": MessageLookupByLibrary.simpleMessage(
      "Manage operator access and roles",
    ),
    "permissionsTitle": MessageLookupByLibrary.simpleMessage("Permissions"),
    "planningActive": MessageLookupByLibrary.simpleMessage("Active"),
    "planningBiweeklyDuration": m69,
    "planningBiweeklyHours": m70,
    "planningCreateTitle": MessageLookupByLibrary.simpleMessage("New planning"),
    "planningCurrentWeek": m71,
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
    "planningShowExpired": m72,
    "planningType": MessageLookupByLibrary.simpleMessage("Planning type"),
    "planningTypeBiweekly": MessageLookupByLibrary.simpleMessage("Biweekly"),
    "planningTypeUnavailable": MessageLookupByLibrary.simpleMessage(
      "Unavailable",
    ),
    "planningTypeWeekly": MessageLookupByLibrary.simpleMessage("Weekly"),
    "planningValidFrom": MessageLookupByLibrary.simpleMessage(
      "Validity start date",
    ),
    "planningValidFromOnly": m73,
    "planningValidFromTo": m74,
    "planningValidTo": MessageLookupByLibrary.simpleMessage(
      "Validity end date",
    ),
    "planningValidityFrom": m75,
    "planningValidityRange": m76,
    "planningWeekA": MessageLookupByLibrary.simpleMessage("Week A"),
    "planningWeekB": MessageLookupByLibrary.simpleMessage("Week B"),
    "planningWeeklyDuration": m77,
    "planningWeeklyHours": m78,
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
    "profileLanguageEnglish": MessageLookupByLibrary.simpleMessage("English"),
    "profileLanguageItalian": MessageLookupByLibrary.simpleMessage("Italian"),
    "profileLanguageLabel": MessageLookupByLibrary.simpleMessage(
      "Admin language",
    ),
    "profileLanguageUseSystem": MessageLookupByLibrary.simpleMessage(
      "Use system language",
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
    "recurrencePreviewConfirm": m79,
    "recurrencePreviewConflictForce": MessageLookupByLibrary.simpleMessage(
      "Create anyway",
    ),
    "recurrencePreviewConflictSkip": MessageLookupByLibrary.simpleMessage(
      "Skip due to conflict",
    ),
    "recurrencePreviewConflicts": m80,
    "recurrencePreviewCount": m81,
    "recurrencePreviewExcludeConflicts": MessageLookupByLibrary.simpleMessage(
      "Exclude overlaps",
    ),
    "recurrencePreviewExcludeUnavailable": MessageLookupByLibrary.simpleMessage(
      "Exclude unavailable slots",
    ),
    "recurrencePreviewHint": MessageLookupByLibrary.simpleMessage(
      "Uncheck the dates you don\'t want to create",
    ),
    "recurrencePreviewIncludeConflicts": MessageLookupByLibrary.simpleMessage(
      "Include overlaps",
    ),
    "recurrencePreviewIncludeUnavailable": MessageLookupByLibrary.simpleMessage(
      "Include unavailable slots",
    ),
    "recurrencePreviewSelected": m82,
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
    "recurrenceSeriesOf": m83,
    "recurrenceSummaryAppointments": MessageLookupByLibrary.simpleMessage(
      "Appointments:",
    ),
    "recurrenceSummaryConflict": MessageLookupByLibrary.simpleMessage(
      "Skipped due to conflict",
    ),
    "recurrenceSummaryCreated": m84,
    "recurrenceSummaryDeleted": MessageLookupByLibrary.simpleMessage("Deleted"),
    "recurrenceSummaryError": MessageLookupByLibrary.simpleMessage(
      "Error creating series",
    ),
    "recurrenceSummarySkipped": m85,
    "recurrenceSummaryTitle": MessageLookupByLibrary.simpleMessage(
      "Series created",
    ),
    "recurrenceWeek": MessageLookupByLibrary.simpleMessage("week"),
    "recurrenceWeeks": MessageLookupByLibrary.simpleMessage("weeks"),
    "recurringDeleteChooseScope": MessageLookupByLibrary.simpleMessage(
      "Which appointments do you want to delete?",
    ),
    "recurringDeleteMessage": m86,
    "recurringDeleteTitle": MessageLookupByLibrary.simpleMessage(
      "Delete recurring appointment",
    ),
    "recurringEditChooseScope": MessageLookupByLibrary.simpleMessage(
      "Which appointments do you want to edit?",
    ),
    "recurringEditMessage": m87,
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
    "removeServiceFromLocationAction": MessageLookupByLibrary.simpleMessage(
      "Remove from this location",
    ),
    "removeServiceFromLocationMessage": MessageLookupByLibrary.simpleMessage(
      "The service will no longer be available in this location. If it is active in other locations, it will stay available there.",
    ),
    "removeServiceFromLocationTitle": MessageLookupByLibrary.simpleMessage(
      "Remove service from this location?",
    ),
    "removeServiceFromManageableLocationsAction":
        MessageLookupByLibrary.simpleMessage("From all manageable locations"),
    "removeServiceFromSelectedLocationTooltip":
        MessageLookupByLibrary.simpleMessage("Remove from selected location"),
    "removeServiceMultiLocationMessage": MessageLookupByLibrary.simpleMessage(
      "This service is active in multiple locations you can manage. Choose whether to remove it only from the selected location or from all manageable locations.",
    ),
    "removeServiceMultiLocationTitle": MessageLookupByLibrary.simpleMessage(
      "Remove service?",
    ),
    "reorderCategoriesLabel": MessageLookupByLibrary.simpleMessage(
      "Categories",
    ),
    "reorderClassesLabel": MessageLookupByLibrary.simpleMessage("Classes"),
    "reorderDoneButtonLabel": MessageLookupByLibrary.simpleMessage(
      "Done reordering",
    ),
    "reorderHelpDescription": MessageLookupByLibrary.simpleMessage(
      "Reorder categories and services by dragging them: the same order will be applied to online booking. Select whether to sort categories or services.",
    ),
    "reorderServicesAndPackagesLabel": MessageLookupByLibrary.simpleMessage(
      "Services and/or Packages",
    ),
    "reorderServicesLabel": MessageLookupByLibrary.simpleMessage("Services"),
    "reorderTitle": MessageLookupByLibrary.simpleMessage("Reorder"),
    "reportsAppointmentsAmount": MessageLookupByLibrary.simpleMessage(
      "Total collected",
    ),
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
    "reportsColRevenue": MessageLookupByLibrary.simpleMessage("Amount"),
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
    "reportsPresetYesterday": MessageLookupByLibrary.simpleMessage("Yesterday"),
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
    "rescheduleNotifyDecisionMessage": MessageLookupByLibrary.simpleMessage(
      "The booking start time changed. Do you want to send a client notification? Unsent reminders will be adjusted automatically.",
    ),
    "rescheduleNotifyDecisionSend": MessageLookupByLibrary.simpleMessage(
      "Send notification",
    ),
    "rescheduleNotifyDecisionSkip": MessageLookupByLibrary.simpleMessage(
      "Do not send",
    ),
    "rescheduleNotifyDecisionTitle": MessageLookupByLibrary.simpleMessage(
      "Send notification to client?",
    ),
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
    "resourceServiceCountPlural": m88,
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
      "Resources are equipment or spaces (e.g., cabins, beds) that can be requested by services",
    ),
    "resourcesTitle": MessageLookupByLibrary.simpleMessage("Resources"),
    "searchClientPlaceholder": MessageLookupByLibrary.simpleMessage(
      "Search client...",
    ),
    "searchServices": MessageLookupByLibrary.simpleMessage("Search service..."),
    "selectClientTitle": MessageLookupByLibrary.simpleMessage("Select client"),
    "selectService": MessageLookupByLibrary.simpleMessage("Select service"),
    "selectStaffTitle": MessageLookupByLibrary.simpleMessage("Select team"),
    "serverError500": MessageLookupByLibrary.simpleMessage(
      "Internal server error. Please try again later.",
    ),
    "serverError502": MessageLookupByLibrary.simpleMessage(
      "Service temporarily unavailable (bad gateway). Please try again.",
    ),
    "serverError503": MessageLookupByLibrary.simpleMessage(
      "Service temporarily unavailable. Please try again shortly.",
    ),
    "serverError504": MessageLookupByLibrary.simpleMessage(
      "Server response timeout. Please try again.",
    ),
    "serviceColorLabel": MessageLookupByLibrary.simpleMessage("Service color"),
    "serviceDeleteMultipleLocationsBlocked": MessageLookupByLibrary.simpleMessage(
      "This service is active in multiple locations. You can remove it from the selected location, or deactivate it when it remains associated with only one location.",
    ),
    "serviceDuplicateCopyWord": MessageLookupByLibrary.simpleMessage("Copy"),
    "serviceDuplicateError": MessageLookupByLibrary.simpleMessage(
      "A service with this name already exists",
    ),
    "serviceEligibleStaffCount": m89,
    "serviceEligibleStaffNone": MessageLookupByLibrary.simpleMessage(
      "No eligible team members",
    ),
    "serviceLocationsCount": m90,
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
    "servicesSelectedCount": m91,
    "servicesTabLabel": MessageLookupByLibrary.simpleMessage("Services"),
    "servicesTypeFilterClasses": MessageLookupByLibrary.simpleMessage(
      "Classes",
    ),
    "servicesTypeFilterServicesAndPackages":
        MessageLookupByLibrary.simpleMessage("Services and packages"),
    "setPriceToEnable": MessageLookupByLibrary.simpleMessage(
      "Set a price to enable this option",
    ),
    "shiftDeleteAll": MessageLookupByLibrary.simpleMessage(
      "Delete all these shifts",
    ),
    "shiftDeleteAllDesc": m92,
    "shiftDeleteThisOnly": MessageLookupByLibrary.simpleMessage(
      "Delete only this shift",
    ),
    "shiftDeleteThisOnlyDesc": m93,
    "shiftEditAll": MessageLookupByLibrary.simpleMessage(
      "Edit all these shifts",
    ),
    "shiftEditAllDesc": m94,
    "shiftEditThisOnly": MessageLookupByLibrary.simpleMessage(
      "Edit only this shift",
    ),
    "shiftEditThisOnlyDesc": m95,
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
    "teamEligibleServicesCount": m96,
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
          "If disabled, the system assigns the service provider automatically",
        ),
    "teamLocationAllowCustomerChooseStaffLabel":
        MessageLookupByLibrary.simpleMessage(
          "Allow customers to choose the service provider",
        ),
    "teamLocationAllowMultiServiceBookingHint":
        MessageLookupByLibrary.simpleMessage(
          "If disabled, the customer can select only one service, package, or event per booking",
        ),
    "teamLocationAllowMultiServiceBookingLabel":
        MessageLookupByLibrary.simpleMessage(
          "Allow multiple service/package/event selection online",
        ),
    "teamLocationBookingConfirmationMessageHelper":
        MessageLookupByLibrary.simpleMessage(
          "You can use line breaks to separate information and make a word or sentence bold by wrapping it with two asterisks.\n\nExample: **Please arrive 10 minutes early**.",
        ),
    "teamLocationBookingConfirmationMessageLabel":
        MessageLookupByLibrary.simpleMessage("Online confirmation message"),
    "teamLocationBookingConfirmationMessagePlaceholder":
        MessageLookupByLibrary.simpleMessage(
          "Example: **Important:** please arrive 10 minutes before your appointment.\n\nSportswear is required for classes.",
        ),
    "teamLocationBookingDefaultLocaleAuto":
        MessageLookupByLibrary.simpleMessage("Automatic"),
    "teamLocationBookingDefaultLocaleEnglish":
        MessageLookupByLibrary.simpleMessage("English"),
    "teamLocationBookingDefaultLocaleHint": MessageLookupByLibrary.simpleMessage(
      "Sets the initial language for the booking frontend. It does not change timezone or admin app language.",
    ),
    "teamLocationBookingDefaultLocaleItalian":
        MessageLookupByLibrary.simpleMessage("Italian"),
    "teamLocationBookingDefaultLocaleLabel":
        MessageLookupByLibrary.simpleMessage("Default online booking language"),
    "teamLocationBookingIntroMessageHelper": MessageLookupByLibrary.simpleMessage(
      "You can use line breaks to separate information and make a word or sentence bold by wrapping it with two asterisks.\n\nExample: **Please arrive 10 minutes early**.",
    ),
    "teamLocationBookingIntroMessageLabel":
        MessageLookupByLibrary.simpleMessage("Online booking intro message"),
    "teamLocationBookingIntroMessagePlaceholder":
        MessageLookupByLibrary.simpleMessage(
          "Example: **Important:** please arrive 10 minutes before your appointment.\n\nSportswear is required for classes.",
        ),
    "teamLocationBookingLimitsSection": MessageLookupByLibrary.simpleMessage(
      "Online booking limits",
    ),
    "teamLocationBookingTextOverridesDefaultOnly":
        MessageLookupByLibrary.simpleMessage(
          "Only the \"default\" block is allowed.",
        ),
    "teamLocationBookingTextOverridesHelper":
        MessageLookupByLibrary.simpleMessage(
          "Single block only: required key \"default\".",
        ),
    "teamLocationBookingTextOverridesHint":
        MessageLookupByLibrary.simpleMessage(
          "{\"default\":{\"services_title\":\"Choose activities\"}}",
        ),
    "teamLocationBookingTextOverridesInvalid":
        MessageLookupByLibrary.simpleMessage(
          "Invalid JSON. Provide an object with non-empty phrases.",
        ),
    "teamLocationBookingTextOverridesLabel":
        MessageLookupByLibrary.simpleMessage("Nomenclature JSON"),
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
    "teamLocationCancellationHoursUseBusinessWithValue": m97,
    "teamLocationCountryAustria": MessageLookupByLibrary.simpleMessage(
      "Austria",
    ),
    "teamLocationCountryBelgium": MessageLookupByLibrary.simpleMessage(
      "Belgium",
    ),
    "teamLocationCountryFrance": MessageLookupByLibrary.simpleMessage("France"),
    "teamLocationCountryGermany": MessageLookupByLibrary.simpleMessage(
      "Germany",
    ),
    "teamLocationCountryHint": MessageLookupByLibrary.simpleMessage("e.g. IT"),
    "teamLocationCountryItaly": MessageLookupByLibrary.simpleMessage("Italy"),
    "teamLocationCountryLabel": MessageLookupByLibrary.simpleMessage("Country"),
    "teamLocationCountryNetherlands": MessageLookupByLibrary.simpleMessage(
      "Netherlands",
    ),
    "teamLocationCountryPortugal": MessageLookupByLibrary.simpleMessage(
      "Portugal",
    ),
    "teamLocationCountrySpain": MessageLookupByLibrary.simpleMessage("Spain"),
    "teamLocationCountrySwitzerland": MessageLookupByLibrary.simpleMessage(
      "Switzerland",
    ),
    "teamLocationCountryUnitedKingdom": MessageLookupByLibrary.simpleMessage(
      "United Kingdom",
    ),
    "teamLocationCountryUnitedStates": MessageLookupByLibrary.simpleMessage(
      "United States",
    ),
    "teamLocationDays": m98,
    "teamLocationEmailHint": MessageLookupByLibrary.simpleMessage(
      "Email to receive customer replies",
    ),
    "teamLocationEmailLabel": MessageLookupByLibrary.simpleMessage(
      "Customer reply email",
    ),
    "teamLocationHours": m99,
    "teamLocationIsActiveHint": MessageLookupByLibrary.simpleMessage(
      "If disabled, the location will not be visible to customers",
    ),
    "teamLocationIsActiveLabel": MessageLookupByLibrary.simpleMessage(
      "Location active",
    ),
    "teamLocationLabel": MessageLookupByLibrary.simpleMessage("Location"),
    "teamLocationLocationDisplayHint": MessageLookupByLibrary.simpleMessage(
      "E.g. Location, Place, Room",
    ),
    "teamLocationLocationDisplayLabel": MessageLookupByLibrary.simpleMessage(
      "Location label",
    ),
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
    "teamLocationMinutes": m100,
    "teamLocationNameLabel": MessageLookupByLibrary.simpleMessage(
      "Location name",
    ),
    "teamLocationNomenclatureAddRow": MessageLookupByLibrary.simpleMessage(
      "Add label",
    ),
    "teamLocationNomenclatureCountPlaceholderError":
        MessageLookupByLibrary.simpleMessage(
          "For \"services_selected_many\" you must include the count placeholder.",
        ),
    "teamLocationNomenclatureCountPlaceholderNote": m101,
    "teamLocationNomenclatureDefaultValue": m102,
    "teamLocationNomenclatureDuplicateKey":
        MessageLookupByLibrary.simpleMessage(
          "The same key has been entered more than once.",
        ),
    "teamLocationNomenclatureEditorIntro": MessageLookupByLibrary.simpleMessage(
      "Add only the labels you want to override. They will apply to all users.",
    ),
    "teamLocationNomenclatureInputHint": MessageLookupByLibrary.simpleMessage(
      "Enter custom text (optional)",
    ),
    "teamLocationNomenclatureKeyLabel": MessageLookupByLibrary.simpleMessage(
      "Key",
    ),
    "teamLocationNomenclatureLeaveEmptyHint":
        MessageLookupByLibrary.simpleMessage("Leave empty to keep default."),
    "teamLocationNomenclatureSection": MessageLookupByLibrary.simpleMessage(
      "Online booking nomenclature",
    ),
    "teamLocationNomenclatureValueLabel": MessageLookupByLibrary.simpleMessage(
      "Custom text",
    ),
    "teamLocationNotificationEmailsHelper": MessageLookupByLibrary.simpleMessage(
      "Alerts for online customer activity (booking, modify, cancel). Separate multiple emails with commas.",
    ),
    "teamLocationNotificationEmailsHint": MessageLookupByLibrary.simpleMessage(
      "email1@example.com, email2@example.com",
    ),
    "teamLocationNotificationEmailsLabel": MessageLookupByLibrary.simpleMessage(
      "Customer booking notification emails",
    ),
    "teamLocationOnlineBookingEnabledHint": MessageLookupByLibrary.simpleMessage(
      "If disabled, this location cannot be booked online. It remains visible and operational in the management panel.",
    ),
    "teamLocationOnlineBookingEnabledLabel":
        MessageLookupByLibrary.simpleMessage("Online booking"),
    "teamLocationOnlineBookingSettingsSection":
        MessageLookupByLibrary.simpleMessage(
          "Online booking configuration for this location",
        ),
    "teamLocationServiceDisplayHint": MessageLookupByLibrary.simpleMessage(
      "E.g. Service, Treatment, Session",
    ),
    "teamLocationServiceDisplayLabel": MessageLookupByLibrary.simpleMessage(
      "Service label",
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
    "teamLocationStaffDisplayHint": MessageLookupByLibrary.simpleMessage(
      "E.g. Team member, Resource, Specialist",
    ),
    "teamLocationStaffDisplayLabel": MessageLookupByLibrary.simpleMessage(
      "Team label",
    ),
    "teamLocationStaffIconKeyHint": MessageLookupByLibrary.simpleMessage(
      "Icon shown in online booking for service provider selection",
    ),
    "teamLocationStaffIconKeyLabel": MessageLookupByLibrary.simpleMessage(
      "Service provider selection icon",
    ),
    "teamLocationTimezoneHint": MessageLookupByLibrary.simpleMessage(
      "e.g. Europe/Rome",
    ),
    "teamLocationTimezoneLabel": MessageLookupByLibrary.simpleMessage(
      "Timezone",
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
    "teamSelectedServicesCount": m103,
    "teamServicesLabel": MessageLookupByLibrary.simpleMessage("Services"),
    "teamStaffBookableOnlineLabel": MessageLookupByLibrary.simpleMessage(
      "Enabled for online bookings",
    ),
    "teamStaffColorLabel": MessageLookupByLibrary.simpleMessage("Color"),
    "teamStaffHasFutureBookingsQuestion": MessageLookupByLibrary.simpleMessage(
      "Would you like to view the future bookings assigned to this team member?",
    ),
    "teamStaffLabel": MessageLookupByLibrary.simpleMessage("Team"),
    "teamStaffLocationsLabel": MessageLookupByLibrary.simpleMessage(
      "Assigned locations",
    ),
    "teamStaffMultiLocationWarning": MessageLookupByLibrary.simpleMessage(
      "If the member works across multiple locations, make sure availability aligns with the selected locations.",
    ),
    "teamStaffNameLabel": MessageLookupByLibrary.simpleMessage("First name"),
    "teamStaffSurnameLabel": MessageLookupByLibrary.simpleMessage("Last name"),
    "teamStaffViewFutureBookings": MessageLookupByLibrary.simpleMessage(
      "View bookings",
    ),
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
    "weeklyScheduleTotalHours": m104,
    "whatsappAddConfig": MessageLookupByLibrary.simpleMessage(
      "New configuration",
    ),
    "whatsappBusinessMessagesDisabledMessage":
        MessageLookupByLibrary.simpleMessage(
          "WhatsApp message sending has been disabled for this business.",
        ),
    "whatsappBusinessMessagesEnabledMessage":
        MessageLookupByLibrary.simpleMessage(
          "WhatsApp message sending is active for this business.",
        ),
    "whatsappBusinessMessagesSuperadminDisabled":
        MessageLookupByLibrary.simpleMessage(
          "Turn this on to resume automatic WhatsApp sends from the management system.",
        ),
    "whatsappBusinessMessagesSuperadminEnabled":
        MessageLookupByLibrary.simpleMessage(
          "Turn this off to pause automatic WhatsApp sends from the management system.",
        ),
    "whatsappBusinessMessagesToggleTitle": MessageLookupByLibrary.simpleMessage(
      "WhatsApp message sending",
    ),
    "whatsappBusinessMessagesUpdatedTitle":
        MessageLookupByLibrary.simpleMessage("Setting updated"),
    "whatsappCheckOptInActive": MessageLookupByLibrary.simpleMessage(
      "Client opt-in active",
    ),
    "whatsappCheckPhoneNumberActive": MessageLookupByLibrary.simpleMessage(
      "WhatsApp number active",
    ),
    "whatsappCheckTemplateApproved": MessageLookupByLibrary.simpleMessage(
      "Utility template approved",
    ),
    "whatsappCheckWebhookVerified": MessageLookupByLibrary.simpleMessage(
      "Webhook verified",
    ),
    "whatsappConfigsTitle": MessageLookupByLibrary.simpleMessage(
      "Numbers and configurations",
    ),
    "whatsappConnectMeta": MessageLookupByLibrary.simpleMessage(
      "Connect with Meta",
    ),
    "whatsappConnectionInvalidMessage": MessageLookupByLibrary.simpleMessage(
      "WhatsApp is configured, but the Meta connection is no longer valid. Reconnect the account to resume message sending.",
    ),
    "whatsappConnectionInvalidTitle": MessageLookupByLibrary.simpleMessage(
      "Meta connection no longer valid",
    ),
    "whatsappCopyTechnicalValueTooltip": MessageLookupByLibrary.simpleMessage(
      "Copy",
    ),
    "whatsappCreateLocationCta": MessageLookupByLibrary.simpleMessage(
      "Create location",
    ),
    "whatsappDeleteConfigMessage": MessageLookupByLibrary.simpleMessage(
      "This action removes the configuration and related mappings.",
    ),
    "whatsappDeleteConfigTitle": MessageLookupByLibrary.simpleMessage(
      "Delete WhatsApp configuration?",
    ),
    "whatsappEditConfig": MessageLookupByLibrary.simpleMessage(
      "Edit configuration",
    ),
    "whatsappEmbeddedSignupCode": MessageLookupByLibrary.simpleMessage("Code"),
    "whatsappEmbeddedSignupConfirm": MessageLookupByLibrary.simpleMessage(
      "Complete connection",
    ),
    "whatsappEmbeddedSignupDisplayPhone": MessageLookupByLibrary.simpleMessage(
      "Display phone number (+39...)",
    ),
    "whatsappEmbeddedSignupHint": MessageLookupByLibrary.simpleMessage(
      "Paste the code returned by Embedded Signup. Other fields are optional and help initial matching.",
    ),
    "whatsappEmbeddedSignupSessionVersion":
        MessageLookupByLibrary.simpleMessage("Session info version"),
    "whatsappEmbeddedSignupState": MessageLookupByLibrary.simpleMessage(
      "Anti-CSRF state",
    ),
    "whatsappEmbeddedSignupStateInvalid": MessageLookupByLibrary.simpleMessage(
      "Unable to start the secure Meta session. Try again.",
    ),
    "whatsappEmbeddedSignupSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "The WhatsApp number has been connected successfully. WhatsApp reminders can now be used when message sending is enabled.",
    ),
    "whatsappEmbeddedSignupSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "WhatsApp connection completed",
    ),
    "whatsappEmbeddedSignupSuccessWithMapping":
        MessageLookupByLibrary.simpleMessage(
          "The WhatsApp number has been connected successfully. The business locations have been linked to the number automatically. WhatsApp reminders can now be used when message sending is enabled.",
        ),
    "whatsappEmbeddedSignupTitle": MessageLookupByLibrary.simpleMessage(
      "Complete Meta onboarding",
    ),
    "whatsappFieldAccessToken": MessageLookupByLibrary.simpleMessage(
      "Access token",
    ),
    "whatsappFieldBookingId": MessageLookupByLibrary.simpleMessage(
      "Booking ID",
    ),
    "whatsappFieldClientId": MessageLookupByLibrary.simpleMessage("Client ID"),
    "whatsappFieldDefault": MessageLookupByLibrary.simpleMessage("Default"),
    "whatsappFieldDisplayPhoneNumber": MessageLookupByLibrary.simpleMessage(
      "WhatsApp number",
    ),
    "whatsappFieldLocation": MessageLookupByLibrary.simpleMessage("Location"),
    "whatsappFieldPhoneNumberId": MessageLookupByLibrary.simpleMessage(
      "Phone Number ID",
    ),
    "whatsappFieldRecipientPhone": MessageLookupByLibrary.simpleMessage(
      "Recipient phone",
    ),
    "whatsappFieldStatus": MessageLookupByLibrary.simpleMessage("Status"),
    "whatsappFieldTemplateName": MessageLookupByLibrary.simpleMessage(
      "Template name",
    ),
    "whatsappFieldTemplateVariables": MessageLookupByLibrary.simpleMessage(
      "Template variables (JSON)",
    ),
    "whatsappFieldWabaId": MessageLookupByLibrary.simpleMessage("WABA ID"),
    "whatsappForgetLocalConfigAction": MessageLookupByLibrary.simpleMessage(
      "Disconnect from Meta",
    ),
    "whatsappForgetLocalConfigMessage": MessageLookupByLibrary.simpleMessage(
      "The management system will stop using this WhatsApp configuration and will cancel queued sends.\n\nTo fully revoke the permissions granted to the management system, complete the disconnection in Meta Business as well.",
    ),
    "whatsappForgetLocalConfigTitle": MessageLookupByLibrary.simpleMessage(
      "Disconnect from Meta?",
    ),
    "whatsappGoLiveCheck": MessageLookupByLibrary.simpleMessage(
      "Go-live check",
    ),
    "whatsappGoLiveCheckBusiness": MessageLookupByLibrary.simpleMessage(
      "Go-live check business",
    ),
    "whatsappGoLiveCheckLocation": MessageLookupByLibrary.simpleMessage(
      "Go-live check location",
    ),
    "whatsappGoLiveHint": MessageLookupByLibrary.simpleMessage(
      "Run checks to verify if this business is ready for production go-live.",
    ),
    "whatsappGoLiveNotReady": MessageLookupByLibrary.simpleMessage(
      "Configuration is incomplete",
    ),
    "whatsappGoLiveReady": MessageLookupByLibrary.simpleMessage(
      "Configuration ready for go-live",
    ),
    "whatsappGoLiveScopeBusiness": MessageLookupByLibrary.simpleMessage(
      "Scope: business",
    ),
    "whatsappGuideAfterConnectionApprovalRequired":
        MessageLookupByLibrary.simpleMessage(
          "Automatic message sending can start only when the settings and template are approved and active.",
        ),
    "whatsappGuideAfterConnectionConfigSaved": MessageLookupByLibrary.simpleMessage(
      "The management system saves the WhatsApp configuration connected to your business.",
    ),
    "whatsappGuideAfterConnectionTitle": MessageLookupByLibrary.simpleMessage(
      "What happens after the connection",
    ),
    "whatsappGuideCodeImportant": MessageLookupByLibrary.simpleMessage(
      "Important: without entering the verification code in the admin panel, WhatsApp connection will not be activated.",
    ),
    "whatsappGuideIntro": MessageLookupByLibrary.simpleMessage(
      "To connect WhatsApp to the management system, you will be redirected to Meta\'s secure setup flow. During the process you can select or create your business Meta account, connect a WhatsApp Business account, and verify the phone number used for automatic messages.",
    ),
    "whatsappGuideManageNumberCurrent": MessageLookupByLibrary.simpleMessage(
      "If you want to use your current number: if it is already used on WhatsApp or the WhatsApp Business App, you may need to disconnect or migrate it by following Meta\'s instructions before connecting it.",
    ),
    "whatsappGuideManageNumberLandline": MessageLookupByLibrary.simpleMessage(
      "If you use a landline: choose phone call verification when supported by Meta. You will receive a call to the business landline with the code to enter.",
    ),
    "whatsappGuideManageNumberNewSim": MessageLookupByLibrary.simpleMessage(
      "If you use a new SIM: insert it into a phone only to receive the initial verification code. Once setup is confirmed, you can remove the SIM; the system will keep working even with the phone turned off.",
    ),
    "whatsappGuideManageNumberTitle": MessageLookupByLibrary.simpleMessage(
      "How to manage the phone number",
    ),
    "whatsappGuideNeedDedicatedNumber": MessageLookupByLibrary.simpleMessage(
      "A phone number to connect to WhatsApp Business: it can be a new SIM or a landline. The number must not have an active WhatsApp account during the connection process.",
    ),
    "whatsappGuideNeedMetaAccount": MessageLookupByLibrary.simpleMessage(
      "A personal Facebook/Meta account: it must belong to the person who manages the business or can administer its Business Manager.",
    ),
    "whatsappGuideNeedMetaBusinessAccount": MessageLookupByLibrary.simpleMessage(
      "A Meta Business Account for the business: if it does not exist yet, Meta may guide you through creating one during the setup flow.",
    ),
    "whatsappGuideNeedPaymentCard": MessageLookupByLibrary.simpleMessage(
      "A Meta payment method, if requested: payment details are entered only in Meta\'s secure window and are never visible to the management system.",
    ),
    "whatsappGuideNeedVat": MessageLookupByLibrary.simpleMessage(
      "Your VAT number: by adding it, you can avoid Meta charging Irish VAT on the invoice. You should still consult your accountant, since you will receive the invoice from Meta, which is effectively a foreign invoice.",
    ),
    "whatsappGuideNeedWebsiteNotRequired": MessageLookupByLibrary.simpleMessage(
      "A website is not mandatory: if Meta asks for an online reference, you can use the business details or the public booking link provided by the management system, if available.",
    ),
    "whatsappGuideNeedsTitle": MessageLookupByLibrary.simpleMessage(
      "What you need to get started",
    ),
    "whatsappGuideNoBusinessAccountBody": MessageLookupByLibrary.simpleMessage(
      "No problem: during the setup flow Meta may allow you to create one. Use a real Facebook/Meta profile belonging to the person who manages the business.",
    ),
    "whatsappGuideNoBusinessAccountTitle": MessageLookupByLibrary.simpleMessage(
      "Do not have a Meta Business Account yet?",
    ),
    "whatsappGuidePaymentsBody": MessageLookupByLibrary.simpleMessage(
      "Any WhatsApp message costs are managed directly by Meta according to its pricing. Payment details are entered only in Meta\'s secure screens: the management system never sees card number, expiry date, or CVV.",
    ),
    "whatsappGuidePaymentsTitle": MessageLookupByLibrary.simpleMessage(
      "Payments and security",
    ),
    "whatsappGuideProfessionalBody": MessageLookupByLibrary.simpleMessage(
      "A regular WhatsApp account cannot be used to send automatic messages from the platform. Meta therefore requires a number connected to the WhatsApp Business Platform. You can use a dedicated number, a new SIM, or a business landline, as long as it can be verified and does not have an active WhatsApp account during the connection process.",
    ),
    "whatsappGuideProfessionalTitle": MessageLookupByLibrary.simpleMessage(
      "Why do you need a professional number?",
    ),
    "whatsappGuidePublicBookingLinkBody": MessageLookupByLibrary.simpleMessage(
      "You can use this link as the business online reference during the Meta setup flow.",
    ),
    "whatsappGuidePublicBookingLinkCopiedAction":
        MessageLookupByLibrary.simpleMessage("Link copied"),
    "whatsappGuidePublicBookingLinkCopyAction":
        MessageLookupByLibrary.simpleMessage("Copy link"),
    "whatsappGuidePublicBookingLinkTitle": MessageLookupByLibrary.simpleMessage(
      "Public booking link",
    ),
    "whatsappGuideStep1": MessageLookupByLibrary.simpleMessage(
      "Click \"Connect with Meta\".",
    ),
    "whatsappGuideStep2": MessageLookupByLibrary.simpleMessage(
      "Sign in with your personal Facebook/Meta account, meaning the account of the person who administers the business.",
    ),
    "whatsappGuideStep3": MessageLookupByLibrary.simpleMessage(
      "Select your business Meta Business Account or create a new one when Meta offers it.",
    ),
    "whatsappGuideStep4": MessageLookupByLibrary.simpleMessage(
      "Create or connect the WhatsApp Business account and choose the phone number to use.",
    ),
    "whatsappGuideStep5": MessageLookupByLibrary.simpleMessage(
      "Verify the phone number by SMS or phone call when requested by Meta.",
    ),
    "whatsappGuideStep6": MessageLookupByLibrary.simpleMessage(
      "Confirm the required permissions so the management system can send automatic messages.",
    ),
    "whatsappGuideStepsTitle": MessageLookupByLibrary.simpleMessage(
      "Steps to follow",
    ),
    "whatsappGuideTipBody": MessageLookupByLibrary.simpleMessage(
      "If you use a dedicated SIM, remember to keep it active according to your operator\'s terms. Also keep any Meta payment methods updated; otherwise Meta may suspend the service.",
    ),
    "whatsappGuideTipTitle": MessageLookupByLibrary.simpleMessage(
      "A small tip",
    ),
    "whatsappGuideTitle": MessageLookupByLibrary.simpleMessage(
      "Guide to activating WhatsApp Business",
    ),
    "whatsappInvalidJson": MessageLookupByLibrary.simpleMessage(
      "Template variables JSON is invalid.",
    ),
    "whatsappLastUpdate": MessageLookupByLibrary.simpleMessage("Last update"),
    "whatsappLocationMappingTitle": MessageLookupByLibrary.simpleMessage(
      "Location to number mapping",
    ),
    "whatsappLocationOverridesTitle": MessageLookupByLibrary.simpleMessage(
      "Location overrides",
    ),
    "whatsappMessagingActiveMessage": MessageLookupByLibrary.simpleMessage(
      "WhatsApp messaging is active for this business. Automatic messages can be sent when WhatsApp notifications are enabled.",
    ),
    "whatsappMessagingActiveTitle": MessageLookupByLibrary.simpleMessage(
      "WhatsApp messaging active",
    ),
    "whatsappNoConfigs": MessageLookupByLibrary.simpleMessage(
      "No configurations found.",
    ),
    "whatsappNoLocationBannerMessage": MessageLookupByLibrary.simpleMessage(
      "To use WhatsApp, create at least one active location first.",
    ),
    "whatsappNoLocationBannerTitle": MessageLookupByLibrary.simpleMessage(
      "No active locations",
    ),
    "whatsappNoLocations": MessageLookupByLibrary.simpleMessage(
      "No active locations available.",
    ),
    "whatsappNotEnabledForBusiness": MessageLookupByLibrary.simpleMessage(
      "WhatsApp is not enabled for this business yet.",
    ),
    "whatsappOutboxDelivered": MessageLookupByLibrary.simpleMessage(
      "Delivered",
    ),
    "whatsappOutboxEmpty": MessageLookupByLibrary.simpleMessage(
      "No messages in outbox.",
    ),
    "whatsappOutboxRead": MessageLookupByLibrary.simpleMessage("Read"),
    "whatsappOutboxTitle": MessageLookupByLibrary.simpleMessage(
      "WhatsApp outbox",
    ),
    "whatsappPanelSubtitle": MessageLookupByLibrary.simpleMessage(
      "Manage numbers, location mappings, test sends, and outbox monitoring",
    ),
    "whatsappPanelTitle": MessageLookupByLibrary.simpleMessage(
      "WhatsApp integration",
    ),
    "whatsappQueueAndSendTest": MessageLookupByLibrary.simpleMessage(
      "Queue and send",
    ),
    "whatsappQueueTest": MessageLookupByLibrary.simpleMessage("Queue test"),
    "whatsappQueuedAndSent": MessageLookupByLibrary.simpleMessage(
      "Message queued and sent.",
    ),
    "whatsappQueuedOnly": MessageLookupByLibrary.simpleMessage(
      "Message queued successfully.",
    ),
    "whatsappReconnectMeta": MessageLookupByLibrary.simpleMessage(
      "Reconnect with Meta",
    ),
    "whatsappRefresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "whatsappRetryNow": MessageLookupByLibrary.simpleMessage("Retry"),
    "whatsappRunWorker": MessageLookupByLibrary.simpleMessage("Run worker"),
    "whatsappSavedSuccessMessage": MessageLookupByLibrary.simpleMessage(
      "WhatsApp changes were saved successfully.",
    ),
    "whatsappSavedSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "WhatsApp updated",
    ),
    "whatsappSelectBusinessHint": MessageLookupByLibrary.simpleMessage(
      "Select one business to manage WhatsApp integration.",
    ),
    "whatsappSendNow": MessageLookupByLibrary.simpleMessage("Send now"),
    "whatsappSingleLocationMappingHint": MessageLookupByLibrary.simpleMessage(
      "Only one active location: mapping is not required.",
    ),
    "whatsappStatsConfigs": MessageLookupByLibrary.simpleMessage(
      "Configurations",
    ),
    "whatsappStatsFailed": MessageLookupByLibrary.simpleMessage(
      "Failed messages",
    ),
    "whatsappStatsMappings": MessageLookupByLibrary.simpleMessage(
      "Location mappings",
    ),
    "whatsappStatsQueued": MessageLookupByLibrary.simpleMessage(
      "Queued messages",
    ),
    "whatsappStatusActive": MessageLookupByLibrary.simpleMessage("Active"),
    "whatsappStatusError": MessageLookupByLibrary.simpleMessage("Error"),
    "whatsappStatusInactive": MessageLookupByLibrary.simpleMessage("Inactive"),
    "whatsappStatusPending": MessageLookupByLibrary.simpleMessage("Pending"),
    "whatsappSuperadminMustEnable": MessageLookupByLibrary.simpleMessage(
      "Contact support to enable WhatsApp for this business.",
    ),
    "whatsappTabTitle": MessageLookupByLibrary.simpleMessage("WhatsApp"),
    "whatsappTechnicalValueCopiedMessage": MessageLookupByLibrary.simpleMessage(
      "The technical value has been copied to the clipboard.",
    ),
    "whatsappTechnicalValueCopiedTitle": MessageLookupByLibrary.simpleMessage(
      "Value copied",
    ),
    "whatsappTemplateAddAction": MessageLookupByLibrary.simpleMessage(
      "New template",
    ),
    "whatsappTemplateAssignmentsSectionTitle":
        MessageLookupByLibrary.simpleMessage("Template assignments"),
    "whatsappTemplateAutoSubmitEnabled": MessageLookupByLibrary.simpleMessage(
      "Automatically submit the template to Meta",
    ),
    "whatsappTemplateAutoSubmitHint": MessageLookupByLibrary.simpleMessage(
      "After Embedded Signup the core submits the reminder template creation request for this configuration.",
    ),
    "whatsappTemplateBodyPreviewLabel": MessageLookupByLibrary.simpleMessage(
      "Body preview",
    ),
    "whatsappTemplateBusinessBadge": MessageLookupByLibrary.simpleMessage(
      "Business",
    ),
    "whatsappTemplateCategoryAuthentication":
        MessageLookupByLibrary.simpleMessage("Authentication"),
    "whatsappTemplateCategoryMarketing": MessageLookupByLibrary.simpleMessage(
      "Marketing",
    ),
    "whatsappTemplateCategoryService": MessageLookupByLibrary.simpleMessage(
      "Service",
    ),
    "whatsappTemplateCategoryUtility": MessageLookupByLibrary.simpleMessage(
      "Utility",
    ),
    "whatsappTemplateCreateTitle": MessageLookupByLibrary.simpleMessage(
      "New WhatsApp template",
    ),
    "whatsappTemplateDefaultCategory": MessageLookupByLibrary.simpleMessage(
      "Default template category",
    ),
    "whatsappTemplateDefaultLanguage": MessageLookupByLibrary.simpleMessage(
      "Default template language",
    ),
    "whatsappTemplateDefaultsHint": MessageLookupByLibrary.simpleMessage(
      "These options only apply to the automatic template request for this WhatsApp configuration.",
    ),
    "whatsappTemplateEditTitle": MessageLookupByLibrary.simpleMessage(
      "Edit WhatsApp template",
    ),
    "whatsappTemplateGlobalBadge": MessageLookupByLibrary.simpleMessage(
      "Global",
    ),
    "whatsappTemplateGlobalHelper": MessageLookupByLibrary.simpleMessage(
      "Makes the template available as a fallback for every business.",
    ),
    "whatsappTemplateGlobalLabel": MessageLookupByLibrary.simpleMessage(
      "Global template",
    ),
    "whatsappTemplateLanguageLabel": MessageLookupByLibrary.simpleMessage(
      "Language",
    ),
    "whatsappTemplateMessageTypeLabel": MessageLookupByLibrary.simpleMessage(
      "Message type",
    ),
    "whatsappTemplateSubmitAction": MessageLookupByLibrary.simpleMessage(
      "Submit template to Meta",
    ),
    "whatsappTemplateSubmitErrorMessage": MessageLookupByLibrary.simpleMessage(
      "Unable to submit the default template to Meta.",
    ),
    "whatsappTemplateSubmitErrorTitle": MessageLookupByLibrary.simpleMessage(
      "Template submission failed",
    ),
    "whatsappTemplateSubmitReason": MessageLookupByLibrary.simpleMessage(
      "Reason",
    ),
    "whatsappTemplateSubmitStatus": MessageLookupByLibrary.simpleMessage(
      "Status",
    ),
    "whatsappTemplateSubmitSuccessMessage":
        MessageLookupByLibrary.simpleMessage(
          "The default template request has been submitted to Meta.",
        ),
    "whatsappTemplateSubmitSuccessTitle": MessageLookupByLibrary.simpleMessage(
      "Template request submitted",
    ),
    "whatsappTemplateSubmitTemplate": MessageLookupByLibrary.simpleMessage(
      "Template",
    ),
    "whatsappTemplatesEmpty": MessageLookupByLibrary.simpleMessage(
      "No templates configured.",
    ),
    "whatsappTemplatesSectionTitle": MessageLookupByLibrary.simpleMessage(
      "Available templates",
    ),
    "whatsappTestSendTitle": MessageLookupByLibrary.simpleMessage(
      "Template test send",
    ),
    "whatsappUnassigned": MessageLookupByLibrary.simpleMessage("Unassigned"),
    "whatsappValidationRequired": MessageLookupByLibrary.simpleMessage(
      "Fill in all required fields.",
    ),
    "whatsappWorkerCompleted": MessageLookupByLibrary.simpleMessage(
      "Outbox worker completed successfully.",
    ),
  };
}
