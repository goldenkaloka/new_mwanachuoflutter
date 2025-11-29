import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/shared/notifications/data/models/notification_model.dart';
import 'package:mwanachuo/features/shared/notifications/data/models/notification_preferences_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract class defining notification remote data source operations
abstract class NotificationRemoteDataSource {
  /// Get notifications for the current user
  Future<List<NotificationModel>> getNotifications({
    int? limit,
    int? offset,
    bool? unreadOnly,
  });

  /// Get unread notification count
  Future<int> getUnreadCount();

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead();

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Delete all read notifications
  Future<void> deleteAllRead();

  /// Subscribe to real-time notifications
  Stream<NotificationModel> subscribeToNotifications();

  /// Register device token (OneSignal player ID)
  Future<void> registerDeviceToken({
    required String playerId,
    required String platform,
  });

  /// Unregister device token
  Future<void> unregisterDeviceToken(String playerId);

  /// Get notification preferences
  Future<NotificationPreferencesModel> getNotificationPreferences();

  /// Update notification preferences
  Future<NotificationPreferencesModel> updateNotificationPreferences({
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

/// Implementation of NotificationRemoteDataSource using Supabase
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient supabaseClient;

  NotificationRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<NotificationModel>> getNotifications({
    int? limit,
    int? offset,
    bool? unreadOnly,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      var queryBuilder = supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .select()
          .eq('user_id', currentUser.id);

      if (unreadOnly == true) {
        queryBuilder = queryBuilder.eq('is_read', false);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit ?? 20)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 20) - 1);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      final response = await supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .select()
          .eq('user_id', currentUser.id)
          .eq('is_read', false);

      return (response as List).length;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get unread count: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      await supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', currentUser.id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      await supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUser.id)
          .eq('is_read', false);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to mark all as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      await supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .delete()
          .eq('id', notificationId)
          .eq('user_id', currentUser.id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> deleteAllRead() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      await supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .delete()
          .eq('user_id', currentUser.id)
          .eq('is_read', true);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete read notifications: $e');
    }
  }

  @override
  Stream<NotificationModel> subscribeToNotifications() {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      return supabaseClient
          .from(DatabaseConstants.notificationsTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => NotificationModel.fromJson(json)))
          .expand((notifications) => notifications);
    } catch (e) {
      throw ServerException('Failed to subscribe to notifications: $e');
    }
  }

  @override
  Future<void> registerDeviceToken({
    required String playerId,
    required String platform,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      // Delete any existing row with this player_id first
      // This handles the case where the player_id was previously registered to another user
      // We need to delete first because a player_id should be unique per device,
      // and the current user should be able to take over the device token
      await supabaseClient
          .from(DatabaseConstants.deviceTokensTable)
          .delete()
          .eq('player_id', playerId);

      // Now insert the new row
      await supabaseClient
          .from(DatabaseConstants.deviceTokensTable)
          .insert({
            'user_id': currentUser.id,
            'player_id': playerId,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to register device token: $e');
    }
  }

  @override
  Future<void> unregisterDeviceToken(String playerId) async {
    try {
      // Delete by player_id only - this works even if user is logging out
      // The DELETE policy allows deleting any row by player_id
      await supabaseClient
          .from(DatabaseConstants.deviceTokensTable)
          .delete()
          .eq('player_id', playerId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to unregister device token: $e');
    }
  }

  @override
  Future<NotificationPreferencesModel> getNotificationPreferences() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      final response = await supabaseClient
          .from(DatabaseConstants.notificationPreferencesTable)
          .select()
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        // Create default preferences if none exist
        final defaultPrefs = await supabaseClient
            .from(DatabaseConstants.notificationPreferencesTable)
            .insert({
              'user_id': currentUser.id,
              'push_enabled': true,
              'messages_enabled': true,
              'reviews_enabled': true,
              'listings_enabled': true,
              'promotions_enabled': true,
              'seller_requests_enabled': true,
            })
            .select()
            .single();

        return NotificationPreferencesModel.fromJson(defaultPrefs);
      }

      return NotificationPreferencesModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get notification preferences: $e');
    }
  }

  @override
  Future<NotificationPreferencesModel> updateNotificationPreferences({
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
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (pushEnabled != null) updateData['push_enabled'] = pushEnabled;
      if (messagesEnabled != null) updateData['messages_enabled'] = messagesEnabled;
      if (reviewsEnabled != null) updateData['reviews_enabled'] = reviewsEnabled;
      if (listingsEnabled != null) updateData['listings_enabled'] = listingsEnabled;
      if (promotionsEnabled != null) updateData['promotions_enabled'] = promotionsEnabled;
      if (sellerRequestsEnabled != null) {
        updateData['seller_requests_enabled'] = sellerRequestsEnabled;
      }
      if (soundEnabled != null) updateData['sound_enabled'] = soundEnabled;
      if (vibrationEnabled != null) updateData['vibration_enabled'] = vibrationEnabled;
      if (badgeEnabled != null) updateData['badge_enabled'] = badgeEnabled;
      if (inAppBannerEnabled != null) {
        updateData['in_app_banner_enabled'] = inAppBannerEnabled;
      }
      if (groupNotifications != null) {
        updateData['group_notifications'] = groupNotifications;
      }
      if (groupByCategory != null) {
        updateData['group_by_category'] = groupByCategory;
      }
      if (quietHoursStart != null) {
        // Store as TIME format (HH:mm)
        updateData['quiet_hours_start'] =
            '${quietHoursStart.hour.toString().padLeft(2, '0')}:${quietHoursStart.minute.toString().padLeft(2, '0')}';
      } else if (quietHoursStart == null && quietHoursEnd == null) {
        // Both null means disable quiet hours
        updateData['quiet_hours_start'] = null;
        updateData['quiet_hours_end'] = null;
      }
      if (quietHoursEnd != null) {
        // Store as TIME format (HH:mm)
        updateData['quiet_hours_end'] =
            '${quietHoursEnd.hour.toString().padLeft(2, '0')}:${quietHoursEnd.minute.toString().padLeft(2, '0')}';
      }

      final response = await supabaseClient
          .from(DatabaseConstants.notificationPreferencesTable)
          .upsert({
            'user_id': currentUser.id,
            ...updateData,
          }, onConflict: 'user_id')
          .select()
          .single();

      return NotificationPreferencesModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to update notification preferences: $e');
    }
  }
}
