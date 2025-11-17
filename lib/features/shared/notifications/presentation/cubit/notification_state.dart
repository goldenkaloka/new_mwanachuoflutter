import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_entity.dart';

/// Base class for all notification states
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class NotificationInitial extends NotificationState {}

/// Loading notifications
class NotificationsLoading extends NotificationState {}

/// Notifications loaded
class NotificationsLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final bool hasMore;

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [notifications, unreadCount, hasMore];
}

/// Loading unread count
class UnreadCountLoading extends NotificationState {}

/// Unread count loaded
class UnreadCountLoaded extends NotificationState {
  final int count;

  const UnreadCountLoaded({required this.count});

  @override
  List<Object?> get props => [count];
}

/// Marking as read
class MarkingAsRead extends NotificationState {}

/// Marked as read
class MarkedAsRead extends NotificationState {}

/// Marking all as read
class MarkingAllAsRead extends NotificationState {}

/// Marked all as read
class MarkedAllAsRead extends NotificationState {}

/// Deleting notification
class DeletingNotification extends NotificationState {}

/// Notification deleted
class NotificationDeleted extends NotificationState {}

/// Deleting all read
class DeletingAllRead extends NotificationState {}

/// All read deleted
class AllReadDeleted extends NotificationState {}

/// New notification received (real-time)
class NewNotificationReceived extends NotificationState {
  final NotificationEntity notification;

  const NewNotificationReceived({required this.notification});

  @override
  List<Object?> get props => [notification];
}

/// Error state
class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object?> get props => [message];
}

