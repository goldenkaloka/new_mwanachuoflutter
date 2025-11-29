import 'package:equatable/equatable.dart';

/// Notification action entity for tracking user actions on notifications
class NotificationActionEntity extends Equatable {
  final String id;
  final String notificationId;
  final String userId;
  final String actionType; // 'reply', 'view', 'dismiss', 'snooze', 'mark_read'
  final String? actionLabel;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const NotificationActionEntity({
    required this.id,
    required this.notificationId,
    required this.userId,
    required this.actionType,
    this.actionLabel,
    this.actionUrl,
    this.metadata,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        notificationId,
        userId,
        actionType,
        actionLabel,
        actionUrl,
        metadata,
        createdAt,
      ];
}

