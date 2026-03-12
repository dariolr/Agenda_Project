import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

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
  final String? body;
  final String? errorMessage;
  final int attempts;
  final int maxAttempts;
  final DateTime? createdAt;
  final DateTime? scheduledAt;
  final DateTime? lastAttemptAt;
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
    this.body,
    this.errorMessage,
    this.attempts = 0,
    this.maxAttempts = 0,
    this.createdAt,
    this.scheduledAt,
    this.lastAttemptAt,
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

    String? firstNonEmpty(List<dynamic> values) {
      for (final value in values) {
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    bool looksLikeEmailBody(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return false;
      final lower = trimmed.toLowerCase();
      if (lower.contains('<html') ||
          lower.contains('<body') ||
          lower.contains('<table') ||
          lower.contains('<div') ||
          lower.contains('<br') ||
          lower.contains('<p')) {
        return true;
      }
      return trimmed.length > 120 && trimmed.contains('\n');
    }

    int bodyCandidateScore(String key, String value, String? subjectValue) {
      final k = key.toLowerCase();
      final v = value.trim().toLowerCase();
      final subject = (subjectValue ?? '').trim().toLowerCase();

      if (v.isEmpty) return -1;
      if (subject.isNotEmpty && v == subject) return -1;
      if (k.contains('error') ||
          k.contains('subject') ||
          k.contains('recipient') ||
          k.contains('status') ||
          k.contains('channel')) {
        return -1;
      }

      var score = 0;
      if (k.contains('html')) score += 120;
      if (k.contains('body')) score += 100;
      if (k.contains('content')) score += 70;
      if (k.contains('message')) {
        // Accept generic "message" only when it clearly looks like full content.
        if (looksLikeEmailBody(value) || value.trim().length > 220) {
          score += 40;
        } else {
          return -1;
        }
      }
      if (looksLikeEmailBody(value)) score += 80;
      score += value.length > 300 ? 20 : 0;
      return score;
    }

    String? deepBodyCandidate(Map<String, dynamic> data, String? subjectValue) {
      String? bestValue;
      var bestScore = -1;

      void visit(dynamic node, String path) {
        if (node is Map) {
          node.forEach((k, v) {
            visit(v, '$path.${k.toString()}');
          });
          return;
        }
        if (node is List) {
          for (var i = 0; i < node.length; i++) {
            visit(node[i], '$path[$i]');
          }
          return;
        }
        if (node is String) {
          final score = bodyCandidateScore(path, node, subjectValue);
          if (score > bestScore) {
            bestScore = score;
            bestValue = node;
          }
        }
      }

      visit(data, 'root');
      return bestScore > 0 ? bestValue : null;
    }

    final payload = json['payload'];
    Map<String, dynamic> payloadMap = const <String, dynamic>{};
    if (payload is Map) {
      payloadMap = Map<String, dynamic>.from(payload);
    } else if (payload is String && payload.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          payloadMap = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Keep empty payload map when invalid JSON.
      }
    }

    final payloadVariables = payloadMap['variables'];
    final variablesMap = payloadVariables is Map
        ? Map<String, dynamic>.from(payloadVariables)
        : const <String, dynamic>{};

    final resolvedBody = firstNonEmpty([
          json['body'],
          json['message_body'],
          json['text_body'],
          json['html_body'],
          json['email_body'],
          json['email_html'],
          json['mail_body'],
          json['mail_html'],
          json['rendered_body'],
          json['rendered_html'],
          json['html'],
          json['text'],
          json['content'],
          payloadMap['body'],
          payloadMap['message_body'],
          payloadMap['text_body'],
          payloadMap['html_body'],
          payloadMap['email_body'],
          payloadMap['email_html'],
          payloadMap['mail_body'],
          payloadMap['mail_html'],
          payloadMap['rendered_body'],
          payloadMap['rendered_html'],
          payloadMap['html'],
          payloadMap['text'],
          payloadMap['content'],
          variablesMap['body'],
          variablesMap['message_body'],
          variablesMap['text_body'],
          variablesMap['html_body'],
          variablesMap['email_body'],
          variablesMap['email_html'],
          variablesMap['mail_body'],
          variablesMap['mail_html'],
          variablesMap['rendered_body'],
          variablesMap['rendered_html'],
          variablesMap['html'],
          variablesMap['text'],
          variablesMap['content'],
        ]) ??
        deepBodyCandidate(json, json['subject'] as String?);

    if (kDebugMode && (resolvedBody == null || resolvedBody.trim().isEmpty)) {
      final keys = json.keys.join(', ');
      final payloadKeys = payloadMap.keys.join(', ');
      debugPrint(
        'BookingNotificationItem[id=${json['id']}] body missing. '
        'keys=[$keys] payloadKeys=[$payloadKeys]',
      );
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
      body: resolvedBody,
      errorMessage: json['error_message'] as String?,
      attempts: json['attempts'] as int? ?? 0,
      maxAttempts: json['max_attempts'] as int? ?? 0,
      createdAt: parseDate(json['created_at']),
      scheduledAt: parseDate(json['scheduled_at']),
      lastAttemptAt: parseDate(json['last_attempt_at']),
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
