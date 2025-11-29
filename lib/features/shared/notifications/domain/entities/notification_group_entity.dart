import 'package:equatable/equatable.dart';

/// Notification group entity for grouping related notifications
class NotificationGroupEntity extends Equatable {
  final String id;
  final String userId;
  final String groupKey; // e.g., "message_conversation_123"
  final String category; // 'message', 'review', 'order', etc.
  final String title;
  final String? summary;
  final int unreadCount;
  final String? latestNotificationId;
  final DateTime? latestNotificationAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationGroupEntity({
    required this.id,
    required this.userId,
    required this.groupKey,
    required this.category,
    required this.title,
    this.summary,
    this.unreadCount = 0,
    this.latestNotificationId,
    this.latestNotificationAt,
    required this.createdAt,
    required this.updatedAt,
  });

  NotificationGroupEntity copyWith({
    String? id,
    String? userId,
    String? groupKey,
    String? category,
    String? title,
    String? summary,
    int? unreadCount,
    String? latestNotificationId,
    DateTime? latestNotificationAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationGroupEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupKey: groupKey ?? this.groupKey,
      category: category ?? this.category,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      unreadCount: unreadCount ?? this.unreadCount,
      latestNotificationId: latestNotificationId ?? this.latestNotificationId,
      latestNotificationAt: latestNotificationAt ?? this.latestNotificationAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    groupKey,
    category,
    title,
    summary,
    unreadCount,
    latestNotificationId,
    latestNotificationAt,
    createdAt,
    updatedAt,
  ];
}
