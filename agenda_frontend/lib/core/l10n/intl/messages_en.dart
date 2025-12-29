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

  static String m0(id) => "Booking code: ${id}";

  static String m1(date) => "First available: ${date}";

  static String m2(hours) => "${hours} hour";

  static String m3(hours, minutes) => "${hours} hour ${minutes} min";

  static String m4(minutes) => "${minutes} min";

  static String m5(minutes) => "${minutes} min";

  static String m6(path) => "Page not found: ${path}";

  static String m7(days) =>
      "${Intl.plural(days, one: 'Modifiable until tomorrow', other: 'Modifiable for ${days} days')}";

  static String m8(hours) =>
      "${Intl.plural(hours, one: 'Modifiable for 1 hour', other: 'Modifiable for ${hours} hours')}";

  static String m9(minutes) =>
      "${Intl.plural(minutes, one: 'Modifiable for 1 minute', other: 'Modifiable for ${minutes} minutes')}";

  static String m10(price) => "€${price}";

  static String m11(duration) => "${duration} min";

  static String m12(price) => "from ${price}";

  static String m13(count) =>
      "${Intl.plural(count, zero: 'No service selected', one: '1 service selected', other: '${count} services selected')}";

  static String m14(total) => "Total: ${total}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "actionBack": MessageLookupByLibrary.simpleMessage("Back"),
    "actionCancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "actionClose": MessageLookupByLibrary.simpleMessage("Close"),
    "actionConfirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "actionLogin": MessageLookupByLibrary.simpleMessage("Login"),
    "actionLogout": MessageLookupByLibrary.simpleMessage("Logout"),
    "actionNext": MessageLookupByLibrary.simpleMessage("Next"),
    "actionRegister": MessageLookupByLibrary.simpleMessage("Register"),
    "actionRetry": MessageLookupByLibrary.simpleMessage("Retry"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Book Online"),
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
    "authFirstName": MessageLookupByLibrary.simpleMessage("First name"),
    "authForgotPassword": MessageLookupByLibrary.simpleMessage(
      "Forgot password?",
    ),
    "authHaveAccount": MessageLookupByLibrary.simpleMessage(
      "Already have an account?",
    ),
    "authInvalidEmail": MessageLookupByLibrary.simpleMessage("Invalid email"),
    "authInvalidPassword": MessageLookupByLibrary.simpleMessage(
      "Password too short (min. 6 characters)",
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
    "authPhone": MessageLookupByLibrary.simpleMessage("Phone"),
    "authRegisterFailed": MessageLookupByLibrary.simpleMessage(
      "Registration failed",
    ),
    "authRegisterSuccess": MessageLookupByLibrary.simpleMessage(
      "Registration completed",
    ),
    "authRegisterTitle": MessageLookupByLibrary.simpleMessage(
      "Create a new account",
    ),
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
    "bookingCancelFailed": MessageLookupByLibrary.simpleMessage(
      "Error cancelling booking",
    ),
    "bookingCancelled": MessageLookupByLibrary.simpleMessage(
      "Booking cancelled successfully",
    ),
    "bookingRescheduled": MessageLookupByLibrary.simpleMessage(
      "Booking rescheduled successfully",
    ),
    "bookingStepDateTime": MessageLookupByLibrary.simpleMessage("Date & Time"),
    "bookingStepServices": MessageLookupByLibrary.simpleMessage("Services"),
    "bookingStepStaff": MessageLookupByLibrary.simpleMessage("Staff"),
    "bookingStepSummary": MessageLookupByLibrary.simpleMessage("Summary"),
    "bookingTitle": MessageLookupByLibrary.simpleMessage("Book appointment"),
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
    "confirmReschedule": MessageLookupByLibrary.simpleMessage(
      "Confirm reschedule",
    ),
    "confirmationBookingId": m0,
    "confirmationGoHome": MessageLookupByLibrary.simpleMessage("Go to home"),
    "confirmationNewBooking": MessageLookupByLibrary.simpleMessage(
      "New booking",
    ),
    "confirmationSubtitle": MessageLookupByLibrary.simpleMessage(
      "We\'ve sent you a confirmation email",
    ),
    "confirmationTitle": MessageLookupByLibrary.simpleMessage(
      "Booking confirmed!",
    ),
    "currentBooking": MessageLookupByLibrary.simpleMessage("Current booking"),
    "dateTimeAfternoon": MessageLookupByLibrary.simpleMessage("Afternoon"),
    "dateTimeEvening": MessageLookupByLibrary.simpleMessage("Evening"),
    "dateTimeFirstAvailable": m1,
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
    "durationHour": m2,
    "durationHourMinute": m3,
    "durationMinute": m4,
    "durationMinutes": m5,
    "errorBusinessNotFound": MessageLookupByLibrary.simpleMessage(
      "Business not found",
    ),
    "errorBusinessNotFoundSubtitle": MessageLookupByLibrary.simpleMessage(
      "The requested business does not exist or is not yet configured for online bookings.",
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
    "errorNotFound": m6,
    "errorServiceUnavailable": MessageLookupByLibrary.simpleMessage(
      "Service temporarily unavailable",
    ),
    "errorServiceUnavailableSubtitle": MessageLookupByLibrary.simpleMessage(
      "We are working to fix the issue. Please try again in a few minutes.",
    ),
    "errorTitle": MessageLookupByLibrary.simpleMessage("Error"),
    "modifiable": MessageLookupByLibrary.simpleMessage("Modifiable"),
    "modifiableUntilDays": m7,
    "modifiableUntilHours": m8,
    "modifiableUntilMinutes": m9,
    "modify": MessageLookupByLibrary.simpleMessage("Modify"),
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
    "noPastBookings": MessageLookupByLibrary.simpleMessage(
      "You have no past bookings",
    ),
    "noUpcomingBookings": MessageLookupByLibrary.simpleMessage(
      "You have no upcoming bookings",
    ),
    "notModifiable": MessageLookupByLibrary.simpleMessage("Not modifiable"),
    "pastBookings": MessageLookupByLibrary.simpleMessage("Past"),
    "priceFormat": m10,
    "rescheduleBookingTitle": MessageLookupByLibrary.simpleMessage(
      "Reschedule booking",
    ),
    "selectDate": MessageLookupByLibrary.simpleMessage("Select date"),
    "selectNewDate": MessageLookupByLibrary.simpleMessage("Select new date"),
    "selectNewTime": MessageLookupByLibrary.simpleMessage("Select new time"),
    "servicesDuration": m11,
    "servicesEmpty": MessageLookupByLibrary.simpleMessage(
      "No services available at the moment",
    ),
    "servicesEmptySubtitle": MessageLookupByLibrary.simpleMessage(
      "There are no services available for online booking at this business",
    ),
    "servicesFree": MessageLookupByLibrary.simpleMessage("Free"),
    "servicesPriceFrom": m12,
    "servicesSelected": m13,
    "servicesSubtitle": MessageLookupByLibrary.simpleMessage(
      "You can select one or more services",
    ),
    "servicesTitle": MessageLookupByLibrary.simpleMessage("Choose services"),
    "servicesTotal": m14,
    "staffAnyOperator": MessageLookupByLibrary.simpleMessage(
      "Any available staff",
    ),
    "staffAnyOperatorSubtitle": MessageLookupByLibrary.simpleMessage(
      "We\'ll assign you the first available staff member",
    ),
    "staffEmpty": MessageLookupByLibrary.simpleMessage(
      "No staff available at the moment",
    ),
    "staffSubtitle": MessageLookupByLibrary.simpleMessage(
      "Select who you want to be served by",
    ),
    "staffTitle": MessageLookupByLibrary.simpleMessage("Choose staff member"),
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
    "yes": MessageLookupByLibrary.simpleMessage("Yes"),
  };
}
