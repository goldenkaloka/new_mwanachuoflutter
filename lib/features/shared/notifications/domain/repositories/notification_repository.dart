import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_entity.dart';
import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_preferences_entity.dart';

/// Notification repository interface
abstract class NotificationRepository {
  /// Get all notifications for the current user
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int? limit,
    int? offset,
    bool? unreadOnly,
  });

  /// Get unread notification count
  Future<Either<Failure, int>> getUnreadCount();

  /// Mark a notification as read
  Future<Either<Failure, void>> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<Either<Failure, void>> markAllAsRead();

  /// Delete a notification
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// Delete all read notifications
  Future<Either<Failure, void>> deleteAllRead();

  /// Subscribe to real-time notifications
  Stream<NotificationEntity> subscribeToNotifications();

  /// Register device token (OneSignal player ID)
  Future<Either<Failure, void>> registerDeviceToken({
    required String playerId,
    required String platform,
  });

  /// Unregister device token
  Future<Either<Failure, void>> unregisterDeviceToken(String playerId);

  /// Get notification preferences
  Future<Either<Failure, NotificationPreferencesEntity>> getNotificationPreferences();

  /// Update notification preferences
  Future<Either<Failure, void>> updateNotificationPreferences({
    bool? pushEnabled,
    bool? messagesEnabled,
    bool? reviewsEnabled,
    bool? listingsEnabled,
    bool? promotionsEnabled,
    bool? sellerRequestsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? badgeEnabled,
    bool? inAppBannerEnabled,
    bool? groupNotifications,
    bool? groupByCategory,
    DateTime? quietHoursStart,
    DateTime? quietHoursEnd,
  });
}

