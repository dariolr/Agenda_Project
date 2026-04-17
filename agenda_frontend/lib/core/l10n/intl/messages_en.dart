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

  static String m0(message) => "Validation error: ${message}";

  static String m1(label) => "Choose ${label}";

  static String m2(locationLabel) =>
      "The selected ${locationLabel} is not available";

  static String m3(serviceLabel) =>
      "One or more selected ${serviceLabel} are not available";

  static String m4(staffLabel, serviceLabel) =>
      "The selected ${staffLabel} is not available for these ${serviceLabel}";

  static String m5(serviceLabel) => "Unable to load booking ${serviceLabel}";

  static String m6(staffLabel) =>
      "The selected ${staffLabel} is not available at this time";

  static String m7(fields) => "Changed fields: ${fields}";

  static String m8(type) => "Email sent of type: ${type}";

  static String m9(email) => "Recipient: ${email}";

  static String m10(dateTime) => "Sent at: ${dateTime}";

  static String m11(count) => "${count} spots available";

  static String m12(count) => "${count} spots";

  static String m13(id) => "Booking code: ${id}";

  static String m14(date) => "First available: ${date}";

  static String m15(hours) => "${hours} hour";

  static String m16(hours, minutes) => "${hours} hour ${minutes} min";

  static String m17(minutes) => "${minutes} min";

  static String m18(minutes) => "${minutes} min";

  static String m19(path) => "Page not found: ${path}";

  static String m20(label) => "${label} temporarily unavailable";

  static String m21(label) => "No ${label} available";

  static String m22(dateTime) => "Modifiable until ${dateTime}";

  static String m23(days) =>
      "${Intl.plural(days, one: 'Modifiable until tomorrow', other: 'Modifiable for ${days} days')}";

  static String m24(hours) =>
      "${Intl.plural(hours, one: 'Modifiable for 1 hour', other: 'Modifiable for ${hours} hours')}";

  static String m25(minutes) =>
      "${Intl.plural(minutes, one: 'Modifiable for 1 minute', other: 'Modifiable for ${minutes} minutes')}";

  static String m26(dateTime) =>
      "The deadline to modify or cancel expired on ${dateTime}.";

  static String m27(staffLabel, serviceLabel) =>
      "No ${staffLabel} can perform all selected ${serviceLabel}. Try selecting fewer or different ${serviceLabel}.";

  static String m28(price) => "€${price}";

  static String m29(id) => "Category ${id}";

  static String m30(duration) => "${duration} min";

  static String m31(label) => "No ${label} available at the moment";

  static String m32(label) =>
      "There are no ${label} available for online booking at this business";

  static String m33(price) => "from ${price}";

  static String m34(count) =>
      "${Intl.plural(count, zero: 'No service selected', one: '1 service selected', other: '${count} services selected')}";

  static String m35(count, label) => "${count} ${label} selected";

  static String m36(label) => "No ${label} selected";

  static String m37(label) => "1 ${label} selected";

  static String m38(label) => "You can select one or more ${label}";

  static String m39(total) => "Total: ${total}";

  static String m40(label) => "Any available ${label}";

  static String m41(label) => "We\'ll assign you the first available ${label}";

  static String m42(label) => "No ${label} available at the moment";

  static String m43(label) => "Select your preferred ${label}";

  static String m44(days) =>
      "${Intl.plural(days, one: 'Up to 1 day before', other: 'Up to ${days} days before')}";

  static String m45(hours) => "Up to ${hours} hours before";

  static String m46(label) => "Selected ${label}";

  static String m47(businessName) =>
      "To book at ${businessName}, you need to log in with an account registered here.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "actionBack": MessageLookupByLibrary.simpleMessage("Back"),
    "actionCancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "actionCancelBooking": MessageLookupByLibrary.simpleMessage("Cancel"),
    "actionClose": MessageLookupByLibrary.simpleMessage("Close"),
    "actionConfirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "actionDelete": MessageLookupByLibrary.simpleMessage("Delete"),
    "actionLogin": MessageLookupByLibrary.simpleMessage("Login"),
    "actionLogout": MessageLookupByLibrary.simpleMessage("Logout"),
    "actionNext": MessageLookupByLibrary.simpleMessage("Next"),
    "actionRegister": MessageLookupByLibrary.simpleMessage("Register"),
    "actionRetry": MessageLookupByLibrary.simpleMessage("Retry"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Book Online"),
    "authBusinessNotFound": MessageLookupByLibrary.simpleMessage(
      "Unable to load business information. Please try again.",
    ),
    "authChangePassword": MessageLookupByLibrary.simpleMessage(
      "Change password",
    ),
    "authChangePasswordError": MessageLookupByLibrary.simpleMessage(
      "Current password is incorrect",
    ),
    "authChangePasswordSuccess": MessageLookupByLibrary.simpleMessage(
      "Password changed successfully",
    ),
    "authChangePasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Change password",
    ),
    "authConfirmPassword": MessageLookupByLibrary.simpleMessage(
      "Confirm password",
    ),
    "authCurrentPassword": MessageLookupByLibrary.simpleMessage(
      "Current password",
    ),
    "authEmail": MessageLookupByLibrary.simpleMessage("Email"),
    "authEmailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
      "This email is already registered. Try logging in.",
    ),
    "authErrorAccountDisabled": MessageLookupByLibrary.simpleMessage(
      "Your account is disabled",
    ),
    "authErrorEmailAlreadyExists": MessageLookupByLibrary.simpleMessage(
      "This email is already registered. Try logging in.",
    ),
    "authErrorInvalidCredentials": MessageLookupByLibrary.simpleMessage(
      "Invalid email or password",
    ),
    "authErrorInvalidResetToken": MessageLookupByLibrary.simpleMessage(
      "Invalid password reset token",
    ),
    "authErrorResetTokenExpired": MessageLookupByLibrary.simpleMessage(
      "Password reset token has expired",
    ),
    "authErrorSessionRevoked": MessageLookupByLibrary.simpleMessage(
      "Your session has been revoked. Please log in again.",
    ),
    "authErrorTokenExpired": MessageLookupByLibrary.simpleMessage(
      "Your session has expired. Please log in again.",
    ),
    "authErrorTokenInvalid": MessageLookupByLibrary.simpleMessage(
      "Your session is not valid. Please log in again.",
    ),
    "authErrorWeakPassword": MessageLookupByLibrary.simpleMessage(
      "Password too weak. Please choose a stronger password.",
    ),
    "authFirstName": MessageLookupByLibrary.simpleMessage("First name"),
    "authForgotPassword": MessageLookupByLibrary.simpleMessage(
      "Forgot password?",
    ),
    "authHaveAccount": MessageLookupByLibrary.simpleMessage(
      "Already have an account?",
    ),
    "authInvalidEmail": MessageLookupByLibrary.simpleMessage("Invalid email"),
    "authInvalidPassword": MessageLookupByLibrary.simpleMessage(
      "Password must contain at least 8 characters, one uppercase, one lowercase and one number",
    ),
    "authInvalidPhone": MessageLookupByLibrary.simpleMessage(
      "Invalid phone number",
    ),
    "authLastName": MessageLookupByLibrary.simpleMessage("Last name"),
    "authLoginFailed": MessageLookupByLibrary.simpleMessage(
      "Invalid credentials",
    ),
    "authLoginSuccess": MessageLookupByLibrary.simpleMessage(
      "Login successful",
    ),
    "authLoginTitle": MessageLookupByLibrary.simpleMessage(
      "Login to your account",
    ),
    "authNetworkError": MessageLookupByLibrary.simpleMessage(
      "Unable to contact the server. Check your connection and try again shortly.",
    ),
    "authNewPassword": MessageLookupByLibrary.simpleMessage("New password"),
    "authNoAccount": MessageLookupByLibrary.simpleMessage(
      "Don\'t have an account?",
    ),
    "authPassword": MessageLookupByLibrary.simpleMessage("Password"),
    "authPasswordMismatch": MessageLookupByLibrary.simpleMessage(
      "Passwords don\'t match",
    ),
    "authPasswordRequirements": MessageLookupByLibrary.simpleMessage(
      "Password must contain: uppercase, lowercase, number",
    ),
    "authPasswordTooShort": MessageLookupByLibrary.simpleMessage(
      "Password too short (min. 8 characters)",
    ),
    "authPasswordValidationError": m0,
    "authPhone": MessageLookupByLibrary.simpleMessage("Phone"),
    "authRedirectFromBooking": MessageLookupByLibrary.simpleMessage(
      "To book an appointment, log in with your account or register if you don\'t have one yet.",
    ),
    "authRedirectFromMyBookings": MessageLookupByLibrary.simpleMessage(
      "To view your appointments, log in with your account or register if you don\'t have one yet.",
    ),
    "authRegisterFailed": MessageLookupByLibrary.simpleMessage(
      "Registration failed",
    ),
    "authRegisterSuccess": MessageLookupByLibrary.simpleMessage(
      "Registration completed",
    ),
    "authRegisterTitle": MessageLookupByLibrary.simpleMessage(
      "Create a new account",
    ),
    "authRememberMe": MessageLookupByLibrary.simpleMessage("Remember me"),
    "authRequiredField": MessageLookupByLibrary.simpleMessage("Required field"),
    "authResetPasswordConfirmError": MessageLookupByLibrary.simpleMessage(
      "Invalid or expired token",
    ),
    "authResetPasswordConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "Enter your new password",
    ),
    "authResetPasswordConfirmSuccess": MessageLookupByLibrary.simpleMessage(
      "Password reset successful!",
    ),
    "authResetPasswordConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Reset password",
    ),
    "authResetPasswordEmailNotFound": MessageLookupByLibrary.simpleMessage(
      "Email not found in our system. Please check the address or register.",
    ),
    "authResetPasswordError": MessageLookupByLibrary.simpleMessage(
      "Error sending email. Please try again.",
    ),
    "authResetPasswordMessage": MessageLookupByLibrary.simpleMessage(
      "Enter your email and we\'ll send you instructions to reset your password.",
    ),
    "authResetPasswordSend": MessageLookupByLibrary.simpleMessage("Send"),
    "authResetPasswordSuccess": MessageLookupByLibrary.simpleMessage(
      "Email sent! Check your inbox.",
    ),
    "authResetPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Reset password",
    ),
    "authWelcome": MessageLookupByLibrary.simpleMessage("Welcome"),
    "blockedCustomerContactMessage": MessageLookupByLibrary.simpleMessage(
      "For any appointment needs, please contact us. Thank you.",
    ),
    "bookingCancelFailed": MessageLookupByLibrary.simpleMessage(
      "Error cancelling booking",
    ),
    "bookingCancelled": MessageLookupByLibrary.simpleMessage(
      "Booking cancelled successfully",
    ),
    "bookingChooseCustomLabel": m1,
    "bookingErrorInvalidClient": MessageLookupByLibrary.simpleMessage(
      "The selected client is not valid",
    ),
    "bookingErrorInvalidLocation": MessageLookupByLibrary.simpleMessage(
      "The selected location is not available",
    ),
    "bookingErrorInvalidLocationCustom": m2,
    "bookingErrorInvalidService": MessageLookupByLibrary.simpleMessage(
      "One or more selected services are not available",
    ),
    "bookingErrorInvalidServiceCustom": m3,
    "bookingErrorInvalidStaff": MessageLookupByLibrary.simpleMessage(
      "The selected staff member is not available for these services",
    ),
    "bookingErrorInvalidStaffCustom": m4,
    "bookingErrorInvalidTime": MessageLookupByLibrary.simpleMessage(
      "The selected time is not valid",
    ),
    "bookingErrorMissingServices": MessageLookupByLibrary.simpleMessage(
      "Unable to load booking services",
    ),
    "bookingErrorMissingServicesCustom": m5,
    "bookingErrorNotFound": MessageLookupByLibrary.simpleMessage(
      "Booking not found",
    ),
    "bookingErrorNotModifiable": MessageLookupByLibrary.simpleMessage(
      "This booking cannot be modified",
    ),
    "bookingErrorOutsideWorkingHours": MessageLookupByLibrary.simpleMessage(
      "The selected time is outside working hours",
    ),
    "bookingErrorServer": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again",
    ),
    "bookingErrorSlotConflict": MessageLookupByLibrary.simpleMessage(
      "The selected time slot is no longer available",
    ),
    "bookingErrorStaffUnavailable": MessageLookupByLibrary.simpleMessage(
      "The selected staff member is not available at this time",
    ),
    "bookingErrorStaffUnavailableCustom": m6,
    "bookingErrorUnauthorized": MessageLookupByLibrary.simpleMessage(
      "You are not authorized to complete this action",
    ),
    "bookingErrorValidation": MessageLookupByLibrary.simpleMessage(
      "Please check the entered data",
    ),
    "bookingHistoryActorCustomer": MessageLookupByLibrary.simpleMessage(
      "Customer",
    ),
    "bookingHistoryActorStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "bookingHistoryActorSystem": MessageLookupByLibrary.simpleMessage("System"),
    "bookingHistoryChangedFields": m7,
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
    "bookingHistoryEventNotificationSentTitle": m8,
    "bookingHistoryEventPriceChanged": MessageLookupByLibrary.simpleMessage(
      "Price changed",
    ),
    "bookingHistoryEventReplaced": MessageLookupByLibrary.simpleMessage(
      "Booking replaced",
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
    "bookingHistoryNotificationChannelCancelled":
        MessageLookupByLibrary.simpleMessage("Booking cancellation"),
    "bookingHistoryNotificationChannelConfirmed":
        MessageLookupByLibrary.simpleMessage("Booking confirmation"),
    "bookingHistoryNotificationChannelReminder":
        MessageLookupByLibrary.simpleMessage("Booking reminder"),
    "bookingHistoryNotificationChannelRescheduled":
        MessageLookupByLibrary.simpleMessage("Booking rescheduled"),
    "bookingHistoryNotificationRecipient": m9,
    "bookingHistoryNotificationSentAt": m10,
    "bookingHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "Booking history",
    ),
    "bookingRescheduled": MessageLookupByLibrary.simpleMessage(
      "Booking modified successfully",
    ),
    "bookingServiceSingularLabel": MessageLookupByLibrary.simpleMessage(
      "service",
    ),
    "bookingStepDateTime": MessageLookupByLibrary.simpleMessage("Date & Time"),
    "bookingStepLocation": MessageLookupByLibrary.simpleMessage("Location"),
    "bookingStepServices": MessageLookupByLibrary.simpleMessage("Services"),
    "bookingStepStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "bookingStepSummary": MessageLookupByLibrary.simpleMessage("Summary"),
    "bookingTitle": MessageLookupByLibrary.simpleMessage("Book appointment"),
    "bookingUpdatedTitle": MessageLookupByLibrary.simpleMessage(
      "Booking updated",
    ),
    "businessNotFound": MessageLookupByLibrary.simpleMessage(
      "Business not found",
    ),
    "businessNotFoundHint": MessageLookupByLibrary.simpleMessage(
      "Please check the URL or contact the business directly.",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancelBookingConfirm": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to cancel this booking?",
    ),
    "cancelBookingTitle": MessageLookupByLibrary.simpleMessage(
      "Cancel booking",
    ),
    "cancelledBadge": MessageLookupByLibrary.simpleMessage("CANCELLED"),
    "cancelledBookings": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "classBookingWaitlistedBadge": MessageLookupByLibrary.simpleMessage(
      "Waitlist",
    ),
    "classEventFull": MessageLookupByLibrary.simpleMessage("Full"),
    "classEventGroupLesson": MessageLookupByLibrary.simpleMessage(
      "Group class",
    ),
    "classEventSpotsAvailable": m11,
    "classEventSpotsLeft": m12,
    "classEventWaitlistLabel": MessageLookupByLibrary.simpleMessage("Waitlist"),
    "classEventWaitlistNotice": MessageLookupByLibrary.simpleMessage(
      "You\'ll be added to the waitlist",
    ),
    "confirmReschedule": MessageLookupByLibrary.simpleMessage(
      "Confirm changes",
    ),
    "confirmationBookingId": m13,
    "confirmationGoHome": MessageLookupByLibrary.simpleMessage("Go to home"),
    "confirmationNewBooking": MessageLookupByLibrary.simpleMessage(
      "New booking",
    ),
    "confirmationPostRegistrationMyBookingsHint":
        MessageLookupByLibrary.simpleMessage(
          "You will find your booking list in the top-right Profile section.",
        ),
    "confirmationSubtitle": MessageLookupByLibrary.simpleMessage(
      "We\'ve sent you a confirmation email",
    ),
    "confirmationTitle": MessageLookupByLibrary.simpleMessage(
      "Booking confirmed!",
    ),
    "confirmationWaitlistSubtitle": MessageLookupByLibrary.simpleMessage(
      "You\'ll be confirmed as soon as a spot opens up",
    ),
    "confirmationWaitlistTitle": MessageLookupByLibrary.simpleMessage(
      "You\'re on the waitlist!",
    ),
    "currentBooking": MessageLookupByLibrary.simpleMessage("Current booking"),
    "dateTimeAfternoon": MessageLookupByLibrary.simpleMessage("Afternoon"),
    "dateTimeEvening": MessageLookupByLibrary.simpleMessage("Evening"),
    "dateTimeFirstAvailable": m14,
    "dateTimeGoToFirst": MessageLookupByLibrary.simpleMessage(
      "Go to first available date",
    ),
    "dateTimeGoToNext": MessageLookupByLibrary.simpleMessage(
      "Go to next available date",
    ),
    "dateTimeMorning": MessageLookupByLibrary.simpleMessage("Morning"),
    "dateTimeNoSlots": MessageLookupByLibrary.simpleMessage(
      "No time slots available for this date",
    ),
    "dateTimeSelectDate": MessageLookupByLibrary.simpleMessage("Select a date"),
    "dateTimeSubtitle": MessageLookupByLibrary.simpleMessage(
      "Select when you want to book",
    ),
    "dateTimeTitle": MessageLookupByLibrary.simpleMessage(
      "Choose date and time",
    ),
    "durationHour": m15,
    "durationHourMinute": m16,
    "durationMinute": m17,
    "durationMinutes": m18,
    "environmentDemoBannerSubtitle": MessageLookupByLibrary.simpleMessage(
      "Data is reset periodically.",
    ),
    "environmentDemoBannerTitle": MessageLookupByLibrary.simpleMessage(
      "DEMO ENVIRONMENT",
    ),
    "errorBusinessNotActive": MessageLookupByLibrary.simpleMessage(
      "Business not active",
    ),
    "errorBusinessNotActiveSubtitle": MessageLookupByLibrary.simpleMessage(
      "This business is not yet configured for online bookings. Please contact the business directly.",
    ),
    "errorBusinessNotFound": MessageLookupByLibrary.simpleMessage(
      "Business not found",
    ),
    "errorBusinessNotFoundSubtitle": MessageLookupByLibrary.simpleMessage(
      "The requested business does not exist. Please check the URL or contact the business directly.",
    ),
    "errorConnectionTimeout": MessageLookupByLibrary.simpleMessage(
      "The connection is taking too long. Please try again.",
    ),
    "errorGeneric": MessageLookupByLibrary.simpleMessage("An error occurred"),
    "errorLoadingAvailability": MessageLookupByLibrary.simpleMessage(
      "Unable to load availability. Check your connection and try again.",
    ),
    "errorLoadingBookings": MessageLookupByLibrary.simpleMessage(
      "Error loading bookings",
    ),
    "errorLoadingServices": MessageLookupByLibrary.simpleMessage(
      "Unable to load services. Check your connection and try again.",
    ),
    "errorLoadingStaff": MessageLookupByLibrary.simpleMessage(
      "Unable to load staff. Check your connection and try again.",
    ),
    "errorLocationNotFound": MessageLookupByLibrary.simpleMessage(
      "Location not available",
    ),
    "errorLocationNotFoundSubtitle": MessageLookupByLibrary.simpleMessage(
      "The selected location is not active. Contact the business for more information.",
    ),
    "errorNoAvailability": MessageLookupByLibrary.simpleMessage(
      "No availability for the selected date",
    ),
    "errorNotFound": m19,
    "errorServiceUnavailable": MessageLookupByLibrary.simpleMessage(
      "Service temporarily unavailable",
    ),
    "errorServiceUnavailableCustom": m20,
    "errorServiceUnavailableSubtitle": MessageLookupByLibrary.simpleMessage(
      "We are working to fix the issue. Please try again in a few minutes.",
    ),
    "errorTitle": MessageLookupByLibrary.simpleMessage("Error"),
    "loadingAvailability": MessageLookupByLibrary.simpleMessage(
      "Loading availability...",
    ),
    "loadingGeneric": MessageLookupByLibrary.simpleMessage("Loading..."),
    "locationEmpty": MessageLookupByLibrary.simpleMessage(
      "No location available",
    ),
    "locationEmptyCustom": m21,
    "locationSubtitle": MessageLookupByLibrary.simpleMessage(
      "Select where you want to book",
    ),
    "locationTitle": MessageLookupByLibrary.simpleMessage("Choose location"),
    "modifiable": MessageLookupByLibrary.simpleMessage("Modifiable"),
    "modifiableUntilDateTime": m22,
    "modifiableUntilDays": m23,
    "modifiableUntilHours": m24,
    "modifiableUntilMinutes": m25,
    "modificationWindowExpired": MessageLookupByLibrary.simpleMessage(
      "The time window to modify or cancel this booking has expired.",
    ),
    "modificationWindowExpiredDateTime": m26,
    "modify": MessageLookupByLibrary.simpleMessage("Reschedule"),
    "modifyNotImplemented": MessageLookupByLibrary.simpleMessage(
      "Modify feature under development",
    ),
    "monthApril": MessageLookupByLibrary.simpleMessage("April"),
    "monthAugust": MessageLookupByLibrary.simpleMessage("August"),
    "monthDecember": MessageLookupByLibrary.simpleMessage("December"),
    "monthFebruary": MessageLookupByLibrary.simpleMessage("February"),
    "monthJanuary": MessageLookupByLibrary.simpleMessage("January"),
    "monthJuly": MessageLookupByLibrary.simpleMessage("July"),
    "monthJune": MessageLookupByLibrary.simpleMessage("June"),
    "monthMarch": MessageLookupByLibrary.simpleMessage("March"),
    "monthMay": MessageLookupByLibrary.simpleMessage("May"),
    "monthNovember": MessageLookupByLibrary.simpleMessage("November"),
    "monthOctober": MessageLookupByLibrary.simpleMessage("October"),
    "monthSeptember": MessageLookupByLibrary.simpleMessage("September"),
    "myBookings": MessageLookupByLibrary.simpleMessage("My bookings"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "noCancelledBookings": MessageLookupByLibrary.simpleMessage(
      "You have no cancelled bookings",
    ),
    "noPastBookings": MessageLookupByLibrary.simpleMessage(
      "You have no past bookings",
    ),
    "noStaffForAllServices": MessageLookupByLibrary.simpleMessage(
      "No staff member can perform all selected services. Try selecting fewer or different services.",
    ),
    "noStaffForAllServicesCustom": m27,
    "noUpcomingBookings": MessageLookupByLibrary.simpleMessage(
      "You have no upcoming bookings",
    ),
    "notModifiable": MessageLookupByLibrary.simpleMessage("Not modifiable"),
    "pastBookings": MessageLookupByLibrary.simpleMessage("Past"),
    "priceFormat": m28,
    "profileTitle": MessageLookupByLibrary.simpleMessage("Profile"),
    "rescheduleBookingTitle": MessageLookupByLibrary.simpleMessage(
      "Modify booking",
    ),
    "selectDate": MessageLookupByLibrary.simpleMessage("Select date"),
    "selectNewDate": MessageLookupByLibrary.simpleMessage("Select new date"),
    "selectNewTime": MessageLookupByLibrary.simpleMessage("Select new time"),
    "servicePackageExpandError": MessageLookupByLibrary.simpleMessage(
      "Unable to expand the selected package.",
    ),
    "servicePackageLabel": MessageLookupByLibrary.simpleMessage("Package"),
    "servicePackagesLoadError": MessageLookupByLibrary.simpleMessage(
      "Unable to load packages.",
    ),
    "servicePackagesLoading": MessageLookupByLibrary.simpleMessage(
      "Loading packages...",
    ),
    "servicePackagesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Or pick a ready-made package",
    ),
    "servicePackagesTitle": MessageLookupByLibrary.simpleMessage("Packages"),
    "servicesCategoryFallbackName": m29,
    "servicesDuration": m30,
    "servicesEmpty": MessageLookupByLibrary.simpleMessage(
      "No services available at the moment",
    ),
    "servicesEmptyCustom": m31,
    "servicesEmptySubtitle": MessageLookupByLibrary.simpleMessage(
      "There are no services available for online booking at this business",
    ),
    "servicesEmptySubtitleCustom": m32,
    "servicesFree": MessageLookupByLibrary.simpleMessage("Free"),
    "servicesPriceFrom": m33,
    "servicesSelected": m34,
    "servicesSelectedManyCustom": m35,
    "servicesSelectedNoneCustom": m36,
    "servicesSelectedOneCustom": m37,
    "servicesSubtitle": MessageLookupByLibrary.simpleMessage(
      "You can select one or more services",
    ),
    "servicesSubtitleCustom": m38,
    "servicesTitle": MessageLookupByLibrary.simpleMessage("Choose services"),
    "servicesTotal": m39,
    "sessionExpired": MessageLookupByLibrary.simpleMessage(
      "Session expired. Please log in again.",
    ),
    "slotNoLongerAvailable": MessageLookupByLibrary.simpleMessage(
      "The time slot is no longer available. Your original booking remains unchanged.",
    ),
    "staffAnyOperator": MessageLookupByLibrary.simpleMessage(
      "Any available staff",
    ),
    "staffAnyOperatorCustom": m40,
    "staffAnyOperatorSubtitle": MessageLookupByLibrary.simpleMessage(
      "We\'ll assign you the first available staff member",
    ),
    "staffAnyOperatorSubtitleCustom": m41,
    "staffEmpty": MessageLookupByLibrary.simpleMessage(
      "No staff available at the moment",
    ),
    "staffEmptyCustom": m42,
    "staffSubtitle": MessageLookupByLibrary.simpleMessage(
      "Select who you want to be served by",
    ),
    "staffSubtitleCustom": m43,
    "staffTitle": MessageLookupByLibrary.simpleMessage("Choose staff member"),
    "summaryCancellationPolicyAcceptLabel":
        MessageLookupByLibrary.simpleMessage(
          "I accept the modify/cancel policy",
        ),
    "summaryCancellationPolicyAcceptRequiredError":
        MessageLookupByLibrary.simpleMessage(
          "To confirm, you must accept the modify/cancel policy.",
        ),
    "summaryCancellationPolicyAlways": MessageLookupByLibrary.simpleMessage(
      "Always",
    ),
    "summaryCancellationPolicyDays": m44,
    "summaryCancellationPolicyHours": m45,
    "summaryCancellationPolicyNever": MessageLookupByLibrary.simpleMessage(
      "Never (not allowed after booking)",
    ),
    "summaryCancellationPolicyTitle": MessageLookupByLibrary.simpleMessage(
      "Modify/cancel policy",
    ),
    "summaryDateTime": MessageLookupByLibrary.simpleMessage("Date and time"),
    "summaryDuration": MessageLookupByLibrary.simpleMessage("Total duration"),
    "summaryNotes": MessageLookupByLibrary.simpleMessage("Notes (optional)"),
    "summaryNotesHint": MessageLookupByLibrary.simpleMessage(
      "Add any notes for the appointment...",
    ),
    "summaryOperator": MessageLookupByLibrary.simpleMessage("Staff member"),
    "summaryPrice": MessageLookupByLibrary.simpleMessage("Total price"),
    "summaryServices": MessageLookupByLibrary.simpleMessage(
      "Selected services",
    ),
    "summaryServicesCustom": m46,
    "summarySubtitle": MessageLookupByLibrary.simpleMessage(
      "Review the details before confirming",
    ),
    "summaryTitle": MessageLookupByLibrary.simpleMessage("Booking summary"),
    "upcomingBookings": MessageLookupByLibrary.simpleMessage("Upcoming"),
    "validationInvalidEmail": MessageLookupByLibrary.simpleMessage(
      "Invalid email",
    ),
    "validationInvalidPhone": MessageLookupByLibrary.simpleMessage(
      "Invalid phone",
    ),
    "validationRequired": MessageLookupByLibrary.simpleMessage(
      "Required field",
    ),
    "weekdayFri": MessageLookupByLibrary.simpleMessage("Fri"),
    "weekdayMon": MessageLookupByLibrary.simpleMessage("Mon"),
    "weekdaySat": MessageLookupByLibrary.simpleMessage("Sat"),
    "weekdaySun": MessageLookupByLibrary.simpleMessage("Sun"),
    "weekdayThu": MessageLookupByLibrary.simpleMessage("Thu"),
    "weekdayTue": MessageLookupByLibrary.simpleMessage("Tue"),
    "weekdayWed": MessageLookupByLibrary.simpleMessage("Wed"),
    "wrongBusinessAuthAction": MessageLookupByLibrary.simpleMessage(
      "Log out and sign in here",
    ),
    "wrongBusinessAuthMessage": m47,
    "wrongBusinessAuthTitle": MessageLookupByLibrary.simpleMessage(
      "Account linked to another business",
    ),
    "yes": MessageLookupByLibrary.simpleMessage("Yes"),
  };
}
