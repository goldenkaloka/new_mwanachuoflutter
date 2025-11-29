import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/shared/notifications/data/datasources/notification_local_data_source.dart';
import 'package:mwanachuo/features/shared/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_entity.dart';
import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:mwanachuo/features/shared/notifications/domain/repositories/notification_repository.dart';

/// Implementation of NotificationRepository
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int? limit,
    int? offset,
    bool? unreadOnly,
  }) async {
    if (!await networkInfo.isConnected) {
      // Try to get from cache
      try {
        final cachedNotifications =
            await localDataSource.getCachedNotifications();
        return Right(cachedNotifications);
      } on CacheException {
        return Left(
          NetworkFailure('No internet connection and no cached data'),
        );
      }
    }

    try {
      final notifications = await remoteDataSource.getNotifications(
        limit: limit,
        offset: offset,
        unreadOnly: unreadOnly,
      );

      // Cache notifications
      await localDataSource.cacheNotifications(notifications);

      return Right(notifications);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get notifications: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    if (!await networkInfo.isConnected) {
      // Try to get from cache
      try {
        final cachedCount = await localDataSource.getCachedUnreadCount();
        return Right(cachedCount);
      } on CacheException {
        return Left(
          NetworkFailure('No internet connection and no cached data'),
        );
      }
    }

    try {
      final count = await remoteDataSource.getUnreadCount();

      // Cache count
      await localDataSource.cacheUnreadCount(count);

      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get unread count: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.markAsRead(notificationId);

      // Clear cache to force refresh
      await localDataSource.clearCache();

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to mark as read: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.markAllAsRead();

      // Clear cache to force refresh
      await localDataSource.clearCache();

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to mark all as read: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(
    String notificationId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteNotification(notificationId);

      // Clear cache to force refresh
      await localDataSource.clearCache();

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete notification: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllRead() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteAllRead();

      // Clear cache to force refresh
      await localDataSource.clearCache();

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete read notifications: $e'));
    }
  }

  @override
  Stream<NotificationEntity> subscribeToNotifications() {
    return remoteDataSource.subscribeToNotifications();
  }

  @override
  Future<Either<Failure, void>> registerDeviceToken({
    required String playerId,
    required String platform,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.registerDeviceToken(
        playerId: playerId,
        platform: platform,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to register device token: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unregisterDeviceToken(String playerId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.unregisterDeviceToken(playerId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to unregister device token: $e'));
    }
  }

  @override
  Future<Either<Failure, NotificationPreferencesEntity>> getNotificationPreferences() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final preferences = await remoteDataSource.getNotificationPreferences();
      return Right(preferences.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get notification preferences: $e'));
    }
  }

  @override
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
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.updateNotificationPreferences(
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
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update notification preferences: $e'));
    }
  }
}

