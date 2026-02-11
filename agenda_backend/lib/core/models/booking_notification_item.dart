import 'package:flutter/material.dart';

import '/core/l10n/l10_extension.dart';

class BookingNotificationItem {
  final int id;
  final int businessId;
  final int? bookingId;
  final int? locationId;
  final String? locationName;
  final String? clientName;
  final String channel;
  final String status;
  final String? recipientEmail;
  final String? recipientName;
  final String? subject;
  final String? errorMessage;
  final int attempts;
  final int maxAttempts;
  final DateTime? createdAt;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? failedAt;
  final DateTime? firstStartTime;
  final DateTime? lastEndTime;

  const BookingNotificationItem({
    required this.id,
    required this.businessId,
    this.bookingId,
    this.locationId,
    this.locationName,
    this.clientName,
    required this.channel,
    required this.status,
    this.recipientEmail,
    this.recipientName,
    this.subject,
    this.errorMessage,
    this.attempts = 0,
    this.maxAttempts = 0,
    this.createdAt,
    this.scheduledAt,
    this.sentAt,
    this.failedAt,
    this.firstStartTime,
    this.lastEndTime,
  });

  Color get statusColor {
    switch (status) {
      case 'sent':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String statusLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (status) {
      case 'pending':
        return l10n.bookingNotificationsStatusPending;
      case 'processing':
        return l10n.bookingNotificationsStatusProcessing;
      case 'sent':
        return l10n.bookingNotificationsStatusSent;
      case 'failed':
        return l10n.bookingNotificationsStatusFailed;
      default:
        return status;
    }
  }

  String channelLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (channel) {
      case 'booking_confirmed':
        return l10n.bookingNotificationsChannelConfirmed;
      case 'booking_rescheduled':
        return l10n.bookingNotificationsChannelRescheduled;
      case 'booking_cancelled':
        return l10n.bookingNotificationsChannelCancelled;
      case 'booking_reminder':
        return l10n.bookingNotificationsChannelReminder;
      default:
        return channel;
    }
  }

  factory BookingNotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str);
    }

    return BookingNotificationItem(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      bookingId: json['booking_id'] as int?,
      locationId: json['location_id'] as int?,
      locationName: json['location_name'] as String?,
      clientName: json['client_name'] as String?,
      channel: json['channel'] as String? ?? '',
      status: json['status'] as String? ?? '',
      recipientEmail: json['recipient_email'] as String?,
      recipientName: json['recipient_name'] as String?,
      subject: json['subject'] as String?,
      errorMessage: json['error_message'] as String?,
      attempts: json['attempts'] as int? ?? 0,
      maxAttempts: json['max_attempts'] as int? ?? 0,
      createdAt: parseDate(json['created_at']),
      scheduledAt: parseDate(json['scheduled_at']),
      sentAt: parseDate(json['sent_at']),
      failedAt: parseDate(json['failed_at']),
      firstStartTime: parseDate(json['first_start_time']),
      lastEndTime: parseDate(json['last_end_time']),
    );
  }
}

class BookingNotificationsResult {
  final List<BookingNotificationItem> notifications;
  final int total;
  final int limit;
  final int offset;

  const BookingNotificationsResult({
    required this.notifications,
    required this.total,
    required this.limit,
    required this.offset,
  });

  bool get hasMore => offset + notifications.length < total;

  factory BookingNotificationsResult.fromJson(Map<String, dynamic> json) {
    final list = json['notifications'] as List<dynamic>? ?? [];
    return BookingNotificationsResult(
      notifications: list
          .map(
            (e) => BookingNotificationItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
    );
  }
}
