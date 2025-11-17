import 'dart:convert';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/shared/notifications/data/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract class defining notification local data source operations
abstract class NotificationLocalDataSource {
  /// Cache notifications
  Future<void> cacheNotifications(List<NotificationModel> notifications);

  /// Get cached notifications
  Future<List<NotificationModel>> getCachedNotifications();

  /// Cache unread count
  Future<void> cacheUnreadCount(int count);

  /// Get cached unread count
  Future<int> getCachedUnreadCount();

  /// Clear notification cache
  Future<void> clearCache();
}

/// Implementation of NotificationLocalDataSource using SharedPreferences
class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final SharedPreferences sharedPreferences;

  NotificationLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheNotifications(
    List<NotificationModel> notifications,
  ) async {
    try {
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await sharedPreferences.setString(
        StorageConstants.notificationsCacheKey,
        json.encode(jsonList),
      );
    } catch (e) {
      throw CacheException('Failed to cache notifications: $e');
    }
  }

  @override
  Future<List<NotificationModel>> getCachedNotifications() async {
    try {
      final jsonString = sharedPreferences.getString(
        StorageConstants.notificationsCacheKey,
      );

      if (jsonString == null) {
        throw CacheException('No cached notifications found');
      }

      final jsonList = json.decode(jsonString) as List;
      return jsonList
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get cached notifications: $e');
    }
  }

  @override
  Future<void> cacheUnreadCount(int count) async {
    try {
      await sharedPreferences.setInt(
        StorageConstants.unreadCountKey,
        count,
      );
    } catch (e) {
      throw CacheException('Failed to cache unread count: $e');
    }
  }

  @override
  Future<int> getCachedUnreadCount() async {
    try {
      final count = sharedPreferences.getInt(
        StorageConstants.unreadCountKey,
      );

      if (count == null) {
        throw CacheException('No cached unread count found');
      }

      return count;
    } catch (e) {
      throw CacheException('Failed to get cached unread count: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await Future.wait([
        sharedPreferences.remove(StorageConstants.notificationsCacheKey),
        sharedPreferences.remove(StorageConstants.unreadCountKey),
      ]);
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }
}

