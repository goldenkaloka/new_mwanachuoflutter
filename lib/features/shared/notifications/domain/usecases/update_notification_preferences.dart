import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/notifications/domain/repositories/notification_repository.dart';

/// Use case for updating notification preferences
class UpdateNotificationPreferences {
  final NotificationRepository repository;

  UpdateNotificationPreferences(this.repository);

  Future<Either<Failure, void>> call({
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
  }) async {
    return await repository.updateNotificationPreferences(
      pushEnabled: pushEnabled,
      messagesEnabled: messagesEnabled,
      reviewsEnabled: reviewsEnabled,
      listingsEnabled: listingsEnabled,
      promotionsEnabled: promotionsEnabled,
      sellerRequestsEnabled: sellerRequestsEnabled,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      badgeEnabled: badgeEnabled,
      inAppBannerEnabled: inAppBannerEnabled,
      groupNotifications: groupNotifications,
      groupByCategory: groupByCategory,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
    );
  }
}

